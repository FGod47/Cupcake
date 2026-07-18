import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"

Rectangle {
    id: cardRoot
    property string title: ""
    property string description: ""
    property string icon: ""
    
    default property alias content: innerLayout.data

    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight + (cardHeader.visible ? cardHeader.height + 28 : 32)
    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
    radius: 12
    border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.08)
    border.width: 1
    clip: true

    RowLayout {
        id: cardHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 16
        visible: cardRoot.title !== ""
        spacing: 8

        Text {
            text: cardRoot.title
            color: Theme.colOnSurfaceVariant
            font.family: Theme.defaultFontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 0.8
            font.capitalization: Font.AllUppercase
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15) }
    }

    ColumnLayout {
        id: mainLayout
        anchors.top: cardHeader.visible ? cardHeader.bottom : parent.top
        anchors.topMargin: cardHeader.visible ? 12 : 16
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.bottomMargin: 16
        spacing: 0
        
        ColumnLayout {
            id: innerLayout
            Layout.fillWidth: true
            spacing: 0
        }
    }
}
