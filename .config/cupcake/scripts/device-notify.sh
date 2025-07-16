#!/bin/bash

export DISPLAY=:0
export XAUTHORITY=/home/codeblack/.Xauthority

USER="codeblack"
DEVICE="$1"

# Send desktop notification
sudo -u $USER DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY \
notify-send "📱 Device Connected" "$DEVICE is now connected."
