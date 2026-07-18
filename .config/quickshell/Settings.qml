//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import "theme"
import "modules/panels"
import "modules/settings"
import "modules/common"

Window {
    id: settingsWindow
    visible: true
    width: 900
    height: 800
    minimumWidth: 800
    minimumHeight: 600
    maximumWidth: 1200
    maximumHeight: 900
    title: "Cupcake Settings"
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint
    
    property real bgOpacity: 0.75
    Process {
        id: initSettingsOpacity
        command: ["cat", Quickshell.env("HOME") + "/.config/cupcake/.settings_opacity"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { let v = parseFloat(text.trim()); if (!isNaN(v)) settingsWindow.bgOpacity = v; }
            }
        }
    }
    Timer { interval: 500; running: true; repeat: true; onTriggered: initSettingsOpacity.running = true }

    Rectangle {
        anchors.fill: parent
        radius: 20
        border.width: 1
        border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.3)
        clip: true
        
        // Solid glassy background to prevent color banding (line blocks)
        color: Qt.rgba(Theme.colSurfaceContainer.r, Theme.colSurfaceContainer.g, Theme.colSurfaceContainer.b, settingsWindow.bgOpacity)
        
        SettingsUI {
            id: settingsUI
            anchors.fill: parent
            
            Connections {
                target: settingsUI
                function onRequestClose() {
                    Qt.quit();
                }
            }
        }
    }
}
