import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../../theme"

Item {
    id: tog
    property bool checked: false
    signal toggled(bool val)

    width: 44; height: 24
    
    // Modern Flat Track
    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        
        color: tog.checked ? Theme.colPrimary : Qt.rgba(255/255, 255/255, 255/255, 0.15)
        border.color: Qt.rgba(255/255, 255/255, 255/255, 0.05)
        border.width: 1
        Behavior on color { ColorAnimation { duration: 250 } }
    }

    // Thumb Container (larger to prevent shadow clipping)
    Item {
        id: thumbContainer
        width: 44
        height: 44
        y: -10
        x: tog.checked ? 10 : -10
        Behavior on x { NumberAnimation { duration: 800; easing.type: Easing.OutElastic; easing.amplitude: 1.0; easing.period: 0.85 } }
        
        scale: ma.pressed ? 0.85 : 1.0
        Behavior on scale { NumberAnimation { duration: 800; easing.type: Easing.OutElastic; easing.amplitude: 1.0; easing.period: 0.85 } }
        
        Item {
            id: thumbSrc
            anchors.fill: parent
            visible: false
            Rectangle { 
                anchors.verticalCenter: parent.verticalCenter
                property bool isExpanded: ma.pressed || ma.containsMouse
                x: tog.checked ? (isExpanded ? 7 : 13) : 13
                width: isExpanded ? 24 : 18
                height: 18; radius: 9
                color: tog.checked ? Theme.colOnPrimary : Qt.rgba(255/255, 255/255, 255/255, 0.9)
                Behavior on color { ColorAnimation { duration: 250 } }
                Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.OutElastic; easing.amplitude: 1.0; easing.period: 0.85 } }
                Behavior on x { NumberAnimation { duration: 800; easing.type: Easing.OutElastic; easing.amplitude: 1.0; easing.period: 0.85 } }
            }
        }
        
        // Soft drop shadow for thumb depth
        DropShadow {
            anchors.fill: parent
            source: thumbSrc
            color: Qt.rgba(0, 0, 0, 0.35)
            horizontalOffset: 0
            verticalOffset: 2
            radius: 6
            samples: 13
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { tog.checked = !tog.checked; tog.toggled(tog.checked) }
    }
}
