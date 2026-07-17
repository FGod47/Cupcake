#!/usr/bin/env bash

# Check if a laptop backlight device exists
if ls /sys/class/backlight/* 1> /dev/null 2>&1; then
    # Laptop screen: use brightnessctl
    if [[ "$1" == "up" ]]; then
        brightnessctl set 5%+
    elif [[ "$1" == "down" ]]; then
        brightnessctl set 5%-
    fi

    # Fetch current brightness percentage
    VAL=$(brightnessctl -m | head -n 1 | awk -F, '{print $4}' | tr -d '%')
    quickshell ipc call osd brightness "$VAL"
else
    # External monitor: use ddcutil
    # ddcutil is slow and blocks the I2C bus. We use a lock file to prevent overlapping calls.
    LOCK=/tmp/ddcutil_brightness.lock
    exec 200>$LOCK
    flock -n 200 || exit 0

    if [[ "$1" == "up" ]]; then
        ddcutil setvcp 10 + 5 --noverify
    elif [[ "$1" == "down" ]]; then
        ddcutil setvcp 10 - 5 --noverify
    fi

    # Fetch current brightness
    VAL=$(ddcutil getvcp 10 --terse | awk '{print $4}')
    quickshell ipc call osd brightness "$VAL"
fi
