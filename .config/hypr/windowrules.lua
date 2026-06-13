-- Opacity & Blur
hl.window_rule({
    match = { class = "^()$", title = "^()$" },
    no_blur = true
})

hl.window_rule({
    match = { class = "^(.*)$", title = "^(.*)$" },
    opacity = "0.90 0.90"
})

hl.window_rule({
    match = { class = "^(firefox)$" },
    opacity = "1.0 1.0"
})

-- Picture In Picture
hl.window_rule({
    match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
    float = true,
    keep_aspect_ratio = true,
    move = "74.5% 74%",
    size = "25% 25%",
    pin = true
})

-- Idle Inhibit rules
hl.window_rule({
    match = { class = "^(.*celluloid.*)$|^(.*mpv.*)$|^(.*vlc.*)$" },
    idle_inhibit = "fullscreen"
})

hl.window_rule({
    match = { class = "^(.*[Ss]potify.*)$" },
    idle_inhibit = "fullscreen"
})

hl.window_rule({
    match = { class = "^(yandex-music)$" },
    idle_inhibit = "fullscreen"
})

hl.window_rule({
    match = { class = "^(.*LibreWolf.*)$|^(.*floorp.*)$|^(.*brave-browser.*)$|^(.*firefox.*)$|^(.*chromium.*)$|^(.*zen.*)$|^(.*vivaldi.*)$" },
    idle_inhibit = "fullscreen"
})

-- Floating Windows
hl.window_rule({ match = { class = "^(vlc)$" }, float = true })
hl.window_rule({ match = { class = "^(blueman-manager)$" }, float = true })
hl.window_rule({ match = { class = "^(firefox)$", title = "^(Picture-in-Picture)$" }, float = true })
hl.window_rule({ match = { class = "^(firefox)$", title = "^(Library)$" }, float = true })
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, float = true })
hl.window_rule({ match = { class = "^(qt5ct)$" }, float = true })
hl.window_rule({ match = { class = "^(qt6ct)$" }, float = true })
hl.window_rule({ match = { class = "^(org.kde.ark)$" }, float = true })
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" }, float = true, size = "48% 42%" })
hl.window_rule({ match = { class = "^(yad)$" }, float = true })
hl.window_rule({ match = { class = "^(gnome-calculator)$" }, float = true, center = true, size = "19% 47%" })
hl.window_rule({ match = { class = "^(org.gnome.Loupe)$" }, float = true, center = true, size = "63% 74%" })
hl.window_rule({ match = { class = "^(org.gnome.FileRoller)$" }, float = true, center = true, size = "63% 74%" })
hl.window_rule({ match = { class = "^(com.cupcake.Keybinds)$" }, float = true, center = true, size = "63% 74%" })
hl.window_rule({ match = { class = "^(qalculate-gtk)$" }, float = true, center = true, size = "45% 55%" })

-- Modals
hl.window_rule({ match = { title = "^(Open)$" }, float = true })
hl.window_rule({ match = { title = "^(Authentication Required)$" }, float = true })
hl.window_rule({ match = { title = "^(Add Folder to Workspace)$" }, float = true })
hl.window_rule({ match = { initial_title = "^(Open File)$" }, float = true })
hl.window_rule({ match = { title = "^(Choose Files)$" }, float = true })
hl.window_rule({ match = { title = "^(Save As)$" }, float = true })
hl.window_rule({ match = { title = "^(Confirm to replace files)$" }, float = true })
hl.window_rule({ match = { title = "^(File Operation Progress)$" }, float = true })
hl.window_rule({ match = { title = "^(File Upload)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Choose wallpaper)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Library)(.*)$" }, float = true })
hl.window_rule({ match = { class = "^(.*dialog.*)$" }, float = true })
hl.window_rule({ match = { title = "^(.*dialog.*)$" }, float = true })

-- Portals
hl.window_rule({ match = { class = "^(org.freedesktop.impl.portal.desktop.hyprland)$" }, float = true, center = true })
hl.window_rule({ match = { class = "^(org.freedesktop.impl.portal.desktop.gtk)$" }, float = true, center = true })
hl.window_rule({ match = { class = "^([Xx]dg-desktop-portal-gtk)$" }, float = true, center = true })

-- Layer rules
hl.layer_rule({
    match = { namespace = "notifications" },
    blur = true,
    ignore_alpha = 0
})

-- Cupcake Settings App
hl.window_rule({ match = { title = "^(Cupcake Settings)$" }, float = true })
