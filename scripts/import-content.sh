#!/usr/bin/env bash
###############################################################################
# import-content.sh — Import articles into OJS using Native XML Import Plugin
#
# Usage:
#   ./scripts/import-content.sh --journal-path vestnik --import-dir ./content/
#   ./scripts/import-content.sh --journal-path vestnik --file article.xml
#   ./scripts/import-content.sh --journal-path vestnik --import-dir ./content/ --user admin
#
# Requires:
#   - Run inside OJS Docker container or with access to OJS PHP tools
#   - OJS must be installed and the journal must exist
###############################################################################
set -euo pipefail

# ─── Constants ───────────────────────────────────────────────────────────────
OJS_ROOT="${OJS_ROOT:-/var/www/html}"
PHP_BIN="${PHP_BIN:-php}"
IMPORT_TOOL="${OJS_ROOT}/tools/importExport.php"
PLUGIN_NAME="NativeImportExportPlugin"
DEFAULT_USER="admin"

# ─── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[IMPORT]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ─── Usage ───────────────────────────────────────────────────────────────────
usage() {
    cat <<USAGE
Usage: $(basename "$0") [OPTIONS]

Options:
  --journal-path PATH   OJS journal path (e.g. vestnik)    [required]
  --import-dir DIR      Directory with XML files to import
  --file FILE           Single XML file to import
  --user USERNAME       OJS admin username (default: admin)
  --dry-run             Validate XML without importing
  --help                Show this help

Examples:
  $(basename "$0") --journal-path vestnik --import-dir ./content/
  $(basename "$0") --journal-path vestnik --file content/sample-article.xml
  $(basename "$0") --journal-path vestnik --file article.xml --dry-run
USAGE
    exit 0
}

# ─── Parse arguments ────────────────────────────────────────────────────────
JOURNAL_PATH=""
IMPORT_DIR=""
IMPORT_FILE=""
OJS_USER="${DEFAULT_USER}"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --journal-path)
            JOURNAL_PATH="$2"
            shift 2
            ;;
        --import-dir)
            IMPORT_DIR="$2"
            shift 2
            ;;
        --file)
            IMPORT_FILE="$2"
            shift 2
            ;;
        --user)
            OJS_USER="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --help|-h)
            usage
            ;;
        *)
            err "Unknown option: $1"
            usage
            ;;
    esac
done

# ─── Validate ───────────────────────────────────────────────────────────────
if [[ -z "${JOURNAL_PATH}" ]]; then
    err "--journal-path is required"
    usage
fi

if [[ -z "${IMPORT_DIR}" ]] && [[ -z "${IMPORT_FILE}" ]]; then
    err "Specify --import-dir or --file"
    usage
fi

if [[ ! -f "${IMPORT_TOOL}" ]]; then
    err "OJS import tool not found: ${IMPORT_TOOL}"
    err "Make sure OJS_ROOT is set correctly or run inside the OJS container."
    exit 1
fi

# ─── Import single file ────────────────────────────────────────────────────
import_file() {
    local xml_file="$1"
    local filename
    filename=$(basename "${xml_file}")

    if [[ ! -f "${xml_file}" ]]; then
        err "File not found: ${xml_file}"
        return 1
    fi

    if [[ "${xml_file}" != *.xml ]]; then
        warn "Skipping non-XML file: ${filename}"
        return 0
    fi

    # Validate XML syntax first
    if command -v xmllint &>/dev/null; then
        if ! xmllint --noout "${xml_file}" 2>/dev/null; then
            err "Invalid XML syntax: ${filename}"
            return 1
        fi
    fi

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "[DRY-RUN] Validating: ${filename}"
        # OJS import tool doesn't have a dedicated dry-run, but we can try
        # importing to /dev/null or just validate XML
        log "[DRY-RUN] XML syntax OK: ${filename}"
        return 0
    fi

    log "Importing: ${filename} → journal/${JOURNAL_PATH}"

    local output
    local exit_code=0

    output=$("${PHP_BIN}" "${IMPORT_TOOL}" \
        "${PLUGIN_NAME}" import \
        "${xml_file}" \
        "${JOURNAL_PATH}" \
        "${OJS_USER}" \
        2>&1) || exit_code=$?

    if [[ ${exit_code} -ne 0 ]]; then
        err "Import failed for ${filename} (exit code: ${exit_code})"
        err "Output: ${output}"
        return 1
    fi

    # Check for error messages in output
    if echo "${output}" | grep -qi "error\|fatal\|exception"; then
        warn "Import completed with warnings for ${filename}:"
        echo "${output}"
        return 1
    fi

    log "Successfully imported: ${filename}"
    if [[ -n "${output}" ]]; then
        echo "  ${output}"
    fi

    return 0
}

# ─── Main ───────────────────────────────────────────────────────────────────
total=0
success=0
failed=0
skipped=0

log "Starting import to journal: ${JOURNAL_PATH}"
log "OJS user: ${OJS_USER}"
[[ "${DRY_RUN}" -eq 1 ]] && log "Mode: DRY RUN (no actual import)"
echo ""

if [[ -n "${IMPORT_FILE}" ]]; then
    # Single file import
    total=1
    if import_file "${IMPORT_FILE}"; then
        success=$((success + 1))
    else
        failed=$((failed + 1))
    fi
elif [[ -n "${IMPORT_DIR}" ]]; then
    # Directory import
    if [[ ! -d "${IMPORT_DIR}" ]]; then
        err "Import directory not found: ${IMPORT_DIR}"
        exit 1
    fi

    # Count XML files
    xml_count=$(find "${IMPORT_DIR}" -maxdepth 1 -name "*.xml" -type f | wc -l)
    if [[ "${xml_count}" -eq 0 ]]; then
        warn "No XML files found in ${IMPORT_DIR}"
        exit 0
    fi

    log "Found ${xml_count} XML files in ${IMPORT_DIR}"
    echo ""

    # Sort files for consistent ordering
    while IFS= read -r xml_file; do
        total=$((total + 1))
        if import_file "${xml_file}"; then
            success=$((success + 1))
        else
            failed=$((failed + 1))
        fi
        echo ""
    done < <(find "${IMPORT_DIR}" -maxdepth 1 -name "*.xml" -type f | sort)
fi

# ─── Summary ────────────────────────────────────────────────────────────────
echo ""
log "=========================================="
log "  Import Summary"
log "=========================================="
echo "  Total:     ${total}"
echo "  Success:   ${success}"
echo "  Failed:    ${failed}"
echo ""

if [[ "${failed}" -gt 0 ]]; then
    err "Some imports failed. Check the output above for details."
    exit 1
fi

if [[ "${DRY_RUN}" -eq 0 ]] && [[ "${success}" -gt 0 ]]; then
    log "Rebuilding search index..."
    "${PHP_BIN}" "${OJS_ROOT}/tools/rebuildSearchIndex.php" 2>&1 || \
        warn "Search index rebuild failed — run manually: php tools/rebuildSearchIndex.php"
fi

log "Done."
