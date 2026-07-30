pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../common"

PanelWindow {
    id: solidBoardWindow
    
    property var modelData
    screen: modelData

    anchors { top: true; right: true; bottom: true; left: true } // fill entire screen for background click
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Top
    exclusiveZone: -1 // overlapping
    color: "transparent"
    
    property bool isVisible: false
    visible: isVisible

    // Background click-to-close
    MouseArea {
        anchors.fill: parent
        onClicked: globalState.solidBoardOpen = false
    }

    Timer {
        id: hideTimer
        interval: 350
        onTriggered: solidBoardWindow.isVisible = false
    }

    Connections {
        target: globalState
        function onSolidBoardOpenChanged() {
            if (globalState.solidBoardOpen) {
                solidBoardWindow.isVisible = true;
                hideTimer.stop();
            } else {
                hideTimer.restart();
            }
        }
    }

    // Main SolidBoard container
    Rectangle {
        id: boardContainer
        width: 854
        height: contentGrid.implicitHeight + 40
        
        // Centered horizontally, slides down from top
        x: (solidBoardWindow.width - width) / 2
        y: globalState.solidBoardOpen ? 60 : (-height - 20)
        
        color: Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, 0.85)
        radius: 20
        border.color: Qt.rgba(255, 255, 255, 0.05)
        border.width: 1

        Behavior on y {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutBack
                easing.overshoot: 1.1
            }
        }

        GridLayout {
            id: contentGrid
            anchors.fill: parent
            anchors.margins: 20
            rowSpacing: 16
            columnSpacing: 16
            columns: 6

            // Placeholder for the widgets we'll build
            Text {
                Layout.columnSpan: 6
                Layout.alignment: Qt.AlignCenter
                text: "SolidBoard coming soon..."
                font.family: Theme.defaultFontFamily
                font.pixelSize: 18
                color: Theme.fg
            }
        }
    }
}
