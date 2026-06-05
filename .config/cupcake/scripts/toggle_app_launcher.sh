#!/usr/bin/env bash

if pgrep -f "\[q\]uickshell.*AppLauncher.qml" > /dev/null; then
    pkill -f "\[q\]uickshell.*AppLauncher.qml"
else
    quickshell --daemonize -p ~/.config/quickshell/AppLauncher.qml
fi
