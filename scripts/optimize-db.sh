#!/usr/bin/env bash
# =============================================================
# optimize-db.sh — MySQL optimization for OJS
# Zhezkazgan University Journal
# =============================================================
# Usage: ./optimize-db.sh [mysql-container-name]
# Default container: ojs-db
# =============================================================

set -euo pipefail

# --- Configuration ---
CONTAINER="${1:-ojs-db}"
DB_NAME="${DB_NAME:-ojs}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Helper ---
log()  { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $*"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARN:${NC} $*"; }
err()  { echo -e "${RED}[$(date +'%H:%M:%S')] ERROR:${NC} $*" >&2; }

mysql_exec() {
    docker exec -i "${CONTAINER}" mysql \
        -u"${MYSQL_USER}" \
        ${MYSQL_PWD:+-p"${MYSQL_PWD}"} \
        --default-character-set=utf8mb4 \
        "$@"
}

# --- Pre-checks ---
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    err "Container '${CONTAINER}' is not running."
    echo "Usage: $0 [container-name]"
    exit 1
fi

echo ""
echo "============================================================="
echo "  MySQL Optimization — OJS Database"
echo "  Container: ${CONTAINER}"
echo "  Database:  ${DB_NAME}"
echo "  Date:      $(date +'%Y-%m-%d %H:%M:%S')"
echo "============================================================="
echo ""

# --- 1. Show database size ---
log "Database size:"
mysql_exec -e "
SELECT
    table_schema AS 'Database',
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)',
    COUNT(*) AS 'Tables'
FROM information_schema.tables
WHERE table_schema = '${DB_NAME}'
GROUP BY table_schema;
" 2>/dev/null
echo ""

# --- 2. Top 10 largest tables ---
log "Top 10 largest tables:"
mysql_exec -e "
SELECT
    table_name AS 'Table',
    ROUND((data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)',
    table_rows AS 'Rows (approx)',
    ROUND(data_free / 1024 / 1024, 2) AS 'Fragmented (MB)'
FROM information_schema.tables
WHERE table_schema = '${DB_NAME}'
ORDER BY (data_length + index_length) DESC
LIMIT 10;
" 2>/dev/null
echo ""

# --- 3. ANALYZE TABLE for all OJS tables ---
log "Running ANALYZE TABLE on all tables..."
TABLES=$(mysql_exec -N -e "
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = '${DB_NAME}'
      AND table_type = 'BASE TABLE'
    ORDER BY table_name;
" "${DB_NAME}" 2>/dev/null)

TABLE_COUNT=0
for TABLE in ${TABLES}; do
    TABLE_COUNT=$((TABLE_COUNT + 1))
done

CURRENT=0
for TABLE in ${TABLES}; do
    CURRENT=$((CURRENT + 1))
    printf "  [%d/%d] ANALYZE %s ... " "${CURRENT}" "${TABLE_COUNT}" "${TABLE}"
    RESULT=$(mysql_exec -N -e "ANALYZE TABLE \`${TABLE}\`;" "${DB_NAME}" 2>/dev/null | awk '{print $NF}')
    echo -e "${CYAN}${RESULT}${NC}"
done
echo ""

# --- 4. OPTIMIZE TABLE for fragmented tables ---
log "Checking for fragmented tables (>1MB free space)..."
FRAGMENTED=$(mysql_exec -N -e "
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = '${DB_NAME}'
      AND table_type = 'BASE TABLE'
      AND data_free > 1048576
    ORDER BY data_free DESC;
" 2>/dev/null)

if [ -z "${FRAGMENTED}" ]; then
    log "No significantly fragmented tables found."
else
    for TABLE in ${FRAGMENTED}; do
        printf "  OPTIMIZE %s ... " "${TABLE}"
        RESULT=$(mysql_exec -N -e "OPTIMIZE TABLE \`${TABLE}\`;" "${DB_NAME}" 2>/dev/null | awk '{print $NF}')
        echo -e "${CYAN}${RESULT}${NC}"
    done
fi
echo ""

# --- 5. Check slow query log ---
log "Slow query log status:"
mysql_exec -e "
SHOW VARIABLES LIKE 'slow_query_log%';
SHOW VARIABLES LIKE 'long_query_time';
" 2>/dev/null
echo ""

# Check if slow log file exists and has content
SLOW_LOG_SIZE=$(docker exec "${CONTAINER}" sh -c \
    "wc -c < /var/log/mysql/slow.log 2>/dev/null || echo 0" 2>/dev/null)

if [ "${SLOW_LOG_SIZE}" -gt 0 ] 2>/dev/null; then
    log "Last 20 lines of slow query log:"
    docker exec "${CONTAINER}" tail -20 /var/log/mysql/slow.log 2>/dev/null || true
else
    log "Slow query log is empty or not found."
fi
echo ""

# --- 6. InnoDB status summary ---
log "InnoDB buffer pool usage:"
mysql_exec -e "
SELECT
    ROUND(@@innodb_buffer_pool_size / 1024 / 1024) AS 'Buffer Pool (MB)',
    (SELECT COUNT(*) FROM information_schema.INNODB_BUFFER_PAGE) AS 'Pages in Pool',
    (SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2)
     FROM information_schema.tables
     WHERE table_schema = '${DB_NAME}') AS 'Data Size (MB)';
" 2>/dev/null
echo ""

# --- 7. Check for tables without primary key ---
log "Tables without PRIMARY KEY (potential performance issue):"
NOPK=$(mysql_exec -N -e "
    SELECT t.table_name
    FROM information_schema.tables t
    LEFT JOIN information_schema.table_constraints c
        ON t.table_schema = c.table_schema
        AND t.table_name = c.table_name
        AND c.constraint_type = 'PRIMARY KEY'
    WHERE t.table_schema = '${DB_NAME}'
      AND t.table_type = 'BASE TABLE'
      AND c.constraint_name IS NULL
    ORDER BY t.table_name;
" 2>/dev/null)

if [ -z "${NOPK}" ]; then
    echo -e "  ${GREEN}All tables have primary keys.${NC}"
else
    for TABLE in ${NOPK}; do
        echo -e "  ${YELLOW}WARNING: ${TABLE} — no primary key${NC}"
    done
fi
echo ""

echo "============================================================="
log "Optimization complete."
echo "============================================================="
