#!/bin/bash
# Nextcloud Data Directory Backup
# Location: /srv/backups/scripts/nextcloud-backup.sh
# Run: bash /srv/backups/scripts/nextcloud-backup.sh
# Cron: 0 3 * * * /bin/bash /srv/backups/scripts/nextcloud-backup.sh

set -euo pipefail

SOURCE="/srv/data/nextcloud"
DEST="/srv/backups/nextcloud-data"
LOGFILE="/srv/backups/backup.log"
TIMESTAMP=$(date +%F_%H%M)

mkdir -p "$DEST"

echo "[$(date)] Starting Nextcloud data backup..." >> "$LOGFILE"

rsync -avz --progress --delete \
  "$SOURCE/" \
  "$DEST/" \
  >> "/srv/backups/rsync_$TIMESTAMP.log" 2>&1

DEST_SIZE=$(du -sh "$DEST" | cut -f1)
echo "[$(date)] Nextcloud data backup completed. Destination size: $DEST_SIZE" >> "$LOGFILE"

# Remove rsync logs older than 14 days
find /srv/backups -name "rsync_*.log" -mtime +14 -delete
