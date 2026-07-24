import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "theme"

Item {
    id: root
    anchors.fill: parent
    
    property int countdownSeconds: 5
    
    Timer {
        id: powerTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.countdownSeconds--;
            if (root.countdownSeconds <= 0) {
                running = false;
                Quickshell.execDetached(["bash", "-c", "systemctl poweroff"]);
                Qt.quit();
            }
            countdownRing.requestPaint();
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
                    color: Qt.rgba(220/255, 70/255, 70/255, 0.12)
                    anchors.horizontalCenter: parent.horizontalCenter
                    Text {
                        text: "\ueb0d"
                        color: Theme.colError
                        font.family: "tabler-icons"
                        font.pixelSize: 26
                        anchors.centerIn: parent
                    }
                }
                Text {
                    text: "Shut down?"
                    color: Theme.colOnSurface
                    font.family: Theme.defaultFontFamily
                    font.weight: 600
                    font.pixelSize: 15
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "This will close all apps"
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
                        
                        var progress = (5 - root.countdownSeconds) / 5.0;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * (1 - progress));
                        ctx.strokeStyle = Theme.colError;
                        ctx.lineWidth = 3;
                        ctx.lineCap = "round";
                        ctx.stroke();
                    }
                }
                Text {
                    text: root.countdownSeconds
                    color: Theme.colError
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
                    color: "#c0392b"
                    Text { text: "Shut down"; color: "white"; font.family: Theme.defaultFontFamily; font.weight: 600; font.pixelSize: 13; anchors.centerIn: parent }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            powerTimer.running = false
                            Quickshell.execDetached(["bash", "-c", "systemctl poweroff"])
                            Qt.quit()
                        }
                    }
                }
            }
        }
    }
}
