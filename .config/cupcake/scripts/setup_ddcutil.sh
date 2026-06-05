#!/bin/bash

echo "Configuring ddcutil and i2c for external monitor brightness control..."

# Install ddcutil and i2c-tools if not present
if ! command -v ddcutil &> /dev/null; then
    echo "Installing ddcutil and i2c-tools..."
    sudo pacman -S --needed --noconfirm ddcutil i2c-tools
fi

# Load i2c-dev module and configure it to load on boot
echo "Loading i2c-dev module..."
sudo modprobe i2c-dev
echo 'i2c-dev' | sudo tee /etc/modules-load.d/i2c-dev.conf > /dev/null

# Add current user to i2c group
if ! groups "$USER" | grep -q '\bi2c\b'; then
    echo "Adding $USER to i2c group..."
    sudo usermod -aG i2c "$USER"
    echo "Group i2c added. Please log out and log back in for permissions to take effect!"
else
    echo "$USER is already in the i2c group."
fi

echo "ddcutil and i2c configuration complete!"
