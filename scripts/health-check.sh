#!/bin/bash
# Comprehensive health check for Ludora platform

set -e

echo "🏥 Ludora Platform Health Check"
echo "==============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Health check results
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Function to log results
log_result() {
    local status=$1
    local message=$2
    local details=$3

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    case $status in
        "PASS")
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            echo -e "✅ ${GREEN}PASS${NC}: $message"
            ;;
        "FAIL")
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            echo -e "❌ ${RED}FAIL${NC}: $message"
            ;;
        "WARN")
            WARNING_CHECKS=$((WARNING_CHECKS + 1))
            echo -e "⚠️  ${YELLOW}WARN${NC}: $message"
            ;;
        "INFO")
            echo -e "ℹ️  ${BLUE}INFO${NC}: $message"
            ;;
    esac

    if [ -n "$details" ]; then
        echo "   $details"
    fi
}

# Function to check if command exists
check_command() {
    local cmd=$1
    local name=$2

    if command -v "$cmd" &> /dev/null; then
        log_result "PASS" "$name is installed"
        return 0
    else
        log_result "FAIL" "$name is not installed"
        return 1
    fi
}

# Function to check URL health
check_url() {
    local url=$1
    local name=$2
    local expected_code=${3:-200}
    local timeout=${4:-10}

    if ! command -v curl &> /dev/null; then
        log_result "WARN" "Cannot check $name - curl not available"
        return 1
    fi

    local response
    local http_code
    local response_time

    # Get HTTP code and response time
    response=$(curl -s -w "%{http_code}|%{time_total}" "$url" --max-time "$timeout" 2>/dev/null || echo "000|0")
    http_code=$(echo "$response" | cut -d'|' -f1)
    response_time=$(echo "$response" | cut -d'|' -f2)

    if [ "$http_code" = "$expected_code" ]; then
        log_result "PASS" "$name is responding" "HTTP $http_code in ${response_time}s"
        return 0
    elif [ "$http_code" = "000" ]; then
        log_result "FAIL" "$name is not reachable" "Connection timeout or network error"
        return 1
    else
        log_result "FAIL" "$name returned unexpected status" "HTTP $http_code (expected $expected_code)"
        return 1
    fi
}

# Function to check JSON response
check_json_endpoint() {
    local url=$1
    local name=$2
    local expected_field=$3
    local expected_value=$4

    if ! command -v curl &> /dev/null; then
        log_result "WARN" "Cannot check $name - curl not available"
        return 1
    fi

    local response
    response=$(curl -s "$url" --max-time 10 2>/dev/null)

    if [ $? -ne 0 ]; then
        log_result "FAIL" "$name endpoint not reachable"
        return 1
    fi

    if echo "$response" | grep -q "\"$expected_field\":\"$expected_value\""; then
        log_result "PASS" "$name endpoint health check"
        return 0
    else
        log_result "FAIL" "$name endpoint health check" "Expected $expected_field=$expected_value"
        return 1
    fi
}

# Function to check Fly.io app status
check_fly_app() {
    local app_name=$1
    local service_name=$2

    if ! command -v flyctl &> /dev/null; then
        log_result "WARN" "Cannot check $service_name - flyctl not available"
        return 1
    fi

    if ! flyctl auth whoami &> /dev/null; then
        log_result "WARN" "Cannot check $service_name - not logged in to Fly.io"
        return 1
    fi

    local status_output
    status_output=$(flyctl status -a "$app_name" 2>/dev/null)

    if [ $? -ne 0 ]; then
        log_result "FAIL" "$service_name app status check" "Cannot get app status"
        return 1
    fi

    # Check if any machines are running
    if echo "$status_output" | grep -q "started"; then
        local running_count
        running_count=$(echo "$status_output" | grep -c "started" || echo "0")
        log_result "PASS" "$service_name has running instances" "$running_count machine(s) running"
        return 0
    else
        log_result "FAIL" "$service_name has no running instances"
        return 1
    fi
}

# Parse command line arguments
QUICK=false
DETAILED=false
SKIP_EXTERNAL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --quick|-q)
            QUICK=true
            shift
            ;;
        --detailed|-d)
            DETAILED=true
            shift
            ;;
        --skip-external)
            SKIP_EXTERNAL=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Comprehensive health check for Ludora platform"
            echo ""
            echo "Options:"
            echo "  --quick, -q        Quick check (essential services only)"
            echo "  --detailed, -d     Detailed check with additional tests"
            echo "  --skip-external    Skip external service checks"
            echo "  --help, -h         Show this help message"
            echo ""
            echo "The health check verifies:"
            echo "  - Required tools installation"
            echo "  - Fly.io authentication and app status"
            echo "  - API and frontend accessibility"
            echo "  - Database connectivity"
            echo "  - Service health endpoints"
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "📅 Health check started at $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 1. Check required tools
echo "🔧 Checking Required Tools"
echo "--------------------------"
check_command "flyctl" "Fly.io CLI"
check_command "curl" "curl"
check_command "psql" "PostgreSQL client"

if [ "$DETAILED" = true ]; then
    check_command "jq" "jq (JSON processor)"
    check_command "git" "Git"
fi

echo ""

# 2. Check Fly.io authentication
echo "🔐 Checking Fly.io Authentication"
echo "---------------------------------"
if command -v flyctl &> /dev/null; then
    if flyctl auth whoami &> /dev/null; then
        local user_info
        user_info=$(flyctl auth whoami 2>/dev/null || echo "Unknown")
        log_result "PASS" "Fly.io authentication" "Logged in as: $user_info"
    else
        log_result "FAIL" "Fly.io authentication" "Not logged in - run 'flyctl auth login'"
    fi
else
    log_result "FAIL" "Fly.io authentication" "flyctl not available"
fi

echo ""

# 3. Check Fly.io app status
echo "🚀 Checking Fly.io App Status"
echo "-----------------------------"
check_fly_app "ludora-api" "API Server"
check_fly_app "ludora-front" "Frontend"
check_fly_app "ludora-db" "Database"

echo ""

# 4. Check external endpoints (if not skipped)
if [ "$SKIP_EXTERNAL" = false ]; then
    echo "🌐 Checking External Endpoints"
    echo "------------------------------"

    # Frontend check
    check_url "https://ludora-front.fly.dev" "Frontend" "200"

    # API root check
    check_url "https://ludora-api.fly.dev" "API Root" "200"

    # API health endpoint
    check_json_endpoint "https://ludora-api.fly.dev/health" "API Health" "status" "healthy"

    # Auth endpoint (should return 401 without credentials)
    check_url "https://ludora-api.fly.dev/api/auth/me" "API Auth Endpoint" "401"

    if [ "$DETAILED" = true ]; then
        # Additional endpoint checks
        check_url "https://ludora-api.fly.dev/api" "API Info Endpoint" "200"
    fi

    echo ""
fi

# 5. Check database connectivity (if quick mode is off)
if [ "$QUICK" = false ]; then
    echo "🗄️  Checking Database Connectivity"
    echo "---------------------------------"

    # Check if proxy is running
    if lsof -Pi :5433 -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_result "PASS" "Database proxy is running" "Port 5433 is open"

        # Try to connect if psql is available and password is set
        if command -v psql &> /dev/null && [ -n "$PGPASSWORD" ]; then
            if psql -h localhost -p 5433 -U postgres -d postgres -c "SELECT 1;" &>/dev/null; then
                log_result "PASS" "Database connection test"
            else
                log_result "FAIL" "Database connection test" "Cannot connect via proxy"
            fi
        else
            log_result "INFO" "Database connection test skipped" "Set PGPASSWORD to test connection"
        fi
    else
        log_result "WARN" "Database proxy not running" "Run 'flyctl proxy 5433:5432 -a ludora-db'"
    fi

    echo ""
fi

# 6. Performance and additional checks (detailed mode)
if [ "$DETAILED" = true ]; then
    echo "⚡ Performance and Additional Checks"
    echo "-----------------------------------"

    # Check response times
    if command -v curl &> /dev/null; then
        local api_time
        api_time=$(curl -s -w "%{time_total}" "https://ludora-api.fly.dev/health" -o /dev/null --max-time 5 2>/dev/null || echo "timeout")

        if [ "$api_time" != "timeout" ]; then
            local time_ms
            time_ms=$(echo "$api_time * 1000" | bc 2>/dev/null || echo "unknown")
            if (( $(echo "$api_time < 2" | bc -l 2>/dev/null || echo 0) )); then
                log_result "PASS" "API response time" "${time_ms}ms"
            else
                log_result "WARN" "API response time is slow" "${time_ms}ms"
            fi
        else
            log_result "FAIL" "API response time check" "Request timed out"
        fi

        # Check if services are using HTTPS
        if curl -s -I "https://ludora-front.fly.dev" | grep -q "HTTP/2 200"; then
            log_result "PASS" "Frontend HTTPS/HTTP2"
        else
            log_result "WARN" "Frontend HTTPS/HTTP2 check"
        fi
    fi

    echo ""
fi

# 7. Summary
echo "📊 Health Check Summary"
echo "======================="
echo "📅 Completed at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "🧪 Total checks: $TOTAL_CHECKS"
echo -e "✅ ${GREEN}Passed: $PASSED_CHECKS${NC}"

if [ $WARNING_CHECKS -gt 0 ]; then
    echo -e "⚠️  ${YELLOW}Warnings: $WARNING_CHECKS${NC}"
fi

if [ $FAILED_CHECKS -gt 0 ]; then
    echo -e "❌ ${RED}Failed: $FAILED_CHECKS${NC}"
fi

echo ""

# Overall health status
if [ $FAILED_CHECKS -eq 0 ]; then
    if [ $WARNING_CHECKS -eq 0 ]; then
        echo -e "🎉 ${GREEN}Overall Status: HEALTHY${NC}"
        exit 0
    else
        echo -e "⚠️  ${YELLOW}Overall Status: HEALTHY (with warnings)${NC}"
        exit 0
    fi
else
    echo -e "🚨 ${RED}Overall Status: UNHEALTHY${NC}"
    echo ""
    echo "💡 Troubleshooting suggestions:"
    echo "  - Check failed services with: ./scripts/logs.sh"
    echo "  - Verify app status with: ./scripts/status.sh"
    echo "  - SSH into services with: ./scripts/ssh-api.sh or ./scripts/ssh-frontend.sh"
    exit 1
fi