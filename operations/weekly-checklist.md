# Weekly Maintenance Checklist

Run every week. Takes under 10 minutes.

## System Health

```bash
uptime
df -h
free -h
```

- [ ] Uptime looks correct (no unexpected reboots)
- [ ] Disk usage below 80% on all mounts
- [ ] Memory usage reasonable

## Container Status

```bash
docker ps
docker compose -f /srv/compose/nextcloud/docker-compose.yml ps
docker compose -f /srv/compose/pihole/docker-compose.yml ps
```

- [ ] All expected containers show as `Up`
- [ ] No containers in `Restarting` or `Exited` state

## Log Review

```bash
journalctl -xe --since "7 days ago" --priority=err
docker compose -f /srv/compose/nextcloud/docker-compose.yml logs --tail=50
```

- [ ] No unexpected errors in system logs
- [ ] No unexpected errors in container logs

## Security

```bash
sudo fail2ban-client status sshd
sudo ufw status
```

- [ ] Fail2Ban sshd jail active and running
- [ ] UFW rules unchanged

## Network

```bash
# Verify Pi-hole is resolving
nslookup google.com SERVER_IP

# Verify Tailscale node is connected
tailscale status
```

- [ ] Pi-hole DNS responding correctly
- [ ] Tailscale node shows connected

## Backups

```bash
ls -lh /srv/backups/ | tail -10
du -sh /srv/backups/
```

- [ ] Backup files updated within last 24 hours
- [ ] No unexpected size changes
