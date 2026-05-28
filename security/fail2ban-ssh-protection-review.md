# Security Review: Fail2Ban SSH Protection

**Date:** 2026-05
**Type:** Intrusion prevention review
**Performed by:** System administrator

---

## Purpose

Review the Fail2Ban configuration protecting SSH access to confirm that it is active, correctly configured, and banning as expected.

---

## Scope

Fail2Ban daemon status, SSH jail configuration, ban log review.

---

## Commands Used

```bash
# Confirm Fail2Ban is running
sudo systemctl status fail2ban

# Check SSH jail status
sudo fail2ban-client status sshd

# Review recent ban activity
sudo fail2ban-client status sshd | grep -i "banned\|total"

# Review Fail2Ban log for recent activity
sudo tail -50 /var/log/fail2ban.log
```

---

## Expected Result

Fail2Ban service active and running. SSH jail enabled with configured ban time, find time, and max retry values. Log shows active monitoring.

---

## Validation Result

Fail2Ban confirmed active and running. SSH jail enabled. Configuration reviewed:

| Parameter | Value |
|-----------|-------|
| Jail name | sshd |
| Status | Active |
| Max retries | 5 |
| Find time | 10 minutes |
| Ban time | 1 hour |
| Currently failed | Within normal range |
| Total banned | Minimal, consistent with VPN-only access design |

Log review showed Fail2Ban is monitoring the SSH auth log and has been active since service startup. Low ban count is expected because SSH is not exposed to the public internet; access is Tailscale-only, so external brute-force attempts are not reaching the SSH service.

---

## Issues Found

None. Fail2Ban is functioning as configured.

---

## Fix or Recommendation

- The low ban count is expected and correct, not a sign that Fail2Ban is not working
- If SSH were ever temporarily exposed to a public interface, the ban count would increase significantly; this confirms the value of the VPN-first design
- Consider increasing ban time for repeat offenders if future scans show persistent attempts from specific IPs

---

## Next Review Date

2026-06-30

---

## Defense-in-Depth Note

Fail2Ban is the third layer of SSH protection in this environment:

1. Tailscale VPN: Only authorized devices reach the server
2. SSH key-only authentication: Password authentication disabled
3. Fail2Ban: Bans IPs with repeated failed attempts

All three layers must fail simultaneously for an unauthorized user to gain SSH access. This is intentional defense-in-depth design.
