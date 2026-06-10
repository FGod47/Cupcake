import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: dropdownWindow
    visible: globalState.popups && globalState.popups.length > 0
    
    anchors.top: true
    anchors.right: true
    
    // Perfectly align right edge with the main bar's content padding (8px)
    // Place it exactly below the 46px bar with a clean 8px gap
    margins.top: 54
    margins.right: 8

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "waybar-dropdown"
    WlrLayershell.layer: WlrLayer.Top

    implicitWidth: 380
    
    property bool closingIsland: globalState.closingIsland
    property bool hasDropdown: globalState.popups && globalState.popups.length > 0 && !closingIsland
    
    // Smoothly track the height of the content, but clamp it to a reasonable maximum (e.g., 400px) so it doesn't overflow the screen
    implicitHeight: hasDropdown ? Math.min(800, contentItem.implicitHeight) : 0
    Behavior on implicitHeight { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }

    Item {
        id: contentItem
        anchors.fill: parent
        implicitHeight: dropdownCol.implicitHeight + 16
        
        // Inner scale and opacity for a beautiful opening effect
        scale: dropdownWindow.hasDropdown ? 1.0 : 0.95
        opacity: dropdownWindow.hasDropdown ? 1.0 : 0.0
        transformOrigin: Item.Top
        
        Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            color: "#1e1e2e" // Deep premium background
            radius: 16
            border.color: "#33ffffff"
            border.width: 1
            clip: true

            Column {
                id: dropdownCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 8
                spacing: 6
                
                // Only show up to the 5 most recent notifications to prevent massive overflow
                Repeater {
                    model: globalState.popups ? globalState.popups.slice(0, 5) : []
                    delegate: NotificationCard {
                        width: dropdownCol.width
                        notificationData: modelData
                        inPanel: false
                    }
                }
            }
        }
    }
}
