import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "theme"

PanelWindow {
    id: confirmWindow
    visible: true
    color: "transparent"
    
    WlrLayershell.layer: WlrLayer.Top
    exclusiveZone: -1
    
    property string activeStyle: "Island"
    
    implicitWidth: activeStyle === "Center" ? 400 : (activeStyle === "Default" ? 340 : 230)
    implicitHeight: activeStyle === "Center" ? 250 : (activeStyle === "Default" ? 160 : 290)
    
    anchors.top: activeStyle === "Island"
    anchors.right: activeStyle === "Island"
    margins.top: activeStyle === "Island" ? 54 : 0
    margins.right: activeStyle === "Island" ? 10 : 0
    
    Process {
        id: getStyleProcess
        command: ["bash", "-c", "cat ~/.config/cupcake/.power_confirmation_style 2>/dev/null || echo 'Island'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    confirmWindow.activeStyle = text.trim();
                }
            }
        }
    }
    
    Loader {
        anchors.fill: parent
        source: {
            if (activeStyle === "Center") return "PowerConfirmationCenter.qml";
            if (activeStyle === "Default") return "PowerConfirmationDefault.qml";
            return "PowerConfirmationIsland.qml";
        }
    }
}
