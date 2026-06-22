pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: themeSingleton

    property bool globalTransparency: true
    
    Process {
        command: ["cat", "/home/zero/.config/cupcake/.transparency"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "false") {
                    themeSingleton.globalTransparency = false;
                }
            }
        }
    }
    
    property real bgAlpha: globalTransparency ? 0.85 : 1.0

    // Fonts
    property string defaultFontFamily: "Inter"
    property string monoFontFamily: "JetBrainsMono Nerd Font Propo"
    property real defaultFontScale: 1.0
    property real monoFontScale: 1.0

    Process {
        command: ["cat", "/home/zero/.config/cupcake/.font_default"]
        running: true
        stdout: StdioCollector { onStreamFinished: { if (text.trim() !== "") themeSingleton.defaultFontFamily = text.trim(); } }
    }
    Process {
        command: ["cat", "/home/zero/.config/cupcake/.font_mono"]
        running: true
        stdout: StdioCollector { onStreamFinished: { if (text.trim() !== "") themeSingleton.monoFontFamily = text.trim(); } }
    }
    Process {
        command: ["cat", "/home/zero/.config/cupcake/.font_default_scale"]
        running: true
        stdout: StdioCollector { onStreamFinished: { let v = parseFloat(text.trim()); if (!isNaN(v)) themeSingleton.defaultFontScale = v; } }
    }
    Process {
        command: ["cat", "/home/zero/.config/cupcake/.font_mono_scale"]
        running: true
        stdout: StdioCollector { onStreamFinished: { let v = parseFloat(text.trim()); if (!isNaN(v)) themeSingleton.monoFontScale = v; } }
    }

    // helper function to parse hex string into color with alpha
    function transparentize(hexStr, alpha) {
        var c = Qt.color(hexStr);
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }

    property color colBackground: transparentize("#11140f", bgAlpha)
    property color colOnBackground: "#e1e4d9"
    property color colSurface: transparentize("#11140f", bgAlpha)
    property color colSurfaceContainer: transparentize("#1d211a", bgAlpha)
    property color colSurfaceContainerHigh: transparentize("#282b24", bgAlpha)
    property color colOnSurface: "#e1e4d9"
    property color colOnSurfaceVariant: "#c3c8bb"
    property color colOutline: "#8d9286"
    property color colPrimary: "#a9d291"
    property color colOnPrimary: "#173807"
    property color colSecondary: "#bccbb0"
    property color colError: "#ffb4ab"
}
