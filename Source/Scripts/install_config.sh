#!/bin/bash

# ──────────────── Load Colors ────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"

# ──────────────── Color & Config Setup ────────────────
COLORS=(15)
CONFIGS=(
  cupcake cava fastfetch hypr kitty nvim quickshell qylock matugen
)
SOURCE_DIR="$(cd "$SCRIPT_DIR/../../.config" && pwd)"
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

  # ──────────────── (Deprecated components removed) ────────────────
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

# ──────────────── Install local bin scripts ────────────────
BIN_SRC_DIR="$(cd "$SCRIPT_DIR/../../.local/bin" && pwd 2>/dev/null)"
if [ -d "$BIN_SRC_DIR" ]; then
  echo -e "${GREEN}[INSTALL]${RESET} local bin scripts → ~/.local/bin"
  mkdir -p "$HOME/.local/bin"
  cp -r "$BIN_SRC_DIR/"* "$HOME/.local/bin/"
  chmod +x "$HOME/.local/bin/"*
else
  echo -e "${YELLOW}[SKIP]${RESET} local bin scripts not found"
fi


# ──────────────── Install Desktop Entry ────────────────
DESKTOP_ENTRY_SRC="$SCRIPT_DIR/../cupcake-keybinds.desktop"
DESKTOP_ENTRY_DEST="$HOME/.local/share/applications/cupcake-keybinds.desktop"

if [ -f "$DESKTOP_ENTRY_SRC" ]; then
  echo -e "${GREEN}[INSTALL]${RESET} cupcake-keybinds.desktop → ~/.local/share/applications"
  mkdir -p "$HOME/.local/share/applications"
  cp "$DESKTOP_ENTRY_SRC" "$DESKTOP_ENTRY_DEST"
  update-desktop-database "$HOME/.local/share/applications" &>/dev/null || true
else
  echo -e "${YELLOW}[SKIP]${RESET} cupcake-keybinds.desktop not found"
fi

# ──────────────── Install Quickshell Lockscreen & SDDM Theme ────────────────
QYLOCK_SRC="$SCRIPT_DIR/../../.local/share/qylock-themes"
QS_LOCK_SRC="$SCRIPT_DIR/../../.local/share/quickshell-lockscreen"

if [ -d "$QYLOCK_SRC" ]; then
  echo -e "${GREEN}[INSTALL]${RESET} qylock themes → ~/.local/share/qylock-themes"
  mkdir -p "$HOME/.local/share/qylock-themes"
  cp -r "$QYLOCK_SRC/"* "$HOME/.local/share/qylock-themes/"
fi

if [ -d "$QS_LOCK_SRC" ]; then
  echo -e "${GREEN}[INSTALL]${RESET} quickshell-lockscreen → ~/.local/share/quickshell-lockscreen"
  mkdir -p "$HOME/.local/share/quickshell-lockscreen"
  cp -r "$QS_LOCK_SRC/"* "$HOME/.local/share/quickshell-lockscreen/"
  chmod +x "$HOME/.local/share/quickshell-lockscreen/lock.sh"
fi

if command -v sddm &> /dev/null; then
  echo -e "${GREEN}[INSTALL]${RESET} SDDM Theme (cupcake-sddm) → /usr/share/sddm/themes/cupcake-sddm"
  sudo mkdir -p /usr/share/sddm/themes/cupcake-sddm
  sudo cp -r "$HOME/.local/share/qylock-themes/cupcake-sddm/"* /usr/share/sddm/themes/cupcake-sddm/
  sudo mkdir -p /etc/sddm.conf.d
  echo -e "[Theme]\nCurrent=cupcake-sddm\nCursorTheme=Bibata-Modern-Ice" | sudo tee /etc/sddm.conf.d/theme.conf > /dev/null
fi

# ──────────────── Install Cursor Configuration ────────────────
echo -e "${GREEN}[INSTALL]${RESET} Configuring Bibata-Modern-Ice cursor globally"
mkdir -p "$HOME/.icons/default"
echo -e "[Icon Theme]\nName=Default\nComment=Default Cursor Theme\nInherits=Bibata-Modern-Ice" > "$HOME/.icons/default/index.theme"

if [ -d "$HOME/.icons/Bibata-Modern-Ice" ]; then
  mkdir -p "$HOME/.local/share/icons"
  cp -r "$HOME/.icons/Bibata-Modern-Ice" "$HOME/.local/share/icons/"
  cp -r "$HOME/.icons/default" "$HOME/.local/share/icons/"
  sudo cp -r "$HOME/.icons/Bibata-Modern-Ice" /usr/share/icons/
  sudo mkdir -p /usr/share/icons/default
  echo -e "[Icon Theme]\nInherits=Bibata-Modern-Ice" | sudo tee /usr/share/icons/default/index.theme > /dev/null
fi

mkdir -p "$HOME/.config/gtk-3.0"
cat <<EOF > "$HOME/.config/gtk-3.0/settings.ini"
[Settings]
gtk-theme-name=catppuccin-frappe-blue-standard+default
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Adwaita Sans 11
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=0
EOF

gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice' 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-frappe-blue-standard+default' 2>/dev/null || true
gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 11' 2>/dev/null || true

# ──────────────── Tabler Icons Font ────────────────
echo -e "${YELLOW}[INFO]${RESET} Installing Tabler Icons font..."
mkdir -p "$HOME/.local/share/fonts"
if [ ! -f "$HOME/.local/share/fonts/tabler-icons.ttf" ]; then
  curl -sL "https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/fonts/tabler-icons.ttf" \
    -o "$HOME/.local/share/fonts/tabler-icons.ttf" \
    && echo -e "${GREEN}[OK]${RESET} Tabler Icons font installed" \
    || echo -e "${RED}[WARN]${RESET} Failed to download Tabler Icons font"
  fc-cache -f 2>/dev/null || true
else
  echo -e "${GREEN}[SKIP]${RESET} Tabler Icons font already installed"
fi

# ──────────────── Initialize Cupcake State Files ────────────────
# These dotfiles are read by QML and shell scripts at runtime.
# Without them, quickshell throws FILE NOT FOUND warnings and
# settings pages fail to load their saved state on first boot.
echo -e "${YELLOW}[INFO]${RESET} Initializing Cupcake state files..."
CUPCAKE_STATE="$HOME/.config/cupcake"

_write_default() {
  local file="$CUPCAKE_STATE/$1"
  local value="$2"
  if [ ! -f "$file" ]; then
    echo "$value" > "$file"
    echo -e "${GREEN}[INIT]${RESET} $1 = $value"
  fi
}

_write_default ".color_mode"                    "dark"
_write_default ".color_scheme"                  "catppuccin-frappe"
_write_default ".borders"                       "true"
_write_default ".shadows"                       "false"
_write_default ".transparency"                  "true"
_write_default ".gaps_in"                       "4"
_write_default ".gaps_out"                      "8"
_write_default ".bar_monitors"                  "all"
_write_default ".dock_monitors"                 "all"
_write_default ".dock_autohide"                 "false"
_write_default ".dock_reserve_space"            "true"
_write_default ".dock_shape"                    "pill"
_write_default ".dock_show_dots"                "true"
_write_default ".dock_magnification_enabled"    "false"
_write_default ".dock_magnification_scale"      "1.5"
_write_default ".dock_launcher_position"        "left"
_write_default ".dock_pinned_apps_enabled"      "true"
_write_default ".dock_pinned_apps"              "[]"

# Write default transparency values file (key=value format expected by scripts)
if [ ! -f "$CUPCAKE_STATE/.transparency_values" ]; then
  printf 'OPACITY=0.90\nBLUR_SIZE=6\nBLUR_PASSES=3\n' > "$CUPCAKE_STATE/.transparency_values"
  echo -e "${GREEN}[INIT]${RESET} .transparency_values"
fi

echo -e "${GREEN}[DONE]${RESET} Cupcake state files initialized."

# ──────────────── PATH: Add ~/.local/bin ────────────────
# Ensure ~/.local/bin is on PATH so all Cupcake scripts are accessible.
ZSHRC="$HOME/.zshrc"
BASHRC="$HOME/.bashrc"
LOCAL_BIN_EXPORT='export PATH="$HOME/.local/bin:$PATH"'
LOCAL_BIN_COMMENT='# ─── Cupcake local bin ────────────────────────────────'

for rcfile in "$ZSHRC" "$BASHRC"; do
  if [ -f "$rcfile" ] && ! grep -q '.local/bin' "$rcfile"; then
    printf '\n%s\n%s\n' "$LOCAL_BIN_COMMENT" "$LOCAL_BIN_EXPORT" >> "$rcfile"
    echo -e "${GREEN}[DONE]${RESET} Added ~/.local/bin to PATH in $(basename $rcfile)"
  fi
done

# ──────────────── qt5ct Config ────────────────
# qt5ct is needed for proper Qt app theming. Without this config
# Qt apps fall back to an unstyled look.
QT5CT_DIR="$HOME/.config/qt5ct"
QT5CT_CONF="$QT5CT_DIR/qt5ct.conf"
if [ ! -f "$QT5CT_CONF" ]; then
  mkdir -p "$QT5CT_DIR"
  cat > "$QT5CT_CONF" << 'QTEOF'
[Appearance]
color_scheme_path=
custom_palette=false
icon_theme=Papirus-Dark
standard_dialogs=default
style=gtk2

[Fonts]
fixed=@Variant(\0\0\0@\0\0\0\x12JetBrains Mono\0\0\0\0\0\0\0\0\0\xd0\0\0\0\n\0\0\0\0\0\0\0\0\0\0\0)
general=@Variant(\0\0\0@\0\0\0\x18Adwaita Sans\0\0\0\0\0\0\0\0\0\xd6\0\0\0\n\0\0\0\0\0\0\0\0\0\0\0)

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Variant(\0\0\0\x7f\0\0\0\x12AnimateComboBox)
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Variant(\0\0\0\x7f\0\0\0\0)
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3
QTEOF
  echo -e "${GREEN}[INSTALL]${RESET} qt5ct.conf written"
fi

# ──────────────── Copy Papirus Icons Locally ────────────────
# dynamic-icons and some scripts need Papirus-Dark in ~/.local/share/icons.
# Without this, icon refresh on theme change fails silently.
PAPIRUS_SRC="/usr/share/icons/Papirus-Dark"
PAPIRUS_DEST="$HOME/.local/share/icons/Papirus-Dark"
if [ -d "$PAPIRUS_SRC" ] && [ ! -d "$PAPIRUS_DEST" ]; then
  echo -e "${YELLOW}[INFO]${RESET} Copying Papirus-Dark icons to ~/.local/share/icons..."
  mkdir -p "$HOME/.local/share/icons"
  cp -r "$PAPIRUS_SRC" "$PAPIRUS_DEST"
  echo -e "${GREEN}[DONE]${RESET} Papirus-Dark icons copied locally"
fi

echo -e "\n${GREEN}[SUCCESS]${RESET} Cupcake configuration installed successfully!\n"
echo -e "${YELLOW}[NOTE]${RESET} Please log out and log back in (or reboot) for all changes to take effect.\n"
