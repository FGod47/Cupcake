#!/usr/bin/env python3
import sys
import subprocess
import json
import os

if len(sys.argv) < 2:
    print("[]")
    sys.exit(0)

query = sys.argv[1].strip()
if not query:
    print("[]")
    sys.exit(0)

home = os.path.expanduser("~")
cmd = [
    "find", home,
    "-maxdepth", "5",
    "-type", "f",
    "-not", "-path", "*/\.*",
    "-not", "-path", "*/node_modules/*",
    "-not", "-path", "*/__pycache__/*",
    "-iname", f"*{query}*"
]

try:
    # Run find, get top 10 results directly using head to prevent massive output
    find_proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    head_proc = subprocess.Popen(["head", "-n", "8"], stdin=find_proc.stdout, stdout=subprocess.PIPE)
    find_proc.stdout.close()
    output = head_proc.communicate(timeout=2)[0].decode("utf-8")
except Exception as e:
    output = ""

results = []
for line in output.splitlines():
    if not line: continue
    filepath = line.strip()
    filename = os.path.basename(filepath)
    
    icon = "text-x-generic"
    lower_name = filename.lower()
    if lower_name.endswith((".png", ".jpg", ".jpeg", ".gif", ".svg")):
        icon = "image-x-generic"
    elif lower_name.endswith((".mp4", ".mkv", ".webm")):
        icon = "video-x-generic"
    elif lower_name.endswith((".mp3", ".wav", ".flac", ".ogg")):
        icon = "audio-x-generic"
    elif lower_name.endswith((".pdf", ".doc", ".docx", ".txt", ".md")):
        icon = "x-office-document"
    elif lower_name.endswith((".py", ".js", ".html", ".css", ".qml", ".cpp", ".c", ".h", ".sh")):
        icon = "text-x-script"
    elif lower_name.endswith((".zip", ".tar", ".gz", ".rar", ".7z")):
        icon = "package-x-generic"
        
    results.append({
        "name": filename,
        "comment": filepath,
        "url": filepath,
        "icon": icon
    })

print(json.dumps(results))
