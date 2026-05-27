#!/bin/bash
# MariaDB Backup — Nextcloud Database
# Location: /srv/backups/scripts/mariadb-backup.sh
# Run: bash /srv/backups/scripts/mariadb-backup.sh
# Cron: 0 2 * * * /bin/bash /srv/backups/scripts/mariadb-backup.sh

set -euo pipefail

BACKUP_DIR="/srv/backups/db"
CONTAINER="nextcloud_db"
DB_NAME="nextcloud"
RETAIN_DAYS=14
TIMESTAMP=$(date +%F_%H%M)
LOGFILE="/srv/backups/backup.log"

mkdir -p "$BACKUP_DIR"

echo "[$(date)] Starting MariaDB backup..." >> "$LOGFILE"

docker exec "$CONTAINER" \
  mysqldump -u root -p"${DB_ROOT_PASSWORD}" "$DB_NAME" \
  > "$BACKUP_DIR/nextcloud_db_$TIMESTAMP.sql"

FILESIZE=$(du -sh "$BACKUP_DIR/nextcloud_db_$TIMESTAMP.sql" | cut -f1)
echo "[$(date)] Backup completed: nextcloud_db_$TIMESTAMP.sql ($FILESIZE)" >> "$LOGFILE"

# Remove backups older than RETAIN_DAYS
find "$BACKUP_DIR" -name "*.sql" -mtime +"$RETAIN_DAYS" -delete
echo "[$(date)] Cleanup: removed backups older than $RETAIN_DAYS days." >> "$LOGFILE"
