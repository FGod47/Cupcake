#!/bin/bash
# Args: $1 = Action ("Sleep" or "Display Off")

ACTION="$1"
mkdir -p ~/.config/hypr/custom

if [ "$ACTION" = "Display Off" ]; then
    # Write the display-off binding to custom/keybinding.lua
    cat > ~/.config/hypr/custom/keybinding.lua <<EOF
-- Auto-generated lid switch bindings
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("hyprctl keyword monitor 'eDP-1, disable'"), {locked = true})
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("hyprctl keyword monitor 'eDP-1, preferred, auto, 1'"), {locked = true})
EOF
else
    # Write the suspend binding
    cat > ~/.config/hypr/custom/keybinding.lua <<EOF
-- Auto-generated lid switch bindings
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("systemctl suspend"), {locked = true})
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("hyprctl keyword monitor 'eDP-1, preferred, auto, 1'"), {locked = true})
EOF
fi

# Reload hyprland
hyprctl reload
