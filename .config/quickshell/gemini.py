#!/usr/bin/env python3
import sys
import json
import urllib.request
import os

key_path = os.path.expanduser("~/.config/quickshell/gemini_key.txt")
try:
    with open(key_path, "r") as f:
        API_KEY = f.read().strip()
except Exception:
    print(json.dumps({"error": "No API key found in ~/.config/quickshell/gemini_key.txt"}))
    sys.exit(1)

if not API_KEY:
    print(json.dumps({"error": "API key is empty."}))
    sys.exit(1)

if len(sys.argv) < 2:
    sys.exit(0)

prompt = sys.argv[1]
url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:streamGenerateContent?alt=sse&key={API_KEY}"

data = {
    "contents": [{"parts": [{"text": prompt}]}]
}

req = urllib.request.Request(url, data=json.dumps(data).encode('utf-8'), method="POST")
req.add_header("Content-Type", "application/json")

try:
    with urllib.request.urlopen(req) as response:
        for line in response:
            line = line.decode('utf-8').strip()
            if line.startswith("data: "):
                try:
                    payload = json.loads(line[6:])
                    text = payload["candidates"][0]["content"]["parts"][0].get("text", "")
                    if text:
                        print(json.dumps({"text": text}))
                        sys.stdout.flush()
                except Exception:
                    pass
except Exception as e:
    print(json.dumps({"error": str(e)}))
