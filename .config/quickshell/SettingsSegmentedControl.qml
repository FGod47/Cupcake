import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "theme"

Rectangle {
    id: root
    
    // API
    property var model: [] // Array of { label: "Text", value: "val", icon: "󰏘" }
    property string currentValue: ""
    property int currentIndex: -1
    signal valueChanged(string value, int index)
    
    // Internal
    height: 36
    implicitWidth: layout.implicitWidth + 8
    radius: height / 2
    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
    border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
    border.width: 1
    
    Component.onCompleted: {
        for (let i = 0; i < model.length; i++) {
            if (model[i].value === currentValue) {
                currentIndex = i;
                return;
            }
        }
        if (currentIndex >= 0 && currentIndex < model.length) {
            currentValue = model[currentIndex].value;
        } else if (model.length > 0) {
            currentIndex = 0;
            currentValue = model[0].value;
        }
    }
    
    onCurrentValueChanged: {
        for (let i = 0; i < model.length; i++) {
            if (model[i].value === currentValue) {
                currentIndex = i;
                return;
            }
        }
    }
    
    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 4
        spacing: 4
        
        Repeater {
            model: root.model
            
            delegate: Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: contentRow.implicitWidth + 24
                radius: root.height / 2 - 4
                
                property bool isSelected: root.currentIndex === index
                
                color: isSelected 
                    ? Qt.rgba(Theme.colSurfaceContainerHigh.r, Theme.colSurfaceContainerHigh.g, Theme.colSurfaceContainerHigh.b, 1.0)
                    : (mouseArea.containsMouse ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05) : "transparent")
                
                border.width: 1
                border.color: isSelected 
                    ? Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.2) 
                    : "transparent"
                    
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                
                RowLayout {
                    id: contentRow
                    anchors.centerIn: parent
                    spacing: 6
                    
                    Text {
                        visible: modelData.icon !== undefined
                        text: modelData.icon !== undefined ? modelData.icon : ""
                        color: isSelected ? Theme.colOnSurface : Theme.colOnSurfaceVariant
                        font.family: root.font ? root.font.family : "Inter"
                        font.pixelSize: 14
                    }
                    
                    Text {
                        text: modelData.label
                        color: isSelected ? Theme.colOnSurface : Theme.colOnSurfaceVariant
                        font.family: "Inter"
                        font.pixelSize: 13
                        font.bold: isSelected
                    }
                }
                
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentIndex = index;
                        root.currentValue = modelData.value;
                        root.valueChanged(modelData.value, index);
                    }
                }
            }
        }
    }
}
