#!/bin/bash
if pgrep -x quickshell >/dev/null; then
    killall quickshell 2>/dev/null
else
    QSG_RENDER_LOOP=basic quickshell -p ~/.config/quickshell >/dev/null 2>&1 &
fi
