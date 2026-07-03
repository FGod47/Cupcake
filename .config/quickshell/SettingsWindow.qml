import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "theme"

PanelWindow {
    id: settingsWin
    WlrLayershell.namespace: "quickshell-settings"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.layer: WlrLayer.Overlay
    
    // Make it take the whole screen but be transparent
    anchors {
        top: true; bottom: true; left: true; right: true
    }
    color: "transparent"
    
    visible: globalState.settingsOpen
    
    Process {
        id: settingsIpcPoll
        command: ["bash", "-c", "while true; do cat /tmp/cupcake_settings 2>/dev/null || echo 0; sleep 0.1; done"]
        running: true
        stdout: SplitParser {
            onRead: (data) => {
                if (data.trim() === "1") {
                    globalState.settingsOpen = true;
                    Quickshell.execDetached(["bash", "-c", "echo 0 > /tmp/cupcake_settings"]);
                }
            }
        }
    }
    
    MouseArea {
        anchors.fill: parent
        onClicked: globalState.settingsOpen = false
    }
    
    Item {
        anchors.centerIn: parent
        width: 868
        height: 768
        
        MouseArea {
            anchors.fill: parent
            onClicked: mouse.accepted = true
        }
        
        SettingsUI {
            id: settingsUI
            anchors.fill: parent
            
            Connections {
                target: settingsUI
                function onRequestClose() {
                    globalState.settingsOpen = false;
                }
            }
        }
    }
}
