import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: osdWindow
    anchors {
        bottom: true
    }
    margins.bottom: 80

    implicitWidth: 260
    implicitHeight: 48
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
        anchors.fill: parent
        radius: 24
        color: "#000000"
        opacity: osdWindow.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
        
        Row {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12
            
            Text {
                text: osdWindow.osdIcon
                color: "#cdd6f4"
                font.pixelSize: 18
                anchors.verticalCenter: parent.verticalCenter
            }
            
            Rectangle {
                width: parent.width - 32
                height: 6
                anchors.verticalCenter: parent.verticalCenter
                radius: 3
                color: "#1a1b26"
                
                Rectangle {
                    width: (osdWindow.osdValue / 100) * parent.width
                    height: parent.height
                    radius: 3
                    color: "#89b4fa"
                    Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
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
            osdWindow.osdIcon = ["󰃜", "󰃛", "󰃚", "󰃝", "󰃞", "󰃟", "󰃠"][Math.min(6, Math.floor(bright / 15))]
            
            if (!osdWindow.visible) {
                osdWindow.visible = true
            }
            hideTimer.restart()
        }
    }

    visible: false
}
