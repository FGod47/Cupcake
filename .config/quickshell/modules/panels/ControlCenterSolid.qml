pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../theme"
import "../common"

PanelWindow {
    id: ccWindow
    
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

    // Full screen invisible catch-all to close the CC on click
    MouseArea {
        anchors.fill: parent
        onClicked: globalState.ccOpen = false
    }

    property string brightStr: "0"
    property string volStr: "0"

    Process {
        id: lightProc
        command: ["sh", "-c", "~/.config/cupcake/scripts/light.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (ccWindow.isDestroying) return;
                let data = text;
                try { brightStr = JSON.parse(data).percentage || "0" } catch(e) { brightStr = data || "0" }
            }
        }
    }
    Timer {
        interval: 1000; running: globalState.ccOpen; repeat: true
        onTriggered: lightProc.running = true
    }

    Process {
        id: audioProc
        command: ["sh", "-c", "~/.config/cupcake/scripts/audio.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (ccWindow.isDestroying) return;
                let data = text;
                try { volStr = JSON.parse(data).percentage || "0" } catch(e) { volStr = data || "0" }
            }
        }
    }
    Timer {
        interval: 1000; running: globalState.ccOpen; repeat: true
        onTriggered: audioProc.running = true
    }

    Timer {
        id: hideTimer
        interval: 350
        onTriggered: ccWindow.isVisible = false
    }

    Connections {
        target: globalState
        function onCcOpenChanged() {
            if (globalState.ccOpen) {
                ccWindow.isVisible = true;
                hideTimer.stop();
                lightProc.running = true;
                audioProc.running = true;
            } else {
                hideTimer.restart();
            }
        }
    }


    // Floating Frosted Glass Panel
    Rectangle {
        id: ccPanel
        width: 320
        height: 140
        
        // Float at top right
        x: ccWindow.width - width - 20
        y: globalState.ccOpen ? 60 : 40 // Slides down slightly
        
        opacity: globalState.ccOpen ? 1.0 : 0.0
        
        Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
        
        radius: 20
        color: Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity || 0.85)
        border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
        border.width: 1
        
        // Prevent click-through to the background dim
        MouseArea { anchors.fill: parent }

        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 24
            
            // Brightness Slider
            Row {
                width: parent.width
                spacing: 16
                Text {
                    text: "\ueb30" // sun icon
                    font.family: "tabler-icons"
                    font.pixelSize: 20
                    color: Theme.colOnSurface
                    anchors.verticalCenter: parent.verticalCenter
                }
                Slider {
                    id: ddBrightSlider
                    width: parent.width - 40
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true
                    handle: Rectangle {
                        x: ddBrightSlider.leftPadding + ddBrightSlider.visualPosition * (ddBrightSlider.availableWidth - width)
                        y: ddBrightSlider.height / 2 - height / 2
                        width: 16; height: 16; radius: 8
                        color: Theme.colPrimary
                    }
                    background: Rectangle {
                        x: ddBrightSlider.leftPadding
                        y: ddBrightSlider.height / 2 - height / 2
                        implicitWidth: 100
                        implicitHeight: 8
                        width: ddBrightSlider.availableWidth
                        height: implicitHeight
                        radius: 4
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.2)
                        Rectangle {
                            width: ddBrightSlider.visualPosition * parent.width
                            height: parent.height
                            color: Theme.colPrimary
                            radius: 4
                        }
                    }
                    from: 0; to: 100
                    value: parseFloat(brightStr) || 0
                    Timer {
                        id: ddDdcTimer
                        interval: 500; repeat: false
                        property int targetValue: 100
                        onTriggered: Quickshell.execDetached(["ddcutil", "setvcp", "10", Math.round(targetValue).toString(), "--noverify"])
                    }
                    onMoved: { ddDdcTimer.targetValue = value; ddDdcTimer.restart(); brightStr = Math.round(value).toString() }
                    onPressedChanged: {
                        if (!pressed) {
                            ddDdcTimer.stop()
                            Quickshell.execDetached(["ddcutil", "setvcp", "10", Math.round(value).toString()])
                        }
                    }
                }
            }

            // Volume Slider
            Row {
                width: parent.width
                spacing: 16
                Text {
                    text: "\ueb51" // volume icon
                    font.family: "tabler-icons"
                    font.pixelSize: 20
                    color: Theme.colOnSurface
                    anchors.verticalCenter: parent.verticalCenter
                }
                Slider {
                    id: ddVolSlider
                    width: parent.width - 40
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true
                    handle: Rectangle {
                        x: ddVolSlider.leftPadding + ddVolSlider.visualPosition * (ddVolSlider.availableWidth - width)
                        y: ddVolSlider.height / 2 - height / 2
                        width: 16; height: 16; radius: 8
                        color: Theme.colPrimary
                    }
                    background: Rectangle {
                        x: ddVolSlider.leftPadding
                        y: ddVolSlider.height / 2 - height / 2
                        implicitWidth: 100
                        implicitHeight: 8
                        width: ddVolSlider.availableWidth
                        height: implicitHeight
                        radius: 4
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.2)
                        Rectangle {
                            width: ddVolSlider.visualPosition * parent.width
                            height: parent.height
                            color: Theme.colPrimary
                            radius: 4
                        }
                    }
                    from: 0; to: 100
                    value: parseFloat(volStr) || 0
                    Timer {
                        id: ddAudioVolTimer
                        interval: 50; repeat: false
                        property int targetVal: 100
                        onTriggered: Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.round(targetVal).toString() + "%"])
                    }
                    onMoved: { ddAudioVolTimer.targetVal = value; ddAudioVolTimer.restart(); volStr = Math.round(value).toString() }
                }
            }
        }
    }
}
