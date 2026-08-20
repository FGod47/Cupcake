#!/bin/bash
if pgrep -f "quickshell.*shell.qml" >/dev/null 2>&1; then
    quickshell ipc call bar toggle 2>/dev/null || qs ipc call bar toggle 2>/dev/null
else
    quickshell -d -p "$HOME/.config/quickshell/shell.qml" >/dev/null 2>&1 &
fi

