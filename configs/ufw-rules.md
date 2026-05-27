# UFW Firewall Policy
# Default-deny inbound. All rules are interface and subnet scoped.
# Replace SERVER_SUBNET with your actual LAN subnet (e.g. 192.168.1.0/24)

# --- Default policy ---
sudo ufw default deny incoming
sudo ufw default allow outgoing

# --- SSH via Tailscale only ---
sudo ufw allow in on tailscale0 to any port 22 proto tcp

# --- Nextcloud (LAN only) ---
sudo ufw allow from SERVER_SUBNET to any port 8080 proto tcp

# --- Portainer (LAN only) ---
sudo ufw allow from SERVER_SUBNET to any port 9443 proto tcp

# --- Pi-hole DNS (LAN) ---
sudo ufw allow from SERVER_SUBNET to any port 53 proto tcp
sudo ufw allow from SERVER_SUBNET to any port 53 proto udp

# --- Pi-hole admin UI (LAN only) ---
sudo ufw allow from SERVER_SUBNET to any port 8081 proto tcp

# --- Open WebUI / Ollama (LAN only) ---
sudo ufw allow from SERVER_SUBNET to any port 3000 proto tcp
sudo ufw allow from SERVER_SUBNET to any port 11434 proto tcp

# --- Enable ---
sudo ufw enable
sudo ufw status verbose

# --- Verify nothing is exposed globally ---
sudo ss -tulpn | grep -v "127.0.0.1\|::1"
