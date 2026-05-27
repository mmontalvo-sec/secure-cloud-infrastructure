# Backup Strategy

## Philosophy

An unverified backup is an assumption, not a backup. Every backup procedure in this environment includes a defined verification step. Backups are tested by restoration to isolated containers before they are needed in a real recovery scenario.

## What Is Backed Up

| Asset | Script | Frequency | Retention |
|-------|--------|-----------|-----------|
| Nextcloud database (MariaDB) | `mariadb-backup.sh` | Daily 02:00 | 14 days |
| Nextcloud data directory | `nextcloud-backup.sh` | Daily 03:00 | Rolling sync |
| Docker Compose stacks | Version-controlled (this repo) | On change | Git history |
| `.env` files | Encrypted, stored offline | On change | Manual |
| UFW rules | `/configs/ufw-rules.md` | On change | Git history |
| SSH config | `/configs/sshd_config.hardened` | On change | Git history |
| fstab | `/configs/fstab-mounts.md` | On change | Git history |

## Cron Schedule

```bash
# Add to crontab: crontab -e
0 2 * * * /bin/bash /srv/backups/scripts/mariadb-backup.sh
0 3 * * * /bin/bash /srv/backups/scripts/nextcloud-backup.sh
```

## Verification Procedure

### Database Backup Verification

```bash
# Start isolated test container
docker run --rm -d --name test_db \
  -e MYSQL_ROOT_PASSWORD=testpass \
  mariadb:10.11

# Wait for initialization
sleep 15

# Restore latest backup
docker exec -i test_db \
  mysql -u root -ptestpass < /srv/backups/db/nextcloud_db_YYYY-MM-DD_HHMM.sql

# Verify table count
docker exec test_db \
  mysql -u root -ptestpass -e "USE nextcloud; SHOW TABLES;" | wc -l

# Cleanup
docker stop test_db
```

### Data Directory Verification

```bash
# Verify destination is not empty and size is reasonable
du -sh /srv/backups/nextcloud-data/
ls /srv/backups/nextcloud-data/ | head -20

# Spot-check a known file exists in backup
ls /srv/backups/nextcloud-data/data/<username>/files/
```

## Recovery Procedure

Full recovery from backup:

```bash
# 1. Enable maintenance mode on running instance (if still up)
docker exec -u www-data nextcloud php occ maintenance:mode --on

# 2. Restore database
docker exec -i nextcloud_db \
  mysql -u root -p"${DB_ROOT_PASSWORD}" nextcloud \
  < /srv/backups/db/nextcloud_db_YYYY-MM-DD_HHMM.sql

# 3. Restore data directory
rsync -avz --delete \
  /srv/backups/nextcloud-data/ \
  /srv/data/nextcloud/

# 4. Fix permissions
docker exec nextcloud chown -R www-data:www-data /var/www/html/data

# 5. Run Nextcloud repair
docker exec -u www-data nextcloud php occ maintenance:repair

# 6. Disable maintenance mode
docker exec -u www-data nextcloud php occ maintenance:mode --off

# 7. Verify
docker exec -u www-data nextcloud php occ status
```
