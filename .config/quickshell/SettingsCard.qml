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
                    color: onSurfaceColor
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 14
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
    
    Component.onCompleted: {
        for (let i = 0; i < innerLayout.children.length; i++) {
            let child = innerLayout.children[i];
            let comp = Qt.createQmlObject('import QtQuick; Rectangle { color: Qt.rgba(Theme.colSurfaceVariant.r, Theme.colSurfaceVariant.g, Theme.colSurfaceVariant.b, 0.4); radius: height/2; z: -1 }', child, "dynamicBg" + i);
            comp.anchors.fill = child;
            comp.anchors.margins = -12;
            comp.anchors.leftMargin = -20;
            comp.anchors.rightMargin = -20;
        }
    }
}
