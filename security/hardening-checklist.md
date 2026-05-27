# Security Hardening Checklist

Complete this checklist on initial provisioning and re-validate monthly.

## BIOS / Firmware

- [ ] Power-on-AC enabled (headless server never stays off after power cycle)
- [ ] Sleep / Modern Standby disabled
- [ ] Secure Boot enabled (Ubuntu supports it)
- [ ] Virtualization (AMD-V / SVM) enabled
- [ ] Fast Boot optional (leave ON)

## OS Baseline

- [ ] Ubuntu Server 22.04 LTS (not Desktop)
- [ ] Non-root admin user created during install
- [ ] OpenSSH server installed
- [ ] Full system update applied: `sudo apt update && sudo apt full-upgrade -y`
- [ ] `unattended-upgrades` installed and enabled for security patches
- [ ] Unnecessary packages removed

## SSH

- [ ] SSH key pair generated on client
- [ ] Public key deployed to `~/.ssh/authorized_keys` on server
- [ ] `PermitRootLogin no`
- [ ] `PasswordAuthentication no`
- [ ] `KbdInteractiveAuthentication no`
- [ ] `X11Forwarding no`
- [ ] `AllowTcpForwarding no` (except Tailscale Match block)
- [ ] SSH service restarted and verified operational

## Firewall (UFW)

- [ ] Default deny inbound
- [ ] Default allow outbound
- [ ] SSH restricted to Tailscale interface only
- [ ] All service ports restricted to LAN subnet
- [ ] No rules binding globally to 0.0.0.0
- [ ] `sudo ufw enable`
- [ ] `sudo ufw status verbose` reviewed

## Fail2Ban

- [ ] Fail2Ban installed
- [ ] `jail.local` configured (not editing `jail.conf` directly)
- [ ] sshd jail enabled
- [ ] Service active: `sudo fail2ban-client status`

## Tailscale

- [ ] Tailscale installed and authenticated
- [ ] Node visible in Tailscale admin panel
- [ ] SSH reachable via Tailscale IP
- [ ] ACL policy reviewed — only authorized devices in network

## Docker

- [ ] Docker installed via official repo (not Ubuntu snap)
- [ ] Docker Compose v2 installed
- [ ] No containers binding to 0.0.0.0
- [ ] All port bindings verified: `docker ps --format "table {{.Names}}\t{{.Ports}}"`
- [ ] All Compose stacks in `/srv/compose/`
- [ ] Portainer access via SSH tunnel only (not direct internet)

## Storage

- [ ] NVMe #2 partitioned, formatted ext4, UUID-mounted to `/srv/data`
- [ ] fstab entry uses UUID (not /dev/nvme1n1p1)
- [ ] `nofail` flag set
- [ ] `noatime` flag set
- [ ] Mount verified: `df -h | grep /srv/data`

## Monitoring Baseline

- [ ] `journalctl` accessible and logging
- [ ] `sudo ss -tulpn` reviewed — no unexpected listeners
- [ ] `docker ps` shows all expected containers running
- [ ] Backup schedule active and verified
