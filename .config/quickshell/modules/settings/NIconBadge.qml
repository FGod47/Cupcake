import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"

Rectangle {
    property string icon: ""
    property color iconColor: Theme.colOnSurfaceVariant
    property color bgColor: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
    width: 36; height: 36; radius: 10
    color: bgColor
    Text {
        anchors.centerIn: parent
        text: parent.icon
        font.family: "tabler-icons"
        font.pixelSize: 18
        color: parent.iconColor
    }
}
