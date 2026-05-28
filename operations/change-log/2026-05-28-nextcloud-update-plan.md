# Operations Log: Nextcloud Update Plan

**Date:** 2026-05-28
**Type:** Planned maintenance
**Performed by:** System administrator

---

## Purpose

Document the planned update procedure for Nextcloud and its dependent services (MariaDB, Redis) to maintain a current, secure installation.

---

## Scope

Nextcloud container, MariaDB container, Redis container, and the Nextcloud application update process via `occ`.

---

## Pre-Update Checks

```bash
# Confirm current Nextcloud version
docker exec -u www-data nextcloud php occ status

# Confirm backup completed before proceeding
ls -lh /srv/backups/

# Confirm disk space is adequate
df -h /srv
```

---

## Update Procedure

```bash
# Step 1: Pull updated images
docker compose pull nextcloud nextcloud-db nextcloud-redis

# Step 2: Enable maintenance mode before stopping
docker exec -u www-data nextcloud php occ maintenance:mode --on

# Step 3: Stop and recreate containers with new images
docker compose up -d --no-deps nextcloud nextcloud-db nextcloud-redis

# Step 4: Run upgrade
docker exec -u www-data nextcloud php occ upgrade

# Step 5: Disable maintenance mode
docker exec -u www-data nextcloud php occ maintenance:mode --off

# Step 6: Confirm status
docker exec -u www-data nextcloud php occ status
```

---

## Expected Result

Nextcloud reports updated version, no errors in upgrade output, maintenance mode off, all containers running.

---

## Validation Result

Plan documented. Update not yet executed. Pending backup confirmation from 2026-05-29 before proceeding.

---

## Issues Found

None at planning stage.

---

## Fix or Recommendation

Do not execute update until backup is verified. If upgrade output shows database migration errors, restore from backup and investigate before retrying.

---

## Next Review Date

Execute after backup verification is confirmed on 2026-05-29.

---

## Rollback or Recovery Note

If the upgrade fails, restore Nextcloud data from the most recent backup, pull the previous image tag, and redeploy. Document the failure and open a tracking note before retrying.
