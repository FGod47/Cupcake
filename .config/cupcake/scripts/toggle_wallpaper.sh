#!/usr/bin/env bash

if pgrep -f 'quickshell.*WallpaperSwitcher\.qml' | grep -v $$ > /dev/null; then
    quickshell ipc -p ~/.config/quickshell/WallpaperSwitcher.qml call wallpaperswitcher toggle
else
    quickshell --daemonize -p ~/.config/quickshell/WallpaperSwitcher.qml
fi
