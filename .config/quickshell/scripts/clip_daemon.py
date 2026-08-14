#!/usr/bin/env python3
import sys
import os
import json
import subprocess
from pathlib import Path

STATE_DIR = Path.home() / ".local" / "state" / "quickshell"
PINNED_FILE = STATE_DIR / "pinned_clips.json"

def ensure_state_dir():
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    if not PINNED_FILE.exists():
        with open(PINNED_FILE, "w", encoding="utf-8") as f:
            json.dump({"pinned_contents": []}, f)

def load_pinned():
    ensure_state_dir()
    try:
        with open(PINNED_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            return set(data.get("pinned_contents", []))
    except Exception:
        return set()

def save_pinned(pinned_set):
    ensure_state_dir()
    try:
        with open(PINNED_FILE, "w", encoding="utf-8") as f:
            json.dump({"pinned_contents": list(pinned_set)}, f)
    except Exception:
        pass

def get_clips():
    pinned_set = load_pinned()
    items = []
    try:
        res = subprocess.run(["cliphist", "list"], capture_output=True, text=True, errors="replace")
        lines = res.stdout.strip().split("\n") if res.stdout else []
        for line in lines[:60]:
            if not line.strip():
                continue
            parts = line.split("\t", 1)
            clip_id = parts[0].strip()
            preview = parts[1] if len(parts) > 1 else ""
            
            is_image = preview.startswith("[[ binary data") or "image" in preview.lower() or ".png" in preview.lower() or ".jpg" in preview.lower()
            clip_type = "image" if is_image else "text"
            
            is_pinned = preview in pinned_set
            
            items.append({
                "id": clip_id,
                "type": clip_type,
                "preview": preview[:250],
                "content": preview,
                "pinned": is_pinned
            })
    except Exception as e:
        items = []
    
    # Sort pinned items to the top, then recent
    items.sort(key=lambda x: (not x["pinned"]))
    print(json.dumps(items))

def copy_clip(clip_id):
    try:
        p1 = subprocess.Popen(["cliphist", "decode", str(clip_id)], stdout=subprocess.PIPE)
        subprocess.run(["wl-copy"], stdin=p1.stdout, check=True)
        p1.stdout.close()
        p1.wait()
    except Exception as e:
        pass

def toggle_pin(clip_id):
    try:
        res = subprocess.run(["cliphist", "list"], capture_output=True, text=True, errors="replace")
        lines = res.stdout.strip().split("\n") if res.stdout else []
        target_content = None
        for line in lines:
            parts = line.split("\t", 1)
            if parts[0].strip() == str(clip_id):
                target_content = parts[1] if len(parts) > 1 else ""
                break
        
        if target_content:
            pinned = load_pinned()
            if target_content in pinned:
                pinned.remove(target_content)
            else:
                pinned.add(target_content)
            save_pinned(pinned)
    except Exception:
        pass

def delete_clip(clip_id):
    try:
        res = subprocess.run(["cliphist", "list"], capture_output=True, text=True, errors="replace")
        lines = res.stdout.strip().split("\n") if res.stdout else []
        for line in lines:
            parts = line.split("\t", 1)
            if parts[0].strip() == str(clip_id):
                # Remove from cliphist
                p = subprocess.Popen(["cliphist", "delete"], stdin=subprocess.PIPE, text=True)
                p.communicate(input=line + "\n")
                # Remove from pinned if present
                content = parts[1] if len(parts) > 1 else ""
                pinned = load_pinned()
                if content in pinned:
                    pinned.remove(content)
                    save_pinned(pinned)
                break
    except Exception:
        pass

def clear_all():
    try:
        pinned = load_pinned()
        # Get list of all items
        res = subprocess.run(["cliphist", "list"], capture_output=True, text=True, errors="replace")
        lines = res.stdout.strip().split("\n") if res.stdout else []
        for line in lines:
            parts = line.split("\t", 1)
            content = parts[1] if len(parts) > 1 else ""
            if content not in pinned:
                p = subprocess.Popen(["cliphist", "delete"], stdin=subprocess.PIPE, text=True)
                p.communicate(input=line + "\n")
    except Exception:
        pass

def main():
    if len(sys.argv) < 2:
        get_clips()
        return
    
    cmd = sys.argv[1]
    if cmd == "get":
        get_clips()
    elif cmd == "copy" and len(sys.argv) >= 3:
        copy_clip(sys.argv[2])
    elif cmd == "pin" and len(sys.argv) >= 3:
        toggle_pin(sys.argv[2])
    elif cmd == "delete" and len(sys.argv) >= 3:
        delete_clip(sys.argv[2])
    elif cmd == "clear":
        clear_all()
    else:
        get_clips()

if __name__ == "__main__":
    main()
