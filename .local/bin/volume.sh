#!/usr/bin/env bash

if [[ "$1" == "up" ]]; then
    pamixer -i 2
elif [[ "$1" == "down" ]]; then
    pamixer -d 2
elif [[ "$1" == "mute" ]]; then
    pamixer -t
fi

MUTE=$(pamixer --get-mute)
if [[ "$MUTE" == "true" ]]; then
    quickshell ipc call osd volume 0
else
    quickshell ipc call osd volume $(pamixer --get-volume)
fi
