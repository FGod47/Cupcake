#!/bin/bash
# Setup script to configure UFW / Firewalld / IP Forwarding for Wi-Fi Hotspots

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

echo -e "${GREEN}[HOTSPOT FIREWALL FIX]${RESET} Configuring Firewall & NetworkManager for Hotspots..."

# 1. Ensure kernel IP forwarding configuration
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-cupcake-ipforward.conf >/dev/null
sudo sysctl -p /etc/sysctl.d/99-cupcake-ipforward.conf >/dev/null 2>&1 || true

# 2. Configure UFW if installed
if command -v ufw &>/dev/null; then
    echo -e "${GREEN}[UFW]${RESET} Configuring UFW firewall rules for Wi-Fi Hotspot..."
    sudo sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
    
    # Get active wifi device names (e.g., wlan0)
    WIFI_DEVS=$(nmcli -t -f DEVICE,TYPE dev | grep ':wifi$' | cut -d: -f1)
    for dev in $WIFI_DEVS; do
        sudo ufw allow in on "$dev" >/dev/null 2>&1 || true
    done
    sudo ufw reload >/dev/null 2>&1 || true
fi

# 3. Configure firewalld if active
if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld; then
    echo -e "${GREEN}[FIREWALLD]${RESET} Adding wifi interfaces to trusted zone..."
    WIFI_DEVS=$(nmcli -t -f DEVICE,TYPE dev | grep ':wifi$' | cut -d: -f1)
    for dev in $WIFI_DEVS; do
        sudo firewall-cmd --zone=trusted --add-interface="$dev" --permanent >/dev/null 2>&1 || true
    done
    sudo firewall-cmd --reload >/dev/null 2>&1 || true
fi

# 4. Install NetworkManager Dispatcher Script
if [ -d /etc/NetworkManager/dispatcher.d ]; then
    echo -e "${GREEN}[NETWORKMANAGER]${RESET} Installing Hotspot Dispatcher Script..."
    sudo cp "$SCRIPT_DIR/99-hotspot-firewall.sh" /etc/NetworkManager/dispatcher.d/99-hotspot-firewall.sh
    sudo chmod +x /etc/NetworkManager/dispatcher.d/99-hotspot-firewall.sh
fi

echo -e "${GREEN}[SUCCESS]${RESET} Hotspot firewall fix applied successfully!"
