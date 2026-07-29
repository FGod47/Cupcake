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
import "../settings"
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: bar
    property string rxSpeedStr: "0 KB/s"
    property string hwStr: ""
    property string recStr: ""
    property string clockStr: ""
    property int audioVal: 50
    property int lightVal: 50
    property bool isDestroying: false
    Component.onDestruction: isDestroying = true
    anchors {
        top: true
        left: true
        right: true
    }
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 40

    HyprlandFocusGrab {
        windows: [bar]
        active: globalState.settingsOpen || bar.ccOpen || archPill.isExpanded || globalState.powerMenuOpen
    }

    // Track active player status for Dynamic Island animations
    property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool hasPlayer: activePlayer !== null
    property bool isMusicPlaying: hasPlayer && activePlayer.isPlaying

    // and to allow the Settings menu to animate to the center of the screen
    implicitHeight: modelData.height
    color: "transparent"

    ParallelAnimation {
        id: pillEntranceAnim
        running: false

        NumberAnimation {
            target: mainBarStrip
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 400
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: mainBarStrip
            property: "scale"
            from: 0.94
            to: 1.0
            duration: 400
            easing.type: Easing.OutBack
            easing.overshoot: 0.4
        }
        NumberAnimation {
            target: archPill
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 400
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: archPill
            property: "scale"
            from: 0.94
            to: 1.0
            duration: 400
            easing.type: Easing.OutBack
            easing.overshoot: 0.4
        }
        NumberAnimation {
            target: powerPill
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 400
            easing.type: Easing.OutCubic
        }
    }

    onVisibleChanged: {
        if (visible) {
            mainBarStrip.opacity = 0.0;
            mainBarStrip.scale = 0.94;
            archPill.opacity = 0.0;
            archPill.scale = 0.94;
            powerPill.opacity = 0.0;
            pillEntranceAnim.restart();
        }
    }
    
    property bool ccOpen: false
    mask: (globalState.settingsOpen || ccOpen || archPill.isExpanded || powerPill.actionsExpanded || globalState.overviewOpen) ? null : normalMask
    
    Region {
        id: normalMask
        Region { item: leftModules }
        Region { item: archPill }
        Region { item: networkPill }
        Region { item: hwPill }
        Region { item: recPill }
        Region { item: trayPill }
        Region { item: controlsPill }
        Region { item: clockWrapper }
        Region { item: powerPill }
    }

    property var modelData
    screen: modelData
    


    SystemClock {
        id: timeClock
        precision: SystemClock.Minutes 
    }

    // Shared style definitions based on user's style.css
    property color bg: Theme.colSurface
    property color fg: Theme.colOnSurface
    property string fontName: "tabler-icons"
    property int fontSize: Theme.defaultFontSize

    MouseArea {
        id: fullScreenClickAway
        anchors.fill: parent
        enabled: globalState.settingsOpen || bar.ccOpen || archPill.isExpanded || powerPill.actionsExpanded
        onClicked: {
            globalState.settingsOpen = false;
            bar.ccOpen = false;
            if (archPill.isExpanded) {
                archPill.isExpanded = false;
            }
            if (globalState.powerMenuOpen) {
                globalState.powerMenuOpen = false;
            }
            if (powerPill.confirmingDefault) {
                powerPill.confirmingDefault = false;
            }
        }
        z: -1
    }

    // padding 0 16px translates to implicitWidth = contentItem.width + 32
    // margin: 8px 4px 0 4px is handled by Layout properties or anchors

    Item {
        id: mainBarStrip
        // Fixed 46px top strip — never resizes when bar grows
        z: 1
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.max(40, clockPill.height + 16, powerPill.height + 16)

        // Inner wrapper to keep the original padding logic identical
        Item {
            anchors.fill: parent
            anchors.topMargin: 8
            anchors.leftMargin: 8
            anchors.rightMargin: 8

        // =======================
        // LEFT MODULES
        // =======================
        Row {
            id: leftModules
            anchors.left: parent.left
            anchors.top: parent.top
            spacing: 8
            
            visible: true
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            // Workspaces Pill (#workspaces)
            Rectangle {
                color: Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity)
                radius: 18
                implicitHeight: 34
                implicitWidth: 168 // 5 * 32px + 8px padding
                Layout.alignment: Qt.AlignVCenter
                
                // Seamless slide highlight bubble
                Rectangle {
                    id: workspaceHighlight
                    width: 26
                    height: 26
                    radius: 13
                    color: Theme.colPrimary
                    
                    property int activeWs: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
                    property int validIndex: Math.max(0, Math.min(activeWs - 1, 4))
                    
                    x: 7 + 32 * validIndex
                    y: 4
                    opacity: (activeWs >= 1 && activeWs <= 5) ? 1 : 0
                    
                    Behavior on x { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                
                Row {
                    id: workspaceRow
                    anchors.centerIn: parent
                    spacing: 0
                    
                    Repeater {
                        model: 5
                        delegate: Item {
                            width: 32
                            height: 34
                            property int wsId: index + 1
                            property bool isFocused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
                            property bool isOccupied: isFocused || Hyprland.workspaces.values.some(ws => ws.id === wsId)

                            // Inner Dot (For focused, occupied, or empty)
                            Rectangle {
                                anchors.centerIn: parent
                                width: isFocused ? 6 : (isOccupied ? 8 : 6)
                                height: width
                                radius: width / 2
                                color: isFocused ? Theme.colOnPrimary : (isOccupied ? fg : Qt.rgba(fg.r, fg.g, fg.b, 0.4))
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 150; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: function(mouse) {
                                    Hyprland.dispatch("hl.dsp.focus({workspace = " + wsId + "})")
                                }
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                }
            }

            // Active Window Pill (#window)
            Rectangle {
                id: windowPill
                radius: 18
                implicitHeight: 34
                color: Theme.colPrimary
                implicitWidth: windowText.implicitWidth > 0 ? Math.min(windowText.implicitWidth, 400) + 32 : 0
                Layout.alignment: Qt.AlignVCenter
                visible: Hyprland.activeToplevel && Hyprland.activeToplevel.title !== ""
                clip: true
                Behavior on implicitWidth { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                
                Text {
                    id: windowText
                    anchors.centerIn: parent
                    text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
                    color: Theme.colSurfaceContainerHigh
                    font.family: Theme.defaultFontFamily
                    font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                    style: Text.Normal
                    renderType: Text.NativeRendering
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    width: Math.min(implicitWidth, 400)
                }
            }
        }



        // =======================
        // RIGHT MODULES
        // =======================
        Row {
            id: rightModules
            anchors.right: parent.right
            anchors.rightMargin: actualMargin
            anchors.top: parent.top
            spacing: 8
            
            property real targetRightMargin: powerPill.targetWidth + 8
            property real actualMargin: targetRightMargin
            Behavior on actualMargin { NumberAnimation { duration: 400; easing.type: Easing.InOutCubic } }
            
            visible: true
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            // Network Pill
            Rectangle {
                id: networkPill
                
                property bool isWifi: false
                property bool isWired: false
                property bool hotspotActive: false
                property string hotspotName: ""
                property string activeWifiName: ""
                property bool btPowered: false
                property string btConnectedDevice: ""
                property int signalPct: 78
                property bool isHovered: netHoverArea.containsMouse
                
                color: Theme.colPrimary
                radius: 17
                implicitHeight: 34
                implicitWidth: networkRow.implicitWidth + 24
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { ColorAnimation { duration: 300 } }
                property real lastRx: 0
                property real lastTx: 0

                MouseArea {
                    id: netHoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                }
                
                Row {
                    id: networkRow
                    anchors.centerIn: parent
                    spacing: 6

                    // 1. Hotspot Badge
                    Row {
                        spacing: 4
                        visible: networkPill.hotspotActive && !powerPill.actionsExpanded && !controlsPill.actionsExpanded && !clockPill.hasDropdown
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: "\ued1b"
                            color: Theme.colOnPrimary
                            font.family: fontName
                            font.weight: Theme.defaultFontWeight
                            font.pixelSize: Theme.defaultFontSize
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Text {
                            text: networkPill.hotspotName
                            color: Theme.colOnPrimary
                            font.family: Theme.defaultFontFamily
                            font.weight: Font.DemiBold
                            font.pixelSize: Theme.defaultFontSize - 1
                            anchors.verticalCenter: parent.verticalCenter
                            width: networkPill.isHovered ? implicitWidth : 0
                            clip: true
                            Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 500; easing.type: Theme.liquidify ? Easing.OutElastic : (networkPill.isHovered ? Easing.OutBack : Easing.InOutCubic); easing.amplitude: 1.0; easing.period: 0.85; easing.overshoot: 1.5 } }
                        }
                    }


                    // 2. Bluetooth Badge
                    Row {
                        spacing: 4
                        visible: networkPill.btPowered && !powerPill.actionsExpanded && !controlsPill.actionsExpanded && !clockPill.hasDropdown
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: networkPill.btConnectedDevice !== "" ? "\uecea" : "\uea37"
                            color: Theme.colOnPrimary
                            font.family: fontName
                            font.weight: Theme.defaultFontWeight
                            font.pixelSize: Theme.defaultFontSize
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Text {
                            text: networkPill.btConnectedDevice
                            color: Theme.colOnPrimary
                            font.family: Theme.defaultFontFamily
                            font.weight: Font.DemiBold
                            font.pixelSize: Theme.defaultFontSize - 1
                            anchors.verticalCenter: parent.verticalCenter
                            width: (networkPill.isHovered && networkPill.btConnectedDevice !== "") ? implicitWidth : 0
                            clip: true
                            Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 500; easing.type: Theme.liquidify ? Easing.OutElastic : (networkPill.isHovered ? Easing.OutBack : Easing.InOutCubic); easing.amplitude: 1.0; easing.period: 0.85; easing.overshoot: 1.5 } }
                        }
                    }

                    // 3. Wi-Fi Badge
                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter
                        visible: networkPill.isWifi
                        
                        Text {
                            text: {
                                let pct = networkPill.signalPct;
                                if (pct >= 75) return "\ueb52";      // wifi
                                if (pct >= 50) return "\ueba5";      // wifi-2
                                if (pct >= 25) return "\ueba4";      // wifi-1
                                return "\ueba3";                     // wifi-0
                            }
                            color: Theme.colOnPrimary
                            font.family: fontName
                            font.weight: Theme.defaultFontWeight
                            font.pixelSize: Theme.defaultFontSize
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: networkPill.activeWifiName
                            color: Theme.colOnPrimary
                            font.family: Theme.defaultFontFamily
                            font.weight: Font.DemiBold
                            font.pixelSize: Theme.defaultFontSize - 1
                            anchors.verticalCenter: parent.verticalCenter
                            width: (text !== "" && !powerPill.actionsExpanded && !controlsPill.actionsExpanded && !clockPill.hasDropdown) ? implicitWidth : 0
                            clip: true
                            Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 500; easing.type: Theme.liquidify ? Easing.OutElastic : (networkPill.isHovered ? Easing.OutBack : Easing.InOutCubic); easing.amplitude: 1.0; easing.period: 0.85; easing.overshoot: 1.5 } }
                        }
                    }


                    // 4. Wired Badge
                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter
                        visible: networkPill.isWired
                        
                        Text {
                            text: "\uebd9"
                            color: Theme.colOnPrimary
                            font.family: fontName
                            font.weight: Theme.defaultFontWeight
                            font.pixelSize: Theme.defaultFontSize
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Wired"
                            color: Theme.colOnPrimary
                            font.family: Theme.defaultFontFamily
                            font.weight: Font.DemiBold
                            font.pixelSize: Theme.defaultFontSize - 1
                            anchors.verticalCenter: parent.verticalCenter
                            width: (!powerPill.actionsExpanded && !controlsPill.actionsExpanded && !clockPill.hasDropdown) ? implicitWidth : 0
                            clip: true
                            Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 500; easing.type: Theme.liquidify ? Easing.OutElastic : (networkPill.isHovered ? Easing.OutBack : Easing.InOutCubic); easing.amplitude: 1.0; easing.period: 0.85; easing.overshoot: 1.5 } }
                        }
                    }

                    // Thin Vertical Hairline Separator
                    Rectangle {
                        width: ((networkPill.isWired || networkPill.isWifi) && !powerPill.actionsExpanded && !controlsPill.actionsExpanded && !clockPill.hasDropdown) ? 1 : 0
                        height: 13
                        color: Theme.colOnPrimary
                        opacity: 0.3
                        anchors.verticalCenter: parent.verticalCenter
                        clip: true
                        Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 500; easing.type: Theme.liquidify ? Easing.OutElastic : (networkPill.isHovered ? Easing.OutBack : Easing.InOutCubic); easing.amplitude: 1.0; easing.period: 0.85; easing.overshoot: 1.5 } }
                    }

                    // Network Speed Traffic Badge
                    Row {
                        spacing: 3
                        anchors.verticalCenter: parent.verticalCenter
                        width: ((networkPill.isWired || networkPill.isWifi) && !powerPill.actionsExpanded && !controlsPill.actionsExpanded && !clockPill.hasDropdown) ? implicitWidth : 0
                        clip: true
                        Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 500; easing.type: Theme.liquidify ? Easing.OutElastic : (networkPill.isHovered ? Easing.OutBack : Easing.InOutCubic); easing.amplitude: 1.0; easing.period: 0.85; easing.overshoot: 1.5 } }

                        Text {
                            id: rxSpeedText
                            text: bar.rxSpeedStr
                            color: Qt.rgba(Theme.colOnPrimary.r, Theme.colOnPrimary.g, Theme.colOnPrimary.b, 0.8)
                            font.family: Theme.defaultFontFamily
                            font.weight: Theme.defaultFontWeight
                            font.pixelSize: Theme.defaultFontSize - 1
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                
                Process {
                    id: networkProc
                    command: ["bash", "-c", "nmcli -t -f TYPE,STATE,CONNECTION d 2>/dev/null; echo '---'; nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null | grep '^\\*'; echo '---'; nmcli -g 802-11-wireless.ssid con show \"$(nmcli -t -f TYPE,STATE,CONNECTION d 2>/dev/null | grep '^wifi:connected:' | cut -d: -f3-)\" 2>/dev/null || true"]
                    running: true
                    stdout: StdioCollector {
                        onStreamFinished: () => {
                            if (bar.isDestroying) return;
                            if (!text) {
                                networkPill.isWifi = false;
                                networkPill.isWired = false;
                                networkPill.activeWifiName = "";
                                return;
                            }
                            const sections = text.trim().split("---");
                            const lines = sections[0].trim().split("\n");
                            let activeWifi = "";
                            let activeEthernet = false;

                            for (let i = 0; i < lines.length; i++) {
                                const parts = lines[i].split(":");
                                if (parts.length >= 3) {
                                    if (parts[0] === "wifi" && parts[1] === "connected") {
                                        activeWifi = parts.slice(2).join(":");
                                    } else if (parts[0] === "ethernet" && parts[1] === "connected") {
                                        activeEthernet = true;
                                    }
                                }
                            }

                            if (sections.length > 1 && sections[1].trim() !== "") {
                                const sigParts = sections[1].trim().split(":");
                                if (sigParts.length >= 2) {
                                    networkPill.signalPct = parseInt(sigParts[1]) || 75;
                                }
                            }

                            const isHotspot = activeWifi.toLowerCase().includes("hotspot");
                            const realSsid = (sections.length > 2) ? sections[2].trim() : "";
                            networkPill.hotspotActive = isHotspot;
                            networkPill.hotspotName = isHotspot ? (realSsid || activeWifi) : "";
                            networkPill.isWifi = (activeWifi !== "" && !isHotspot);
                            networkPill.isWired = activeEthernet;
                            networkPill.activeWifiName = isHotspot ? "" : activeWifi;
                        }
                    }
                }
                
                Timer {
                    interval: 2000; running: true; repeat: true
                    onTriggered: networkProc.running = true
                }

                Process {
                    id: btProc
                    command: ["bash", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 'powered' || exit 0; bluetoothctl devices Connected 2>/dev/null | head -n1 | cut -d' ' -f3-"]
                    running: true
                    stdout: StdioCollector {
                        onStreamFinished: () => {
                            if (bar.isDestroying) return;
                            if (!text) {
                                networkPill.btPowered = false;
                                networkPill.btConnectedDevice = "";
                                return;
                            }
                            const lines = text.trim().split("\n");
                            networkPill.btPowered = lines.length > 0 && lines[0] === "powered";
                            if (lines.length > 1 && lines[1] !== "") {
                                networkPill.btConnectedDevice = lines[1];
                            } else {
                                networkPill.btConnectedDevice = "";
                            }
                        }
                    }
                }

                Timer {
                    interval: 3000; running: true; repeat: true
                    onTriggered: btProc.running = true
                }
                
                Process {
                    id: speedProc
                    command: ["cat", "/proc/net/dev"]
                    running: true
                    stdout: StdioCollector {
                        onStreamFinished: () => {
                            if (bar.isDestroying) return;
                            if (!text) return;
                            const lines = text.trim().split("\n");
                            let totalRx = 0;
                            let totalTx = 0;
                            for (let i = 2; i < lines.length; i++) {
                                const parts = lines[i].trim().split(/\s+/);
                                if (parts.length >= 10 && (parts[0].startsWith("en") || parts[0].startsWith("wl") || parts[0].startsWith("eth"))) {
                                    totalRx += parseInt(parts[1]);
                                    totalTx += parseInt(parts[9]);
                                }
                            }
                            
                            if (networkPill.lastRx > 0 && networkPill.lastTx > 0) {
                                let rxDiff = totalRx - networkPill.lastRx;
                                let txDiff = totalTx - networkPill.lastTx;
                                
                                let formatSpeed = (bytes) => {
                                    if (bytes >= 1048576) return (bytes / 1048576).toFixed(1) + " MB/s";
                                    return (bytes / 1024).toFixed(0) + " KB/s";
                                }
                                bar.rxSpeedStr = formatSpeed(rxDiff + txDiff);
                            } else {
                                bar.rxSpeedStr = "0 KB/s";
                            }
                            networkPill.lastRx = totalRx;
                            networkPill.lastTx = totalTx;
                        }
                    }
                }
                
                Timer {
                    interval: 1000; running: true; repeat: true
                    onTriggered: speedProc.running = true
                }

            }

            // Hardware Pill
            Rectangle {
                radius: 18
                implicitHeight: 34
                id: hwPill
                implicitWidth: hwText.implicitWidth + 32
                Layout.alignment: Qt.AlignVCenter
                color: Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity) // from custom-hw gradient
                Text {
                    id: hwText
                    anchors.centerIn: parent
                    text: bar.hwStr
                    color: Theme.colOnSurfaceVariant
                    font.family: fontName
                    font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                }
                Process {
                    id: hwProc
                    command: ["sh", "-c", "~/.config/cupcake/scripts/hw_toggle_display.sh"]
                    running: true
                    stdout: StdioCollector {
                        onStreamFinished: () => {
                            if (bar.isDestroying) return;
                            let data = text;
                            try { bar.hwStr = JSON.parse(data).text || "" } catch(e) { bar.hwStr = data || "" }
                            hwPill.visible = bar.hwStr !== ""
                        }
                    }
                }
                Timer {
                    interval: 1000; running: true; repeat: true
                    onTriggered: hwProc.running = true
                }
                MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached("~/.config/cupcake/scripts/hw_toggle_state.sh") }
            }

            // Recording Pill
            Rectangle {
                color: Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity)
                radius: 18
                implicitHeight: 34
                id: recPill
                implicitWidth: recText.implicitWidth + 32
                Layout.alignment: Qt.AlignVCenter
                Text {
                    id: recText
                    anchors.centerIn: parent
                    text: bar.recStr
                    color: fg
                    font.family: fontName
                    font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                }
                Process {
                    id: recProc
                    command: ["sh", "-c", "~/.config/cupcake/scripts/rec-status.sh"]
                    running: true
                    stdout: StdioCollector {
                        onStreamFinished: () => {
                            if (bar.isDestroying) return;
                            let data = text;
                            try { bar.recStr = JSON.parse(data).text || "" } catch(e) { bar.recStr = data || "" }
                            recPill.visible = bar.recStr !== ""
                        }
                    }
                }
                Timer {
                    interval: 1000; running: true; repeat: true
                    onTriggered: recProc.running = true
                }
            }

            // Tray Pill
            Rectangle {
                id: trayPill
                color: Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity)
                radius: 18
                implicitHeight: 34
                implicitWidth: trayRow.implicitWidth + 32
                Layout.alignment: Qt.AlignVCenter
                Row {
                    id: trayRow
                    anchors.centerIn: parent
                    spacing: 8
                    
                    Repeater {
                        model: SystemTray.items
                        delegate: Image {
                            source: modelData.icon || ""
                            sourceSize: Qt.size(18, 18)
                            width: 18
                            height: 18
                            fillMode: Image.PreserveAspectFit
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.LeftButton) {
                                        modelData.activate()
                                    } else if (mouse.button === Qt.RightButton) {
                                        if (modelData.hasMenu) {
                                            var pos = mapToItem(bar.contentItem, mouse.x, mouse.y)
                                            modelData.display(bar, pos.x, pos.y)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Controls Pill (#control)
            Rectangle {
                id: controlsPill
                color: Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity)
                radius: 18
                implicitHeight: 34
                implicitWidth: controlsRow.implicitWidth + 32
                clip: true
                
                property bool actionsExpanded: false
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: controlsPill.actionsExpanded = !controlsPill.actionsExpanded
                    cursorShape: Qt.PointingHandCursor
                }
                
                Row {
                    id: controlsRow
                    anchors.centerIn: parent
                    spacing: 12
                    
                    // Audio
                    Row {
                        spacing: 0
                        Text { text: audioSlider.value === 0 ? "" : (audioSlider.value < 50 ? "" : ""); color: fg; font.family: fontName; font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize; anchors.verticalCenter: parent.verticalCenter }
                        Slider {
                            id: audioSlider
                            leftPadding: 8
                            width: controlsPill.actionsExpanded ? 108 : 0
                            clip: true
                            handle: Rectangle {
                                x: audioSlider.leftPadding + audioSlider.visualPosition * (audioSlider.availableWidth - width)
                                y: audioSlider.topPadding + audioSlider.availableHeight / 2 - height / 2
                                width: 14; height: 14
                                color: "transparent"
                            }
                            background: Rectangle {
                                x: audioSlider.leftPadding
                                y: audioSlider.topPadding + audioSlider.availableHeight / 2 - height / 2
                                implicitWidth: 100
                                implicitHeight: 14
                                width: audioSlider.availableWidth
                                height: implicitHeight
                                radius: 7
                                color: Theme.colSurfaceContainerHigh // track color
                                Rectangle {
                                    width: audioSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: Theme.colPrimary // fill color
                                    radius: 7
                                }
                            }
                            Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 500; easing.type: Theme.liquidify ? Easing.OutElastic : (controlsPill.actionsExpanded ? Easing.OutBack : Easing.InOutCubic); easing.amplitude: 1.0; easing.period: 0.85; easing.overshoot: 1.5 } }
                            from: 0; to: 100; value: 50
                            anchors.verticalCenter: parent.verticalCenter
                            Timer {
                                id: audioVolTimer
                                interval: 50; repeat: false
                                property int targetVal: 100
                                onTriggered: Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.round(targetVal).toString() + "%"])
                            }
                            onMoved: { audioVolTimer.targetVal = value; audioVolTimer.restart(); bar.audioVal = Math.round(value) }
                        }
                        Text {
                            leftPadding: 8
                            text: bar.audioVal + "%"
                            color: fg; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight
                            width: (controlsHover.hovered || controlsPill.actionsExpanded) ? implicitWidth : 0
                            clip: true
                            Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 500; easing.type: Theme.liquidify ? Easing.OutElastic : ((controlsHover.hovered || controlsPill.actionsExpanded) ? Easing.OutBack : Easing.InOutCubic); easing.amplitude: 1.0; easing.period: 0.85; easing.overshoot: 1.5 } }
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    // Backlight
                    Row {
                        spacing: 0
                        Text { text: lightSlider.value < 33 ? "\uf237" : (lightSlider.value < 66 ? "\ueb30" : "\uf236"); color: fg; font.family: fontName; font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize; anchors.verticalCenter: parent.verticalCenter }
                        Slider {
                            id: lightSlider
                            leftPadding: 8
                            width: controlsPill.actionsExpanded ? 108 : 0
                            clip: true
                            handle: Rectangle {
                                x: lightSlider.leftPadding + lightSlider.visualPosition * (lightSlider.availableWidth - width)
                                y: lightSlider.topPadding + lightSlider.availableHeight / 2 - height / 2
                                width: 14; height: 14
                                color: "transparent"
                            }
                            background: Rectangle {
                                x: lightSlider.leftPadding
                                y: lightSlider.topPadding + lightSlider.availableHeight / 2 - height / 2
                                implicitWidth: 100
                                implicitHeight: 14
                                width: lightSlider.availableWidth
                                height: implicitHeight
                                radius: 7
                                color: Theme.colSurfaceContainerHigh // track color
                                Rectangle {
                                    width: lightSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: Theme.colSecondary // fill color
                                    radius: 7
                                }
                            }
                            Timer {
                                id: ddcTimer
                                interval: 500
                                repeat: false
                                property int targetValue: 100
                                onTriggered: Quickshell.execDetached(["ddcutil", "setvcp", "10", Math.round(targetValue).toString(), "--noverify"])
                            }
                            onMoved: { 
                                ddcTimer.targetValue = value;
                                ddcTimer.restart();
                            }
                            onPressedChanged: {
                                if (!pressed) {
                                    ddcTimer.stop();
                                    Quickshell.execDetached(["ddcutil", "setvcp", "10", Math.round(value).toString()]);
                                }
                            }
                            Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 500; easing.type: Theme.liquidify ? Easing.OutElastic : (controlsPill.actionsExpanded ? Easing.OutBack : Easing.InOutCubic); easing.amplitude: 1.0; easing.period: 0.85; easing.overshoot: 1.5 } }
                            from: 0; to: 100; value: 50
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            leftPadding: 8
                            text: bar.lightVal + "%"
                            color: fg; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight
                            width: (controlsHover.hovered || controlsPill.actionsExpanded) ? implicitWidth : 0
                            clip: true
                            Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 500; easing.type: Theme.liquidify ? Easing.OutElastic : ((controlsHover.hovered || controlsPill.actionsExpanded) ? Easing.OutBack : Easing.InOutCubic); easing.amplitude: 1.0; easing.period: 0.85; easing.overshoot: 1.5 } }
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                HoverHandler { 
                    id: controlsHover 
                    onHoveredChanged: {
                        if (!hovered && controlsPill.actionsExpanded) {
                            controlsPill.actionsExpanded = false;
                        }
                    }
                }

                // Audio fetch process — at pill level like ControlCenterUI pattern
                Process {
                    id: audioProc
                    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
                    stdout: StdioCollector { id: audioProcOut }
                    onExited: {
                        if (bar.isDestroying) return;
                        let t = (audioProcOut.text || "").trim();
                        let match = t.match(/Volume:\s+([\d\.]+)/);
                        if (match && match[1]) {
                            let val = Math.round(parseFloat(match[1]) * 100);
                            if (!isNaN(val) && !audioSlider.pressed) {
                                bar.audioVal = val;
                                try { audioSlider.value = val; } catch(e) {}
                            }
                        }
                    }
                }
                // Brightness fetch process — at pill level like ControlCenterUI pattern
                Process {
                    id: lightProc
                    command: ["ddcutil", "getvcp", "10", "--terse"]
                    stdout: StdioCollector { id: lightProcOut }
                    onExited: {
                        if (bar.isDestroying) return;
                        let t = (lightProcOut.text || "");
                        let match = t.match(/VCP\s+10\s+[A-Za-z]+\s+(\d+)/);
                        if (match && match[1]) {
                            let val = parseInt(match[1]);
                            if (!isNaN(val) && !lightSlider.pressed) {
                                bar.lightVal = val;
                                try { lightSlider.value = val; } catch(e) {}
                            }
                        }
                    }
                }
                // Volume polls every 2s while pill is open (wpctl is instant)
                Timer {
                    id: controlsSliderTimer
                    interval: 2000
                    running: controlsPill.actionsExpanded
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: audioProc.running = true
                }
                // Brightness fetched once when pill opens — ddcutil is slow (I2C)
                // repeated calls pile up and cause slider glitching
                Timer {
                    id: barLightInitTimer
                    interval: 50
                    repeat: false
                    onTriggered: {
                        if (!lightProc.running) lightProc.running = true;
                    }
                }
                Connections {
                    target: controlsPill
                    function onActionsExpandedChanged() {
                        if (controlsPill.actionsExpanded) barLightInitTimer.restart();
                    }
                }
            }
            // Clock/Notif Pill (#clock-notif-pill)
            Item {
                id: clockWrapper
                width: clockPill.width
                height: clockPill.height
                implicitWidth: clockPill.width
                implicitHeight: clockPill.height
                
                onHeightChanged: {
                    console.log("clockWrapper height changed:", height, "mapped to window:", mapToItem(null, 0, 0, width, height))
                }
                
                Rectangle {
                    id: clockPill
                    y: 0
                    radius: 18
                    height: hasDropdown ? Math.min(600, Math.max(34, dropdownCol.implicitHeight + 16)) : 34
                    Behavior on height { NumberAnimation { duration: Theme.liquidify ? 800 : 400; easing.type: Theme.liquidify ? Easing.OutElastic : (globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack); easing.amplitude: 1.0; easing.period: 0.85; easing.overshoot: 0.5 } }
                    color: Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity)
                    width: hasDropdown ? 380 : clockRow.implicitWidth + 32
                    Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 400; easing.type: Theme.liquidify ? Easing.OutElastic : (globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack); easing.amplitude: 1.0; easing.period: 0.85; easing.overshoot: 0.5 } }
                    clip: true
                    
                    property var activeNotif: globalState.popups && globalState.popups.length > 0 ? globalState.popups[0] : null
                    property bool hasDropdown: globalState.popups && globalState.popups.length > 0 && !globalState.hideIsland
                    
                    onWidthChanged: {
                        globalState.islandWidth = width
                        console.log("clockPill width changed:", width)
                    }
                    onHeightChanged: {
                        console.log("clockPill height changed:", height, "mapped to window:", mapToItem(null, 0, 0, width, height))
                    }
                    Component.onCompleted: {
                        globalState.islandWidth = width
                        console.log("clockPill completed. Height:", height)
                    }

                    Row {
                        id: clockRow
                        anchors.top: parent.top
                        anchors.topMargin: (34 - height) / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 5
                        
                        // --- Standard Clock State ---
                        Row {
                            id: mainClockRow
                            spacing: 5
                            opacity: 1.0
                            
                            NumberAnimation { id: mainClockFadeIn; target: mainClockRow; property: "opacity"; to: 1.0; duration: 400; easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack }
                            NumberAnimation { id: mainClockFadeOut; target: mainClockRow; property: "opacity"; to: 0.0; duration: 400; easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack }
                            Timer { id: mainClockDelayTimer; interval: 400; onTriggered: mainClockFadeIn.start() }
                            
                            Connections {
                                target: clockPill
                                function onHasDropdownChanged() {
                                    if (clockPill.hasDropdown) {
                                        mainClockFadeIn.stop(); mainClockDelayTimer.stop(); mainClockFadeOut.start();
                                    } else {
                                        mainClockFadeOut.stop(); mainClockDelayTimer.start();
                                    }
                                }
                            }





                            Text {
                                id: notifBellIcon
                                text: "\uea35"
                                color: (globalState.notifications && Object.keys(globalState.notifications.values).length > 0) ? Theme.colPrimary : fg
                                font.family: "tabler-icons"
                                font.pixelSize: Theme.defaultFontSize + 2
                                anchors.verticalCenter: parent.verticalCenter
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: globalState.notifPanelVisible = !globalState.notifPanelVisible
                                }
                            }
                            
                            Rectangle {
                                width: 1
                                height: 16
                                color: fg
                                opacity: 0.3
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                id: customClockText
                                text: bar.clockStr !== "" ? bar.clockStr : Qt.formatDateTime(timeClock.date, "MMM dd • hh:mm AP")
                                color: fg; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight
                                onTextChanged: globalState.clockString = customClockText.text
                                Component.onCompleted: globalState.clockString = customClockText.text
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton) {
                                            globalState.notifPanelVisible = !globalState.notifPanelVisible;
                                        } else {
                                            Quickshell.execDetached("~/.config/cupcake/scripts/toggle_clock.sh");
                                            clockUpdateTimer.start();
                                        }
                                    }
                                }
                            }
                            
                            Timer {
                                id: clockUpdateTimer
                                interval: 100
                                repeat: false
                                onTriggered: clockProc.running = true
                            }
                            
                            Process {
                                id: clockProc
                                command: ["sh", "-c", "~/.config/cupcake/scripts/display_clock.sh"]
                                stdout: StdioCollector { onStreamFinished: () => { if (bar.isDestroying) return; let data = text; try { bar.clockStr = JSON.parse(data).text || bar.clockStr } catch(e) { if(data) bar.clockStr = data } } }
                            }
                            Timer { interval: 5000; running: true; repeat: true; onTriggered: clockProc.running = true }
                        }
                    }

                    // The overlay clock (when expanded)
                    Row {
                        id: overlayClock
                        visible: false
                        anchors.top: parent.top
                        anchors.topMargin: (34 - height) / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 5
                        opacity: 0.0
                        
                        NumberAnimation { id: explicitFadeOut; target: overlayClock; property: "opacity"; to: 0.0; duration: 400; easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack }
                        NumberAnimation { id: explicitFadeIn; target: overlayClock; property: "opacity"; to: 1.0; duration: 400; easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack }
                        Timer { id: overlayFadeInDelay; interval: 400; onTriggered: explicitFadeIn.start() }
                        
                        Connections {
                            target: clockPill
                            function onHasDropdownChanged() {
                                if (!clockPill.hasDropdown) { explicitFadeIn.stop(); explicitFadeOut.start(); }
                                else { explicitFadeOut.stop(); overlayClock.opacity = 1.0; explicitFadeIn.start(); }
                            }
                        }

                        Text { text: globalState.clockString || Qt.formatDateTime(new Date(), "MMM dd • hh:mm AP"); color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight }
                    }

                    // The dropdown column
                    Column {
                        id: dropdownCol
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 8
                        
                        transformOrigin: Item.TopRight
                        scale: clockPill.hasDropdown ? 1.0 : 0.0
                        opacity: clockPill.hasDropdown ? 1.0 : 0.0
                        
                        Behavior on scale { NumberAnimation { duration: 400; easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack; easing.overshoot: 0.5 } }
                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack } }

                        spacing: 6
                        Repeater {
                            model: globalState.popups ? globalState.popups : []
                            delegate: Item {
                                width: dropdownCol.width
                                property bool isOverflow: globalState.popups.length > 3 && index === 3
                                height: isOverflow ? overflowBadge.height : notifCard.height
                                visible: index <= 3

                                NotificationCard {
                                    id: notifCard
                                    width: parent.width
                                    notificationData: !parent.isOverflow ? modelData : null
                                    inPanel: false
                                    visible: !parent.isOverflow
                                }

                                Rectangle {
                                    id: overflowBadge
                                    width: parent.width
                                    height: 32
                                    radius: 16
                                    color: Qt.rgba(Theme.colSurfaceContainerHigh.r, Theme.colSurfaceContainerHigh.g, Theme.colSurfaceContainerHigh.b, root.globalOpacity)
                                    border.color: Qt.rgba(1, 1, 1, 0.05)
                                    border.width: 1
                                    visible: parent.isOverflow
                                    Text {
                                        anchors.centerIn: parent
                                        text: "+" + (globalState.popups.length - 3) + " more"
                                        color: Theme.colOnSurfaceVariant
                                        font.family: Theme.defaultFontFamily
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Power Pill (#custom-power)
        PowerPill {
            id: powerPill
            anchors.right: parent.right
            anchors.top: parent.top
        }
    }

}
    // Moved archPill out of 46px restricted Item
        // =======================
        // CENTER MODULES
        // =======================
         Rectangle {
            id: archPill
            z: 20
            
            property bool isExpanded: false
            
            property bool showMusicPill: bar.hasPlayer && (bar.activePlayer.isPlaying || pillMouseArea.containsMouse)
            
            onShowMusicPillChanged: {
                if (!archPill.showMusicPill) {
                    archPill.isExpanded = false;
                }
            }
            
            property int targetHeight: bar.ccOpen ? (ccLoader.item ? ccLoader.item.height : 615) : (archPill.showMusicPill ? (archPill.isExpanded ? 340 : 34) : 34)
            
            y: 10
            anchors.horizontalCenter: parent.horizontalCenter
            radius: bar.ccOpen ? 18 : (archPill.isExpanded ? 28 : 18)
            width: bar.ccOpen ? 362 : (archPill.showMusicPill ? (archPill.isExpanded ? 220 : 160) : archText.implicitWidth + 32)
            height: targetHeight
            
            Behavior on y { NumberAnimation { duration: Theme.liquidify ? 800 : 450; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutExpo; easing.amplitude: 1.0; easing.period: 0.85 } }
            Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 450; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutExpo; easing.amplitude: 1.0; easing.period: 0.85 } }
            Behavior on height { NumberAnimation { duration: Theme.liquidify ? 800 : 450; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutExpo; easing.amplitude: 1.0; easing.period: 0.85 } }
            Behavior on radius { NumberAnimation { duration: Theme.liquidify ? 800 : 450; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutExpo; easing.amplitude: 1.0; easing.period: 0.85 } }
            
            property real morphProgress: bar.ccOpen ? 1.0 : 0.0
            Behavior on morphProgress {
                NumberAnimation { duration: Theme.liquidify ? 800 : 600; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutExpo; easing.amplitude: 1.0; easing.period: 0.85 }
            }
            
            // Fade out the gradient if either CC is open or the music player is expanded
            property real rawExpansion: Math.max(archPill.morphProgress, archPill.expandFade)
            property real expansion: Math.max(0.0, Math.min(1.0, rawExpansion))
            
            property real gradientAlpha: Math.max(0.0, Math.min(1.0, 1.0 - rawExpansion))
            property real expandFade: archPill.isExpanded ? 1.0 : 0.0
            Behavior on expandFade { NumberAnimation { duration: 300 } }
            property color mixColor: Qt.rgba(
                Theme.colPrimary.r * (1 - expansion) + Theme.colSurface.r * expansion,
                Theme.colPrimary.g * (1 - expansion) + Theme.colSurface.g * expansion,
                Theme.colPrimary.b * (1 - expansion) + Theme.colSurface.b * expansion,
                1.0
            )
            property real currentAlpha: 1.0 * (1 - expansion) + root.ccOpacity * expansion
            color: Qt.rgba(mixColor.r, mixColor.g, mixColor.b, currentAlpha)
            

            MouseArea {
                id: pillMouseArea
                anchors.fill: parent
                enabled: !bar.ccOpen
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton) {
                        if (bar.hasPlayer) {
                            archPill.isExpanded = !archPill.isExpanded;
                        }
                    } else {
                        bar.ccOpen = true;
                    }
                }
            }
            
            // Center label (Arch logo + name)
            Row {
                id: archText
                anchors.centerIn: parent
                spacing: 8
                opacity: bar.ccOpen ? 0.0 : (archPill.showMusicPill ? 0.0 : 1.0)
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Text { anchors.verticalCenter: parent.verticalCenter; text: "\uf303"; color: Theme.colOnPrimary; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Theme.defaultFontSize + 1; font.weight: Theme.defaultFontWeight }
                Text { anchors.verticalCenter: parent.verticalCenter; text: "Arch"; color: Theme.colOnPrimary; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight }
            }

            // Music Island Container
            Item {
                anchors.fill: parent
                opacity: bar.ccOpen ? 0.0 : (archPill.showMusicPill ? 1.0 : 0.0)
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                // ================= COLLAPSED VIEW =================
                Item {
                    id: collapsedView
                    anchors.fill: parent
                    
                    state: archPill.isExpanded ? "hidden" : "visible"
                    states: [
                        State { name: "visible"; PropertyChanges { target: collapsedView; opacity: 1.0; visible: true } },
                        State { name: "hidden"; PropertyChanges { target: collapsedView; opacity: 0.0; visible: false } }
                    ]
                    transitions: [
                        Transition {
                            from: "hidden"; to: "visible"
                            SequentialAnimation {
                                PauseAnimation { duration: 200 }
                                NumberAnimation { target: collapsedView; property: "opacity"; duration: 300 }
                            }
                        },
                        Transition {
                            from: "visible"; to: "hidden"
                            NumberAnimation { target: collapsedView; property: "opacity"; duration: 300 }
                        }
                    ]
                    
                    Item {
                        id: albumArtSmall
                        width: 24; height: 24
                        anchors.left: parent.left; anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle { id: artMaskSmall; anchors.fill: parent; radius: 12; visible: false }
                        Image {
                            anchors.fill: parent; source: (bar.activePlayer && bar.activePlayer.trackArtUrl) ? bar.activePlayer.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop; layer.enabled: true; layer.effect: OpacityMask { maskSource: artMaskSmall }
                        }
                    }

                    Item {
                        anchors.left: albumArtSmall.right
                        anchors.right: playBtnSmall.left
                        anchors.verticalCenter: parent.verticalCenter
                        height: 14
                        
                        Row {
                            height: 14; spacing: 3
                            anchors.centerIn: parent
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 3; height: 12; radius: 1.5; color: Theme.colOnPrimary; SequentialAnimation on height { loops: Animation.Infinite; running: !archPill.isExpanded && bar.isMusicPlaying; NumberAnimation { to: 4; duration: 300; easing.type: Easing.InOutSine } NumberAnimation { to: 12; duration: 350; easing.type: Easing.InOutSine } } }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 3; height: 12; radius: 1.5; color: Theme.colOnPrimary; SequentialAnimation on height { loops: Animation.Infinite; running: !archPill.isExpanded && bar.isMusicPlaying; NumberAnimation { to: 14; duration: 400; easing.type: Easing.InOutSine } NumberAnimation { to: 6; duration: 300; easing.type: Easing.InOutSine } } }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 3; height: 12; radius: 1.5; color: Theme.colOnPrimary; SequentialAnimation on height { loops: Animation.Infinite; running: !archPill.isExpanded && bar.isMusicPlaying; NumberAnimation { to: 8; duration: 350; easing.type: Easing.InOutSine } NumberAnimation { to: 14; duration: 400; easing.type: Easing.InOutSine } } }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 3; height: 12; radius: 1.5; color: Theme.colOnPrimary; SequentialAnimation on height { loops: Animation.Infinite; running: !archPill.isExpanded && bar.isMusicPlaying; NumberAnimation { to: 6; duration: 320; easing.type: Easing.InOutSine } NumberAnimation { to: 10; duration: 280; easing.type: Easing.InOutSine } } }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 3; height: 12; radius: 1.5; color: Theme.colOnPrimary; SequentialAnimation on height { loops: Animation.Infinite; running: !archPill.isExpanded && bar.isMusicPlaying; NumberAnimation { to: 12; duration: 380; easing.type: Easing.InOutSine } NumberAnimation { to: 4; duration: 340; easing.type: Easing.InOutSine } } }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 3; height: 12; radius: 1.5; color: Theme.colOnPrimary; SequentialAnimation on height { loops: Animation.Infinite; running: !archPill.isExpanded && bar.isMusicPlaying; NumberAnimation { to: 4; duration: 290; easing.type: Easing.InOutSine } NumberAnimation { to: 14; duration: 390; easing.type: Easing.InOutSine } } }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 3; height: 12; radius: 1.5; color: Theme.colOnPrimary; SequentialAnimation on height { loops: Animation.Infinite; running: !archPill.isExpanded && bar.isMusicPlaying; NumberAnimation { to: 14; duration: 410; easing.type: Easing.InOutSine } NumberAnimation { to: 8; duration: 310; easing.type: Easing.InOutSine } } }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 3; height: 12; radius: 1.5; color: Theme.colOnPrimary; SequentialAnimation on height { loops: Animation.Infinite; running: !archPill.isExpanded && bar.isMusicPlaying; NumberAnimation { to: 10; duration: 330; easing.type: Easing.InOutSine } NumberAnimation { to: 6; duration: 360; easing.type: Easing.InOutSine } } }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 3; height: 12; radius: 1.5; color: Theme.colOnPrimary; SequentialAnimation on height { loops: Animation.Infinite; running: !archPill.isExpanded && bar.isMusicPlaying; NumberAnimation { to: 8; duration: 370; easing.type: Easing.InOutSine } NumberAnimation { to: 12; duration: 320; easing.type: Easing.InOutSine } } }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 3; height: 12; radius: 1.5; color: Theme.colOnPrimary; SequentialAnimation on height { loops: Animation.Infinite; running: !archPill.isExpanded && bar.isMusicPlaying; NumberAnimation { to: 12; duration: 340; easing.type: Easing.InOutSine } NumberAnimation { to: 4; duration: 380; easing.type: Easing.InOutSine } } }
                        }
                    }
                    
                    Text {
                        id: playBtnSmall
                        anchors.right: parent.right; anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: (bar.activePlayer && bar.activePlayer.isPlaying) ? "\ued45" : "\ued46"
                        font.family: "tabler-icons"; font.pixelSize: 15; color: Theme.colOnPrimary
                        
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -10
                            onClicked: {
                                if (bar.activePlayer) bar.activePlayer.isPlaying = !bar.activePlayer.isPlaying
                            }
                        }
                    }
                }

                // ================= EXPANDED VIEW =================
                Item {
                    id: expandedView
                    anchors.fill: parent
                    
                    state: archPill.isExpanded ? "visible" : "hidden"
                    states: [
                        State { name: "visible"; PropertyChanges { target: expandedView; opacity: 1.0; visible: true } },
                        State { name: "hidden"; PropertyChanges { target: expandedView; opacity: 0.0; visible: false } }
                    ]
                    transitions: [
                        Transition {
                            from: "hidden"; to: "visible"
                            SequentialAnimation {
                                PauseAnimation { duration: 200 }
                                NumberAnimation { target: expandedView; property: "opacity"; duration: 300 }
                            }
                        },
                        Transition {
                            from: "visible"; to: "hidden"
                            NumberAnimation { target: expandedView; property: "opacity"; duration: 300 }
                        }
                    ]
                    
                    Column {
                        width: parent.width - 32
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 14
                        
                        Item {
                            width: 120; height: 120
                            anchors.horizontalCenter: parent.horizontalCenter
                            
                            Rectangle { id: artMaskLarge; anchors.fill: parent; radius: 16; visible: false }
                            Image {
                                anchors.fill: parent; source: (bar.activePlayer && bar.activePlayer.trackArtUrl) ? bar.activePlayer.trackArtUrl : ""
                                fillMode: Image.PreserveAspectCrop; layer.enabled: true; layer.effect: OpacityMask { maskSource: artMaskLarge }
                            }
                            
                            Row {
                                height: 20
                                spacing: 4
                                anchors.bottom: parent.bottom; anchors.bottomMargin: 14
                                anchors.horizontalCenter: parent.horizontalCenter
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; radius: 2; color: "white"; opacity: 0.7; SequentialAnimation on height { loops: Animation.Infinite; running: archPill.isExpanded && bar.isMusicPlaying; NumberAnimation{to:8;duration:300;easing.type:Easing.InOutSine} NumberAnimation{to:16;duration:350;easing.type:Easing.InOutSine} } }
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; radius: 2; color: "white"; opacity: 0.7; SequentialAnimation on height { loops: Animation.Infinite; running: archPill.isExpanded && bar.isMusicPlaying; NumberAnimation{to:18;duration:400;easing.type:Easing.InOutSine} NumberAnimation{to:6;duration:300;easing.type:Easing.InOutSine} } }
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; radius: 2; color: "white"; opacity: 0.7; SequentialAnimation on height { loops: Animation.Infinite; running: archPill.isExpanded && bar.isMusicPlaying; NumberAnimation{to:12;duration:250;easing.type:Easing.InOutSine} NumberAnimation{to:22;duration:450;easing.type:Easing.InOutSine} } }
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; radius: 2; color: "white"; opacity: 0.7; SequentialAnimation on height { loops: Animation.Infinite; running: archPill.isExpanded && bar.isMusicPlaying; NumberAnimation{to:24;duration:350;easing.type:Easing.InOutSine} NumberAnimation{to:10;duration:300;easing.type:Easing.InOutSine} } }
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; radius: 2; color: "white"; opacity: 0.7; SequentialAnimation on height { loops: Animation.Infinite; running: archPill.isExpanded && bar.isMusicPlaying; NumberAnimation{to:14;duration:300;easing.type:Easing.InOutSine} NumberAnimation{to:26;duration:400;easing.type:Easing.InOutSine} } }
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; radius: 2; color: "white"; opacity: 0.7; SequentialAnimation on height { loops: Animation.Infinite; running: archPill.isExpanded && bar.isMusicPlaying; NumberAnimation{to:6;duration:450;easing.type:Easing.InOutSine} NumberAnimation{to:18;duration:350;easing.type:Easing.InOutSine} } }
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; radius: 2; color: "white"; opacity: 0.7; SequentialAnimation on height { loops: Animation.Infinite; running: archPill.isExpanded && bar.isMusicPlaying; NumberAnimation{to:20;duration:300;easing.type:Easing.InOutSine} NumberAnimation{to:8;duration:400;easing.type:Easing.InOutSine} } }
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; radius: 2; color: "white"; opacity: 0.7; SequentialAnimation on height { loops: Animation.Infinite; running: archPill.isExpanded && bar.isMusicPlaying; NumberAnimation{to:10;duration:350;easing.type:Easing.InOutSine} NumberAnimation{to:24;duration:300;easing.type:Easing.InOutSine} } }
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; radius: 2; color: "white"; opacity: 0.7; SequentialAnimation on height { loops: Animation.Infinite; running: archPill.isExpanded && bar.isMusicPlaying; NumberAnimation{to:22;duration:400;easing.type:Easing.InOutSine} NumberAnimation{to:12;duration:350;easing.type:Easing.InOutSine} } }
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; radius: 2; color: "white"; opacity: 0.7; SequentialAnimation on height { loops: Animation.Infinite; running: archPill.isExpanded && bar.isMusicPlaying; NumberAnimation{to:8;duration:300;easing.type:Easing.InOutSine} NumberAnimation{to:16;duration:400;easing.type:Easing.InOutSine} } }
                            }
                        }
                        
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 2
                            Text {
                                text: bar.activePlayer ? bar.activePlayer.trackTitle : ""
                                font.pixelSize: 15; font.weight: 600; color: Theme.colOnSurface
                                font.family: Theme.defaultFontFamily
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 180; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                            }
                            Text {
                                text: bar.activePlayer ? bar.activePlayer.trackArtist : ""
                                font.pixelSize: 12; color: Theme.colOnSurface; opacity: 0.7
                                font.family: Theme.defaultFontFamily
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 180; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                            }
                        }
                        
                        Item {
                            width: 180; height: 4
                            anchors.horizontalCenter: parent.horizontalCenter
                            Rectangle { anchors.fill: parent; color: Theme.colOnSurface; opacity: 0.2; radius: 2 }
                            Rectangle { 
                                height: 4; radius: 2; color: Theme.colOnSurface
                                width: parent.width * (bar.activePlayer && bar.activePlayer.length > 0 ? (bar.activePlayer.position / bar.activePlayer.length) : 0)
                            }
                        }
                        
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 22
                            Text { 
                                text: "\ued48"; font.family: "tabler-icons"; font.pixelSize: 20; color: Theme.colOnSurface; anchors.verticalCenter: parent.verticalCenter 
                                MouseArea { anchors.fill: parent; anchors.margins: -10; onClicked: if (bar.activePlayer) bar.activePlayer.previous() }
                            }
                            Rectangle {
                                width: 44; height: 44; radius: 22; color: Theme.colOnSurface
                                Text { anchors.centerIn: parent; text: (bar.activePlayer && bar.activePlayer.isPlaying) ? "\ued45" : "\ued46"; font.family: "tabler-icons"; font.pixelSize: 22; color: Theme.colSurface }
                                MouseArea { anchors.fill: parent; onClicked: if (bar.activePlayer) bar.activePlayer.isPlaying = !bar.activePlayer.isPlaying }
                            }
                            Text { 
                                text: "\ued49"; font.family: "tabler-icons"; font.pixelSize: 20; color: Theme.colOnSurface; anchors.verticalCenter: parent.verticalCenter 
                                MouseArea { anchors.fill: parent; anchors.margins: -10; onClicked: if (bar.activePlayer) bar.activePlayer.next() }
                            }
                        }
                    }
                }
            }

            // Inner clipping container for the content
            Item {
                anchors.fill: parent
                anchors.margins: 0
                clip: true
                visible: bar.ccOpen || archPill.morphProgress > 0.0
                
                Loader {
                    id: ccLoader
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 362
                    height: ccLoader.item ? ccLoader.item.height : 615
                    source: "ControlCenterUI.qml"
                    active: true
                    
                    layer.enabled: true
                    opacity: Math.max(0, archPill.morphProgress * 3 - 2) // Stays 0 until 66% expanded
                    visible: true
                    enabled: bar.ccOpen
                    
                    onLoaded: {
                        item.anchors.fill = ccLoader;
                    }
                    
                    Connections {
                        target: ccLoader.item
                        function onRequestClose() {
                            bar.ccOpen = false;
                        }
                    }
                }
                }
            }
        }
