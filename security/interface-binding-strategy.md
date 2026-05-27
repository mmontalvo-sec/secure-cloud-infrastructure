# Interface Binding Strategy

## The Problem with 0.0.0.0

When a Docker container binds to `0.0.0.0:PORT`, it listens on every network interface on the host:
- LAN interface
- Tailscale interface (100.x.x.x)
- Loopback (127.0.0.1)
- Any future interface added to the system

Relying on UFW to restrict access from unintended interfaces creates a single point of failure in the security model. One incorrect rule change exposes everything bound globally.

## The Solution: Explicit Interface Binding

Services are configured to bind only to the interfaces where access is intentionally permitted.

### Binding Reference

| Binding | Accessible from |
|---------|----------------|
| `127.0.0.1:PORT` | Local machine only |
| `SERVER_IP:PORT` | LAN network only |
| `100.x.x.x:PORT` | Tailscale VPN clients only |
| `0.0.0.0:PORT` | Everywhere — avoid |

### Docker Compose Example

```yaml
# Wrong — global binding
ports:
  - "8080:80"

# Correct — LAN only
ports:
  - "SERVER_IP:8080:80"

# Correct — LAN + Tailscale (when both needed)
ports:
  - "SERVER_IP:8080:80"
  - "100.x.x.x:8080:80"
```

### Verification

After deploying any stack, verify bindings:

```bash
# Check Docker port mappings
docker ps --format "table {{.Names}}\t{{.Ports}}"

# Check what the OS is actually listening on
sudo ss -tulpn | grep <port>

# Confirm no 0.0.0.0 listeners for sensitive services
sudo ss -tulpn | grep "0.0.0.0"
```

## SSH Pivot Access Pattern

For services intentionally bound to LAN only, remote access is handled through SSH port forwarding over the Tailscale VPN session. No additional port bindings are needed.

```bash
# Forward a LAN-only service through Tailscale SSH
ssh -L LOCAL_PORT:SERVER_IP:SERVICE_PORT user@100.x.x.x

# Examples
ssh -L 9443:SERVER_IP:9443 user@100.x.x.x    # Portainer
ssh -L 8080:SERVER_IP:8080 user@100.x.x.x    # Nextcloud
ssh -L 8081:SERVER_IP:8081 user@100.x.x.x    # Pi-hole dashboard

# Then access in browser
https://localhost:9443
http://localhost:8081/admin
```

This pattern provides full remote access to any LAN-bound service with no additional firewall rules, no new port exposures, and no changes to service configuration. The security boundary remains unchanged.
