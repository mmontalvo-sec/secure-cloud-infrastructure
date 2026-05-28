# Security Review: Tailscale Access Control

**Date:** 2026-05
**Type:** Access control security review
**Performed by:** System administrator

---

## Purpose

Review the Tailscale configuration from a security perspective to confirm that access to the infrastructure is restricted to authorized devices and that no unintended exposure exists.

---

## Scope

Tailscale node inventory, access policy, key management, and SSH access control.

---

## Checks Performed

| Check | Command | Result |
|-------|---------|--------|
| Node inventory | `tailscale status` | Only authorized nodes present |
| Key expiry status | Tailscale admin console | Keys current, no expiry within 30 days |
| ACL policy review | Tailscale admin console ACLs | Policy restricts access to tagged devices only |
| SSH access test | Tailscale SSH from authorized device | Functional |
| Public port exposure | `sudo ufw status verbose` + external scan | No public ports exposed |

---

## Tailscale Security Posture

| Item | Status |
|------|--------|
| Public-facing management interface | None |
| Service ports exposed to internet | None |
| Tailscale SSH enabled | Yes, replaces traditional SSH port exposure |
| Traditional SSH port (22) open publicly | No |
| Device authentication required | Yes |
| Unauthorized nodes in tailnet | None found |

---

## Issues Found

None. Access control posture confirmed as designed: no public exposure, VPN-only access, authorized devices only.

---

## Fix or Recommendation

- Review tailnet node list monthly and remove any decommissioned or lost devices immediately
- Rotate access credentials if any authorized device is lost or compromised
- Consider enabling Tailscale device posture checks if the admin account supports it

---

## Next Review Date

2026-06-30

---

## Notes

Tailscale-based access control is the primary security boundary for this infrastructure. All services bind to internal interfaces only. UFW default deny inbound ensures that even if Tailscale were bypassed, no services are reachable from the public internet.
