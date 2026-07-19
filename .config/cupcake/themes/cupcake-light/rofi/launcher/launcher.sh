#!/usr/bin/env bash

dir="$HOME/.config/rofi/launcher/"
style=$(cat ~/.config/cupcake/.applauncher_style 2>/dev/null)
if [ "$style" = "Hover" ]; then
    theme='hover'
else
    theme='hug'
fi

## Run
rofi \
    -show drun \
    -theme ${dir}/${theme}.rasi
