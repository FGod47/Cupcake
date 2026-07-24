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
    anchors {
        top: true
        left: true
        right: true
    }
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 46

    // Track active player status for Dynamic Island animations
    property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool hasPlayer: activePlayer !== null
    property bool isMusicPlaying: hasPlayer && activePlayer.isPlaying

    // and to allow the Settings menu to animate to the center of the screen
    implicitHeight: modelData.height
    color: "transparent"
    
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
            if (powerPill.actionsExpanded) {
                powerPill.actionsExpanded = false;
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
        // Fixed 46px top strip — never resizes when bar grows
        z: 1
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.max(46, clockPill.height + 16, powerPill.height + 16)

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
                
                color: isWired ? Theme.colPrimary : (isWifi ? Theme.colSecondary : Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity))
                radius: 18
                implicitHeight: 34
                implicitWidth: networkRow.implicitWidth + 32
                Layout.alignment: Qt.AlignVCenter
                Behavior on implicitWidth { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 300 } }
                property real lastRx: 0
                property real lastTx: 0
                
                Row {
                    id: networkRow
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        id: networkIcon
                        text: "\ueb52"
                        color: (networkPill.isWifi || networkPill.isWired) ? Theme.colBackground : fg
                        font.family: fontName
                        font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        id: networkText
                        text: ""
                        color: (networkPill.isWifi || networkPill.isWired) ? Theme.colBackground : fg
                        font.family: Theme.defaultFontFamily
                        font.weight: Font.DemiBold; font.pixelSize: Theme.defaultFontSize - 1
                        anchors.verticalCenter: parent.verticalCenter
                        visible: text !== "" && !powerPill.actionsExpanded && !controlsPill.actionsExpanded && !clockPill.hasDropdown
                    }
                    
                    Rectangle {
                        width: 1
                        height: 14
                        color: (networkPill.isWifi || networkPill.isWired) ? Theme.colBackground : Theme.colOnSurfaceVariant
                        opacity: 0.4
                        anchors.verticalCenter: parent.verticalCenter
                        visible: networkText.text !== "Disconnected" && networkSpeedText.text !== "" && !powerPill.actionsExpanded && !controlsPill.actionsExpanded && !clockPill.hasDropdown
                    }
                    
                    Text {
                        id: networkSpeedText
                        text: "\uea16 0 KB/s  \uea25 0 KB/s"
                        color: (networkPill.isWifi || networkPill.isWired) ? Theme.colBackground : Theme.colOnSurfaceVariant
                        font.family: Theme.defaultFontFamily
                        font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize - 2
                        anchors.verticalCenter: parent.verticalCenter
                        visible: networkText.text !== "Disconnected" && !powerPill.actionsExpanded && !controlsPill.actionsExpanded && !clockPill.hasDropdown
                    }
                }
                
                Process {
                    id: networkProc
                    command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "d"]
                    stdout: StdioCollector {
                        onStreamFinished: () => {
                            if (!text) {
                                networkIcon.text = ""
                                networkText.text = "Disconnected"
                                return;
                            }
                            const lines = text.trim().split("\n");
                            let activeWifi = "";
                            let activeEthernet = false;
                            let hotspotActive = false;

                            for (let i = 0; i < lines.length; i++) {
                                const parts = lines[i].split(":");
                                if (parts.length >= 3) {
                                    if (parts[0] === "wifi" && parts[1] === "connected") {
                                        const connName = parts.slice(2).join(":");
                                        if (connName.toLowerCase() === "hotspot") {
                                            hotspotActive = true; // Our own hotspot — don't show as Wi-Fi
                                        } else {
                                            activeWifi = connName;
                                        }
                                    } else if (parts[0] === "ethernet" && parts[1] === "connected") {
                                        activeEthernet = true;
                                    }
                                }
                            }

                            if (activeEthernet) {
                                networkPill.isWifi = false;
                                networkPill.isWired = true;
                                networkIcon.text = "\uebd9";
                                networkText.text = "Wired";
                            } else if (activeWifi !== "") {
                                networkPill.isWifi = true;
                                networkPill.isWired = false;
                                networkIcon.text = "\ueb52";
                                networkText.text = activeWifi;
                            } else if (hotspotActive) {
                                networkPill.isWifi = true;
                                networkPill.isWired = false;
                                networkIcon.text = "\ued1b"; // hotspot icon
                                networkText.text = "Hotspot";
                            } else {
                                networkPill.isWifi = false;
                                networkPill.isWired = false;
                                networkIcon.text = "\ueb53";
                                networkText.text = "Disconnected";
                            }
                        }
                    }
                }
                
                Timer {
                    interval: 2000; running: true; repeat: true
                    onTriggered: networkProc.running = true
                }
                
                Process {
                    id: speedProc
                    command: ["cat", "/proc/net/dev"]
                    stdout: StdioCollector {
                        onStreamFinished: () => {
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
                                    // Even if it's less than 1024 bytes, we divide by 1024 and show 0 KB/s or 0.x KB/s, avoiding B/s entirely.
                                    return (bytes / 1024).toFixed(0) + " KB/s";
                                }
                                
                                let rxText = formatSpeed(rxDiff);
                                let txText = formatSpeed(txDiff);
                                
                                networkSpeedText.text = "\uea16 " + rxText + "  \uea25 " + txText;
                            } else {
                                networkSpeedText.text = "\uea16 0 KB/s  \uea25 0 KB/s";
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
                    text: "HW"
                    color: Theme.colOnSurfaceVariant
                    font.family: fontName
                    font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                }
                Process {
                    id: hwProc
                    command: ["sh", "-c", "~/.config/cupcake/scripts/hw_toggle_display.sh"]
                    stdout: StdioCollector {
                        onStreamFinished: (data) => {
                            try { hwText.text = JSON.parse(data).text || "" } catch(e) { hwText.text = data || "" }
                            hwPill.visible = hwText.text !== ""
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
                    text: ""
                    color: fg
                    font.family: fontName
                    font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                }
                Process {
                    id: recProc
                    command: ["sh", "-c", "~/.config/cupcake/scripts/rec-status.sh"]
                    stdout: StdioCollector {
                        onStreamFinished: (data) => {
                            try { recText.text = JSON.parse(data).text || "" } catch(e) { recText.text = data || "" }
                            recPill.visible = recText.text !== ""
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
                            onMoved: { Quickshell.execDetached(["pamixer", "--set-volume", Math.round(value).toString()]) }
                            
                            Process {
                                id: audioProc
                                command: ["pamixer", "--get-volume"]
                                running: true
                                stdout: StdioCollector { id: audioStdout }
                                onExited: {
                                    let val = parseInt((audioStdout.text || "").trim());
                                    if (!isNaN(val) && !audioSlider.pressed) audioSlider.value = val;
                                }
                            }
                            Timer {
                                interval: 3000; running: true; repeat: true
                                onTriggered: audioProc.running = true
                            }
                        }
                        Text {
                            leftPadding: 8
                            text: Math.round(audioSlider.value) + "%"
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
                                interval: 150
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
                            from: 0; to: 100; value: 100
                            anchors.verticalCenter: parent.verticalCenter
                            
                            Process {
                                id: lightProc
                                command: ["ddcutil", "getvcp", "10", "--terse"]
                                running: true
                                stdout: StdioCollector { id: lightStdout }
                                onExited: {
                                    let text = (lightStdout.text || "");
                                    let match = text.match(/VCP\s+10\s+[A-Za-z]+\s+(\d+)/);
                                    if (match && match[1]) {
                                        let val = parseInt(match[1]);
                                        if (!isNaN(val) && !lightSlider.pressed) lightSlider.value = val;
                                    }
                                }
                            }
                        }
                        Text {
                            leftPadding: 8
                            text: Math.round(lightSlider.value) + "%"
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
                                id: customClockText
                                text: Qt.formatDateTime(timeClock.date, "MMM dd • hh:mm AP")
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
                                stdout: StdioCollector { onStreamFinished: (data) => { try { customClockText.text = JSON.parse(data).text || customClockText.text } catch(e) { if(data) customClockText.text = data } } }
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
        Rectangle {
            id: powerPill
            anchors.right: parent.right
            anchors.top: parent.top
            radius: 18
            
            property bool actionsExpanded: false
            property bool confirmingDefault: false
            property string pendingAction: ""
            
            property real targetHeight: actionsExpanded ? (state2Column.implicitHeight + 24) : 34
            property real targetWidth: actionsExpanded ? (state2Column.implicitWidth + 24) : (powerHover.containsMouse ? (34 + powerHoverText.implicitWidth + 8) : 34)
            
            height: targetHeight
            width: targetWidth
            
            color: powerHover.containsMouse || actionsExpanded ? Theme.colError : Theme.colPrimary
            Behavior on radius { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
            Behavior on height { NumberAnimation { duration: Theme.liquidify ? 800 : 500; easing.type: Theme.liquidify ? Easing.OutElastic : (powerPill.actionsExpanded ? Easing.OutBack : Easing.InOutCubic); easing.amplitude: 1.0; easing.period: 0.85; easing.overshoot: 1.5 } }
            Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 500; easing.type: Theme.liquidify ? Easing.OutElastic : (powerPill.actionsExpanded ? Easing.OutBack : Easing.InOutCubic); easing.amplitude: 1.0; easing.period: 0.85; easing.overshoot: 1.5 } }
            Behavior on color { ColorAnimation { duration: 300 } }
            clip: true
            
            function executeAction(action) {
                powerPill.confirmingDefault = false;
                powerPill.actionsExpanded = false;
                if (action === "shutdown") Quickshell.execDetached(["bash", "-c", "systemctl poweroff"]);
                else if (action === "reboot") Quickshell.execDetached(["bash", "-c", "systemctl reboot"]);
                else if (action === "logout") Quickshell.execDetached(["bash", "-c", "loginctl kill-session $XDG_SESSION_ID"]);
                else if (action === "sleep") Quickshell.execDetached(["bash", "-c", "systemctl suspend"]);
            }
            
            function triggerAction(action) {
                powerPill.pendingAction = action;
                powerPill.confirmingDefault = true;
            }
            
            // Stored click-time coordinates for the flying icon animation
            property real heroStartX: 0
            property real heroStartY: 0
            
            function launchHeroFrom(iconRect) {
                // Map the clicked icon's top-left into statesContainer's coordinate space
                var startPos = iconRect.mapToItem(statesContainer, 0, 0);
                // Map the center of the confirmation placeholder as the landing target
                var centerPos = confirmIconPlaceholder.mapToItem(statesContainer,
                    confirmIconPlaceholder.width / 2,
                    confirmIconPlaceholder.height / 2);
                heroIcon.x = startPos.x;
                heroIcon.y = startPos.y;
                heroIcon.width = 32;
                heroIcon.height = 32;
                heroIcon.radius = 16;
                heroIcon.opacity = 1;
                // Now animate to center of placeholder (offset by half of final 48px size)
                // We also subtract 12 from the X target because state3Column starts with a +12 leftMargin 
                // but animates to 0, so its final position will be 12px further to the left.
                heroXAnim.from = startPos.x;
                heroXAnim.to = centerPos.x - 12 - 24;
                heroYAnim.from = startPos.y;
                heroYAnim.to = centerPos.y - 24;
                heroWAnim.from = 32;
                heroWAnim.to = 48;
                heroHAnim.from = 32;
                heroHAnim.to = 48;
                heroRAnim.from = 16;
                heroRAnim.to = 24;
                heroXAnim.restart();
                heroYAnim.restart();
                heroWAnim.restart();
                heroHAnim.restart();
                heroRAnim.restart();
            }
            
            function getActionLabel(action) {
                if (action === "sleep") return "Sleep now?";
                if (action === "logout") return "Logout now?";
                if (action === "reboot") return "Reboot now?";
                if (action === "shutdown") return "Shutdown now?";
                return "";
            }
            
            function getActionIcon(action) {
                if (action === "sleep") return "\ueaf8";
                if (action === "logout") return "\ueba8";
                if (action === "reboot") return "\ueb13";
                if (action === "shutdown") return "\ueb0d";
                return "";
            }
            
            function getActionSub(action) {
                if (action === "sleep") return "The screen will lock and go dark.";
                if (action === "logout") return "You will be signed out of this session.";
                if (action === "reboot") return "The system will restart shortly.";
                if (action === "shutdown") return "Unsaved work will be lost.";
                return "";
            }
            
            MouseArea {
                id: powerHover
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    if (!powerPill.confirmingDefault) {
                        powerPill.actionsExpanded = !powerPill.actionsExpanded;
                    }
                }
            }
            
            // Expanded Actions Inner Row
            Item {
                id: innerContent
                anchors.fill: parent
                opacity: (powerPill.actionsExpanded) ? 1.0 : 0.0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 300 } }
                
                Row {
                    id: powerRow
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    layoutDirection: Qt.RightToLeft
                    spacing: 14
                    
                    // State 1: Expanding Actions Background
                    Rectangle {
                        visible: powerPill.actionsExpanded
                        width: powerPill.actionsExpanded ? state2Column.implicitWidth : 0
                        height: powerPill.actionsExpanded ? state2Column.implicitHeight : 0
                        color: "transparent"
                        anchors.verticalCenter: parent.verticalCenter
                        clip: true
                        
                        // State 2 & 3 Container
                        Item {
                            id: statesContainer
                            width: powerPill.actionsExpanded ? state2Column.implicitWidth : 0
                            height: powerPill.actionsExpanded ? state2Column.implicitHeight : 0
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            visible: powerPill.actionsExpanded
                            clip: true
                            Behavior on height { NumberAnimation { duration: Theme.liquidify ? 800 : 500; easing.type: Theme.liquidify ? Easing.OutElastic : (powerPill.actionsExpanded ? Easing.OutBack : Easing.InOutCubic); easing.amplitude: 1.0; easing.period: 0.85; easing.overshoot: 1.5 } }
                            Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 500; easing.type: Theme.liquidify ? Easing.OutElastic : (powerPill.actionsExpanded ? Easing.OutBack : Easing.InOutCubic); easing.amplitude: 1.0; easing.period: 0.85; easing.overshoot: 1.5 } }
                            
                            // Floating Hero Icon — driven imperatively from launchHeroFrom()
                            Rectangle {
                                id: heroIcon
                                width: 32; height: 32; radius: width / 2
                                color: "#ffffff"
                                z: 10
                                opacity: 0
                                visible: opacity > 0
                                
                                NumberAnimation on x { id: heroXAnim; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.1; running: false }
                                NumberAnimation on y { id: heroYAnim; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.1; running: false }
                                NumberAnimation on width  { id: heroWAnim; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.1; running: false }
                                NumberAnimation on height { id: heroHAnim; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.1; running: false }
                                NumberAnimation on radius { id: heroRAnim; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.1; running: false }
                                
                                Connections {
                                    target: powerPill
                                    function onConfirmingDefaultChanged() {
                                        if (!powerPill.confirmingDefault) {
                                            heroIcon.opacity = 0;
                                        }
                                    }
                                }
                                
                                Text { 
                                    text: powerPill.getActionIcon(powerPill.pendingAction)
                                    color: Theme.colError
                                    font.family: fontName
                                    font.pixelSize: parent.width * 0.5
                                    anchors.centerIn: parent
                                }
                            }
                            
                            // State 2: Clicked Actions
                            Column {
                                id: state2Column
                                spacing: 6
                                width: 196
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: !powerPill.confirmingDefault ? 0 : -12
                                opacity: !powerPill.confirmingDefault ? 1 : 0
                                visible: opacity > 0
                                Behavior on opacity { NumberAnimation { duration: 180 } }
                                Behavior on anchors.leftMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                                // Sleep
                                Rectangle {
                                    width: parent.width; height: 42; radius: 21
                                    color: Qt.rgba(255, 255, 255, sleepArea.containsMouse ? 0.62 : 0.38)
                                    Row {
                                        anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
                                        spacing: 10
                                        Rectangle {
                                            id: sleepIconRect
                                            width: 32; height: 32; radius: 16
                                            color: "#ffffff"
                                            opacity: (powerPill.confirmingDefault && powerPill.pendingAction === "sleep") ? 0 : 1
                                            Text { text: "\ueaf8"; color: Theme.colError; font.family: fontName; font.pixelSize: 15; anchors.fill: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                        }
                                        Text { text: "Sleep"; color: "#ffffff"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600; anchors.verticalCenter: parent.verticalCenter }
                                    }
                                    MouseArea { 
                                        id: sleepArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { 
                                            mouse.accepted = true
                                            powerPill.pendingAction = "sleep"
                                            powerPill.launchHeroFrom(sleepIconRect)
                                            powerPill.confirmingDefault = true
                                        }
                                    }
                                }

                                // Logout
                                Rectangle {
                                    width: parent.width; height: 42; radius: 21
                                    color: Qt.rgba(255, 255, 255, logoutArea.containsMouse ? 0.62 : 0.38)
                                    Row {
                                        anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
                                        spacing: 10
                                        Rectangle {
                                            id: logoutIconRect
                                            width: 32; height: 32; radius: 16
                                            color: "#ffffff"
                                            opacity: (powerPill.confirmingDefault && powerPill.pendingAction === "logout") ? 0 : 1
                                            Text { text: "\ueba8"; color: Theme.colError; font.family: fontName; font.pixelSize: 15; anchors.fill: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                        }
                                        Text { text: "Logout"; color: "#ffffff"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600; anchors.verticalCenter: parent.verticalCenter }
                                    }
                                    MouseArea { 
                                        id: logoutArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { 
                                            mouse.accepted = true
                                            powerPill.pendingAction = "logout"
                                            powerPill.launchHeroFrom(logoutIconRect)
                                            powerPill.confirmingDefault = true
                                        }
                                    }
                                }

                                // Reboot
                                Rectangle {
                                    width: parent.width; height: 42; radius: 21
                                    color: Qt.rgba(255, 255, 255, rebootArea.containsMouse ? 0.62 : 0.38)
                                    Row {
                                        anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
                                        spacing: 10
                                        Rectangle {
                                            id: rebootIconRect
                                            width: 32; height: 32; radius: 16
                                            color: "#ffffff"
                                            opacity: (powerPill.confirmingDefault && powerPill.pendingAction === "reboot") ? 0 : 1
                                            Text { text: "\ueb13"; color: Theme.colError; font.family: fontName; font.pixelSize: 15; anchors.fill: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                        }
                                        Text { text: "Reboot"; color: "#ffffff"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600; anchors.verticalCenter: parent.verticalCenter }
                                    }
                                    MouseArea { 
                                        id: rebootArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { 
                                            mouse.accepted = true
                                            powerPill.pendingAction = "reboot"
                                            powerPill.launchHeroFrom(rebootIconRect)
                                            powerPill.confirmingDefault = true
                                        }
                                    }
                                }

                                // Shutdown
                                Rectangle {
                                    width: parent.width; height: 42; radius: 21
                                    color: Qt.rgba(255, 255, 255, shutdownArea.containsMouse ? 0.62 : 0.38)
                                    Row {
                                        anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
                                        spacing: 10
                                        Rectangle {
                                            id: shutdownIconRect
                                            width: 32; height: 32; radius: 16
                                            color: "#ffffff"
                                            opacity: (powerPill.confirmingDefault && powerPill.pendingAction === "shutdown") ? 0 : 1
                                            Text { text: "\ueb0d"; color: Theme.colError; font.family: fontName; font.pixelSize: 15; anchors.fill: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                        }
                                        Text { text: "Shutdown"; color: "#ffffff"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600; anchors.verticalCenter: parent.verticalCenter }
                                    }
                                    MouseArea { 
                                        id: shutdownArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { 
                                            mouse.accepted = true
                                            powerPill.pendingAction = "shutdown"
                                            powerPill.launchHeroFrom(shutdownIconRect)
                                            powerPill.confirmingDefault = true
                                        }
                                    }
                                }
                            }
                            
                            // State 3: Default Style Confirmation
                            Item {
                                id: state3Column
                                width: 196
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.leftMargin: powerPill.confirmingDefault ? 0 : 12
                                opacity: powerPill.confirmingDefault ? 1 : 0
                                visible: opacity > 0
                                Behavior on opacity { NumberAnimation { duration: 180 } }
                                Behavior on anchors.leftMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                
                                Item {
                                    anchors.top: parent.top
                                    anchors.bottom: buttonsRow.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    
                                    Column {
                                        anchors.centerIn: parent
                                        width: parent.width
                                        spacing: 8
                                        
                                        Item {
                                            id: confirmIconPlaceholder
                                            width: 48; height: 48
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                        
                                        Column {
                                            width: parent.width
                                            spacing: 2
                                            Text { width: parent.width; text: powerPill.getActionLabel(powerPill.pendingAction); color: "#ffffff"; font.family: Theme.defaultFontFamily; font.pixelSize: 14; font.weight: 700; horizontalAlignment: Text.AlignHCenter }
                                            Text { width: parent.width; text: powerPill.getActionSub(powerPill.pendingAction); color: "#ffffff"; opacity: 0.6; font.family: Theme.defaultFontFamily; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter }
                                        }
                                    }
                                }
                                
                                Row {
                                    id: buttonsRow
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 8
                                    width: parent.width
                                    spacing: 6
                                    
                                    Rectangle {
                                        width: (parent.width - 6) / 2; height: 32; radius: 16
                                        color: Qt.rgba(255, 255, 255, nopeArea.containsMouse ? 0.62 : 0.4)
                                        Text { text: "Cancel"; color: "#ffffff"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: 700; anchors.centerIn: parent }
                                        MouseArea { id: nopeArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { mouse.accepted = true; powerPill.confirmingDefault = false; } }
                                    }
                                    
                                    Rectangle {
                                        width: (parent.width - 6) / 2; height: 32; radius: 16
                                        color: sureArea.containsMouse ? "#6c2b3c" : "#5a2432"
                                        Text { text: "Confirm"; color: "#fbdfe4"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: 700; anchors.centerIn: parent }
                                        MouseArea { id: sureArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { mouse.accepted = true; powerPill.executeAction(powerPill.pendingAction); } }
                                    }
                                }
                            }
                        // End of statesContainer
                        }
                    }
                }
            }
            
            // Main Icon and Hover Text
            Row {
                anchors.right: parent.right
                anchors.rightMargin: (34 - powerIconText.implicitWidth) / 2
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                opacity: (!powerPill.actionsExpanded && !powerPill.confirmingDefault) ? 1.0 : 0.0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 300 } }
                    Text {
                        id: powerHoverText
                        text: "Power"
                        color: "#ffffff"
                        font.family: Theme.defaultFontFamily
                        font.weight: 600
                        font.pixelSize: Theme.defaultFontSize
                        clip: true
                        width: powerHover.containsMouse ? implicitWidth : 0
                        Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 500; easing.type: Theme.liquidify ? Easing.OutElastic : ((powerHover.containsMouse || powerPill.actionsExpanded) ? Easing.OutBack : Easing.InOutCubic); easing.amplitude: 1.0; easing.period: 0.85; easing.overshoot: 1.5 } }
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Text {
                        id: powerIconText
                        text: "\ueb0d"
                        color: bg
                        font.family: fontName
                        font.weight: Theme.defaultFontWeight
                        font.pixelSize: Theme.defaultFontSize
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }



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
            
            property int targetHeight: bar.ccOpen ? 615 : (archPill.showMusicPill ? (archPill.isExpanded ? 340 : 34) : 34)
            
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
                        text: (bar.activePlayer && bar.activePlayer.isPlaying) ? "\uF04C" : "\uF04B"
                        font.family: "Symbols Nerd Font"; font.pixelSize: 15; color: Theme.colOnPrimary
                        
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
                                text: "\uF048"; font.family: "Symbols Nerd Font"; font.pixelSize: 18; color: Theme.colOnSurface; anchors.verticalCenter: parent.verticalCenter 
                                MouseArea { anchors.fill: parent; anchors.margins: -10; onClicked: if (bar.activePlayer) bar.activePlayer.previous() }
                            }
                            Rectangle {
                                width: 44; height: 44; radius: 22; color: Theme.colOnSurface
                                Text { anchors.centerIn: parent; text: (bar.activePlayer && bar.activePlayer.isPlaying) ? "\uF04C" : "\uF04B"; font.family: "Symbols Nerd Font"; font.pixelSize: 20; color: Theme.colSurface }
                                MouseArea { anchors.fill: parent; onClicked: if (bar.activePlayer) bar.activePlayer.isPlaying = !bar.activePlayer.isPlaying }
                            }
                            Text { 
                                text: "\uF051"; font.family: "Symbols Nerd Font"; font.pixelSize: 18; color: Theme.colOnSurface; anchors.verticalCenter: parent.verticalCenter 
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
                    height: parent.height
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
