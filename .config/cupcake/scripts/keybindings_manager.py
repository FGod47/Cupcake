#!/usr/bin/env python3
import sys
import os
import json
import subprocess

CONFIG_DIR = os.path.expanduser("~/.config/cupcake")
SHORTCUTS_JSON = os.path.join(CONFIG_DIR, ".shortcuts.json")
HYPR_KEYBINDING_LUA = os.path.expanduser("~/.config/hypr/keybinding.lua")
CUPCAKE_KEYBINDING_LUA = os.path.expanduser("~/Cupcake/.config/hypr/keybinding.lua")

DEFAULT_SHORTCUTS = [
    # PILL / PANELS
    {
        "category": "PILL",
        "items": [
            { "id": "app_launcher", "label": "App launcher", "key": "SUPER + space", "default_key": "SUPER + space", "cmd": 'hl.dsp.exec_cmd(HOME .. "/.config/cupcake/scripts/toggle_app_launcher.sh")' },
            { "id": "overview", "label": "Workspace overview", "key": "SUPER + Tab", "default_key": "SUPER + Tab", "cmd": 'hl.dsp.global("quickshell:overview_toggle")' },
            { "id": "powermenu", "label": "Power menu", "key": "SUPER + P", "default_key": "SUPER + P", "cmd": 'hl.dsp.global("quickshell:powermenu_toggle")' },
            { "id": "aipanel", "label": "AI panel", "key": "SUPER + A", "default_key": "SUPER + A", "cmd": 'hl.dsp.global("quickshell:aipanel_toggle")' },
            { "id": "settings", "label": "These settings", "key": "SUPER + I", "default_key": "SUPER + I", "cmd": 'hl.dsp.exec_cmd("quickshell -p " .. HOME .. "/.config/quickshell/Settings.qml")' },
            { "id": "shortcuts_manager", "label": "Shortcuts cheat sheet", "key": "SUPER + slash", "default_key": "SUPER + slash", "cmd": 'hl.dsp.exec_cmd("quickshell -p " .. HOME .. "/.config/quickshell/ShortcutsManager.qml")' },
            { "id": "clipboard", "label": "Clipboard", "key": "SUPER + SHIFT + V", "default_key": "SUPER + SHIFT + V", "cmd": 'hl.dsp.global("quickshell:clipboard_toggle")' },
            { "id": "wallpaper", "label": "Wallpaper switcher", "key": "SUPER + SHIFT + W", "default_key": "SUPER + SHIFT + W", "cmd": 'hl.dsp.exec_cmd("quickshell -p " .. HOME .. "/.config/quickshell/WallpaperSwitcher.qml")' },
            { "id": "toggle_bar", "label": "Toggle top bar", "key": "SUPER + SHIFT + B", "default_key": "SUPER + SHIFT + B", "cmd": 'hl.dsp.exec_cmd(HOME .. "/.config/cupcake/scripts/toggle_bar.sh")' },
            { "id": "restart_qs", "label": "Restart quickshell", "key": "ALT + SHIFT + W", "default_key": "ALT + SHIFT + W", "cmd": 'hl.dsp.exec_cmd(HOME .. "/.config/cupcake/scripts/restart_quickshell.sh")' },
            { "id": "theme_toggle", "label": "Switch theme", "key": "SUPER + T", "default_key": "SUPER + T", "cmd": 'hl.dsp.exec_cmd(HOME .. "/.config/cupcake/scripts/toggle_theme.sh")' },
            { "id": "lockscreen", "label": "Lock screen", "key": "SUPER + SHIFT + L", "default_key": "SUPER + SHIFT + L", "cmd": 'hl.dsp.exec_cmd(HOME .. "/.local/share/quickshell-lockscreen/lock.sh")' }
        ]
    },
    # APPLICATIONS
    {
        "category": "APPLICATIONS",
        "items": [
            { "id": "terminal", "label": "Terminal", "key": "SUPER + Q", "default_key": "SUPER + Q", "cmd": 'hl.dsp.exec_cmd(apps.terminal)' },
            { "id": "terminal_float", "label": "Terminal (floating)", "key": "SUPER + SHIFT + T", "default_key": "SUPER + SHIFT + T", "cmd": 'hl.dsp.exec_cmd(apps.terminal, { float = true, size = "1000 500" })' },
            { "id": "browser", "label": "Browser", "key": "SUPER + F", "default_key": "SUPER + F", "cmd": 'hl.dsp.exec_cmd(apps.browser)' },
            { "id": "file_manager", "label": "File manager", "key": "SUPER + E", "default_key": "SUPER + E", "cmd": 'hl.dsp.exec_cmd(apps.fileManager)' },
            { "id": "ide", "label": "Code IDE", "key": "SUPER + C", "default_key": "SUPER + C", "cmd": 'hl.dsp.exec_cmd("antigravity-ide")' },
            { "id": "notes", "label": "Notes", "key": "SUPER + O", "default_key": "SUPER + O", "cmd": 'hl.dsp.exec_cmd("obsidian " .. HOME .. "/Obsidian/\\\\ \\\\Vault\\\\ Notes.canvas")' },
            { "id": "task_manager", "label": "Task manager", "key": "CTRL + SHIFT + tab", "default_key": "CTRL + SHIFT + tab", "cmd": 'hl.dsp.exec_cmd(apps.terminal .. " " .. apps.taskManager)' },
            { "id": "colorpicker", "label": "Color picker", "key": "SUPER + N", "default_key": "SUPER + N", "cmd": 'hl.dsp.exec_cmd(apps.colorpicker .. " -a")' },
            { "id": "screenshot_region", "label": "Screenshot (region)", "key": "SUPER + SHIFT + Print", "default_key": "SUPER + SHIFT + Print", "cmd": 'hl.dsp.exec_cmd("bash -c \'mkdir -p $HOME/Pictures/Screenshot && file=\\\"$HOME/Pictures/Screenshot/$(date +%m-%d-%H-%M-%S-%3N).png\\\" && grim -g \\\"$(slurp)\\\" \\\"$file\\\" && notify-send \\\"Screenshot Saved\\\" \\\"$file\\\" -i \\\"$file\\\"\'")' },
            { "id": "screenshot_full", "label": "Screenshot (full)", "key": "ALT + SHIFT + S", "default_key": "ALT + SHIFT + S", "cmd": 'hl.dsp.exec_cmd("bash -c \'mkdir -p $HOME/Pictures/Screenshot && file=\\\"$HOME/Pictures/Screenshot/$(date +%m-%d-%H-%M-%S-%3N).png\\\" && grim \\\"$file\\\" && notify-send \\\"Screenshot Saved\\\" \\\"$file\\\" -i \\\"$file\\\"\'")' },
            { "id": "screenshot_edit", "label": "Screenshot (edit)", "key": "SUPER + Print", "default_key": "SUPER + Print", "cmd": 'hl.dsp.exec_cmd(HOME .. "/.config/cupcake/scripts/screenshot-edit.sh")' },
            { "id": "record_screen", "label": "Record screen", "key": "SUPER + SHIFT + J", "default_key": "SUPER + SHIFT + J", "cmd": 'hl.dsp.exec_cmd(HOME .. "/.config/cupcake/scripts/record-screen.sh")' },
            { "id": "stop_recording", "label": "Stop recording", "key": "SUPER + SHIFT + K", "default_key": "SUPER + SHIFT + K", "cmd": 'hl.dsp.exec_cmd("pkill wf-recorder")' }
        ]
    },
    # WINDOWS
    {
        "category": "WINDOWS",
        "items": [
            { "id": "close_window", "label": "Close window", "key": "ALT + Q", "default_key": "ALT + Q", "cmd": 'hl.dsp.window.close()' },
            { "id": "float_window", "label": "Floating window", "key": "SUPER + V", "default_key": "SUPER + V", "cmd": 'hl.dsp.window.float({ action = "toggle" })' },
            { "id": "maximize_window", "label": "Maximize window", "key": "SUPER + W", "default_key": "SUPER + W", "cmd": 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })' },
            { "id": "fullscreen_window", "label": "Fullscreen", "key": "SUPER + G", "default_key": "SUPER + G", "cmd": 'hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })' },
            { "id": "cycle_next", "label": "Cycle window next", "key": "ALT + Tab", "default_key": "ALT + Tab", "cmd": 'hl.dsp.window.cycle_next()' },
            { "id": "cycle_prev", "label": "Cycle window prev", "key": "ALT + SHIFT + Tab", "default_key": "ALT + SHIFT + Tab", "cmd": 'hl.dsp.window.cycle_next("prev")' }
        ]
    },
    # WORKSPACES
    {
        "category": "WORKSPACES",
        "items": [
            { "id": "focus_left", "label": "Focus left", "key": "SUPER + H", "default_key": "SUPER + H", "cmd": 'hl.dsp.focus({ direction = "left" })' },
            { "id": "focus_right", "label": "Focus right", "key": "SUPER + L", "default_key": "SUPER + L", "cmd": 'hl.dsp.focus({ direction = "right" })' },
            { "id": "focus_up", "label": "Focus up", "key": "SUPER + K", "default_key": "SUPER + K", "cmd": 'hl.dsp.focus({ direction = "up" })' },
            { "id": "focus_down", "label": "Focus down", "key": "SUPER + J", "default_key": "SUPER + J", "cmd": 'hl.dsp.focus({ direction = "down" })' },
            { "id": "special_workspace", "label": "Scratchpad / Special", "key": "SUPER + S", "default_key": "SUPER + S", "cmd": 'hl.dsp.workspace.toggle_special("magic")' },
            { "id": "move_special", "label": "Move to scratchpad", "key": "SUPER + SHIFT + E", "default_key": "SUPER + SHIFT + E", "cmd": 'hl.dsp.window.move({ workspace = "special:magic" })' }
        ]
    }
]

FIXED_ITEMS = [
    { "key": "Super + 1..0", "label": "Switch workspace" },
    { "key": "Super + Shift + 1..0", "label": "Move to workspace" },
    { "key": "Super + ↑↓←→", "label": "Focus by direction" },
    { "key": "Super + Shift + ↑↓←→", "label": "Move window" },
    { "key": "Alt + ↑↓←→", "label": "Resize window" },
    { "key": "Super + wheel", "label": "Cycle workspaces" },
    { "key": "Super + left click", "label": "Drag window" },
    { "key": "Super + right click", "label": "Resize window" },
    { "key": "Middle mouse button", "label": "Close window" },
    { "key": "Media keys", "label": "Volume, brightness" },
    { "key": "Laptop lid", "label": "Lock screen" }
]

def load_shortcuts():
    if os.path.exists(SHORTCUTS_JSON):
        try:
            with open(SHORTCUTS_JSON, "r") as f:
                data = json.load(f)
                return data
        except Exception:
            pass
    return DEFAULT_SHORTCUTS

def save_shortcuts(categories):
    os.makedirs(CONFIG_DIR, exist_ok=True)
    with open(SHORTCUTS_JSON, "w") as f:
        json.dump(categories, f, indent=2)

    # Generate Lua file
    lines = [
        'hl.config({',
        '    binds = {',
        '        workspace_back_and_forth = true,',
        '        allow_workspace_cycles = true',
        '    }',
        '})',
        '',
        'local HOME = os.getenv("HOME") or "/home/zero"',
        'local apps = require("apps")',
        'local mainMod = "SUPER"',
        'local sMod = "SUPER + SHIFT"',
        'local aMod = "ALT"',
        ''
    ]

    for cat in categories:
        lines.append(f'-- ── {cat["category"]} ──')
        for it in cat["items"]:
            k = it.get("key", "").strip()
            cmd = it.get("cmd", "")
            if k and k.upper() != "NONE" and cmd:
                lines.append(f'hl.bind("{k}", {cmd})')
        lines.append('')

    # Fixed core system bindings
    lines.append('-- ── Audio & Media Controls ──')
    lines.append('hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(HOME .. "/.local/bin/volume.sh up"), { repeating = true })')
    lines.append('hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(HOME .. "/.local/bin/volume.sh down"), { repeating = true })')
    lines.append('hl.bind("XF86AudioMute",        hl.dsp.exec_cmd(HOME .. "/.local/bin/volume.sh mute"), { repeating = true })')
    lines.append('hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })')
    lines.append('hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })')
    lines.append('hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })')
    lines.append('hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(HOME .. "/.local/bin/brightness.sh down"), { repeating = true })')
    lines.append('hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(HOME .. "/.local/bin/brightness.sh up"),   { repeating = true })')
    lines.append('')
    lines.append('-- ── Workspaces & Mouse Navigation ──')
    lines.append('for i = 1, 10 do')
    lines.append('    local key = i % 10')
    lines.append('    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))')
    lines.append('    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))')
    lines.append('end')
    lines.append('hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))')
    lines.append('hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))')
    lines.append('hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })')
    lines.append('hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })')
    lines.append('')

    content = '\n'.join(lines)

    try:
        with open(HYPR_KEYBINDING_LUA, "w") as f:
            f.write(content)
        if os.path.exists(os.path.dirname(CUPCAKE_KEYBINDING_LUA)):
            with open(CUPCAKE_KEYBINDING_LUA, "w") as f:
                f.write(content)
    except Exception as e:
        print(f"Error writing keybinding.lua: {e}", file=sys.stderr)

    # Reload Hyprland
    subprocess.run(["hyprctl", "reload"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return True

if __name__ == "__main__":
    if len(sys.argv) > 1:
        action = sys.argv[1]
        if action == "get":
            shortcuts = load_shortcuts()
            print(json.dumps({ "categories": shortcuts, "fixed": FIXED_ITEMS }))
        elif action == "save":
            raw = ""
            if len(sys.argv) > 2:
                raw = sys.argv[2]
            elif os.path.exists("/tmp/cupcake_shortcuts_save.json"):
                try:
                    with open("/tmp/cupcake_shortcuts_save.json", "r") as f:
                        raw = f.read()
                except Exception:
                    pass
            if not raw:
                raw = sys.stdin.read()
            if raw:
                try:
                    data = json.loads(raw)
                    save_shortcuts(data.get("categories", data))
                    print(json.dumps({ "status": "ok" }))
                except Exception as e:
                    print(json.dumps({ "status": "error", "message": str(e) }))
        elif action == "reset":
            save_shortcuts(DEFAULT_SHORTCUTS)
            print(json.dumps({ "categories": DEFAULT_SHORTCUTS, "fixed": FIXED_ITEMS }))
    else:
        shortcuts = load_shortcuts()
        print(json.dumps({ "categories": shortcuts, "fixed": FIXED_ITEMS }))
