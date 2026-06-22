import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "theme"

Rectangle {
    id: cardRoot
    property string title: ""
    property string icon: ""
    
    property color surfaceColor: root.globalTransparency ? Qt.rgba(Theme.colSurfaceContainer.r, Theme.colSurfaceContainer.g, Theme.colSurfaceContainer.b, 0.4) : Theme.colSurfaceContainer
    property color surfaceHoverColor: root.globalTransparency ? Qt.rgba(Theme.colSurfaceContainerHigh.r, Theme.colSurfaceContainerHigh.g, Theme.colSurfaceContainerHigh.b, 0.5) : Theme.colSurfaceContainerHigh
    property color surfacePressColor: root.globalTransparency ? Qt.rgba(Theme.colSurfaceContainerHighest.r, Theme.colSurfaceContainerHighest.g, Theme.colSurfaceContainerHighest.b, 0.6) : Theme.colSurfaceContainerHighest
    property color outlineColor
    property color primaryColor
    property color onSurfaceColor
    
    default property alias content: innerLayout.data

    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight + 40
    color: surfaceColor
    radius: 16
    border.color: outlineColor
    border.width: 1

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            visible: cardRoot.title !== ""
            spacing: 12
            
            Text { 
                text: cardRoot.icon
                color: primaryColor
                font.pixelSize: 22
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
    }
}
