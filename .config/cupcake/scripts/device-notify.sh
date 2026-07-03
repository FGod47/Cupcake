#!/bin/bash

# Find the active user
USER=$(loginctl list-users --no-legend | head -n 1 | awk '{print $2}')
if [ -z "$USER" ]; then
    USER=$(logname 2>/dev/null || whoami)
fi

USER_HOME=$(getent passwd "$USER" | cut -d: -f6)

export DISPLAY=:0
export XAUTHORITY="$USER_HOME/.Xauthority"
DEVICE="$1"

# Send desktop notification
sudo -u "$USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $USER)/bus" DISPLAY="$DISPLAY" XAUTHORITY="$XAUTHORITY" \
notify-send "📱 Device Connected" "$DEVICE is now connected."
