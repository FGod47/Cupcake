#!/bin/bash
if ! pgrep -f "[q]uickshell.*shell.qml" > /dev/null; then
    quickshell -p ~/.config/quickshell/shell.qml &
else
    pkill -f "[q]uickshell.*shell.qml"
fi
