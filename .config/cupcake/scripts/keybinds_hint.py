#!/usr/bin/env python3
import sys
import json
import subprocess
import gi

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, Pango, GLib

MODMASKS = {
    64: "Super",
    8: "Alt",
    4: "Ctrl",
    1: "Shift",
}

CSS = """
window {
    background-color: #1e1e2e;
    color: #cdd6f4;
    font-family: 'JetBrains Mono', sans-serif;
}
headerbar {
    background-color: #11111b;
    border: none;
    box-shadow: none;
}
notebook header {
    background-color: #181825;
}
notebook tab {
    background-color: transparent;
    color: #a6adc8;
    padding: 8px 16px;
    border: none;
    font-weight: bold;
}
notebook tab:checked {
    color: #cdd6f4;
    border-bottom: 2px solid #cba6f7;
}
.search-bar {
    background-color: #181825;
    color: #cdd6f4;
    border: 1px solid #313244;
    border-radius: 8px;
    padding: 8px 12px;
}
.search-bar:focus {
    border-color: #cba6f7;
}
flowbox {
    padding: 10px;
    background-color: #1e1e2e;
}
flowboxchild {
    background-color: #181825;
    border: 1px solid #313244;
    border-radius: 10px;
    padding: 12px;
    margin: 5px;
}
flowboxchild:selected {
    background-color: #181825;
    border: 1px solid #cba6f7;
}
.keycap {
    background-color: #1e1e2e;
    color: #cdd6f4;
    font-weight: 800;
    padding: 4px 10px;
    border-radius: 6px;
    border-bottom: 3px solid #11111b;
    border-left: 1px solid #313244;
    border-top: 1px solid #313244;
    border-right: 1px solid #313244;
}
.keycap-super {
    background-color: #cba6f7;
    color: #1e1e2e;
    border-bottom: 3px solid #b4befe;
    border-left: 1px solid #cba6f7;
    border-top: 1px solid #cba6f7;
    border-right: 1px solid #cba6f7;
}
.plus {
    color: #a6adc8;
    font-weight: bold;
    margin: 0 4px;
}
.command {
    color: #a6adc8;
    font-size: 13px;
    margin-top: 8px;
}
.description {
    color: #cdd6f4;
    font-size: 14px;
    font-weight: bold;
    margin-top: 8px;
}
"""

def apply_css():
    provider = Gtk.CssProvider()
    provider.load_from_data(CSS.encode('utf-8'))
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
        if settings:
            settings.set_property("gtk-application-prefer-dark-theme", True)

        self.binds = get_binds()
        self.categories = {}
        
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
            category = bind.get('dispatcher', 'Other')
            
            if category not in self.categories:
                self.categories[category] = []
            self.categories[category].append((mods, key, desc, command))

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

        self.notebook = Gtk.Notebook()
        self.notebook.set_scrollable(True)
        vbox.pack_start(self.notebook, True, True, 0)

        self.flowboxes = []

        for category, items in sorted(self.categories.items()):
            flowbox = Gtk.FlowBox()
            flowbox.set_valign(Gtk.Align.START)
            flowbox.set_selection_mode(Gtk.SelectionMode.SINGLE)
            flowbox.set_max_children_per_line(10)
            flowbox.set_min_children_per_line(1)
            flowbox.set_row_spacing(10)
            flowbox.set_column_spacing(10)

            for item in items:
                mods, key, desc, command = item
                
                card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
                card.set_margin_top(5)
                card.set_margin_bottom(5)
                card.set_margin_start(5)
                card.set_margin_end(5)

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
                
                # Store search string directly on child
                search_str = f"{' '.join(mods)} {key} {desc} {command}".lower()
                child.search_str = search_str
                
                flowbox.insert(child, -1)

            flowbox.set_filter_func(self.filter_func)
            self.flowboxes.append(flowbox)

            scrolled = Gtk.ScrolledWindow()
            scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
            scrolled.add(flowbox)

            cat_name = category.replace("to", " to ").replace("workspace", "Workspace").title()
            self.notebook.append_page(scrolled, Gtk.Label(label=cat_name))

    def on_search_changed(self, entry):
        self.search_query = entry.get_text().lower()
        for flowbox in self.flowboxes:
            flowbox.invalidate_filter()

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
