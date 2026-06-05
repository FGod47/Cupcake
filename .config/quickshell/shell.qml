import Quickshell
import Quickshell.Services.Notifications
import QtQuick

ShellRoot {
    id: root

    // Top Bar Components for all screens
    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    // Global State
    Scope {
        id: globalState
        property bool notifPanelVisible: false
        property var notifications: notifServer.trackedNotifications
        property var popups: []
    }

    // Popups & Panels
    NotificationPanel {}
    NotificationPopup {}
    
    // Initialize Quickshell services
    NotificationServer {
        id: notifServer
        onNotification: notif => {
            notif.tracked = true;
            
            // Add to popup array using concat to create a new array reference so the UI actually updates
            globalState.popups = globalState.popups.concat(notif);
        }
    }
}
