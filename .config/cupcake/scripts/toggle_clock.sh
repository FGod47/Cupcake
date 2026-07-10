#!/bin/bash

STATE_FILE="/tmp/cupcake_clock_state"

if [[ -f "$STATE_FILE" && "$(cat "$STATE_FILE")" == "expanded" ]]; then
  echo "compact" > "$STATE_FILE"
else
  echo "expanded" > "$STATE_FILE"
fi
