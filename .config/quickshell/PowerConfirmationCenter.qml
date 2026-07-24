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
        }
    }
    
    Rectangle {
        anchors.fill: parent
        color: Theme.colSurfaceContainerHigh
        radius: 20
        border.color: Qt.rgba(255/255, 255/255, 255/255, 0.1)
        border.width: 1
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 25
            spacing: 20
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 15
                
                Rectangle {
                    width: 50; height: 50; radius: 25
                    color: Qt.rgba(220/255, 70/255, 70/255, 0.15)
                    Text {
                        text: "\ueb0d"
                        color: Theme.colError
                        font.family: "tabler-icons"
                        font.pixelSize: 24
                        anchors.centerIn: parent
                    }
                }
                
                Column {
                    Layout.fillWidth: true
                    Text {
                        text: "Shutting down"
                        color: Theme.colOnSurface
                        font.family: Theme.defaultFontFamily
                        font.weight: 600
                        font.pixelSize: 20
                    }
                    Text {
                        text: "System will power off in " + root.countdownSeconds + " seconds"
                        color: Theme.colOnSurfaceVariant
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 13
                    }
                }
            }
            
            // Linear Progress Bar
            Item {
                Layout.fillWidth: true
                height: 6
                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: Qt.rgba(255/255, 255/255, 255/255, 0.05)
                }
                Rectangle {
                    height: parent.height
                    radius: 3
                    color: Theme.colError
                    width: parent.width * (root.countdownSeconds / 5.0)
                    Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.Linear } }
                }
            }
            
            Item { Layout.fillHeight: true } // Spacer
            
            // Actions
            RowLayout {
                Layout.fillWidth: true
                spacing: 15
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 45
                    radius: 12
                    color: Qt.rgba(255/255, 255/255, 255/255, 0.08)
                    Text { text: "Cancel"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.weight: 500; font.pixelSize: 14; anchors.centerIn: parent }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.quit()
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 45
                    radius: 12
                    color: Theme.colError
                    Text { text: "Shut down now"; color: Theme.colBackground; font.family: Theme.defaultFontFamily; font.weight: 600; font.pixelSize: 14; anchors.centerIn: parent }
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
