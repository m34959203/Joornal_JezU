#!/usr/bin/env bash
# check-health.sh — Healthcheck for OJS + MySQL + Disk + SSL
# Usage: ./scripts/check-health.sh [BASE_URL] [MYSQL_HOST] [MYSQL_USER] [MYSQL_PASS] [MYSQL_DB]
set -euo pipefail

BASE_URL="${1:-http://localhost:8080}"
MYSQL_HOST="${2:-127.0.0.1}"
MYSQL_USER="${3:-ojs}"
MYSQL_PASS="${4:-}"
MYSQL_DB="${5:-ojs}"
DISK_THRESHOLD=90
ERRORS=0

green()  { printf "\033[32m%s\033[0m\n" "$*"; }
red()    { printf "\033[31m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }

echo "============================================"
echo "  OJS Health Check  —  $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"
echo ""

# ── 1. OJS HTTP ──────────────────────────────────────────
echo -n "[HTTP]  OJS at ${BASE_URL} ... "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${BASE_URL}" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    green "OK (HTTP ${HTTP_CODE})"
else
    red "FAIL (HTTP ${HTTP_CODE})"
    ((ERRORS++))
fi

# ── 2. MySQL ─────────────────────────────────────────────
echo -n "[MySQL] Connection to ${MYSQL_HOST}/${MYSQL_DB} ... "
if command -v mysqladmin &>/dev/null; then
    if mysqladmin ping -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASS" --silent 2>/dev/null; then
        green "OK"
    else
        red "FAIL (cannot connect)"
        ((ERRORS++))
    fi
elif command -v docker &>/dev/null; then
    # Try via docker container named 'ojs-db' or 'db'
    DB_CONTAINER=$(docker ps --filter "name=db" --format "{{.Names}}" 2>/dev/null | head -1)
    if [ -n "$DB_CONTAINER" ]; then
        if docker exec "$DB_CONTAINER" mysqladmin ping -u "$MYSQL_USER" -p"$MYSQL_PASS" --silent 2>/dev/null; then
            green "OK (via docker: ${DB_CONTAINER})"
        else
            red "FAIL (docker container ${DB_CONTAINER} — cannot ping)"
            ((ERRORS++))
        fi
    else
        yellow "SKIP (no mysql client, no db container found)"
    fi
else
    yellow "SKIP (mysqladmin not available)"
fi

# ── 3. Disk space ────────────────────────────────────────
echo -n "[Disk]  Usage on / ... "
DISK_USED=$(df / | awk 'NR==2 {gsub(/%/,""); print $5}')
if [ "$DISK_USED" -lt "$DISK_THRESHOLD" ]; then
    green "OK (${DISK_USED}% used, threshold ${DISK_THRESHOLD}%)"
else
    red "WARNING (${DISK_USED}% used — above ${DISK_THRESHOLD}% threshold)"
    ((ERRORS++))
fi

# ── 4. SSL certificate ──────────────────────────────────
DOMAIN=$(echo "$BASE_URL" | sed -E 's|https?://||;s|[:/].*||')
if echo "$BASE_URL" | grep -q "^https"; then
    echo -n "[SSL]   Certificate for ${DOMAIN} ... "
    EXPIRY=$(echo | openssl s_client -servername "$DOMAIN" -connect "${DOMAIN}:443" 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null \
        | sed 's/notAfter=//')
    if [ -n "$EXPIRY" ]; then
        EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s 2>/dev/null || echo 0)
        NOW_EPOCH=$(date +%s)
        DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))
        if [ "$DAYS_LEFT" -gt 14 ]; then
            green "OK (expires in ${DAYS_LEFT} days — ${EXPIRY})"
        elif [ "$DAYS_LEFT" -gt 0 ]; then
            yellow "WARNING (expires in ${DAYS_LEFT} days — ${EXPIRY})"
            ((ERRORS++))
        else
            red "FAIL (certificate expired: ${EXPIRY})"
            ((ERRORS++))
        fi
    else
        red "FAIL (cannot read certificate)"
        ((ERRORS++))
    fi
else
    echo -n "[SSL]   "
    yellow "SKIP (not HTTPS)"
fi

# ── Summary ──────────────────────────────────────────────
echo ""
echo "--------------------------------------------"
if [ "$ERRORS" -eq 0 ]; then
    green "All checks passed."
else
    red "${ERRORS} check(s) failed."
fi
exit "$ERRORS"
