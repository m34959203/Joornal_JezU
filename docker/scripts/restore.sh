#!/usr/bin/env bash
# =============================================================
# OJS Restore Script
# Restores from backup: MySQL database + OJS files + config
# Usage: ./restore.sh <backup_path>
# =============================================================
set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[RESTORE]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
err() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }

# --- Check arguments ---
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <backup_path>"
    echo ""
    echo "Example: $0 /opt/backups/ojs/20260323_030000"
    echo ""
    echo "Available backups:"
    BACKUP_BASE="${BACKUP_DIR:-/opt/backups/ojs}"
    if [[ -d "$BACKUP_BASE" ]]; then
        ls -1d "$BACKUP_BASE"/*/ 2>/dev/null | while read -r d; do
            SIZE=$(du -sh "$d" 2>/dev/null | cut -f1)
            echo "  $(basename "$d")  ($SIZE)"
        done
    else
        echo "  No backups found in $BACKUP_BASE"
    fi
    exit 1
fi

BACKUP_PATH="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env if exists
if [[ -f "$COMPOSE_DIR/.env" ]]; then
    set -a
    source "$COMPOSE_DIR/.env"
    set +a
fi

DB_CONTAINER="ojs-db"
OJS_CONTAINER="ojs-app"

# --- Validate backup ---
if [[ ! -d "$BACKUP_PATH" ]]; then
    err "Backup directory not found: $BACKUP_PATH"
    exit 1
fi

if [[ ! -f "$BACKUP_PATH/database.sql.gz" ]]; then
    err "Database dump not found in backup: $BACKUP_PATH/database.sql.gz"
    exit 1
fi

# --- Verify checksums ---
if [[ -f "$BACKUP_PATH/checksums.sha256" ]]; then
    log "Verifying checksums..."
    cd "$BACKUP_PATH"
    if sha256sum -c checksums.sha256 --quiet 2>/dev/null; then
        log "Checksums OK"
    else
        err "Checksum verification FAILED. Backup may be corrupted."
        read -rp "Continue anyway? (y/N): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            exit 1
        fi
    fi
fi

# --- Confirmation ---
echo ""
warn "This will OVERWRITE the current OJS installation!"
echo ""
echo "Backup: $BACKUP_PATH"
echo "Contents:"
ls -lh "$BACKUP_PATH/"
echo ""
read -rp "Are you sure you want to restore? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    log "Restore cancelled."
    exit 0
fi

# --- Check containers ---
if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
    err "Container $DB_CONTAINER is not running. Start it first: docker compose up -d db"
    exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -q "^${OJS_CONTAINER}$"; then
    err "Container $OJS_CONTAINER is not running. Start it first: docker compose up -d ojs"
    exit 1
fi

# --- 1. Restore database ---
log "Restoring MySQL database..."
gunzip -c "$BACKUP_PATH/database.sql.gz" | docker exec -i "$DB_CONTAINER" \
    mysql -u root -p"${DB_ROOT_PASSWORD}" 2>/dev/null
log "Database restored."

# --- 2. Restore private files ---
if [[ -f "$BACKUP_PATH/private_files.tar.gz" ]]; then
    log "Restoring OJS private files..."
    gunzip -c "$BACKUP_PATH/private_files.tar.gz" | docker cp - "$OJS_CONTAINER":/var/
    log "Private files restored."
else
    warn "No private_files.tar.gz found, skipping."
fi

# --- 3. Restore public files ---
if [[ -f "$BACKUP_PATH/public_files.tar.gz" ]]; then
    log "Restoring OJS public files..."
    gunzip -c "$BACKUP_PATH/public_files.tar.gz" | docker cp - "$OJS_CONTAINER":/var/www/html/
    log "Public files restored."
else
    warn "No public_files.tar.gz found, skipping."
fi

# --- 4. Restore config ---
if [[ -f "$BACKUP_PATH/config.inc.php" ]]; then
    log "Restoring OJS config..."
    docker cp "$BACKUP_PATH/config.inc.php" "$OJS_CONTAINER":/var/www/html/config.inc.php
    log "Config restored."
else
    warn "No config.inc.php found, skipping."
fi

# --- 5. Fix permissions ---
log "Fixing file permissions..."
docker exec "$OJS_CONTAINER" chown -R www-data:www-data /var/private_files /var/www/html/public 2>/dev/null || true
docker exec "$OJS_CONTAINER" chmod 600 /var/www/html/config.inc.php 2>/dev/null || true

# --- Done ---
log "Restore complete from: $BACKUP_PATH"
log "Restart OJS to apply changes: docker compose restart ojs"
