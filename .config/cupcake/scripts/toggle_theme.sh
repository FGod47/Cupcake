#!/bin/bash

# File to remember current theme
STATE="$HOME/.config/cupcake/.current_theme"
DARK="cupcake-dark"
LIGHT="cupcake-light"

# Default to dark if no file exists
[[ -f "$STATE" ]] || echo "$DARK" > "$STATE"

CURRENT=$(cat "$STATE")

if [[ "$CURRENT" == "$DARK" ]]; then
    NEW="$LIGHT"
else
    NEW="$DARK"
fi

# Save new state
echo "$NEW" > "$STATE"

# Paths
THEME_DIR="$HOME/.config/cupcake/themes/$NEW"
WAYBAR_CONFIG="$HOME/.config/waybar/style.css"
ROFI_CONFIG="$HOME/.config/rofi/theme.rasi"
WALLPAPER_DEST="$HOME/.config/hypr/wall.jpg"

# Apply new theme
cp "$THEME_DIR/waybar/style.css" "$WAYBAR_CONFIG"
cp "$THEME_DIR/rofi/theme.rasi" "$ROFI_CONFIG"

# Select the first wallpaper dynamically
DEFAULT_WALL=$(find "$THEME_DIR/walls" -type f | head -n 1)
[[ -n "$DEFAULT_WALL" ]] && cp "$DEFAULT_WALL" "$WALLPAPER_DEST"

# Reload wallpaper and bar
awww img "$WALLPAPER_DEST" --transition-type grow --transition-fps 60 --transition-duration 1

# Restart the shell
pkill -9 -x quickshell
QT_NO_SESSION_MANAGER=1 quickshell -p ~/.config/quickshell/shell.qml &

notify-send "Switched to $NEW"
