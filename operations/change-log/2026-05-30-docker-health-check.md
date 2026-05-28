# Operations Log: Docker Service Health Check

**Date:** 2026-05-30
**Type:** Routine health check
**Performed by:** System administrator

---

## Purpose

Perform a routine health check on all Docker containers and confirm services are operating as expected. Identify any containers in an unhealthy, restarting, or exited state.

---

## Scope

All containers managed under the active Docker Compose configuration.

---

## Commands Used

```bash
# Container status overview
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}"

# Resource usage
docker stats --no-stream

# Container logs review for recent errors (last 50 lines each)
docker logs --tail 50 nextcloud
docker logs --tail 50 nextcloud-db
docker logs --tail 50 pihole
docker logs --tail 50 portainer

# Disk usage by container and volumes
docker system df

# Prune unused images to recover disk space
docker image prune -f
```

---

## Expected Result

All containers in running state with uptime consistent with last known restart. No error patterns in recent logs. Disk usage within acceptable range. No containers consuming unexpectedly high CPU or memory.

---

## Validation Result

All containers confirmed running. Log review showed no critical errors in any service. Pi-hole logs showed normal DNS query activity. Nextcloud logs showed routine cron and sync activity.

Docker image prune removed unused layers and recovered approximately 400MB of disk space.

---

## Issues Found

Portainer reported a minor warning in its logs about an older agent version. Not critical but noted for follow-up.

---

## Fix or Recommendation

Schedule Portainer update in the next maintenance window. No immediate action required. Warning does not affect functionality.

---

## Next Review Date

2026-06-05

---

## Rollback or Recovery Note

If any container enters a restart loop after a future update, use `docker logs [container-name]` to identify the error before attempting recovery. Most restart loops in this environment are caused by configuration file errors or missing environment variables, both of which are recoverable from the backup.
