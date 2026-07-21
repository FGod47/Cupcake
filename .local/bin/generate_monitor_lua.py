#!/usr/bin/env python3
import json
import subprocess
import os

def generate():
    try:
        output = subprocess.check_output(['hyprctl', 'monitors', '-j']).decode('utf-8')
        monitors = json.loads(output)
    except Exception as e:
        print(f"Error reading monitors: {e}")
        return

    lua_content = 'local HOME = os.getenv("HOME")\n\n'
    
    for m in monitors:
        out = m.get("name", "")
        w = m.get("width", 1920)
        h = m.get("height", 1080)
        hz = m.get("refreshRate", 60)
        scale = m.get("scale", 1)
        x = m.get("x", 0)
        y = m.get("y", 0)
        transform = m.get("transform", 0)
        fmt = m.get("currentFormat", "")
        bitdepth_str = ",\n    bitdepth = 10" if "2101010" in fmt or "1010102" in fmt else ""
        
        lua_content += f'hl.monitor({{\n    output = "{out}",\n    mode = "{w}x{h}@{hz:.3f}",\n    position = "{x}x{y}",\n    scale = {scale},\n    transform = {transform}{bitdepth_str}\n}})\n\n'

    lua_content += 'hl.monitor({\n    output = "",\n    mode = "highrr",\n    position = "auto",\n    scale = 1\n})\n\n'

    # Fetch and persist VRR
    try:
        vrr_output = subprocess.check_output(['hyprctl', 'getoption', 'misc:vrr', '-j']).decode('utf-8')
        vrr_json = json.loads(vrr_output)
        vrr_val = vrr_json.get('int', 0)
        lua_content += f'hl.config({{\n    misc = {{\n        vrr = {vrr_val}\n    }}\n}})\n'
    except Exception as e:
        print(f"Error reading VRR: {e}")

    config_path = os.path.expanduser('~/.config/hypr/monitor.lua')
    with open(config_path, 'w') as f:
        f.write(lua_content)
    
    print(f"Successfully wrote {config_path}")

if __name__ == "__main__":
    generate()
