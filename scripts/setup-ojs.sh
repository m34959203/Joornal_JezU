#!/usr/bin/env bash
###############################################################################
# setup-ojs.sh — Первоначальная настройка OJS 3.4.x
#
# Выполняет:
#   1. Подстановку переменных из .env в config.inc.php
#   2. Создание директорий с правильными правами
#   3. Копирование темы zhezujournal
#   4. Копирование кастомных плагинов
#   5. Копирование казахской локали
#
# Использование:
#   ./scripts/setup-ojs.sh [--env-file .env]
#
# Запускать из корня проекта или внутри контейнера OJS.
###############################################################################
set -euo pipefail

# ─── Constants ───────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
OJS_ROOT="${OJS_ROOT:-/var/www/html}"
OJS_FILES="${OJS_FILES:-/var/www/files}"
TEMPLATE="${PROJECT_DIR}/docker/config.inc.php.template"
CONFIG_OUT="${OJS_ROOT}/config.inc.php"
ENV_FILE="${1:-.env}"

# ─── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[SETUP]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ─── Preflight checks ───────────────────────────────────────────────────────
if [[ ! -f "${TEMPLATE}" ]]; then
    err "Template not found: ${TEMPLATE}"
    exit 1
fi

if [[ "${ENV_FILE}" != "--"* ]] && [[ -f "${ENV_FILE}" ]]; then
    log "Loading environment from ${ENV_FILE}"
    set -a
    # shellcheck source=/dev/null
    source "${ENV_FILE}"
    set +a
elif [[ -f "${PROJECT_DIR}/.env" ]]; then
    log "Loading environment from ${PROJECT_DIR}/.env"
    set -a
    # shellcheck source=/dev/null
    source "${PROJECT_DIR}/.env"
    set +a
else
    warn "No .env file found — using current environment variables"
fi

# ─── Required variables ─────────────────────────────────────────────────────
REQUIRED_VARS=(
    OJS_BASE_URL
    OJS_DOMAIN
    DB_USER
    DB_PASSWORD
    DB_NAME
    API_KEY_SECRET
    SMTP_HOST
    SMTP_PORT
    SMTP_AUTH
    SMTP_USER
    SMTP_PASSWORD
    SMTP_ENCRYPTION
    SMTP_FROM
    OAI_REPOSITORY_ID
)

missing=0
for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        err "Missing required variable: ${var}"
        missing=1
    fi
done

if [[ "${missing}" -eq 1 ]]; then
    err "Set all required variables in .env and re-run."
    exit 1
fi

# ─── Step 1: Generate config.inc.php ────────────────────────────────────────
log "Generating config.inc.php from template..."

cp "${TEMPLATE}" "${CONFIG_OUT}"

# Substitute all %%VARIABLE%% placeholders with environment values
declare -A SUBSTITUTIONS=(
    [%%OJS_BASE_URL%%]="${OJS_BASE_URL}"
    [%%OJS_DOMAIN%%]="${OJS_DOMAIN}"
    [%%DB_USER%%]="${DB_USER}"
    [%%DB_PASSWORD%%]="${DB_PASSWORD}"
    [%%DB_NAME%%]="${DB_NAME}"
    [%%API_KEY_SECRET%%]="${API_KEY_SECRET}"
    [%%SMTP_HOST%%]="${SMTP_HOST}"
    [%%SMTP_PORT%%]="${SMTP_PORT}"
    [%%SMTP_AUTH%%]="${SMTP_AUTH}"
    [%%SMTP_USER%%]="${SMTP_USER}"
    [%%SMTP_PASSWORD%%]="${SMTP_PASSWORD}"
    [%%SMTP_ENCRYPTION%%]="${SMTP_ENCRYPTION}"
    [%%SMTP_FROM%%]="${SMTP_FROM}"
    [%%OAI_REPOSITORY_ID%%]="${OAI_REPOSITORY_ID}"
    [%%RECAPTCHA_PUBLIC_KEY%%]="${RECAPTCHA_PUBLIC_KEY:-}"
    [%%RECAPTCHA_PRIVATE_KEY%%]="${RECAPTCHA_PRIVATE_KEY:-}"
)

for placeholder in "${!SUBSTITUTIONS[@]}"; do
    value="${SUBSTITUTIONS[${placeholder}]}"
    # Escape sed special characters in value
    escaped_value=$(printf '%s\n' "${value}" | sed -e 's/[\/&]/\\&/g')
    sed -i "s/${placeholder}/${escaped_value}/g" "${CONFIG_OUT}"
done

chmod 600 "${CONFIG_OUT}"
log "config.inc.php generated at ${CONFIG_OUT}"

# ─── Step 2: Create directories ─────────────────────────────────────────────
log "Creating OJS directories..."

directories=(
    "${OJS_FILES}"
    "${OJS_FILES}/journals"
    "${OJS_FILES}/cache"
    "${OJS_FILES}/cache/t_cache"
    "${OJS_FILES}/cache/t_compile"
    "${OJS_FILES}/cache/db"
    "${OJS_ROOT}/public"
    "${OJS_ROOT}/cache"
    "${OJS_ROOT}/cache/t_cache"
    "${OJS_ROOT}/cache/t_compile"
)

for dir in "${directories[@]}"; do
    if [[ ! -d "${dir}" ]]; then
        mkdir -p "${dir}"
        log "  Created: ${dir}"
    fi
done

# Set ownership to www-data (web server user)
chown -R www-data:www-data "${OJS_FILES}"
chown -R www-data:www-data "${OJS_ROOT}/public"
chown -R www-data:www-data "${OJS_ROOT}/cache"
chmod -R 755 "${OJS_FILES}"
chmod -R 755 "${OJS_ROOT}/public"
chmod -R 755 "${OJS_ROOT}/cache"

log "Directories created with www-data ownership"

# ─── Step 3: Copy theme ─────────────────────────────────────────────────────
THEME_SRC="${PROJECT_DIR}/theme/zhezujournal"
THEME_DST="${OJS_ROOT}/plugins/themes/zhezujournal"

if [[ -d "${THEME_SRC}" ]]; then
    log "Copying theme zhezujournal..."
    mkdir -p "${THEME_DST}"
    cp -r "${THEME_SRC}/." "${THEME_DST}/"
    chown -R www-data:www-data "${THEME_DST}"
    log "  Theme installed to ${THEME_DST}"
else
    warn "Theme source not found at ${THEME_SRC} — skipping"
fi

# ─── Step 4: Copy custom plugins ────────────────────────────────────────────
PLUGINS_SRC="${PROJECT_DIR}/plugins/generic"
PLUGINS_DST="${OJS_ROOT}/plugins/generic"

if [[ -d "${PLUGINS_SRC}" ]]; then
    log "Copying custom plugins..."
    for plugin_dir in "${PLUGINS_SRC}"/*/; do
        plugin_name=$(basename "${plugin_dir}")
        mkdir -p "${PLUGINS_DST}/${plugin_name}"
        cp -r "${plugin_dir}." "${PLUGINS_DST}/${plugin_name}/"
        chown -R www-data:www-data "${PLUGINS_DST}/${plugin_name}"
        log "  Plugin installed: ${plugin_name}"
    done
else
    warn "No custom plugins found at ${PLUGINS_SRC} — skipping"
fi

# ─── Step 5: Copy Kazakh locale ─────────────────────────────────────────────
LOCALE_SRC="${PROJECT_DIR}/locales/kk"
LOCALE_DST="${OJS_ROOT}/locale/kk"

if [[ -d "${LOCALE_SRC}" ]]; then
    log "Copying Kazakh locale..."
    mkdir -p "${LOCALE_DST}"
    cp -r "${LOCALE_SRC}/." "${LOCALE_DST}/"
    chown -R www-data:www-data "${LOCALE_DST}"
    log "  Kazakh locale installed to ${LOCALE_DST}"
else
    warn "Kazakh locale not found at ${LOCALE_SRC} — skipping"
fi

# ─── Done ────────────────────────────────────────────────────────────────────
echo ""
log "=========================================="
log "  OJS Setup Complete!"
log "=========================================="
echo ""
echo "Next steps:"
echo "  1. Start the Docker containers:"
echo "       docker compose up -d"
echo ""
echo "  2. If this is a fresh install, open the browser:"
echo "       ${OJS_BASE_URL}/index.php/index/install"
echo ""
echo "  3. In the web installer, verify:"
echo "       - Database settings match your .env"
echo "       - Admin account is created"
echo "       - Primary locale: ru_RU"
echo ""
echo "  4. After install, create the journal:"
echo "       Settings → Site → Hosted Journals → Create Journal"
echo "       - Path: vestnik"
echo "       - Languages: ru_RU, kk, en_US"
echo ""
echo "  5. Enable the theme:"
echo "       Settings → Website → Appearance → zhezujournal"
echo ""
echo "  6. Set up scheduled tasks cron:"
echo "       0 */4 * * * php ${OJS_ROOT}/tools/runScheduledTasks.php"
echo ""
echo "  7. Rebuild search index:"
echo "       php ${OJS_ROOT}/tools/rebuildSearchIndex.php"
echo ""
log "Done. Happy publishing!"
