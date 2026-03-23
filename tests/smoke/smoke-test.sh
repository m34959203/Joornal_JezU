#!/usr/bin/env bash
# smoke-test.sh — Basic smoke tests for OJS endpoints
# Usage: ./tests/smoke/smoke-test.sh [BASE_URL]
set -uo pipefail

BASE_URL="${1:-http://localhost:8080}"
PASSED=0
FAILED=0
TOTAL=0

check() {
    local label="$1"
    local path="$2"
    local url="${BASE_URL}${path}"
    ((TOTAL++))

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time 15 "$url" 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" = "200" ]; then
        printf "  \033[32mPASS\033[0m  %-30s  %s\n" "$label" "(HTTP ${HTTP_CODE})"
        ((PASSED++))
    else
        printf "  \033[31mFAIL\033[0m  %-30s  %s\n" "$label" "(HTTP ${HTTP_CODE})"
        ((FAILED++))
    fi
}

echo "============================================"
echo "  OJS Smoke Tests  —  $(date '+%Y-%m-%d %H:%M:%S')"
echo "  Target: ${BASE_URL}"
echo "============================================"
echo ""

check "Home page"        "/"
check "About"            "/about"
check "Issue archive"    "/issue/archive"
check "Search"           "/search"
check "Login"            "/login"

echo ""
echo "--------------------------------------------"
echo "  Total: ${TOTAL}  |  Passed: ${PASSED}  |  Failed: ${FAILED}"
echo "--------------------------------------------"

if [ "$FAILED" -gt 0 ]; then
    printf "\033[31m  RESULT: %d test(s) failed\033[0m\n" "$FAILED"
    exit 1
else
    printf "\033[32m  RESULT: All tests passed\033[0m\n"
    exit 0
fi
