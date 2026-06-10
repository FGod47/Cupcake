import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: dropdownWindow
    visible: globalState.popups && globalState.popups.length > 0 || globalState.closingIsland
    
    anchors.top: true
    anchors.right: true
    
    // Position exactly over the Bar's clockPill to create a perfect Dynamic Island morph!
    // clockPill Absolute Y = 10, Absolute Right Margin = 62
    margins.top: 10
    margins.right: 62

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "waybar-dropdown"
    WlrLayershell.layer: WlrLayer.Overlay

    // Expand width to 380 matching the pill's expansion
    implicitWidth: hasDropdown ? 380 : 150 // Match normal clock pill width when closed
    Behavior on implicitWidth { NumberAnimation { duration: closingIsland ? 600 : 400; easing.type: closingIsland ? Easing.InOutQuad : Easing.OutQuint } }
    
    property bool closingIsland: globalState.closingIsland
    property bool hasDropdown: globalState.popups && globalState.popups.length > 0 && !closingIsland
    
    // Smoothly track height, starting from 34 (pill height)
    implicitHeight: hasDropdown ? Math.min(600, Math.max(34, dropdownCol.height + 16)) : 34
    Behavior on implicitHeight { NumberAnimation { duration: closingIsland ? 600 : 400; easing.type: closingIsland ? Easing.InOutQuad : Easing.OutQuint } }

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
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.topMargin: 8
            
            transformOrigin: Item.TopRight
            scale: dropdownWindow.hasDropdown ? 1.0 : 0.0
            opacity: dropdownWindow.hasDropdown ? 1.0 : 0.0
            
            Behavior on scale { NumberAnimation { duration: dropdownWindow.closingIsland ? 600 : 400; easing.type: dropdownWindow.closingIsland ? Easing.InOutQuad : Easing.OutQuint } }
            Behavior on opacity { NumberAnimation { duration: dropdownWindow.closingIsland ? 600 : 400; easing.type: dropdownWindow.closingIsland ? Easing.InOutQuad : Easing.OutQuint } }

            spacing: 6
            Repeater {
                model: globalState.popups && globalState.popups.length > 0 ? globalState.popups.slice(0, 5) : []
                delegate: NotificationCard {
                    width: dropdownCol.width
                    notificationData: modelData
                    inPanel: false
                }
            }
        }
    }
}
