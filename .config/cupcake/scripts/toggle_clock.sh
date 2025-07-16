#!/bin/bash

STATE_FILE="/tmp/waybar_clock_state"

if [[ -f "$STATE_FILE" && "$(cat "$STATE_FILE")" == "expanded" ]]; then
  echo "compact" > "$STATE_FILE"
else
  echo "expanded" > "$STATE_FILE"
fi

# Tell Waybar to update the module
pkill -SIGRTMIN+10 waybar
