#!/bin/bash

echo -e "\n\033[1;34m[ 󰖩 ]\033[0m \033[1mConfiguring Wi-Fi Adapters...\033[0m"

# Check for MEDIATEK MT7902
if lspci -nn | grep -qi "14c3:7902"; then
    echo -e "   \033[1;32m[DETECTED]\033[0m MT7902 Wi-Fi Adapter found."
    echo -e "   \033[1;36m[ACTION]\033[0m Forcing 'mt7921e' kernel driver for this adapter..."
    
    sudo bash -c 'cat > /etc/modprobe.d/mt7902.conf <<EOF
# Alias for Mediatek MT7902 to use mt7921e driver
alias pci:v000014C3d00007902sv*sd*bc*sc*i* mt7921e
EOF'
    sudo modprobe mt7921e 2>/dev/null || true
    echo -e "   \033[1;32m[DONE]\033[0m Wi-Fi driver configured successfully."
else
    echo -e "   \033[1;33m[SKIP]\033[0m MT7902 adapter not found. Skipping MT7902 driver override."
fi
