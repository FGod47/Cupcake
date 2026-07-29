import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"

Rectangle {
    id: seg
    property var options: []
    property string current: options.length > 0 ? options[0] : ""
    signal selected(string value)
    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.1)
    radius: 8
    implicitHeight: 30
    implicitWidth: row.implicitWidth + 4
    Item {
        anchors.fill: row
        Rectangle {
            id: segHighlight
            property Item activeItem: null
            
            x: activeItem ? activeItem.x : 0
            y: activeItem ? activeItem.y : 0
            width: activeItem ? activeItem.width : 0
            height: activeItem ? activeItem.height : 0
            
            property bool activeHovered: activeItem && activeItem.hovered
            scale: activeHovered ? 1.08 : 1.0
            
            color: Theme.colPrimary
            radius: 6
            z: 1
            
            Behavior on x { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
            Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
            Behavior on scale { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 1
        z: 2
        Repeater {
            model: seg.options
            delegate: Rectangle {
                id: pillDel
                required property string modelData
                property bool active: modelData === seg.current
                height: 26
                width: label.implicitWidth + 24
                radius: 6
                color: "transparent"
                
                property bool hovered: ma.containsMouse
                
                Text {
                    id: label
                    anchors.centerIn: parent
                    text: modelData
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: active ? Theme.colOnPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.5)
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: { seg.current = modelData; seg.selected(modelData) }
                }
                
                onActiveChanged: {
                    if (active) segHighlight.activeItem = pillDel
                }
                Component.onCompleted: {
                    if (active) segHighlight.activeItem = pillDel
                }
            }
        }
    }
}
