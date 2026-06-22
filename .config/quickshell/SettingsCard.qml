import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "theme"

Rectangle {
    id: cardRoot
    property string title: ""
    property string icon: ""
    
    // Colors
    property color surfaceColor
    property color outlineColor
    property color primaryColor
    property color onSurfaceColor
    
    default property alias content: innerLayout.data

    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight + 40
    color: "transparent"
    radius: 0
    border.width: 0

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 14
        anchors.bottomMargin: 14
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            visible: cardRoot.title !== ""
            spacing: 12
            
            Text { 
                visible: cardRoot.icon !== ""
                text: cardRoot.icon
                color: Theme.colOnSurfaceVariant
                font.pixelSize: 18
                font.family: "JetBrainsMono Nerd Font Propo" 
            }
            Text { 
                text: cardRoot.title
                color: onSurfaceColor
                font.family: "Inter"
                font.pixelSize: 18
                font.bold: true
                Layout.fillWidth: true 
            }
        }

        ColumnLayout {
            id: innerLayout
            Layout.fillWidth: true
            spacing: 16
        }

        Item { Layout.fillHeight: true; Layout.minimumHeight: 1 }

    }
}
