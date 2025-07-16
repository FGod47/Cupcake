#!/bin/bash

# ──────────────── Load Colors ────────────────
source "$HOME/Cupcake/Source/Scripts/colors.sh"

# ──────────────── Pastel Banner Colors ────────────────
COLORS=(15)

# ──────────────── Banner ────────────────
BANNER=(
"█ █▄░█ █▀ ▀█▀ ▄▀█ █░░ █░░ █ █▄░█ █▀▀   █▀█ ▄▀█ █▀▀ █▄▀ ▄▀█ █▀▀ █▀▀ █▀"
"█ █░▀█ ▄█ ░█░ █▀█ █▄▄ █▄▄ █ █░▀█ █▄█   █▀▀ █▀█ █▄▄ █░█ █▀█ █▄█ ██▄ ▄█"
)

# ──────────────── Spinner Animation ────────────────
spinner() {
    local pid=$!
    local i=0
    local spin='|/-\\'
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        printf "\r[*] Working on %-20s %s " "$1" "${spin:$i:1}"
        sleep 0.2
    done
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

# ──────────────── Update Pacman Database ────────────────
echo "[*] Updating package database..."
sudo pacman -Sy --noconfirm >/dev/null 2>&1

# ──────────────── Install Yay (if missing) ────────────────
if ! command -v yay &>/dev/null; then
    echo -e "${YELLOW}[INFO]${RESET} yay not found. Installing yay..."
    (git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si --noconfirm) &
    spinner "yay"
    wait $!
    echo -e "\r\033[K${GREEN}[DONE]${RESET} yay installed\n"
fi

# ──────────────── Handle Pacman Packages ────────────────
handle_package() {
    local pkg="$1"
    if pacman -Qi "$pkg" &>/dev/null; then
        if pacman -Qu "$pkg" | grep -q "^$pkg "; then
            (sudo pacman -S --noconfirm "$pkg" >/dev/null 2>&1) &
            spinner "$pkg"
            wait $!
            echo -e "\r\033[K${BLUE}[UPDATED]${RESET} $pkg upgraded"
        else
            echo -e "${YELLOW}[SKIP]${RESET} $pkg is already up-to-date"
        fi
    else
        (sudo pacman -S --noconfirm "$pkg" >/dev/null 2>&1) &
        spinner "$pkg"
        wait $!
        if [ $? -eq 0 ]; then
            echo -e "\r\033[K${GREEN}[DONE]${RESET} Installed $pkg"
        else
            echo -e "\r\033[K${RED}[FAIL]${RESET} Failed to install $pkg"
        fi
    fi
}

# ──────────────── Handle AUR Packages ────────────────
handle_aur_package() {
    local pkg="$1"
    if yay -Qi "$pkg" &>/dev/null; then
        echo -e "${YELLOW}[SKIP]${RESET} $pkg (AUR) already installed"
    else
        (yay -S --noconfirm "$pkg" >/dev/null 2>&1) &
        spinner "$pkg (AUR)"
        wait $!
        if [ $? -eq 0 ]; then
            echo -e "\r\033[K${GREEN}[AUR DONE]${RESET} Installed $pkg"
        else
            echo -e "\r\033[K${RED}[AUR FAIL]${RESET} Failed to install $pkg"
        fi
    fi
}

# ──────────────── Pacman Package List ────────────────
packages=(
    git nwg-look curl nvim zsh firefox kitty fastfetch btop vlc
    wl-clipboard xdg-desktop-portal-hyprland xdg-desktop-portal
    slurp grim android-tools imagemagick bc code cava waybar
    rofi wget swaync pamixer pavucontrol telegram-desktop bat dunst nwg-look
    nwg-displays libnotify udiskie udisks2 polkit-gnome gnome-disk-utility
    gvfs-mtp gvfs-gphoto2 gvfs-afc jmtpfs mtpfs libmtp repo os-prober cpio 7zip
    python-pipx ccache erofs-utils
)

# ──────────────── AUR Package List ────────────────
aur_packages=(
    atuin fzf swww starship nitch zip unzip
    zsh-history-substring-search zsh-completions
    zsh-autosuggestions zsh-syntax-highlighting
    wlogout ttf-firacode-nerd ttf-jetbrains-mono-nerd
    catppuccin-gtk-theme-mocha catppuccin-gtk-theme-frappe
)

# ──────────────── Install All Pacman Packages ────────────────
for pkg in "${packages[@]}"; do
    handle_package "$pkg"
done

# ──────────────── Install All AUR Packages ────────────────
for aur_pkg in "${aur_packages[@]}"; do
    handle_aur_package "$aur_pkg"
done

# ──────────────── Completion Notice ────────────────
echo -e "\n${GREEN}[DONE]${RESET} ${TEXT}All packages processed successfully!${RESET}\n"

# ──────────────── Run Config Script ────────────────
if [[ -f ./Source/Scripts/install_config.sh ]]; then
    bash ./Source/Scripts/install_config.sh
else
    echo -e "${RED}[WARN]${RESET} install_config.sh not found!"
fi
