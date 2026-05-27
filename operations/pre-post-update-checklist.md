# Pre/Post Update Checklists

## Before Any Major Update

Run this before Nextcloud major versions, MariaDB version upgrades,
or any change with a defined rollback path.

### Pre-Update Checklist

```bash
# 1. Verify current state
docker ps
docker exec -u www-data nextcloud php occ status

# 2. Database backup
docker exec nextcloud_db \
  mysqldump -u root -p"${DB_ROOT_PASSWORD}" nextcloud \
  > /srv/backups/pre_update_db_$(date +%F_%H%M).sql

# 3. Nextcloud data sync
rsync -avz --progress /srv/data/nextcloud/ /srv/backups/pre_update_nextcloud/

# 4. Back up Compose files and configs
cp -r /srv/compose/ /srv/backups/pre_update_compose_$(date +%F)/

# 5. Enable maintenance mode
docker exec -u www-data nextcloud php occ maintenance:mode --on

# 6. Verify backup file sizes are reasonable
du -sh /srv/backups/pre_update_*
ls -lh /srv/backups/pre_update_db_*
```

- [ ] `docker ps` — all containers running before update
- [ ] Database backup completed and file size verified
- [ ] Data directory backup completed
- [ ] Compose files backed up
- [ ] Maintenance mode enabled
- [ ] Target version changelog reviewed
- [ ] App compatibility checked against target version
- [ ] Rollback path documented (which backup to restore)

---

## After Any Major Update

Run this after completing any major update.

### Post-Update Checklist

```bash
# 1. Run upgrade routine
docker exec -u www-data nextcloud php occ upgrade

# 2. Verify status
docker exec -u www-data nextcloud php occ status

# 3. Disable maintenance mode
docker exec -u www-data nextcloud php occ maintenance:mode --off

# 4. Verify containers
docker ps

# 5. Verify port bindings unchanged
docker ps --format "table {{.Names}}\t{{.Ports}}"

# 6. Verify UFW
sudo ufw status verbose

# 7. Verify DNS
nslookup google.com SERVER_IP
```

- [ ] `occ upgrade` completed without errors
- [ ] `occ status` reports healthy
- [ ] Maintenance mode confirmed OFF
- [ ] All containers running
- [ ] Port bindings unchanged — no 0.0.0.0 entries
- [ ] UFW rules intact
- [ ] Pi-hole DNS resolving correctly
- [ ] Tailscale connectivity verified
- [ ] File sync validated from client device
- [ ] Test login to Nextcloud successful

---

## Rollback Procedure (If Update Fails)

```bash
# 1. Keep maintenance mode ON

# 2. Restore database
docker exec -i nextcloud_db \
  mysql -u root -p"${DB_ROOT_PASSWORD}" nextcloud \
  < /srv/backups/pre_update_db_YYYY-MM-DD_HHMM.sql

# 3. Restore Nextcloud data if needed
rsync -avz --delete \
  /srv/backups/pre_update_nextcloud/ \
  /srv/data/nextcloud/

# 4. Revert to previous image
# Edit docker-compose.yml to pin previous version tag
# docker compose up -d nextcloud

# 5. Disable maintenance mode
docker exec -u www-data nextcloud php occ maintenance:mode --off

# 6. Verify
docker exec -u www-data nextcloud php occ status
```
