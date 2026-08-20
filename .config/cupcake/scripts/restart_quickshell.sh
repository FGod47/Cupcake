#!/bin/bash
# Kill any running quickshell instance cleanly
killall -9 quickshell 2>/dev/null || true

# Wait briefly for process and socket cleanup
sleep 0.3

# Launch quickshell daemon
quickshell -d -p "$HOME/.config/quickshell/shell.qml"
