#!/bin/bash

# Arguments: dimScreen offScreen suspendBat suspendAc
DIM_MIN=$1
OFF_MIN=$2
SUSPEND_BAT_MIN=$3
SUSPEND_AC_MIN=$4

DIM_SEC=$(( DIM_MIN * 60 ))
OFF_SEC=$(( OFF_MIN * 60 ))
SUSPEND_BAT_SEC=$(( SUSPEND_BAT_MIN * 60 ))
SUSPEND_AC_SEC=$(( SUSPEND_AC_MIN * 60 ))

mkdir -p ~/.config/hypr

cat > ~/.config/hypr/hypridle.conf <<EOF
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}

listener {
    timeout = $DIM_SEC
    on-timeout = brightnessctl -s set 10%
    on-resume = brightnessctl -r
}

listener {
    timeout = $OFF_SEC
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}

listener {
    timeout = $SUSPEND_BAT_SEC
    on-timeout = if [ "\$(cat /sys/class/power_supply/BAT*/status | head -n 1)" = "Discharging" ]; then systemctl suspend; fi
}

listener {
    timeout = $SUSPEND_AC_SEC
    on-timeout = if [ "\$(cat /sys/class/power_supply/BAT*/status | head -n 1)" != "Discharging" ]; then systemctl suspend; fi
}
EOF

# Restart hypridle to apply changes
killall hypridle
hypridle -c ~/.config/hypr/hypridle.conf &
