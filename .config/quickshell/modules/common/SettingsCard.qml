import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"

Rectangle {
    id: cardRoot
    property string title: ""
    property string description: ""
    property string icon: ""
    
    // Colors
    property color surfaceColor
    property color outlineColor
    property color primaryColor
    property color onSurfaceColor
    
    default property alias content: innerLayout.data

    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight + 40
    color: surfaceColor
    radius: 16
    border.width: 0

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 20
        anchors.bottomMargin: 20
        spacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            visible: cardRoot.title !== "" || cardRoot.description !== ""
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                visible: cardRoot.title !== ""
                spacing: 12
                
                Text { 
                    visible: cardRoot.icon !== ""
                    text: cardRoot.icon
                    color: Theme.colOnSurfaceVariant
                    font.weight: Theme.defaultFontWeight; font.pixelSize: 14
                    font.family: Theme.monoFontFamily 
                }
                Text { 
                    text: cardRoot.title
                    color: Theme.colOnSurface
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 11
                    font.weight: 500
                    font.letterSpacing: 0.4
                    opacity: 0.45
                    Layout.fillWidth: true 
                }
            }
            
            Text {
                visible: cardRoot.description !== ""
                text: cardRoot.description
                color: Theme.colOnSurfaceVariant
                font.family: Theme.defaultFontFamily
                font.weight: Theme.defaultFontWeight; font.pixelSize: 12
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

        ColumnLayout {
            id: innerLayout
            Layout.fillWidth: true
            spacing: 16
        }

        Item { Layout.fillHeight: true; Layout.minimumHeight: 1 }
    }
    
    // Removed the dynamic bubble backgrounds to match the new flat liquid UI style
}
