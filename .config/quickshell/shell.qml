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
    function setGlobalDockRadius(c: int) {
        globalState.dockRadius = c;
    }

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
        property bool dockAutoHide: false
        property bool dockReserveSpace: false
        property string dockLauncherPosition: "Start"
        property bool dockShowDots: true
        property bool dockPinnedAppsEnabled: true
        property var dockPinnedApps: [
            { appId: "firefox", exec: "firefox", name: "Firefox" },
            { appId: "kitty", exec: "kitty", name: "Terminal" },
            { appId: "org.gnome.Nautilus", exec: "nautilus", name: "Files" },
            { appId: "code", exec: "code", name: "Code" }
        ]
        property bool dockMagnificationEnabled: false
        property real dockMagnificationScale: 1.5
        property var dockRadius: 20
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

    property real dockOpacity: 0.50
    Process {
        id: initDockOpacity
        command: ["cat", root.homeDir + "/.config/cupcake/.dock_opacity"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { let v = parseFloat(text.trim()); if (!isNaN(v)) root.dockOpacity = v; }
            }
        }
    }
    Timer { interval: 500; running: true; repeat: true; onTriggered: initDockOpacity.running = true }

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

    Process {
        id: initDockSettings
        command: ["bash", "-c", "cat ~/.config/cupcake/.dock_autohide 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_reserve_space 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_launcher_position 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_show_dots 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_magnification_enabled 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_magnification_scale 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_shape 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_pinned_apps_enabled 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_pinned_apps 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    let parts = text.trim().split('---');
                    if (parts[0]) globalState.dockAutoHide = (parts[0].trim() === "true");
                    if (parts[1]) globalState.dockReserveSpace = (parts[1].trim() === "true");
                    if (parts[2] && parts[2].trim() !== "") globalState.dockLauncherPosition = parts[2].trim();
                    if (parts[3] && parts[3].trim() !== "") globalState.dockShowDots = (parts[3].trim() === "true");
                    if (parts[4] && parts[4].trim() !== "") globalState.dockMagnificationEnabled = (parts[4].trim() === "true");
                    if (parts[5] && parts[5].trim() !== "") globalState.dockMagnificationScale = parseFloat(parts[5].trim());
                    if (parts[6] && parts[6].trim() !== "") {
                        globalState.dockRadius = parseInt(parts[6].trim());
                    }
                    if (parts[7] && parts[7].trim() !== "") globalState.dockPinnedAppsEnabled = (parts[7].trim() === "true");
                    if (parts[8] && parts[8].trim() !== "") {
                        try {
                            globalState.dockPinnedApps = JSON.parse(parts[8].trim());
                        } catch(e) {}
                    }
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
        function setAutoHide(enabled: bool) {
            globalState.dockAutoHide = enabled;
        }
        function setReserveSpace(enabled: bool) {
            globalState.dockReserveSpace = enabled;
        }
        function setLauncherPosition(position: string) {
            globalState.dockLauncherPosition = position;
        }
        function setShowDots(show: bool) {
            globalState.dockShowDots = show;
        }
        function setMagnificationEnabled(enabled: bool) {
            globalState.dockMagnificationEnabled = enabled;
        }
        function setMagnificationScale(scale: real) {
            globalState.dockMagnificationScale = scale;
        }
        function setDockShape(c: int) {
            root.setGlobalDockRadius(c);
        }
        function setPinnedAppsEnabled(enabled: bool) {
            globalState.dockPinnedAppsEnabled = enabled;
        }
        function setPinnedAppsEncoded(encoded: string) {
            try {
                let jsonStr = decodeURIComponent(encoded);
                let newArr = JSON.parse(jsonStr);
                globalState.dockPinnedApps = []; // force visual flush
                Qt.callLater(function() {
                    globalState.dockPinnedApps = newArr;
                });
            } catch(e) {
                console.log("Failed to parse pinned apps JSON:", e);
            }
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
