#!/bin/bash
if pgrep -x quickshell >/dev/null || pgrep -x qs >/dev/null; then
    killall -9 qs quickshell 2>/dev/null
    pkill -9 -f "quickshell" 2>/dev/null
    pkill -9 -f "qs" 2>/dev/null
else
    killall -9 qs quickshell 2>/dev/null
    pkill -9 -f "quickshell" 2>/dev/null
    pkill -9 -f "qs" 2>/dev/null
    sleep 0.5
    DISPLAY=:0 WAYLAND_DISPLAY=wayland-1 /usr/bin/qs -d >/dev/null 2>&1 &
fi

