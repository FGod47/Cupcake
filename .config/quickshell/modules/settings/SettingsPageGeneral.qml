import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"

Item {
    id: root
    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        color: "black"

        Text {
            anchors.centerIn: parent
            text: "General Page"
            color: "white"
            font.pixelSize: 24
            font.family: Theme.defaultFontFamily
        }
    }
}
