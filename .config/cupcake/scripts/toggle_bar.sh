#!/bin/bash
killall -9 quickshell 2>/dev/null
sleep 0.5
QSG_RENDER_LOOP=basic quickshell -p ~/.config/quickshell/shell.qml >/dev/null 2>&1 &
