#!/bin/bash
sleep 0.5 && hyprctl monitors -j | jq -r '.[0] | "hyprctl dispatch movecursor \((.width / 2 | floor)) \((.height / 2 | floor))"' | sh
quickshell -p ~/.config/quickshell/CursorFocus.qml &
