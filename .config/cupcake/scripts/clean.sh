#!/bin/bash

echo "🧹 Cleaning orphan packages..."
sudo pacman -Rns $(pacman -Qdtq)

echo "🧼 Clearing old cache..."
sudo paccache -rk2

echo "📦 Removing unused flatpaks..."
flatpak uninstall --unused -y

echo "🗂 Clearing yay cache..."
yay -Sc --noconfirm

echo "📝 Vacuuming journal logs..."
sudo journalctl --vacuum-time=7d

echo "✅ Done!"
