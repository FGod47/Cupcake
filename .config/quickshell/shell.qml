//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import QtQuick
import "theme"

ShellRoot {
    id: root

    readonly property string homeDir: Quickshell.env("HOME")

    // Top Bar Components for all screens
    Variants {
        model: Quickshell.screens
        delegate: Bar {
            visible: globalState.barMonitors.includes("all") || globalState.barMonitors.includes(modelData.name)
        }
    }

    // Bottom Dock for all screens
    Variants {
        model: Quickshell.screens
        delegate: Dock {
            visible: globalState.dockMonitors.includes("all") || globalState.dockMonitors.includes(modelData.name)
        }
    }

    // Global State
    property real globalOpacity: 1.0
    property real barOpacity: 0.50
    property bool barTransparency: true

    function withOpacity(col) {
        if (!root.barTransparency) return col;
        return Qt.rgba(col.r, col.g, col.b, root.barOpacity);
    }

    Process {
        id: initTransparencyValues
        command: ["cat", root.homeDir + "/.config/cupcake/.transparency_values"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.length > 0) {
                    let lines = text.trim().split('\n');
                    for (let i = 0; i < lines.length; i++) {
                        if (lines[i].startsWith('OPACITY=')) root.globalOpacity = parseFloat(lines[i].split('=')[1]);
                    }
                }
            }
        }
    }

    Scope {
        id: globalState
        property var barMonitors: ["all"]
        property var dockMonitors: ["all"]
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
        property bool settingsOpen: false
    }

    Process {
        id: initBarTransparency
        command: ["cat", root.homeDir + "/.config/cupcake/.bar_transparency"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { root.barTransparency = (text.trim() === "true"); }
            }
        }
    }
    Timer { interval: 500; running: true; repeat: true; onTriggered: initBarTransparency.running = true }

    Process {
        id: initBarOpacity
        command: ["cat", root.homeDir + "/.config/cupcake/.bar_opacity"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { let v = parseFloat(text.trim()); if (!isNaN(v)) root.barOpacity = v; }
            }
        }
    }
    Timer { interval: 500; running: true; repeat: true; onTriggered: initBarOpacity.running = true }

    Process {
        id: initMonitorTargets
        command: ["bash", "-c", "cat ~/.config/cupcake/.bar_monitors 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_monitors 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.length > 0) {
                    let parts = text.trim().split('---');
                    let barStr = parts[0] ? parts[0].trim() : "";
                    let dockStr = parts[1] ? parts[1].trim() : "";
                    if (barStr !== "") globalState.barMonitors = barStr.split(',');
                    if (dockStr !== "") globalState.dockMonitors = dockStr.split(',');
                }
            }
        }
    }

    IpcHandler {
        target: "theme"
        function reload() {
            if (globalState.settingsOpen) {
                Quickshell.execDetached(["bash", "-c", "echo 1 > /tmp/cupcake_settings"]);
            }
            Quickshell.reload(false);
        }
    }

    IpcHandler {
        target: "dock"
        function setMonitors(monitorsStr: string) {
            globalState.dockMonitors = monitorsStr.split(',');
        }
    }

    IpcHandler {
        target: "aipanel"
        function toggle() {
            globalState.aiPanelVisible = !globalState.aiPanelVisible;
        }
    }

    IpcHandler {
        target: "notifpanel"
        function toggle(): void {
            globalState.notifPanelVisible = !globalState.notifPanelVisible;
        }
    }

    GlobalShortcut {
        name: "notifpanel_toggle"
        onPressed: {
            globalState.notifPanelVisible = !globalState.notifPanelVisible;
        }
    }

    GlobalShortcut {
        name: "aipanel_toggle"
        onPressed: {
            globalState.aiPanelVisible = !globalState.aiPanelVisible;
        }
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
