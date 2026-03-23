#!/usr/bin/env bash
# =============================================================
# test-submission-workflow.sh — Тест workflow подачи статьи
# через OJS 3.4.x REST API
# Проект: JRNL-2026 | Агент: QAUTO
# =============================================================
# Использование:
#   ./test-submission-workflow.sh BASE_URL ADMIN_API_KEY
#   ./test-submission-workflow.sh http://localhost:8080 abc123secret
#
# ВНИМАНИЕ: Тест создаёт тестовые данные (пользователь, подача).
#           Запускать ТОЛЬКО на dev/staging среде!
# =============================================================

set -uo pipefail

BASE_URL="${1:-}"
ADMIN_API_KEY="${2:-}"

if [[ -z "$BASE_URL" || -z "$ADMIN_API_KEY" ]]; then
    echo "Использование: $0 <BASE_URL> <ADMIN_API_KEY>"
    echo "Пример:        $0 http://localhost:8080 your_api_key_here"
    exit 2
fi

BASE_URL="${BASE_URL%/}"
API_URL="${BASE_URL}/api/v1"

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

# --- Временные данные ---
TIMESTAMP=$(date +%s)
TEST_USERNAME="testauthor_${TIMESTAMP}"
TEST_EMAIL="testauthor_${TIMESTAMP}@test.example.com"
TEST_PASSWORD="TestPass123!"
TEST_GIVEN_NAME="[TEST] Author"
TEST_FAMILY_NAME="Automated_${TIMESTAMP}"
SUBMISSION_ID=""
FILE_ID=""

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

# ====================================================================
echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  REGRESSION TEST — Submission Workflow (OJS API)    ║${NC}"
echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo "  Base URL: $BASE_URL"
echo "  API URL:  $API_URL"
echo "  Date:     $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# ====================================================================
# Шаг 0: Проверить доступность API
# ====================================================================
section "Шаг 0: Проверка доступности API"

API_CHECK=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    -H "Authorization: Bearer ${ADMIN_API_KEY}" \
    "${API_URL}/contexts" 2>/dev/null) || API_CHECK="000"

if [[ "$API_CHECK" == "200" ]]; then
    pass "API доступен (HTTP $API_CHECK)"
else
    fail "API недоступен (HTTP $API_CHECK) — дальнейшие тесты могут не пройти"
fi

# Получить context (journal) ID
CONTEXT_RESPONSE=$(curl -s --max-time 10 \
    -H "Authorization: Bearer ${ADMIN_API_KEY}" \
    "${API_URL}/contexts" 2>/dev/null) || CONTEXT_RESPONSE=""

CONTEXT_ID=$(echo "$CONTEXT_RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    items = data.get('items', data) if isinstance(data, dict) else data
    if isinstance(items, list) and len(items) > 0:
        print(items[0].get('id', 1))
    else:
        print(1)
except:
    print(1)
" 2>/dev/null) || CONTEXT_ID="1"

info "Context ID: $CONTEXT_ID"

# ====================================================================
# Шаг 1: Регистрация тестового пользователя
# ====================================================================
section "Шаг 1: Регистрация тестового пользователя"

info "Username: $TEST_USERNAME"
info "Email: $TEST_EMAIL"

USER_RESPONSE=$(curl -s -w "\n%{http_code}" --max-time 15 \
    -X POST \
    -H "Authorization: Bearer ${ADMIN_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{
        \"userName\": \"${TEST_USERNAME}\",
        \"email\": \"${TEST_EMAIL}\",
        \"password\": \"${TEST_PASSWORD}\",
        \"givenName\": {\"en_US\": \"${TEST_GIVEN_NAME}\", \"ru_RU\": \"${TEST_GIVEN_NAME}\"},
        \"familyName\": {\"en_US\": \"${TEST_FAMILY_NAME}\", \"ru_RU\": \"${TEST_FAMILY_NAME}\"},
        \"affiliation\": {\"en_US\": \"[TEST] ZhezU\", \"ru_RU\": \"[TEST] ЖезУ\"},
        \"country\": \"KZ\"
    }" \
    "${API_URL}/users" 2>/dev/null) || USER_RESPONSE=$'\n000'

USER_HTTP=$(echo "$USER_RESPONSE" | tail -1)
USER_BODY=$(echo "$USER_RESPONSE" | sed '$d')

if [[ "$USER_HTTP" == "200" || "$USER_HTTP" == "201" ]]; then
    pass "Пользователь создан (HTTP $USER_HTTP)"
    USER_ID=$(echo "$USER_BODY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null) || USER_ID=""
    info "User ID: $USER_ID"
else
    fail "Ошибка создания пользователя (HTTP $USER_HTTP)"
    info "Response: $(echo "$USER_BODY" | head -c 300)"
fi

# ====================================================================
# Шаг 2: Авторизация (получить API key)
# ====================================================================
section "Шаг 2: Авторизация"

# В OJS 3.4.x авторизация через API key или CSRF token.
# Используем admin API key для дальнейших операций от имени пользователя,
# т.к. OJS REST API не предоставляет прямого endpoint для получения токена.
# В реальном сценарии пользователь использует UI для входа.

AUTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    -H "Authorization: Bearer ${ADMIN_API_KEY}" \
    "${API_URL}/users/${TEST_USERNAME}" 2>/dev/null) || AUTH_CHECK="000"

if [[ "$AUTH_CHECK" == "200" ]]; then
    pass "Авторизация с API key работает (HTTP $AUTH_CHECK)"
else
    fail "Авторизация не работает (HTTP $AUTH_CHECK)"
fi

# ====================================================================
# Шаг 3: Создание новой подачи (submission)
# ====================================================================
section "Шаг 3: Создание подачи (submission)"

SUBMISSION_RESPONSE=$(curl -s -w "\n%{http_code}" --max-time 15 \
    -X POST \
    -H "Authorization: Bearer ${ADMIN_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{
        \"contextId\": ${CONTEXT_ID},
        \"sectionId\": 1,
        \"locale\": \"ru_RU\",
        \"title\": {
            \"ru_RU\": \"[TEST] Тестовая статья ${TIMESTAMP}\",
            \"en_US\": \"[TEST] Test article ${TIMESTAMP}\"
        },
        \"abstract\": {
            \"ru_RU\": \"Автоматически созданная тестовая статья для regression-теста.\",
            \"en_US\": \"Automatically created test article for regression testing.\"
        }
    }" \
    "${API_URL}/submissions" 2>/dev/null) || SUBMISSION_RESPONSE=$'\n000'

SUB_HTTP=$(echo "$SUBMISSION_RESPONSE" | tail -1)
SUB_BODY=$(echo "$SUBMISSION_RESPONSE" | sed '$d')

if [[ "$SUB_HTTP" == "200" || "$SUB_HTTP" == "201" ]]; then
    SUBMISSION_ID=$(echo "$SUB_BODY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null) || SUBMISSION_ID=""
    pass "Подача создана (HTTP $SUB_HTTP, ID: $SUBMISSION_ID)"
else
    fail "Ошибка создания подачи (HTTP $SUB_HTTP)"
    info "Response: $(echo "$SUB_BODY" | head -c 500)"
fi

# ====================================================================
# Шаг 4: Загрузка файла рукописи
# ====================================================================
section "Шаг 4: Загрузка файла рукописи"

if [[ -n "$SUBMISSION_ID" ]]; then
    # Создать временный тестовый PDF-файл
    TEMP_FILE=$(mktemp /tmp/test-manuscript-XXXXXX.pdf)
    # Минимальный валидный PDF
    cat > "$TEMP_FILE" << 'PDFEOF'
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] >>
endobj
xref
0 4
0000000000 65535 f
0000000009 00000 n
0000000058 00000 n
0000000115 00000 n
trailer
<< /Size 4 /Root 1 0 R >>
startxref
190
%%EOF
PDFEOF

    FILE_RESPONSE=$(curl -s -w "\n%{http_code}" --max-time 30 \
        -X POST \
        -H "Authorization: Bearer ${ADMIN_API_KEY}" \
        -F "file=@${TEMP_FILE};type=application/pdf;filename=test-manuscript.pdf" \
        -F "name={\"ru_RU\":\"test-manuscript.pdf\",\"en_US\":\"test-manuscript.pdf\"}" \
        -F "fileStage=2" \
        -F "genreId=1" \
        "${API_URL}/submissions/${SUBMISSION_ID}/files" 2>/dev/null) || FILE_RESPONSE=$'\n000'

    FILE_HTTP=$(echo "$FILE_RESPONSE" | tail -1)
    FILE_BODY=$(echo "$FILE_RESPONSE" | sed '$d')

    rm -f "$TEMP_FILE"

    if [[ "$FILE_HTTP" == "200" || "$FILE_HTTP" == "201" ]]; then
        FILE_ID=$(echo "$FILE_BODY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null) || FILE_ID=""
        pass "Файл загружен (HTTP $FILE_HTTP, File ID: $FILE_ID)"
    else
        fail "Ошибка загрузки файла (HTTP $FILE_HTTP)"
        info "Response: $(echo "$FILE_BODY" | head -c 500)"
    fi
else
    fail "Загрузка файла пропущена — нет ID подачи"
fi

# ====================================================================
# Шаг 5: Проверка статуса подачи
# ====================================================================
section "Шаг 5: Проверка статуса подачи"

if [[ -n "$SUBMISSION_ID" ]]; then
    STATUS_RESPONSE=$(curl -s -w "\n%{http_code}" --max-time 10 \
        -H "Authorization: Bearer ${ADMIN_API_KEY}" \
        "${API_URL}/submissions/${SUBMISSION_ID}" 2>/dev/null) || STATUS_RESPONSE=$'\n000'

    STATUS_HTTP=$(echo "$STATUS_RESPONSE" | tail -1)
    STATUS_BODY=$(echo "$STATUS_RESPONSE" | sed '$d')

    if [[ "$STATUS_HTTP" == "200" ]]; then
        pass "Статус подачи получен (HTTP $STATUS_HTTP)"

        # Проверить поля
        SUB_STATUS=$(echo "$STATUS_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status',''), d.get('stageId',''))" 2>/dev/null) || SUB_STATUS=""
        info "Статус подачи: $SUB_STATUS"

        # Проверить что submission содержит наш title
        SUB_TITLE=$(echo "$STATUS_BODY" | python3 -c "
import sys,json
d=json.load(sys.stdin)
pubs = d.get('publications', [])
if pubs:
    t = pubs[0].get('title', pubs[0].get('fullTitle', {}))
    if isinstance(t, dict):
        print(t.get('ru_RU', t.get('en_US', '')))
    else:
        print(t)
else:
    print('')
" 2>/dev/null) || SUB_TITLE=""

        if echo "$SUB_TITLE" | grep -q "TEST"; then
            pass "Подача содержит корректный заголовок"
        else
            fail "Заголовок подачи не найден или некорректный"
            info "Title: $SUB_TITLE"
        fi
    else
        fail "Не удалось получить статус подачи (HTTP $STATUS_HTTP)"
        info "Response: $(echo "$STATUS_BODY" | head -c 300)"
    fi
else
    fail "Проверка статуса пропущена — нет ID подачи"
fi

# ====================================================================
# Шаг 6: Очистка (удаление тестовых данных)
# ====================================================================
section "Шаг 6: Очистка тестовых данных"

if [[ -n "$SUBMISSION_ID" ]]; then
    DEL_SUB=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
        -X DELETE \
        -H "Authorization: Bearer ${ADMIN_API_KEY}" \
        "${API_URL}/submissions/${SUBMISSION_ID}" 2>/dev/null) || DEL_SUB="000"
    info "Удаление подачи: HTTP $DEL_SUB"
fi

if [[ -n "${USER_ID:-}" ]]; then
    DEL_USER=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
        -X DELETE \
        -H "Authorization: Bearer ${ADMIN_API_KEY}" \
        "${API_URL}/users/${USER_ID}" 2>/dev/null) || DEL_USER="000"
    info "Удаление пользователя: HTTP $DEL_USER"
fi

# ====================================================================
# ИТОГОВЫЙ ОТЧЁТ
# ====================================================================
echo ""
echo -e "${YELLOW}══════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  ИТОГОВЫЙ ОТЧЁТ — Submission Workflow${NC}"
echo -e "${YELLOW}══════════════════════════════════════════════════${NC}"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo -e "  ${GREEN}Результат: $PASSED/$TOTAL PASSED${NC}"
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
