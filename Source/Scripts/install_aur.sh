#!/bin/bash

# ──────────────── Clear and Load Colors ────────────────
clear
source "$HOME/Cupcake/Source/Scripts/colors.sh"

COLORS=(15)

# ──────────────── AUR Banner ────────────────
AUR_BANNER=(
""
""
"█▀ █▀▀ █░░ █▀▀ █▀▀ ▀█▀   ▄▀█ █░█ █▀█   █░█ █▀▀ █░░ █▀█ █▀▀ █▀█"
"▄█ ██▄ █▄▄ ██▄ █▄▄ ░█░   █▀█ █▄█ █▀▄   █▀█ ██▄ █▄▄ █▀▀ ██▄ █▀▄"
)

for line in "${AUR_BANNER[@]}"; do
    COLOR="\033[38;5;${COLORS[RANDOM % ${#COLORS[@]}]}m"
    echo -e "${COLOR}${line}${RESET}"
done
echo

# ──────────────── Variables ────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
aur_helper=""
repo_url=""

# ──────────────── Detect AUR Helper ────────────────
if command -v yay &>/dev/null; then
    aur_helper="yay"
elif command -v paru &>/dev/null; then
    aur_helper="paru"
fi

# ──────────────── Prompt Install If Not Found ────────────────
if [[ -z "$aur_helper" ]]; then
    echo -e "${YELLOW}➤ No AUR helper found. Choose one to install:${RESET}"
    echo -e "  1) yay"
    echo -e "  2) paru"
    read -rp "  Enter your choice [1/2]: " choice

    if [[ "$choice" == "1" ]]; then
        aur_helper="yay"
        repo_url="https://aur.archlinux.org/yay.git"
    elif [[ "$choice" == "2" ]]; then
        aur_helper="paru"
        repo_url="https://aur.archlinux.org/paru.git"
    else
        echo -e "${RED}[ERROR]${RESET} Invalid selection. Exiting."
        exit 1
    fi

    echo -e "\n${TEXT}[*] Installing prerequisites...${RESET}"
    sudo pacman -S --needed git base-devel --noconfirm

    echo -e "${TEXT}[*] Cloning $aur_helper from AUR...${RESET}"
    git clone "$repo_url" || { echo -e "${RED}[FAIL]${RESET} Git clone failed."; exit 1; }

    cd "$aur_helper" || exit 1

    echo -e "${TEXT}[*] Building and installing $aur_helper...${RESET}"
    makepkg -si --noconfirm || { echo -e "${RED}[FAIL]${RESET} makepkg failed."; exit 1; }

    echo -e "${TEXT}[*] Cleaning up...${RESET}"
    cd ..
    rm -rf "$aur_helper"

    echo -e "${GREEN}[DONE]${RESET} $aur_helper installed successfully."
else
    echo -e "${GREEN}[SKIP]${RESET} $aur_helper already installed."
fi

# ──────────────── Continue to Package Script ────────────────
echo -e "\n${YELLOW}[*] Running install_pkg.sh...${RESET}"
bash "$SCRIPT_DIR/install_pkg.sh"
