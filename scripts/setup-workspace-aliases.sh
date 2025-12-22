#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
aliases_path="${script_dir}/workspace-aliases.sh"

if [ ! -f "${aliases_path}" ]; then
  echo "Missing ${aliases_path}" >&2
  exit 1
fi

echo "To load workspace helpers for this shell session, run:"
echo "  source \"${aliases_path}\""
echo
echo "To load them automatically, add this line to your shell rc file:"
echo "  source \"${aliases_path}\""
