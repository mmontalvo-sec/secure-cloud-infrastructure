# Architecture Overview

## Design Goals

This infrastructure was designed to satisfy four requirements simultaneously:

1. All services accessible from the local network with no configuration required on client devices
2. All services accessible remotely through an authenticated encrypted channel
3. No service exposed to the public internet under any conditions
4. Infrastructure recoverable from failure without physical access to the server

Every architectural decision flows from these four constraints.

---

## Physical Layer

**Server hardware:** AMD Ryzen 5 3450U, 16GB DDR4, dual NVMe SSDs, running Ubuntu Server 22.04 LTS in headless configuration.

**BIOS configuration:** Power-on-AC enabled, all sleep and standby modes disabled. A headless server that enters standby on idle takes down every hosted service silently.

**Storage layout:**
- NVMe #1: Ubuntu Server OS
- NVMe #2: All persistent data (`/srv/data`), mounted via UUID fstab entry with `nofail`

The `nofail` flag is critical for headless operation — boot succeeds and SSH access is preserved even if the data drive fails to mount.

---

## Network Layer

**ISP:** Claro Fiber, 1Gbps symmetrical, CGNAT environment. No public IP is available for port forwarding.

**Edge device:** Ubiquiti EdgeRouter 4 manages network segmentation. DHCP on all segments is configured to distribute the server's IP as the primary DNS resolver, providing Pi-hole filtering to all clients without per-device configuration.

**Server static IP:** Configured via Netplan (`networkd` renderer). DHCP is not used for the server itself — a static assignment ensures consistent port binding targets.

---

## VPN Layer (Tailscale)

Tailscale provides the authenticated overlay network for all remote access. The CGNAT environment makes traditional port forwarding impossible, which makes Tailscale the only viable path to remote administration.

The result is a stronger security posture than a typical forwarded-port setup:
- No public ports open on the internet-facing edge
- All remote sessions authenticated via Tailscale's control plane
- SSH access restricted to the `tailscale0` interface via UFW

Remote access to LAN-bound services (Portainer, Pi-hole admin) uses SSH port forwarding through the Tailscale session. No additional ports need to be opened.

---

## Service Layer

All services run in Docker containers managed by Docker Compose. Each service has its own Compose stack in `/srv/compose/<service>/` to allow independent restart, update, and troubleshooting without affecting other services.

Portainer provides a web-based management interface for all containers and is itself accessible only via SSH tunnel — never directly exposed to any network interface beyond LAN.

---

## Data Layer

Persistent data for all services lives under `/srv/data/` on the dedicated NVMe. Volume mounts in Compose files reference these absolute paths rather than Docker-managed volumes, making backup targeting and disaster recovery straightforward.

```
/srv/data/
├── nextcloud/     Nextcloud application data
├── db/            MariaDB data directory
├── redis/         Redis persistence
└── pihole/        Pi-hole configuration and logs
```

---

## Security Layer

Security is implemented at four independent levels. Failure or misconfiguration at any one level does not create a viable attack path:

1. **Interface binding** — services do not listen on interfaces where access is not permitted
2. **UFW** — default-deny inbound; rules are subnet-scoped, not port-only
3. **Tailscale** — all remote access requires VPN authentication
4. **SSH hardening** — key-only, root disabled, password auth off at daemon level

Fail2Ban provides brute-force mitigation as an additional layer on SSH, though the Tailscale-only SSH access model means public-facing SSH authentication attempts are already eliminated.
