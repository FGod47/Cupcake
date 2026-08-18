#!/usr/bin/env bash
# Update Lockscreen and SDDM Configuration Script

CONF_DIR="$HOME/.config/cupcake"
SDDM_DIR="$HOME/.local/share/qylock-themes/cupcake-sddm"
SYS_SDDM_DIR="/usr/share/sddm/themes/cupcake-sddm"
REPO_SDDM_DIR="$HOME/Cupcake/.local/share/qylock-themes/cupcake-sddm"

# Read values with fallbacks
CLOCK_BLUR=$(cat "$CONF_DIR/.lock_clock_blur" 2>/dev/null || echo "48")
BG_BLUR=$(cat "$CONF_DIR/.lock_bg_blur" 2>/dev/null || echo "42")
GLASS_SHEEN=$(cat "$CONF_DIR/.lock_glass_sheen" 2>/dev/null || echo "48")
CLOCK_FONT=$(cat "$CONF_DIR/.lock_clock_font" 2>/dev/null || echo "OpenSans.ttf")
CLOCK_SIZE=$(cat "$CONF_DIR/.lock_clock_size" 2>/dev/null || echo "124")
SHOW_DATE=$(cat "$CONF_DIR/.lock_show_date" 2>/dev/null || echo "true")
SHOW_SESSION=$(cat "$CONF_DIR/.lock_show_session" 2>/dev/null || echo "true")
SHOW_POWER=$(cat "$CONF_DIR/.lock_show_power" 2>/dev/null || echo "true")
SHOW_AVATAR=$(cat "$CONF_DIR/.lock_show_avatar" 2>/dev/null || echo "true")
USE_24H=$(cat "$CONF_DIR/.clock_24h" 2>/dev/null || echo "false")

cat <<EOF > "$SDDM_DIR/theme.conf"
[General]
# SDDM & Lockscreen General Config
background=background.png
blurRadius=$BG_BLUR
clockBlurRadius=$CLOCK_BLUR
glassSheen=$GLASS_SHEEN
clockFont=$CLOCK_FONT
clockFontSize=$CLOCK_SIZE
showDate=$SHOW_DATE
showSession=$SHOW_SESSION
showPower=$SHOW_POWER
showAvatar=$SHOW_AVATAR
timeFormat24h=$USE_24H
basicTextColor=#ffffff
passwordMask=true
EOF

# Sync to repo and system SDDM
mkdir -p "$REPO_SDDM_DIR"
cp -f "$SDDM_DIR/theme.conf" "$REPO_SDDM_DIR/theme.conf" 2>/dev/null || true
pkexec cp -f "$SDDM_DIR/theme.conf" "$SYS_SDDM_DIR/theme.conf" 2>/dev/null || sudo -n cp -f "$SDDM_DIR/theme.conf" "$SYS_SDDM_DIR/theme.conf" 2>/dev/null || true
