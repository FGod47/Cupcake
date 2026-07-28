#!/bin/bash
if pgrep -f "[q]uickshell.*shell.qml" > /dev/null; then
    quickshell ipc call bar toggle 2>/dev/null
else
    quickshell -p ~/.config/quickshell/shell.qml &
fi
