//@ pragma UseQApplication
import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import "theme"

ShellRoot {
    id: root

    // Top Bar Components for all screens
    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    // Bottom Dock for all screens
    Variants {
        model: Quickshell.screens
        delegate: Dock {}
    }

    // Global State
    Scope {
        id: globalState
        property bool aiPanelVisible: false
        property bool notifPanelVisible: false
        property var notifications: notifServer.trackedNotifications
        property var popups: []
        property var activePopup: null
        property real activeNotifWidth: 352
        property real clockPillWidth: 150
        property real islandWidth: 150
        property string clockString: ""
        property bool closingIsland: false
        property bool hideIsland: false
    }

    // Popups & Panels
    NotificationPanel {}
    Osd {}
    AiPanel {}

    Timer {
        id: islandTimer
        interval: 5000 // Island stays open for 5 seconds
        repeat: false
        onTriggered: {
            if (globalState.popups.length > 0) {
                globalState.closingIsland = true;
                islandHideTimer.start();
                islandCloseTimer.start();
            }
        }
    }

    Timer {
        id: islandHideTimer
        interval: 50
        repeat: false
        onTriggered: {
            globalState.hideIsland = true;
        }
    }

    Timer {
        id: islandCloseTimer
        interval: 2050 // Wait for the visual closing animations to finish before clearing popups
        repeat: false
        onTriggered: {
            globalState.popups = [];
            globalState.closingIsland = false;
            globalState.hideIsland = false;
        }
    }
    
    // Initialize Quickshell services
    NotificationServer {
        id: notifServer
        onNotification: notif => {
            notif.tracked = true;

            // Reset closing state if a new notification arrives
            globalState.closingIsland = false;
            globalState.hideIsland = false;
            islandHideTimer.stop();
            islandCloseTimer.stop();

            // Add to popup array using concat to create a new array reference so the UI actually updates
            globalState.popups = [notif].concat(globalState.popups);
            
            islandTimer.restart();
        }
    }
}
