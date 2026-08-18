import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "theme"

Item {
    id: root
    anchors.fill: parent
    
    property string actionType: "shutdown"
    property string actionIcon: "\ueb0d"
    property string actionTitle: "Shut down?"
    property string actionDesc: "This will close all apps"
    property string actionCommand: "systemctl poweroff"
    property color actionColor: Theme.colError
    
    Process {
        id: actionReader
        command: ["bash", "-c", "cat ~/.config/cupcake/.power_action 2>/dev/null || echo 'shutdown'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var act = text.trim();
                root.actionType = act;
                if (act === "reboot") {
                    root.actionIcon = "\ueb13";
                    root.actionTitle = "Reboot?";
                    root.actionDesc = "The system will restart";
                    root.actionCommand = "systemctl reboot";
                    root.actionColor = "#e67e22";
                } else if (act === "logout") {
                    root.actionIcon = "\ueba8";
                    root.actionTitle = "Log out?";
                    root.actionDesc = "You will be signed out";
                    root.actionCommand = Theme.homeDir + "/.local/bin/cupcake-logout";
                    root.actionColor = "#3498db";
                } else if (act === "sleep") {
                    root.actionIcon = "\ueaf8";
                    root.actionTitle = "Sleep?";
                    root.actionDesc = "Suspend to RAM";
                    root.actionCommand = "systemctl suspend";
                    root.actionColor = "#9b59b6";
                }
            }
        }
    }
    
    property int countdownSeconds: 5
    property real countdownVisual: 5
    Behavior on countdownVisual { NumberAnimation { duration: 1000; easing.type: Easing.Linear } }
    
    Timer {
        id: powerTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.countdownSeconds--;
            root.countdownVisual = root.countdownSeconds;
            if (root.countdownSeconds <= 0) {
                running = false;
                Quickshell.execDetached(["bash", "-c", root.actionCommand]);
                Qt.quit();
            }
        }
    }
    
    Rectangle {
        anchors.fill: parent
        color: Theme.colSurfaceContainerHigh
        radius: 28
        border.color: Qt.rgba(255/255, 255/255, 255/255, 0.05)
        border.width: 1
        
        Column {
            anchors.centerIn: parent
            spacing: 16
            
            // Icon & Text
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6
                Rectangle {
                    width: 56; height: 56; radius: 28
                    color: Qt.rgba(root.actionColor.r, root.actionColor.g, root.actionColor.b, 0.12)
                    anchors.horizontalCenter: parent.horizontalCenter
                    Text {
                        text: root.actionIcon
                        color: root.actionColor
                        font.family: "tabler-icons"
                        font.pixelSize: 26
                        anchors.centerIn: parent
                    }
                }
                Text {
                    text: root.actionTitle
                    color: Theme.colOnSurface
                    font.family: Theme.defaultFontFamily
                    font.weight: 600
                    font.pixelSize: 15
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: root.actionDesc
                    color: Theme.colOnSurfaceVariant
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 11
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
            
            // Countdown Ring
            Item {
                width: 40; height: 40
                anchors.horizontalCenter: parent.horizontalCenter
                Canvas {
                    id: countdownRing
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var cx = width / 2;
                        var cy = height / 2;
                        var r = 16;
                        
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                        ctx.strokeStyle = "rgba(255,255,255,0.06)";
                        ctx.lineWidth = 3;
                        ctx.stroke();
                        
                        var progress = (5 - root.countdownVisual) / 5.0;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * (1 - progress));
                        ctx.strokeStyle = root.actionColor;
                        ctx.lineWidth = 3;
                        ctx.lineCap = "round";
                        ctx.stroke();
                    }
                }
                Text {
                    text: Math.ceil(root.countdownVisual)
                    color: root.actionColor
                    font.family: Theme.defaultFontFamily
                    font.weight: 600
                    font.pixelSize: 13
                    anchors.centerIn: parent
                }
                
                Timer {
                    interval: 16
                    running: true
                    repeat: true
                    onTriggered: countdownRing.requestPaint()
                }
            }
            
            // Main Action Buttons
            RowLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 190
                spacing: 10
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 12
                    color: Qt.rgba(255/255, 255/255, 255/255, 0.07)
                    Text { text: "Cancel"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.weight: 500; font.pixelSize: 13; anchors.centerIn: parent }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.quit()
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 12
                    color: root.actionColor
                    Text { text: root.actionTitle.replace("?", ""); color: Theme.colBackground; font.family: Theme.defaultFontFamily; font.weight: 600; font.pixelSize: 13; anchors.centerIn: parent }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            powerTimer.running = false
                            Quickshell.execDetached(["bash", "-c", root.actionCommand])
                            Qt.quit()
                        }
                    }
                }
            }
        }
    }
}
