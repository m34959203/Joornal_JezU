#!/usr/bin/env bash
# =============================================================
# test-search.sh — Тест поисковой системы OJS
# Проект: JRNL-2026 | Агент: QAUTO
# =============================================================
# Использование:
#   ./test-search.sh [BASE_URL]
#   ./test-search.sh http://localhost:8080
# =============================================================

set -uo pipefail

BASE_URL="${1:-http://localhost:8080}"
BASE_URL="${BASE_URL%/}"
SEARCH_URL="${BASE_URL}/search/search"

# --- Цвета ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

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

info() {
    echo -e "  ${CYAN}[INFO]${NC} $1"
}

section() {
    echo ""
    echo -e "${CYAN}=== $1 ===${NC}"
}

# Выполнить поиск и вернуть HTTP code + body
# Аргументы: query [дополнительные_параметры_curl]
do_search() {
    local query="$1"
    shift
    curl -s --max-time 15 -L \
        --data-urlencode "query=${query}" \
        "$@" \
        "${SEARCH_URL}" 2>/dev/null
}

# Проверить что поиск возвращает HTTP 200 и валидный HTML
# Аргументы: описание, query
check_search_http() {
    local desc="$1"
    local query="$2"
    local status

    status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 -L \
        --data-urlencode "query=${query}" \
        "${SEARCH_URL}" 2>/dev/null) || status="000"

    if [[ "$status" == "200" ]]; then
        pass "$desc — HTTP 200"
        return 0
    else
        fail "$desc — HTTP $status (ожидался 200)"
        return 1
    fi
}

# Проверить что поиск содержит/не содержит указанный текст
# Аргументы: описание, query, expected_pattern, should_find (1=yes, 0=no)
check_search_content() {
    local desc="$1"
    local query="$2"
    local pattern="$3"
    local should_find="${4:-1}"
    local body

    body=$(do_search "$query") || body=""

    if [[ "$should_find" == "1" ]]; then
        if echo "$body" | grep -qi "$pattern"; then
            pass "$desc — текст найден"
        else
            fail "$desc — текст '$pattern' не найден в результатах"
        fi
    else
        # Проверяем отсутствие результатов (должна быть пустая выдача)
        # OJS показывает "No results" / "Ничего не найдено" при пустом результате
        if echo "$body" | grep -qiE "(No results|Ничего не найдено|Нет результатов|Результаты не найдены|no items)"; then
            pass "$desc — корректно показывает отсутствие результатов"
        elif ! echo "$body" | grep -qi "$pattern"; then
            pass "$desc — текст корректно отсутствует"
        else
            fail "$desc — неожиданно найден текст '$pattern'"
        fi
    fi
}

# ====================================================================
echo -e "${YELLOW}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║     SEARCH TEST — Вестник ЖезУ (OJS 3.4.x)     ║${NC}"
echo -e "${YELLOW}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo "  Base URL:   $BASE_URL"
echo "  Search URL: $SEARCH_URL"
echo "  Date:       $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# ====================================================================
# 1. Базовая доступность поиска
# ====================================================================
section "1. Доступность поискового интерфейса"

# GET запрос к /search
SEARCH_PAGE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 -L \
    "${BASE_URL}/search" 2>/dev/null) || SEARCH_PAGE_STATUS="000"

if [[ "$SEARCH_PAGE_STATUS" == "200" ]]; then
    pass "Страница поиска доступна (HTTP 200)"
else
    fail "Страница поиска недоступна (HTTP $SEARCH_PAGE_STATUS)"
fi

# Проверить что на странице есть форма поиска
SEARCH_PAGE_BODY=$(curl -s --max-time 10 -L "${BASE_URL}/search" 2>/dev/null) || SEARCH_PAGE_BODY=""
if echo "$SEARCH_PAGE_BODY" | grep -qiE '(<form|<input.*search|type="search"|name="query")'; then
    pass "Форма поиска присутствует на странице"
else
    fail "Форма поиска не найдена на странице"
fi

# ====================================================================
# 2. Поиск по названию статьи
# ====================================================================
section "2. Поиск по названию статьи"

check_search_http "Поиск по названию" "Вестник"

# Проверяем что поиск возвращает HTML с результатами или пустую выдачу
TITLE_BODY=$(do_search "Вестник") || TITLE_BODY=""
if echo "$TITLE_BODY" | grep -qiE "(<html|<body|<div)"; then
    pass "Поиск по названию возвращает валидный HTML"
else
    fail "Поиск по названию — невалидный ответ"
fi

# ====================================================================
# 3. Поиск по автору
# ====================================================================
section "3. Поиск по автору"

# OJS поддерживает поиск по авторам через параметр authors
AUTHOR_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 -L \
    --data-urlencode "authors=Иванов" \
    "${SEARCH_URL}" 2>/dev/null) || AUTHOR_STATUS="000"

if [[ "$AUTHOR_STATUS" == "200" ]]; then
    pass "Поиск по автору — HTTP 200"
else
    fail "Поиск по автору — HTTP $AUTHOR_STATUS"
fi

# Также проверяем через общий query
check_search_http "Поиск автора через общий запрос" "автор"

# ====================================================================
# 4. Поиск по ключевому слову
# ====================================================================
section "4. Поиск по ключевому слову"

check_search_http "Поиск по ключевому слову (наука)" "наука"
check_search_http "Поиск по ключевому слову (research)" "research"

# ====================================================================
# 5. Поиск по DOI
# ====================================================================
section "5. Поиск по DOI"

check_search_http "Поиск по DOI-паттерну" "10.1234/test"

DOI_BODY=$(do_search "10.1234/test") || DOI_BODY=""
if echo "$DOI_BODY" | grep -qiE "(<html|<body)"; then
    pass "Поиск по DOI возвращает валидный HTML"
else
    fail "Поиск по DOI — невалидный ответ"
fi

# ====================================================================
# 6. Поиск несуществующего
# ====================================================================
section "6. Поиск несуществующего"

NONSENSE_QUERY="xyzzy_nonexistent_${RANDOM}_zzzzqqqq"

check_search_http "Поиск несуществующего — HTTP 200" "$NONSENSE_QUERY"
check_search_content "Поиск несуществующего — пустая выдача" "$NONSENSE_QUERY" "xyzzy_nonexistent" 0

# ====================================================================
# 7. Поиск с кириллицей — корректная кодировка
# ====================================================================
section "7. Кириллица и кодировка"

CYRILLIC_QUERY="Исследование"

CYRILLIC_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 -L \
    --data-urlencode "query=${CYRILLIC_QUERY}" \
    "${SEARCH_URL}" 2>/dev/null) || CYRILLIC_STATUS="000"

if [[ "$CYRILLIC_STATUS" == "200" ]]; then
    pass "Поиск с кириллицей — HTTP 200"
else
    fail "Поиск с кириллицей — HTTP $CYRILLIC_STATUS"
fi

# Проверить что ответ в UTF-8 и кириллица не повреждена
CYRILLIC_BODY=$(do_search "$CYRILLIC_QUERY") || CYRILLIC_BODY=""

# Проверяем charset
if echo "$CYRILLIC_BODY" | grep -qiE '(charset=utf-8|charset="utf-8"|encoding="utf-8")'; then
    pass "Кодировка UTF-8 указана в ответе"
else
    # Проверим заголовок Content-Type
    CONTENT_TYPE=$(curl -s -o /dev/null -w "%{content_type}" --max-time 15 -L \
        --data-urlencode "query=${CYRILLIC_QUERY}" \
        "${SEARCH_URL}" 2>/dev/null) || CONTENT_TYPE=""

    if echo "$CONTENT_TYPE" | grep -qi "utf-8"; then
        pass "Кодировка UTF-8 в Content-Type заголовке"
    else
        fail "Кодировка UTF-8 не найдена (Content-Type: $CONTENT_TYPE)"
    fi
fi

# Проверить что кириллица в ответе не искажена (ищем типичные HTML-элементы на русском)
if echo "$CYRILLIC_BODY" | grep -qP '[\x{0400}-\x{04FF}]'; then
    pass "Кириллические символы присутствуют в ответе (не искажены)"
else
    fail "Кириллические символы не найдены в ответе — возможно проблема с кодировкой"
fi

# Казахская кириллица
KK_QUERY="Зерттеу"
KK_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 -L \
    --data-urlencode "query=${KK_QUERY}" \
    "${SEARCH_URL}" 2>/dev/null) || KK_STATUS="000"

if [[ "$KK_STATUS" == "200" ]]; then
    pass "Поиск с казахской кириллицей — HTTP 200"
else
    fail "Поиск с казахской кириллицей — HTTP $KK_STATUS"
fi

# ====================================================================
# 8. Расширенные параметры поиска OJS
# ====================================================================
section "8. Расширенные параметры поиска"

# Поиск с несколькими параметрами одновременно
MULTI_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 -L \
    --data-urlencode "query=тест" \
    --data-urlencode "authors=Иванов" \
    "${SEARCH_URL}" 2>/dev/null) || MULTI_STATUS="000"

if [[ "$MULTI_STATUS" == "200" ]]; then
    pass "Комбинированный поиск (query + authors) — HTTP 200"
else
    fail "Комбинированный поиск — HTTP $MULTI_STATUS"
fi

# Пустой запрос
EMPTY_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 -L \
    --data-urlencode "query=" \
    "${SEARCH_URL}" 2>/dev/null) || EMPTY_STATUS="000"

if [[ "$EMPTY_STATUS" == "200" ]]; then
    pass "Пустой поисковый запрос — HTTP 200 (не 500)"
else
    fail "Пустой поисковый запрос — HTTP $EMPTY_STATUS"
fi

# Специальные символы
SPECIAL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 -L \
    --data-urlencode "query=<script>alert(1)</script>" \
    "${SEARCH_URL}" 2>/dev/null) || SPECIAL_STATUS="000"

if [[ "$SPECIAL_STATUS" == "200" || "$SPECIAL_STATUS" == "400" ]]; then
    pass "Специальные символы в поиске не вызывают ошибку сервера (HTTP $SPECIAL_STATUS)"
else
    fail "Специальные символы — HTTP $SPECIAL_STATUS (возможная уязвимость)"
fi

# Проверим что XSS не отражается
XSS_BODY=$(do_search "<script>alert(1)</script>") || XSS_BODY=""
if echo "$XSS_BODY" | grep -q "<script>alert(1)</script>"; then
    fail "XSS — скрипт отражается в ответе без экранирования!"
else
    pass "XSS — скрипт не отражается (экранирование работает)"
fi

# ====================================================================
# ИТОГОВЫЙ ОТЧЁТ
# ====================================================================
echo ""
echo -e "${YELLOW}══════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  ИТОГОВЫЙ ОТЧЁТ — Search Tests${NC}"
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

[[ $FAILED -gt 0 ]] && exit 1
exit 0
