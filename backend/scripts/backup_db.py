"""
backup_db.py — Cross-platform PostgreSQL backup script.

Works on Windows, Mac, and Linux. Reads DATABASE_URL from .env automatically.

Usage:
    python scripts/backup_db.py              # Normal backup
    python scripts/backup_db.py --dry-run    # Show what would happen
    python scripts/backup_db.py --list       # List existing backups
"""
import os
import sys
import gzip
import shutil
import subprocess
import argparse
from typing import Optional
from pathlib import Path
from datetime import datetime, timedelta
from urllib.parse import urlparse

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR = Path(__file__).parent
BACKEND_DIR = SCRIPT_DIR.parent
ENV_FILE = BACKEND_DIR / ".env"
BACKUP_DIR = BACKEND_DIR / "backups"
LOG_DIR = BACKEND_DIR / "logs"
LOG_FILE = LOG_DIR / "backup.log"
KEEP_DAYS = 7


def log(msg: str):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{timestamp}] {msg}"
    print(line)
    LOG_FILE.parent.mkdir(exist_ok=True)
    with open(LOG_FILE, "a") as f:
        f.write(line + "\n")


def load_env() -> dict:
    """Load .env file into a dict."""
    if not ENV_FILE.exists():
        raise FileNotFoundError(f".env not found at {ENV_FILE}")
    env = {}
    for line in ENV_FILE.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, _, v = line.partition("=")
            env[k.strip()] = v.strip().strip('"').strip("'")
    return env


def parse_db_url(url: str) -> dict:
    """Parse DATABASE_URL into components."""
    # Strip asyncpg driver prefix
    url = url.replace("postgresql+asyncpg://", "postgresql://")
    parsed = urlparse(url)
    return {
        "host": parsed.hostname or "localhost",
        "port": str(parsed.port or 5432),
        "user": parsed.username or "postgres",
        "password": parsed.password or "",
        "dbname": parsed.path.lstrip("/"),
    }


def run_backup(db: dict, dry_run: bool = False) -> Optional[Path]:
    """Run pg_dump and compress output."""
    BACKUP_DIR.mkdir(exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_file = BACKUP_DIR / f"cropdiag_{timestamp}.sql.gz"

    log("=== DB Backup Started ===")
    log(f"Database : {db['dbname']} @ {db['host']}:{db['port']}")
    log(f"Output   : {backup_file}")

    if dry_run:
        log("DRY RUN — no backup created.")
        return None

    env = os.environ.copy()
    env["PGPASSWORD"] = db["password"]

    cmd = [
        "pg_dump",
        f"--host={db['host']}",
        f"--port={db['port']}",
        f"--username={db['user']}",
        f"--dbname={db['dbname']}",
        "--no-password",
        "--format=plain",
    ]

    try:
        result = subprocess.run(cmd, capture_output=True, env=env, check=True)
        # Compress output
        with gzip.open(backup_file, "wb") as gz:
            gz.write(result.stdout)
        size_kb = backup_file.stat().st_size // 1024
        log(f"SUCCESS: Backup created — {backup_file} ({size_kb} KB)")
        return backup_file
    except subprocess.CalledProcessError as e:
        log(f"ERROR: pg_dump failed: {e.stderr.decode()}")
        backup_file.unlink(missing_ok=True)
        return None
    except FileNotFoundError:
        log("ERROR: pg_dump not found. Install PostgreSQL client tools.")
        return None


def cleanup_old_backups():
    """Delete backups older than KEEP_DAYS."""
    cutoff = datetime.now() - timedelta(days=KEEP_DAYS)
    deleted = 0
    for f in BACKUP_DIR.glob("cropdiag_*.sql.gz"):
        if datetime.fromtimestamp(f.stat().st_mtime) < cutoff:
            f.unlink()
            deleted += 1
    log(f"Cleaned up {deleted} old backup(s) (kept last {KEEP_DAYS} days).")


def list_backups():
    """List all existing backups."""
    backups = sorted(BACKUP_DIR.glob("cropdiag_*.sql.gz"), reverse=True)
    if not backups:
        print("No backups found.")
        return
    print(f"\n{'File':<50} {'Size':>10} {'Date'}")
    print("-" * 75)
    for f in backups:
        size = f"{f.stat().st_size // 1024} KB"
        mtime = datetime.fromtimestamp(f.stat().st_mtime).strftime("%Y-%m-%d %H:%M")
        print(f"{f.name:<50} {size:>10}  {mtime}")
    print(f"\nTotal: {len(backups)} backup(s)")


def main():
    parser = argparse.ArgumentParser(description="PostgreSQL backup utility")
    parser.add_argument("--dry-run", action="store_true", help="Show what would happen")
    parser.add_argument("--list", action="store_true", help="List existing backups")
    args = parser.parse_args()

    if args.list:
        list_backups()
        return

    try:
        env = load_env()
        db_url = env.get("DATABASE_URL", "")
        if not db_url:
            log("ERROR: DATABASE_URL not found in .env")
            sys.exit(1)
        db = parse_db_url(db_url)
    except Exception as e:
        log(f"ERROR loading config: {e}")
        sys.exit(1)

    backup_file = run_backup(db, dry_run=args.dry_run)

    if backup_file:
        cleanup_old_backups()
        remaining = list(BACKUP_DIR.glob("cropdiag_*.sql.gz"))
        log(f"Backups retained: {len(remaining)}")
        log("=== DB Backup Complete ===")
    elif not args.dry_run:
        sys.exit(1)


if __name__ == "__main__":
    main()
