import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
import QtQuick.Controls
import "../../theme"
import "../common"
import Quickshell.Services.Mpris
import "modular"
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: bar
    property var modelData
    screen: modelData

    readonly property bool isBottom: Theme.barPosition === "Below" || Theme.barPosition === "bottom" || Theme.barPosition === "Bottom"

    anchors { 
        top: !bar.isBottom
        bottom: bar.isBottom
        left: true
        right: true 
    }
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    property bool anyDropdownOpen: bar.dropdownOpen || bar.netDropdownOpen || bar.musicDropdownOpen || globalState.powerDropdownOpen || globalState.solidBoardOpen || globalState.clipboardOpen
    WlrLayershell.layer: WlrLayer.Top
    exclusiveZone: 40
    implicitHeight: bar.screen.height - 40
    color: "transparent"
    mask: Region {
        Region { item: solidBar }
        Region { item: clockSplitPill }
        Region { item: powerSplitPill }
        Region { item: volBrightSplitPill }
        Region { item: netSplitPill }
        Region { item: musicSplitPill }
        Region { item: clipboardSplitPill }
        Region { item: notifDetachedPod }
    }

    onAnyDropdownOpenChanged: {
        globalState.anyBarDropdownOpen = anyDropdownOpen;
    }

    Connections {
        target: globalState
        function onCloseAllDropdowns() {
            bar.dropdownOpen = false;
            bar.netDropdownOpen = false;
            bar.musicDropdownOpen = false;
            globalState.powerDropdownOpen = false;
            globalState.solidBoardOpen = false;
            globalState.clipboardOpen = false;
        }
    }

    property real baseHeight: startHeight
    property bool dropdownOpen: false
    property bool netDropdownOpen: false
    property bool musicDropdownOpen: false
    property var barActivePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool isMusicPlaying: barActivePlayer !== null && (barActivePlayer.playbackState === 1 || barActivePlayer.isPlaying) && (barActivePlayer.trackTitle !== "")
    property bool keepMusicAlive: !hasNotifPopup && (isMusicPlaying || musicDropdownOpen)
    onKeepMusicAliveChanged: {
        if (!keepMusicAlive) musicDropdownOpen = false;
    }
    property real extraHeight: 0
    
    Connections {
        target: globalState
        function onSolidBoardOpenChanged() {
            if (globalState.solidBoardOpen) {
                bar.dropdownOpen = false;
                bar.netDropdownOpen = false;
                globalState.powerDropdownOpen = false;
                globalState.clipboardOpen = false;
            }
        }
        function onPowerDropdownOpenChanged() {
            if (globalState.powerDropdownOpen) {
                bar.dropdownOpen = false;
                bar.netDropdownOpen = false;
                globalState.solidBoardOpen = false;
                globalState.clipboardOpen = false;
            }
        }
        function onClipboardOpenChanged() {
            if (globalState.clipboardOpen) {
                bar.dropdownOpen = false;
                bar.netDropdownOpen = false;
                globalState.solidBoardOpen = false;
                globalState.powerDropdownOpen = false;
            }
        }
    }

    onDropdownOpenChanged: {
        if (dropdownOpen) {
            netDropdownOpen = false;
            globalState.solidBoardOpen = false;
            globalState.powerDropdownOpen = false;
            globalState.clipboardOpen = false;
        }
    }

    onNetDropdownOpenChanged: {
        if (netDropdownOpen) {
            dropdownOpen = false;
            globalState.solidBoardOpen = false;
            globalState.powerDropdownOpen = false;
            globalState.clipboardOpen = false;
        }
    }

    Connections {
        target: Hyprland
        function onActiveWindowChanged() {
            if (anyDropdownOpen) {
                bar.dropdownOpen = false;
                bar.netDropdownOpen = false;
                bar.musicDropdownOpen = false;
                globalState.powerDropdownOpen = false;
                globalState.solidBoardOpen = false;
                globalState.clipboardOpen = false;
            }
        }
    }

    // Shared styling
    property color bg: Theme.colSurface
    property color fg: Theme.colOnSurface
    FontLoader {
        id: localTablerFont
        source: Qt.resolvedUrl("file://" + Quickshell.env("HOME") + "/.local/share/fonts/tabler-icons.ttf")
    }
    property string fontName: "tabler-icons"

    property real barOpacity: Theme.barOpacity
    property bool barTransparency: Theme.barTransparency

    Process {
        id: initBarConfigs
        command: ["bash", "-c", "cat ~/.config/cupcake/.bar_transparency 2>/dev/null; echo '---'; cat ~/.config/cupcake/.bar_opacity 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                let p = text.trim().split('---');
                if (p[0] && p[0].trim() !== "") {
                    let bt = (p[0].trim() !== "false");
                    bar.barTransparency = bt;
                    Theme.barTransparency = bt;
                }
                if (p[1] && p[1].trim() !== "") {
                    let v = parseFloat(p[1].trim());
                    if (!isNaN(v)) {
                        bar.barOpacity = v;
                        Theme.barOpacity = v;
                    }
                }
            }
        }
    }

    FileView {
        id: barOpacityFileView
        path: Quickshell.env("HOME") + "/.config/cupcake/.bar_opacity"
        watchChanges: true
        onFileChanged: { reload(); }
        onTextChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let v = parseFloat(t.trim());
                if (!isNaN(v)) {
                    bar.barOpacity = v;
                    Theme.barOpacity = v;
                }
            }
        }
        onLoadedChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let v = parseFloat(t.trim());
                if (!isNaN(v)) {
                    bar.barOpacity = v;
                    Theme.barOpacity = v;
                }
            }
        }
    }

    FileView {
        id: barTransFileView
        path: Quickshell.env("HOME") + "/.config/cupcake/.bar_transparency"
        watchChanges: true
        onFileChanged: { reload(); }
        onTextChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let bt = (t.trim() !== "false");
                bar.barTransparency = bt;
                Theme.barTransparency = bt;
            }
        }
        onLoadedChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let bt = (t.trim() !== "false");
                bar.barTransparency = bt;
                Theme.barTransparency = bt;
            }
        }
    }

    property color pillColor: Theme.isPitchBlack
        ? (bar.barOpacity < 1.0 ? Qt.rgba(0, 0, 0, bar.barOpacity) : "#000000")
        : (bar.barOpacity < 1.0 ? Qt.rgba(bg.r, bg.g, bg.b, bar.barOpacity) : (bar.barTransparency ? Qt.rgba(bg.r, bg.g, bg.b, bar.barOpacity) : Qt.rgba(bg.r, bg.g, bg.b, 1.0)))

    // Hardware data
    property string cpuStr: "0"
    property string ramStr: "0"
    property string swapStr: "0"
    property string tempStr: "0"
    property string volStr: "0"
    property string brightStr: "0"
    property string batStr: "100"
    property string netStr: "0 KB/s"
    property string netRxStr: "0 KB/s"
    property string netTxStr: "0 KB/s"
    // CPU delta tracking (for accurate /proc/stat measurement)
    property int prevCpuIdle: 0
    property int prevCpuTotal: 0
    property bool isWifi: false
    property bool isWired: false
    property bool isBluetooth: false
    property bool isBluetoothConnected: false
    property bool isHotspot: false
    property int netDropdownTab: 1 // 1: Wi-Fi, 3: Bluetooth, 2: Hotspot, 0: Ethernet
    property bool isVolMuted: false
    property string activeSinkName: ""
    property var sinkList: []

    property int activeWsId: 1
    property string activeWinTitle: ""
    property var occupiedWsMap: ({})

    Process {
        id: hyprStateProc
        command: ["bash", "-c", "hyprctl activeworkspace -j; echo '---'; hyprctl activewindow -j; echo '---'; hyprctl workspaces -j"]
        running: false
        stdout: SplitParser {
            onRead: (data) => {
                try {
                    let parts = data.split("---");
                    if (parts.length >= 3) {
                        let wsJson = JSON.parse(parts[0].trim());
                        if (wsJson && wsJson.id) bar.activeWsId = wsJson.id;

                        let winJson = JSON.parse(parts[1].trim());
                        if (winJson && winJson.title) bar.activeWinTitle = winJson.title;
                        else if (winJson && winJson.title === "") bar.activeWinTitle = "";

                        let allWsJson = JSON.parse(parts[2].trim());
                        if (Array.isArray(allWsJson)) {
                            let map = {};
                            allWsJson.forEach(w => { map[w.id] = true; });
                            bar.occupiedWsMap = map;
                        }
                    }
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 300
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!hyprStateProc.running) hyprStateProc.running = true;
        }
    }

    function getVolumeIcon(volVal, isMuted) {
        if (isMuted) return "";
        var v = parseFloat(volVal) || 0;
        if (v <= 0) return "";
        if (v < 50) return "";
        return "";
    }

    function getBrightnessIcon(brightVal) {
        var b = parseFloat(brightVal) || 0;
        if (b < 33) return "";
        if (b < 66) return "";
        return "";
    }

    Process {
        id: volMuteCheckProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                bar.isVolMuted = text.includes("[MUTED]");
            }
        }
    }

    Process {
        id: sinkFetchProc
        command: ["pactl", "-f", "json", "list", "sinks"]
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(text);
                        bar.sinkList = parsed;
                    } catch (e) {}
                }
            }
        }
    }

    Process {
        id: activeSinkProc
        command: ["pactl", "get-default-sink"]
        stdout: StdioCollector {
            onTextChanged: {
                if (text) bar.activeSinkName = text.trim();
            }
        }
    }
    SystemClock { id: timeClock; precision: SystemClock.Minutes }

    readonly property real screenW: bar.screen ? bar.screen.width : (bar.width > 0 ? bar.width : 1920)
    readonly property real barW: bar.screenW - 200
    readonly property real barX: 100
    readonly property real startW: 100
    readonly property real startX: (bar.screenW - bar.startW) / 2
    readonly property real midY: 10
    readonly property real startHeight: 30
    readonly property real barHeight: 30
    readonly property real startRadius: 15
    readonly property real barRadius: 15

    // Power split pill dimensions
    readonly property real powerPillGap: 8   // gap between bar and power pill
    property real powerSplitOffset: 0       // grows with OutBack to push bar left
    Behavior on powerSplitOffset {
        NumberAnimation { duration: 1400; easing.type: Easing.OutExpo }
    }
    onPowerSplitOffsetChanged: {
        // keep mask updated
    }

    Connections {
        target: globalState
        function onPowerDropdownOpenChanged() {
            // powerSplitPill drives its own width; we track it via a binding below
        }
    }

    // Dynamic Island Notification state & Synchronized Single-Driver Motion
    property var notifPopups: (globalState && globalState.popups) ? globalState.popups : []
    property bool hasNotifPopup: notifPopups.length > 0 && !globalState.hideIsland

    // ── THE SINGLE DRIVER FOR SYNCHRONIZED LIQUID MOTION ──
    property real notifAnimWidth: hasNotifPopup ? 320 : 0
    Behavior on notifAnimWidth {
        NumberAnimation {
            duration: 1200
            easing.type: Easing.OutCubic
        }
    }

    // ─────────────────────────────────────────────────────
    //  MORPHING BAR (Starts from cupcake logo pill, expands into solid bar, morphs into Dynamic Island for notifications)
    // ─────────────────────────────────────────────────────
    // MAIN TOP BAR (Rock-Solid Fixed Full Width Geometry)
    // ─────────────────────────────────────────────────────
    Item {
        id: solidBar
        y: bar.isBottom ? (bar.height - (bar.baseHeight + bar.extraHeight) - bar.midY) : bar.midY
        Behavior on y { enabled: !expandAnim.running; NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
        x: expandAnim.running ? bar.startX : bar.barX
        Behavior on x { enabled: !expandAnim.running; NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
        width: bar.isBottom ? bar.barW : (bar.barW - (bar.notifAnimWidth > 0 ? (bar.notifAnimWidth + 8) : 0))
        height: (bar.baseHeight + bar.extraHeight)
        Behavior on height { enabled: !expandAnim.running; NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
        clip: false

        Rectangle {
            id: solidBarBg
            anchors.fill: parent
            radius: height / 2
            color: bar.pillColor
            visible: !squareBR
            readonly property bool squareBR: globalState.powerDropdownOpen && Theme.barDropdownStyle === "Attached"
        }

        Shape {
            id: solidBarAttachedShape
            anchors.fill: parent
            visible: solidBarBg.squareBR
            readonly property real r: height / 2
            readonly property real w: width
            readonly property real h: height

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: bar.pillColor
                startX: solidBarAttachedShape.r
                startY: 0

                PathLine { x: solidBarAttachedShape.w - solidBarAttachedShape.r; y: 0 }
                PathArc {
                    x: solidBarAttachedShape.w
                    y: solidBarAttachedShape.r
                    radiusX: solidBarAttachedShape.r
                    radiusY: solidBarAttachedShape.r
                    useLargeArc: false
                    direction: PathArc.Clockwise
                }
                PathLine { x: solidBarAttachedShape.w; y: solidBarAttachedShape.h }
                PathLine { x: solidBarAttachedShape.r; y: solidBarAttachedShape.h }
                PathArc {
                    x: 0
                    y: solidBarAttachedShape.h - solidBarAttachedShape.r
                    radiusX: solidBarAttachedShape.r
                    radiusY: solidBarAttachedShape.r
                    useLargeArc: false
                    direction: PathArc.Clockwise
                }
                PathLine { x: 0; y: solidBarAttachedShape.r }
                PathArc {
                    x: solidBarAttachedShape.r
                    y: 0
                    radiusX: solidBarAttachedShape.r
                    radiusY: solidBarAttachedShape.r
                    useLargeArc: false
                    direction: PathArc.Clockwise
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: anyDropdownOpen
            onClicked: {
                if (globalState.powerDropdownOpen) globalState.powerDropdownOpen = false;
                if (globalState.solidBoardOpen) globalState.solidBoardOpen = false;
                if (bar.dropdownOpen) bar.dropdownOpen = false;
                if (bar.netDropdownOpen) bar.netDropdownOpen = false;
            }
        }

        // Solid Bar Modules (Permanently visible)
        RowLayout {
            id: contentLayout
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            anchors.leftMargin: 13
            anchors.rightMargin: 13
            height: bar.barHeight
            spacing: 0
            opacity: 1.0
            visible: opacity > 0

            // ── LEFT: Workspaces (Glowing Halo Ring Style) ────────
            Item {
                id: workspacesContainer
                Layout.preferredWidth: workspacesRow.implicitWidth
                Layout.preferredHeight: 30
                Layout.alignment: Qt.AlignVCenter

                Row {
                    id: workspacesRow
                    spacing: 10
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: 5
                        delegate: Item {
                            width: 14
                            height: 30
                            property int wsId: index + 1
                            property bool isFocused: (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0) ? Hyprland.focusedWorkspace.id === wsId : (bar.activeWsId === wsId)
                            property bool isOccupied: isFocused || (Hyprland.workspaces && Hyprland.workspaces.values.length > 0 ? Hyprland.workspaces.values.some(ws => ws.id === wsId) : (bar.occupiedWsMap && bar.occupiedWsMap[wsId] ? true : false))

                            // Clean Core Workspace Dot
                            Rectangle {
                                anchors.centerIn: parent
                                width: isFocused ? 6 : (isOccupied ? 5 : 4)
                                height: width
                                radius: width / 2
                                color: isFocused ? Theme.colPrimary : (isOccupied ? Qt.rgba(fg.r, fg.g, fg.b, 0.7) : Qt.rgba(fg.r, fg.g, fg.b, wsMouse.containsMouse ? 0.45 : 0.25))

                                Behavior on color  { ColorAnimation  { duration: 180 } }
                                Behavior on width  { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                id: wsMouse
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    console.log("CLICKED WORKSPACE: " + wsId);
                                    bar.activeWsId = wsId;
                                    dispatchProc.cmd = "hyprctl dispatch 'hl.dsp.focus({workspace = " + wsId + "})'";
                                    dispatchProc.running = true;
                                }
                            }
                        }
                    }
                }
            }
            
            // ── LEFT: Window Title ────────


            Text {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 12
                Layout.maximumWidth: 300
                elide: Text.ElideRight
                visible: (Hyprland.activeToplevel && Hyprland.activeToplevel.title !== "") || (bar.activeWinTitle && bar.activeWinTitle !== "")
                text: (Hyprland.activeToplevel && Hyprland.activeToplevel.title !== "") ? Hyprland.activeToplevel.title : (bar.activeWinTitle ? bar.activeWinTitle : "")
                font.family: Theme.defaultFontFamily
                font.pixelSize: 13
                font.weight: Theme.defaultFontWeight
                color: Qt.rgba(fg.r, fg.g, fg.b, 0.6)
            }

            // Spacer
            Item { Layout.fillWidth: true }

            // ── RIGHT: Network & Connectivity Pill ──────────────────
            Item {
                id: networkContainer
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: networkRowContent.implicitWidth
                implicitHeight: 20
                Layout.preferredWidth: implicitWidth
                clip: true
                opacity: 1.0
                visible: true

                Behavior on Layout.preferredWidth {
                    NumberAnimation {
                        duration: 380
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.08, 0.85, 0.2, 1.0, 1.0, 1.0]
                    }
                }

                Row {
                    id: networkRowContent
                    height: 20
                    spacing: 5
                    anchors.verticalCenter: parent.verticalCenter

                    // Helper component for interactive top bar connectivity icon
                    component NetBarIcon: Item {
                        property int tabId: 1
                        property string iconCode: "\ueb52"
                        property bool forceVisible: false
                        property color iconColor: fg
                        
                        readonly property bool isShown: forceVisible || bar.netDropdownOpen
                        visible: width > 0 || opacity > 0.01
                        width: isShown ? 22 : 0
                        height: 22
                        anchors.verticalCenter: parent.verticalCenter
                        clip: true

                        Behavior on width {
                            NumberAnimation {
                                duration: 280
                                easing.type: Easing.OutCubic
                            }
                        }

                        Rectangle {
                            id: iconBg
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            radius: 11
                            property bool isSelected: bar.netDropdownOpen && bar.netDropdownTab === tabId
                            color: isSelected ? Qt.rgba(fg.r, fg.g, fg.b, 0.16) : (netIconMa.containsMouse ? Qt.rgba(fg.r, fg.g, fg.b, 0.08) : "transparent")
                            scale: parent.isShown ? 1.0 : 0.7
                            opacity: parent.isShown ? 1.0 : 0.0

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 220
                                    easing.type: Easing.OutQuad
                                }
                            }
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: iconCode
                                font.family: fontName
                                font.pixelSize: 13
                                color: iconBg.isSelected ? fg : (netIconMa.containsMouse ? fg : Qt.rgba(fg.r, fg.g, fg.b, 0.65))
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            MouseArea {
                                id: netIconMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (globalState.solidBoardOpen) globalState.solidBoardOpen = false;
                                    if (globalState.powerDropdownOpen) globalState.powerDropdownOpen = false;
                                    if (bar.dropdownOpen) bar.dropdownOpen = false;

                                    if (bar.netDropdownOpen && bar.netDropdownTab === tabId) {
                                        bar.netDropdownOpen = false;
                                    } else {
                                        bar.netDropdownTab = tabId;
                                        bar.netDropdownOpen = true;
                                    }
                                }
                            }
                        }
                    }

                    // 1. Wi-Fi
                    NetBarIcon {
                        tabId: 1
                        iconCode: "\ueb52"
                        forceVisible: isWifi || (!isWired && !isHotspot)
                        iconColor: (netSplitPill && netSplitPill.wifiSSID !== "Disconnected" && !netSplitPill.hasInternet) ? "#ff6b6b" : fg
                    }

                    // 2. Bluetooth
                    NetBarIcon {
                        tabId: 3
                        iconCode: isBluetoothConnected ? "\uecea" : "\uea37"
                        forceVisible: isBluetooth
                        iconColor: fg
                    }

                    // 3. Hotspot
                    NetBarIcon {
                        tabId: 2
                        iconCode: "\ued1b"
                        forceVisible: isHotspot
                        iconColor: fg
                    }

                    // 4. Ethernet
                    NetBarIcon {
                        tabId: 0
                        iconCode: "\uebd9"
                        forceVisible: isWired
                        iconColor: (netSplitPill && !netSplitPill.hasInternet) ? "#ff6b6b" : fg
                    }

                    // 5. Network Speed / Status Text
                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        height: 20
                        readonly property bool isNetCollapsed: bar.hasNotifPopup
                        width: isNetCollapsed ? 0 : netSpeedText.implicitWidth
                        clip: true
                        opacity: isNetCollapsed ? 0 : 1
                        visible: width > 0 || opacity > 0.01

                        Behavior on width {
                            NumberAnimation {
                                duration: 380
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: [0.08, 0.85, 0.2, 1.0, 1.0, 1.0]
                            }
                        }
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

                        Text {
                            id: netSpeedText
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                let isWifiConn = netSplitPill ? netSplitPill.wifiSSID !== "Disconnected" : false;
                                let hasInt = netSplitPill ? netSplitPill.hasInternet : true;
                                if (isWired) {
                                    return hasInt ? netStr : "No Internet";
                                } else if (isWifi && isWifiConn) {
                                    return hasInt ? netStr : "No Internet";
                                } else if (isHotspot) {
                                    return netStr;
                                } else {
                                    return "Disconnected";
                                }
                            }
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 13
                            font.weight: Theme.defaultFontWeight
                            color: {
                                let isWifiConn = netSplitPill ? netSplitPill.wifiSSID !== "Disconnected" : false;
                                let hasInt = netSplitPill ? netSplitPill.hasInternet : true;
                                let noInt = ((isWired || (isWifi && isWifiConn)) && !hasInt);
                                return noInt ? "#ff6b6b" : Qt.rgba(fg.r, fg.g, fg.b, 0.7);
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (globalState.solidBoardOpen) globalState.solidBoardOpen = false;
                                if (globalState.powerDropdownOpen) globalState.powerDropdownOpen = false;
                                if (bar.dropdownOpen) bar.dropdownOpen = false;
                                bar.netDropdownOpen = !bar.netDropdownOpen;
                            }
                        }
                    }
                }
            }

            // ── RIGHT: Dot Separator (Network -> Hardware) ────────
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                width: 3
                height: 3
                radius: 1.5
                color: Qt.rgba(fg.r, fg.g, fg.b, 0.3)
                opacity: 1.0
                visible: true
            }
            
            // ── RIGHT: Hardware Icons (Brightness & Sound) ────────
            Item {
                id: hardwareContainer
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: hardwareRow.implicitWidth + 12
                Layout.preferredWidth: implicitWidth
                height: 22
                opacity: 1.0
                visible: true

                Rectangle {
                    anchors.fill: parent
                    radius: 11
                    color: bar.dropdownOpen
                           ? Qt.rgba(fg.r, fg.g, fg.b, 0.16)
                           : ((bMouse.containsMouse || vMouse.containsMouse) ? Qt.rgba(fg.r, fg.g, fg.b, 0.08) : "transparent")
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Row {
                    id: hardwareRow
                    anchors.centerIn: parent
                    spacing: 10

                    // Brightness
                    MouseArea {
                        id: bMouse
                        width: childrenRect.width
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onEntered: { if (bar.brightStr === "0") lightProc.running = true; }
                        onClicked: {
                            let cur = bar.dropdownOpen;
                            if (globalState.solidBoardOpen) globalState.solidBoardOpen = false;
                            if (globalState.powerDropdownOpen) globalState.powerDropdownOpen = false;
                            if (bar.netDropdownOpen) bar.netDropdownOpen = false;
                            bar.dropdownOpen = !cur;
                        }
                        
                        Row {
                            height: 20
                            spacing: bMouse.containsMouse ? 4 : 0
                            Behavior on spacing { NumberAnimation { duration: 200 } }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: bar.getBrightnessIcon(bar.brightStr)
                                font.family: fontName
                                font.pixelSize: 14
                                color: fg
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: bar.brightStr + "%"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 12
                                font.weight: Theme.defaultFontWeight
                                color: Qt.rgba(fg.r, fg.g, fg.b, 0.7)
                                width: bMouse.containsMouse ? implicitWidth : 0
                                clip: true
                                Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutSine } }
                            }
                        }
                    }

                    // Volume
                    MouseArea {
                        id: vMouse
                        width: childrenRect.width
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onClicked: {
                            let cur = bar.dropdownOpen;
                            if (globalState.solidBoardOpen) globalState.solidBoardOpen = false;
                            if (globalState.powerDropdownOpen) globalState.powerDropdownOpen = false;
                            if (bar.netDropdownOpen) bar.netDropdownOpen = false;
                            bar.dropdownOpen = !cur;
                        }
                        
                        Row {
                            height: 20
                            spacing: vMouse.containsMouse ? 4 : 0
                            Behavior on spacing { NumberAnimation { duration: 200 } }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: bar.getVolumeIcon(bar.volStr, bar.isVolMuted)
                                font.family: fontName
                                font.pixelSize: 14
                                color: bar.isVolMuted ? Theme.colError : fg
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: bar.volStr + "%"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 12
                                font.weight: Theme.defaultFontWeight
                                color: bar.isVolMuted ? Theme.colError : Qt.rgba(fg.r, fg.g, fg.b, 0.7)
                                width: vMouse.containsMouse ? implicitWidth : 0
                                clip: true
                                Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutSine } }
                            }
                        }
                    }
                }
            }

            // ── RIGHT: Dot Separator (Hardware -> Tray) ────────
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 8 * opacity
                Layout.rightMargin: 8 * opacity
                width: 3 * opacity
                height: 3
                radius: 1.5
                color: Qt.rgba(fg.r, fg.g, fg.b, 0.3)
                opacity: sysTrayRepeater.count > 0 ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
            }

            // ── RIGHT: System Tray ────────
            Row {
                id: sysTrayRow
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: implicitWidth * opacity
                height: 20
                spacing: 8
                opacity: sysTrayRepeater.count > 0 ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }

                Repeater {
                    id: sysTrayRepeater
                    model: SystemTray.items
                    delegate: Item {
                        width: 13
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter

                        IconImage {
                            anchors.centerIn: parent
                            source: modelData.icon || ""
                            width: 13
                            height: 13
                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: bar.fg
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.LeftButton) {
                                    modelData.activate();
                                } else if (mouse.button === Qt.RightButton) {
                                    if (modelData.hasMenu) {
                                        var pos = mapToItem(bar.contentItem, mouse.x, mouse.y);
                                        modelData.display(bar, pos.x, pos.y);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── RIGHT: Clipboard Pill ────────
            Item {
                id: clipboardItem
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: sysTrayRepeater.count > 0 ? 6 : 0
                height: 22
                width: 22
                Layout.preferredWidth: 22
                opacity: 1.0
                visible: true

                Rectangle {
                    anchors.fill: parent
                    radius: 11
                    color: globalState.clipboardOpen
                           ? Qt.rgba(fg.r, fg.g, fg.b, 0.16)
                           : (clipMa.containsMouse ? Qt.rgba(fg.r, fg.g, fg.b, 0.08) : "transparent")
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "\uea6d"
                    font.family: fontName
                    font.pixelSize: 13
                    color: fg
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    id: clipMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let cur = globalState.clipboardOpen;
                        if (globalState.solidBoardOpen) globalState.solidBoardOpen = false;
                        if (globalState.powerDropdownOpen) globalState.powerDropdownOpen = false;
                        if (bar.dropdownOpen) bar.dropdownOpen = false;
                        if (bar.netDropdownOpen) bar.netDropdownOpen = false;
                        globalState.clipboardOpen = !cur;
                    }
                }
            }

            // ── RIGHT: Dot Separator (Clipboard -> Clock) ────────
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                width: 3
                height: 3
                radius: 1.5
                color: Qt.rgba(fg.r, fg.g, fg.b, 0.3)
                opacity: 1.0
                visible: true
            }

            // ── RIGHT: Clock ────────
            Item {
                id: clockItem
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: clockRow.implicitWidth + 12
                Layout.preferredWidth: implicitWidth
                height: 22
                opacity: 1.0
                visible: true

                Rectangle {
                    anchors.fill: parent
                    radius: 11
                    color: globalState.solidBoardOpen
                           ? Qt.rgba(fg.r, fg.g, fg.b, 0.16)
                           : (clockMouse.containsMouse ? Qt.rgba(fg.r, fg.g, fg.b, 0.08) : "transparent")
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    id: clockMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        let cur = globalState.solidBoardOpen;
                        if (globalState.powerDropdownOpen) globalState.powerDropdownOpen = false;
                        if (bar.dropdownOpen) bar.dropdownOpen = false;
                        if (bar.netDropdownOpen) bar.netDropdownOpen = false;
                        globalState.solidBoardOpen = !cur;
                    }
                }

                Row {
                    id: clockRow
                    height: 20
                    anchors.centerIn: parent
                    spacing: clockMouse.containsMouse ? 6 : 0
                    Behavior on spacing { NumberAnimation { duration: 200 } }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDateTime(timeClock.date, "hh:mm AP").replace(/ (AM|PM)/i, "")
                        font.family: Theme.appFontMono
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                        color: fg
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        width: clockMouse.containsMouse ? implicitWidth : 0
                        clip: true
                        Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutSine } }

                        Rectangle {
                            width: 1
                            height: 11
                            anchors.verticalCenter: parent.verticalCenter
                            color: Qt.rgba(fg.r, fg.g, fg.b, 0.3)
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Qt.formatDateTime(timeClock.date, "ddd , dd MMM / yyyy").toUpperCase()
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            font.weight: Font.Normal
                            font.letterSpacing: 0.5
                            color: Qt.rgba(fg.r, fg.g, fg.b, 0.65)
                        }
                    }
                }
            }

            // ── RIGHT: Dot Separator (Clock -> Power) ────────
            Rectangle {
                id: clockBulletMain
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                width: 3
                height: 3
                radius: 1.5
                color: Qt.rgba(fg.r, fg.g, fg.b, 0.3)
                opacity: 1.0
                visible: true
            }

            // ── RIGHT: Power Button ────────
            Item {
                id: powerPillItem
                Layout.alignment: Qt.AlignVCenter
                height: 22
                width: 22
                Layout.preferredWidth: 22
                opacity: 1.0
                visible: true

                Rectangle {
                    anchors.fill: parent
                    radius: 11
                    color: globalState.powerDropdownOpen
                           ? Qt.rgba(fg.r, fg.g, fg.b, 0.16)
                           : (powerMa.containsMouse ? Qt.rgba(fg.r, fg.g, fg.b, 0.08) : "transparent")
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "\ueb0d"
                    font.family: fontName
                    font.pixelSize: 14
                    color: globalState.powerDropdownOpen ? fg : (powerMa.containsMouse ? Theme.colError : fg)
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    id: powerMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let cur = globalState.powerDropdownOpen;
                        if (globalState.solidBoardOpen) globalState.solidBoardOpen = false;
                        if (bar.dropdownOpen) bar.dropdownOpen = false;
                        if (bar.netDropdownOpen) bar.netDropdownOpen = false;
                        globalState.powerDropdownOpen = !cur;
                    }
                }
            }

        }
        
        // ── BAR CENTER: CUPCAKE LOGO (TOP) / EMBEDDED DOCK ICONS (BOTTOM) ──
        Item {
            id: barCenterContainer
            x: (bar.screenW / 2) - solidBar.x - (width / 2)
            anchors.verticalCenter: parent.verticalCenter
            width: bar.isBottom ? Math.max(cupcakeLogo.width, barDockRow.implicitWidth) : cupcakeLogo.width
            height: bar.barHeight
            clip: true

            Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

            // ── TOP BAR: CUPCAKE WORD LOGO (Slides UP when bar is at bottom) ──
            Image {
                id: cupcakeLogo
                anchors.horizontalCenter: parent.horizontalCenter
                y: bar.isBottom ? -36 : ((parent.height - height) / 2)
                opacity: bar.isBottom ? 0.0 : 1.0
                source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/cupcake-word-" + (Theme.isDark ? "light" : "dark") + ".svg"
                sourceSize.height: 22
                width: 67
                height: 22
                fillMode: Image.PreserveAspectFit
                layer.enabled: true
                layer.effect: ColorOverlay { color: bar.fg }

                Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
            }

            // ── BOTTOM BAR: EMBEDDED DOCK ICONS (Slides IN from bottom when bar is at bottom) ──
            RowLayout {
                id: barDockRow
                anchors.horizontalCenter: parent.horizontalCenter
                y: bar.isBottom ? ((parent.height - height) / 2) : 36
                opacity: bar.isBottom ? 1.0 : 0.0
                visible: opacity > 0.01
                spacing: 6

                Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }

                // Pinned Apps
                Repeater {
                    model: (globalState && globalState.dockPinnedAppsEnabled && globalState.dockPinnedApps) ? globalState.dockPinnedApps : []

                    delegate: Item {
                        id: barPinnedItem
                        required property var modelData
                        width: 26; height: 26
                        Layout.alignment: Qt.AlignVCenter

                        property var toplevel: null

                        Instantiator {
                            model: ToplevelManager.toplevels
                            delegate: QtObject {
                                required property var modelData
                                property var tl: modelData
                                Component.onCompleted: {
                                    if (tl && tl.appId === barPinnedItem.modelData.appId) {
                                        barPinnedItem.toplevel = tl;
                                    }
                                }
                                Component.onDestruction: {
                                    if (barPinnedItem.toplevel === tl) {
                                        barPinnedItem.toplevel = null;
                                    }
                                }
                            }
                        }

                        readonly property bool isRunning: toplevel !== null
                        readonly property bool isActive: isRunning && toplevel.activated

                        Rectangle {
                            id: iconTile
                            anchors.centerIn: parent
                            width: 24; height: 24; radius: 12
                            color: barPinnedItem.isActive
                                   ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.22)
                                   : (barPinnedItem.isRunning
                                      ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.10)
                                      : (barPinnedMa.containsMouse ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.12) : "transparent"))
                            border.color: barPinnedItem.isActive
                                          ? Theme.colPrimary
                                          : (barPinnedItem.isRunning
                                             ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.35)
                                             : (barPinnedMa.containsMouse ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.2) : "transparent"))
                            border.width: barPinnedItem.isActive ? 1.5 : (barPinnedItem.isRunning ? 1 : (barPinnedMa.containsMouse ? 1 : 0))
                            scale: barPinnedMa.containsMouse ? 1.15 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Image {
                                anchors.centerIn: parent
                                width: 16; height: 16
                                source: "image://icon/" + barPinnedItem.modelData.appId
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }

                            MouseArea {
                                id: barPinnedMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (barPinnedItem.isRunning && barPinnedItem.toplevel) {
                                        barPinnedItem.toplevel.activate();
                                    } else {
                                        Quickshell.execDetached(["bash", "-c", barPinnedItem.modelData.exec]);
                                    }
                                }
                            }
                        }
                    }
                }

                // 3. Divider before unpinned running apps
                Rectangle {
                    width: 1
                    height: 14
                    radius: 0.5
                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.2)
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 2
                    Layout.rightMargin: 2
                    visible: {
                        var hasUnpinned = false;
                        var pinnedIds = [];
                        if (globalState && globalState.dockPinnedAppsEnabled && globalState.dockPinnedApps) {
                            for (var j = 0; j < globalState.dockPinnedApps.length; j++) {
                                pinnedIds.push(globalState.dockPinnedApps[j].appId);
                            }
                        }
                        if (ToplevelManager && ToplevelManager.toplevels) {
                            for (var i = 0; i < ToplevelManager.toplevels.length; i++) {
                                if (!pinnedIds.includes(ToplevelManager.toplevels[i].appId)) {
                                    hasUnpinned = true;
                                    break;
                                }
                            }
                        }
                        return hasUnpinned;
                    }
                }

                // 4. Unpinned Running Apps
                Repeater {
                    model: ToplevelManager ? ToplevelManager.toplevels : []

                    delegate: Item {
                        id: barUnpinnedItem
                        required property var modelData

                        readonly property bool isPinned: {
                            if (!globalState || !globalState.dockPinnedAppsEnabled || !globalState.dockPinnedApps) return false;
                            for (var j = 0; j < globalState.dockPinnedApps.length; j++) {
                                if (globalState.dockPinnedApps[j].appId === modelData.appId) return true;
                            }
                            return false;
                        }

                        visible: !isPinned
                        width: visible ? 26 : 0
                        height: 26
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            anchors.centerIn: parent
                            width: 24; height: 24; radius: 12
                            color: barUnpinnedItem.modelData.activated
                                   ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.22)
                                   : (barUnpinnedMa.containsMouse ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.14) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.10))
                            border.color: barUnpinnedItem.modelData.activated
                                          ? Theme.colPrimary
                                          : (barUnpinnedMa.containsMouse ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.35))
                            border.width: barUnpinnedItem.modelData.activated ? 1.5 : 1
                            scale: barUnpinnedMa.containsMouse ? 1.15 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Image {
                                anchors.centerIn: parent
                                width: 16; height: 16
                                source: barUnpinnedItem.modelData.appId ? ("image://icon/" + barUnpinnedItem.modelData.appId) : ""
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }

                            MouseArea {
                                id: barUnpinnedMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: barUnpinnedItem.modelData.activate()
                            }
                        }
                    }
                }
            }
        }
    }

    // ── NETWORK SPLIT PILL ──────────────────────────────────────────────────
    DropdownNetwork { id: netSplitPill; visible: opacity > 0 }

    // ── VOLUME & BRIGHTNESS SPLIT PILL ──────────────────────────────────────────────────
    DropdownHardware { id: volBrightSplitPill; visible: opacity > 0 }

    // ── CLOCK SPLIT PILL ──────────────────────────────────────────────────
    DropdownClock { id: clockSplitPill; visible: opacity > 0 }

    // ── POWER SPLIT PILL ──────────────────────────────────────────────────
    DropdownPower { id: powerSplitPill; visible: opacity > 0 }

    // ── MUSIC SPLIT PILL ──────────────────────────────────────────────────
    DropdownMusic { id: musicSplitPill; visible: opacity > 0 }

    // ── CLIPBOARD SPLIT PILL ──────────────────────────────────────────────
    DropdownClipboard { id: clipboardSplitPill; visible: opacity > 0 }

    // ── INCOMING NOTIFICATION DETACHED ISLAND PILL (Right Side) ──────────
    Item {
        id: notifDetachedPod
        readonly property bool hasNotif: bar.hasNotifPopup
        readonly property var popupsList: bar.notifPopups ? bar.notifPopups : []
        property var cachedPopups: []
        onPopupsListChanged: {
            if (popupsList && popupsList.length > 0) {
                cachedPopups = popupsList;
            }
        }
        readonly property var effectivePopups: (popupsList && popupsList.length > 0) ? popupsList : cachedPopups
        property bool showAllNotifs: false
        readonly property int cardCount: (effectivePopups.length > 0 && bar.notifAnimWidth > 0.5) ? (showAllNotifs ? effectivePopups.length : Math.min(3, effectivePopups.length)) : 0

        readonly property real maxScreenH: (bar.screen && bar.screen.height > 0) ? (bar.screen.height - bar.midY - 60) : 700
        readonly property real fullW: 320
        readonly property real footerH: (effectivePopups.length > 3) ? 34 : 0
        readonly property real maxListH: maxScreenH - footerH
        readonly property real targetListH: Math.min(maxListH, notifStackCol.implicitHeight)
        readonly property real targetTotalH: targetListH + ((hasNotif || bar.notifAnimWidth > 0.5) ? footerH : 0)
        readonly property color cardBg: bar.pillColor

        onHasNotifChanged: {
            if (!hasNotif) {
                showAllNotifs = false;
                notifFlickable.contentY = 0;
            }
        }

        width: bar.notifAnimWidth
        height: (hasNotif || bar.notifAnimWidth > 0.5) ? targetTotalH : bar.barHeight
        y: bar.midY
        x: (bar.barX + bar.barW) - bar.notifAnimWidth
        opacity: bar.notifAnimWidth > 2 ? 1.0 : 0.0
        visible: bar.notifAnimWidth > 0.5
        clip: false

        // 1. SCROLLABLE LIST OF CARDS (Anchored rigidly to parent.top to match status bar top line)
        Flickable {
            id: notifFlickable
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: notifDetachedPod.targetListH
            contentWidth: width
            contentHeight: notifStackCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            WheelHandler {
                onWheel: (event) => {
                    let delta = event.angleDelta.y;
                    notifFlickable.contentY = Math.max(0, Math.min(notifFlickable.contentHeight - notifFlickable.height, notifFlickable.contentY - delta));
                }
            }

            // Scrollbar Indicator
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 2
                width: 3
                radius: 1.5
                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.4)
                visible: notifFlickable.contentHeight > notifFlickable.height
                y: notifFlickable.contentHeight > notifFlickable.height ? (notifFlickable.contentY * (notifFlickable.height - height) / (notifFlickable.contentHeight - notifFlickable.height)) : 0
                height: notifFlickable.contentHeight > 0 ? Math.max(20, notifFlickable.height * (notifFlickable.height / notifFlickable.contentHeight)) : 20
                opacity: (notifFlickable.moving || notifDetachedPod.showAllNotifs) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // Stack of Notification Cards
            ColumnLayout {
                id: notifStackCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 6

                Repeater {
                    model: notifDetachedPod.cardCount
                    delegate: Rectangle {
                        id: cardItem
                        readonly property int itemIdx: index
                        readonly property var notifData: (notifDetachedPod.effectivePopups && itemIdx < notifDetachedPod.effectivePopups.length) ? notifDetachedPod.effectivePopups[itemIdx] : null
                        readonly property bool isCardHovered: cardMa.containsMouse || dismissCardMa.containsMouse

                        function getCleanAppTag(notif) {
                            if (!notif) return "SYSTEM";
                            let summary = (notif.summary || "").toLowerCase();
                            let body = (notif.body || "").toLowerCase();
                            let app = (notif.appName || "").trim();
                            if (summary.includes("screenshot") || body.includes("/screenshot/")) return "SCREENSHOT";
                            if (app.toLowerCase() === "notify-send" || app === "") return "SYSTEM";
                            return app.toUpperCase();
                        }

                        function getCompactPreview(notif) {
                            if (!notif) return "";
                            let summary = (notif.summary || "").replace(/[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{2600}-\u{27BF}]/gu, '').trim();
                            let body = (notif.body || "").replace(/[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{2600}-\u{27BF}]/gu, '').trim();
                            let app = (notif.appName || "").toLowerCase();

                            // 1. File paths (e.g. screenshots / downloads / images) -> show clean filename only
                            if (body.startsWith("/") || body.includes("/Screenshot/") || body.includes("/Pictures/") || body.includes("/Downloads/")) {
                                let parts = body.split('/');
                                let filename = parts[parts.length - 1] || "";
                                if (filename.length > 0) {
                                    return "Saved • " + filename;
                                }
                            }

                            // 2. Chat / Messenger (e.g. Alex: "Are we still meeting for coffee?")
                            if (body && summary && body !== summary) {
                                if (["telegram", "discord", "slack", "signal", "whatsapp", "messages"].indexOf(app) !== -1 || summary.length <= 18) {
                                    return summary + ": " + body;
                                }
                                return summary + " • " + body;
                            }

                            return summary || body;
                        }

                        function getExpandedHeading(notif) {
                            if (!notif) return "";
                            let summary = (notif.summary || "").replace(/[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{2600}-\u{27BF}]/gu, '').trim();
                            let body = (notif.body || "").replace(/[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{2600}-\u{27BF}]/gu, '').trim();
                            if (summary.toLowerCase().includes("screenshot") || body.includes("/Screenshot/")) {
                                return "Screenshot Saved";
                            }
                            return summary || "Notification";
                        }

                        function getLocationDir(notif) {
                            if (!notif) return "";
                            let body = (notif.body || "").replace(/[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{2600}-\u{27BF}]/gu, '').trim();
                            if (body.startsWith("/") && (body.includes(".png") || body.includes(".jpg") || body.includes(".jpeg"))) {
                                let lastSlash = body.lastIndexOf('/');
                                let dir = body.substring(0, lastSlash);
                                return dir ? (dir + "/") : "";
                            }
                            return "";
                        }

                        function getFilename(notif) {
                            if (!notif) return "";
                            let body = (notif.body || "").replace(/[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{2600}-\u{27BF}]/gu, '').trim();
                            if (body.startsWith("/") && (body.includes(".png") || body.includes(".jpg") || body.includes(".jpeg"))) {
                                let parts = body.split('/');
                                return parts[parts.length - 1] || body;
                            }
                            return "";
                        }

                        function getRegularBody(notif) {
                            if (!notif) return "";
                            let body = (notif.body || "").replace(/[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{2600}-\u{27BF}]/gu, '').trim();
                            let summary = (notif.summary || "").replace(/[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{2600}-\u{27BF}]/gu, '').trim();
                            if (body === summary) return "";
                            return body;
                        }
                        
                        Layout.fillWidth: true
                        Layout.preferredHeight: isCardHovered ? (bar.barHeight + expandedDetailsCol.implicitHeight + 14) : bar.barHeight
                        implicitHeight: Layout.preferredHeight
                        radius: isCardHovered ? 15 : bar.startRadius
                        color: notifDetachedPod.cardBg
                        border.width: isCardHovered ? 1 : 0
                        border.color: isCardHovered ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.25) : "transparent"
                        clip: true
                        opacity: 1.0

                        Behavior on Layout.preferredHeight {
                            NumberAnimation {
                                duration: 720
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]
                            }
                        }
                        Behavior on radius { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        Behavior on border.color { ColorAnimation { duration: 250 } }

                        // 1. Header & Controls Row (Clean RowLayout - 100% immune to collisions!)
                        RowLayout {
                            id: headerRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: bar.barHeight
                            anchors.leftMargin: 13
                            anchors.rightMargin: 13
                            spacing: 8

                            Rectangle {
                                id: urgencyDot
                                width: 6
                                height: 6
                                radius: 3
                                color: (cardItem.notifData && cardItem.notifData.urgency === 2) ? "#E06C75" : "#E5C07B"
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                id: notifAppTag
                                text: cardItem.getCleanAppTag(cardItem.notifData)
                                font.family: Theme.appFontMono
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.4
                                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.55)
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Compact Preview Text (Saved • 08-16-09-27-43.png)
                            Text {
                                id: inlinePreviewText
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: cardItem.getCompactPreview(cardItem.notifData)
                                font.family: Theme.appFontMono
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: bar.fg
                                elide: Text.ElideRight
                                opacity: cardItem.isCardHovered ? 0.0 : 1.0
                                Behavior on opacity { NumberAnimation { duration: 250 } }
                            }

                            // Circle Countdown Timer Ring
                            Shape {
                                width: 14
                                height: 14
                                Layout.alignment: Qt.AlignVCenter
                                layer.enabled: true
                                layer.samples: 4
                                opacity: cardItem.isCardHovered ? 0.35 : 0.9
                                Behavior on opacity { NumberAnimation { duration: 250 } }

                                ShapePath {
                                    strokeColor: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.15)
                                    strokeWidth: 1.5
                                    fillColor: "transparent"
                                    capStyle: ShapePath.RoundCap

                                    PathAngleArc {
                                        centerX: 7
                                        centerY: 7
                                        radiusX: 5
                                        radiusY: 5
                                        startAngle: 0
                                        sweepAngle: 360
                                    }
                                }

                                ShapePath {
                                    strokeColor: (cardItem.notifData && cardItem.notifData.urgency === 2) ? "#E06C75" : Theme.colPrimary
                                    strokeWidth: 1.5
                                    fillColor: "transparent"
                                    capStyle: ShapePath.RoundCap

                                    PathAngleArc {
                                        centerX: 7
                                        centerY: 7
                                        radiusX: 5
                                        radiusY: 5
                                        startAngle: -90
                                        sweepAngle: -360 * cardItem.timerProgress
                                    }
                                }
                            }

                            // Dismiss button (✕)
                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                color: dismissCardMa.containsMouse ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.16) : "transparent"
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "\ueb55"
                                    font.family: bar.fontName
                                    font.pixelSize: 9
                                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                                }

                                MouseArea {
                                    id: dismissCardMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (cardItem.notifData) cardItem.notifData.dismiss();
                                        let curList = notifDetachedPod.popupsList.slice();
                                        curList.splice(cardItem.itemIdx, 1);
                                        globalState.popups = curList;
                                    }
                                }
                            }
                        }

                        // 2. Expanded Details Section (Smooth downward reveal on hover, pristine collapse!)
                        ColumnLayout {
                            id: expandedDetailsCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: headerRow.bottom
                            anchors.leftMargin: 13
                            anchors.rightMargin: 13
                            anchors.topMargin: 2
                            spacing: 6
                            visible: opacity > 0.01
                            opacity: cardItem.isCardHovered ? 1.0 : 0.0

                            transform: Translate {
                                y: cardItem.isCardHovered ? 0 : -8
                                Behavior on y {
                                    NumberAnimation {
                                        duration: 650
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]
                                    }
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 400
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]
                                }
                            }

                            // Heading Title (Screenshot Saved / App Title)
                            Text {
                                Layout.fillWidth: true
                                text: cardItem.getExpandedHeading(cardItem.notifData)
                                font.family: Theme.appFontMono
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: bar.fg
                            }

                            // Divider Line
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.08)
                            }

                            // Location Section (Location path + Filename)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                visible: cardItem.getLocationDir(cardItem.notifData) !== ""

                                Text {
                                    Layout.fillWidth: true
                                    text: "Location: " + cardItem.getLocationDir(cardItem.notifData)
                                    font.family: Theme.appFontMono
                                    font.pixelSize: 10
                                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: cardItem.getFilename(cardItem.notifData)
                                    font.family: Theme.appFontMono
                                    font.pixelSize: 11
                                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.85)
                                    elide: Text.ElideRight
                                }
                            }

                            // Regular Body Text (for messages, chat, system alerts)
                            Text {
                                Layout.fillWidth: true
                                visible: cardItem.getLocationDir(cardItem.notifData) === "" && text !== ""
                                text: cardItem.getRegularBody(cardItem.notifData)
                                font.family: Theme.appFontMono
                                font.pixelSize: 11
                                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.65)
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                lineHeight: 1.25
                            }
                        }

                    property real timerProgress: 1.0
                    property int expireMs: (cardItem.notifData && cardItem.notifData.expireTimeout > 0) ? cardItem.notifData.expireTimeout : 6000

                    NumberAnimation on timerProgress {
                        id: progressAnim
                        from: 1.0
                        to: 0.0
                        duration: cardItem.expireMs
                        running: true
                        paused: cardItem.isCardHovered || notifFlickable.moving
                        onFinished: {
                            if (cardItem.notifData) {
                                cardItem.notifData.dismiss();
                            }
                            let curList = notifDetachedPod.popupsList.slice();
                            curList.splice(cardItem.itemIdx, 1);
                            globalState.popups = curList;
                        }
                    }

                    MouseArea {
                        id: cardMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        propagateComposedEvents: true
                        onClicked: (mouse) => {
                            if (cardItem.notifData) {
                                if (cardItem.notifData.actions && cardItem.notifData.actions.length > 0) {
                                    cardItem.notifData.actions[0].trigger();
                                }
                                cardItem.notifData.dismiss();
                            }
                            let curList = notifDetachedPod.popupsList.slice();
                            curList.splice(cardItem.itemIdx, 1);
                            globalState.popups = curList;
                        }
                    }
                }
            }
        }
    }

    // 2. PINNED / CONSTANT CONTROLS (Anchored directly below notifFlickable)
    // 2a. More Button (Unrolls all notifications in-place)
    Rectangle {
        anchors.top: notifFlickable.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        visible: !notifDetachedPod.showAllNotifs && notifDetachedPod.popupsList.length > 3
        height: 28
        radius: 14
        color: notifDetachedPod.cardBg
        border.color: moreMa.containsMouse ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.28) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.16)
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: "\uea5f" // chevron-down in tabler
                font.family: bar.fontName
                font.pixelSize: 12
                color: bar.fg
            }

            Text {
                text: "+" + (notifDetachedPod.popupsList.length - 3) + " more notifications"
                font.family: Theme.appFontMono
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: bar.fg
            }
        }

        MouseArea {
            id: moreMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                notifDetachedPod.showAllNotifs = true;
            }
        }
    }

    // 2b. Expanded Fixed Footer: Show Less & Clear All (Pinned directly below notifFlickable)
    RowLayout {
        anchors.top: notifFlickable.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        visible: notifDetachedPod.showAllNotifs && notifDetachedPod.popupsList.length > 3
        height: 28
        spacing: 6

        // Show Less button
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            radius: 14
            color: notifDetachedPod.cardBg
            border.color: lessMa.containsMouse ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.28) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.16)
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text: "\uea62" // chevron-up in tabler
                    font.family: bar.fontName
                    font.pixelSize: 12
                    color: bar.fg
                }

                Text {
                    text: "Show less"
                    font.family: Theme.appFontMono
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: bar.fg
                }
            }

            MouseArea {
                id: lessMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    notifDetachedPod.showAllNotifs = false;
                }
            }
        }

        // Clear All button
        Rectangle {
            Layout.preferredWidth: 88
            Layout.preferredHeight: 28
            radius: 14
            color: notifDetachedPod.cardBg
            border.color: clearAllMa.containsMouse ? Theme.colError : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.16)
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: "\ueb55" // x in tabler
                    font.family: bar.fontName
                    font.pixelSize: 11
                    color: clearAllMa.containsMouse ? Theme.colError : bar.fg
                }

                Text {
                    text: "Clear all"
                    font.family: Theme.appFontMono
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: clearAllMa.containsMouse ? Theme.colError : bar.fg
                }
            }

            MouseArea {
                id: clearAllMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    for (let i = 0; i < notifDetachedPod.popupsList.length; i++) {
                        if (notifDetachedPod.popupsList[i]) notifDetachedPod.popupsList[i].dismiss();
                    }
                    globalState.popups = [];
                    notifDetachedPod.showAllNotifs = false;
                }
            }
        }
    }
    }
    // ─────────────────────────────────────────────────────
    //  1. FORWARD EXPANSION ANIMATION (Cupcake Pill -> Solid Bar)
    // ─────────────────────────────────────────────────────
    ParallelAnimation {
        id: expandAnim
        running: false

        NumberAnimation {
            target: solidBar
            property: "x"
            from: bar.startX
            to: bar.barX
            duration: 700
            easing.type: Easing.OutQuart
        }
        NumberAnimation {
            target: solidBar
            property: "width"
            from: bar.startW
            to: bar.barW
            duration: 700
            easing.type: Easing.OutQuart
        }
        NumberAnimation {
            target: bar
            property: "baseHeight"
            from: bar.startHeight
            to: bar.barHeight
            duration: 700
            easing.type: Easing.OutQuart
        }
        NumberAnimation {
            target: solidBar
            property: "radius"
            from: bar.startRadius
            to: bar.barRadius
            duration: 700
            easing.type: Easing.OutQuart
        }
        NumberAnimation {
            target: contentLayout
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 420
            easing.type: Easing.InOutCubic
        }
        
        onFinished: {
            solidBar.x = Qt.binding(function() {
                return bar.barX;
            });
            solidBar.width = Qt.binding(function() {
                return bar.isBottom ? bar.barW : (bar.barW - (bar.notifAnimWidth > 0 ? (bar.notifAnimWidth + 8) : 0));
            });
            contentLayout.opacity = 1.0;
        }
    }

    function resetToCupcakePill() {
        expandAnim.stop();
        solidBar.x = bar.startX;
        solidBar.width = bar.startW;
        bar.baseHeight = bar.startHeight;
        contentLayout.opacity = 0.0;
    }

    Component.onCompleted: {
        resetToCupcakePill();
        expandAnim.start();
    }

    // ─────────────────────────────────────────────────────
    //  BACKGROUND DATA POLLING
    // ── SYSTEM RESOURCE PROCESSES ───────────────────────────────────────────────
    Process {
        id: dispatchProc
        property string cmd: ""
        command: ["bash", "-c", cmd]
        running: false
    }

    // Accurate CPU via /proc/stat delta
    Process {
        id: cpuProc; running: true
        command: ["bash", "-c", "head -1 /proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = text.trim().split(/\s+/);
                let user=parseInt(p[1])||0, nice=parseInt(p[2])||0, sys=parseInt(p[3])||0,
                    idle=parseInt(p[4])||0, iowait=parseInt(p[5])||0,
                    irq=parseInt(p[6])||0, softirq=parseInt(p[7])||0;
                let total = user+nice+sys+idle+iowait+irq+softirq;
                let idleAll = idle+iowait;
                if (bar.prevCpuTotal > 0) {
                    let dTotal = total - bar.prevCpuTotal;
                    let dIdle  = idleAll - bar.prevCpuIdle;
                    if (dTotal > 0)
                        bar.cpuStr = Math.max(0, Math.min(100, Math.round(100*(1-dIdle/dTotal)))).toString();
                }
                bar.prevCpuIdle  = idleAll;
                bar.prevCpuTotal = total;
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: cpuProc.running = true }

    // RAM + Swap via /proc/meminfo
    Process {
        id: ramProc; running: true
        command: ["bash", "-c", "awk '/^MemTotal:/{mt=$2}/^MemAvailable:/{ma=$2}/^SwapTotal:/{st=$2}/^SwapFree:/{sf=$2}END{printf \"%.0f %.0f\",((mt-ma)/mt*100),(st>0?(st-sf)/st*100:0)}' /proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = text.trim().split(" ");
                let r = parseFloat(parts[0]); if (!isNaN(r)) bar.ramStr = Math.round(r).toString();
                let s = parseFloat(parts[1]); if (!isNaN(s)) bar.swapStr = Math.round(s).toString();
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: ramProc.running = true }

    Process {
        id: tempProc; running: true
        command: ["bash", "-c", "sensors 2>/dev/null | awk '/^(Tctl|Package id 0|CPU Temperature)/{print int($2); exit}'"]
        stdout: StdioCollector { onStreamFinished: { let v = parseFloat(text); if (!isNaN(v)) bar.tempStr = Math.round(v).toString() } }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: tempProc.running = true }

    Process {
        id: volProc; running: true
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}'"]
        stdout: StdioCollector { onStreamFinished: { if (text) bar.volStr = text.trim().split('\n').pop() } }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: volProc.running = true }

    Process {
        id: lightProc; running: false
        command: ["bash", "-c", "ddcutil getvcp 10 --terse 2>/dev/null | awk '{print $4}'"]
        stdout: StdioCollector { onStreamFinished: { if (text) bar.brightStr = text.trim().split('\n').pop() } }
    }

    Process {
        id: batProc; running: true
        command: ["bash", "-c", "upower -i $(upower -e | grep BAT) 2>/dev/null | grep percentage | awk '{print $2}' | tr -d '%'"]
        stdout: StdioCollector { onStreamFinished: { if (text && text.trim() !== "") bar.batStr = text.trim(); else bar.batStr = "100" } }
    }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: batProc.running = true }

    Process {
        id: netProc; running: true
        command: ["bash", "-c", "cat /proc/net/dev"]
        property real lastRx: 0; property real lastTx: 0
        property double lastTime: 0
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return
                const now = Date.now()
                const lines = text.trim().split("\n")
                let rx = 0, tx = 0
                for (let i = 2; i < lines.length; i++) {
                    const line = lines[i].trim()
                    if (!line) continue
                    const colonIdx = line.indexOf(":")
                    if (colonIdx === -1) continue
                    const iface = line.substring(0, colonIdx).trim()
                    const rest = line.substring(colonIdx + 1).trim()
                    const p = rest.split(/\s+/)
                    if (p.length >= 9 && (iface.startsWith("en") || iface.startsWith("wl") || iface.startsWith("eth") || iface.startsWith("wlan") || iface.startsWith("ww"))) {
                        rx += parseInt(p[0]) || 0
                        tx += parseInt(p[8]) || 0
                    }
                }
                if (netProc.lastTime > 0 && netProc.lastRx > 0) {
                    const dt = Math.max(0.1, (now - netProc.lastTime) / 1000.0)
                    const rxRate = Math.max(0, (rx - netProc.lastRx) / dt)
                    const txRate = Math.max(0, (tx - netProc.lastTx) / dt)
                    const rxFmt = rxRate >= 1048576 ? (rxRate / 1048576).toFixed(1) + " MB/s" : (Math.round(rxRate / 1024) + " KB/s")
                    const txFmt = txRate >= 1048576 ? (txRate / 1048576).toFixed(1) + " MB/s" : (Math.round(txRate / 1024) + " KB/s")
                    bar.netRxStr = rxFmt
                    bar.netTxStr = txFmt
                    bar.netStr = rxFmt
                }
                netProc.lastRx = rx
                netProc.lastTx = tx
                netProc.lastTime = now
            }
        }
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: netProc.running = true }

    Process {
        id: netTypeProc; running: true
        command: ["bash", "-c", "echo '---wifi---'; nmcli radio wifi; echo '---nmcli---'; nmcli -t -f NAME,TYPE,STATE con show --active; echo '---bt---'; bluetoothctl show; echo '---bt-conn---'; bluetoothctl devices Connected"]
        stdout: StdioCollector {
            onStreamFinished: { 
                let t = text.toLowerCase();
                bar.isWifi = t.includes("---wifi---") ? t.split("---wifi---")[1].split("---")[0].includes("enabled") : false;
                bar.isWired = t.includes("802-3-ethernet");
                bar.isHotspot = t.includes("hotspot");
                bar.isBluetooth = t.includes("powered: yes");
                bar.isBluetoothConnected = t.includes("---bt-conn---") && t.split("---bt-conn---")[1].includes("device");
            }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: netTypeProc.running = true }
}
