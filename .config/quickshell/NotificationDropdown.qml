import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: dropdownWindow
    visible: globalState.popups && globalState.popups.length > 0
    
    anchors.top: true
    anchors.right: true
    
    // Top margin matches the clock pill's vertical position relative to the screen.
    // Bar is 46px, pill is 34px centered (Y offset = 6).
    margins.top: 6
    
    // Right margin matches where the clock pill roughly is
    margins.right: 108

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "waybar-dropdown"
    WlrLayershell.layer: WlrLayer.Overlay

    width: 380
    
    property bool closingIsland: globalState.closingIsland
    property bool hasDropdown: globalState.popups && globalState.popups.length > 0 && !closingIsland
    
    // Shrink vertically down to the clock pill's height (34)
    height: hasDropdown ? Math.max(34, dropdownCol.height + 16) : 34
    Behavior on height { NumberAnimation { duration: closingIsland ? 600 : 400; easing.type: closingIsland ? Easing.InOutQuad : Easing.OutQuint } }

    Rectangle {
        anchors.fill: parent
        color: "#27293F"
        radius: 18
        clip: true
        
        Column {
            id: dropdownCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            
            transformOrigin: Item.TopRight
            scale: dropdownWindow.hasDropdown ? 1.0 : 0.0
            Behavior on scale { NumberAnimation { duration: dropdownWindow.closingIsland ? 600 : 400; easing.type: dropdownWindow.closingIsland ? Easing.InOutQuad : Easing.OutQuint } }

            spacing: 6
            Repeater {
                model: globalState.popups && globalState.popups.length > 0 ? globalState.popups : []
                delegate: NotificationCard {
                    width: dropdownCol.width
                    notificationData: modelData
                    inPanel: false
                }
            }
        }
    }
}
