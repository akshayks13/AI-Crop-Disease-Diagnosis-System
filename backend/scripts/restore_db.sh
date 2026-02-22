#!/usr/bin/env bash
# =============================================================================
# restore_db.sh — Restore a PostgreSQL backup
#
# Usage:
#   ./scripts/restore_db.sh backups/cropdiag_20260218_020000.sql.gz
#
# WARNING: This will DROP and recreate the target database!
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$BACKEND_DIR/.env"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# ── Validate args ─────────────────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <backup_file.sql.gz>"
  echo "Example: $0 backups/cropdiag_20260218_020000.sql.gz"
  exit 1
fi

BACKUP_FILE="$1"

if [[ ! -f "$BACKUP_FILE" ]]; then
  log "ERROR: Backup file not found: $BACKUP_FILE"
  exit 1
fi

# ── Load .env ─────────────────────────────────────────────────────────────────
DB_URL=$(grep -E '^DATABASE_URL=' "$ENV_FILE" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
DB_URL="${DB_URL/postgresql+asyncpg:\/\//postgresql://}"

DB_USER=$(echo "$DB_URL" | sed -E 's|postgresql://([^:]+):.*|\1|')
DB_PASS=$(echo "$DB_URL" | sed -E 's|postgresql://[^:]+:([^@]+)@.*|\1|')
DB_HOST=$(echo "$DB_URL" | sed -E 's|postgresql://[^@]+@([^:/]+).*|\1|')
DB_PORT=$(echo "$DB_URL" | sed -E 's|.*:([0-9]+)/.*|\1|')
DB_NAME=$(echo "$DB_URL" | sed -E 's|.*/([^?]+).*|\1|')

# ── Confirm ───────────────────────────────────────────────────────────────────
log "=== DB Restore ==="
log "Backup file : $BACKUP_FILE"
log "Target DB   : $DB_NAME @ $DB_HOST:$DB_PORT"
echo ""
echo "⚠️  WARNING: This will DROP and recreate '$DB_NAME'. All current data will be lost!"
read -rp "Type 'yes' to confirm: " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
  log "Restore cancelled."
  exit 0
fi

export PGPASSWORD="$DB_PASS"

# ── Drop and recreate DB ──────────────────────────────────────────────────────
log "Dropping existing database '$DB_NAME'..."
psql --host="$DB_HOST" --port="$DB_PORT" --username="$DB_USER" \
  --dbname="postgres" --no-password \
  -c "DROP DATABASE IF EXISTS \"$DB_NAME\";"

log "Creating fresh database '$DB_NAME'..."
psql --host="$DB_HOST" --port="$DB_PORT" --username="$DB_USER" \
  --dbname="postgres" --no-password \
  -c "CREATE DATABASE \"$DB_NAME\";"

# ── Restore ───────────────────────────────────────────────────────────────────
log "Restoring from $BACKUP_FILE ..."
gunzip -c "$BACKUP_FILE" | psql \
  --host="$DB_HOST" \
  --port="$DB_PORT" \
  --username="$DB_USER" \
  --dbname="$DB_NAME" \
  --no-password

log "=== Restore Complete! ==="
log "Database '$DB_NAME' restored from $BACKUP_FILE"
