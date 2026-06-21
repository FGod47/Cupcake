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
        
        lua_content += f'hl.monitor({{\n    output = "{out}",\n    mode = "{w}x{h}@{hz:.3f}",\n    position = "{x}x{y}",\n    scale = {scale}\n}})\n\n'

    lua_content += 'hl.monitor({\n    output = "",\n    mode = "highrr",\n    position = "auto",\n    scale = 1\n})\n'

    config_path = os.path.expanduser('~/.config/hypr/monitor.lua')
    with open(config_path, 'w') as f:
        f.write(lua_content)
    
    print(f"Successfully wrote {config_path}")

if __name__ == "__main__":
    generate()
