import QtQuick
import Quickshell
import "../../theme"

PanelWindow {
    id: root
    color: "transparent"
    width: 300
    height: 300
    
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    // We make it ignore input so it doesn't block the actual mouse
    exclusiveZone: 0
    margins {
        top: 0; bottom: 0; left: 0; right: 0
    }

    Rectangle {
        id: ripple
        anchors.centerIn: parent
        width: 10
        height: 10
        radius: width / 2
        color: "transparent"
        border.color: Theme.colPrimary
        border.width: 4
        opacity: 1.0

        SequentialAnimation {
            running: true
            onStopped: Qt.quit()

            ParallelAnimation {
                NumberAnimation {
                    target: ripple
                    property: "width"
                    to: 200
                    duration: 600
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: ripple
                    property: "height"
                    to: 200
                    duration: 600
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: ripple
                    property: "opacity"
                    to: 0.0
                    duration: 600
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
