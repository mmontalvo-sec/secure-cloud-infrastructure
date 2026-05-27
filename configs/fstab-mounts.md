# fstab Mount Configuration
# Persistent NVMe mount for /srv/data
# UUID-based — survives device enumeration changes across reboots

# --- Step 1: Identify UUID ---
# blkid /dev/nvme1n1p1

# --- Step 2: Add to /etc/fstab ---
# UUID=YOUR-UUID-HERE  /srv/data  ext4  defaults,noatime,nofail  0  2

# Options explained:
#   defaults  — standard mount options (rw, suid, exec, auto, nouser, async)
#   noatime   — skip access time writes; reduces unnecessary NVMe write cycles
#   nofail    — boot succeeds even if drive is absent (safe for headless)
#   0         — no dump
#   2         — fsck runs after root (0 = skip, 1 = root only, 2 = other)

# --- Step 3: Mount and verify ---
# sudo mount -a
# df -h | grep /srv/data

# --- Verify on reboot ---
# sudo reboot
# df -h | grep /srv/data
