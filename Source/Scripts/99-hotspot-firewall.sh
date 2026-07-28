#!/bin/bash
# NetworkManager Dispatcher Script for Cupcake Hotspot Firewall Compatibility

IFACE="$1"
ACTION="$2"

if [ "$ACTION" = "up" ]; then
    # Check if interface is acting as Access Point / Shared Connection
    IP4_METHOD=$(nmcli -g ipv4.method dev show "$IFACE" 2>/dev/null)
    
    if [ "$IP4_METHOD" = "shared" ]; then
        # 1. Enable kernel IP forwarding
        sysctl -w net.ipv4.ip_forward=1 &>/dev/null || true

        # 2. Configure UFW if installed
        if command -v ufw &>/dev/null; then
            sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw 2>/dev/null || true
            ufw allow in on "$IFACE" &>/dev/null || true
            ufw reload &>/dev/null || true
        fi

        # 3. Configure firewalld if running
        if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld; then
            firewall-cmd --zone=trusted --add-interface="$IFACE" &>/dev/null || true
        fi
    fi
fi
