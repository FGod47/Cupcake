#!/usr/bin/env python3
import os
import glob
import subprocess
from pathlib import Path

HOME = Path.home()
LUTRIS_COVER = HOME / ".local/share/lutris/coverart"
LUTRIS_BANNER = HOME / ".local/share/lutris/banners"
APPS_DIR = HOME / ".local/share/applications"

ICON_DIRS = [
    HOME / ".local/share/icons/hicolor/128x128/apps",
    HOME / ".local/share/icons/hicolor/256x256/apps",
    HOME / ".local/share/icons/Papirus/48x48/apps",
    HOME / ".local/share/icons/Papirus/64x64/apps",
    HOME / ".local/share/icons/Papirus-Dark/48x48/apps",
    HOME / ".local/share/icons/Papirus-Dark/64x64/apps",
    HOME / ".local/share/icons"
]

for d in ICON_DIRS:
    d.mkdir(parents=True, exist_ok=True)

def sync_icons():
    desktop_files = glob.glob(str(APPS_DIR / "net.lutris.*.desktop")) + glob.glob(str(APPS_DIR / "lutris-*.desktop"))
    updated = False

    for df in desktop_files:
        icon_name = None
        with open(df, "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                if line.startswith("Icon="):
                    icon_name = line.strip().split("=", 1)[1]
                    break
        
        if not icon_name:
            continue

        slug = icon_name.replace("net.lutris.", "").replace("lutris_", "")
        target_128 = HOME / ".local/share/icons/hicolor/128x128/apps" / f"{icon_name}.png"
        
        sources = [
            LUTRIS_COVER / f"{slug}.jpg",
            LUTRIS_COVER / f"{slug}.png",
            LUTRIS_BANNER / f"{slug}.jpg",
            LUTRIS_BANNER / f"{slug}.png",
        ]
        
        source_img = None
        for s in sources:
            if s.exists():
                source_img = s
                break

        if source_img:
            for d in [HOME / ".local/share/icons/hicolor/256x256/apps", HOME / ".local/share/icons/hicolor/128x128/apps"]:
                out = d / f"{icon_name}.png"
                size = 256 if "256" in str(d) else 128
                ss_size = size * 2
                radius = ss_size // 2
                subprocess.run([
                    "magick", str(source_img),
                    "-background", "none",
                    "-resize", f"{ss_size}x{ss_size}^",
                    "-gravity", "center",
                    "-extent", f"{ss_size}x{ss_size}",
                    "(", "-size", f"{ss_size}x{ss_size}", "xc:none",
                    "-fill", "white", "-draw", f"circle {radius},{radius} {radius},1", ")",
                    "-alpha", "off", "-compose", "CopyOpacity", "-composite",
                    "-resize", f"{size}x{size}",
                    f"PNG32:{out}"
                ], check=False)

            for d in ICON_DIRS:
                dest = d / f"{icon_name}.png"
                if dest != target_128:
                    subprocess.run(["cp", "-f", str(target_128), str(dest)], check=False)
            
            updated = True

    if updated:
        subprocess.run(["gtk-update-icon-cache", "-f", str(HOME / ".local/share/icons/hicolor")], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["gtk-update-icon-cache", "-f", str(HOME / ".local/share/icons/Papirus")], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["gtk-update-icon-cache", "-f", str(HOME / ".local/share/icons/Papirus-Dark")], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

if __name__ == "__main__":
    sync_icons()
