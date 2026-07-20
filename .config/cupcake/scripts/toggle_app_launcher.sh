#!/usr/bin/env bash

STYLE=$(cat ~/.config/cupcake/.applauncher_style 2>/dev/null || echo "Hover")
LIQUIDIFY=$(cat ~/.config/cupcake/.liquidify 2>/dev/null || echo "false")
export LIQUIDIFY

if [ "$STYLE" = "Hug" ]; then
    TARGET="AppLauncherHug.qml"
else
    TARGET="AppLauncherHover.qml"
fi

if pgrep -f "\[q\]uickshell.*AppLauncher.*\.qml" > /dev/null; then
    pkill -f "\[q\]uickshell.*AppLauncher.*\.qml"
else
    quickshell --daemonize -p ~/.config/quickshell/$TARGET
fi
