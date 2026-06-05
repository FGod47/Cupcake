#!/bin/bash

# ──────────────── Load Colors ────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"

# ──────────────── Pastel Banner Colors ────────────────
COLORS=(15)

# ──────────────── Banner ────────────────
BANNER=(
"█▀ █▀█ █░░ ▄▀█ █▀ █░█"
"▄█ █▀▀ █▄▄ █▀█ ▄█ █▀█"
)

# ──────────────── Spinner Animation ────────────────
spinner() {
    local pid=$!
    local i=0
    local spin='|/-\'
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
SRC="$SCRIPT_DIR/../custom-splash-1080p.bmp"
DEST="/usr/share/systemd/bootctl/splash-arch.bmp"

# ──────────────── Copy Splash Image ────────────────
if [ ! -f "$SRC" ]; then
    echo -e "${RED}[FAIL]${RESET} Source image not found: $SRC"
    exit 1
fi

echo -e "${YELLOW}[INFO]${RESET} Setting up custom boot splash..."
(
    sudo cp "$SRC" "$DEST"
) & spinner "Injecting custom splash image"
echo -e "${GREEN}[DONE]${RESET} Splash image installed"

# ──────────────── Rebuild Kernel Initramfs ────────────────
(
    sudo mkinitcpio -P >/dev/null 2>&1
) & spinner "Rebuilding kernel UKI images"
echo -e "${GREEN}[DONE]${RESET} Initramfs rebuilt"

# ──────────────── Complete ────────────────
echo -e "\n${GREEN}[SUCCESS]${RESET} Custom UKI boot splash applied successfully!\n"
