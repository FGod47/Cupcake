import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "theme"

Rectangle {
    id: seg
    property var options: []
    property string current: options.length > 0 ? options[0] : ""
    signal selected(string value)
    color: Qt.rgba(0, 0, 0, 0.28)
    radius: 8
    height: 30
    width: row.implicitWidth + 4
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 1
        Repeater {
            model: seg.options
            delegate: Rectangle {
                required property string modelData
                property bool active: modelData === seg.current
                height: 26
                width: label.implicitWidth + 24
                radius: 6
                color: active ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.92) : "transparent"
                Text {
                    id: label
                    anchors.centerIn: parent
                    text: modelData
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: active ? Theme.colSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.5)
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { seg.current = modelData; seg.selected(modelData) }
                }
            }
        }
    }
}
