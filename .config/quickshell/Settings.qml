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
    width: 977
    height: 806
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

    // Dynamically read Hyprland's rounding value so window corners always match
    property int hyprRounding: 10
    Process {
        id: initRounding
        command: ["bash", "-c", "hyprctl getoption decoration:rounding -j | grep -o '\"int\": [0-9]*' | grep -o '[0-9]*'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let v = parseInt(text.trim());
                if (!isNaN(v) && v >= 0) settingsWindow.hyprRounding = v;
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: settingsWindow.hyprRounding
        border.width: 1
        border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.3)
        clip: true
        
        // Solid glassy background to prevent color banding (line blocks)
        color: Qt.rgba(Theme.colSurfaceContainer.r, Theme.colSurfaceContainer.g, Theme.colSurfaceContainer.b, settingsWindow.bgOpacity)
        
        SettingsUI {
            id: settingsUI
            anchors.fill: parent
            windowRadius: settingsWindow.hyprRounding
            
            Connections {
                target: settingsUI
                function onRequestClose() {
                    Qt.quit();
                }
            }
        }
    }
}
