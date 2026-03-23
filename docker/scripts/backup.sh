#!/usr/bin/env bash
# =============================================================
# OJS Backup Script
# Backs up: MySQL database + OJS files + config
# Rotation: keeps last N days (default 30)
# Usage: ./backup.sh [backup_dir] [retention_days]
# =============================================================
set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env if exists
if [[ -f "$COMPOSE_DIR/.env" ]]; then
    set -a
    source "$COMPOSE_DIR/.env"
    set +a
fi

BACKUP_DIR="${1:-${BACKUP_DIR:-/opt/backups/ojs}}"
RETENTION_DAYS="${2:-${BACKUP_RETENTION_DAYS:-30}}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_PATH="$BACKUP_DIR/$TIMESTAMP"

DB_CONTAINER="ojs-db"
OJS_CONTAINER="ojs-app"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[BACKUP]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
err() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }

# --- Pre-checks ---
if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
    err "Container $DB_CONTAINER is not running"
    exit 1
fi

# --- Create backup directory ---
mkdir -p "$BACKUP_PATH"
log "Starting backup to $BACKUP_PATH"

# --- 1. Database dump ---
log "Dumping MySQL database..."
docker exec "$DB_CONTAINER" mysqldump \
    -u root \
    -p"${DB_ROOT_PASSWORD}" \
    --single-transaction \
    --routines \
    --triggers \
    --databases "${DB_NAME}" \
    2>/dev/null | gzip > "$BACKUP_PATH/database.sql.gz"

DB_SIZE=$(du -sh "$BACKUP_PATH/database.sql.gz" 2>/dev/null | cut -f1)
log "Database dump: $DB_SIZE"

# --- 2. OJS private files ---
log "Backing up OJS private files..."
docker cp "$OJS_CONTAINER":/var/private_files - 2>/dev/null | gzip > "$BACKUP_PATH/private_files.tar.gz"
log "Private files: $(du -sh "$BACKUP_PATH/private_files.tar.gz" 2>/dev/null | cut -f1)"

# --- 3. OJS public files ---
log "Backing up OJS public files..."
docker cp "$OJS_CONTAINER":/var/www/html/public - 2>/dev/null | gzip > "$BACKUP_PATH/public_files.tar.gz"
log "Public files: $(du -sh "$BACKUP_PATH/public_files.tar.gz" 2>/dev/null | cut -f1)"

# --- 4. OJS config ---
log "Backing up OJS config..."
docker cp "$OJS_CONTAINER":/var/www/html/config.inc.php "$BACKUP_PATH/config.inc.php" 2>/dev/null || warn "config.inc.php not found"

# --- 5. Docker compose config ---
log "Backing up docker compose configs..."
cp "$COMPOSE_DIR/docker-compose.yml" "$BACKUP_PATH/" 2>/dev/null || true
cp "$COMPOSE_DIR/.env" "$BACKUP_PATH/env.backup" 2>/dev/null || true

# --- Create checksum ---
log "Generating checksums..."
cd "$BACKUP_PATH"
sha256sum *.gz *.php 2>/dev/null > checksums.sha256 || true

# --- Summary ---
TOTAL_SIZE=$(du -sh "$BACKUP_PATH" | cut -f1)
log "Backup complete: $BACKUP_PATH ($TOTAL_SIZE)"

# --- Rotation: delete old backups ---
if [[ -d "$BACKUP_DIR" ]]; then
    DELETED=0
    while IFS= read -r old_backup; do
        if [[ -d "$old_backup" ]]; then
            rm -rf "$old_backup"
            ((DELETED++))
        fi
    done < <(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +"$RETENTION_DAYS" 2>/dev/null)

    if [[ $DELETED -gt 0 ]]; then
        log "Rotated $DELETED old backup(s) (older than $RETENTION_DAYS days)"
    fi
fi

log "Done."
