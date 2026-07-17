import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"

Rectangle {
    default property alias rowContent: innerLayout.data
    Layout.fillWidth: true
    implicitHeight: innerLayout.implicitHeight + 20
    color: "transparent"
    radius: 8

    property bool hoverable: false
    property bool hovered: hoverArea.containsMouse
    Behavior on color { ColorAnimation { duration: 120 } }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: parent.hoverable
    }

    RowLayout {
        id: innerLayout
        anchors.fill: parent
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 12
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
        opacity: 0.6
    }
}
