#!/usr/bin/env sh

WINDOWRULES="$HOME/.config/hypr/windowrules.conf"
SWAYNC_CONFIG="$HOME/.config/swaync/style.css"
HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1 {print $2}')

if [ "$HYPRGAMEMODE" = "1" ]; then
    # Disable opacity rules by commenting them
    sed -i 's/^\(windowrule = opacity.*\)/# \1/' "$WINDOWRULES"

    # Replace swaync CSS with minimal version
    if [ -d "$HOME/.config/swaync" ]; then
        cp "$HOME/.config/swaync/styles/minimal.css" "$SWAYNC_CONFIG"
    fi

else
    # Re-enable opacity rules by uncommenting
    sed -i 's/^# \(windowrule = opacity.*\)/\1/' "$WINDOWRULES"

     # Restore swaync full style
    if [ -d "$HOME/.config/swaync" ]; then
        cp "$HOME/.config/swaync/styles/default.css" "$SWAYNC_CONFIG"
    fi
fi

# Handle Hyprland settings
if [ "$HYPRGAMEMODE" = "1" ]; then
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:drop_shadow 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0"
else
    hyprctl reload
fi
