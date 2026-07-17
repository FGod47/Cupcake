import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"

Rectangle {
    id: tog
    property bool checked: false
    signal toggled(bool val)
    width: 44; height: 24; radius: 12
    color: checked ? Theme.colPrimary : Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.08)
    Behavior on color { ColorAnimation { duration: 150 } }
    Rectangle {
        width: 18; height: 18; radius: 9
        anchors.verticalCenter: parent.verticalCenter
        x: tog.checked ? parent.width - width - 3 : 3
        color: "white"
        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        layer.enabled: true
        layer.effect: null
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: { tog.checked = !tog.checked; tog.toggled(tog.checked) }
    }
}
