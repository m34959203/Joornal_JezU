#!/usr/bin/env bash
# =============================================================================
# ssl-renew.sh — Обновление SSL-сертификата Let's Encrypt (JRNL-2026)
# Агент: SEC (agents/15-SEC.md)
# Правила: rules/03-security.md
#
# Использование:
#   ./ssl-renew.sh
#
# Cron (ежедневно в 04:00):
#   0 4 * * * /path/to/scripts/ssl-renew.sh >> /var/log/ssl-renew.log 2>&1
# =============================================================================

set -euo pipefail

# --- Конфигурация ---
LOG_FILE="/var/log/ssl-renew.log"
NGINX_CONTAINER="${NGINX_CONTAINER:-jrnl-nginx}"
COMPOSE_DIR="${COMPOSE_DIR:-/home/ubuntu/Joornal_JezU/docker}"

# --- Функции ---
timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

log_info() {
    echo "[$(timestamp)] [INFO] $1"
}

log_error() {
    echo "[$(timestamp)] [ERROR] $1" >&2
}

log_ok() {
    echo "[$(timestamp)] [OK] $1"
}

# =============================================================================
log_info "=== Начало обновления SSL-сертификата ==="

# --- Проверяем наличие certbot ---
if ! command -v certbot &>/dev/null; then
    # Попробуем через Docker
    if docker exec "$NGINX_CONTAINER" which certbot &>/dev/null 2>&1; then
        CERTBOT_CMD="docker exec $NGINX_CONTAINER certbot"
        log_info "Используем certbot из контейнера $NGINX_CONTAINER"
    else
        log_error "certbot не найден ни на хосте, ни в контейнере $NGINX_CONTAINER"
        exit 1
    fi
else
    CERTBOT_CMD="certbot"
    log_info "Используем certbot на хосте"
fi

# --- Получаем информацию о текущем сертификате (до обновления) ---
CERT_BEFORE=""
if $CERTBOT_CMD certificates 2>/dev/null | grep -q "Expiry Date"; then
    CERT_BEFORE=$($CERTBOT_CMD certificates 2>/dev/null | grep "Expiry Date" | head -1 | tr -s ' ')
    log_info "Текущий сертификат: $CERT_BEFORE"
else
    log_info "Не удалось получить информацию о текущем сертификате"
fi

# --- Обновляем сертификат ---
log_info "Запуск certbot renew..."

RENEW_OUTPUT=$($CERTBOT_CMD renew --non-interactive 2>&1) || {
    RENEW_EXIT=$?
    log_error "certbot renew завершился с ошибкой (exit code: $RENEW_EXIT)"
    log_error "Вывод: $RENEW_OUTPUT"
    exit 1
}

log_info "certbot renew завершён успешно"

# --- Проверяем результат обновления ---
if echo "$RENEW_OUTPUT" | grep -q "No renewals were attempted"; then
    log_info "Обновление не требуется — сертификат ещё действителен"
elif echo "$RENEW_OUTPUT" | grep -q "Congratulations"; then
    log_ok "Сертификат успешно обновлён!"

    # --- Проверяем новый сертификат ---
    CERT_AFTER=""
    if $CERTBOT_CMD certificates 2>/dev/null | grep -q "Expiry Date"; then
        CERT_AFTER=$($CERTBOT_CMD certificates 2>/dev/null | grep "Expiry Date" | head -1 | tr -s ' ')
        log_info "Новый сертификат: $CERT_AFTER"
    fi
elif echo "$RENEW_OUTPUT" | grep -qi "renewed"; then
    log_ok "Сертификат обновлён"
else
    log_info "Результат certbot: $(echo "$RENEW_OUTPUT" | tail -3)"
fi

# --- Перезагружаем Nginx ---
log_info "Перезагрузка Nginx для применения нового сертификата..."

if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${NGINX_CONTAINER}$"; then
    # Nginx работает в Docker
    if docker exec "$NGINX_CONTAINER" nginx -t 2>&1; then
        docker exec "$NGINX_CONTAINER" nginx -s reload 2>&1
        log_ok "Nginx перезагружен (Docker: $NGINX_CONTAINER)"
    else
        log_error "Ошибка конфигурации Nginx — reload отменён"
        exit 1
    fi
elif command -v nginx &>/dev/null; then
    # Nginx на хосте
    if nginx -t 2>&1; then
        systemctl reload nginx 2>&1 || nginx -s reload 2>&1
        log_ok "Nginx перезагружен (хост)"
    else
        log_error "Ошибка конфигурации Nginx — reload отменён"
        exit 1
    fi
elif docker compose -f "$COMPOSE_DIR/docker-compose.yml" ps 2>/dev/null | grep -q nginx; then
    # Попробуем через docker compose
    docker compose -f "$COMPOSE_DIR/docker-compose.yml" exec nginx nginx -s reload 2>&1
    log_ok "Nginx перезагружен (docker compose)"
else
    log_error "Nginx не найден — не удалось выполнить reload"
    exit 1
fi

# --- Итог ---
log_info "=== Обновление SSL завершено ==="
