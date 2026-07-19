import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../../theme"

Switch {
    id: customSwitch
    property real scale: 1.0
    implicitHeight: 20 * scale
    implicitWidth: 36 * scale
    hoverEnabled: true

    indicator: Item {
        implicitWidth: 36 * customSwitch.scale
        implicitHeight: 20 * customSwitch.scale
        
        // Modern Flat Track
        Rectangle {
            id: track
            anchors.fill: parent
            radius: height / 2
            
            color: customSwitch.checked ? Theme.colPrimary : Qt.rgba(255/255, 255/255, 255/255, 0.15)
            border.color: Qt.rgba(255/255, 255/255, 255/255, 0.05)
            border.width: 1 * customSwitch.scale
            Behavior on color { ColorAnimation { duration: 250 } }
        }

        // Thumb Container (larger to prevent shadow clipping)
        Item {
            id: thumbContainer
            width: 36 * customSwitch.scale
            height: 36 * customSwitch.scale
            y: -8 * customSwitch.scale
            x: (customSwitch.checked ? 8 : -8) * customSwitch.scale
            Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 2.5 } }
            
            scale: (customSwitch.pressed || customSwitch.down) ? 0.85 : 1.0
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 2.5 } }
            
            Item {
                id: thumbSrc
                anchors.fill: parent
                visible: false
                Rectangle { 
                    anchors.centerIn: parent
                    width: ((customSwitch.pressed || customSwitch.hovered) ? 24 : 14) * customSwitch.scale
                    height: 14 * customSwitch.scale; radius: height / 2
                    color: customSwitch.checked ? Theme.colOnPrimary : Qt.rgba(255/255, 255/255, 255/255, 0.9)
                    Behavior on color { ColorAnimation { duration: 250 } }
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 2.5 } }
                }
            }
            
            // Soft drop shadow for thumb depth
            DropShadow {
                anchors.fill: parent
                source: thumbSrc
                color: Qt.rgba(0, 0, 0, 0.35)
                horizontalOffset: 0
                verticalOffset: 2 * customSwitch.scale
                radius: 6 * customSwitch.scale
                samples: 13
            }
        }
    }
}
