import QtQuick
import QtQuick.Controls
import "theme"

Switch {
    id: customSwitch
    property real scale: 0.8
    implicitHeight: 32 * scale
    implicitWidth: 52 * scale

    // Custom track styling
    background: Rectangle {
        width: parent.width
        height: parent.height
        radius: 9999
        color: customSwitch.checked ? Theme.colPrimary : Theme.colSurfaceContainerHigh
        border.width: 2 * customSwitch.scale
        border.color: customSwitch.checked ? Theme.colPrimary : Theme.colOutline

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    // Custom thumb styling
    indicator: Rectangle {
        width: (customSwitch.pressed || customSwitch.down) ? (28 * customSwitch.scale) : (24 * customSwitch.scale)
        height: (customSwitch.pressed || customSwitch.down) ? (28 * customSwitch.scale) : (24 * customSwitch.scale)
        radius: 9999
        color: customSwitch.checked ? Theme.colOnPrimary : Theme.colOutline
        
        // Vertically center it
        y: (customSwitch.implicitHeight - height) / 2
        
        // Calculate X based on state
        // Gap of 4 * scale from the edge
        x: customSwitch.checked 
            ? (customSwitch.implicitWidth - width - (4 * customSwitch.scale))
            : (4 * customSwitch.scale)

        Behavior on x {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
        Behavior on width {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
