import QtQuick
import QtQuick.Layouts
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

    anchors { top: true; left: true; right: true }
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    property bool anyDropdownOpen: bar.dropdownOpen || bar.netDropdownOpen || bar.musicDropdownOpen || globalState.powerDropdownOpen || globalState.solidBoardOpen
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
        }
    }

    property real baseHeight: startHeight
    property bool dropdownOpen: false
    property bool netDropdownOpen: false
    property bool musicDropdownOpen: false
    property var barActivePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool isMusicPlaying: barActivePlayer !== null && (barActivePlayer.playbackState === 1 || barActivePlayer.isPlaying) && (barActivePlayer.trackTitle !== "")
    property bool keepMusicAlive: !hasNotifPopup && (isMusicPlaying || (musicSplitPill && musicSplitPill.isHovered))
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
            }
        }
        function onPowerDropdownOpenChanged() {
            if (globalState.powerDropdownOpen) {
                bar.dropdownOpen = false;
                bar.netDropdownOpen = false;
                globalState.solidBoardOpen = false;
            }
        }
    }

    onDropdownOpenChanged: {
        if (dropdownOpen) {
            netDropdownOpen = false;
            globalState.solidBoardOpen = false;
            globalState.powerDropdownOpen = false;
        }
    }

    onNetDropdownOpenChanged: {
        if (netDropdownOpen) {
            dropdownOpen = false;
            globalState.solidBoardOpen = false;
            globalState.powerDropdownOpen = false;
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
    property color pillColor: Qt.rgba(bg.r, bg.g, bg.b, root.barOpacity)

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
        NumberAnimation { duration: 850; easing.type: Easing.OutExpo }
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

    // Dynamic Island Notification state
    readonly property real notifIslandW: 380
    property var notifPopups: (globalState && globalState.popups) ? globalState.popups : []
    property bool hasNotifPopup: notifPopups.length > 0 && !globalState.hideIsland
    property bool showNotifContent: false

    onHasNotifPopupChanged: {
        if (hasNotifPopup) {
            notifRevealTimer.restart();
        } else {
            notifRevealTimer.stop();
            showNotifContent = false;
        }
    }

    Timer {
        id: notifRevealTimer
        interval: 600 // Smooth slow glide before revealing notification card
        repeat: false
        onTriggered: {
            if (bar.hasNotifPopup) {
                bar.showNotifContent = true;
            }
        }
    }

    // ─────────────────────────────────────────────────────
    //  MORPHING BAR (Starts from cupcake logo pill, expands into solid bar, morphs into Dynamic Island for notifications)
    // ─────────────────────────────────────────────────────
    Rectangle {
        id: solidBar
        y: bar.midY
        x: expandAnim.running ? bar.startX : (hasNotifPopup ? ((bar.screenW - bar.notifIslandW) / 2) : (bar.keepMusicAlive ? (bar.barX + musicSplitPill.contentW + 8) : bar.barX))
        Behavior on x { enabled: !expandAnim.running; NumberAnimation { duration: 800; easing.type: Easing.OutExpo } }
        width: hasNotifPopup ? bar.notifIslandW : ((bar.barW) 
               - (bar.keepMusicAlive ? (musicSplitPill.contentW + 8) : 0)
               - (globalState.powerDropdownOpen ? (powerSplitPill.contentW + powerSplitPill.openGap) : 
                 (globalState.solidBoardOpen ? (36 + 16 + clockSplitPill.contentW + clockSplitPill.openGap) : 
                 (bar.dropdownOpen ? (clockSplitPill.contentW + 16 + volBrightSplitPill.contentW + 16) : 
                 (bar.netDropdownOpen ? (clockSplitPill.contentW + 16 + netSplitPill.contentW + 16) : 0)))))
        Behavior on width { enabled: !expandAnim.running; NumberAnimation { duration: 800; easing.type: Easing.OutExpo } }
        height: hasNotifPopup ? Math.min(320, Math.max(54, notifIslandCol.implicitHeight + 20)) : (bar.baseHeight + bar.extraHeight)
        Behavior on height { enabled: !expandAnim.running; NumberAnimation { duration: 800; easing.type: Easing.OutExpo } }
        radius: hasNotifPopup ? 22 : bar.startRadius
        Behavior on radius { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        color: bar.pillColor
        clip: true

        MouseArea {
            anchors.fill: parent
            enabled: anyDropdownOpen
            propagateComposedEvents: true
            onClicked: (mouse) => {
                if (globalState.powerDropdownOpen) globalState.powerDropdownOpen = false;
                if (globalState.solidBoardOpen) globalState.solidBoardOpen = false;
                if (bar.dropdownOpen) bar.dropdownOpen = false;
                if (bar.netDropdownOpen) bar.netDropdownOpen = false;
                mouse.accepted = false;
            }
        }

        // ── DYNAMIC ISLAND NOTIFICATION CONTENT (Active when notification arrives) ────────
        Column {
            id: notifIslandCol
            anchors.top: parent.top
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 10
            spacing: 8
            opacity: showNotifContent ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            visible: opacity > 0

            Repeater {
                model: hasNotifPopup ? Math.min(notifPopups.length, 3) : 0
                delegate: Item {
                    width: notifIslandCol.width
                    property bool isOverflow: notifPopups.length > 3 && index === 2
                    height: isOverflow ? 32 : notifItemCard.height

                    NotificationCard {
                        id: notifItemCard
                        width: parent.width
                        notificationData: !parent.isOverflow ? notifPopups[index] : null
                        inPanel: false
                        visible: !parent.isOverflow
                    }

                    Rectangle {
                        width: parent.width
                        height: 32
                        radius: 16
                        color: Qt.rgba(Theme.colSurfaceContainerHigh.r, Theme.colSurfaceContainerHigh.g, Theme.colSurfaceContainerHigh.b, 0.6)
                        border.color: Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        visible: parent.isOverflow

                        Text {
                            anchors.centerIn: parent
                            text: "+" + (notifPopups.length - 2) + " more notifications"
                            color: Theme.colPrimary
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                }
            }
        }

        // Solid Bar Modules (fades out during notification dynamic island morph)
        RowLayout {
            id: contentLayout
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            anchors.leftMargin: 13
            anchors.rightMargin: (bar.dropdownOpen || globalState.solidBoardOpen || globalState.powerDropdownOpen || bar.netDropdownOpen) ? 22 : 13
            Behavior on anchors.rightMargin { NumberAnimation { duration: 850; easing.type: Easing.OutExpo } }
            height: bar.barHeight
            spacing: 0
            opacity: hasNotifPopup ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            visible: opacity > 0

            // ── LEFT: Workspaces ────────
            Item {
                id: workspacesContainer
                Layout.preferredWidth: workspacesRow.implicitWidth
                Layout.preferredHeight: 30
                Layout.alignment: Qt.AlignVCenter

                Row {
                    id: workspacesRow
                    spacing: 8
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: 5
                        delegate: Item {
                            width: isFocused ? 22 : 12
                            height: 30
                            property int wsId: index + 1
                            property bool isFocused: (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0) ? Hyprland.focusedWorkspace.id === wsId : (bar.activeWsId === wsId)
                            property bool isOccupied: isFocused || (Hyprland.workspaces && Hyprland.workspaces.values.length > 0 ? Hyprland.workspaces.values.some(ws => ws.id === wsId) : (bar.occupiedWsMap && bar.occupiedWsMap[wsId] ? true : false))
                            
                            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutSine } }

                            Rectangle {
                                id: wsRect
                                anchors.centerIn: parent
                                width: parent.width
                                height: isFocused ? 6 : (wsMouse.containsMouse ? 6 : 4)
                                radius: height / 2
                                color: isFocused ? Theme.colPrimary : (isOccupied ? Qt.rgba(fg.r, fg.g, fg.b, 0.5) : Qt.rgba(fg.r, fg.g, fg.b, 0.2))
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutSine } }
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
                visible: (Hyprland.activeToplevel && Hyprland.activeToplevel.title !== "") || (bar.activeWinTitle && bar.activeWinTitle !== "")
                text: "•"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 15
                font.weight: Theme.defaultFontWeight
                color: Qt.rgba(fg.r, fg.g, fg.b, 0.4)
            }

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

            // ── CENTER-RIGHT: System Resource Monitor ────────
            BarResources {
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: 10
            }




            Item {
                id: networkContainer
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: networkRowContent.implicitWidth
                implicitHeight: 20
                Layout.preferredWidth: implicitWidth * opacity
                opacity: (hasNotifPopup || bar.netDropdownOpen) ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }

                Row {
                    id: networkRowContent
                    height: 20
                    spacing: 8
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        visible: isHotspot
                        text: "\ued1b" // tabler icon for hotspot
                        font.family: fontName
                        font.pixelSize: 15
                        color: fg
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        visible: isBluetooth
                        text: isBluetoothConnected ? "\uecea" : "\uea37" // tabler icon for bluetooth connected/on
                        font.family: fontName
                        font.pixelSize: 15
                        color: fg
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        visible: isWired
                        text: "\uebd9" // tabler icon for wired
                        font.family: fontName
                        font.pixelSize: 15
                        color: (netSplitPill && !netSplitPill.hasInternet) ? "#ff6b6b" : fg
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        visible: isWifi && !isWired && !isHotspot
                        text: "\ueb52" // tabler icon for wifi
                        font.family: fontName
                        font.pixelSize: 15
                        color: (netSplitPill && netSplitPill.wifiSSID !== "Disconnected" && !netSplitPill.hasInternet) ? "#ff6b6b" : fg
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
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
                        anchors.verticalCenter: parent.verticalCenter
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

            // ── RIGHT: Dot Separator (Network -> Hardware) ────────
            Text {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 8 * opacity
                Layout.rightMargin: 8 * opacity
                Layout.preferredWidth: implicitWidth * opacity
                text: "•"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 15
                font.weight: Theme.defaultFontWeight
                color: Qt.rgba(fg.r, fg.g, fg.b, 0.4)
                opacity: (!hasNotifPopup && !bar.dropdownOpen && !bar.netDropdownOpen) ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
            }
            
            // ── RIGHT: Hardware Icons (Brightness & Sound) ────────
            Row {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: implicitWidth * opacity
                spacing: 12
                opacity: (hasNotifPopup || bar.dropdownOpen || bar.netDropdownOpen) ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
                
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
                        if (globalState.solidBoardOpen) globalState.solidBoardOpen = false;
                        if (bar.netDropdownOpen) bar.netDropdownOpen = false;
                        bar.dropdownOpen = !bar.dropdownOpen;
                    }
                    
                    Row {
                        height: 20
                        spacing: bMouse.containsMouse ? 4 : 0
                        Behavior on spacing { NumberAnimation { duration: 200 } }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: bar.getBrightnessIcon(bar.brightStr)
                            font.family: fontName
                            font.pixelSize: 15
                            color: fg
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: bar.brightStr + "%"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 13
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
                        if (globalState.solidBoardOpen) globalState.solidBoardOpen = false;
                        if (bar.netDropdownOpen) bar.netDropdownOpen = false;
                        bar.dropdownOpen = !bar.dropdownOpen;
                    }
                    
                    Row {
                        height: 20
                        spacing: vMouse.containsMouse ? 4 : 0
                        Behavior on spacing { NumberAnimation { duration: 200 } }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: bar.getVolumeIcon(bar.volStr, bar.isVolMuted)
                            font.family: fontName
                            font.pixelSize: 15
                            color: bar.isVolMuted ? Theme.colError : fg
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: bar.volStr + "%"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 13
                            font.weight: Theme.defaultFontWeight
                            color: bar.isVolMuted ? Theme.colError : Qt.rgba(fg.r, fg.g, fg.b, 0.7)
                            width: vMouse.containsMouse ? implicitWidth : 0
                            clip: true
                            Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutSine } }
                        }
                    }
                }
            }

            // ── RIGHT: Dot Separator (Hardware -> Tray) ────────
            Text {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 8 * opacity
                Layout.rightMargin: 8 * opacity
                Layout.preferredWidth: implicitWidth * opacity
                text: "•"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 15
                font.weight: Theme.defaultFontWeight
                color: Qt.rgba(fg.r, fg.g, fg.b, 0.4)
                opacity: (!hasNotifPopup && !bar.dropdownOpen && !bar.netDropdownOpen && sysTrayRepeater.count > 0) ? 1 : 0
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
                opacity: (hasNotifPopup || bar.dropdownOpen || bar.netDropdownOpen) ? 0 : 1
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

            // ── RIGHT: Dot Separator (Tray -> Hardware -> Clock) ────────
            Text {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 8 * opacity
                Layout.rightMargin: 8 * opacity
                Layout.preferredWidth: implicitWidth * opacity
                text: "•"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 15
                font.weight: Theme.defaultFontWeight
                color: Qt.rgba(fg.r, fg.g, fg.b, 0.4)
                opacity: (!hasNotifPopup && !bar.dropdownOpen && !bar.netDropdownOpen && !globalState.solidBoardOpen) ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
            }

            // ── RIGHT: Clock ────────
            MouseArea {
                id: clockMouse
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: clockRow.implicitWidth
                Layout.preferredWidth: implicitWidth * opacity
                height: 20
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                opacity: (hasNotifPopup || bar.dropdownOpen || bar.netDropdownOpen || globalState.solidBoardOpen) ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
                onClicked: globalState.solidBoardOpen = !globalState.solidBoardOpen

                Row {
                    id: clockRow
                    height: 20
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: clockMouse.containsMouse ? 4 : 0
                    Behavior on spacing { NumberAnimation { duration: 200 } }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDateTime(timeClock.date, "hh:mm AP")
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: Theme.defaultFontSize
                        font.weight: Theme.defaultFontWeight
                        color: fg
                    }
                }
            }

            // ── RIGHT: Dot Separator (Clock -> Power) ────────
            Text {
                id: clockBulletMain
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 8 * opacity
                Layout.rightMargin: 8 * opacity
                Layout.preferredWidth: implicitWidth * opacity
                text: "•"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 15
                font.weight: Theme.defaultFontWeight
                color: Qt.rgba(fg.r, fg.g, fg.b, 0.4)
                opacity: (!hasNotifPopup && !globalState.solidBoardOpen && !globalState.powerDropdownOpen && !bar.dropdownOpen && !bar.netDropdownOpen) ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
            }

            // ── RIGHT: Power Pill ────────
            Item {
                id: powerPillItem
                Layout.alignment: Qt.AlignVCenter
                height: 26
                implicitWidth: powerPillInner.implicitWidth
                Layout.preferredWidth: implicitWidth * opacity
                opacity: (hasNotifPopup || bar.dropdownOpen || bar.netDropdownOpen || globalState.solidBoardOpen || globalState.powerDropdownOpen) ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }

                property bool expanded: false  // always false — expansion now handled by PowerDropdown
                onExpandedChanged: {
                    if (!expanded) {
                        logoutBtn.confirming = false
                        restartBtn.confirming = false
                        shutdownBtn.confirming = false
                    }
                }
                
                property bool isHovered: hoverMa.containsMouse || powerMa.containsMouse || logoutMa.containsMouse || restartMa.containsMouse
                // Note: no auto-collapse since we use the separate PowerDropdown now

                MouseArea {
                    id: hoverMa
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }

                Row {
                    id: powerPillInner
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    // ── Expanded: action icons slide in ──
                    // Logout
                    Item {
                        id: logoutBtn
                        height: 26
                        width: powerPillItem.expanded ? logoutRow.implicitWidth : 0
                        opacity: powerPillItem.expanded ? 1 : 0
                        clip: true
                        property bool confirming: false
                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutSine } }
                        Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutSine } }
                        Timer { id: logoutTimer; interval: 3000; onTriggered: logoutBtn.confirming = false }
                        
                        Row {
                            id: logoutRow
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            spacing: 0
                            Item {
                                width: 26; height: 26
                                Text {
                                    anchors.centerIn: parent
                                    text: "\ueba8"
                                    font.family: fontName
                                    font.pixelSize: 14
                                    color: logoutMa.containsMouse ? Theme.colError : Qt.rgba(fg.r, fg.g, fg.b, 0.65)
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: logoutBtn.confirming ? "Sure?" : "Logout"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: logoutMa.containsMouse ? Theme.colError : Qt.rgba(fg.r, fg.g, fg.b, 0.65)
                                Behavior on color { ColorAnimation { duration: 120 } }
                                rightPadding: 8
                            }
                        }
                        MouseArea {
                            id: logoutMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (logoutBtn.confirming) {
                                    powerPillItem.expanded = false;
                                    logoutBtn.confirming = false;
                                    Quickshell.execDetached(["bash", "-c", "hyprctl dispatch exit"]);
                                } else {
                                    logoutBtn.confirming = true;
                                    logoutTimer.restart();
                                }
                            }
                        }
                    }

                    // Restart
                    Item {
                        id: restartBtn
                        height: 26
                        width: powerPillItem.expanded ? restartRow.implicitWidth : 0
                        opacity: powerPillItem.expanded ? 1 : 0
                        clip: true
                        property bool confirming: false
                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutSine } }
                        Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutSine } }
                        Timer { id: restartTimer; interval: 3000; onTriggered: restartBtn.confirming = false }
                        
                        Row {
                            id: restartRow
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            spacing: 0
                            Item {
                                width: 26; height: 26
                                Text {
                                    anchors.centerIn: parent
                                    text: "\ueb13"
                                    font.family: fontName
                                    font.pixelSize: 14
                                    color: restartMa.containsMouse ? Theme.colError : Qt.rgba(fg.r, fg.g, fg.b, 0.65)
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: restartBtn.confirming ? "Sure?" : "Restart"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: restartMa.containsMouse ? Theme.colError : Qt.rgba(fg.r, fg.g, fg.b, 0.65)
                                Behavior on color { ColorAnimation { duration: 120 } }
                                rightPadding: 8
                            }
                        }
                        MouseArea {
                            id: restartMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (restartBtn.confirming) {
                                    powerPillItem.expanded = false;
                                    restartBtn.confirming = false;
                                    Quickshell.execDetached(["bash", "-c", "systemctl reboot"]);
                                } else {
                                    restartBtn.confirming = true;
                                    restartTimer.restart();
                                }
                            }
                        }
                    }

                    // ── Power icon (always visible) & Shutdown text ──
                    Item {
                        id: shutdownBtn
                        height: 26
                        width: globalState.powerDropdownOpen ? 0 : shutdownRow.implicitWidth
                        opacity: globalState.powerDropdownOpen ? 0.0 : 1.0
                        visible: opacity > 0 || width > 0
                        clip: true
                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutSine } }
                        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutSine } }
                        property bool confirming: false
                        Timer { id: shutdownTimer; interval: 3000; onTriggered: shutdownBtn.confirming = false }
                        
                        Row {
                            id: shutdownRow
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            spacing: 0
                            Item {
                                width: 26; height: 26
                                Text {
                                    anchors.centerIn: parent
                                    text: "\ueb0d"
                                    font.family: fontName
                                    font.pixelSize: 15
                                    color: (powerPillItem.expanded ? powerMa.containsMouse : powerPillItem.isHovered) ? Theme.colError : fg
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }
                            Text {
                                id: powerLabel
                                anchors.verticalCenter: parent.verticalCenter
                                text: powerPillItem.expanded ? (shutdownBtn.confirming ? "Sure?" : "Shutdown") : "Power"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: powerMa.containsMouse ? Theme.colError : (powerPillItem.expanded ? fg : Theme.colError)
                                width: (powerPillItem.expanded || powerPillItem.isHovered) ? implicitWidth : 0
                                opacity: (powerPillItem.expanded || powerPillItem.isHovered) ? 1 : 0
                                clip: true
                                visible: opacity > 0 || width > 0
                                rightPadding: 8
                                Behavior on width   { NumberAnimation { duration: 400; easing.type: Easing.OutSine } }
                                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutSine } }
                            }
                        }
                        MouseArea {
                            id: powerMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (globalState.solidBoardOpen) globalState.solidBoardOpen = false;
                                globalState.powerDropdownOpen = !globalState.powerDropdownOpen;
                            }
                        }
                    }
                }
            }

        }
        
        Image {
            id: cupcakeLogo
            x: (bar.screenW / 2) - solidBar.x - (width / 2)
            anchors.top: parent.top
            anchors.topMargin: (bar.barHeight - 24) / 2
            source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/cupcake-word-" + (Theme.isDark ? "light" : "dark") + ".svg"
            sourceSize.height: 24
            width: 67
            fillMode: Image.PreserveAspectFit
            opacity: hasNotifPopup ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 250 } }
            layer.enabled: true
            layer.effect: ColorOverlay {
                color: bar.fg
            }
        }
    }

    // ── NETWORK SPLIT PILL ──────────────────────────────────────────────────
    DropdownNetwork { id: netSplitPill; visible: !hasNotifPopup }

    // ── VOLUME & BRIGHTNESS SPLIT PILL ──────────────────────────────────────────────────
    DropdownHardware { id: volBrightSplitPill; visible: !hasNotifPopup }

    // ── CLOCK SPLIT PILL ──────────────────────────────────────────────────
    DropdownClock { id: clockSplitPill; visible: !hasNotifPopup }

    // ── POWER SPLIT PILL ──────────────────────────────────────────────────
    DropdownPower { id: powerSplitPill; visible: !hasNotifPopup }

    // ── MUSIC SPLIT PILL ──────────────────────────────────────────────────
    DropdownMusic { id: musicSplitPill; visible: !hasNotifPopup }

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
                return bar.hasNotifPopup ? ((bar.screenW - bar.notifIslandW) / 2) : (bar.keepMusicAlive ? (bar.barX + musicSplitPill.contentW + 16) : bar.barX);
            });
            solidBar.width = Qt.binding(function() {
                return bar.hasNotifPopup ? bar.notifIslandW : ((bar.barW) 
                       - (bar.keepMusicAlive ? (musicSplitPill.contentW + 16) : 0)
                       - (globalState.powerDropdownOpen ? (powerSplitPill.contentW + powerSplitPill.openGap) : 
                         (globalState.solidBoardOpen ? (36 + 16 + clockSplitPill.contentW + clockSplitPill.openGap) : 
                         (bar.dropdownOpen ? (clockSplitPill.contentW + 16 + volBrightSplitPill.contentW + 16) : 
                         (bar.netDropdownOpen ? (clockSplitPill.contentW + 16 + netSplitPill.contentW + 16) : 0)))));
            });
            contentLayout.opacity = Qt.binding(function() {
                return bar.hasNotifPopup ? 0.0 : 1.0;
            });
        }
    }

    function resetToCupcakePill() {
        expandAnim.stop();
        solidBar.x = bar.startX;
        solidBar.width = bar.startW;
        bar.baseHeight = bar.startHeight;
        solidBar.radius = bar.startRadius;
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
