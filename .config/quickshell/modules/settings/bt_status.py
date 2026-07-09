#!/usr/bin/env python3
import subprocess
import json

def get_bt_status():
    try:
        # Check power status
        power_out = subprocess.check_output(["bluetoothctl", "show"], text=True)
        powered = "Powered: yes" in power_out
        
        if not powered:
            return {"powered": False, "devices": []}
            
        devices = []
        dev_out = subprocess.check_output(["bluetoothctl", "devices"], text=True)
        for line in dev_out.splitlines():
            if line.startswith("Device"):
                parts = line.split(" ", 2)
                if len(parts) == 3:
                    mac = parts[1]
                    name = parts[2].strip()
                    
                    try:
                        info_out = subprocess.check_output(["bluetoothctl", "info", mac], stderr=subprocess.STDOUT, text=True)
                        paired = "Paired: yes" in info_out
                        connected = "Connected: yes" in info_out
                        
                        devices.append({
                            "mac": mac,
                            "name": name,
                            "paired": paired,
                            "connected": connected
                        })
                    except subprocess.CalledProcessError:
                        # Device info failed (might be out of range now)
                        pass
                        
        return {"powered": True, "devices": devices}
        
    except Exception as e:
        return {"powered": False, "devices": []}

if __name__ == "__main__":
    print(json.dumps(get_bt_status()))
