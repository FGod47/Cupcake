import QtQuick
import QtQuick.Controls
import "theme"

Slider {
    id: control
    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 200
        implicitHeight: 6
        width: control.availableWidth
        height: implicitHeight
        radius: 3
        color: Theme.colOnSurface
        opacity: 0.15

        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            color: Theme.colOnSurface
            opacity: 0.85
            radius: 3
        }
    }
    
    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 16
        implicitHeight: 16
        radius: 8
        color: Theme.colOnSurface
        
        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
    }
}
