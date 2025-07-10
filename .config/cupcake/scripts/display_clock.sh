#!/bin/bash

STATE_FILE="/tmp/waybar_clock_state"
STATE="compact"

# Correct fallback if file exists
if [[ -f "$STATE_FILE" ]]; then
  STATE=$(<"$STATE_FILE")
fi

if [[ "$STATE" == "expanded" ]]; then
  echo "{\"text\": \"$(date '+%A ⦵ %d %B %Y')\", \"tooltip\": false}"
else
  echo "{\"text\": \"󰥔 $(date '+%I:%M %p')\", \"tooltip\": \"$(date '+%A ⦵ %d %B %Y')\"}"
fi
