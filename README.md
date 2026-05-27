# Secure Cloud Infrastructure Server

![Ubuntu](https://img.shields.io/badge/Ubuntu_Server-22.04_LTS-E95420?style=flat-square&logo=ubuntu&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=flat-square&logo=docker&logoColor=white)
![Tailscale](https://img.shields.io/badge/Tailscale-VPN_Overlay-0054AD?style=flat-square&logo=tailscale&logoColor=white)
![Nextcloud](https://img.shields.io/badge/Nextcloud-Private_Cloud-0082C9?style=flat-square&logo=nextcloud&logoColor=white)
![Pi-hole](https://img.shields.io/badge/Pi--hole-DNS_Filtering-96060C?style=flat-square&logo=pi-hole&logoColor=white)
![Status](https://img.shields.io/badge/Status-Operational-2EA44F?style=flat-square)

Self-hosted, hardened Linux infrastructure platform delivering private cloud storage, DNS filtering, local AI inference, and containerized services — with zero public internet exposure and VPN-gated remote administration.

---

## Overview

This repository documents the full deployment, security architecture, and ongoing operations of a production-style self-hosted Linux infrastructure environment built on repurposed consumer hardware.

The platform was engineered around three non-negotiable principles: no service is exposed to the public internet, all remote access routes through an authenticated encrypted VPN overlay, and defense-in-depth controls operate independently at every layer. A misconfigured firewall rule, a missed update, or a single point of failure should not create a viable attack path or take down the environment.

Beyond deployment, this project reflects an operational discipline focused on structured maintenance windows, backup integrity verification, validated upgrade sequencing, and documented troubleshooting methodology. Infrastructure that cannot be safely operated and recovered is not production infrastructure.

---

## Architecture

```
Internet (Claro Fiber · 1Gbps Symmetrical · CGNAT)
                        |
              Ubiquiti EdgeRouter 4
                        |
              Ubuntu Server (Headless)
              AMD Ryzen 5 3450U · 16GB DDR4
              Dual NVMe SSDs
                        |
          ┌─────────────────────────────────┐
          │           Docker Host           │
          │                                 │
          │  Nextcloud · MariaDB · Redis    │
          │  Pi-hole · Portainer            │
          │  Ollama · Open WebUI · Kiwix    │
          └─────────────────────────────────┘
                        |
       Tailscale Overlay (100.x.x.x/32)
       VPN-only · Authenticated · Encrypted
       No public ports · No attack surface
```

---

## Infrastructure Philosophy

**Minimal attack surface.** Services that do not need to be internet-facing are not internet-facing. This is enforced at the socket binding level, not just the firewall level. A service not listening on an interface cannot be reached through that interface regardless of firewall state.

**Operational durability.** Infrastructure that runs reliably once is expected to keep running reliably. Updates are validated before and after execution, backups are verified by restoration, and every configuration change is documented.

**Defense in depth.** Interface binding, UFW policy, Fail2Ban, SSH hardening, and VPN-gated administration operate as independent layers. No single misconfiguration creates a complete failure in the security model.

---

## Hardware

| Component | Specification |
|-----------|--------------|
| CPU | AMD Ryzen 5 3450U |
| RAM | 16GB DDR4 |
| Storage | Dual NVMe SSDs |
| OS | Ubuntu Server 22.04 LTS |
| Operation | Headless, 24/7 |
| BIOS | Power-on-AC enabled, sleep disabled |

Consumer hardware repurposed as production-grade infrastructure through proper BIOS configuration, OS hardening, and operational discipline.

---

## Security Model

### Zero Public Exposure

This environment intentionally avoids:
- Port forwarding of any kind to the public internet
- Global `0.0.0.0` service bindings
- Direct internet-facing services
- Any publicly reachable attack surface on hosted services

### Private Access Architecture

All remote access routes through **Tailscale VPN overlay networking**. Services bind exclusively to specific interfaces:

```
SERVER_LAN_IP   (local network access)
100.x.x.x       (Tailscale interface — authenticated remote access)
```

Binding to a specific interface at the service level is a security control, not a convenience setting. UFW provides an additional layer, but is not the primary access enforcement mechanism.

### SSH Tunnel Forwarding (Pivot Access)

For internal-only admin panels, SSH port forwarding proxies access through the encrypted VPN session without opening additional ports:

```bash
# Forward Portainer through the Tailscale SSH session
ssh -L 9443:SERVER_IP:9443 user@100.x.x.x

# Then access locally
https://localhost:9443
```

This pattern keeps management interfaces LAN-bound while remaining fully accessible to authorized remote sessions. No additional firewall rules or port bindings required.

### Security Controls

| Control | Tool | Purpose |
|---------|------|---------|
| Firewall | UFW | Default-deny inbound, interface-scoped rules |
| Intrusion prevention | Fail2Ban | SSH brute-force mitigation, auth log monitoring |
| SSH hardening | sshd_config | Key-only auth, root login disabled, TCP forwarding restricted |
| Remote access | Tailscale | Authenticated VPN overlay, zero public ports |
| Service isolation | Docker | Container-level resource and network boundaries |
| DNS filtering | Pi-hole | Network-wide sinkhole, query logging |
| Interface binding | Docker Compose | Explicit per-interface port mapping |

### UFW Policy

```bash
# Default deny — all inbound blocked unless explicitly permitted
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH — Tailscale interface only
sudo ufw allow in on tailscale0 to any port 22 proto tcp

# Web services — LAN only
sudo ufw allow from SERVER_SUBNET to any port 8080 proto tcp
sudo ufw allow from SERVER_SUBNET to any port 8081 proto tcp

# Portainer — LAN only
sudo ufw allow from SERVER_SUBNET to any port 9443 proto tcp

# Pi-hole DNS — LAN
sudo ufw allow from SERVER_SUBNET to any port 53

sudo ufw enable
```

### SSH Hardening (`/etc/ssh/sshd_config`)

```
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
X11Forwarding no
AllowTcpForwarding no
```

Key-based authentication only. Password authentication is disabled at the SSH daemon level, not managed through policy alone.

---

## Network Architecture

The infrastructure runs on consumer-grade hardware connected through a segmented network managed by a Ubiquiti EdgeRouter 4. Pi-hole provides DNS filtering for the full network via router DHCP configuration — no per-client DNS changes required.

The server maintains a static IP configured through Netplan:

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp3s0:
      dhcp4: no
      addresses: [SERVER_IP/24]
      routes:
        - to: default
          via: GATEWAY_IP
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
```

---

## Filesystem Layout

The server uses a structured `/srv` hierarchy separating compose files, persistent data, and backups:

```
/srv/
├── compose/          Docker Compose stacks (one directory per service)
│   ├── nextcloud/
│   ├── pihole/
│   └── ollama/
├── data/             Persistent volume data
│   ├── nextcloud/
│   ├── db/
│   └── redis/
├── backups/          Local backup staging
├── ai/               AI inference data
│   ├── ollama/
│   └── openwebui/
└── logs/             Centralized log staging
```

Data volumes live on a dedicated NVMe drive mounted to `/srv/data` via fstab with UUID-based identification.

---

## Service Stack

### Infrastructure Layer

| Service | Purpose |
|---------|---------|
| Portainer | Container lifecycle management and monitoring |
| Pi-hole | Network-wide DNS filtering and query analytics |
| Docker Compose | Multi-service orchestration |

### Application Layer

| Service | Stack | Purpose |
|---------|-------|---------|
| Nextcloud | nextcloud + MariaDB + Redis | Private cloud storage and file synchronization |
| MariaDB 10.11 | mariadb:10.11 | Nextcloud relational database backend |
| Redis | redis:alpine | Session caching and performance |

### AI and Knowledge Layer

| Service | Purpose |
|---------|---------|
| Ollama | Local LLM inference engine — no external API calls |
| Open WebUI | Browser interface for Ollama model interaction |
| Kiwix | Offline Wikipedia and ZIM archive hosting |

---

## Docker Compose — Nextcloud Stack

```yaml
version: '3'

services:
  nextcloud:
    image: nextcloud:latest
    restart: always
    ports:
      - "SERVER_IP:8080:80"
    volumes:
      - /srv/data/nextcloud:/var/www/html
      - /srv/data/nextcloud/data:/var/www/html/data
    environment:
      - MYSQL_HOST=db
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_PASSWORD=${DB_PASSWORD}
    depends_on:
      db:
        condition: service_healthy

  db:
    image: mariadb:10.11
    restart: always
    volumes:
      - /srv/data/db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_PASSWORD=${DB_PASSWORD}
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:alpine
    restart: always

networks:
  default:
    driver: bridge
```

The port binding `SERVER_IP:8080:80` is intentional. Binding to a specific interface address rather than `0.0.0.0:8080:80` ensures the service is unreachable from interfaces outside the defined scope.

---

## Operations and Maintenance

Deploying infrastructure is a single event. Operating it reliably is an ongoing discipline. The following procedures define the maintenance cadence applied to keep this environment stable, patched, and recoverable.

### Linux Server Maintenance

```bash
# Review available updates
sudo apt update
sudo apt list --upgradable

# Apply system and security updates
sudo apt upgrade -y

# System health snapshot
uptime
df -h
free -h

# Review recent logs for anomalies
journalctl -xe --since "1 hour ago"

# Validate Docker daemon after updates
systemctl status docker

# Planned reboot after kernel updates
sudo reboot
```

All services are configured with `restart: always` or `restart: unless-stopped`. After reboot, container availability is verified within five minutes.

### Docker Maintenance

```bash
# Verify all expected containers are running
docker ps
docker compose ps

# Review container logs for errors
docker compose logs --tail=100 nextcloud
docker compose logs --tail=100 db

# Check port bindings are correct
docker ps --format "table {{.Names}}\t{{.Ports}}"

# Pull updated images (after changelog review)
docker compose pull

# Apply updates with minimal downtime
docker compose up -d

# Remove dangling images after updates
docker image prune -f
```

Image updates are not applied blindly. Release notes and known issues are reviewed before pulling, particularly for Nextcloud and MariaDB where major version upgrades require sequential migration paths.

### Nextcloud Maintenance

Nextcloud updates follow a structured sequence to prevent data corruption or broken migrations:

```bash
# 1. Enable maintenance mode before any update
docker exec -u www-data nextcloud php occ maintenance:mode --on

# 2. Verify backup is current before proceeding

# 3. Pull and apply updated image
docker compose pull nextcloud
docker compose up -d nextcloud

# 4. Run upgrade routine
docker exec -u www-data nextcloud php occ upgrade

# 5. Validate application health
docker exec -u www-data nextcloud php occ status

# 6. Disable maintenance mode
docker exec -u www-data nextcloud php occ maintenance:mode --off

# 7. Verify file sync from a client device
```

App compatibility is checked against the target Nextcloud version before upgrading. Incompatible apps are disabled prior to migration to prevent failed upgrade states.

---

## Backup Strategy

### What Is Backed Up

| Asset | Method | Frequency |
|-------|--------|-----------|
| Nextcloud data directory | `rsync` to secondary location | Daily |
| MariaDB database | `mysqldump` via Docker exec | Daily |
| Docker Compose stacks | Version-controlled in this repo | On change |
| `.env` files | Encrypted, stored offline | On change |
| UFW rules | Documented in `/configs` | On change |
| SSH config | Documented in `/configs` | On change |
| fstab | Documented in `/configs` | On change |

### MariaDB Backup

```bash
docker exec db \
  mysqldump -u root -p"${DB_ROOT_PASSWORD}" nextcloud \
  > /srv/backups/nextcloud_db_$(date +%F).sql
```

### Nextcloud Data Backup

```bash
rsync -avz --progress --delete \
  /srv/data/nextcloud/ \
  /srv/backups/nextcloud-data/
```

### Backup Verification

Backups are tested by restoring to an isolated container and validating database integrity and file accessibility. An unverified backup is not a backup.

```bash
# Verify dump integrity
mysqlcheck --databases nextcloud < /srv/backups/nextcloud_db_YYYY-MM-DD.sql

# Confirm backup volume is consistent
du -sh /srv/backups/
ls -lh /srv/backups/ | tail -10
```

---

## Maintenance Checklists

### Weekly

- [ ] `journalctl -xe` — review for errors or anomalies
- [ ] `docker ps` — all expected containers running
- [ ] `docker compose ps` — all services healthy
- [ ] Pi-hole dashboard — review query logs for unusual traffic
- [ ] Tailscale — verify node connectivity
- [ ] Confirm backup files updated within expected window
- [ ] `df -h` — disk usage within acceptable range

### Monthly

- [ ] Apply pending OS security updates
- [ ] Review UFW logs for blocked connection patterns
- [ ] Pull updated Docker images (after changelog review)
- [ ] Validate Nextcloud file sync from a client device
- [ ] `sudo fail2ban-client status sshd` — verify active and logging
- [ ] Test backup restoration on isolated container
- [ ] Review Tailscale node list for stale entries
- [ ] `sudo nvme smart-log /dev/nvme0` — NVMe drive health

### Before Major Updates

- [ ] MariaDB dump completed and verified
- [ ] Nextcloud data directory backed up
- [ ] Compose files version-controlled
- [ ] Nextcloud maintenance mode enabled
- [ ] App compatibility verified against target version
- [ ] Rollback path documented

### After Major Updates

- [ ] All containers returned to running state
- [ ] `docker exec -u www-data nextcloud php occ status` — healthy
- [ ] File sync validated from client device
- [ ] Pi-hole DNS resolution functional
- [ ] Tailscale connectivity verified
- [ ] `sudo ufw status verbose` — rules intact
- [ ] Maintenance mode confirmed off

---

## Troubleshooting Methodology

When something breaks, there are exactly three layers to investigate in order: **container, service, network.** Skipping ahead wastes time.

```
1. Is the container running?       docker ps
2. Why is it failing?              docker logs <container> --tail=50
3. Is the port open?               ss -tulpn | grep <port>
4. Does it work locally?           curl http://SERVER_IP:PORT
5. Does it work from client?       nc -zv SERVER_IP PORT
6. Firewall check                  sudo ufw status
```

### Docker Bind Failures

**Symptom:** Service unreachable from network after deployment.

**Root cause:** Default Docker port mappings bind to `0.0.0.0` when no interface is specified. Relying on UFW alone is insufficient — bind to the target interface explicitly.

**Resolution:**
```yaml
ports:
  - "SERVER_IP:8080:80"       # LAN only
  - "100.x.x.x:8080:80"      # Tailscale (if needed)
```

**Verification:**
```bash
docker ps --format "table {{.Names}}\t{{.Ports}}"
ss -tulpn | grep 8080
```

---

### MariaDB Healthcheck Failures

**Symptom:** Nextcloud exits at startup. Logs show `SQLSTATE[HY000] [2002] Connection refused`.

**Root cause:** `depends_on` without `condition: service_healthy` only waits for container start, not InnoDB initialization. MariaDB first-run init takes several seconds beyond the container becoming "running."

**Resolution:** Health check using the bundled `healthcheck.sh` script validates InnoDB readiness rather than TCP availability:
```yaml
healthcheck:
  test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
  interval: 10s
  timeout: 5s
  retries: 5
```

---

### Tailscale SSH Tunnel Not Forwarding

**Symptom:** SSH connects via Tailscale IP. Admin panel at forwarded port returns connection refused.

**Root cause:** `AllowTcpForwarding no` in `sshd_config` blocks port forwarding entirely.

**Resolution:** Enable TCP forwarding selectively for the Tailscale interface, or use a `Match` block:
```
Match Address 100.0.0.0/8
    AllowTcpForwarding yes
```

Alternatively, use `-W` flag for direct forwarding without enabling global TCP forwarding.

---

### Persistent Storage Mount Loss After Reboot

**Symptom:** Nextcloud data directory missing after server reboot. Containers start but report missing volume data.

**Root cause:** External drive mount not persisted in `/etc/fstab`.

**Resolution:**
```bash
# Identify UUID
blkid /dev/nvme1n1p1

# Persist mount
echo "UUID=YOUR-UUID  /srv/data  ext4  defaults,noatime,nofail  0  2" | sudo tee -a /etc/fstab

# Reload and verify
sudo mount -a
df -h | grep /srv/data
```

`nofail` prevents boot failure if the drive is temporarily absent. `noatime` reduces unnecessary write cycles.

---

### Wrong Docker Image (Kiwix)

**Symptom:** Kiwix container starts but web interface is inaccessible or returns errors.

**Root cause:** Multiple Kiwix images exist with different internal port mappings and entrypoints. The correct image is `ghcr.io/kiwix/kiwix-serve`, not `kiwix/kiwix-serve` on Docker Hub.

**Resolution:** Specify the correct image explicitly in the Compose file and verify port mapping matches the image's exposed port:
```yaml
image: ghcr.io/kiwix/kiwix-serve:latest
```

---

### Nextcloud Upgrade Stuck in Maintenance Mode

**Symptom:** Nextcloud returns 503 after upgrade attempt. `occ status` shows upgrade state or maintenance locked.

**Root cause:** Incompatible app blocking migration, or maintenance mode left enabled after a failed upgrade run.

**Resolution:**
```bash
# Check detailed logs
docker compose logs --tail=200 nextcloud

# Disable conflicting app
docker exec -u www-data nextcloud php occ app:disable <app_name>

# Re-run upgrade
docker exec -u www-data nextcloud php occ upgrade

# Confirm maintenance mode is off
docker exec -u www-data nextcloud php occ maintenance:mode --off
docker exec -u www-data nextcloud php occ status
```

---

## Lessons Learned

**Interface binding is a security control, not a configuration detail.** Binding services to `0.0.0.0` and relying on UFW creates a single point of failure. One incorrect firewall rule exposes everything listening globally. Binding to specific interfaces removes that dependency entirely.

**`depends_on` is not a readiness guarantee.** Docker startup ordering only verifies container state, not application readiness. Any service with a cold-start initialization window needs an explicit health check before dependent containers will function.

**Nextcloud upgrade paths are sequential, not flexible.** Skipping major versions corrupts the upgrade state. Version-to-version sequencing must be planned before initiating any upgrade.

**Backup verification is the only thing that matters.** A backup that has never been tested in a restore scenario is an assumption, not a backup. MariaDB dumps and Nextcloud data directories are restored periodically to isolated containers to confirm recoverability before they are needed.

**VPN-only administration removes an entire attack category.** Moving SSH and all admin interfaces behind Tailscale dropped authentication-based attack attempts to zero. The attack surface was removed at the network level.

**The `/srv` layout matters operationally.** Separating compose files, persistent data, and backups into a consistent directory structure reduces errors during maintenance and makes backup targeting straightforward.

**Consumer hardware requires explicit BIOS hardening for 24/7 operation.** Power-on-AC and sleep disable settings are not optional — a laptop that enters standby on idle takes down every hosted service.

---

## Future Roadmap

| Phase | Improvement | Impact |
|-------|-------------|--------|
| 1 | Reverse proxy — Caddy or NGINX with internal TLS | HTTPS for all services, unified routing |
| 1 | Internal Certificate Authority | Trusted certs without external dependency |
| 2 | Centralized logging — Loki + Grafana | Cross-service log aggregation and dashboards |
| 2 | Uptime monitoring — Uptime Kuma | Service availability tracking and alerting |
| 3 | Automated backup pipeline with verification | Scheduled, tested, off-server backups |
| 3 | Ansible provisioning playbooks | Repeatable infrastructure deployment |
| 4 | SIEM integration — Wazuh or ELK | Log correlation, alerting, and audit trail |
| 4 | Isolated red team VLAN | Controlled attack simulation environment |
| 5 | Secondary node — high availability | Failover for critical services |
| 5 | Redundant DNS | Pi-hole HA across two hosts |

---

## Skills Demonstrated

| Domain | Specifics |
|--------|-----------|
| Linux Administration | Ubuntu Server, systemd, Netplan, UFW, Fail2Ban, fstab, journalctl, NVMe management |
| Docker | Compose orchestration, health checks, interface binding, volume management, image lifecycle |
| Networking | Network segmentation, DHCP, DNS, static IP, firewall policy, SSH tunneling |
| Security Engineering | Attack surface reduction, defense in depth, VPN-gated access, socket-level isolation |
| Remote Access | Tailscale overlay networking, SSH port forwarding, pivot access patterns |
| DNS Infrastructure | Pi-hole, upstream resolver config, network-wide distribution via DHCP |
| Storage | Dual-NVMe layout, UUID-based fstab, persistent volume management, noatime tuning |
| Operations | Maintenance cadence, change control, backup strategy, upgrade sequencing, rollback planning |
| Troubleshooting | Container/service/network isolation methodology, root cause analysis, systematic documentation |

---

## Repository Structure

```
├── docs/               Architecture, security, and operations documentation
├── diagrams/           Network topology and service architecture diagrams
├── screenshots/        Operational proof — running dashboards and services
├── docker-compose/     Production Compose stacks with hardened port bindings
├── configs/            Hardened configuration references (UFW, SSH, fstab)
├── security/           Security model, hardening checklist, access strategy
├── operations/         Maintenance checklists and operational procedures
├── backups/            Backup scripts and restoration procedures
└── troubleshooting/    Documented incident resolutions with root cause analysis
```

---

## License

MIT. See [LICENSE](LICENSE).
