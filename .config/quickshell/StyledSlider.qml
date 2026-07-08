import QtQuick
import QtQuick.Controls
import "theme"

Slider {
    id: control
    hoverEnabled: true

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 200
        implicitHeight: 2
        width: control.availableWidth
        height: implicitHeight
        radius: height / 2
        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.15)

        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            color: Theme.colPrimary
            radius: height / 2
        }
    }
    
    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: control.pressed ? 16 : (control.hovered ? 14 : 10)
        implicitHeight: control.pressed ? 16 : (control.hovered ? 14 : 10)
        radius: width / 2
        color: Theme.colPrimary
        
        Behavior on implicitWidth { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }
        Behavior on implicitHeight { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }
    }
}
