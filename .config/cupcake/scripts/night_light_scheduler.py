#!/usr/bin/env python3
import os
import sys
import json
import time
import datetime
import subprocess
import argparse
import fcntl

CONFIG_DIR = os.path.expanduser("~/.config/cupcake")
STATE_FILE = os.path.join(CONFIG_DIR, "nightlight.json")
LOCK_FILE = os.path.join(CONFIG_DIR, "nightlight.lock")

DEFAULT_STATE = {
    "enabled": False,
    "temperature": 3400,
    "schedule": "manual",
    "customStart": "20:00",
    "customEnd": "06:00"
}

def load_state():
    if not os.path.exists(STATE_FILE):
        return DEFAULT_STATE.copy()
    try:
        with open(STATE_FILE, "r") as f:
            return {**DEFAULT_STATE, **json.load(f)}
    except:
        return DEFAULT_STATE.copy()

def save_state(state):
    os.makedirs(CONFIG_DIR, exist_ok=True)
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=4)

def update_state(args):
    state = load_state()
    if args.enabled is not None:
        state["enabled"] = (args.enabled.lower() == 'true')
    if args.temperature is not None:
        state["temperature"] = int(args.temperature)
    if args.schedule is not None:
        state["schedule"] = args.schedule
    if args.custom_start is not None:
        state["customStart"] = args.custom_start
    if args.custom_end is not None:
        state["customEnd"] = args.custom_end
    save_state(state)
    print("State updated.")

def is_night_time(state):
    schedule = state["schedule"]
    if schedule == "manual":
        return True
    
    now = datetime.datetime.now().time()
    
    if schedule == "auto":
        # Hardcode typical sunset/sunrise times
        start_time = datetime.time(19, 0)
        end_time = datetime.time(7, 0)
    else: # custom
        try:
            h, m = map(int, state["customStart"].split(':'))
            start_time = datetime.time(h, m)
            h, m = map(int, state["customEnd"].split(':'))
            end_time = datetime.time(h, m)
        except:
            return False

    if start_time < end_time:
        return start_time <= now <= end_time
    else:
        return now >= start_time or now <= end_time

def run_daemon():
    # Ensure only one daemon is running
    lock = open(LOCK_FILE, 'w')
    try:
        fcntl.lockf(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except IOError:
        print("Daemon is already running.")
        sys.exit(1)

    last_applied = None

    while True:
        state = load_state()
        should_be_on = state["enabled"] and is_night_time(state)
        temp = state["temperature"]
        
        current_status = (should_be_on, temp)
        
        if current_status != last_applied:
            subprocess.run(["pkill", "-x", "hyprsunset"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if should_be_on:
                subprocess.Popen(["hyprsunset", "-t", str(temp)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            last_applied = current_status
            
        time.sleep(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Night Light Scheduler for Cupcake")
    parser.add_argument("--daemon", action="store_true", help="Run in background as scheduler daemon")
    parser.add_argument("--enabled", type=str, help="true/false")
    parser.add_argument("--temperature", type=int, help="Temperature in Kelvin")
    parser.add_argument("--schedule", type=str, help="manual, auto, or custom")
    parser.add_argument("--custom-start", type=str, help="HH:MM")
    parser.add_argument("--custom-end", type=str, help="HH:MM")
    
    args = parser.parse_args()
    
    if args.daemon:
        run_daemon()
    else:
        update_state(args)
