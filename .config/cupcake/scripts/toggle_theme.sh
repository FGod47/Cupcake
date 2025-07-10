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
ROFI_CONFIG="$HOME/.config/rofi/config.rasi"
WALLPAPER_DEST="$HOME/.config/hypr/wall.jpg"

# Apply new theme
cp "$THEME_DIR/waybar.css" "$WAYBAR_CONFIG"
cp "$THEME_DIR/rofi.rasi" "$ROFI_CONFIG"
cp "$THEME_DIR/wallpaper.jpg" "$WALLPAPER_DEST"

# Reload wallpaper and waybar
swww img "$WALLPAPER_DEST" --transition-type grow --transition-fps 60 --transition-duration 1
pkill waybar && waybar &

notify-send "Switched to $NEW"
