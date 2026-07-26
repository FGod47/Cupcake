import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"

Rectangle {
    default property alias content: cardCol.data
    property string sectionTitle: ""
    Layout.fillWidth: true
    implicitHeight: cardCol.implicitHeight + (cardHeader.visible ? cardHeader.height + 28 : 32)
    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
    radius: 20
    border.width: 0
    clip: true

    RowLayout {
        id: cardHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 16
        visible: sectionTitle !== ""
        spacing: 8

        Text {
            text: sectionTitle
            color: Theme.colOnSurfaceVariant
            font.family: Theme.defaultFontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 0.8
            font.capitalization: Font.AllUppercase
        }
    }

    ColumnLayout {
        id: cardCol
        anchors.top: cardHeader.visible ? cardHeader.bottom : parent.top
        anchors.topMargin: cardHeader.visible ? 12 : 16
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.bottomMargin: 16
        spacing: 0
    }
}
