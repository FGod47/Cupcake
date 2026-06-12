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

MODEL = "gemini-3.5-flash"
model_path = os.path.expanduser("~/.config/quickshell/gemini_model.txt")
try:
    with open(model_path, "r") as f:
        stored_model = f.read().strip()
        if stored_model:
            MODEL = stored_model
except Exception:
    pass

url = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:streamGenerateContent?alt=sse&key={API_KEY}"

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
except urllib.error.HTTPError as e:
    body = e.read().decode('utf-8')
    try:
        err_json = json.loads(body)
        err_msg = err_json.get("error", {}).get("message", str(e))
        print(json.dumps({"error": err_msg}))
    except Exception:
        print(json.dumps({"error": f"HTTP Error {e.code}: {e.reason}"}))
except Exception as e:
    print(json.dumps({"error": str(e)}))
