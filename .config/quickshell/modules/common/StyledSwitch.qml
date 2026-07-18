import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../../theme"

Switch {
    id: customSwitch
    property real scale: 0.8
    implicitHeight: 26 * scale
    implicitWidth: 46 * scale

    background: Rectangle {
        width: parent.width
        height: parent.height
        radius: 13 * customSwitch.scale
        
        color: customSwitch.checked ? "transparent" : Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
        
        gradient: customSwitch.checked ? onGradient : null
        Gradient {
            id: onGradient
            GradientStop { position: 0.0; color: Theme.colPrimary }
            GradientStop { position: 1.0; color: Qt.lighter(Theme.colPrimary, 1.15) }
        }

        border.width: 1 * customSwitch.scale
        border.color: customSwitch.checked ? "transparent" : Qt.rgba(255/255, 255/255, 255/255, 0.04)

        Behavior on color { ColorAnimation { duration: 280 } }
    }

    indicator: Rectangle {
        width: 20 * customSwitch.scale
        height: 20 * customSwitch.scale
        radius: 10 * customSwitch.scale
        
        y: (customSwitch.implicitHeight - height) / 2
        
        x: customSwitch.checked 
            ? (customSwitch.implicitWidth - width - (3 * customSwitch.scale))
            : (3 * customSwitch.scale)

        color: "white"
        
        scale: (customSwitch.pressed || customSwitch.down) ? 0.9 : 1.0
        
        Behavior on x { NumberAnimation { duration: 340; easing.type: Easing.OutBack } }
        Behavior on scale { NumberAnimation { duration: 200 } }

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            color: Qt.rgba(0, 0, 0, 0.35)
            radius: 4 * customSwitch.scale
            samples: 9
            verticalOffset: 2 * customSwitch.scale
        }
    }
}
