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

    height: 46
    color: "transparent"

    // The single combined solid bar
    Rectangle {
        id: solidBarBackground
        anchors.centerIn: parent
        width: parent.width - 24 // Give it some outer margins (12px on each side)
        height: 34               // A standard bar height
        
        // Solid dark premium background with rounding
        color: Qt.rgba(0.05, 0.05, 0.05, 0.85) // Dark translucent background
        radius: 17 // Perfectly rounded edges
        
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
