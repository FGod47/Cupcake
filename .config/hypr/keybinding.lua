hl.config({
    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles = true
    }
})

local apps = require("apps")
local mainMod = "SUPER"
local sMod = "SUPER + SHIFT"
local aMod = "ALT"

-- Basic keybinds
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(apps.terminal))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(apps.browser))
hl.bind(aMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + W", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mainMod .. " + G", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("obsidian " .. (os.getenv("HOME") or "/home/code") .. "/Obsidian/\\ \\Vault\\ Notes.canvas"))
hl.bind(sMod .. " + O", hl.dsp.exec_cmd("obsidian"))
hl.bind(sMod .. " + T", hl.dsp.exec_cmd(apps.terminal, { float = true, size = "1000 500" }))

-- Nautilus File Manager
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(apps.fileManager))
-- Quickshell Powermenu
hl.bind(mainMod .. " + P", hl.dsp.global("quickshell:powermenu_toggle"))
-- AI Panel Toggle
hl.bind(mainMod .. " + a", hl.dsp.global("quickshell:aipanel_toggle"))
-- QuickShell App Launcher
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd("~/.config/cupcake/scripts/toggle_app_launcher.sh"))
-- Hotkeys cheat sheet
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("~/.config/cupcake/scripts/keybinds_hint.sh"))

-- Toggle Cupcake Dark/Light Theme
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("~/.config/cupcake/scripts/toggle_theme.sh"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("antigravity-ide"))

-- Screenshots
hl.bind(sMod .. " + Print", hl.dsp.exec_cmd("bash -c 'mkdir -p $HOME/Pictures/Screenshot && file=\"$HOME/Pictures/Screenshot/$(date +%m-%d-%H-%M-%S).png\" && grim -g \"$(slurp)\" \"$file\" && notify-send \"Screenshot Saved\" \"$file\" -i \"$file\"'"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("~/.config/cupcake/scripts/screenshot-edit.sh"))

-- Screen recording
hl.bind(sMod .. " + J", hl.dsp.exec_cmd("~/.config/cupcake/scripts/record-screen.sh"))
hl.bind(sMod .. " + K", hl.dsp.exec_cmd("pkill wf-recorder"))

-- Toggle bar
hl.bind("ALT + SHIFT + W", hl.dsp.exec_cmd("~/.config/cupcake/scripts/toggle_bar.sh"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("~/.config/cupcake/scripts/toggle_bar.sh"))

-- Task Manager
hl.bind("CTRL + SHIFT + tab", hl.dsp.exec_cmd(apps.terminal .. " " .. apps.taskManager))

-- ColorPicker
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(apps.colorpicker .. " -a"))

-- Wallpaper switcher
hl.bind(sMod .. " + W", hl.dsp.exec_cmd("quickshell -p ~/.config/quickshell/WallpaperSwitcher.qml"))

-- Volume Control
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.local/bin/volume.sh up"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/.local/bin/volume.sh down"), { repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("~/.local/bin/volume.sh mute"), { repeating = true })

-- Player Control
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })

-- Brightness Control
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("~/.local/bin/brightness.sh down"), { repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("~/.local/bin/brightness.sh up"),   { repeating = true })

-- Lockscreen
hl.bind(sMod .. " + L", hl.dsp.exec_cmd("~/.local/share/quickshell-lockscreen/lock.sh"))

-- Cycling and focus management
hl.bind("ALT + tab",             hl.dsp.window.cycle_next())
hl.bind(mainMod .. " + tab",     hl.dsp.global("quickshell:overview_toggle"))
hl.bind("ALT + SHIFT + tab",     hl.dsp.window.cycle_next("prev"))

-- Move focus with mainMod + h/j/k/l
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces and move active windows
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.window.move({ workspace = "special:magic" }))

-- Workspace scrolling
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mouse dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Settings App
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("quickshell -p ~/.config/quickshell/Settings.qml"))
