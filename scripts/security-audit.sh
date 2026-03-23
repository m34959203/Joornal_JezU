#!/usr/bin/env bash
# =============================================================================
# security-audit.sh — Автоматический аудит безопасности JRNL-2026
# Агент: SEC (agents/15-SEC.md)
# Правила: rules/03-security.md
# =============================================================================

set -euo pipefail

# --- Конфигурация ---
BASE_URL="${1:-http://localhost:8080}"
# Убираем trailing slash
BASE_URL="${BASE_URL%/}"

# Определяем HTTPS URL (для проверок SSL)
if [[ "$BASE_URL" == http://* ]]; then
    HTTPS_URL="${BASE_URL/http:\/\//https:\/\/}"
else
    HTTPS_URL="$BASE_URL"
fi

# --- Счётчики ---
PASS=0
FAIL=0
WARN=0
TOTAL=0

# --- Цвета ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# --- Функции ---
log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASS++))
    ((TOTAL++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAIL++))
    ((TOTAL++))
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARN++))
    ((TOTAL++))
}

separator() {
    echo ""
    echo -e "${BOLD}=== $1 ===${NC}"
}

# =============================================================================
echo -e "${BOLD}Security Audit — JRNL-2026${NC}"
echo "URL: $BASE_URL"
echo "Дата: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================="

# =============================================================================
separator "1. HTTPS Redirect"
# =============================================================================

HTTP_URL="${HTTPS_URL/https:\/\//http:\/\/}"
HTTP_STATUS=$(curl -sI -o /dev/null -w "%{http_code}" --max-time 10 "$HTTP_URL" 2>/dev/null || echo "000")

if [[ "$HTTP_STATUS" == "301" || "$HTTP_STATUS" == "302" ]]; then
    REDIRECT_LOCATION=$(curl -sI --max-time 10 "$HTTP_URL" 2>/dev/null | grep -i "^location:" | head -1 | tr -d '\r')
    if echo "$REDIRECT_LOCATION" | grep -qi "https://"; then
        log_pass "HTTP → HTTPS redirect ($HTTP_STATUS → $REDIRECT_LOCATION)"
    else
        log_warn "HTTP redirect exists ($HTTP_STATUS) but not to HTTPS: $REDIRECT_LOCATION"
    fi
elif [[ "$HTTP_STATUS" == "000" ]]; then
    log_warn "HTTP port не отвечает (сервер может быть только HTTPS)"
else
    log_fail "HTTP не делает redirect на HTTPS (статус: $HTTP_STATUS, ожидался 301)"
fi

# =============================================================================
separator "2. Security Headers"
# =============================================================================

HEADERS=$(curl -sI --max-time 10 -k "$HTTPS_URL" 2>/dev/null || curl -sI --max-time 10 "$BASE_URL" 2>/dev/null || echo "")

if [[ -z "$HEADERS" ]]; then
    log_fail "Не удалось получить заголовки от $BASE_URL"
else
    # X-Frame-Options
    if echo "$HEADERS" | grep -qi "X-Frame-Options"; then
        VALUE=$(echo "$HEADERS" | grep -i "X-Frame-Options" | head -1 | tr -d '\r')
        log_pass "X-Frame-Options: $VALUE"
    else
        log_fail "X-Frame-Options отсутствует"
    fi

    # X-Content-Type-Options
    if echo "$HEADERS" | grep -qi "X-Content-Type-Options"; then
        VALUE=$(echo "$HEADERS" | grep -i "X-Content-Type-Options" | head -1 | tr -d '\r')
        log_pass "X-Content-Type-Options: $VALUE"
    else
        log_fail "X-Content-Type-Options отсутствует"
    fi

    # Strict-Transport-Security (HSTS)
    if echo "$HEADERS" | grep -qi "Strict-Transport-Security"; then
        VALUE=$(echo "$HEADERS" | grep -i "Strict-Transport-Security" | head -1 | tr -d '\r')
        log_pass "HSTS: $VALUE"
    else
        log_fail "Strict-Transport-Security (HSTS) отсутствует"
    fi

    # X-XSS-Protection
    if echo "$HEADERS" | grep -qi "X-XSS-Protection"; then
        VALUE=$(echo "$HEADERS" | grep -i "X-XSS-Protection" | head -1 | tr -d '\r')
        log_pass "X-XSS-Protection: $VALUE"
    else
        log_warn "X-XSS-Protection отсутствует (устаревший заголовок, но рекомендуется)"
    fi

    # Content-Security-Policy
    if echo "$HEADERS" | grep -qi "Content-Security-Policy"; then
        log_pass "Content-Security-Policy присутствует"
    else
        log_warn "Content-Security-Policy отсутствует"
    fi

    # Referrer-Policy
    if echo "$HEADERS" | grep -qi "Referrer-Policy"; then
        VALUE=$(echo "$HEADERS" | grep -i "Referrer-Policy" | head -1 | tr -d '\r')
        log_pass "Referrer-Policy: $VALUE"
    else
        log_warn "Referrer-Policy отсутствует"
    fi

    # Permissions-Policy
    if echo "$HEADERS" | grep -qi "Permissions-Policy"; then
        log_pass "Permissions-Policy присутствует"
    else
        log_warn "Permissions-Policy отсутствует"
    fi
fi

# =============================================================================
separator "3. Запрещённые файлы (должны возвращать 403)"
# =============================================================================

check_forbidden() {
    local path="$1"
    local description="$2"
    local status
    status=$(curl -sI -o /dev/null -w "%{http_code}" --max-time 10 -k "${BASE_URL}${path}" 2>/dev/null || echo "000")

    if [[ "$status" == "403" ]]; then
        log_pass "$description — 403 Forbidden"
    elif [[ "$status" == "404" ]]; then
        log_pass "$description — 404 Not Found (файл не найден, тоже безопасно)"
    elif [[ "$status" == "000" ]]; then
        log_warn "$description — сервер не отвечает"
    else
        log_fail "$description — статус $status (ожидался 403)"
    fi
}

check_forbidden "/config.inc.php" "config.inc.php"
check_forbidden "/.env" ".env"
check_forbidden "/.git/" ".git/"
check_forbidden "/.git/config" ".git/config"
check_forbidden "/.git/HEAD" ".git/HEAD"

# =============================================================================
separator "4. SSL сертификат"
# =============================================================================

DOMAIN=$(echo "$HTTPS_URL" | sed -E 's|https?://([^/:]+).*|\1|')

if command -v openssl &>/dev/null; then
    CERT_INFO=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:443" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "")

    if [[ -n "$CERT_INFO" ]]; then
        NOT_AFTER=$(echo "$CERT_INFO" | grep "notAfter" | cut -d= -f2)
        if [[ -n "$NOT_AFTER" ]]; then
            EXPIRY_EPOCH=$(date -d "$NOT_AFTER" +%s 2>/dev/null || echo "0")
            NOW_EPOCH=$(date +%s)
            DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

            if [[ $DAYS_LEFT -le 0 ]]; then
                log_fail "SSL сертификат ИСТЁК ($NOT_AFTER)"
            elif [[ $DAYS_LEFT -le 7 ]]; then
                log_fail "SSL сертификат истекает через $DAYS_LEFT дней ($NOT_AFTER)"
            elif [[ $DAYS_LEFT -le 30 ]]; then
                log_warn "SSL сертификат истекает через $DAYS_LEFT дней ($NOT_AFTER)"
            else
                log_pass "SSL сертификат валиден, истекает через $DAYS_LEFT дней ($NOT_AFTER)"
            fi
        else
            log_warn "Не удалось определить срок действия SSL"
        fi
    else
        log_warn "Не удалось подключиться к $DOMAIN:443 для проверки SSL"
    fi
else
    log_warn "openssl не установлен — пропуск проверки SSL"
fi

# =============================================================================
separator "5. XSS тестирование"
# =============================================================================

XSS_PAYLOAD='<script>alert(1)</script>'
XSS_ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$XSS_PAYLOAD'))" 2>/dev/null || echo "%3Cscript%3Ealert(1)%3C%2Fscript%3E")

XSS_RESPONSE=$(curl -sL --max-time 15 -k "${BASE_URL}/search?query=${XSS_ENCODED}" 2>/dev/null || echo "")

if [[ -z "$XSS_RESPONSE" ]]; then
    log_warn "Поиск не ответил — невозможно проверить XSS"
elif echo "$XSS_RESPONSE" | grep -qF '<script>alert(1)</script>'; then
    log_fail "XSS: тег <script> отражается без экранирования в ответе поиска!"
else
    log_pass "XSS: тег <script> не найден в ответе (экранирован или удалён)"
fi

# =============================================================================
separator "6. SQL Injection тестирование"
# =============================================================================

SQLI_PAYLOAD="' OR 1=1 --"
SQLI_ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote(\"' OR 1=1 --\"))" 2>/dev/null || echo "%27%20OR%201%3D1%20--")

# Получаем нормальный ответ для сравнения
NORMAL_RESPONSE=$(curl -sL --max-time 15 -k "${BASE_URL}/search?query=test12345nonexistent" 2>/dev/null || echo "")
SQLI_RESPONSE=$(curl -sL --max-time 15 -k "${BASE_URL}/search?query=${SQLI_ENCODED}" 2>/dev/null || echo "")

if [[ -z "$SQLI_RESPONSE" ]]; then
    log_warn "Поиск не ответил — невозможно проверить SQL Injection"
else
    # Проверяем признаки SQL ошибок
    if echo "$SQLI_RESPONSE" | grep -qiE "(sql syntax|mysql_|mysqli_|pg_query|ORA-[0-9]|syntax error|unclosed quotation|SQLSTATE)"; then
        log_fail "SQL Injection: обнаружены SQL-ошибки в ответе!"
    else
        # Сравниваем размеры ответов (если SQLi сработал, ответ будет значительно больше)
        NORMAL_SIZE=${#NORMAL_RESPONSE}
        SQLI_SIZE=${#SQLI_RESPONSE}

        if [[ $NORMAL_SIZE -gt 0 && $SQLI_SIZE -gt 0 ]]; then
            RATIO=0
            if [[ $NORMAL_SIZE -gt 0 ]]; then
                RATIO=$(( SQLI_SIZE * 100 / NORMAL_SIZE ))
            fi

            if [[ $RATIO -gt 300 ]]; then
                log_warn "SQL Injection: ответ на SQLi payload в ${RATIO}% больше нормального (возможная уязвимость)"
            else
                log_pass "SQL Injection: нет признаков уязвимости (нет SQL-ошибок, размер ответа в норме)"
            fi
        else
            log_pass "SQL Injection: нет SQL-ошибок в ответе"
        fi
    fi
fi

# =============================================================================
separator "ИТОГИ"
# =============================================================================

echo ""
echo "============================================="
echo -e "Всего проверок: ${BOLD}$TOTAL${NC}"
echo -e "  ${GREEN}PASS: $PASS${NC}"
echo -e "  ${RED}FAIL: $FAIL${NC}"
echo -e "  ${YELLOW}WARN: $WARN${NC}"
echo ""

if [[ $FAIL -eq 0 ]]; then
    if [[ $WARN -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}РЕЗУЛЬТАТ: ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ${NC}"
    else
        echo -e "${YELLOW}${BOLD}РЕЗУЛЬТАТ: ПРОЙДЕНО С ПРЕДУПРЕЖДЕНИЯМИ ($WARN)${NC}"
    fi
    exit 0
else
    echo -e "${RED}${BOLD}РЕЗУЛЬТАТ: ОБНАРУЖЕНЫ ПРОБЛЕМЫ ($FAIL FAIL, $WARN WARN)${NC}"
    echo ""
    echo "Рекомендации:"
    echo "  1. Исправить все FAIL-проверки перед деплоем на production"
    echo "  2. Проверить WARN-предупреждения и устранить по возможности"
    echo "  3. Перезапустить аудит после исправлений"
    exit 1
fi
