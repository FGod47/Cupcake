//@ pragma UseQApplication
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
        property var activePopup: null
        property real activeNotifWidth: 352
        property bool closingIsland: false
    }

    // NotificationPopup is now completely embedded inside Bar.qml for pixel-perfect pill alignment

    Timer {
        id: islandTimer
        interval: 5000
        repeat: false
        onTriggered: {
            if (globalState.popups.length > 0) {
                globalState.closingIsland = true;
                islandCloseTimer.start();
            }
        }
    }

    Timer {
        id: islandCloseTimer
        interval: 900
        repeat: false
        onTriggered: {
            globalState.popups = [];
            globalState.closingIsland = false;
        }
    }
    
    // Initialize Quickshell services
    NotificationServer {
        id: notifServer
        onNotification: notif => {
            notif.tracked = true;

            // Reset closing state if a new notification arrives
            globalState.closingIsland = false;
            islandCloseTimer.stop();

            // Add to popup array using concat to create a new array reference so the UI actually updates
            globalState.popups = [notif].concat(globalState.popups);
            
            islandTimer.restart();
        }
    }
}
