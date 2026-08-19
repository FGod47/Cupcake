#!/bin/bash
if pgrep -f "quickshell.*shell.qml" >/dev/null 2>&1; then
    hyprctl dispatch global quickshell:bar_toggle 2>/dev/null || qs ipc call bar toggle 2>/dev/null
else
    nohup quickshell -p "$HOME/.config/quickshell/shell.qml" >/dev/null 2>&1 &
fi

