#!/bin/bash

output="$HOME/Videos/recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"

notify-send "  󰑓  Fullscreen Recording Started"

# Record the whole output (auto-detects the main one)
wf-recorder -f "$output"

notify-send "    Recording Saved" "$output"
