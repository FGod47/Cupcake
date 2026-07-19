import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import "../../theme"

Slider {
    id: control
    hoverEnabled: true

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 200
        implicitHeight: 20
        width: control.availableWidth
        height: implicitHeight
        radius: height / 2
        
        color: Qt.rgba(255/255, 255/255, 255/255, 0.04)
        border.color: Qt.rgba(255/255, 255/255, 255/255, 0.1)
        border.width: 1
        
        // Unfilled track
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 10
            height: 4
            radius: 2
            color: Qt.rgba(255/255, 255/255, 255/255, 0.15)
        }
        
        // Filled track
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10
            width: control.visualPosition * (parent.width - 20)
            height: 4
            radius: 2
            color: Theme.colPrimary
            
            Behavior on width {
                enabled: !control.pressed
                NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 2.0 }
            }
        }
    }

    handle: Item {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 20
        implicitHeight: 20
        visible: Theme.showSliderThumb
        
        Behavior on x {
            enabled: !control.pressed
            NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 2.0 }
        }
        
        // Dynamic expanding thumb
        Rectangle {
            anchors.centerIn: parent
            width: (control.pressed || control.hovered) ? 32 : 12
            height: (control.pressed || control.hovered) ? 16 : 12
            radius: height / 2
            color: Theme.colPrimary
            
            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 2.5 } }
            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 2.5 } }
            
            // Subtle drop shadow
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                color: Qt.rgba(0, 0, 0, 0.3)
                radius: 4
                verticalOffset: 1
                samples: 9
            }
            
            // Value text inside thumb
            Text {
                anchors.centerIn: parent
                text: Math.round(control.value * 100)
                color: Theme.colOnPrimary
                font.family: Theme.defaultFontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
                opacity: (control.pressed || control.hovered) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }
    }
}
