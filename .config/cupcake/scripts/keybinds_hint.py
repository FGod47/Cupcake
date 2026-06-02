#!/usr/bin/env python3
import sys
import json
import subprocess
import os
import re
import gi

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, Pango, GLib

MODMASKS = {
    64: "Super",
    8: "Alt",
    4: "Ctrl",
    1: "Shift",
}

CSS_TEMPLATE = """
window {{
    background-color: {main_bg};
    color: {main_fg};
    font-family: 'JetBrains Mono', sans-serif;
}}
.search-bar {{
    background-color: {main_bg};
    color: {main_fg};
    border: 1px solid {main_br};
    border-radius: 8px;
    padding: 8px 12px;
}}
.search-bar:focus {{
    border-color: {main_br};
}}
flowbox {{
    padding: 10px;
    background-color: {main_bg};
}}
flowboxchild {{
    background-color: alpha({main_fg}, 0.05);
    border: 1px solid alpha({main_fg}, 0.1);
    border-radius: 10px;
    padding: 12px;
    margin: 5px;
}}
flowboxchild:selected {{
    background-color: alpha({main_br}, 0.1);
    border: 1px solid {main_br};
}}
.keycap {{
    background-color: {main_bg};
    color: {main_fg};
    font-weight: 800;
    padding: 4px 10px;
    border-radius: 6px;
    border-bottom: 3px solid alpha({main_fg}, 0.2);
    border-left: 1px solid alpha({main_fg}, 0.1);
    border-top: 1px solid alpha({main_fg}, 0.1);
    border-right: 1px solid alpha({main_fg}, 0.1);
}}
.keycap-super {{
    background-color: {main_br};
    color: {main_bg};
    border-bottom: 3px solid alpha({main_bg}, 0.3);
    border-left: 1px solid {main_br};
    border-top: 1px solid {main_br};
    border-right: 1px solid {main_br};
}}
.plus {{
    color: alpha({main_fg}, 0.6);
    font-weight: bold;
    margin: 0 4px;
}}
.command {{
    color: alpha({main_fg}, 0.6);
    font-size: 13px;
    margin-top: 8px;
}}
.description {{
    color: {main_fg};
    font-size: 14px;
    font-weight: bold;
    margin-top: 8px;
}}
.category-label {{
    color: {main_br};
    font-size: 12px;
    font-weight: bold;
    margin-bottom: 4px;
    text-transform: uppercase;
}}
"""

def get_theme_colors():
    colors = {
        "main_bg": "#1e1e2e",
        "main_fg": "#cdd6f4",
        "main_br": "#cba6f7",
        "select_bg": "#cba6f7",
        "select_fg": "#11111b"
    }
    
    theme_path = os.path.expanduser("~/.config/rofi/theme.rasi")
    if os.path.exists(theme_path):
        with open(theme_path, "r") as f:
            content = f.read()
            for match in re.finditer(r"([a-z-]+):\s*(#[a-fA-F0-9]+)", content):
                key = match.group(1).replace("-", "_")
                val = match.group(2)[:7]  # GTK3 only supports #RRGGBB, not #RRGGBBAA
                colors[key] = val
    return colors

def apply_css():
    colors = get_theme_colors()
    css_data = CSS_TEMPLATE.format(**colors)
    provider = Gtk.CssProvider()
    provider.load_from_data(css_data.encode('utf-8'))
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )

def get_mods(modmask):
    if not modmask: return []
    keys = []
    for mask in sorted(MODMASKS.keys(), reverse=True):
        if modmask >= mask:
            keys.append(MODMASKS[mask])
            modmask -= mask
    return keys

def get_binds():
    try:
        output = subprocess.check_output(['hyprctl', 'binds', '-j']).decode('utf-8')
        return json.loads(output)
    except Exception as e:
        print("Failed to get binds:", e)
        return []

class keybinds hintWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="keybinds hint")
        self.set_default_size(900, 650)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_decorated(False)
        self.connect("key-press-event", self.on_key_press)

        settings = Gtk.Settings.get_default()

        self.binds = get_binds()
        
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.add(vbox)

        search_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        search_box.set_margin_top(15)
        search_box.set_margin_bottom(15)
        search_box.set_margin_start(20)
        search_box.set_margin_end(20)
        
        self.search_entry = Gtk.SearchEntry()
        self.search_entry.get_style_context().add_class("search-bar")
        self.search_entry.set_hexpand(True)
        self.search_entry.set_placeholder_text("Search keybinds, commands, descriptions...")
        self.search_entry.connect("search-changed", self.on_search_changed)
        search_box.pack_start(self.search_entry, True, True, 0)
        vbox.pack_start(search_box, False, False, 0)

        # Create a single FlowBox for everything
        self.flowbox = Gtk.FlowBox()
        self.flowbox.set_valign(Gtk.Align.START)
        self.flowbox.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.flowbox.set_max_children_per_line(10)
        self.flowbox.set_min_children_per_line(1)
        self.flowbox.set_row_spacing(10)
        self.flowbox.set_column_spacing(10)

        for bind in self.binds:
            if bind.get('has_description'):
                desc = bind.get('description', '')
            else:
                desc = bind.get('dispatcher', '') + " " + bind.get('arg', '')
            
            if not desc.strip():
                continue

            mods = get_mods(bind.get('modmask', 0))
            key = bind.get('key', '')
            if key == "mouse:272": key = "LMB"
            if key == "mouse:273": key = "RMB"
            
            command = f"{bind.get('dispatcher', '')} {bind.get('arg', '')}".strip()
            category = bind.get('dispatcher', 'Other').replace("to", " to ").replace("workspace", "Workspace").title()

            card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
            card.set_margin_top(5)
            card.set_margin_bottom(5)
            card.set_margin_start(5)
            card.set_margin_end(5)

            # Optional: show category as a tiny label on the card
            cat_lbl = Gtk.Label(label=category)
            cat_lbl.set_xalign(0.0)
            cat_lbl.get_style_context().add_class("category-label")
            card.pack_start(cat_lbl, False, False, 0)

            keys_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
            keys_box.set_valign(Gtk.Align.CENTER)
            
            for i, m in enumerate(mods):
                if i > 0:
                    plus = Gtk.Label(label="+")
                    plus.get_style_context().add_class("plus")
                    keys_box.pack_start(plus, False, False, 0)
                
                key_lbl = Gtk.Label(label=m)
                key_lbl.get_style_context().add_class("keycap")
                if m == "Super":
                    key_lbl.get_style_context().add_class("keycap-super")
                keys_box.pack_start(key_lbl, False, False, 0)
            
            if mods and key:
                plus = Gtk.Label(label="+")
                plus.get_style_context().add_class("plus")
                keys_box.pack_start(plus, False, False, 0)

            if key:
                key_lbl = Gtk.Label(label=key.upper() if len(key) == 1 else key)
                key_lbl.get_style_context().add_class("keycap")
                keys_box.pack_start(key_lbl, False, False, 0)

            card.pack_start(keys_box, False, False, 0)

            desc_lbl = Gtk.Label(label=desc)
            desc_lbl.set_line_wrap(True)
            desc_lbl.set_max_width_chars(30)
            desc_lbl.set_xalign(0.0)
            desc_lbl.get_style_context().add_class("description")
            card.pack_start(desc_lbl, False, False, 0)

            cmd_lbl = Gtk.Label(label=command)
            cmd_lbl.set_line_wrap(True)
            cmd_lbl.set_max_width_chars(30)
            cmd_lbl.set_xalign(0.0)
            cmd_lbl.set_selectable(True)
            cmd_lbl.get_style_context().add_class("command")
            card.pack_start(cmd_lbl, False, False, 0)

            child = Gtk.FlowBoxChild()
            child.add(card)
            
            search_str = f"{category} {' '.join(mods)} {key} {desc} {command}".lower()
            child.search_str = search_str
            
            self.flowbox.insert(child, -1)

        self.flowbox.set_filter_func(self.filter_func)

        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scrolled.add(self.flowbox)

        vbox.pack_start(scrolled, True, True, 0)

    def on_search_changed(self, entry):
        self.search_query = entry.get_text().lower()
        self.flowbox.invalidate_filter()

    def filter_func(self, child):
        if not hasattr(self, 'search_query') or not self.search_query:
            return True
        return self.search_query in getattr(child, 'search_str', '')

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.destroy()
            return True
        return False

def main():
    apply_css()
    GLib.set_prgname('com.cupcake.keybinds hint')
    app = keybinds hintWindow()
    app.connect("destroy", Gtk.main_quit)
    app.show_all()
    Gtk.main()

if __name__ == "__main__":
    main()
