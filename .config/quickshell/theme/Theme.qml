pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: themeSingleton

    readonly property string homeDir: Quickshell.env("HOME")

    property bool globalTransparency: true
    
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




    // helper function to parse hex string into color with alpha
    function transparentize(hexStr, alpha) {
        var c = Qt.color(hexStr);
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }

    property color colBackground: Qt.rgba(Qt.color("#11140f").r, Qt.color("#11140f").g, Qt.color("#11140f").b, bgAlpha)
    property color colOnBackground: "#e1e4d9"
    property color colSurface: Qt.rgba(Qt.color("#11140f").r, Qt.color("#11140f").g, Qt.color("#11140f").b, bgAlpha)
    property color colSurfaceContainer: Qt.rgba(Qt.color("#1d211a").r, Qt.color("#1d211a").g, Qt.color("#1d211a").b, bgAlpha)
    property color colSurfaceContainerHigh: Qt.rgba(Qt.color("#282b24").r, Qt.color("#282b24").g, Qt.color("#282b24").b, bgAlpha)
    property color colOnSurface: "#e1e4d9"
    property color colOnSurfaceVariant: "#c3c8bb"
    property color colOutline: "#8d9286"
    property color colPrimary: "#a9d291"
    property color colOnPrimary: "#173807"
    property color colSecondary: "#bccbb0"
    property color colError: "#ffb4ab"
}
