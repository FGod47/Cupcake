#!/usr/bin/env bash

# Set variables
theme="default"
wall_dir="${HOME}/.config/cupcake/walls"
cacheDir="${HOME}/.cache/jp/${theme}"

# Monitor resolution to thumbnail DPI (approximation)
physical_monitor_size=24  # in inches
monitor_px_width=$(hyprctl monitors | grep "width" | awk '{print $2}' | head -n1)
dpi=$(echo "$monitor_px_width / $physical_monitor_size" | bc)
thumbnail_size=300  # static for better performance

# Rofi appearance override
rofi_override="element-icon { size: ${thumbnail_size}px; border-radius: 8px; }"
rofi_command="rofi -x11 -dmenu -theme ${HOME}/.config/rofi/selecter/wallSelect.rasi -theme-str \"${rofi_override}\""

# Ensure cache directory exists
mkdir -p "${cacheDir}"

# Generate thumbnails if missing
find "$wall_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | while read -r imagen; do
    nombre_archivo=$(basename "$imagen")
    if [ ! -f "${cacheDir}/${nombre_archivo}" ]; then
        convert -strip "$imagen" -thumbnail ${thumbnail_size}x${thumbnail_size}^ -gravity center -extent ${thumbnail_size}x${thumbnail_size} "${cacheDir}/${nombre_archivo}"
    fi
done

# Select wallpaper using rofi
wall_selection=$(find "$wall_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
    -exec basename {} \; | sort | while read -r A; do
        echo -en "$A\x00icon\x1f${cacheDir}/${A}\n"
    done | eval $rofi_command)

# Apply wallpaper using swww with transition
if [ -n "$wall_selection" ]; then
    swww img "${wall_dir}/${wall_selection}" \
        --transition-type grow \
        --transition-pos "$(hyprctl cursorpos)" \
        --transition-fps 160 \
        --transition-duration 1
fi
