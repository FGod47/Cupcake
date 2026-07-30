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
    height: 160
    color: "transparent"
    mask: Region { item: solidBar }

    property real baseHeight: startHeight
    property bool dropdownOpen: false
    property real extraHeight: dropdownOpen ? 120 : 0
    Behavior on extraHeight { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

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


    property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
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

    // ─────────────────────────────────────────────────────
    //  MORPHING BAR (Starts exactly as archPill, expands into solid bar)
    // ─────────────────────────────────────────────────────
    Rectangle {
        id: solidBar
        y: bar.midY
        x: bar.startX
        width: bar.startW
        height: bar.baseHeight + bar.extraHeight
        radius: bar.startRadius
        color: Theme.colPrimary
        clip: true

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
            anchors.leftMargin: 13; anchors.rightMargin: 13
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
                        
                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                        Rectangle {
                            id: wsRect
                            anchors.centerIn: parent
                            width: parent.width
                            height: isFocused ? 6 : (wsMouse.containsMouse ? 6 : 4)
                            radius: height / 2
                            color: isFocused ? Theme.colPrimary : (isOccupied ? Qt.rgba(fg.r, fg.g, fg.b, 0.5) : Qt.rgba(fg.r, fg.g, fg.b, 0.2))
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
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
                    onClicked: bar.dropdownOpen = !bar.dropdownOpen
                    
                    Row {
                        height: 20
                        spacing: bMouse.containsMouse ? 8 : 0
                        Behavior on spacing { NumberAnimation { duration: 200 } }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\ueb30" // tabler icon for sun (brightness)
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
                            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
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
                    
                    onClicked: bar.dropdownOpen = !bar.dropdownOpen
                    
                    Row {
                        height: 20
                        spacing: vMouse.containsMouse ? 8 : 0
                        Behavior on spacing { NumberAnimation { duration: 200 } }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\ueb51" // tabler icon for volume
                            font.family: fontName
                            font.pixelSize: 15
                            color: fg
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
                            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
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
            }
            
            // ── RIGHT: Clock ────────
            Text {
                Layout.alignment: Qt.AlignVCenter
                text: Qt.formatDateTime(timeClock.date, "MMM dd • hh:mm AP")
                font.family: Theme.defaultFontFamily
                font.pixelSize: Theme.defaultFontSize
                font.weight: Theme.defaultFontWeight
                color: fg
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                text: "•"
                font.pixelSize: 8
                color: Qt.rgba(fg.r, fg.g, fg.b, 0.4)
            }
            // ── RIGHT: Power Pill ────────
            // Hover: shows "Power" text. Click: shows Shutdown/Restart/Logout icons.
            Item {
                id: powerPillItem
                Layout.alignment: Qt.AlignVCenter
                height: 26
                implicitWidth: powerPillInner.implicitWidth

                property bool expanded: false  // true after clicking
                onExpandedChanged: {
                    if (!expanded) {
                        logoutBtn.confirming = false
                        restartBtn.confirming = false
                        shutdownBtn.confirming = false
                    }
                }
                
                property bool isHovered: hoverMa.containsMouse || powerMa.containsMouse || logoutMa.containsMouse || restartMa.containsMouse
                onIsHoveredChanged: {
                    if (!isHovered && expanded) {
                        expanded = false
                    }
                }

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
                        clip: true
                        property bool confirming: false
                        Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
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
                        clip: true
                        property bool confirming: false
                        Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
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
                                    text: "\ueb71"
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
                        width: shutdownRow.implicitWidth
                        clip: true
                        property bool confirming: false
                        Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
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
                                anchors.verticalCenter: parent.verticalCenter
                                text: shutdownBtn.confirming ? "Sure?" : "Shutdown"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: powerMa.containsMouse ? Theme.colError : fg
                                width: powerPillItem.expanded ? implicitWidth : 0
                                clip: true
                                Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
                                rightPadding: 8
                            }
                        }
                        MouseArea {
                            id: powerMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (powerPillItem.expanded) {
                                    if (shutdownBtn.confirming) {
                                        powerPillItem.expanded = false;
                                        shutdownBtn.confirming = false;
                                        Quickshell.execDetached(["bash", "-c", "systemctl poweroff"]);
                                    } else {
                                        shutdownBtn.confirming = true;
                                        shutdownTimer.restart();
                                    }
                                } else {
                                    powerPillItem.expanded = true
                                }
                            }
                        }
                    }

                    // ── "Power" label — slides in on initial hover, hidden when expanded ──
                    Text {
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        text: "Power"
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 12
                        font.weight: Theme.defaultFontWeight
                        color: Theme.colError
                        width: (!powerPillItem.expanded && powerPillItem.isHovered) ? implicitWidth + 8 : 0
                        clip: true
                        Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
                        rightPadding: 8
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: powerPillItem.expanded = true
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
        }

        // ── DROPDOWN (Brightness & Volume) ────────
        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: contentLayout.bottom
            anchors.bottom: parent.bottom
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            anchors.topMargin: 8
            anchors.bottomMargin: 16
            spacing: 12
            opacity: bar.dropdownOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
            visible: opacity > 0
            
            // Brightness Slider
            Row {
                width: parent.width
                spacing: 16
                Text {
                    text: "\ueb30" // sun icon
                    font.family: fontName
                    font.pixelSize: 20
                    color: fg
                    anchors.verticalCenter: parent.verticalCenter
                }
                Slider {
                    id: ddBrightSlider
                    width: parent.width - 40
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true
                    handle: Rectangle {
                        x: ddBrightSlider.leftPadding + ddBrightSlider.visualPosition * (ddBrightSlider.availableWidth - width)
                        y: ddBrightSlider.height / 2 - height / 2
                        width: 16; height: 16; radius: 8
                        color: Theme.colPrimary
                    }
                    background: Rectangle {
                        x: ddBrightSlider.leftPadding
                        y: ddBrightSlider.height / 2 - height / 2
                        implicitWidth: 100
                        implicitHeight: 8
                        width: ddBrightSlider.availableWidth
                        height: implicitHeight
                        radius: 4
                        color: Qt.rgba(fg.r, fg.g, fg.b, 0.2)
                        Rectangle {
                            width: ddBrightSlider.visualPosition * parent.width
                            height: parent.height
                            color: Theme.colPrimary
                            radius: 4
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

            // Volume Slider
            Row {
                width: parent.width
                spacing: 16
                Text {
                    text: "\ueb51" // volume icon
                    font.family: fontName
                    font.pixelSize: 20
                    color: fg
                    anchors.verticalCenter: parent.verticalCenter
                }
                Slider {
                    id: ddVolSlider
                    width: parent.width - 40
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true
                    handle: Rectangle {
                        x: ddVolSlider.leftPadding + ddVolSlider.visualPosition * (ddVolSlider.availableWidth - width)
                        y: ddVolSlider.height / 2 - height / 2
                        width: 16; height: 16; radius: 8
                        color: Theme.colPrimary
                    }
                    background: Rectangle {
                        x: ddVolSlider.leftPadding
                        y: ddVolSlider.height / 2 - height / 2
                        implicitWidth: 100
                        implicitHeight: 8
                        width: ddVolSlider.availableWidth
                        height: implicitHeight
                        radius: 4
                        color: Qt.rgba(fg.r, fg.g, fg.b, 0.2)
                        Rectangle {
                            width: ddVolSlider.visualPosition * parent.width
                            height: parent.height
                            color: Theme.colPrimary
                            radius: 4
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
