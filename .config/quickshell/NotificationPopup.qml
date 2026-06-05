import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: popupWindow
    anchors {
        top: true
        right: true
    }
    
    margins {
        top: 45 // perfectly closes the vertical gap
        right: 80 // perfectly aligned left of the power pill
    }
    
    // We want the window to be just wide enough and tall enough to fit our list
    width: 320 + 32 // 320 for toast, 32 for margin padding
    height: popupList.contentHeight + 32 // Extra space for animations
    
    // Nudge it over to the right or center depending on preference. Let's center top.
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    
    // To support multiple monitors or just the active one, pick a screen, or rely on Wayland defaults
    
    color: "transparent"
    
    // Only show the popup list if there are 2 or more notifications, OR if we want to show all
    visible: globalState.popups && globalState.popups.length > 1
    
    ListView {
        id: popupList
        anchors.fill: parent
        anchors.margins: 16
        
        spacing: 8
        interactive: false
        
        model: globalState.popups ? globalState.popups.slice(1) : []
        
        delegate: Item {
            width: popupList.width
            height: cardContainer.implicitHeight
            
            Item {
                id: cardContainer
                width: popupList.width
                implicitHeight: card.height
                
                NotificationCard {
                    id: card
                    notificationData: modelData
                    inPanel: false
                }
            }
        }
    }
}
