import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Widgets
import Quickshell
import "../../../theme"

Row {
    id: powerRow
    spacing: 8
    
    property color fg: Theme.colOnSurface
    property string fontName: "JetBrainsMono Nerd Font"

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "•"
        font.family: Theme.defaultFontFamily
        font.pixelSize: 15
        font.weight: Theme.defaultFontWeight
        color: Qt.rgba(fg.r, fg.g, fg.b, 0.4)
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "\uf011"
        font.family: fontName
        font.pixelSize: 15
        color: powerMa.containsMouse ? Theme.colError : fg
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: powerMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Quickshell.execDetached(["hyprctl", "dispatch", "exec", "wlogout"])
        }
    }
}
