<div align="center">
  <img src="Source/assets/cupcake-word-light.svg" alt="Cupcake Shell" width="400" />
  
  <p><b>A masterfully crafted, high-performance QML Wayland Shell</b></p>
  
  [![Made with QML](https://img.shields.io/badge/Built_with-QML-pink.svg)](https://doc.qt.io/qt-6/qtqml-index.html)
  [![Window System](https://img.shields.io/badge/Wayland-Native-blue.svg)](https://wayland.freedesktop.org/)
</div>

<br/>

## ✨ Introduction

**Cupcake Shell** is a meticulously engineered, purely declarative Wayland desktop shell written entirely in QML (powered by Quickshell). It was built from the ground up to prioritize bleeding-edge fluidity, semantic theming, and an unapologetically premium user experience.

Unlike rigid, traditional shells, Cupcake feels alive. It achieves this through bespoke mathematical animations, a dynamic Material Design 3 engine, and a completely modular component architecture.

---

## 🎨 Signature Features

### 💧 The "Liquid Jelly" Engine
Physics-based springs are a thing of the past. Cupcake pioneers a unique **liquid jelly animation system**, built on aggressively tuned `NumberAnimation` and `Easing.OutElastic` properties.
- Toggleable liquid interactions that wobble, stretch, and snap into place organically.
- Seamless multi-stage expansion states (Hover & Hug launcher styles).

### 🖌️ Live Dynamic Theming
Cupcake features a state-of-the-art QML Singleton (`Theme.qml`) that acts as the nervous system for the entire shell's aesthetics.
- Instantly reacts to dotfile state changes (`~/.config/cupcake/`).
- Dynamically parses and injects **Material Design 3** palettes across every UI component on the fly.
- Global, real-time transparency (`.bar_transparency`) and color mode (`.color_mode`) adjustments.

### 🚀 Complete Boot-to-Desktop Immersion
Cupcake doesn't just skin your desktop; it owns the entire boot experience.
- Custom Plymouth Boot animations.
- A sleek, hyper-minimalist GRUB theme designed to match the Cupcake aesthetic flawlessly.

---

## 🏗️ Architecture

Cupcake Shell bypasses heavy, web-based rendering engines in favor of QML's highly optimized Qt Scene Graph.
- **Wayland Native**: Interfaces directly with Wayland compositors using `PanelWindow` and `WlrLayershell` for native, artifact-free overlay rendering.
- **Modular Components**: Built entirely around a reusable `common/` UI library (Segmented Controls, NToggles, Styled Sliders) ensuring visual consistency and perfectly synchronized animations.
- **Dependency**: Built on top of [Quickshell](https://git.outfoxxed.me/outfoxxed/quickshell).

---

## 🛠️ Installation

Cupcake comes with an automated installation script that handles dependencies, fonts, Quickshell setup, and boot animations.

```bash
git clone https://github.com/your-username/Cupcake.git ~/Cupcake
cd ~/Cupcake
chmod +x install.sh
./install.sh
```

---

<div align="center">
  <p><i>Crafted with precision. Animated with soul.</i></p>
</div>
