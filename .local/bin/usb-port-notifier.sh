#!/bin/bash
# Monitor udev for tty USB devices (COM ports, Qualcomm, etc.) and play a sound

udevadm monitor --subsystem-match=tty | while read -r line; do
    if echo "$line" | grep -qE "ttyUSB|ttyACM"; then
        if echo "$line" | grep -q "add"; then
            canberra-gtk-play -i device-added &
            notify-send "Device Connected" "COM Port / Device Connected" -i usb-pendrive
        elif echo "$line" | grep -q "remove"; then
            canberra-gtk-play -i device-removed &
            notify-send "Device Disconnected" "COM Port / Device Disconnected" -i usb-pendrive
        fi
    fi
done
