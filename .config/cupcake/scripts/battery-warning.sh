#!/bin/bash

# A simple battery warning script
# Sends a notification when battery drops below 20%, 10%, and 5%

WARNING_20=false
WARNING_10=false
WARNING_5=false

while true; do
    # Get battery info (usually BAT0 or BAT1)
    BATTERY=$(ls /sys/class/power_supply | grep -i bat | head -n 1)

    if [ -z "$BATTERY" ]; then
        # No battery found, just sleep
        sleep 300
        continue
    fi

    CAPACITY=$(cat /sys/class/power_supply/$BATTERY/capacity)
    STATUS=$(cat /sys/class/power_supply/$BATTERY/status)

    if [ "$STATUS" = "Discharging" ]; then
        if [ "$CAPACITY" -le 5 ] && [ "$WARNING_5" = false ]; then
            notify-send "Battery Critical" "Battery is at $CAPACITY%. Please plug in immediately!" -u critical -i battery-empty
            WARNING_5=true
            WARNING_10=true
            WARNING_20=true
        elif [ "$CAPACITY" -le 10 ] && [ "$WARNING_10" = false ]; then
            notify-send "Battery Very Low" "Battery is at $CAPACITY%. Please plug in soon." -u critical -i battery-caution
            WARNING_10=true
            WARNING_20=true
        elif [ "$CAPACITY" -le 20 ] && [ "$WARNING_20" = false ]; then
            notify-send "Battery Low" "Battery is at $CAPACITY%." -u normal -i battery-low
            WARNING_20=true
        fi
    else
        # If charging or full, reset the warnings
        if [ "$STATUS" = "Charging" ] || [ "$STATUS" = "Full" ]; then
            WARNING_20=false
            WARNING_10=false
            WARNING_5=false
        fi
    fi

    sleep 60
done
