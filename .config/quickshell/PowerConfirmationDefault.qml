import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "theme"

Item {
    id: root
    anchors.fill: parent
    
    Rectangle {
        anchors.centerIn: parent
        width: 320
        height: 140
        color: Theme.colSurfaceContainerHigh
        radius: 8
        border.color: Theme.colOutlineVariant
        border.width: 1
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15
            
            Text {
                text: "Shut Down"
                color: Theme.colOnSurface
                font.family: Theme.defaultFontFamily
                font.weight: 600
                font.pixelSize: 16
            }
            
            Text {
                Layout.fillWidth: true
                text: "Are you sure you want to shut down the system?"
                color: Theme.colOnSurfaceVariant
                font.family: Theme.defaultFontFamily
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }
            
            Item { Layout.fillHeight: true }
            
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10
                
                Rectangle {
                    width: 80; height: 32; radius: 4
                    color: "transparent"
                    border.color: Theme.colOutline
                    border.width: 1
                    Text { text: "Cancel"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; anchors.centerIn: parent }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.quit() }
                }
                
                Rectangle {
                    width: 90; height: 32; radius: 4
                    color: Theme.colError
                    Text { text: "Shut Down"; color: "white"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600; anchors.centerIn: parent }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["bash", "-c", "systemctl poweroff"])
                            Qt.quit()
                        }
                    }
                }
            }
        }
    }
}
