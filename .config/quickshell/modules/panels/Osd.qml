import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "../../theme"
import "../common"
import "../settings"

PanelWindow {
    id: osdWindow
    anchors {
        bottom: true
    }
    margins.bottom: 80

    implicitWidth: 260
    implicitHeight: Math.max(48, mainCol.implicitHeight + 28)
    color: "transparent"
    
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

    property real osdValue: 50
    property string osdIcon: ""
    
    // Auto-hide timer
    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: osdWindow.visible = false
    }

    Rectangle {
        id: bg
        width: parent.width
        height: Math.max(48, mainCol.implicitHeight + 28)
        Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
        clip: true
        radius: 24
        color: Qt.rgba(Theme.colSurfaceContainerHigh.r, Theme.colSurfaceContainerHigh.g, Theme.colSurfaceContainerHigh.b, root.osdOpacity)
        opacity: osdWindow.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
        
        MouseArea {
            id: osdHover
            anchors.fill: parent
            hoverEnabled: true
            onContainsMouseChanged: {
                if (containsMouse) {
                    hideTimer.stop()
                } else {
                    hideTimer.restart()
                }
            }
        }
        
        Column {
            id: mainCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 12
            
            Row {
                id: contentRow
                width: parent.width
                height: Math.max(iconText.implicitHeight, 20)
                spacing: 12
                
                Text {
                    id: iconText
                    text: osdWindow.osdIcon
                    color: Theme.colOnSurface
                    font.pixelSize: 18
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    horizontalAlignment: Text.AlignHCenter
                }
                
                Rectangle {
                    width: parent.width - iconText.width - pctText.width - (contentRow.spacing * 2)
                    height: 6
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 3
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.2)
                    
                    Rectangle {
                        width: (osdWindow.osdValue / 100) * parent.width
                        height: parent.height
                        radius: 3
                        color: Theme.colPrimary
                        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    }
                }

                Text {
                    id: pctText
                    text: Math.round(osdWindow.osdValue) + "%"
                    color: Theme.colOnSurface
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                    width: 38
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }
            }
            
            Item {
                width: parent.width
                height: osdHover.containsMouse ? innerCol.implicitHeight : 0
                opacity: osdHover.containsMouse ? 1 : 0
                visible: height > 0 || opacity > 0
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }
                
                Column {
                    id: innerCol
                    width: parent.width
                    spacing: 12
                
                Repeater {
                    model: Pipewire.nodes
                    delegate: Row {
                        width: parent.width
                        height: isAudioStream ? 20 : 0
                        visible: isAudioStream
                        spacing: 12
                        
                        property bool isAudioStream: typeof modelData !== "undefined" && modelData.isStream && typeof modelData.audio !== "undefined" && modelData.audio !== null
                        property real currentVol: 0
                        
                        function getIcon(name) {
                            if (!name) return "󰎆";
                            let n = name.toLowerCase();
                            if (n.includes("chrome") || n.includes("firefox") || n.includes("brave") || n.includes("edge")) return "󰊯";
                            if (n.includes("spotify") || n.includes("music")) return "󰓇";
                            if (n.includes("discord") || n.includes("teamspeak")) return "󰙯";
                            if (n.includes("steam")) return "󰓓";
                            if (n.includes("mpv") || n.includes("vlc") || n.includes("player")) return "󰕼";
                            if (n.includes("obs")) return "󰑋";
                            return "󰎆";
                        }
                        
                        Text {
                            id: appIcon
                            text: isAudioStream ? getIcon(modelData.name) : "󰎆"
                            color: Theme.colOnSurfaceVariant
                            font.pixelSize: 18
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Process {
                            id: volProc
                        }
                        
                        Process {
                            id: initVolProc
                            command: isAudioStream ? ["wpctl", "get-volume", modelData.id.toString()] : ["echo"]
                            running: isAudioStream
                            stdout: StdioCollector {
                                id: initVolOut
                            }
                            onExited: {
                                let out = initVolOut.text.trim();
                                let match = out.match(/Volume:\s+([\d\.]+)/);
                                if (match) {
                                    currentVol = parseFloat(match[1]);
                                }
                            }
                        }
                        
                        Connections {
                            target: osdWindow
                            function onVisibleChanged() {
                                if (osdWindow.visible && isAudioStream) {
                                    initVolProc.running = true;
                                }
                            }
                        }
                        
                        Rectangle {
                            width: parent.width - appIcon.width - appPctText.width - (parent.spacing * 2)
                            height: 6
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 3
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.1)
                            
                            Rectangle {
                                width: isAudioStream ? (currentVol * parent.width) : 0
                                height: parent.height
                                radius: 3
                                color: Theme.colPrimary
                                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -8
                                onClicked: (mouse) => { 
                                    if (isAudioStream) {
                                        var v = Math.max(0, Math.min(1, mouse.x / width));
                                        currentVol = v;
                                        volProc.command = ["wpctl", "set-volume", modelData.id.toString(), v.toString()];
                                        volProc.running = true;
                                    }
                                }
                                onPositionChanged: (mouse) => {
                                    if (pressed && isAudioStream) {
                                        var v = Math.max(0, Math.min(1, mouse.x / width));
                                        currentVol = v;
                                        volProc.command = ["wpctl", "set-volume", modelData.id.toString(), v.toString()];
                                        volProc.running = true;
                                    }
                                }
                            }
                        }
                        
                        Text {
                            id: appPctText
                            text: isAudioStream ? Math.round(currentVol * 100) + "%" : "0%"
                            color: Theme.colOnSurfaceVariant
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                            width: 38
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
                }
            }
        }
    }

    IpcHandler {
        target: "osd"
        function volume(vol: int): void {
            osdWindow.osdValue = vol
            osdWindow.osdIcon = vol === 0 ? "󰝟" : ["󰕿", "󰖀", "󰕾"][Math.min(2, Math.floor((vol - 1) / 33))]
            
            if (!osdWindow.visible) {
                osdWindow.visible = true
            }
            hideTimer.restart()
        }
        
        function brightness(bright: int): void {
            osdWindow.osdValue = bright
            osdWindow.osdIcon = ["󰃞", "󰃞", "󰃟", "󰃟", "󰃠", "󰃠", "󰃠"][Math.min(6, Math.floor(bright / 15))]
            
            if (!osdWindow.visible) {
                osdWindow.visible = true
            }
            hideTimer.restart()
        }
    }

    visible: false
}
