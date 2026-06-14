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

    // helper function to parse hex string into color with alpha
    function transparentize(hexStr, alpha) {
        var c = Qt.color(hexStr);
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }

    property color colBackground: transparentize("{{colors.background.default.hex}}", bgAlpha)
    property color colOnBackground: "{{colors.on_background.default.hex}}"
    property color colSurface: transparentize("{{colors.surface.default.hex}}", bgAlpha)
    property color colSurfaceContainer: transparentize("{{colors.surface_container.default.hex}}", bgAlpha)
    property color colSurfaceContainerHigh: transparentize("{{colors.surface_container_high.default.hex}}", bgAlpha)
    property color colOnSurface: "{{colors.on_surface.default.hex}}"
    property color colOnSurfaceVariant: "{{colors.on_surface_variant.default.hex}}"
    property color colOutline: "{{colors.outline.default.hex}}"
    property color colPrimary: "{{colors.primary.default.hex}}"
    property color colOnPrimary: "{{colors.on_primary.default.hex}}"
    property color colSecondary: "{{colors.secondary.default.hex}}"
    property color colError: "{{colors.error.default.hex}}"
}
