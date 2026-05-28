# Operations Log: Backup Verification Test

**Date:** 2026-05-29
**Type:** Backup validation
**Performed by:** System administrator

---

## Purpose

Verify that the backup process is producing complete, restorable backups. A backup that has never been tested for restore is not a reliable backup.

---

## Scope

Nextcloud user data directory, MariaDB database dump, Pi-hole configuration backup.

---

## Commands Used

```bash
# List current backups
ls -lh /srv/backups/

# Verify backup file integrity (checksum)
sha256sum /srv/backups/nextcloud-data-latest.tar.gz
sha256sum /srv/backups/nextcloud-db-latest.sql.gz

# Check backup file sizes are non-zero and reasonable
du -sh /srv/backups/*

# Test extract of a sample backup to a temp directory
mkdir /tmp/restore-test
tar -xzf /srv/backups/nextcloud-data-latest.tar.gz -C /tmp/restore-test --strip-components=1 2>&1 | head -20

# Verify extracted files look correct
ls /tmp/restore-test/

# Clean up test directory
rm -rf /tmp/restore-test
```

---

## Expected Result

Backup files present with non-zero sizes. Checksum matches stored value. Test extract produces readable file structure without errors. Database dump file is non-empty and contains valid SQL.

---

## Validation Result

Backup files confirmed present. Extract test completed without errors. Spot-checked several user data files from the extracted archive and confirmed they were readable. Database dump file reviewed and confirmed non-empty with valid SQL header.

---

## Issues Found

Backup timestamp showed one backup had not run on schedule due to the server being offline during the scheduled window. One missed backup noted.

---

## Fix or Recommendation

Manually triggered a backup run to fill the gap. Reviewed backup schedule to confirm alignment with server uptime. No data loss occurred. Backup schedule confirmed resuming correctly.

---

## Next Review Date

2026-06-05 (weekly backup verification)

---

## Rollback or Recovery Note

Full restore procedure documented in `backups/restore-tests/2026-05-nextcloud-data-restore-drill.md`. If backup files are missing or corrupt, the most recent prior backup should be used and any data created in the gap should be assumed lost.
