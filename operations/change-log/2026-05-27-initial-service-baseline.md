# Operations Log: Initial Service Baseline

**Date:** 2026-05-27
**Type:** Service baseline documentation
**Performed by:** System administrator

---

## Purpose

Establish and document the baseline operating state of all services running on the secure cloud infrastructure. This document serves as the reference point for future health checks, change reviews, and incident comparisons.

---

## Scope

All containerized services managed via Docker Compose on Ubuntu Server, accessed exclusively through Tailscale VPN.

---

## Services Checked

| Service | Container Name | Status | Port Binding |
|---------|---------------|--------|-------------|
| Nextcloud | nextcloud | Running | Internal only |
| MariaDB | nextcloud-db | Running | Internal only |
| Redis | nextcloud-redis | Running | Internal only |
| Pi-hole | pihole | Running | Internal only |
| Portainer | portainer | Running | Internal only |
| Ollama | ollama | Running | Internal only |
| Open WebUI | open-webui | Running | Internal only |

---

## Commands Used

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
docker stats --no-stream
df -h
free -h
uptime
sudo ufw status verbose
tailscale status
```

---

## Expected Result

All containers running. No public-facing ports. UFW default deny inbound. Tailscale node connected. Disk usage within acceptable range.

---

## Validation Result

All services confirmed running. No containers in exited or restarting state. UFW confirmed default deny with no public service ports open. Tailscale node active and reachable from authorized devices.

---

## Issues Found

None at baseline. Environment is clean.

---

## Fix or Recommendation

No immediate action required. Schedule first backup verification test within the next 48 hours.

---

## Next Review Date

2026-05-30

---

## Rollback or Recovery Note

If any service fails to start after a future change, restore from the most recent backup using the procedure documented in `backups/README.md`. Baseline container state is recoverable via `docker compose up -d` from the current `docker-compose.yml`.
