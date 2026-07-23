# Cupcake — GRUB2 Theme

A modern, dark GRUB2 boot theme built around a hand-lettered script
logo, with a blush-pink accent used for the selected menu item and
timeout progress bar.

## What's in this folder
```
theme.txt              theme layout/config
background.png          1920x1080 dark background with the logo
logo_cream.png           standalone cream logo (unused by theme, kept as source)
logo_accent.png          standalone pink logo (unused by theme, kept as source)
select_*.png             9-slice pink pill used to highlight the selected entry
progress_bar_*.png       9-slice track for the countdown bar
progress_highlight_*.png 9-slice fill for the countdown bar
preview.png              a rendered mockup of what the menu looks like
```

## Install (Debian/Ubuntu, Fedora, Arch — any GRUB2 system)

1. Copy the whole folder to GRUB's theme directory as root:
   ```bash
   sudo mkdir -p /boot/grub/themes/cupcake
   sudo cp -r ./* /boot/grub/themes/cupcake/
   ```
   (On Fedora/RHEL the path is `/boot/grub2/themes/cupcake`.)

2. Point GRUB at the theme. Edit `/etc/default/grub` and add or edit:
   ```
   GRUB_THEME="/boot/grub/themes/cupcake/theme.txt"
   GRUB_GFXMODE=1920x1080
   GRUB_GFXPAYLOAD_LINUX=keep
   ```

3. Regenerate the GRUB config:
   ```bash
   sudo update-grub                      # Debian/Ubuntu
   # or
   sudo grub2-mkconfig -o /boot/grub2/grub.cfg   # Fedora/RHEL
   ```

4. Reboot to see it.

## About the font

`theme.txt` references **DejaVu Sans** (Regular/Bold), which is the
font GRUB ships with by default (`unicode.pf2` is DejaVu-based), so on
most distros this works with no extra step.

If your GRUB build doesn't already carry DejaVu, generate a `.pf2`
file yourself and reference it in `theme.txt` instead of the font name:

```bash
grub-mkfont -o dejavu-sans-16.pf2 -s 16 /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
grub-mkfont -o dejavu-sans-bold-16.pf2 -s 16 /usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf
```
Then in `theme.txt`, replace e.g. `item_font = "DejaVu Sans Regular 16"`
with the literal font name embedded in that .pf2 (same string works —
grub-mkfont keeps the family/style name from the source TTF).

## Other resolutions

The background is rendered at 1920x1080. If your display uses a
different native resolution, re-export `background.png` at that size
(the boot menu and progress bar positions in `theme.txt` are already
percentage-based, so they'll reflow automatically — only the
background artwork itself is a fixed-size image).

## Troubleshooting

### The menu / pill / progress bar look oversized or the logo is cropped
This almost always means GRUB is rendering at a **lower resolution than
your monitor's native one** — the theme's fixed-pixel elements (item
height, font size, corner radius) then take up a much bigger share of
the screen than intended, and `background.png` gets scaled down and
cropped instead of shown at 1:1.

Fix it by pinning GRUB to your real resolution:

1. Reboot, and at the GRUB menu press `c` for a command line.
2. Run `videoinfo` — it lists the resolutions your GPU/monitor actually
   support in GRUB (e.g. `1920x1080x32`).
3. Boot normally, then edit `/etc/default/grub`:
   ```
   GRUB_GFXMODE=1920x1080x32       # use a mode videoinfo actually listed
   GRUB_GFXPAYLOAD_LINUX=keep
   ```
4. Regenerate the config and reboot:
   ```bash
   sudo update-grub                              # Debian/Ubuntu
   sudo grub2-mkconfig -o /boot/grub2/grub.cfg   # Fedora/RHEL/Arch (grub-mkconfig)
   ```

This zip's `theme.txt` now uses smaller item/pill/progress-bar sizes
than the first version, so even if GRUB falls back to a lower
resolution, things should look proportionate rather than blown up.

### Black screen for ~1-2 seconds right after pressing Enter
This is the handoff between GRUB's own graphics mode and the kernel/
KMS driver reinitializing the display — it's normal on most systems
and not something the theme file controls. It's usually shortest when
GRUB's resolution matches what the kernel switches to:

- Make sure `GRUB_GFXPAYLOAD_LINUX=keep` is set (above) — this tells
  the kernel to keep using GRUB's video mode instead of renegotiating
  one, which is the main thing that shortens or removes the blank gap.
- If you want the gap to *look* intentional instead of a bare black
  flash, install Plymouth and enable a boot splash so something is
  drawn during that window:
  ```bash
  sudo apt install plymouth plymouth-themes   # Debian/Ubuntu
  sudo plymouth-set-default-theme -R bgrt     # or any installed theme
  ```
  then add `splash` to `GRUB_CMDLINE_LINUX_DEFAULT` in `/etc/default/grub`
  and re-run `update-grub`.
- On dual-GPU or NVIDIA proprietary-driver systems this gap is often
  unavoidable regardless of theme/Plymouth settings.

## Customizing

- **Accent color** — swap the blush pink (`#f2a6c0`) used in the
  selection pill / progress bar for anything else by regenerating
  `select_*.png` and `progress_highlight_*.png` with a different fill.
- **Menu position** — edit the `left`/`top`/`width`/`height` percentages
  in the `boot_menu` block of `theme.txt`.
- **Logo** — `background.png` already has the logo baked in (GRUB
  themes work best with the logo as part of the background rather than
  a separate floating image element).
