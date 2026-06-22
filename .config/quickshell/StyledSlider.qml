import QtQuick
import QtQuick.Controls
import "theme"

Slider {
    id: control
    background: Item {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 200
        implicitHeight: 16
        width: control.availableWidth
        height: implicitHeight
        
        // Full Inactive Track (Continuous Pill)
        Rectangle {
            anchors.fill: parent
            color: Theme.colOnSurface
            opacity: 0.15
            radius: height / 2
        }
        
        // Active Track (clipped straight at the thumb boundary)
        Item {
            width: control.visualPosition * parent.width
            height: parent.height
            clip: true
            
            Rectangle {
                width: control.availableWidth
                height: parent.height
                color: Theme.colPrimary
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

        // Solid Blue Circle (creates the rounded edge around the thumb)
        Rectangle {
            anchors.centerIn: parent
            width: 16
            height: 16
            radius: 8
            color: Theme.colPrimary
        }

        // Inner Thumb Dot
        Rectangle {
            anchors.centerIn: parent
            width: (control.pressed || control.hovered) ? 10 : 6
            height: (control.pressed || control.hovered) ? 10 : 6
            radius: width / 2
            color: "#ffffff"
            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        }
    }
}
