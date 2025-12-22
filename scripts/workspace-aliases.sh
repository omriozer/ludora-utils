#!/usr/bin/env bash
# Source this file to load workspace helpers and aliases.

_lws_script_path() {
  if [ -n "${BASH_SOURCE[0]:-}" ]; then
    echo "${BASH_SOURCE[0]}"
    return
  fi
  if [ -n "${ZSH_VERSION:-}" ]; then
    echo "${(%):-%x}"
    return
  fi
  echo "$0"
}

_lws_root() {
  local script_dir script_path
  script_path="$(_lws_script_path)"
  script_dir="${script_path%/*}"
  if [ "$script_dir" = "$script_path" ]; then
    script_dir="."
  fi
  script_dir="$(cd "$script_dir" && pwd)"
  cd "${script_dir}/../.." && pwd
}

_lws_worktree_name() {
  local root
  root="$(_lws_root)"
  if [ -d "${root}/.worktrees" ]; then
    local path
    path="$(cd "$PWD" && pwd)"
    if [ "${path#${root}/.worktrees/}" != "$path" ]; then
      local rest
      rest="${path#${root}/.worktrees/}"
      echo "${rest%%/*}"
      return
    fi
  fi
  echo "main"
}

_lws_repo_path() {
  local repo="$1"
  local target="${2:-}"
  local root worktree
  root="$(_lws_root_from_pwd)"

  if [ -z "$target" ]; then
    worktree="$(_lws_worktree_name)"
  else
    worktree="$target"
  fi

  if [ "$worktree" = "main" ]; then
    echo "${root}/${repo}"
  else
    echo "${root}/.worktrees/${worktree}/${repo}"
  fi
}

_lws_root_from_pwd() {
  if [ "${PWD#*/.worktrees/}" != "$PWD" ]; then
    echo "${PWD%%/.worktrees/*}"
  else
    _lws_root
  fi
}

_lws_ensure_deps() {
  local repo_path="$1"
  local required_bin="${2:-}"
  local needs_install=0

  if [ ! -d "${repo_path}/node_modules" ]; then
    needs_install=1
  elif [ -n "$required_bin" ] && [ ! -x "${repo_path}/node_modules/.bin/${required_bin}" ]; then
    needs_install=1
  fi

  if [ "$needs_install" -eq 1 ]; then
    echo "node_modules incomplete in ${repo_path}"
    if [ -n "$required_bin" ]; then
      echo "missing: ${required_bin}"
    fi
    echo "Run npm install? (y/n)"
    read -r install_choice
    if [ "$install_choice" = "y" ] || [ "$install_choice" = "Y" ]; then
      (cd "$repo_path" && npm install)
    else
      echo "Skipping npm install."
    fi
  fi
}

_lws_list_worktrees() {
  local root="$(_lws_root)"
  if [ ! -d "${root}/.worktrees" ]; then
    return 0
  fi
  for path in "${root}/.worktrees"/*; do
    [ -d "$path" ] || continue
    echo "${path##*/}"
  done
}

_lws_pick_worktree() {
  local choices
  choices="$(printf "main\n%s" "$(_lws_list_worktrees)")"

  if command -v fzf >/dev/null 2>&1; then
    printf "%s\n" "$choices" | fzf --prompt="Select workspace > " --height=40% --border
    return
  fi

  local selection
  echo "Select a workspace:"
  select selection in $choices; do
    if [ -n "$selection" ]; then
      echo "$selection"
      return
    fi
    echo "invalid selection" >&2
  done
}

_lws_copy_local_files() {
  local repo_path="$1"
  local main_path="$2"
  local pattern
  local restore_nullglob=0

  if [ -n "${ZSH_VERSION:-}" ]; then
    setopt local_options null_glob
  elif [ -n "${BASH_VERSION:-}" ]; then
    shopt -q nullglob || restore_nullglob=1
    shopt -s nullglob
  fi

  _lws_copy_path() {
    local src="$1"
    local dest="$2"
    if [ -e "$src" ]; then
      echo "  copying: $src -> $dest"
      if [ -d "$src" ]; then
        if command -v rsync >/dev/null 2>&1; then
          local rsync_opts="-a"
          if rsync --help 2>&1 | grep -q "progress2"; then
            rsync_opts="-a --info=progress2"
          elif rsync --help 2>&1 | grep -q "progress"; then
            rsync_opts="-a --progress"
          fi
          if [ -n "${LWS_COPY_VERBOSE:-}" ]; then
            rsync $rsync_opts "$src"/ "$dest"/
          else
            rsync $rsync_opts "$src"/ "$dest"/ >/dev/null 2>&1
          fi
          if [ $? -ne 0 ]; then
            echo "  rsync failed, falling back to cp -R"
            mkdir -p "$dest"
            cp -R "$src"/. "$dest"/
          fi
        else
          mkdir -p "$dest"
          cp -R "$src"/. "$dest"/
        fi
      else
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
      fi
      echo "  done: $dest"
    fi
  }

  case "$(basename "$repo_path")" in
    ludora-api)
      for pattern in "${main_path}/.env" "${main_path}/.env."* "${main_path}/staging.env"; do
        [ -f "$pattern" ] || continue
        local filename
        filename="${pattern##*/}"
        if [ ! -f "${repo_path}/${filename}" ]; then
          _lws_copy_path "$pattern" "${repo_path}/${filename}"
        fi
      done
      _lws_copy_path "${main_path}/.firebase" "${repo_path}/.firebase"
      _lws_copy_path "${main_path}/firebase-service-account.json" "${repo_path}/firebase-service-account.json"
      _lws_copy_path "${main_path}/firebase-service-account-dev.json" "${repo_path}/firebase-service-account-dev.json"
      _lws_copy_path "${main_path}/firebase-debug.log" "${repo_path}/firebase-debug.log"
      _lws_copy_path "${main_path}/firestore-debug.log" "${repo_path}/firestore-debug.log"
      _lws_copy_path "${main_path}/ui-debug.log" "${repo_path}/ui-debug.log"
      mkdir -p "${repo_path}/uploads" "${repo_path}/temp" "${repo_path}/tmp"
      for pattern in "${main_path}"/*.sqlite "${main_path}"/*.sqlite3 "${main_path}"/*.db; do
        [ -f "$pattern" ] || continue
        _lws_copy_path "$pattern" "${repo_path}/$(basename "$pattern")"
      done
      if [ ! -d "${repo_path}/node_modules" ]; then
        echo "  node_modules missing in ${repo_path}"
        echo "  run npm install? (y/n)"
        read -r install_choice
        if [ "$install_choice" = "y" ] || [ "$install_choice" = "Y" ]; then
          (cd "$repo_path" && npm install)
        fi
      fi
      ;;
    ludora-front)
      for pattern in "${main_path}/.env" "${main_path}/.env."*; do
        [ -f "$pattern" ] || continue
        local filename
        filename="${pattern##*/}"
        if [ ! -f "${repo_path}/${filename}" ]; then
          _lws_copy_path "$pattern" "${repo_path}/${filename}"
        fi
      done
      _lws_copy_path "${main_path}/.firebase" "${repo_path}/.firebase"
      _lws_copy_path "${main_path}/firebase-debug.log" "${repo_path}/firebase-debug.log"
      _lws_copy_path "${main_path}/firestore-debug.log" "${repo_path}/firestore-debug.log"
      _lws_copy_path "${main_path}/ui-debug.log" "${repo_path}/ui-debug.log"
      _lws_copy_path "${main_path}/.vscode" "${repo_path}/.vscode"
      if [ ! -d "${repo_path}/node_modules" ]; then
        echo "  node_modules missing in ${repo_path}"
        echo "  run npm install? (y/n)"
        read -r install_choice
        if [ "$install_choice" = "y" ] || [ "$install_choice" = "Y" ]; then
          (cd "$repo_path" && npm install)
        fi
      fi
      ;;
  esac

  if [ "$restore_nullglob" -eq 1 ]; then
    shopt -u nullglob
  fi
}

_lws_each_repo() {
  local root repo
  root="$(_lws_root)"
  for repo in ludora-api ludora-front ludora-utils; do
    if [ -e "${root}/${repo}/.git" ]; then
      (cd "${root}/${repo}" && "$@")
    else
      echo "missing repo: ${root}/${repo}" >&2
    fi
  done
}

_lws_each_repo_for() {
  local target="$1"
  shift
  local root repo repo_path
  root="$(_lws_root)"
  for repo in ludora-api ludora-front ludora-utils; do
    repo_path="$(_lws_repo_path "$repo" "$target")"
    if [ -e "${repo_path}/.git" ]; then
      (cd "${repo_path}" && "$@")
    else
      echo "missing repo: ${repo_path}" >&2
    fi
  done
}

lws-root() { cd "$(_lws_root)" || return 1; }
lws-api() { cd "$(_lws_root)/ludora-api" || return 1; }
lws-front() { cd "$(_lws_root)/ludora-front" || return 1; }
lws-utils() { cd "$(_lws_root)/ludora-utils" || return 1; }

lws-status() {
  local target=""
  case "${1:-}" in
    --for=*) target="${1#*=}" ;;
  esac
  if [ -z "$target" ] && [ "$(_lws_worktree_name)" = "main" ]; then
    target="$(_lws_pick_worktree)"
  fi
  if [ -n "$target" ] && [ "$target" != "main" ]; then
    _lws_each_repo_for "$target" git status -sb
  else
    _lws_each_repo git status -sb
  fi
}

lws-fetch() {
  local target=""
  case "${1:-}" in
    --for=*) target="${1#*=}" ;;
  esac
  if [ -n "$target" ]; then
    _lws_each_repo_for "$target" git fetch --prune
  else
    _lws_each_repo git fetch --prune
  fi
}

lws-pull() {
  local target=""
  case "${1:-}" in
    --for=*) target="${1#*=}" ;;
  esac
  if [ -n "$target" ]; then
    _lws_each_repo_for "$target" git pull --ff-only
  else
    _lws_each_repo git pull --ff-only
  fi
}

lws-sync() {
  local target=""
  case "${1:-}" in
    --for=*) target="${1#*=}" ;;
  esac
  if [ -n "$target" ]; then
    lws-fetch --for="$target" && lws-pull --for="$target"
  else
    lws-fetch && lws-pull
  fi
}
lws-stage() {
  local target=""
  case "${1:-}" in
    --for=*) target="${1#*=}" ;;
  esac
  if [ -n "$target" ]; then
    _lws_each_repo_for "$target" git add -A
  else
    _lws_each_repo git add -A
  fi
}

lws-commit() {
  if [ -z "${1:-}" ]; then
    echo "usage: lws-commit <message>" >&2
    return 2
  fi
  local message="$1"
  local target=""
  case "${2:-}" in
    --for=*) target="${2#*=}" ;;
  esac
  if [ -n "$target" ]; then
    _lws_each_repo_for "$target" bash -lc 'if ! git diff --cached --quiet; then git commit -m "$0"; else echo "no staged changes in $(pwd)"; fi' "$message"
  else
    _lws_each_repo bash -lc 'if ! git diff --cached --quiet; then git commit -m "$0"; else echo "no staged changes in $(pwd)"; fi' "$message"
  fi
}

lws-push() {
  local target=""
  case "${1:-}" in
    --for=*) target="${1#*=}" ;;
  esac
  local cmd='
    branch="$(git rev-parse --abbrev-ref HEAD)"
    if [ "$branch" = "HEAD" ]; then
      echo "detached HEAD in $(pwd)" >&2
      exit 0
    fi
    if git rev-parse --verify "origin/${branch}" >/dev/null 2>&1; then
      ahead="$(git rev-list --count "origin/${branch}..${branch}")"
    else
      ahead="$(git rev-list --count "${branch}")"
    fi
    if [ "$ahead" -gt 0 ]; then
      git push -u origin "$branch"
    else
      echo "no commits ahead in $(pwd)"
    fi
  '
  if [ -n "$target" ]; then
    _lws_each_repo_for "$target" bash -lc "$cmd"
  else
    _lws_each_repo bash -lc "$cmd"
  fi
}

lws-branch() {
  if [ -z "$1" ]; then
    echo "usage: lws-branch <name>" >&2
    return 2
  fi
  local branch="$1"
  local target=""
  case "${2:-}" in
    --for=*) target="${2#*=}" ;;
  esac
  if [ -n "$target" ]; then
    _lws_each_repo_for "$target" git checkout -b "$branch"
  else
    _lws_each_repo git checkout -b "$branch"
  fi
}

lws-new() {
  local branch="${1:-}"
  local do_sync=1
  local arg
  local dirty_repos=()
  local repo
  local choice
  local base_ref="origin/staging"

  for arg in "$@"; do
    case "$arg" in
      --no-sync)
        do_sync=0
        ;;
      --base=*)
        base_ref="${arg#*=}"
        ;;
    esac
  done

  if [ -z "$branch" ]; then
    echo "usage: lws-new <name> [--no-sync] [--base=<ref>]" >&2
    return 2
  fi

  if [ "$do_sync" -eq 1 ]; then
    lws-sync
  fi

  for repo in ludora-api ludora-front ludora-utils; do
    if [ -d "$(_lws_root)/${repo}/.git" ]; then
      if (cd "$(_lws_root)/${repo}" && ! git diff --quiet); then
        dirty_repos+=("$repo")
      elif (cd "$(_lws_root)/${repo}" && ! git diff --cached --quiet); then
        dirty_repos+=("$repo")
      elif (cd "$(_lws_root)/${repo}" && [ -n "$(git status --porcelain)" ]); then
        dirty_repos+=("$repo")
      fi
    fi
  done

  if [ "${#dirty_repos[@]}" -gt 0 ]; then
    echo "Uncommitted changes detected in: ${dirty_repos[*]}"
    echo "Choose how to create the new branch:"
    echo "  1) Move changes to the new branch (checkout the branch in each repo)"
    echo "  2) Keep changes on current branches and create a clean branch in new worktrees"
    read -r choice
    case "$choice" in
      1)
        _lws_each_repo bash -lc '
          base="$1"
          branch="$2"
          if git rev-parse --verify "$base" >/dev/null 2>&1; then
            git checkout -b "$branch" "$base"
          else
            echo "base ref not found in $(pwd): $base" >&2
          fi
        ' "$base_ref" "$branch"
        ;;
      2)
        for repo in ludora-api ludora-front ludora-utils; do
          if [ ! -d "$(_lws_root)/${repo}/.git" ]; then
            echo "missing repo: $(_lws_root)/${repo}" >&2
            continue
          fi
          (
            cd "$(_lws_root)/${repo}" || exit 1
            worktree_path="$(_lws_root)/.worktrees/${branch}/${repo}"
            mkdir -p "$(dirname "$worktree_path")"
            if [ -d "$worktree_path" ]; then
              echo "worktree already exists: $worktree_path"
              exit 0
            fi
            if git rev-parse --verify "$base_ref" >/dev/null 2>&1; then
              if git show-ref --verify --quiet "refs/heads/${branch}"; then
                git worktree add "$worktree_path" "${branch}"
              else
                git worktree add -b "${branch}" "$worktree_path" "$base_ref"
              fi
              _lws_copy_local_files "$worktree_path" "$(_lws_root)/${repo}"
            else
              echo "base ref not found in $(pwd): $base_ref" >&2
            fi
          )
        done
        echo "Worktrees created under: $(_lws_root)/.worktrees/${branch}/"
        ;;
      *)
        echo "aborted" >&2
        return 1
        ;;
    esac
  else
    _lws_each_repo bash -lc '
      base="$1"
      branch="$2"
      if git rev-parse --verify "$base" >/dev/null 2>&1; then
        git checkout -b "$branch" "$base"
      else
        echo "base ref not found in $(pwd): $base" >&2
      fi
    ' "$base_ref" "$branch"
  fi
}

lws-checkout() {
  if [ -z "$1" ]; then
    echo "usage: lws-checkout <name>" >&2
    return 2
  fi
  local branch="$1"
  local target=""
  case "${2:-}" in
    --for=*) target="${2#*=}" ;;
  esac
  if [ -z "$target" ] && [ "$(_lws_worktree_name)" = "main" ]; then
    target="$(_lws_pick_worktree)"
  fi
  if [ -n "$target" ] && [ "$target" != "main" ]; then
    _lws_each_repo_for "$target" git checkout "$branch"
  else
    _lws_each_repo git checkout "$branch"
  fi
}

lws-dev() {
  local target="both"
  local port_plus=0
  local base_api_port=3003
  local base_front_port=5173
  local api_port front_port
  local for_target=""

  for arg in "$@"; do
    case "$arg" in
      api|front|both)
        target="$arg"
        ;;
      --port-plus=*)
        port_plus="${arg#*=}"
        ;;
      --for=*)
        for_target="${arg#*=}"
        ;;
      *)
        echo "usage: lws-dev [api|front|both] [--port-plus=N]" >&2
        return 2
        ;;
    esac
  done

  if ! [[ "$port_plus" =~ ^[0-9]+$ ]]; then
    echo "usage: lws-dev [api|front|both] [--port-plus=N]" >&2
    return 2
  fi

  api_port=$((base_api_port + port_plus))
  front_port=$((base_front_port + port_plus))

  case "$target" in
    api)
      echo "lws-dev: api on :${api_port} (NODE_ENV=development, ws=${for_target:-$(_lws_worktree_name)})"
      local api_path
      api_path="$(_lws_repo_path "ludora-api" "$for_target")"
      if [ -e "${api_path}/.git" ]; then
        echo "  api repo: ${api_path} (branch: $(git -C "$api_path" rev-parse --abbrev-ref HEAD 2>/dev/null))"
      fi
      _lws_ensure_deps "$api_path" "nodemon"
      local trap_target
      trap_target="${for_target:-$(_lws_worktree_name)}"
      (cd "$api_path" && env -u NODE_OPTIONS NODE_ENV=development PORT="${api_port}" npm run dev) &
      local dev_pid=$!
      trap 'kill "$dev_pid" 2>/dev/null; return 130' INT TERM
      wait "$dev_pid"
      trap - INT TERM
      ;;
    front)
      echo "lws-dev: front on :${front_port} -> api localhost:${api_port} (ws=${for_target:-$(_lws_worktree_name)})"
      local front_path
      front_path="$(_lws_repo_path "ludora-front" "$for_target")"
      if [ -e "${front_path}/.git" ]; then
        echo "  front repo: ${front_path} (branch: $(git -C "$front_path" rev-parse --abbrev-ref HEAD 2>/dev/null))"
      fi
      _lws_ensure_deps "$front_path" "vite"
      local trap_target
      trap_target="${for_target:-$(_lws_worktree_name)}"
      (cd "$front_path" && \
        env -u NODE_OPTIONS \
        NODE_ENV=development \
        VITE_API_DOMAIN=localhost \
        VITE_API_PORT="${api_port}" \
        VITE_FRONTEND_PORT="${front_port}" \
        VITE_STUDENT_PORTAL_PORT="${front_port}" \
        VITE_TEACHER_PORTAL_DOMAIN=localhost \
        VITE_STUDENT_PORTAL_DOMAIN=my.localhost \
        npm run dev -- --port "${front_port}") &
      local dev_pid=$!
      trap 'kill "$dev_pid" 2>/dev/null; return 130' INT TERM
      wait "$dev_pid"
      trap - INT TERM
      ;;
    both)
      local api_pid front_pid
      local api_path front_path
      api_path="$(_lws_repo_path "ludora-api" "$for_target")"
      front_path="$(_lws_repo_path "ludora-front" "$for_target")"
      _lws_ensure_deps "$api_path" "nodemon"
      _lws_ensure_deps "$front_path" "vite"
      local trap_target
      trap_target="${for_target:-$(_lws_worktree_name)}"
      lws-dev api --port-plus="${port_plus}" ${for_target:+--for="${for_target}"} &
      api_pid=$!
      lws-dev front --port-plus="${port_plus}" ${for_target:+--for="${for_target}"} &
      front_pid=$!
      trap 'lws-stop --for="${trap_target}" --port-plus="${port_plus}"' INT TERM
      while kill -0 "$api_pid" 2>/dev/null && kill -0 "$front_pid" 2>/dev/null; do
        sleep 1
      done
      if ! kill -0 "$api_pid" 2>/dev/null || ! kill -0 "$front_pid" 2>/dev/null; then
        echo "lws-dev: one or more processes exited; stopping both"
        lws-stop --for="${trap_target}" --port-plus="${port_plus}"
      fi
      ;;
    *)
      echo "usage: lws-dev [api|front|both]" >&2
      return 2
      ;;
  esac
}

lws-ports() {
  local port_plus=0
  local base_api_port=3003
  local base_front_port=5173
  local api_port front_port
  local for_target=""

  case "${1:-}" in
    --port-plus=*)
      port_plus="${1#*=}"
      ;;
    --for=*)
      for_target="${1#*=}"
      ;;
    "")
      ;;
    *)
      echo "usage: lws-ports [--port-plus=N]" >&2
      return 2
      ;;
  esac

  if ! [[ "$port_plus" =~ ^[0-9]+$ ]]; then
    echo "usage: lws-ports [--port-plus=N]" >&2
    return 2
  fi

  api_port=$((base_api_port + port_plus))
  front_port=$((base_front_port + port_plus))

  if [ -n "$for_target" ]; then
    echo "workspace: ${for_target}"
  else
    echo "workspace: $(_lws_worktree_name)"
  fi
  echo "api:   :${api_port} (base 3003 + ${port_plus})"
  echo "front: :${front_port} (base 5173 + ${port_plus})"
}

lws-lsof() {
  local port="${1:-}"
  local pid

  if [ -z "$port" ]; then
    echo "usage: lws-lsof <port>" >&2
    return 2
  fi

  pid="$(lsof -i :"$port" -sTCP:LISTEN -Pn 2>/dev/null | awk 'NR==2{print $2}')"
  if [ -n "$pid" ]; then
    local ppid command
    ppid="$(ps -p "$pid" -o ppid= | awk '{print $1}')"
    command="$(ps -p "$pid" -o command=)"
    echo "  pid ${pid} (ppid ${ppid}): ${command}"
  else
    echo "  no listener"
  fi
}

lws-sync-local() {
  local target="${1:-}"
  local root repo main_path repo_path

  if [ -z "$target" ]; then
    target="$(_lws_worktree_name)"
  fi
  if [ "$target" = "main" ]; then
    target="$(_lws_pick_worktree)"
  fi

  root="$(_lws_root_from_pwd)"
  echo "sync local files to worktree: ${target}"
  for repo in ludora-api ludora-front ludora-utils; do
    main_path="${root}/${repo}"
    repo_path="${root}/.worktrees/${target}/${repo}"
    if [ -e "${repo_path}/.git" ] && [ -e "${main_path}/.git" ]; then
      echo "repo: ${repo}"
      _lws_copy_local_files "${repo_path}" "${main_path}"
    else
      echo "missing repo: ${repo_path}" >&2
    fi
  done
}

lws-ports-check() {
  local port_plus=0
  local base_api_port=3003
  local base_front_port=5173
  local api_port front_port
  local lws_ps
  local for_target=""

  case "${1:-}" in
    --port-plus=*)
      port_plus="${1#*=}"
      ;;
    --for=*)
      for_target="${1#*=}"
      ;;
    "")
      ;;
    *)
      echo "usage: lws-ports-check [--port-plus=N]" >&2
      return 2
      ;;
  esac

  if ! [[ "$port_plus" =~ ^[0-9]+$ ]]; then
    echo "usage: lws-ports-check [--port-plus=N]" >&2
    return 2
  fi

  api_port=$((base_api_port + port_plus))
  front_port=$((base_front_port + port_plus))

  if [ -n "$for_target" ]; then
    echo "workspace: ${for_target}"
  else
    echo "workspace: $(_lws_worktree_name)"
  fi
  echo "api port ${api_port}:"
  lws-lsof "${api_port}"
  echo "front port ${front_port}:"
  lws-lsof "${front_port}"

  echo "Likely LWS dev processes:"
  lws_ps="$(ps -Ao pid=,command= | egrep -i 'ludora-front/node_modules/.bin/vite|npm run dev --port|ludora-api/.*/nodemon index.js|ludora-api/.*/bin/node index.js' | grep -v egrep)"
  if [ -n "$lws_ps" ]; then
    local root
    root="$(_lws_root)"
    echo "Frontend (Vite/npm):"
    echo "$lws_ps" | egrep -i 'ludora-front/node_modules/.bin/vite|npm run dev --port' \
      | awk -v root="$root" '{
          gsub(root,"~ludora");
          print "  pid " $1 ": " substr($0, index($0,$2));
          print "";
        }' || true
    echo "Backend (API):"
    echo "$lws_ps" | egrep -i 'ludora-api/.*/nodemon index.js|ludora-api/.*/bin/node index.js' \
      | awk -v root="$root" '{
          gsub(root,"~ludora");
          print "  pid " $1 ": " substr($0, index($0,$2));
          print "";
        }' || true
  else
    echo "  none found"
  fi
}

lws-stop() {
  local target=""
  local explicit_for=0
  local port_plus=0
  local worktree root repo_path pids
  case "${1:-}" in
    --for=*)
      target="${1#*=}"
      explicit_for=1
      ;;
    --port-plus=*)
      port_plus="${1#*=}"
      ;;
  esac

  if [ -z "$target" ]; then
    target="$(_lws_worktree_name)"
  fi
  if [ "$target" = "main" ] && [ "$explicit_for" -ne 1 ]; then
    target="$(_lws_pick_worktree)"
  fi

  worktree="$target"
  root="$(_lws_root_from_pwd)"

  for repo in ludora-api ludora-front; do
    repo_path="$(_lws_repo_path "$repo" "$worktree")"
    if [ ! -e "${repo_path}/.git" ]; then
      continue
    fi
    pids="$(pgrep -f "${repo_path}.*(nodemon|vite|node).*" || true)"
    if [ -n "$pids" ]; then
      echo "stopping ${repo} (pids: ${pids})"
      kill $pids 2>/dev/null
    fi
  done

  if [[ "$port_plus" =~ ^[0-9]+$ ]]; then
    local api_port front_port
    api_port=$((3003 + port_plus))
    front_port=$((5173 + port_plus))
    for port in "$api_port" "$front_port"; do
      pids="$(lsof -ti :"$port" 2>/dev/null || true)"
      if [ -n "$pids" ]; then
        echo "stopping port ${port} (pids: ${pids})"
        kill $pids 2>/dev/null
      fi
    done
  fi
}
lws-pr-create() {
  _lws_each_repo bash -lc '
    if ! command -v gh >/dev/null 2>&1; then
      echo "gh not found; install GitHub CLI" >&2
      exit 0
    fi
    if ! gh auth status >/dev/null 2>&1; then
      echo "gh not authenticated; run: gh auth login" >&2
      exit 0
    fi
    if ! git diff --cached --quiet || ! git diff --quiet; then
      echo "working tree not clean in $(pwd); commit first" >&2
      exit 0
    fi
    gh pr create
  '
}

lws-clean() {
  local branch="${1:-}"
  local repos=()
  local do_local=0
  local do_remote=0
  local repo
  local target=""

  if [ -z "$branch" ]; then
    echo "usage: lws-clean <name>" >&2
    return 2
  fi

  target="$(_lws_worktree_name)"
  if [ "$target" = "main" ]; then
    target="$(_lws_pick_worktree)"
  fi

  echo "Select repos to clean for branch: ${branch}"
  echo "  1) ludora-api"
  echo "  2) ludora-front"
  echo "  3) ludora-utils"
  echo "Enter comma-separated list (e.g., 1,2) or 'all':"
  read -r repo_input

  case "$repo_input" in
    all)
      repos=(ludora-api ludora-front ludora-utils)
      ;;
    *)
      IFS=',' read -r -a repo_choices <<< "$repo_input"
      for repo in "${repo_choices[@]}"; do
        case "$(echo "$repo" | tr -d ' ')" in
          1) repos+=(ludora-api) ;;
          2) repos+=(ludora-front) ;;
          3) repos+=(ludora-utils) ;;
        esac
      done
      ;;
  esac

  if [ "${#repos[@]}" -eq 0 ]; then
    echo "No repos selected." >&2
    return 1
  fi

  echo "Delete local branch? (y/n)"
  read -r local_input
  if [ "$local_input" = "y" ] || [ "$local_input" = "Y" ]; then
    do_local=1
  fi

  echo "Delete remote branch origin/${branch}? (y/n)"
  read -r remote_input
  if [ "$remote_input" = "y" ] || [ "$remote_input" = "Y" ]; then
    do_remote=1
  fi

  for repo in "${repos[@]}"; do
    local repo_path
    repo_path="$(_lws_repo_path "$repo" "$target")"
    if [ ! -e "${repo_path}/.git" ]; then
      echo "missing repo: ${repo_path}" >&2
      continue
    fi
    (
      cd "${repo_path}" || exit 1
      if [ "$do_local" -eq 1 ]; then
        if git show-ref --verify --quiet "refs/heads/${branch}"; then
          git branch -D "${branch}"
        else
          echo "local branch not found in $(pwd)"
        fi
      fi
      if [ "$do_remote" -eq 1 ]; then
        if git ls-remote --exit-code --heads origin "${branch}" >/dev/null 2>&1; then
          git push origin --delete "${branch}"
        else
          echo "remote branch not found in $(pwd)"
        fi
      fi
    )
  done
}

lws-ls() {
  local root dir
  root="$(_lws_root)"
  if [ ! -d "${root}/.worktrees" ]; then
    echo "no worktrees found at ${root}/.worktrees"
    return 0
  fi
  for dir in "${root}/.worktrees"/*; do
    [ -d "$dir" ] || continue
    echo "$(basename "$dir")"
  done
}

lws-cd() {
  local branch="${1:-}"
  local root path

  if [ -z "$branch" ]; then
    local choices choice_index
    root="$(_lws_root)"
    if [ ! -d "${root}/.worktrees" ]; then
      echo "no worktrees found at ${root}/.worktrees" >&2
      return 1
    fi
    choices=()
    for path in "${root}/.worktrees"/*; do
      [ -d "$path" ] || continue
      choices+=("${path##*/}")
    done
    if [ "${#choices[@]}" -eq 0 ]; then
      echo "no worktrees found at ${root}/.worktrees" >&2
      return 1
    fi
    local fzf_bin=""
    if command -v fzf >/dev/null 2>&1; then
      fzf_bin="fzf"
    elif [ -x "/opt/homebrew/bin/fzf" ]; then
      fzf_bin="/opt/homebrew/bin/fzf"
    elif [ -x "/usr/local/bin/fzf" ]; then
      fzf_bin="/usr/local/bin/fzf"
    fi

    if [ -n "$fzf_bin" ]; then
      branch="$(printf "%s\n" "${choices[@]}" | "$fzf_bin" -m --prompt="Select worktree > " --height=40% --border)"
      if [ -z "$branch" ]; then
        echo "no selection" >&2
        return 1
      fi
      branch="${branch%%$'\n'*}"
      branch="${branch//$'\r'/}"
    else
      echo "fzf not found; using numeric selection. Install for checkbox UI:" >&2
      echo "  brew install fzf" >&2
      echo "Select a worktree:"
      select branch in "${choices[@]}"; do
        if [ -n "$branch" ]; then
          break
        fi
        echo "invalid selection" >&2
      done
    fi
    if [ -z "$branch" ]; then
      echo "no selection" >&2
      return 1
    fi
  fi

  root="$(_lws_root)"
  path="${root}/.worktrees/${branch}"
  if [ ! -d "$path" ]; then
    echo "worktree not found: ${path}" >&2
    echo "use: lws-new ${branch}" >&2
    return 1
  fi

  cd "$path" || return 1
  echo "worktree root: $path"
}

lws-flow() {
  cat <<'EOF'
Suggested workflow:
  1) lws-sync
     Pull the newest commits from remote for all repos so you start from the
     same baseline as everyone else. This avoids conflicts later.
  2) lws-branch <feature-name>
     Create a new branch with the same name in each repo so your changes are
     isolated from main/staging and easy to review.
  3) lws-dev [api|front|both] [--port-plus=N]
     Run local servers for testing. Use --port-plus if another server is
     already using the default ports.
  4) lws-stage
     Stage all file changes in each repo so they are ready to commit.
  5) lws-commit "message"
     Create commits in each repo that has staged changes.
  6) lws-push
     Push only repos that have new commits so remote branches are updated.
  7) lws-pr-create
     Open a PR for each repo so the changes can be reviewed and merged.
EOF
}

lws-help() {
  cat <<'EOF'
Workspace helpers:
  lws-root          cd to workspace root (/Users/omri/omri-dev/base44/ludora)
  lws-api           cd to /Users/omri/omri-dev/base44/ludora/ludora-api
  lws-front         cd to /Users/omri/omri-dev/base44/ludora/ludora-front
  lws-utils         cd to /Users/omri/omri-dev/base44/ludora/ludora-utils
  lws-status        git status -sb for all repos (short branch + changes)
                   add --for=main|<worktree> to target a specific workspace
  lws-fetch         git fetch --prune for all repos (prune removes stale remote refs)
                   add --for=main|<worktree> to target a specific workspace
  lws-pull          git pull --ff-only for all repos (no merge commits)
                   add --for=main|<worktree> to target a specific workspace
  lws-sync          fetch + pull for all repos
  lws-stage         git add -A for all repos
                   add --for=main|<worktree> to target a specific workspace
  lws-commit MSG    commit staged changes per repo (skips clean repos)
                   add --for=main|<worktree> to target a specific workspace
  lws-push          push only repos with commits ahead of origin
                   add --for=main|<worktree> to target a specific workspace
  lws-branch NAME   create branch NAME in all repos
                   add --for=main|<worktree> to target a specific workspace
  lws-new NAME      sync (unless --no-sync) then create branch in all repos
                   add --base=<ref> to set the base (default origin/staging)
  lws-checkout NAME checkout branch NAME in all repos
                   add --for=main|<worktree> to target a specific workspace
  lws-dev [target]  run dev servers (api|front|both, default both)
                   use --port-plus=N to offset default ports (api 3003, front 5173)
                   front uses Vite proxy (/api, /socket.io) so CORS is avoided in dev
                   add --for=main|<worktree> to target a specific workspace
  lws-ports         show computed dev ports (use --port-plus=N to match lws-dev)
                   add --for=main|<worktree> to label a specific workspace
  lws-lsof PORT     show listener and process for a port
  lws-ports-check   show listeners for api/front ports (use --port-plus=N)
                   add --for=main|<worktree> to label a specific workspace
  lws-sync-local    copy local ignored files (env, node_modules, firebase, etc.)
  lws-stop          stop dev processes for current or selected worktree
  lws-pr-create     run gh pr create per repo (requires clean repo)
  lws-clean NAME    delete branch locally and/or on origin for selected repos
  lws-ls            list available LWS worktrees
  lws-cd NAME       cd to LWS worktree root (created by lws-new)
  lws-flow          show suggested multi-repo workflow
  lws-help          show this help
EOF
}
