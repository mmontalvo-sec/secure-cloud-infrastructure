# Backup Restore Drill: Nextcloud Data

**Date:** 2026-05
**Type:** Restore validation
**Performed by:** System administrator

---

## Purpose

Validate that the Nextcloud backup can be successfully restored to a functional state. A backup that has not been restored is an assumption, not a guarantee.

---

## Scope

Nextcloud user data directory and MariaDB database restore to a test location. This was a partial restore drill to validate the backup process, not a full production restore.

---

## Pre-Drill Checklist

- [ ] Active backup file confirmed present and non-zero size
- [ ] Sufficient disk space available for restore
- [ ] Test restore directory created and isolated from production data
- [ ] Production Nextcloud service left running during drill (restore was to a separate location)

---

## Restore Procedure Tested

```bash
# Step 1: Create isolated test restore directory
mkdir -p /tmp/restore-drill/nextcloud-data

# Step 2: Extract backup archive to test location
tar -xzf /srv/backups/nextcloud-data-latest.tar.gz \
  -C /tmp/restore-drill/nextcloud-data \
  --strip-components=1

# Step 3: Verify directory structure
ls -la /tmp/restore-drill/nextcloud-data/

# Step 4: Spot-check several files for readability
file /tmp/restore-drill/nextcloud-data/[REDACTED_USER]/files/Documents/[REDACTED_FILE]

# Step 5: Test database dump validity
gunzip -c /srv/backups/nextcloud-db-latest.sql.gz | head -30

# Step 6: Confirm dump contains expected table structure
gunzip -c /srv/backups/nextcloud-db-latest.sql.gz | grep "CREATE TABLE" | head -10

# Step 7: Clean up test restore
rm -rf /tmp/restore-drill
```

---

## Expected Result

Archive extracts without errors. Directory structure matches expected Nextcloud data layout. Spot-checked files are readable and not corrupt. Database dump contains valid SQL with expected table structure.

---

## Validation Result

Archive extracted successfully with no errors. Directory structure confirmed matching expected Nextcloud user data layout. Spot-checked three files of different types; all confirmed readable and intact. Database dump confirmed non-empty with valid SQL header and expected table names.

---

## Issues Found

None. Restore drill passed.

---

## Fix or Recommendation

Full production restore procedure documented below for reference. This drill validated the backup is usable. Full restore should be tested in a staging environment if one becomes available.

---

## Full Production Restore Procedure (Reference)

If a full restore to production is needed:

```bash
# 1. Enable Nextcloud maintenance mode
docker exec -u www-data nextcloud php occ maintenance:mode --on

# 2. Stop containers
docker compose stop nextcloud nextcloud-db

# 3. Restore data directory from backup
tar -xzf /srv/backups/nextcloud-data-latest.tar.gz -C /srv/data/

# 4. Restore database
gunzip -c /srv/backups/nextcloud-db-latest.sql.gz | \
  docker exec -i nextcloud-db mysql -u [USER] -p[PASS] nextcloud

# 5. Fix permissions
docker exec nextcloud chown -R www-data:www-data /var/www/html/data

# 6. Start containers
docker compose start nextcloud-db nextcloud

# 7. Run occ upgrade check
docker exec -u www-data nextcloud php occ upgrade

# 8. Disable maintenance mode
docker exec -u www-data nextcloud php occ maintenance:mode --off

# 9. Verify status
docker exec -u www-data nextcloud php occ status
```

---

## Next Drill Date

2026-07 (quarterly restore drill)

---

## Notes

Credentials and internal paths have been removed from this document. The actual restore commands with real values are stored securely and not committed to this repository.
