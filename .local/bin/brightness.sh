#!/usr/bin/env bash

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
