#!/bin/bash
# Run all GVFS-related daemons for mounting MTP, USB, network, etc.
dbus-update-activation-environment --systemd DISPLAY XAUTHORITY WAYLAND_DISPLAY
/usr/lib/gvfs/gvfsd &
/usr/lib/gvfs/gvfsd-fuse /run/user/$(id -u)/gvfs -o big_writes &
/usr/lib/gvfs/gvfs-udisks2-volume-monitor &
/usr/lib/gvfs/gvfs-mtp-volume-monitor &
/usr/lib/gvfs/gvfs-gphoto2-volume-monitor &
