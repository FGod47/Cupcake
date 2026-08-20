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
    exclusiveZone: Math.max(0, bar.barHeight + bar.midY + (Theme.barWindowGap !== undefined ? Theme.barWindowGap : 0))
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
    readonly property bool hasNotifPopup: (globalState && globalState.popups && globalState.popups.length > 0 && !globalState.hideIsland)
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
    property real targetSideGap: Theme.barSideGap !== undefined ? Theme.barSideGap : 0
    property real animSideGap: targetSideGap
    Behavior on animSideGap {
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutCubic
        }
    }
    readonly property real barSideGap: animSideGap
    readonly property real barW: Math.max(200, bar.screenW - (2 * bar.barSideGap))
    readonly property real barX: bar.barSideGap
    readonly property real startW: 100
    readonly property real startX: (bar.screenW - bar.startW) / 2
    readonly property real midY: Theme.barGap !== undefined ? Theme.barGap : 10
    property real barHeight: Theme.barHeight !== undefined ? Theme.barHeight : 30
    readonly property real startHeight: bar.barHeight
    property real barRadius: Theme.barRadius !== undefined ? Theme.barRadius : 15
    readonly property real startRadius: bar.barRadius
    readonly property real barBorderWidth: Theme.barBorderWidth !== undefined ? Theme.barBorderWidth : 0
    readonly property real barInnerPadding: Theme.barInnerPadding !== undefined ? Theme.barInnerPadding : 13
    readonly property real barItemSpacing: Theme.barItemSpacing !== undefined ? Theme.barItemSpacing : 7

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

    // Dynamic Island Notification state (Driven by standalone NotificationIsland)
    readonly property real notifIslandW: 340
    readonly property real notifIslandGap: 8
    readonly property real notifRightMargin: Math.max(8, bar.midY)
    readonly property real notifRestW: Math.max(100, (bar.screenW - notifIslandW - notifIslandGap - notifRightMargin) - bar.barX)
    readonly property real notifProgress: (globalState && globalState.notifProgress !== undefined) ? globalState.notifProgress : 0.0

    // ─────────────────────────────────────────────────────
    //  MORPHING BAR (Starts from cupcake logo pill, expands into solid bar, morphs into Dynamic Island for notifications)
    // ─────────────────────────────────────────────────────
    // MAIN TOP BAR (Rock-Solid Fixed Full Width Geometry)
    // ─────────────────────────────────────────────────────
    Item {
        id: solidBar
        y: bar.isBottom ? (bar.height - (expandAnim.running ? (bar.baseHeight + bar.extraHeight) : bar.barHeight) - bar.midY) : bar.midY
        Behavior on y { enabled: !expandAnim.running; NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
        x: expandAnim.running ? bar.startX : bar.barX
        width: bar.isBottom ? bar.barW : (bar.barW - Math.max(0, (bar.barW - bar.notifRestW) * bar.notifProgress))
        height: expandAnim.running ? (bar.baseHeight + bar.extraHeight) : bar.barHeight
        Behavior on height { enabled: !expandAnim.running; NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
        clip: false

        Rectangle {
            id: solidBarBg
            anchors.fill: parent
            radius: bar.barRadius
            color: bar.pillColor
            antialiasing: true
            border.width: bar.barBorderWidth
            border.color: bar.barBorderWidth > 0 ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.20) : "transparent"
            visible: !squareBR
            readonly property bool squareBR: globalState.powerDropdownOpen && Theme.barDropdownStyle === "Attached"
        }

        Shape {
            id: solidBarAttachedShape
            anchors.fill: parent
            visible: solidBarBg.squareBR
            readonly property real r: bar.barRadius
            readonly property real w: width
            readonly property real h: height

            layer.enabled: true
            layer.samples: 8
            layer.smooth: true

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
            anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: bar.barInnerPadding
            anchors.rightMargin: bar.barInnerPadding
            height: parent.height
            spacing: 0
            opacity: 1.0
            visible: opacity > 0

            // ── LEFT: Workspaces (Glowing Halo Ring Style) ────────
            Item {
                id: workspacesContainer
                Layout.preferredWidth: workspacesRow.implicitWidth
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter

                Row {
                    id: workspacesRow
                    spacing: 10
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: 5
                        delegate: Item {
                            width: 14
                            height: workspacesContainer.height
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
                implicitHeight: 26
                Layout.preferredWidth: implicitWidth
                clip: false
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
                    height: 26
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter

                    // Helper component for interactive top bar connectivity icon
                    component NetBarIcon: Item {
                        property int tabId: 1
                        property string iconCode: "\ueb52"
                        property bool forceVisible: false
                        property color iconColor: fg
                        
                        readonly property bool isShown: forceVisible || bar.netDropdownOpen
                        visible: width > 0 || opacity > 0.01
                        width: isShown ? 20 : 0
                        height: 22
                        anchors.verticalCenter: parent.verticalCenter
                        clip: false

                        Behavior on width {
                            NumberAnimation {
                                duration: 280
                                easing.type: Easing.OutCubic
                            }
                        }

                        Rectangle {
                            id: iconBg
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            radius: 10
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

                    // 1. Network Speed / Status Text (at left of icons, fixed width to prevent icon bounce)
                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        height: 20
                        readonly property bool isNetCollapsed: bar.hasNotifPopup
                        width: isNetCollapsed ? 0 : 58
                        clip: true
                        opacity: isNetCollapsed ? 0 : 1
                        visible: width > 0 || opacity > 0.01

                        Behavior on width {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

                        Text {
                            id: netSpeedText
                            anchors.fill: parent
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                            anchors.rightMargin: 3
                            text: {
                                let isWifiConn = netSplitPill ? netSplitPill.wifiSSID !== "Disconnected" : false;
                                let hasInt = netSplitPill ? netSplitPill.hasInternet : true;
                                if (isWired) {
                                    return hasInt ? netStr : "No Net";
                                } else if (isWifi && isWifiConn) {
                                    return hasInt ? netStr : "No Net";
                                } else if (isHotspot) {
                                    return netStr;
                                } else {
                                    return "Off";
                                }
                            }
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
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

                    // 2. Wi-Fi
                    NetBarIcon {
                        tabId: 1
                        iconCode: "\ueb52"
                        forceVisible: isWifi || (!isWired && !isHotspot)
                        iconColor: (netSplitPill && netSplitPill.wifiSSID !== "Disconnected" && !netSplitPill.hasInternet) ? "#ff6b6b" : fg
                    }

                    // 3. Bluetooth
                    NetBarIcon {
                        tabId: 3
                        iconCode: isBluetoothConnected ? "\uecea" : "\uea37"
                        forceVisible: isBluetooth
                        iconColor: fg
                    }

                    // 4. Hotspot
                    NetBarIcon {
                        tabId: 2
                        iconCode: "\ued1b"
                        forceVisible: isHotspot
                        iconColor: fg
                    }

                    // 5. Ethernet
                    NetBarIcon {
                        tabId: 0
                        iconCode: "\uebd9"
                        forceVisible: isWired
                        iconColor: (netSplitPill && !netSplitPill.hasInternet) ? "#ff6b6b" : fg
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
            height: parent.height
            clip: false

            Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

            // ── TOP BAR: CUPCAKE WORD LOGO (Slides UP when bar is at bottom) ──
            Image {
                id: cupcakeLogo
                anchors.horizontalCenter: parent.horizontalCenter
                y: bar.isBottom ? -36 : ((parent.height - height) / 2)
                opacity: bar.isBottom ? 0.0 : 1.0
                source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/cupcake-word-" + (Theme.isDark ? "light" : "dark") + ".svg"
                sourceSize.height: Math.min(22, Math.max(14, bar.barHeight - 8))
                width: Math.round(67 * (height / 22))
                height: Math.min(22, Math.max(14, bar.barHeight - 8))
                fillMode: Image.PreserveAspectFit
                layer.enabled: true
                layer.effect: ColorOverlay { color: bar.fg }

                Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
            }

            // ── BOTTOM BAR: EMBEDDED DOCK ICONS (Slides IN from bottom when bar is at bottom) ──
            Row {
                id: barDockRow
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
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
                            width: 26; height: 26; radius: 13
                            color: barPinnedItem.isActive
                                   ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.12)
                                   : (barPinnedMa.containsMouse ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.07) : "transparent")
                            scale: barPinnedMa.containsMouse ? 1.10 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Image {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: barPinnedItem.isRunning ? -1 : 0
                                width: 18; height: 18
                                source: "image://icon/" + barPinnedItem.modelData.appId
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }

                            // Minimalist Active / Running Indicator
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 1
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: barPinnedItem.isActive ? 10 : (barPinnedItem.isRunning ? 3 : 0)
                                height: barPinnedItem.isActive ? 2 : (barPinnedItem.isRunning ? 3 : 0)
                                radius: height / 2
                                color: barPinnedItem.isActive ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                                visible: barPinnedItem.isRunning
                                opacity: barPinnedItem.isRunning ? 1.0 : 0.0
                                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 150 } }
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

                // Divider before unpinned running apps
                Item {
                    width: 5
                    height: 26
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

                    Rectangle {
                        anchors.centerIn: parent
                        width: 1
                        height: 10
                        radius: 0.5
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.15)
                    }
                }

                // Unpinned Running Apps
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

                        Rectangle {
                            anchors.centerIn: parent
                            width: 26; height: 26; radius: 13
                            color: barUnpinnedItem.modelData.activated
                                   ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.12)
                                   : (barUnpinnedMa.containsMouse ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.07) : "transparent")
                            scale: barUnpinnedMa.containsMouse ? 1.10 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Image {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -1
                                width: 18; height: 18
                                source: barUnpinnedItem.modelData.appId ? ("image://icon/" + barUnpinnedItem.modelData.appId) : ""
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }

                            // Minimalist Active / Running Indicator
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 1
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: barUnpinnedItem.modelData.activated ? 10 : 3
                                height: barUnpinnedItem.modelData.activated ? 2 : 3
                                radius: height / 2
                                color: barUnpinnedItem.modelData.activated ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 150 } }
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
            target: solidBarBg
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
                if (bar.isBottom) return bar.barW;
                let p = (globalState && globalState.notifProgress !== undefined) ? globalState.notifProgress : 0.0;
                return bar.barW - Math.max(0, (bar.barW - bar.notifRestW) * p);
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
