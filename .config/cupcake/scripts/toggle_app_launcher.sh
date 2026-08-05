#!/usr/bin/env bash

STYLE=$(cat ~/.config/cupcake/.applauncher_style 2>/dev/null || echo "Hover")
LIQUIDIFY=$(cat ~/.config/cupcake/.liquidify 2>/dev/null || echo "false")
export LIQUIDIFY
export CUPCAKE_IS_DARK=$(cat ~/.config/cupcake/.color_mode 2>/dev/null || echo "dark")
export CUPCAKE_COL_ON_SURFACE=$(python3 -c "import json, os; print(json.load(open(os.path.expanduser('~/.cache/quickshell_colors.json')))['onSurface'])" 2>/dev/null || echo "")
export CUPCAKE_COL_ON_SURFACE_VARIANT=$(python3 -c "import json, os; print(json.load(open(os.path.expanduser('~/.cache/quickshell_colors.json')))['onSurfaceVariant'])" 2>/dev/null || echo "")

if [ "$STYLE" = "Hug" ]; then
    TARGET="AppLauncherHug.qml"
elif [ "$STYLE" = "HoverSleek" ]; then
    TARGET="AppLauncherHoverSleek.qml"
else
    TARGET="AppLauncherHover.qml"
fi

if pgrep -f "quickshell.*AppLauncher.*\.qml" > /dev/null; then
    pkill -f "quickshell.*AppLauncher.*\.qml"
else
    quickshell --daemonize -p ~/.config/quickshell/$TARGET
fi
