#!/bin/bash

# ──────────────── Load Colors ────────────────
source "$HOME/Cupcake/Source/Scripts/colors.sh"

# ──────────────── Color & Config Setup ────────────────
COLORS=(15)
CONFIGS=(
  cupcake cava dunst fastfetch hypr kitty nvim rofi swaync waybar wlogout
)
SOURCE_DIR="$HOME/Cupcake/.config"
BACKUP_DIR="$HOME/.config_backup"

# ──────────────── Banner Function ────────────────
print_banner() {
  local -n BANNER=$1
  echo
  for line in "${BANNER[@]}"; do
    local COLOR="\033[38;5;${COLORS[RANDOM % ${#COLORS[@]}]}m"
    echo -e "${COLOR}${line}${RESET}"
  done
  echo
}

# ──────────────── Backup Banner ────────────────
CONFIG_BACKUP_BANNER=(
"█▄▄ ▄▀█ █▀▀ █▄▀ █░█ █▀█   █▀▀ █░█ █▀█ █▀█ █▀▀ █▄░█ ▀█▀   █▀▀ █▀█ █▄░█ █▀▀ █ █▀▀"
"█▄█ █▀█ █▄▄ █░█ █▄█ █▀▀   █▄▄ █▄█ █▀▄ █▀▄ ██▄ █░▀█ ░█░   █▄▄ █▄█ █░▀█ █▀░ █ █▄█"
)

# ──────────────── Install Banner ────────────────
CONFIG_INSTALLING_BANNER=(
"█ █▄░█ █▀ ▀█▀ ▄▀█ █░░ █░░ █ █▄░█ █▀▀   █▄░█ █▀▀ █░█░█   █▀▀ █▀█ █▄░█ █▀▀ █ █▀▀"
"█ █░▀█ ▄█ ░█░ █▀█ █▄▄ █▄▄ █ █░▀█ █▄█   █░▀█ ██▄ ▀▄▀▄▀   █▄▄ █▄█ █░▀█ █▀░ █ █▄█"
""
)

# ──────────────── Backup Configs ────────────────
print_banner CONFIG_BACKUP_BANNER
echo -e "${YELLOW}[INFO]${RESET} Backing up existing config files to: ${BACKUP_DIR}"
mkdir -p "$BACKUP_DIR"

for dir in "${CONFIGS[@]}"; do
  if [ -d "$HOME/.config/$dir" ]; then
    echo -e "${GREEN}[BACKUP]${RESET} $dir → $BACKUP_DIR"
    cp -r "$HOME/.config/$dir" "$BACKUP_DIR/$dir"
  else
    echo -e "${YELLOW}[SKIP]${RESET} $dir not found in ~/.config"
  fi
done

echo -e "\n${GREEN}[DONE]${RESET} Config backup completed.\n"

# ──────────────── Install Configs ────────────────
print_banner CONFIG_INSTALLING_BANNER
echo -e "${YELLOW}[INFO]${RESET} Installing configs from: ${SOURCE_DIR}"

for dir in "${CONFIGS[@]}"; do
  SRC_DIR="$SOURCE_DIR/$dir"
  DEST_DIR="$HOME/.config/$dir"

  if [ -d "$SRC_DIR" ]; then
    echo -e "${GREEN}[INSTALL]${RESET} $dir → ~/.config"
    mkdir -p "$DEST_DIR"
    cp -r "$SRC_DIR/"* "$DEST_DIR/"
  else
    echo -e "${YELLOW}[SKIP]${RESET} $dir not found in source"
  fi

  # ──────────────── wlogout icons ────────────────
  if [ "$dir" = "wlogout" ]; then
    ICON_SRC="$SRC_DIR/icons"
    ICON_DEST="/usr/share/wlogout/icons"
    if [ -d "$ICON_SRC" ]; then
      echo -e "${GREEN}[INSTALL]${RESET} wlogout icons → /usr/share/wlogout/icons"
      sudo mkdir -p "$ICON_DEST"
      sudo cp -r "$ICON_SRC/"* "$ICON_DEST/"
    else
      echo -e "${YELLOW}[SKIP]${RESET} icons folder not found in wlogout"
    fi
  fi
done

# ──────────────── Install starship.toml ────────────────
STARSHIP_SRC="$SOURCE_DIR/starship/starship.toml"
STARSHIP_DEST="$HOME/.config/starship.toml"

if [ -f "$STARSHIP_SRC" ]; then
  echo -e "${GREEN}[INSTALL]${RESET} starship.toml → ~/.config"
  cp "$STARSHIP_SRC" "$STARSHIP_DEST"
else
  echo -e "${YELLOW}[SKIP]${RESET} starship.toml not found"
fi

# ──────────────── Set Executable Permissions ────────────────
SCRIPTS_DIR="$HOME/.config/cupcake/scripts"
if [ -d "$SCRIPTS_DIR" ]; then
  find "$SCRIPTS_DIR" -type f -name "*.sh" -exec chmod +x {} \;
  echo -e "${GREEN}[DONE]${RESET} Made all .sh files in cupcake/scripts executable.\n"
else
  echo -e "${YELLOW}[SKIP]${RESET} cupcake/scripts folder not found.\n"
fi

# ──────────────── Run Zsh Setup ────────────────
ZSH_SETUP="$HOME/Cupcake/Source/Scripts/setup_zsh.sh"
if [ -f "$ZSH_SETUP" ]; then
  bash "$ZSH_SETUP"
else
  echo -e "${RED}[WARN]${RESET} setup_zsh.sh not found at $ZSH_SETUP"
fi
