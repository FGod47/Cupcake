import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../../theme"

Switch {
    id: customSwitch
    property real scale: 1.0
    implicitHeight: 24 * scale
    implicitWidth: 44 * scale
    hoverEnabled: true

    indicator: Item {
        implicitWidth: 44 * customSwitch.scale
        implicitHeight: 24 * customSwitch.scale
        
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
            width: 44 * customSwitch.scale
            height: 44 * customSwitch.scale
            y: -10 * customSwitch.scale
            x: (customSwitch.checked ? 10 : -10) * customSwitch.scale
            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            
            scale: (customSwitch.pressed || customSwitch.down) ? 0.85 : 1.0
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            
            Item {
                id: thumbSrc
                anchors.fill: parent
                visible: false
                Rectangle { 
                    anchors.verticalCenter: parent.verticalCenter
                    property bool isExpanded: customSwitch.pressed || customSwitch.hovered
                    x: customSwitch.checked ? ((isExpanded ? 1 : 13) * customSwitch.scale) : (13 * customSwitch.scale)
                    width: (isExpanded ? 30 : 18) * customSwitch.scale
                    height: 18 * customSwitch.scale; radius: height / 2
                    color: customSwitch.checked ? Theme.colOnPrimary : Qt.rgba(255/255, 255/255, 255/255, 0.9)
                    Behavior on color { ColorAnimation { duration: 250 } }
                    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
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
