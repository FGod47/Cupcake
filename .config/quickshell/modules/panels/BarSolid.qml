import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
import QtQuick.Controls
import "../../theme"
import "../common"
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: bar
    property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: 40
    height: 600
    color: "transparent"
    mask: Region {
        Region { item: solidBar }
        Region { item: clockSplitPill }
        Region { item: powerSplitPill }
        Region { item: volBrightSplitPill }
    }

    property real baseHeight: startHeight
    property bool dropdownOpen: false
    property real extraHeight: 0
    
    Connections {
        target: globalState
        function onSolidBoardOpenChanged() {
            if (globalState.solidBoardOpen) {
                bar.dropdownOpen = false;
                globalState.powerDropdownOpen = false;
            }
        }
        function onPowerDropdownOpenChanged() {
            if (globalState.powerDropdownOpen) {
                bar.dropdownOpen = false;
                globalState.solidBoardOpen = false;
            }
        }
    }

    onDropdownOpenChanged: {
        if (bar.dropdownOpen) {
            globalState.solidBoardOpen = false;
            globalState.powerDropdownOpen = false;
            volBrightSplitPill.menuExpanded = true;
        } else {
            volBrightSplitPill.menuExpanded = true;
        }
    }

    // Shared styling
    property color bg: Theme.colSurface
    property color fg: Theme.colOnSurface
    property string fontName: "tabler-icons"
    property color pillColor: Qt.rgba(bg.r, bg.g, bg.b, root.barOpacity)

    // Hardware data
    property string cpuStr: "0"
    property string ramStr: "0"
    property string tempStr: "0"
    property string volStr: "0"
    property string brightStr: "0"
    property string batStr: "100"
    property string netStr: "0 KB/s"
    property bool isWifi: false
    property bool isWired: false
    property bool isBluetooth: false
    property bool isBluetoothConnected: false
    property bool isHotspot: false
    property bool isVolMuted: false
    property string activeSinkName: ""
    property var sinkList: []

    function getVolumeIcon(volVal, isMuted) {
        if (isMuted) return "\uec60";
        var v = parseFloat(volVal) || 0;
        if (v <= 0) return "\uec60";
        if (v < 50) return "\ueb4f";
        return "\ueb51";
    }

    function getBrightnessIcon(brightVal) {
        var b = parseFloat(brightVal) || 0;
        if (b < 33) return "\uf237";
        if (b < 66) return "\ueb30";
        return "\uf236";
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
    readonly property real startW: 160
    readonly property real startX: (bar.screenW - bar.startW) / 2
    readonly property real midY: 10
    readonly property real startHeight: 34
    readonly property real barHeight: 30
    readonly property real startRadius: 18
    readonly property real barRadius: 15

    // Power split pill dimensions
    readonly property real powerPillGap: 8   // gap between bar and power pill
    property real powerSplitOffset: 0       // grows with OutBack to push bar left
    Behavior on powerSplitOffset {
        NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
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

    // ─────────────────────────────────────────────────────
    //  MORPHING BAR (Starts exactly as archPill, expands into solid bar)
    // ─────────────────────────────────────────────────────
    Rectangle {
        id: solidBar
        y: bar.midY
        x: bar.startX
        width: globalState.powerDropdownOpen ? (bar.barW - powerSplitPill.contentW - powerSplitPill.openGap) : (globalState.solidBoardOpen ? (bar.barW - 36 - 12 - clockSplitPill.contentW - clockSplitPill.openGap) : (bar.dropdownOpen ? (bar.barW - clockSplitPill.contentW - 12 - volBrightSplitPill.contentW - volBrightSplitPill.openGap) : bar.barW))
        Behavior on width { enabled: !expandAnim.running && !collapseAnim.running; NumberAnimation { duration: 540; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
        height: bar.baseHeight + bar.extraHeight
        radius: bar.startRadius
        color: Theme.colPrimary
        clip: true

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (globalState.powerDropdownOpen) globalState.powerDropdownOpen = false;
                if (globalState.solidBoardOpen) globalState.solidBoardOpen = false;
                if (bar.dropdownOpen) bar.dropdownOpen = false;
            }
        }

        // Top glass highlight line
        Rectangle {
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: 4; anchors.rightMargin: 4
            height: 1; radius: 1
            color: Qt.rgba(1, 1, 1, 0.12)
        }

        // 1. Initial Arch Pill Label (Arch Logo + Name)
        Row {
            id: archHeader
            anchors.centerIn: parent
            spacing: 8
            opacity: 1.0
            visible: opacity > 0

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "\uf303"
                color: Theme.colOnPrimary
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: Theme.defaultFontSize + 1
                font.weight: Theme.defaultFontWeight
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Arch"
                color: Theme.colOnPrimary
                font.family: Theme.defaultFontFamily
                font.pixelSize: Theme.defaultFontSize
                font.weight: Theme.defaultFontWeight
            }
        }

        // 2. Solid Bar Modules (fades in as expansion completes)
        RowLayout {
            id: contentLayout
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            anchors.leftMargin: 13
            anchors.rightMargin: 13
            height: bar.barHeight
            spacing: 0
            opacity: 0

            // ── LEFT: Workspaces ────────
            Row {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: 5
                    delegate: Item {
                        width: isFocused ? 22 : 12
                        height: 30
                        property int wsId: index + 1
                        property bool isFocused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
                        property bool isOccupied: isFocused || Hyprland.workspaces.values.some(ws => ws.id === wsId)
                        
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
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Hyprland.dispatch("hl.dsp.focus({workspace = " + wsId + "})")
                        }
                    }
                }
            }
            
            // ── LEFT: Window Title ────────
            Text {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 12
                visible: Hyprland.activeToplevel && Hyprland.activeToplevel.title !== ""
                text: "•"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 15
                font.weight: Theme.defaultFontWeight
                color: Qt.rgba(fg.r, fg.g, fg.b, 0.4)
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 12
                Layout.maximumWidth: 300 // exact length requested
                elide: Text.ElideRight
                visible: Hyprland.activeToplevel && Hyprland.activeToplevel.title !== ""
                text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
                font.family: Theme.defaultFontFamily
                font.pixelSize: 13
                font.weight: Theme.defaultFontWeight
                color: Qt.rgba(fg.r, fg.g, fg.b, 0.6)
            }

            // Spacer
            Item { Layout.fillWidth: true }
            

            // ── RIGHT: Network Icons ────────
            Row {
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: 12
                spacing: 8
                
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
                    color: fg
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    visible: isWifi && !isWired && !isHotspot
                    text: "\ueb52" // tabler icon for wifi
                    font.family: fontName
                    font.pixelSize: 15
                    color: fg
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    visible: isWifi || isWired || isBluetooth || isHotspot
                    text: "•"
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 15
                    font.weight: Theme.defaultFontWeight
                    color: Qt.rgba(fg.r, fg.g, fg.b, 0.4)
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: netStr
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 13
                    font.weight: Theme.defaultFontWeight
                    color: Qt.rgba(fg.r, fg.g, fg.b, 0.7)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // ── RIGHT: Vertical Separator ────────
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: 12
                width: 1
                height: 16
                color: Qt.rgba(fg.r, fg.g, fg.b, 0.2)
            }
            
            // ── RIGHT: Hardware Icons (Brightness & Sound) ────────
            Row {
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: 12
                spacing: 12
                opacity: bar.dropdownOpen ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                
                // Brightness
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
                        bar.dropdownOpen = !bar.dropdownOpen;
                    }
                    
                    Row {
                        height: 20
                        spacing: bMouse.containsMouse ? 8 : 0
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
                        bar.dropdownOpen = !bar.dropdownOpen;
                    }
                    
                    Row {
                        height: 20
                        spacing: vMouse.containsMouse ? 8 : 0
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
                            color: Qt.rgba(fg.r, fg.g, fg.b, 0.7)
                            width: vMouse.containsMouse ? implicitWidth : 0
                            clip: true
                            Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutSine } }
                        }
                    }
                }
            }

            // ── RIGHT: Vertical Separator ────────
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: 12
                width: 1
                height: 16
                color: Qt.rgba(fg.r, fg.g, fg.b, 0.2)
                opacity: (bar.dropdownOpen || globalState.solidBoardOpen || globalState.powerDropdownOpen) ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
            
            // ── RIGHT: Clock ────────
            Text {
                id: clockTextMain
                Layout.alignment: Qt.AlignVCenter
                text: Qt.formatDateTime(timeClock.date, "MMM dd • hh:mm AP")
                font.family: Theme.defaultFontFamily
                font.pixelSize: Theme.defaultFontSize
                font.weight: Theme.defaultFontWeight
                color: fg
                opacity: (bar.dropdownOpen || globalState.solidBoardOpen) ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: globalState.solidBoardOpen = !globalState.solidBoardOpen
                }
            }

            Text {
                id: clockBulletMain
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 6
                text: "•"
                font.pixelSize: 8
                color: Qt.rgba(fg.r, fg.g, fg.b, 0.7)
                opacity: (bar.dropdownOpen || globalState.solidBoardOpen || globalState.powerDropdownOpen) ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
            // ── RIGHT: Power Pill ────────
            // Hover: shows "Power" text. Click: shows Shutdown/Restart/Logout icons.
            Item {
                id: powerPillItem
                Layout.alignment: Qt.AlignVCenter
                height: 26
                implicitWidth: powerPillInner.implicitWidth
                opacity: (bar.dropdownOpen || globalState.solidBoardOpen || globalState.powerDropdownOpen) ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 200 } }

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
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: (bar.barHeight - sourceSize.height) / 2
            source: Theme.isDark ? "../../assets/cupcake-word-light.svg" : "../../assets/cupcake-word-dark.svg"
            sourceSize.height: 24
            fillMode: Image.PreserveAspectFit
            opacity: contentLayout.opacity

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: globalState.solidBoardOpen = !globalState.solidBoardOpen
            }
        }
    }

    // ── VOLUME & BRIGHTNESS SPLIT PILL ──────────────────────────────────────────────────
    // Teardown animation: starts collapsed at hardware icons location inside solidBar,
    // then physically separates and slides out rightwards into a floating pill with OutBack bounce.
    Rectangle {
        id: volBrightSplitPill

        y: solidBar.y
        property bool menuExpanded: true
        property bool showSinkList: false
        height: menuExpanded ? (volBrightContentCol.implicitHeight + 28) : solidBar.height
        Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

        z: -1

        readonly property real openGap: 12
        readonly property real headerW: volBrightOptionsRow.implicitWidth + 24
        readonly property real expandedW: 260
        property real contentW: menuExpanded ? expandedW : headerW

        // When closed: starts at hardware icons location inside solidBar (around bar.barW - 285)
        // When open: slides out to the left of clockSplitPill as solidBar shrinks
        x: bar.dropdownOpen ? (bar.barX + bar.barW - clockSplitPill.contentW - 12 - contentW) : (bar.barX + bar.barW - 285)
        width: bar.dropdownOpen ? contentW : 80
        scale: bar.dropdownOpen ? 1.0 : 0.5
        transformOrigin: Item.Left

        Behavior on x     { NumberAnimation { duration: 540; easing.type: Easing.OutBack; easing.overshoot: 1.08 } }
        Behavior on width { NumberAnimation { duration: 540; easing.type: Easing.OutBack; easing.overshoot: 1.08 } }
        Behavior on scale { NumberAnimation { duration: 540; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

        radius: menuExpanded ? 16 : solidBar.radius
        Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        clip: true

        color: bar.pillColor
        border.color: Qt.rgba(1, 1, 1, 0.10)
        border.width: 1

        // Top glass highlight
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 4; anchors.rightMargin: 4
            height: 1; radius: 1
            color: Qt.rgba(1, 1, 1, 0.10)
        }

        opacity: bar.dropdownOpen ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        MouseArea {
            id: volBrightSplitPillMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: (mouseY <= solidBar.height) ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (mouse.y <= solidBar.height) {
                    bar.dropdownOpen = !bar.dropdownOpen;
                    if (bar.dropdownOpen) {
                        globalState.solidBoardOpen = false;
                        globalState.powerDropdownOpen = false;
                    }
                }
            }
        }

        // ── Header (Brightness & Volume Icons + %) ──────────────────────────────
        Row {
            id: volBrightOptionsRow
            anchors.horizontalCenter: parent.horizontalCenter
            y: (solidBar.height - height) / 2
            spacing: 8
            opacity: volBrightSplitPill.menuExpanded ? 0.0 : 1.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250 } }

            Row {
                spacing: 4
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: bar.getBrightnessIcon(bar.brightStr)
                    font.family: fontName
                    font.pixelSize: Theme.defaultFontSize
                    color: bar.fg
                }
                Text {
                    text: bar.brightStr + "%"
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: Theme.defaultFontSize
                    font.weight: Theme.defaultFontWeight
                    color: bar.fg
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "•"
                font.pixelSize: 8
                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
            }
            Row {
                spacing: 4
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: bar.getVolumeIcon(bar.volStr, bar.isVolMuted)
                    font.family: fontName
                    font.pixelSize: Theme.defaultFontSize
                    color: bar.isVolMuted ? Theme.colError : bar.fg
                }
                Text {
                    text: bar.volStr + "%"
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: Theme.defaultFontSize
                    font.weight: Theme.defaultFontWeight
                    color: bar.isVolMuted ? Theme.colError : bar.fg
                }
            }
        }

        // ── Expanded Sliders View ────────────────────────────────
        ColumnLayout {
            id: volBrightContentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 12
            opacity: volBrightSplitPill.menuExpanded ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 300 } }

            // Brightness Slider Row
            Row {
                Layout.fillWidth: true
                spacing: 12
                Text {
                    text: bar.getBrightnessIcon(bar.brightStr)
                    font.family: fontName
                    font.pixelSize: 18
                    color: bar.fg
                    anchors.verticalCenter: parent.verticalCenter
                }
                Slider {
                    id: ddBrightSlider
                    width: parent.width - 34
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true
                    handle: Rectangle {
                        x: ddBrightSlider.leftPadding + ddBrightSlider.visualPosition * (ddBrightSlider.availableWidth - width)
                        y: ddBrightSlider.height / 2 - height / 2
                        width: 14; height: 14; radius: 7
                        color: Theme.colPrimary
                    }
                    background: Rectangle {
                        x: ddBrightSlider.leftPadding
                        y: ddBrightSlider.height / 2 - height / 2
                        implicitWidth: 100
                        implicitHeight: 6
                        width: ddBrightSlider.availableWidth
                        height: implicitHeight
                        radius: 3
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.2)
                        Rectangle {
                            width: ddBrightSlider.visualPosition * parent.width
                            height: parent.height
                            color: Theme.colPrimary
                            radius: 3
                        }
                    }
                    from: 0; to: 100
                    value: parseFloat(bar.brightStr) || 0
                    Timer {
                        id: ddDdcTimer
                        interval: 500; repeat: false
                        property int targetValue: 100
                        onTriggered: Quickshell.execDetached(["ddcutil", "setvcp", "10", Math.round(targetValue).toString(), "--noverify"])
                    }
                    onMoved: { ddDdcTimer.targetValue = value; ddDdcTimer.restart(); bar.brightStr = Math.round(value).toString() }
                    onPressedChanged: {
                        if (!pressed) {
                            ddDdcTimer.stop()
                            Quickshell.execDetached(["ddcutil", "setvcp", "10", Math.round(value).toString()])
                        }
                    }
                }
            }

            // Volume Slider Row
            Row {
                Layout.fillWidth: true
                spacing: 8

                // Mute / Unmute Button
                Item {
                    width: 22; height: 22
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        text: bar.getVolumeIcon(bar.volStr, bar.isVolMuted)
                        font.family: fontName
                        font.pixelSize: 18
                        color: bar.isVolMuted ? Theme.colError : bar.fg
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
                            bar.isVolMuted = !bar.isVolMuted;
                        }
                    }
                }

                Slider {
                    id: ddVolSlider
                    width: parent.width - 56
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true
                    handle: Rectangle {
                        x: ddVolSlider.leftPadding + ddVolSlider.visualPosition * (ddVolSlider.availableWidth - width)
                        y: ddVolSlider.height / 2 - height / 2
                        width: 14; height: 14; radius: 7
                        color: bar.isVolMuted ? Theme.colError : Theme.colPrimary
                    }
                    background: Rectangle {
                        x: ddVolSlider.leftPadding
                        y: ddVolSlider.height / 2 - height / 2
                        implicitWidth: 100
                        implicitHeight: 6
                        width: ddVolSlider.availableWidth
                        height: implicitHeight
                        radius: 3
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.2)
                        Rectangle {
                            width: ddVolSlider.visualPosition * parent.width
                            height: parent.height
                            color: bar.isVolMuted ? Theme.colError : Theme.colPrimary
                            radius: 3
                        }
                    }
                    from: 0; to: 100
                    value: parseFloat(bar.volStr) || 0
                    Timer {
                        id: ddAudioVolTimer
                        interval: 50; repeat: false
                        property int targetVal: 100
                        onTriggered: Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.round(targetVal).toString() + "%"])
                    }
                    onMoved: { ddAudioVolTimer.targetVal = value; ddAudioVolTimer.restart(); bar.volStr = Math.round(value).toString() }
                }

                // Audio Output Sources Dropdown Toggle Button
                Item {
                    width: 22; height: 22
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        text: volBrightSplitPill.showSinkList ? "\uea62" : "\uea5f"
                        font.family: fontName
                        font.pixelSize: 16
                        color: volBrightSplitPill.showSinkList ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            volBrightSplitPill.showSinkList = !volBrightSplitPill.showSinkList;
                            if (volBrightSplitPill.showSinkList) {
                                sinkFetchProc.running = true;
                                activeSinkProc.running = true;
                            }
                        }
                    }
                }
            }

            // Audio Output Devices Picker List
            ColumnLayout {
                id: sinkListCol
                Layout.fillWidth: true
                spacing: 6
                opacity: volBrightSplitPill.showSinkList ? 1.0 : 0.0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 250 } }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.15)
                }

                Text {
                    text: "AUDIO OUTPUT"
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                    Layout.topMargin: 4
                }

                Repeater {
                    model: bar.sinkList
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 34
                        radius: 17
                        property bool isActiveSink: modelData.name === bar.activeSinkName
                        color: sinkItemMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : (isActiveSink ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.20) : Qt.rgba(1, 1, 1, 0.04))
                        border.color: isActiveSink ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.35) : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                text: (modelData.name && (modelData.name.includes("hdmi") || modelData.name.includes("HDMI"))) ? "\ueb92" : ((modelData.name && modelData.name.includes("headphone")) ? "\uea76" : "\ueb51")
                                font.family: fontName
                                font.pixelSize: 15
                                color: isActiveSink ? Theme.colPrimary : bar.fg
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.description || modelData.name
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 11
                                font.weight: isActiveSink ? Font.Bold : Font.Normal
                                color: isActiveSink ? Theme.colPrimary : bar.fg
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "\uea5e"
                                font.family: fontName
                                font.pixelSize: 14
                                color: Theme.colPrimary
                                visible: isActiveSink
                            }
                        }

                        MouseArea {
                            id: sinkItemMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["pactl", "set-default-sink", modelData.name]);
                                bar.activeSinkName = modelData.name;
                            }
                        }
                    }
                }
            }
        }
    }

    // ── CLOCK SPLIT PILL ──────────────────────────────────────────────────
    // Teardown animation: starts collapsed at the clock location inside solidBar,
    // then physically separates and slides out rightwards into a floating pill with OutBack bounce.
    Rectangle {
        id: clockSplitPill

        y: solidBar.y
        property bool menuExpanded: globalState.solidBoardOpen
        height: menuExpanded ? (clockContentCol.implicitHeight + 24) : solidBar.height
        Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

        z: -1

        readonly property real openGap: 12
        readonly property real headerW: clockOptionsRow.implicitWidth + 24
        readonly property real expandedW: 280
        property real contentW: menuExpanded ? expandedW : headerW

        // When closed: starts at the clock location inside solidBar
        // When open: slides out to the left of powerSplitPill (or far right if dropdownOpen) as solidBar shrinks
        x: globalState.solidBoardOpen ? (bar.barX + bar.barW - 36 - 12 - contentW) : (bar.dropdownOpen ? (bar.barX + bar.barW - contentW) : (bar.barX + bar.barW - 220))
        width: (globalState.solidBoardOpen || bar.dropdownOpen) ? contentW : 140
        scale: (globalState.solidBoardOpen || bar.dropdownOpen) ? 1.0 : 0.5
        transformOrigin: Item.Left

        Behavior on x     { NumberAnimation { duration: 540; easing.type: Easing.OutBack; easing.overshoot: 1.08 } }
        Behavior on width { NumberAnimation { duration: 540; easing.type: Easing.OutBack; easing.overshoot: 1.08 } }
        Behavior on scale { NumberAnimation { duration: 540; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

        radius: menuExpanded ? 16 : solidBar.radius
        Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        clip: true

        color: bar.pillColor
        border.color: Qt.rgba(1, 1, 1, 0.10)
        border.width: 1

        // Top glass highlight
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 4; anchors.rightMargin: 4
            height: 1; radius: 1
            color: Qt.rgba(1, 1, 1, 0.10)
        }

        opacity: (globalState.solidBoardOpen || bar.dropdownOpen) ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        MouseArea {
            id: clockSplitPillMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: (mouseY <= solidBar.height) ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (mouse.y <= solidBar.height) {
                    if (globalState.solidBoardOpen) {
                        globalState.solidBoardOpen = false;
                    } else {
                        bar.dropdownOpen = false;
                        globalState.powerDropdownOpen = false;
                        globalState.solidBoardOpen = true;
                    }
                }
            }
        }

        // ── Header (Clock & Date Text + Power Icon when dropdown open) ──────
        Row {
            id: clockOptionsRow
            anchors.horizontalCenter: parent.horizontalCenter
            y: (solidBar.height - height) / 2
            spacing: 4
            opacity: clockSplitPill.menuExpanded ? 0.0 : 1.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250 } }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(timeClock.date, "MMM dd • hh:mm AP")
                font.family: Theme.defaultFontFamily
                font.pixelSize: Theme.defaultFontSize
                font.weight: Theme.defaultFontWeight
                color: bar.fg
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "•"
                font.pixelSize: 8
                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                opacity: bar.dropdownOpen ? 1.0 : 0.0
                visible: opacity > 0
            }

            Item {
                width: 22; height: 26
                anchors.verticalCenter: parent.verticalCenter
                opacity: bar.dropdownOpen ? 1.0 : 0.0
                visible: opacity > 0
                Text {
                    anchors.centerIn: parent
                    text: "\ueb0d"
                    font.family: bar.fontName
                    font.pixelSize: 15
                    color: Theme.colError
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        bar.dropdownOpen = false;
                        globalState.powerDropdownOpen = true;
                    }
                }
            }
        }

        // ── Expanded Calendar & Clock View ────────────────────────────────
        ColumnLayout {
            id: clockContentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 10
            opacity: clockSplitPill.menuExpanded ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 300 } }

            // Big Accent Clock Header
            Item {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                implicitHeight: bigClockRow.implicitHeight

                Row {
                    id: bigClockRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: Qt.formatDateTime(timeClock.date, "hh AP").substring(0, 2)
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 36
                        font.weight: Font.Bold
                        color: Theme.colPrimary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: ":"
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 36
                        font.weight: Font.Bold
                        color: Theme.colOnSurface
                        opacity: 0.4
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: Qt.formatDateTime(timeClock.date, "mm")
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 36
                        font.weight: Font.Bold
                        color: Theme.colOnSurface
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1
                        Text {
                            text: Qt.formatDateTime(timeClock.date, "AP")
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Theme.colPrimary
                        }
                        Text {
                            text: Qt.formatDateTime(timeClock.date, "ddd, MMM dd")
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            color: Theme.colOnSurface
                            opacity: 0.55
                        }
                    }
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.1)
            }

            // Inline Calendar
            Column {
                Layout.fillWidth: true
                spacing: 6

                property date currentDate: new Date()

                // Month header
                Row {
                    width: parent.width
                    Text {
                        text: Qt.formatDateTime(parent.currentDate, "MMMM yyyy")
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: Theme.colOnSurface
                        width: parent.width - 48
                    }
                    Row {
                        spacing: 4
                        MouseArea {
                            width: 20; height: 20
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let d = new Date(parent.parent.currentDate);
                                d.setMonth(d.getMonth() - 1);
                                parent.parent.currentDate = d;
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "\uea60"
                                font.family: "tabler-icons"
                                font.pixelSize: 13
                                color: Theme.colOnSurface
                                opacity: 0.6
                            }
                        }
                        MouseArea {
                            width: 20; height: 20
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let d = new Date(parent.parent.currentDate);
                                d.setMonth(d.getMonth() + 1);
                                parent.parent.currentDate = d;
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "\uea61"
                                font.family: "tabler-icons"
                                font.pixelSize: 13
                                color: Theme.colOnSurface
                                opacity: 0.6
                            }
                        }
                    }
                }

                // Day of week header
                Row {
                    width: parent.width
                    Repeater {
                        model: ["Su","Mo","Tu","We","Th","Fr","Sa"]
                        Text {
                            width: (clockContentCol.width - 24) / 7
                            text: modelData
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 10
                            color: Theme.colOnSurface
                            opacity: 0.4
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // Calendar grid
                Grid {
                    id: clockCalGrid
                    width: parent.width
                    columns: 7
                    spacing: 2

                    property date currentDate: parent.currentDate
                    property int month: currentDate.getMonth()
                    property int year: currentDate.getFullYear()
                    property int firstDayOfWeek: new Date(year, month, 1).getDay()
                    property int daysInMonth: new Date(year, month + 1, 0).getDate()
                    property int daysInPrevMonth: new Date(year, month, 0).getDate()
                    property int totalCells: Math.ceil((firstDayOfWeek + daysInMonth) / 7) * 7

                    Repeater {
                        model: clockCalGrid.totalCells
                        delegate: Item {
                            width: (clockContentCol.width - 24) / 7
                            height: width

                            property int cellDay: {
                                let idx = index - clockCalGrid.firstDayOfWeek;
                                if (idx < 0) return clockCalGrid.daysInPrevMonth + idx + 1;
                                if (idx >= clockCalGrid.daysInMonth) return idx - clockCalGrid.daysInMonth + 1;
                                return idx + 1;
                            }
                            property bool isCurrentMonth: {
                                let idx = index - clockCalGrid.firstDayOfWeek;
                                return idx >= 0 && idx < clockCalGrid.daysInMonth;
                            }
                            property bool isToday: {
                                let now = new Date();
                                return isCurrentMonth &&
                                       cellDay === now.getDate() &&
                                       clockCalGrid.month === now.getMonth() &&
                                       clockCalGrid.year === now.getFullYear();
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - 2
                                height: width
                                radius: width / 2
                                color: isToday ? Theme.colPrimary : "transparent"
                            }
                            Text {
                                anchors.centerIn: parent
                                text: cellDay
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 10
                                font.weight: isToday ? Font.Bold : Font.Normal
                                color: isToday ? Theme.colOnPrimary : (isCurrentMonth ? Theme.colOnSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.25))
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }
            }
        }
    }

    // ── POWER SPLIT PILL ──────────────────────────────────────────────────
    // Teardown animation: starts collapsed at the power button location inside solidBar,
    // then physically separates and slides out rightwards into a floating pill with OutBack bounce.
    Rectangle {
        id: powerSplitPill

        y: solidBar.y
        property bool menuExpanded: globalState.powerDropdownOpen
        height: menuExpanded ? (powerMenu.implicitHeight + 20) : solidBar.height
        Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

        z: -1

        readonly property real openGap: 12
        // Hardcode contentW to prevent binding loop caused by Column's implicitWidth depending on children's width
        property real contentW: 130

        // When closed: starts at the power icon location inside solidBar
        // When open: slides out to the right as solidBar shrinks
        x: globalState.powerDropdownOpen ? (bar.barX + bar.barW - contentW) : (globalState.solidBoardOpen ? (bar.barX + bar.barW - 36) : (bar.barX + bar.barW - 40))
        width: globalState.powerDropdownOpen ? contentW : (globalState.solidBoardOpen ? 36 : 30)
        scale: (globalState.powerDropdownOpen || globalState.solidBoardOpen) ? 1.0 : 0.5
        transformOrigin: Item.Left

        Behavior on x     { NumberAnimation { duration: 540; easing.type: Easing.OutBack; easing.overshoot: 1.08 } }
        Behavior on width { NumberAnimation { duration: 540; easing.type: Easing.OutBack; easing.overshoot: 1.08 } }
        Behavior on scale { NumberAnimation { duration: 540; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

        radius: solidBar.radius
        clip: true

        color: bar.pillColor
        border.color: Qt.rgba(1, 1, 1, 0.10)
        border.width: 1

        // Top glass highlight
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 4; anchors.rightMargin: 4
            height: 1; radius: 1
            color: Qt.rgba(1, 1, 1, 0.10)
        }

        opacity: (globalState.powerDropdownOpen || globalState.solidBoardOpen) ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        MouseArea {
            id: powerSplitPillMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: (mouseY <= solidBar.height) ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (mouse.y <= solidBar.height) {
                    if (globalState.powerDropdownOpen) {
                        globalState.powerDropdownOpen = false;
                    } else {
                        bar.dropdownOpen = false;
                        globalState.solidBoardOpen = false;
                        globalState.powerDropdownOpen = true;
                    }
                }
            }
        }

        // ── Header (Power Icon + Text) ──────────────────────────────
        Row {
            id: powerOptionsRow
            anchors.horizontalCenter: parent.horizontalCenter
            y: (solidBar.height - height) / 2
            spacing: 4
            opacity: powerSplitPill.menuExpanded ? 0.0 : 1.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250 } }

            Item {
                width: 22; height: 26
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    anchors.centerIn: parent
                    text: "\ueb0d"
                    font.family: bar.fontName
                    font.pixelSize: 15
                    color: Theme.colError
                }
            }
            Text {
                id: powerPillTextLabel
                anchors.verticalCenter: parent.verticalCenter
                text: "Power"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Theme.colError
                opacity: globalState.powerDropdownOpen ? (powerSplitPill.menuExpanded ? 0.0 : 1.0) : 0.0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }
        }

        // ── Expanded Menu (Vertical) ────────────────────────────────
        Column {
            id: powerMenu
            anchors.top: parent.top
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 4
            opacity: powerSplitPill.menuExpanded ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 300 } }

            component SplitMenuBtn: Item {
                id: splitBtn
                property string icon: ""
                property string label: ""
                property color accentCol: Theme.colError
                property bool confirming: false
                signal triggered()

                width: parent.width
                implicitWidth: innerRow.implicitWidth + 16
                height: 32

                Timer { id: splitConfirmTimer; interval: 3000; onTriggered: splitBtn.confirming = false }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: splitMa.containsMouse
                           ? Qt.rgba(splitBtn.accentCol.r, splitBtn.accentCol.g, splitBtn.accentCol.b, 0.18)
                           : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                Row {
                    id: innerRow
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: splitBtn.icon
                        font.family: bar.fontName
                        font.pixelSize: 14
                        color: splitMa.containsMouse ? splitBtn.accentCol : bar.fg
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: splitBtn.confirming ? "Sure?" : splitBtn.label
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: splitBtn.confirming ? splitBtn.accentCol
                               : (splitMa.containsMouse ? splitBtn.accentCol : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.75))
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }

                MouseArea {
                    id: splitMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (splitBtn.confirming) {
                            splitBtn.confirming = false;
                            splitBtn.triggered();
                        } else {
                            splitBtn.confirming = true;
                            splitConfirmTimer.restart();
                        }
                    }
                }
            }

            SplitMenuBtn {
                icon: "\ueaf8"; label: "Sleep"
                accentCol: Theme.colPrimary
                onTriggered: { globalState.powerDropdownOpen = false; Quickshell.execDetached(["bash","-c","systemctl suspend"]); }
            }
            SplitMenuBtn {
                icon: "\ueba8"; label: "Logout"
                accentCol: Theme.colPrimary
                onTriggered: { globalState.powerDropdownOpen = false; Quickshell.execDetached(["bash","-c","hyprctl dispatch exit"]); }
            }
            SplitMenuBtn {
                icon: "\ueb13"; label: "Restart"
                accentCol: Theme.colError
                onTriggered: { globalState.powerDropdownOpen = false; Quickshell.execDetached(["bash","-c","systemctl reboot"]); }
            }
            SplitMenuBtn {
                icon: "\ueb0d"; label: "Shutdown"
                accentCol: Theme.colError
                onTriggered: { globalState.powerDropdownOpen = false; Quickshell.execDetached(["bash","-c","systemctl poweroff"]); }
            }
        }
    }

    // ─────────────────────────────────────────────────────
    //  1. FORWARD EXPANSION ANIMATION (Pill -> Solid Bar)
    // ─────────────────────────────────────────────────────
    ParallelAnimation {
        id: expandAnim
        running: false

        NumberAnimation {
            target: solidBar
            property: "x"
            from: bar.startX
            to: bar.barX
            duration: 540
            easing.type: Easing.OutBack
            easing.overshoot: 0.5
        }
        NumberAnimation {
            target: solidBar
            property: "width"
            from: bar.startW
            to: bar.barW
            duration: 540
            easing.type: Easing.OutBack
            easing.overshoot: 0.5
        }
        NumberAnimation {
            target: bar
            property: "baseHeight"
            from: bar.startHeight
            to: bar.barHeight
            duration: 540
            easing.type: Easing.OutBack
            easing.overshoot: 0.5
        }
        NumberAnimation {
            target: solidBar
            property: "radius"
            from: bar.startRadius
            to: bar.barRadius
            duration: 540
            easing.type: Easing.OutBack
            easing.overshoot: 0.5
        }
        ColorAnimation {
            target: solidBar
            property: "color"
            from: Theme.colPrimary
            to: bar.pillColor
            duration: 440
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: archHeader
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: 220
            easing.type: Easing.OutQuad
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
            solidBar.color = Qt.binding(function() { return bar.pillColor; });
            solidBar.width = Qt.binding(function() {
                return globalState.powerDropdownOpen ? (bar.barW - powerSplitPill.contentW - powerSplitPill.openGap) : (globalState.solidBoardOpen ? (bar.barW - 36 - 12 - clockSplitPill.contentW - clockSplitPill.openGap) : (bar.dropdownOpen ? (bar.barW - clockSplitPill.contentW - 12 - volBrightSplitPill.contentW - volBrightSplitPill.openGap) : (Math.abs(solidBar.x - bar.barX) < 2 ? bar.barW : bar.startW)));
            });
        }
    }

    // ─────────────────────────────────────────────────────
    //  2. REVERSE COLLAPSE ANIMATION (Solid Bar -> Pill)
    // ─────────────────────────────────────────────────────
    ParallelAnimation {
        id: collapseAnim
        running: false

        NumberAnimation {
            target: solidBar
            property: "x"
            to: bar.startX
            duration: 480
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: solidBar
            property: "width"
            to: bar.startW
            duration: 480
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: bar
            property: "baseHeight"
            to: bar.startHeight
            duration: 480
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: solidBar
            property: "radius"
            to: bar.startRadius
            duration: 480
            easing.type: Easing.InOutCubic
        }
        ColorAnimation {
            target: solidBar
            property: "color"
            to: Theme.colPrimary
            duration: 420
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: archHeader
            property: "opacity"
            to: 1.0
            duration: 250
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: contentLayout
            property: "opacity"
            to: 0.0
            duration: 200
            easing.type: Easing.InQuad
        }

        onFinished: {
            // Once collapse is complete, finalize mode change to "pill"
            globalState.barStyle = "pill";
            globalState.pendingBarStyle = "";
            solidBar.color = Qt.binding(function() { return Theme.colPrimary; });
            solidBar.width = Qt.binding(function() {
                return globalState.powerDropdownOpen ? (bar.barW - powerSplitPill.contentW - powerSplitPill.openGap) : (globalState.solidBoardOpen ? (bar.barW - 36 - 12 - clockSplitPill.contentW - clockSplitPill.openGap) : (bar.dropdownOpen ? (bar.barW - clockSplitPill.contentW - 12 - volBrightSplitPill.contentW - volBrightSplitPill.openGap) : (Math.abs(solidBar.x - bar.barX) < 2 ? bar.barW : bar.startW)));
            });
        }
    }

    function resetToArchPill() {
        collapseAnim.stop();
        expandAnim.stop();
        solidBar.x = bar.startX;
        solidBar.width = bar.startW;
        bar.baseHeight = bar.startHeight;
        solidBar.radius = bar.startRadius;
        solidBar.color = Theme.colPrimary;
        archHeader.opacity = 1.0;
        contentLayout.opacity = 0.0;
    }

    Connections {
        target: globalState
        function onBarStyleChanged() {
            if (globalState.barStyle === "solid") {
                resetToArchPill();
                expandAnim.restart();
            }
        }
        function onPendingBarStyleChanged() {
            if (globalState.pendingBarStyle === "pill") {
                expandAnim.stop();
                collapseAnim.restart();
            }
        }
    }

    Component.onCompleted: {
        if (globalState.barStyle === "solid") {
            resetToArchPill();
            expandAnim.start();
        }
    }

    // ─────────────────────────────────────────────────────
    //  BACKGROUND DATA POLLING
    // ─────────────────────────────────────────────────────
    Process {
        id: cpuProc; running: true
        command: ["bash", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print int($2+$4)}'"]
        stdout: StdioCollector { onStreamFinished: { let v = parseFloat(text); if (!isNaN(v)) bar.cpuStr = Math.round(v).toString() } }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: cpuProc.running = true }

    Process {
        id: ramProc; running: true
        command: ["bash", "-c", "free -m | awk '/Mem:/ {printf \"%.1f\", $3/1024}'"]
        stdout: StdioCollector { onStreamFinished: { if (text) bar.ramStr = text.trim() } }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: ramProc.running = true }

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
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return
                const lines = text.trim().split("\n")
                let rx = 0, tx = 0
                for (let i = 2; i < lines.length; i++) {
                    const p = lines[i].trim().split(/\s+/)
                    if (p.length >= 10 && (p[0].startsWith("en") || p[0].startsWith("wl") || p[0].startsWith("eth"))) {
                        rx += parseInt(p[1]) || 0; tx += parseInt(p[9]) || 0
                    }
                }
                if (netProc.lastRx > 0) {
                    let d = Math.max(0, (rx - netProc.lastRx) + (tx - netProc.lastTx))
                    bar.netStr = d >= 1048576 ? (d/1048576).toFixed(1) + " MB/s" : Math.round(d/1024) + " KB/s"
                }
                netProc.lastRx = rx; netProc.lastTx = tx
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: netProc.running = true }

    Process {
        id: netTypeProc; running: true
        command: ["bash", "-c", "echo '---nmcli---'; nmcli -t -f NAME,TYPE,STATE con show --active; echo '---bt---'; bluetoothctl show; echo '---bt-conn---'; bluetoothctl devices Connected"]
        stdout: StdioCollector {
            onStreamFinished: { 
                let t = text.toLowerCase();
                bar.isWifi = t.includes("802-11-wireless") && !t.includes("hotspot");
                bar.isWired = t.includes("802-3-ethernet");
                bar.isHotspot = t.includes("hotspot");
                bar.isBluetooth = t.includes("powered: yes");
                bar.isBluetoothConnected = t.includes("---bt-conn---\ndevice");
            }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: netTypeProc.running = true }
}
