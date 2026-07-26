import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"

Rectangle {
    property string icon: ""
    property color iconColor: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.6)
    property color bgColor: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
    width: 32; height: 32; radius: 10
    color: bgColor
    Text {
        anchors.centerIn: parent
        text: parent.icon
        font.family: "tabler-icons"
        font.pixelSize: 16
        color: parent.iconColor
    }
}
