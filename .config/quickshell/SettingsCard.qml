import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "theme"

Rectangle {
    id: cardRoot
    property string title: ""
    property string description: ""
    property string icon: ""
    
    // Colors
    property color surfaceColor: Theme.colSurfaceContainer
    property color outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
    property color primaryColor: Theme.colPrimary
    property color onSurfaceColor: Theme.colOnSurface
    
    default property alias content: innerLayout.data

    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight + 48
    color: surfaceColor
    radius: 16
    border.width: 1
    border.color: outlineColor

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.topMargin: 24
        anchors.bottomMargin: 24
        spacing: 16

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
                    font.weight: Theme.defaultFontWeight; font.pixelSize: 18
                    font.family: Theme.monoFontFamily 
                }
                Text { 
                    text: cardRoot.title
                    color: onSurfaceColor
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 18
                    font.weight: Math.min(900, Theme.defaultFontWeight + 200)
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
}
