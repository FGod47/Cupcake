#!/bin/bash
STATE_FILE=".cache/waybar_hw_expanded"

CPU_USAGE=$(grep 'cpu ' /proc/stat | awk '{u=$2+$4; t=$2+$4+$5; printf "%.0f", (u*100)/t}')
MEM_USED=$(free -h | awk '/Mem:/ {gsub(/i/,"",$3); print $3}')
TEMP_RAW=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)
TEMP_C=$((TEMP_RAW / 1000))

if [[ -f "$STATE_FILE" ]]; then
  echo "{\"text\": \"󰍛 ${CPU_USAGE}%  󰾆 ${MEM_USED}  󰈸 ${TEMP_C}°C\", \"tooltip\": \"\", \"class\": \"expanded\"}"
else
  echo "{\"text\": \"󰍛 ${CPU_USAGE}%\", \"tooltip\": \"\"}"
fi
