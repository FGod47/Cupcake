local HOME = os.getenv("HOME") or "/home/zero"

-- Runs on config reload
hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'")
hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 24")

-- Set environment variable
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("QSG_RENDER_LOOP", "basic")

-- Runs once on startup
hl.on("hyprland.start", function()
    hl.exec_cmd(HOME .. "/.config/cupcake/scripts/center_cursor.sh")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("quickshell -p " .. HOME .. "/.config/quickshell/shell.qml")
    hl.exec_cmd("udiskie --automount --smart-tray")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd(HOME .. "/.config/cupcake/scripts/gvfs.sh")
    hl.exec_cmd(HOME .. "/.config/cupcake/scripts/battery-warning.sh")
    hl.exec_cmd("hyprsunset")
    hl.exec_cmd("hypridle -c " .. HOME .. "/.config/hypr/hypridle.conf")
end)
