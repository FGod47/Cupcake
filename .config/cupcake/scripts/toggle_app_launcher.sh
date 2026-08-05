#!/usr/bin/env bash

STYLE=$(cat ~/.config/cupcake/.applauncher_style 2>/dev/null || echo "Hover")
LIQUIDIFY=$(cat ~/.config/cupcake/.liquidify 2>/dev/null || echo "false")
export LIQUIDIFY
export CUPCAKE_IS_DARK=$(cat ~/.config/cupcake/.color_mode 2>/dev/null || echo "dark")
export CUPCAKE_COL_SURFACE_CONTAINER=$(grep '"surfaceContainer"' ~/.cache/quickshell_colors.json | head -n 1 | cut -d '"' -f 4)
export CUPCAKE_COL_SURFACE_CONTAINER_HIGH=$(grep '"surfaceContainerHigh"' ~/.cache/quickshell_colors.json | head -n 1 | cut -d '"' -f 4)
export CUPCAKE_COL_ON_SURFACE=$(grep '"onSurface"' ~/.cache/quickshell_colors.json | head -n 1 | cut -d '"' -f 4)
export CUPCAKE_COL_ON_SURFACE_VARIANT=$(grep '"onSurfaceVariant"' ~/.cache/quickshell_colors.json | head -n 1 | cut -d '"' -f 4)

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
