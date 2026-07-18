import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../../theme"

Rectangle {
    id: tog
    property bool checked: false
    signal toggled(bool val)

    width: 46; height: 26; radius: 13
    
    color: checked ? "transparent" : Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
    
    gradient: checked ? onGradient : null
    Gradient {
        id: onGradient
        GradientStop { position: 0.0; color: Theme.colPrimary }
        GradientStop { position: 1.0; color: Qt.lighter(Theme.colPrimary, 1.15) }
    }
    
    border.width: 1
    border.color: checked ? "transparent" : Qt.rgba(255/255, 255/255, 255/255, 0.04)

    Behavior on color { ColorAnimation { duration: 280 } }

    Rectangle {
        id: thumb
        width: 20; height: 20; radius: 10
        anchors.verticalCenter: parent.verticalCenter
        x: tog.checked ? parent.width - width - 3 : 3
        color: "white"
        
        scale: ma.pressed ? 0.9 : 1.0
        
        Behavior on x { NumberAnimation { duration: 340; easing.type: Easing.OutBack } }
        Behavior on scale { NumberAnimation { duration: 200 } }

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            color: Qt.rgba(0, 0, 0, 0.35)
            radius: 4
            samples: 9
            verticalOffset: 2
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: { tog.checked = !tog.checked; tog.toggled(tog.checked) }
    }
}
