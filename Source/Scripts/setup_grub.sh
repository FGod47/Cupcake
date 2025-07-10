#!/bin/bash

# ──────────────── Load Colors ────────────────
source "$HOME/Cupcake/Source/Scripts/colors.sh"

# ──────────────── Pastel Banner Colors ────────────────
COLORS=(15)

# ──────────────── Banner ────────────────
BANNER=(
"█▀ █▀▀ ▀█▀ ▀█▀ █ █▄░█ █▀▀ █░█ █▀█   █▀▀ █▀█ █░█ █▄▄"
"▄█ ██▄ ░█░ ░█░ █ █░▀█ █▄█ █▄█ █▀▀   █▄█ █▀▄ █▄█ █▄█"
)

# ──────────────── Spinner Animation ────────────────
spinner() {
    local pid=$!
    local i=0
    local spin='|/-\\'
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        printf "\r[*] %-30s %s" "$1" "${spin:$i:1}"
        sleep 0.1
    done
    printf "\r\033[K"
}

# ──────────────── Sudo Authentication ────────────────
sudo -v || { echo -e "${RED}✘ Sudo authentication failed. Exiting.${RESET}"; exit 1; }

# ──────────────── Show Banner ────────────────
echo
for line in "${BANNER[@]}"; do
    COLOR="\033[38;5;${COLORS[RANDOM % ${#COLORS[@]}]}m"
    echo -e "${COLOR}${line}${RESET}"
done
echo

# ──────────────── Variables ────────────────
SRC="$HOME/Cupcake/.config/grub/cupcake"
DEST="/usr/share/grub/themes/cupcake"
GRUB_CFG="/etc/default/grub"
THEME_LINE='GRUB_THEME="/usr/share/grub/themes/cupcake/theme.txt"'
OS_PROBER_LINE='GRUB_DISABLE_OS_PROBER=false'

# ──────────────── Copy Theme Folder ────────────────
if [ ! -d "$SRC" ]; then
    echo -e "${RED}[FAIL]${RESET} Source not found: $SRC"
    exit 1
fi

echo -e "${YELLOW}[INFO]${RESET} Installing Cupcake GRUB theme..."
(
    sudo mkdir -p "$DEST"
    sudo cp -r "$SRC/"* "$DEST/"
) & spinner "Copying files to GRUB theme directory"
echo -e "${GREEN}[DONE]${RESET} Theme installed"

# ──────────────── Update GRUB Theme Line ────────────────
(
    if grep -q '^GRUB_THEME=' "$GRUB_CFG"; then
        sudo sed -i "s|^GRUB_THEME=.*|$THEME_LINE|" "$GRUB_CFG"
    elif grep -q 'GRUB_THEME=' "$GRUB_CFG"; then
        sudo sed -i "s|^#\?GRUB_THEME=.*|$THEME_LINE|" "$GRUB_CFG"
    else
        echo "$THEME_LINE" | sudo tee -a "$GRUB_CFG" >/dev/null
    fi
) & spinner "Applying GRUB_THEME"
echo -e "${GREEN}[DONE]${RESET} GRUB_THEME set"

# ──────────────── Enable OS Prober ────────────────
(
    if grep -q '^#\?GRUB_DISABLE_OS_PROBER=' "$GRUB_CFG"; then
        sudo sed -i "s|^#\?GRUB_DISABLE_OS_PROBER=.*|$OS_PROBER_LINE|" "$GRUB_CFG"
    else
        echo "$OS_PROBER_LINE" | sudo tee -a "$GRUB_CFG" >/dev/null
    fi
) & spinner "Enabling OS Prober"
echo -e "${GREEN}[DONE]${RESET} OS Prober enabled"

# ──────────────── Regenerate GRUB Config ────────────────
(
    sudo grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1
) & spinner "Updating grub.cfg"
echo -e "${GREEN}[DONE]${RESET} grub.cfg updated"

# ──────────────── Complete ────────────────
echo -e "\n${GREEN}[SUCCESS]${RESET} Cupcake GRUB theme applied successfully!\n"
