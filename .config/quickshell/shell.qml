//@ pragma UseQApplication
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import QtQuick
import "theme"
import "modules/panels"
import "modules/panels/modular"
import "modules/settings"
import "modules/common"
import "modules/solidboard"

ShellRoot {
    id: root

    readonly property string homeDir: Quickshell.env("HOME")

    // Load tabler-icons font explicitly at root level so all child components can use it reliably
    FontLoader {
        id: tablerIconsFont
        source: "file://" + root.homeDir + "/.local/share/fonts/tabler-icons.ttf"
    }
    // Top Bar Components for all screens
    function setGlobalDockRadius(c: int) {
        globalState.dockRadius = c;
    }

    // ⚠️ STRICT DIRECTIVE / AGENT LOCK: PILL BAR (Bar.qml) IS TOTALLY DISABLED & ARCHIVED in modules/panels/archive/
    // DO NOT re-enable or instantiate Bar { ... } unless explicitly instructed by the USER.

    Variants {
        model: Quickshell.screens
        delegate: BarSolid {
            visible: globalState.barVisible && !!globalState.barMonitors && (globalState.barMonitors.includes("all") || (modelData && globalState.barMonitors.includes(modelData.name)))
        }
    }

    // Standalone Notification Island (Always on Top Right of the screen)
    Variants {
        model: Quickshell.screens
        delegate: NotificationIsland {}
    }

    // Control Center for solid bar
    Variants {
        model: Quickshell.screens
        delegate: ControlCenterSolid {
            // Note: visible is managed internally by ControlCenterSolid.qml
        }
    }


    // Bottom Dock for all screens
    Variants {
        model: Quickshell.screens
        delegate: Dock {
            visible: !(Theme.barPosition === "Below" || Theme.barPosition === "bottom" || Theme.barPosition === "Bottom") && !!globalState.dockMonitors && (globalState.dockMonitors.includes("all") || (modelData && globalState.dockMonitors.includes(modelData.name)))
        }
    }

    // Wallpaper dim overlay for all screens
    Variants {
        model: Quickshell.screens
        delegate: WallpaperOverlay {}
    }

    // Global State
    property real globalOpacity: 1.0
    property real barOpacity: 1.0
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
        signal closeAllDropdowns()
        property bool anyBarDropdownOpen: false
        property string tablerIconsFamily: tablerIconsFont.name !== "" ? tablerIconsFont.name : "tabler-icons"
        property string barStyle: "solid"
        property bool barVisible: true
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
        property int dockIconSize: 50
        property int dockMainAxisPadding: 0
        property int dockCrossAxisPadding: 5
        property int dockItemSpacing: 11
        property int dockEndsMargin: 10
        property int dockEdgeMargin: 10
        property bool aiPanelVisible: false
        property bool notifPanelVisible: false
        property bool powerMenuOpen: false
        property var notifications: notifServer.trackedNotifications
        property var popups: []
        property var activePopup: null
        property real activeNotifWidth: 352
        property real notifProgress: 0.0
        property real clockPillWidth: 150
        property real islandWidth: 150
        property string clockString: ""
        property bool closingIsland: false
        property bool hideIsland: false
        property bool settingsOpen: false
        property bool overviewOpen: false
        property bool solidBoardOpen: false
        property bool powerDropdownOpen: false
        property bool clipboardOpen: false
        property real dimOverlay: 0.0
        property real notifPanelOpacity: 0.90
        property bool popupHovered: false
        onPopupHoveredChanged: {
            if (popupHovered) {
                islandTimer.stop();
                islandHideTimer.stop();
                islandCloseTimer.stop();
                closingIsland = false;
                hideIsland = false;
            } else {
                if (popups.length > 0) {
                    islandTimer.restart();
                }
            }
        }
    }

    property real dockOpacity: 0.50
    property real osdOpacity: 0.95
    property real ccOpacity: 0.85
    property real overviewOpacity: 0.85
    property int overviewTabs: 5
    property real overviewScale: 0.14

    IpcHandler {
        target: "opacity"
        function setBarTransparency(val: string) { root.barTransparency = (val === "true"); }
        function setBarOpacity(val: real) { root.barOpacity = val; }
        function setDockOpacity(val: real) { root.dockOpacity = val; }
        function setOsdOpacity(val: real) { root.osdOpacity = val; }
        function setCcOpacity(val: real) { root.ccOpacity = val; }
        function setOverviewOpacity(val: real) { root.overviewOpacity = val; }
        function setOverviewTabs(val: int) { root.overviewTabs = val; }
        function setOverviewScale(val: real) { root.overviewScale = val; }
        function setDimOverlay(val: real) { globalState.dimOverlay = val; }
        function setNotifOpacity(val: real) { globalState.notifPanelOpacity = val; }
    }

    Process {
        id: initShellConfigs
        command: ["bash", "-c", "cat ~/.config/cupcake/.dim_overlay 2>/dev/null; echo '---'; cat ~/.config/cupcake/.notif_panel_opacity 2>/dev/null; echo '---'; cat ~/.config/cupcake/.bar_transparency 2>/dev/null; echo '---'; cat ~/.config/cupcake/.bar_opacity 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_opacity 2>/dev/null; echo '---'; cat ~/.config/cupcake/.osd_opacity 2>/dev/null; echo '---'; cat ~/.config/cupcake/.cc_opacity 2>/dev/null; echo '---'; cat ~/.config/cupcake/.overview_opacity 2>/dev/null; echo '---'; cat ~/.config/cupcake/.overview_tabs 2>/dev/null; echo '---'; cat ~/.config/cupcake/.overview_scale 2>/dev/null || exit 0"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                let parts = text.trim().split('---');
                if (parts[0]) { let v = parseFloat(parts[0].trim()); if (!isNaN(v)) globalState.dimOverlay = v; }
                if (parts[1]) { let v = parseFloat(parts[1].trim()); if (!isNaN(v)) globalState.notifPanelOpacity = v; }
                if (parts[2]) { root.barTransparency = (parts[2].trim() === "true"); }
                if (parts[3]) { let v = parseFloat(parts[3].trim()); if (!isNaN(v)) root.barOpacity = v; }
                if (parts[4]) { let v = parseFloat(parts[4].trim()); if (!isNaN(v)) root.dockOpacity = v; }
                if (parts[5]) { let v = parseFloat(parts[5].trim()); if (!isNaN(v)) root.osdOpacity = v; }
                if (parts[6]) { let v = parseFloat(parts[6].trim()); if (!isNaN(v)) root.ccOpacity = v; }
                if (parts[7]) { let v = parseFloat(parts[7].trim()); if (!isNaN(v)) root.overviewOpacity = v; }
                if (parts[8]) { let v = parseInt(parts[8].trim()); if (!isNaN(v) && v > 0) root.overviewTabs = v; }
                if (parts[9]) { let v = parseFloat(parts[9].trim()); if (!isNaN(v) && v > 0) root.overviewScale = v; }
                globalState.barStyle = "solid";
            }
        }
    }

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
        command: ["bash", "-c", "cat ~/.config/cupcake/.dock_autohide 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_reserve_space 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_launcher_position 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_show_dots 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_magnification_enabled 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_magnification_scale 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_shape 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_pinned_apps_enabled 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_pinned_apps 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_icon_size 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_main_axis_padding 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_cross_axis_padding 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_item_spacing 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_ends_margin 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_edge_margin 2>/dev/null"]
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
                    if (parts[9] && parts[9].trim() !== "") globalState.dockIconSize = parseInt(parts[9].trim());
                    if (parts[10] && parts[10].trim() !== "") globalState.dockMainAxisPadding = parseInt(parts[10].trim());
                    if (parts[11] && parts[11].trim() !== "") globalState.dockCrossAxisPadding = parseInt(parts[11].trim());
                    if (parts[12] && parts[12].trim() !== "") globalState.dockItemSpacing = parseInt(parts[12].trim());
                    if (parts[13] && parts[13].trim() !== "") globalState.dockEndsMargin = parseInt(parts[13].trim());
                    if (parts[14] && parts[14].trim() !== "") globalState.dockEdgeMargin = parseInt(parts[14].trim());
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
        function setDockIconSize(size: int) {
            globalState.dockIconSize = size;
        }
        function setDockMainAxisPadding(pad: int) {
            globalState.dockMainAxisPadding = pad;
        }
        function setDockCrossAxisPadding(pad: int) {
            globalState.dockCrossAxisPadding = pad;
        }
        function setDockItemSpacing(space: int) {
            globalState.dockItemSpacing = space;
        }
        function setDockEndsMargin(margin: int) {
            globalState.dockEndsMargin = margin;
        }
        function setDockEdgeMargin(margin: int) {
            globalState.dockEdgeMargin = margin;
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
        target: "wallpaper"
        function setDimOverlay(val: real) {
            globalState.dimOverlay = val;
        }
    }

    IpcHandler {
        target: "bar"
        function toggle() {
            globalState.barVisible = !globalState.barVisible;
        }
        function show() {
            globalState.barVisible = true;
        }
        function hide() {
            globalState.barVisible = false;
        }
    }

    GlobalShortcut {
        name: "bar_toggle"
        onPressed: {
            globalState.barVisible = !globalState.barVisible;
        }
    }

    IpcHandler {
        target: "overview"
        function toggle() {
            globalState.overviewOpen = !globalState.overviewOpen;
        }
    }

    IpcHandler {
        target: "aipanel"
        function toggle() {
            globalState.aiPanelVisible = !globalState.aiPanelVisible;
        }
    }

    IpcHandler {
        target: "solidboard"
        function toggle() {
            globalState.solidBoardOpen = !globalState.solidBoardOpen;
        }
    }

    IpcHandler {
        target: "clipboard"
        function toggle() {
            globalState.clipboardOpen = !globalState.clipboardOpen;
        }
    }

    GlobalShortcut {
        name: "clipboard_toggle"
        onPressed: {
            globalState.clipboardOpen = !globalState.clipboardOpen;
        }
    }

    IpcHandler {
        target: "notifpanel"
        function toggle() {
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

    GlobalShortcut {
        name: "powermenu_toggle"
        onPressed: {
            globalState.powerMenuOpen = !globalState.powerMenuOpen;
        }
    }

    GlobalShortcut {
        name: "solidboard_toggle"
        onPressed: {
            globalState.solidBoardOpen = !globalState.solidBoardOpen;
        }
    }

    // Popups & Panels
    NotificationPanel {}
    Osd {}
    AiPanel {}

    // Overview (workspace switcher)
    Variants {
        model: Quickshell.screens
        delegate: Overview {}
    }

    GlobalShortcut {
        name: "overview_toggle"
        onPressed: { globalState.overviewOpen = !globalState.overviewOpen }
    }

    // Initialize Quickshell services
    NotificationServer {
        id: notifServer
        onNotification: notif => {
            notif.tracked = true;
            globalState.closingIsland = false;
            globalState.hideIsland = false;

            // Automatically clean up popup reference when closed/dismissed
            if (notif.closed) {
                notif.closed.connect(() => {
                    let cur = globalState.popups.filter(p => p !== notif);
                    globalState.popups = cur;
                });
            }

            // Only queue notifications with actual content (filters out blank ghosts)
            let hasContent = (notif.summary && notif.summary.trim().length > 0) ||
                             (notif.body && notif.body.trim().length > 0) ||
                             (notif.appName && notif.appName.trim().length > 0);
            if (hasContent) {
                globalState.popups = [notif].concat(globalState.popups.filter(p => p !== notif));
            }
        }
    }

    // ── Clipboard Notification Watcher ──
    Process {
        id: clipNotifProcess
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/clip_notify.sh"]
        running: true
    }
}
