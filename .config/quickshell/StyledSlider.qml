import QtQuick
import QtQuick.Controls
import "theme"

Slider {
    id: control
    background: Item {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 200
        implicitHeight: 4
        width: control.availableWidth
        height: implicitHeight
        
        // Full Inactive Track
        Rectangle {
            anchors.fill: parent
            color: Theme.colOnSurface
            opacity: 0.15
            radius: height / 2
        }
        
        // Active Track
        Item {
            width: control.visualPosition * parent.width
            height: parent.height
            clip: true
            
            Rectangle {
                width: control.availableWidth
                height: parent.height
                color: Theme.colOnSurface
                opacity: 0.7
                radius: parent.height / 2
            }
        }
    }
    handle: Item {
        // Perfectly center the thumb on the boundary
        x: control.leftPadding + control.visualPosition * control.availableWidth - width / 2
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 16
        implicitHeight: 16

        // Solid Circle Thumb
        Rectangle {
            anchors.centerIn: parent
            width: (control.pressed || control.hovered) ? 18 : 14
            height: (control.pressed || control.hovered) ? 18 : 14
            radius: width / 2
            color: Theme.colOnSurface
            
            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
    }
}
