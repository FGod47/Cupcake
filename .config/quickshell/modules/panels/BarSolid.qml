import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../../theme"

PanelWindow {
    id: bar
    anchors {
        top: true
        left: true
        right: true
    }
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 46

    height: 34 // Solid bar usually matches its internal height

    // The single combined solid bar
    Rectangle {
        id: solidBarBackground
        anchors.fill: parent // Make it perfectly flush with the edges
        
        // Solid dark premium background with rounding
        color: Qt.rgba(0.05, 0.05, 0.05, 0.85) // Dark translucent background
        radius: 0 // Solid bars typically don't have rounded corners if they are flush
        
        border.color: Qt.rgba(1, 1, 1, 0.05)
        border.width: 1

        // Container for future items
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12
            
            // Blank for now, as requested.
        }
    }
}
