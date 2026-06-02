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

def decode_modmask(modmask):
    if not modmask:
        return ""
    keys = []
    for mask in sorted(MODMASKS.keys(), reverse=True):
        if modmask >= mask:
            keys.append(MODMASKS[mask])
            modmask -= mask
    return " + ".join(keys)

def get_binds():
    try:
        output = subprocess.check_output(['hyprctl', 'binds', '-j']).decode('utf-8')
        return json.loads(output)
    except Exception as e:
        print("Failed to get binds:", e)
        return []

class keybinds hintWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="keybinds hint (Cupcake)")
        self.set_default_size(800, 600)
        self.set_position(Gtk.WindowPosition.CENTER)

        # Apply a dark theme preference
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

            mod = decode_modmask(bind.get('modmask', 0))
            key = bind.get('key', '')
            
            # Special keys
            if key == "mouse:272": key = "LMB"
            if key == "mouse:273": key = "RMB"
            
            shortcut = f"{mod} + {key}" if mod else key
            category = bind.get('dispatcher', 'Other')
            
            if category not in self.categories:
                self.categories[category] = []
            self.categories[category].append((shortcut, desc))

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.add(vbox)

        # Header bar (mimicking keybinds hint)
        header = Gtk.HeaderBar()
        header.set_show_close_button(True)
        header.props.title = "keybinds hint"
        self.set_titlebar(header)

        # Search bar
        search_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        search_box.set_margin_top(10)
        search_box.set_margin_bottom(10)
        search_box.set_margin_start(10)
        search_box.set_margin_end(10)
        
        self.search_entry = Gtk.SearchEntry()
        self.search_entry.set_hexpand(True)
        self.search_entry.connect("search-changed", self.on_search_changed)
        search_box.pack_start(self.search_entry, True, True, 0)
        vbox.pack_start(search_box, False, False, 0)

        # Notebook for categories
        self.notebook = Gtk.Notebook()
        self.notebook.set_scrollable(True)
        vbox.pack_start(self.notebook, True, True, 0)

        self.liststores = []

        for category, items in sorted(self.categories.items()):
            # ListStore: Shortcut, Description
            liststore = Gtk.ListStore(str, str)
            for item in items:
                liststore.append(list(item))

            filter_model = liststore.filter_new()
            filter_model.set_visible_func(self.filter_func)
            self.liststores.append((filter_model, liststore))

            treeview = Gtk.TreeView(model=filter_model)
            treeview.set_headers_visible(False)
            
            renderer_shortcut = Gtk.CellRendererText()
            renderer_shortcut.set_property("weight", Pango.Weight.BOLD)
            renderer_shortcut.set_property("foreground", "#89b4fa") # Catppuccin Blue
            column_shortcut = Gtk.TreeViewColumn("Shortcut", renderer_shortcut, text=0)
            column_shortcut.set_min_width(200)
            treeview.append_column(column_shortcut)

            renderer_desc = Gtk.CellRendererText()
            renderer_desc.set_property("foreground", "#cdd6f4") # Catppuccin Text
            column_desc = Gtk.TreeViewColumn("Description", renderer_desc, text=1)
            treeview.append_column(column_desc)

            scrolled = Gtk.ScrolledWindow()
            scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
            scrolled.add(treeview)

            # Map categories to nice names
            cat_name = category.replace("to", " to ").replace("workspace", "Workspace").title()
            self.notebook.append_page(scrolled, Gtk.Label(label=cat_name))

    def on_search_changed(self, entry):
        self.search_query = entry.get_text().lower()
        for filter_model, _ in self.liststores:
            filter_model.refilter()

    def filter_func(self, model, iter, data):
        if not hasattr(self, 'search_query') or not self.search_query:
            return True
        shortcut = model[iter][0].lower()
        desc = model[iter][1].lower()
        return self.search_query in shortcut or self.search_query in desc

def main():
    GLib.set_prgname('com.cupcake.keybinds hint')
    app = keybinds hintWindow()
    app.connect("destroy", Gtk.main_quit)
    app.show_all()
    Gtk.main()

if __name__ == "__main__":
    main()
