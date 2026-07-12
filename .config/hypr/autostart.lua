-- Runs on config reload
hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'")
hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 24")

-- Set environment variable
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")

-- Runs once on startup
hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/cupcake/scripts/center_cursor.sh")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("QSG_RENDER_LOOP=basic quickshell -p ~/.config/quickshell/shell.qml")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("udiskie --no-automount --smart-tray")
    hl.exec_cmd("python $cupcake --action set-wallpaper")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("~/.config/cupcake/scripts/gvfs.sh")
    hl.exec_cmd("~/.config/cupcake/scripts/battery-warning.sh")
end)
