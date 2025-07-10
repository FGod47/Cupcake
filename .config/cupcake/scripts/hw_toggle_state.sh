#!/bin/bash
STATE_FILE=".cache/waybar_hw_expanded"

if [[ -f "$STATE_FILE" ]]; then
  rm "$STATE_FILE"
else
  touch "$STATE_FILE"
fi