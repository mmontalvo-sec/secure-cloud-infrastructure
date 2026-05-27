# Monthly Maintenance Checklist

Run once per month. Includes updates, verification, and hardware health.

## OS Updates

```bash
sudo apt update
sudo apt list --upgradable
sudo apt upgrade -y
sudo reboot
```

- [ ] Pending updates reviewed before applying
- [ ] Kernel updates trigger planned reboot
- [ ] All services recovered after reboot: `docker ps`

## Docker Image Updates

```bash
# Review changelogs for each service before pulling
docker compose -f /srv/compose/nextcloud/docker-compose.yml pull
docker compose -f /srv/compose/pihole/docker-compose.yml pull
docker compose -f /srv/compose/portainer/docker-compose.yml pull

# Apply updates
docker compose -f /srv/compose/nextcloud/docker-compose.yml up -d
docker compose -f /srv/compose/pihole/docker-compose.yml up -d
docker compose -f /srv/compose/portainer/docker-compose.yml up -d

# Clean up unused images
docker image prune -f
```

- [ ] Nextcloud changelog reviewed — no breaking changes in target version
- [ ] MariaDB changelog reviewed — no major version jump without upgrade planning
- [ ] Images updated and containers healthy

## Security Verification

```bash
sudo ufw status verbose
sudo fail2ban-client status sshd
sudo ss -tulpn | grep "0.0.0.0"
```

- [ ] UFW rules match expected policy — no unexpected changes
- [ ] Fail2Ban active, sshd jail running
- [ ] No services listening on 0.0.0.0 unexpectedly

## Backup Restoration Test

Restore MariaDB dump to an isolated container and verify database integrity.

```bash
# Spin up a test MariaDB instance
docker run --rm -d --name test_db \
  -e MYSQL_ROOT_PASSWORD=testpass \
  mariadb:10.11

# Restore latest backup
docker exec -i test_db \
  mysql -u root -ptestpass < /srv/backups/nextcloud_db_YYYY-MM-DD.sql

# Verify tables
docker exec test_db mysql -u root -ptestpass -e "USE nextcloud; SHOW TABLES;"

# Cleanup
docker stop test_db
```

- [ ] Backup restored without errors
- [ ] Table count matches expected
- [ ] Test container cleaned up

## Hardware Health

```bash
sudo nvme smart-log /dev/nvme0
sudo nvme smart-log /dev/nvme1
```

- [ ] No critical warnings
- [ ] Reallocated sectors: 0
- [ ] Temperature within normal range

## Tailscale

```bash
tailscale status
```

- [ ] Node connected and authenticated
- [ ] No stale nodes in network

## Nextcloud File Sync

- [ ] Log in to Nextcloud from a client device
- [ ] Upload a test file and verify it appears
- [ ] Verify sync client reflects changes
