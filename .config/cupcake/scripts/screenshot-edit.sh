#!/bin/bash

mkdir -p "$HOME/Pictures/Screenshot"
filename="$HOME/Pictures/Screenshot/$(date +%m-%d-%H-%M-%S).png"

grim "$filename" && \
  notify-send "📸 Screenshot Saved" "$filename" -i "$filename"
