#!/usr/bin/env sh

STYLE="$HOME/.config/waybar/style.css"
WINDOWRULES="$HOME/.config/hypr/windowrules.conf"
SWAYNC_CONFIG="$HOME/.config/swaync/style.css"
HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1 {print $2}')

# Handle Waybar animations
if [ "$HYPRGAMEMODE" = "1" ]; then
    # Disable Waybar animations
    sed -i 's/^\(.*animation:.*\)$/\/\* \1 \*\//' "$STYLE"
    sed -i 's/^\(.*transition:.*\)$/\/\* \1 \*\//' "$STYLE"

    # Disable opacity rules by commenting them
    sed -i 's/^\(windowrule = opacity.*\)/# \1/' "$WINDOWRULES"

    # Replace swaync CSS with minimal version
    cp "$HOME/.config/swaync/styles/minimal.css" "$SWAYNC_CONFIG"

else
    # Re-enable Waybar animations
    sed -i 's/\/\* \(.*animation:.*\) \*\//\1/' "$STYLE"
    sed -i 's/\/\* \(.*transition:.*\) \*\//\1/' "$STYLE"

    # Re-enable opacity rules by uncommenting
    sed -i 's/^# \(windowrule = opacity.*\)/\1/' "$WINDOWRULES"

     # Restore swaync full style
    cp "$HOME/.config/swaync/styles/default.css" "$SWAYNC_CONFIG"
fi

# Restart Waybar
killall waybar
waybar >/dev/null 2>&1 &

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
