import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../common"
import "../settings"

PanelWindow {
    id: overlayRoot
    
    anchors { left: true; top: true; bottom: true; right: true }
    WlrLayershell.namespace: "cupcake-wallpaper-overlay"
    WlrLayershell.layer: WlrLayer.Bottom
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: globalState.dimOverlay
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
    }
}
