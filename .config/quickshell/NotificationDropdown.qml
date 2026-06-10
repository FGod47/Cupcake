import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: dropdownWindow
    visible: globalState.popups && globalState.popups.length > 0 || globalState.closingIsland
    
    anchors.top: true
    anchors.right: true
    
    // clockPill Absolute Y = 10, Absolute Right Margin = 62
    margins.top: 10
    margins.right: 62

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "waybar-dropdown"
    WlrLayershell.layer: WlrLayer.Overlay

    implicitWidth: 380
    implicitHeight: 600
    
    property bool closingIsland: globalState.closingIsland
    property bool hasDropdown: globalState.popups && globalState.popups.length > 0 && !closingIsland

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        
        width: globalState.islandWidth

        height: dropdownWindow.hasDropdown ? Math.min(600, Math.max(34, dropdownCol.height + 16)) : 34
        Behavior on height { NumberAnimation { duration: globalState.closingIsland ? 800 : 600; easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutExpo } }

        color: "#27293F"
        radius: 18
        clip: true
        
        opacity: 1.0
        
        Item {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 34
            
            Row {
                anchors.centerIn: parent
                spacing: 5
                opacity: globalState.closingIsland ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.InOutCubic } }
                
                Text { text: "󰂚"; color: "#eeffff"; font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 14 }
                Text { text: " | "; color: "#eeffff"; font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 14 }
                Text { 
                    text: globalState.clockString || Qt.formatDateTime(new Date(), "MMM dd  hh:mm AP")
                    color: "#eeffff"; font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 14; font.weight: 500 
                }
            }
        }
        
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
            
            Behavior on scale { NumberAnimation { duration: globalState.closingIsland ? 800 : 600; easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutExpo } }
            Behavior on opacity { NumberAnimation { duration: globalState.closingIsland ? 800 : 600; easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutExpo } }

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
