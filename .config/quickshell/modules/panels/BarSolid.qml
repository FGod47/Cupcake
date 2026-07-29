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

    height: 34 // Make the overall window smaller
    color: "transparent"

    // The single combined solid bar
    Rectangle {
        id: solidBarBackground
        anchors.centerIn: parent
        width: 800 // Fixed smaller width for the bar
        height: 30 // Smaller height
        
        // Glassmorphism background (glass sheet)
        // Must use Theme.barOpacity to pass Hyprland's ignore_alpha threshold
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(0.1, 0.1, 0.1, Theme.barOpacity) }
            GradientStop { position: 0.5; color: Qt.rgba(0.15, 0.15, 0.15, Theme.barOpacity) }
            GradientStop { position: 1.0; color: Qt.rgba(0.1, 0.1, 0.1, Theme.barOpacity) }
        }
        radius: 15
        
        border.color: Qt.rgba(1, 1, 1, 0.2)
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

    // Drop shadow applied externally so the transparent background is correctly exported to Wayland for Hyprland blurls
    DropShadow {
        anchors.fill: solidBarBackground
        source: solidBarBackground
        color: Qt.rgba(0, 0, 0, 0.4)
        radius: 12
        samples: 25
        verticalOffset: 4
        transparentBorder: true
        z: -1
    }
}
