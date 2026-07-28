pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: themeSingleton

    readonly property string homeDir: Quickshell.env("HOME")

    property bool globalTransparency: true
    
    property bool isDark: true
    
    Process {
        command: ["cat", themeSingleton.homeDir + "/.config/cupcake/.color_mode"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    themeSingleton.isDark = (text.trim() !== "light");
                }
            }
        }
    }

    FileView {
        path: themeSingleton.homeDir + "/.config/cupcake/.color_mode"
        watchChanges: true
        onFileChanged: {
            themeSingleton.isDark = (text.trim() !== "light");
        }
    }
    
    Process {
        command: ["cat", themeSingleton.homeDir + "/.config/cupcake/.transparency"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "false") {
                    themeSingleton.globalTransparency = false;
                }
            }
        }
    }

    property bool quickshellTransparency: true
    Process {
        command: ["cat", themeSingleton.homeDir + "/.config/cupcake/.bar_transparency"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "false") {
                    themeSingleton.quickshellTransparency = false;
                }
            }
        }
    }
    
    property real bgAlpha: quickshellTransparency ? 0.85 : 1.0

    // Fonts
    property string defaultFontFamily: "Inter"
    property string monoFontFamily: "JetBrainsMono Nerd Font Propo"
    property real defaultFontScale: 1.0
    property real monoFontScale: 1.0

    Process {
        command: ["cat", themeSingleton.homeDir + "/.config/cupcake/.font_default"]
        running: true
        stdout: StdioCollector { onStreamFinished: { if (text.trim() !== "") themeSingleton.defaultFontFamily = text.trim(); } }
    }
    Process {
        command: ["cat", themeSingleton.homeDir + "/.config/cupcake/.font_mono"]
        running: true
        stdout: StdioCollector { onStreamFinished: { if (text.trim() !== "") themeSingleton.monoFontFamily = text.trim(); } }
    }
    Process {
        command: ["cat", themeSingleton.homeDir + "/.config/cupcake/.font_default_scale"]
        running: true
        stdout: StdioCollector { onStreamFinished: { let v = parseFloat(text.trim()); if (!isNaN(v)) themeSingleton.defaultFontScale = v; } }
    }
    Process {
        command: ["cat", themeSingleton.homeDir + "/.config/cupcake/.font_mono_scale"]
        running: true
        stdout: StdioCollector { onStreamFinished: { let v = parseFloat(text.trim()); if (!isNaN(v)) themeSingleton.monoFontScale = v; } }
    }

    property int defaultFontSize: 14
    property int defaultFontWeight: 500

    Process {
        command: ["cat", themeSingleton.homeDir + "/.config/cupcake/.font_size"]
        running: true
        stdout: StdioCollector { onStreamFinished: { let v = parseInt(text.trim()); if (!isNaN(v)) themeSingleton.defaultFontSize = v; } }
    }
    Process {
        command: ["cat", themeSingleton.homeDir + "/.config/cupcake/.font_weight"]
        running: true
        stdout: StdioCollector { onStreamFinished: { let v = parseInt(text.trim()); if (!isNaN(v)) themeSingleton.defaultFontWeight = v; } }
    }

    // App Fonts
    property string appFontFamily: "Inter"
    property string appMonoFamily: "JetBrainsMono Nerd Font Propo"
    property real appMonoScale: 1.0
    property int appFontSize: 14
    property int appFontWeight: 500

    Process {
        command: ["cat", themeSingleton.homeDir + "/.config/cupcake/.app_font_default"]
        running: true
        stdout: StdioCollector { onStreamFinished: { if (text.trim() !== "") themeSingleton.appFontFamily = text.trim(); } }
    }
    Process {
        command: ["cat", themeSingleton.homeDir + "/.config/cupcake/.app_font_mono"]
        running: true
        stdout: StdioCollector { onStreamFinished: { if (text.trim() !== "") themeSingleton.appMonoFamily = text.trim(); } }
    }
    Process {
        command: ["cat", themeSingleton.homeDir + "/.config/cupcake/.app_font_mono_scale"]
        running: true
        stdout: StdioCollector { onStreamFinished: { let v = parseFloat(text.trim()); if (!isNaN(v)) themeSingleton.appMonoScale = v; } }
    }
    Process {
        command: ["cat", themeSingleton.homeDir + "/.config/cupcake/.app_font_size"]
        running: true
        stdout: StdioCollector { onStreamFinished: { let v = parseInt(text.trim()); if (!isNaN(v)) themeSingleton.appFontSize = v; } }
    }
    Process {
        command: ["cat", themeSingleton.homeDir + "/.config/cupcake/.app_font_weight"]
        running: true
        stdout: StdioCollector { onStreamFinished: { let v = parseInt(text.trim()); if (!isNaN(v)) themeSingleton.appFontWeight = v; } }
    }

    property real sliderThickness: 2.0
    Process {
        command: ["cat", themeSingleton.homeDir + "/.config/cupcake/.slider_thickness"]
        running: true
        stdout: StdioCollector { onStreamFinished: { let v = parseFloat(text.trim()); if (!isNaN(v)) themeSingleton.sliderThickness = v; } }
    }

    property bool showSliderThumb: true
    Process {
        command: ["cat", themeSingleton.homeDir + "/.config/cupcake/.show_slider_thumb"]
        running: true
        stdout: StdioCollector { onStreamFinished: { if (text.trim() === "false") themeSingleton.showSliderThumb = false; } }
    }

    property bool liquidify: true
    Process {
        command: ["cat", themeSingleton.homeDir + "/.config/cupcake/.liquidify"]
        running: true
        stdout: StdioCollector { onStreamFinished: { if (text.trim() === "false") themeSingleton.liquidify = false; } }
    }

    property bool showCardBackground: true
    Process {
        command: ["cat", themeSingleton.homeDir + "/.config/cupcake/.show_card_background"]
        running: true
        stdout: StdioCollector { onStreamFinished: { if (text.trim() === "false") themeSingleton.showCardBackground = false; } }
    }

    property string appLauncherStyle: "Hover"
    Process {
        command: ["cat", themeSingleton.homeDir + "/.config/cupcake/.applauncher_style"]
        running: true
        stdout: StdioCollector { onStreamFinished: { let s = text.trim(); if (s !== "") themeSingleton.appLauncherStyle = s; } }
    }

    property string wallpaperSwitcherStyle: "Carousel"
    Process {
        command: ["cat", themeSingleton.homeDir + "/.config/cupcake/.wallpaper_switcher_style"]
        running: true
        stdout: StdioCollector { onStreamFinished: { let s = text.trim(); if (s !== "") themeSingleton.wallpaperSwitcherStyle = s; } }
    }


    property bool showDividers: true
    Process {
        command: ["cat", themeSingleton.homeDir + "/.config/cupcake/.show_dividers"]
        running: true
        stdout: StdioCollector { onStreamFinished: { if (text.trim() === "false") themeSingleton.showDividers = false; } }
    }

    property real rowSpacing: 4.0
    Process {
        command: ["cat", themeSingleton.homeDir + "/.config/cupcake/.row_spacing"]
        running: true
        stdout: StdioCollector { onStreamFinished: { let v = parseFloat(text.trim()); if (!isNaN(v)) themeSingleton.rowSpacing = v; } }
    }




    // helper function to parse hex string into color with alpha
    function transparentize(hexStr, alpha) {
        var c = Qt.color(hexStr);
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }

    function readColorsImmediately() {
        var text = colorsFileView.text();
        if (text && text.trim().length > 0) {
            try {
                var c = JSON.parse(text.trim());
                if (c.background) themeSingleton.colBackground = themeSingleton.transparentize(c.background, themeSingleton.bgAlpha);
                if (c.onBackground) themeSingleton.colOnBackground = c.onBackground;
                if (c.surfaceContainerHighest) themeSingleton.colSurface = themeSingleton.transparentize(c.surfaceContainerHighest, themeSingleton.bgAlpha);
                if (c.surfaceContainer) themeSingleton.colSurfaceContainer = themeSingleton.transparentize(c.surfaceContainer, themeSingleton.bgAlpha);
                if (c.surfaceContainerHigh) themeSingleton.colSurfaceContainerHigh = themeSingleton.transparentize(c.surfaceContainerHigh, themeSingleton.bgAlpha);
                if (c.surfaceVariant) themeSingleton.colSurfaceVariant = themeSingleton.transparentize(c.surfaceVariant, themeSingleton.bgAlpha);
                if (c.onSurface) themeSingleton.colOnSurface = c.onSurface;
                if (c.onSurfaceVariant) themeSingleton.colOnSurfaceVariant = c.onSurfaceVariant;
                if (c.outline) themeSingleton.colOutline = c.outline;
                if (c.primary) themeSingleton.colPrimary = c.primary;
                if (c.onPrimary) themeSingleton.colOnPrimary = c.onPrimary;
                if (c.secondary) themeSingleton.colSecondary = c.secondary;
                if (c.error) themeSingleton.colError = c.error;
            } catch (e) {}
        }
    }

    Component.onCompleted: {
        readColorsImmediately();
    }

    FileView {
        id: colorsFileView
        path: themeSingleton.homeDir + "/.cache/quickshell_colors.json"
        watchChanges: true
        onFileChanged: {
            reload();
        }
        onTextChanged: {
            themeSingleton.readColorsImmediately();
        }
        onLoadedChanged: {
            themeSingleton.readColorsImmediately();
        }
    }

    property color colBackground: transparentize("#15121c", bgAlpha)
    property color colOnBackground: "#e8dfee"
    property color colSurface: transparentize("#37333e", bgAlpha)
    property color colSurfaceContainer: transparentize("#221e28", bgAlpha)
    property color colSurfaceContainerHigh: transparentize("#2c2833", bgAlpha)
    property color colSurfaceVariant: transparentize("#4a4550", bgAlpha)
    property color colOnSurface: "#e8dfee"
    property color colOnSurfaceVariant: "#cbc4d2"
    property color colOutline: "#958e9b"
    property color colPrimary: "#d4bbff"
    property color colOnPrimary: "#40008c"
    property color colSecondary: "#d7bde4"
    property color colError: "#ffb4ab"
}
