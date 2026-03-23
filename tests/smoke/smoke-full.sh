#!/usr/bin/env bash
# =============================================================
# smoke-full.sh — Расширенный smoke-тест для OJS (Вестник ЖезУ)
# Проект: JRNL-2026 | Агент: QAUTO
# =============================================================
# Использование:
#   ./smoke-full.sh [BASE_URL]
#   ./smoke-full.sh https://journal.zhezu.edu.kz
# =============================================================

set -euo pipefail

BASE_URL="${1:-http://localhost:8080}"
# Убрать trailing slash
BASE_URL="${BASE_URL%/}"

# --- Цвета ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Счётчики ---
TOTAL=0
PASSED=0
FAILED=0
FAIL_LIST=()

# --- Вспомогательные функции ---

pass() {
    TOTAL=$((TOTAL + 1))
    PASSED=$((PASSED + 1))
    echo -e "  ${GREEN}[PASS]${NC} $1"
}

fail() {
    TOTAL=$((TOTAL + 1))
    FAILED=$((FAILED + 1))
    FAIL_LIST+=("$1")
    echo -e "  ${RED}[FAIL]${NC} $1"
}

section() {
    echo ""
    echo -e "${CYAN}=== $1 ===${NC}"
}

# Проверить HTTP status code для URL
# Аргументы: описание, URL, ожидаемый_код (default 200)
check_http() {
    local desc="$1"
    local url="$2"
    local expected="${3:-200}"
    local status

    status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 -L "$url" 2>/dev/null) || status="000"

    if [[ "$status" == "$expected" ]]; then
        pass "$desc (HTTP $status)"
    else
        fail "$desc (expected HTTP $expected, got $status)"
    fi
}

# Проверить что ответ содержит строку
# Аргументы: описание, URL, строка_для_поиска
check_contains() {
    local desc="$1"
    local url="$2"
    local needle="$3"
    local body

    body=$(curl -s --max-time 10 -L "$url" 2>/dev/null) || body=""

    if echo "$body" | grep -qi "$needle"; then
        pass "$desc"
    else
        fail "$desc (string '$needle' not found)"
    fi
}

# ====================================================================
echo -e "${YELLOW}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║     SMOKE TEST — Вестник ЖезУ (OJS 3.4.x)      ║${NC}"
echo -e "${YELLOW}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo "  Base URL: $BASE_URL"
echo "  Date:     $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# ====================================================================
# 1. Публичные страницы — HTTP 200
# ====================================================================
section "1. Публичные страницы (HTTP 200)"

PUBLIC_PAGES=(
    "/|Главная страница"
    "/about|О журнале"
    "/about/editorialTeam|Редколлегия"
    "/about/submissions|Правила подачи"
    "/about/contact|Контакты"
    "/issue/archive|Архив номеров"
    "/search|Поиск"
    "/login|Вход"
    "/user/register|Регистрация"
)

for entry in "${PUBLIC_PAGES[@]}"; do
    IFS='|' read -r path desc <<< "$entry"
    check_http "$desc ($path)" "${BASE_URL}${path}"
done

# ====================================================================
# 2. Ключевые элементы главной страницы
# ====================================================================
section "2. Ключевые элементы главной"

HOMEPAGE_BODY=$(curl -s --max-time 10 -L "$BASE_URL/" 2>/dev/null) || HOMEPAGE_BODY=""

# Title журнала (Вестник / Vestnik / Хабаршы)
if echo "$HOMEPAGE_BODY" | grep -qiE "(Вестник|Vestnik|Хабаршы|ЖезУ|ZhezU)"; then
    pass "Название журнала присутствует на главной"
else
    fail "Название журнала не найдено на главной"
fi

# Меню навигации
if echo "$HOMEPAGE_BODY" | grep -qiE "(<nav|class=\".*nav|id=\".*nav)"; then
    pass "Навигационное меню присутствует"
else
    fail "Навигационное меню не найдено"
fi

# Footer
if echo "$HOMEPAGE_BODY" | grep -qiE "(<footer|class=\".*footer|id=\".*footer)"; then
    pass "Footer присутствует"
else
    fail "Footer не найден"
fi

# HTML валидность (базовая — doctype + html tag)
if echo "$HOMEPAGE_BODY" | grep -qi "<!DOCTYPE html"; then
    pass "DOCTYPE присутствует"
else
    fail "DOCTYPE не найден"
fi

# ====================================================================
# 3. Переключение языков
# ====================================================================
section "3. Переключение языков"

# Русский
RU_BODY=$(curl -s --max-time 10 -L "${BASE_URL}/?setLocale=ru_RU" 2>/dev/null) || RU_BODY=""
if echo "$RU_BODY" | grep -qiE "(Главная|Архив|О журнале|Поиск|Вход)"; then
    pass "Русский язык (ru_RU) — русский текст присутствует"
else
    fail "Русский язык (ru_RU) — русский текст не найден"
fi

# Английский
EN_BODY=$(curl -s --max-time 10 -L "${BASE_URL}/?setLocale=en_US" 2>/dev/null) || EN_BODY=""
if echo "$EN_BODY" | grep -qiE "(Home|Archives|About|Search|Login)"; then
    pass "Английский язык (en_US) — английский текст присутствует"
else
    fail "Английский язык (en_US) — английский текст не найден"
fi

# Казахский
KK_BODY=$(curl -s --max-time 10 -L "${BASE_URL}/?setLocale=kk" 2>/dev/null) || KK_BODY=""
if echo "$KK_BODY" | grep -qiE "(Басты|Мұрағат|Журнал|Іздеу|Кіру)"; then
    pass "Казахский язык (kk) — казахский текст присутствует"
else
    fail "Казахский язык (kk) — казахский текст не найден"
fi

# ====================================================================
# 4. Поиск (POST /search)
# ====================================================================
section "4. Поиск"

SEARCH_BODY=$(curl -s --max-time 10 -L \
    -X POST \
    -d "query=test" \
    "${BASE_URL}/search/search" 2>/dev/null) || SEARCH_BODY=""

if echo "$SEARCH_BODY" | grep -qiE "(<html|search|результат|result|No results|Ничего не найдено)"; then
    pass "Поиск возвращает HTML-ответ"
else
    fail "Поиск не вернул корректный HTML"
fi

# Проверка GET-поиска тоже
SEARCH_GET=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 -L \
    "${BASE_URL}/search/search?query=test" 2>/dev/null) || SEARCH_GET="000"

if [[ "$SEARCH_GET" == "200" ]]; then
    pass "GET-поиск возвращает HTTP 200"
else
    fail "GET-поиск вернул HTTP $SEARCH_GET (ожидался 200)"
fi

# ====================================================================
# 5. HTTPS redirect
# ====================================================================
section "5. HTTPS redirect"

# Проверяем только если BASE_URL — https
if [[ "$BASE_URL" == https://* ]]; then
    HTTP_URL="${BASE_URL/https:\/\//http:\/\/}"
    REDIRECT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$HTTP_URL" 2>/dev/null) || REDIRECT_STATUS="000"

    if [[ "$REDIRECT_STATUS" == "301" || "$REDIRECT_STATUS" == "302" ]]; then
        pass "HTTP → HTTPS redirect (HTTP $REDIRECT_STATUS)"
    else
        fail "HTTP → HTTPS redirect не работает (HTTP $REDIRECT_STATUS)"
    fi

    # Проверить что redirect ведёт на HTTPS
    REDIRECT_LOCATION=$(curl -s -o /dev/null -w "%{redirect_url}" --max-time 10 "$HTTP_URL" 2>/dev/null) || REDIRECT_LOCATION=""
    if [[ "$REDIRECT_LOCATION" == https://* ]]; then
        pass "Redirect ведёт на HTTPS URL"
    else
        fail "Redirect не ведёт на HTTPS (location: $REDIRECT_LOCATION)"
    fi
else
    echo -e "  ${YELLOW}[SKIP]${NC} HTTPS redirect — BASE_URL не HTTPS, пропуск"
fi

# ====================================================================
# 6. PDF-файлы (если есть опубликованные статьи)
# ====================================================================
section "6. Доступность PDF"

# Ищем ссылки на PDF на странице архива
ARCHIVE_BODY=$(curl -s --max-time 10 -L "${BASE_URL}/issue/archive" 2>/dev/null) || ARCHIVE_BODY=""

# Извлечь первую ссылку на выпуск
ISSUE_LINK=$(echo "$ARCHIVE_BODY" | grep -oP 'href="[^"]*(/issue/view/[^"]*)"' | head -1 | grep -oP 'href="\K[^"]+')

if [[ -n "$ISSUE_LINK" ]]; then
    # Если ссылка относительная, сделать абсолютной
    if [[ "$ISSUE_LINK" != http* ]]; then
        ISSUE_LINK="${BASE_URL}${ISSUE_LINK}"
    fi

    ISSUE_BODY=$(curl -s --max-time 10 -L "$ISSUE_LINK" 2>/dev/null) || ISSUE_BODY=""

    # Ищем ссылку на PDF
    PDF_LINK=$(echo "$ISSUE_BODY" | grep -oP 'href="[^"]*\.(pdf|/download/[^"]*)"' | head -1 | grep -oP 'href="\K[^"]+')

    if [[ -n "$PDF_LINK" ]]; then
        if [[ "$PDF_LINK" != http* ]]; then
            PDF_LINK="${BASE_URL}${PDF_LINK}"
        fi

        PDF_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 -L "$PDF_LINK" 2>/dev/null) || PDF_STATUS="000"
        PDF_TYPE=$(curl -s -o /dev/null -w "%{content_type}" --max-time 15 -L "$PDF_LINK" 2>/dev/null) || PDF_TYPE=""

        if [[ "$PDF_STATUS" == "200" ]]; then
            pass "PDF файл доступен (HTTP 200)"
        else
            fail "PDF файл недоступен (HTTP $PDF_STATUS)"
        fi
    else
        echo -e "  ${YELLOW}[SKIP]${NC} PDF ссылки не найдены в выпуске"
    fi
else
    echo -e "  ${YELLOW}[SKIP]${NC} Нет опубликованных выпусков в архиве"
fi

# ====================================================================
# 7. API healthcheck
# ====================================================================
section "7. API healthcheck"

API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 -L \
    "${BASE_URL}/api/v1/_payments" 2>/dev/null) || API_STATUS="000"

# OJS API может вернуть 200, 403, или 404 — главное не 500/502/503
if [[ "$API_STATUS" != "000" && "$API_STATUS" != "500" && "$API_STATUS" != "502" && "$API_STATUS" != "503" ]]; then
    pass "OJS REST API отвечает (HTTP $API_STATUS)"
else
    fail "OJS REST API не отвечает (HTTP $API_STATUS)"
fi

# ====================================================================
# ИТОГОВЫЙ ОТЧЁТ
# ====================================================================
echo ""
echo -e "${YELLOW}══════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  ИТОГОВЫЙ ОТЧЁТ${NC}"
echo -e "${YELLOW}══════════════════════════════════════════════════${NC}"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo -e "  ${GREEN}Результат: $PASSED/$TOTAL PASSED — ВСЕ ТЕСТЫ ПРОЙДЕНЫ${NC}"
else
    echo -e "  ${RED}Результат: $PASSED/$TOTAL PASSED, $FAILED FAILED${NC}"
    echo ""
    echo -e "  ${RED}Список FAIL:${NC}"
    for f in "${FAIL_LIST[@]}"; do
        echo -e "    ${RED}- $f${NC}"
    done
fi

echo ""
echo "  Время: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Exit code: 0 если все pass, 1 если есть fail
if [[ $FAILED -gt 0 ]]; then
    exit 1
fi

exit 0
