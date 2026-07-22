#!/bin/bash

# Setup Plymouth Theme
echo -e "   \033[1;36m[...]\033[0m Installing Cupcake Plymouth theme..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../.. && pwd)"

# Copy theme files
sudo mkdir -p /usr/share/plymouth/themes/cupcake
sudo cp -r "$SCRIPT_DIR/Source/plymouth/cupcake/"* /usr/share/plymouth/themes/cupcake/

# Set Plymouth theme
sudo plymouth-set-default-theme cupcake

# Ensure 'splash' is in kernel parameters for UKI
if [ -f /etc/kernel/cmdline ]; then
    if ! grep -q "splash" /etc/kernel/cmdline; then
        echo -e "   \033[1;33m[!]\033[0m Adding 'splash' to /etc/kernel/cmdline for UKI..."
        sudo sed -i 's/$/ splash/' /etc/kernel/cmdline
    fi
fi

# Ensure 'splash' is in GRUB just in case
if [ -f /etc/default/grub ]; then
    if ! grep -q "splash" /etc/default/grub; then
        echo -e "   \033[1;33m[!]\033[0m Adding 'splash' to /etc/default/grub..."
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 splash"/' /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1
    fi
fi

# Ensure plymouth hook is in mkinitcpio.conf
if [ -f /etc/mkinitcpio.conf ]; then
    if ! grep -q "plymouth" /etc/mkinitcpio.conf; then
        echo -e "   \033[1;33m[!]\033[0m Adding 'plymouth' hook to /etc/mkinitcpio.conf..."
        sudo sed -i 's/HOOKS=(\(.*\)udev\(.*\))/HOOKS=(\1udev plymouth\2)/' /etc/mkinitcpio.conf
    fi
fi

# Explicitly rebuild UKI/initramfs
echo -e "   \033[1;36m[...]\033[0m Rebuilding UKI and Initramfs (this may take a moment)..."
sudo mkinitcpio -P >/dev/null 2>&1

echo -e "   \033[1;32m[OK]\033[0m Cupcake Plymouth theme installed successfully!"
