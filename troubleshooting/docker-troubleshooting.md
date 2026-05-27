# Docker Troubleshooting Methodology

## Core Rule

When something breaks, there are exactly three layers to investigate — in this order:

1. **Container** — is it running?
2. **Service** — is it listening on the right port?
3. **Network** — can you reach it from the right place?

Skipping ahead wastes time. Start at layer 1 every time.

---

## Phase 1 — Container Level

```bash
# What's running
docker ps

# Everything, including dead containers
docker ps -a

# Container states to look for:
#   Up         → running normally
#   Restarting → crash loop — check logs immediately
#   Exited     → dead — check logs

# Logs — most important command
docker logs <container> --tail=50
docker compose logs --tail=100 <service>

# Container details (mounts, env, network)
docker inspect <container>

# Restart
docker restart <container>

# Kill and remove if broken
docker stop <container>
docker rm <container>
```

---

## Phase 2 — Service Level

Container running does not mean the service inside is working.

```bash
# Check what ports are actually listening
ss -tulpn

# Filter by port
ss -tulpn | grep 9443
ss -tulpn | grep 8081
ss -tulpn | grep 53

# Expected output for a LAN-bound service:
# LISTEN  0.0.0.0  SERVER_IP:9443

# Test the service locally from the server
curl -k https://SERVER_IP:9443
curl http://SERVER_IP:8081
curl http://SERVER_IP:53

# Enter container for deep debug
docker exec -it <container> bash
```

---

## Phase 3 — Network Level

Service works locally but not from your client machine → network problem.

```bash
# From your client machine:

# Basic connectivity
ping SERVER_IP

# Test specific port
nc -zv SERVER_IP 9443
nc -zv SERVER_IP 8081

# If using SSH tunnel
ssh -L 9443:SERVER_IP:9443 user@100.x.x.x
curl -k https://localhost:9443
```

---

## Phase 4 — Firewall

```bash
# Check UFW status
sudo ufw status verbose

# Check if a specific port is blocked
sudo ufw status | grep 9443

# Temporarily allow to test (then remove if not needed)
sudo ufw allow 9443/tcp
```

---

## Phase 5 — Port Binding Verification

```bash
# Check exactly what IP each container is bound to
docker ps --format "table {{.Names}}\t{{.Ports}}"

# Binding reference:
#   SERVER_IP:9443->9443/tcp  = LAN only (correct)
#   0.0.0.0:9443->9443/tcp    = everywhere (investigate)
#   127.0.0.1:9443->9443/tcp  = localhost only
```

---

## Phase 6 — SSH Tunnel (Pivot Access)

For LAN-bound admin panels accessed remotely via Tailscale:

```bash
# Tunnel from local client to LAN-bound service
ssh -L 9443:SERVER_IP:9443 user@100.x.x.x

# In a separate terminal, test the tunnel
curl -k https://localhost:9443

# Common reason tunnel fails:
# AllowTcpForwarding no in sshd_config
# Fix: add Match block for Tailscale subnet
```

---

## Quick Reference — One-Liner Diagnostic

```bash
docker ps && ss -tulpn | grep <port> && curl -sk http://SERVER_IP:<port>
```

---

## Common Failure Patterns

| Symptom | Most Likely Cause | First Check |
|---------|-----------------|-------------|
| Container in Restarting loop | Bad config or missing env var | `docker logs <container>` |
| Port open on server, unreachable from client | UFW blocking | `sudo ufw status` |
| Port not open at all | Service not starting inside container | `ss -tulpn` then `docker logs` |
| HTTPS giving SSL error | HTTP vs HTTPS mismatch in URL | Use `curl -k` first |
| DNS not resolving | Pi-hole down or wrong DNS configured | `docker ps | grep pihole` |
| Nextcloud 503 after update | Maintenance mode left on | `docker exec -u www-data nextcloud php occ maintenance:mode --off` |
| Wrong Kiwix image | Docker Hub image vs ghcr.io image | Use `ghcr.io/kiwix/kiwix-serve:latest` |
| SSH tunnel not forwarding | AllowTcpForwarding disabled | Add Tailscale Match block to sshd_config |
