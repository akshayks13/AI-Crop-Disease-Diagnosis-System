#!/usr/bin/env bash
# =============================================================================
# backup_db.sh — PostgreSQL backup script for AI Crop Disease Diagnosis System
#
# Usage:
#   ./scripts/backup_db.sh              # Normal backup
#   ./scripts/backup_db.sh --dry-run    # Show what would happen, no backup
#
# Cron (daily at 2 AM):
#   0 2 * * * /path/to/SE_Proj/backend/scripts/backup_db.sh >> /path/to/SE_Proj/backend/logs/backup.log 2>&1
# =============================================================================

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$BACKEND_DIR/.env"
BACKUP_DIR="$BACKEND_DIR/backups"
LOG_FILE="$BACKEND_DIR/logs/backup.log"
KEEP_DAYS=7
DRY_RUN=false

# ── Parse args ────────────────────────────────────────────────────────────────
for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN=true ;;
  esac
done

# ── Logging helper ────────────────────────────────────────────────────────────
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# ── Load .env ─────────────────────────────────────────────────────────────────
if [[ ! -f "$ENV_FILE" ]]; then
  log "ERROR: .env file not found at $ENV_FILE"
  exit 1
fi

# Parse DATABASE_URL from .env
# Expected format: postgresql+asyncpg://user:password@host:port/dbname
#              or: postgresql://user:password@host:port/dbname
DB_URL=$(grep -E '^DATABASE_URL=' "$ENV_FILE" | cut -d'=' -f2- | tr -d '"' | tr -d "'")

if [[ -z "$DB_URL" ]]; then
  log "ERROR: DATABASE_URL not found in .env"
  exit 1
fi

# Strip asyncpg driver prefix if present
DB_URL="${DB_URL/postgresql+asyncpg:\/\//postgresql://}"

# Extract components
DB_USER=$(echo "$DB_URL" | sed -E 's|postgresql://([^:]+):.*|\1|')
DB_PASS=$(echo "$DB_URL" | sed -E 's|postgresql://[^:]+:([^@]+)@.*|\1|')
DB_HOST=$(echo "$DB_URL" | sed -E 's|postgresql://[^@]+@([^:/]+).*|\1|')
DB_PORT=$(echo "$DB_URL" | sed -E 's|.*:([0-9]+)/.*|\1|')
DB_NAME=$(echo "$DB_URL" | sed -E 's|.*/([^?]+).*|\1|')

# ── Ensure directories exist ──────────────────────────────────────────────────
mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# ── Backup filename ───────────────────────────────────────────────────────────
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_FILE="$BACKUP_DIR/cropdiag_${TIMESTAMP}.sql.gz"

log "=== DB Backup Started ==="
log "Database : $DB_NAME @ $DB_HOST:$DB_PORT"
log "Output   : $BACKUP_FILE"
log "Dry run  : $DRY_RUN"

if [[ "$DRY_RUN" == "true" ]]; then
  log "DRY RUN — no backup created."
  exit 0
fi

# ── Run pg_dump ───────────────────────────────────────────────────────────────
export PGPASSWORD="$DB_PASS"

if pg_dump \
    --host="$DB_HOST" \
    --port="$DB_PORT" \
    --username="$DB_USER" \
    --dbname="$DB_NAME" \
    --no-password \
    --format=plain \
    --verbose \
    2>>"$LOG_FILE" \
  | gzip > "$BACKUP_FILE"; then
  
  SIZE=$(du -sh "$BACKUP_FILE" | cut -f1)
  log "SUCCESS: Backup created — $BACKUP_FILE ($SIZE)"
else
  log "ERROR: pg_dump failed. Check $LOG_FILE for details."
  rm -f "$BACKUP_FILE"  # Remove empty/partial file
  exit 1
fi

# ── Cleanup old backups ───────────────────────────────────────────────────────
log "Cleaning up backups older than $KEEP_DAYS days..."
DELETED=$(find "$BACKUP_DIR" -name "cropdiag_*.sql.gz" -mtime +"$KEEP_DAYS" -print -delete | wc -l | tr -d ' ')
log "Deleted $DELETED old backup(s)."

# ── List current backups ──────────────────────────────────────────────────────
BACKUP_COUNT=$(find "$BACKUP_DIR" -name "cropdiag_*.sql.gz" | wc -l | tr -d ' ')
log "Current backups kept: $BACKUP_COUNT"
find "$BACKUP_DIR" -name "cropdiag_*.sql.gz" -exec ls -lh {} \; | awk '{print "  " $5 "  " $9}'

log "=== DB Backup Complete ==="
