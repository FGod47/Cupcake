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
    property bool isMusicPlaying: activePlayer !== null && activePlayer.isPlaying

    // and to allow the Settings menu to animate to the center of the screen
    implicitHeight: modelData.height
    color: "transparent"
    
    property bool ccOpen: false
    mask: (globalState.settingsOpen || ccOpen) ? null : normalMask
    
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
        enabled: globalState.settingsOpen || bar.ccOpen
        onClicked: {
            globalState.settingsOpen = false;
            bar.ccOpen = false;
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
        // Make this item tall enough to encompass expanding popups instantly so Wayland mask updates reliably
        height: clockPill.hasDropdown ? 800 : 46

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
                color: root.barTransparency ? Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity) : Theme.colSurface
                radius: 18
                implicitHeight: 34
                implicitWidth: 168 // 5 * 32px + 8px padding
                Layout.alignment: Qt.AlignVCenter
                
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

                            // Active Workspace Background Bubble (Large Circle)
                            Rectangle {
                                anchors.centerIn: parent
                                width: isFocused ? 26 : 0
                                height: width
                                radius: width / 2
                                color: Theme.colPrimary
                                opacity: isFocused ? 1 : 0
                                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            // Inner Dot (For focused, occupied, or empty)
                            Rectangle {
                                anchors.centerIn: parent
                                width: isFocused ? 6 : (isOccupied ? 8 : 6)
                                height: width
                                radius: width / 2
                                color: isFocused ? Theme.colOnPrimary : (isOccupied ? fg : Qt.rgba(fg.r, fg.g, fg.b, 0.4))
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on width { NumberAnimation { duration: 150 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: Hyprland.dispatch("hl.dsp.focus({workspace = " + wsId + "})")
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
            anchors.top: parent.top
            spacing: 8
            
            visible: true
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            // Network Pill
            Rectangle {
                id: networkPill
                
                property bool isWifi: false
                property bool isWired: false
                
                color: isWired ? Theme.colPrimary : (isWifi ? Theme.colSecondary : (root.barTransparency ? Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity) : Theme.colSurface))
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
                                networkIcon.text = "󰖪"
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
                color: root.barTransparency ? Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity) : Theme.colSurface // from custom-hw gradient
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
                color: root.barTransparency ? Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity) : Theme.colSurface
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
                color: root.barTransparency ? Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity) : Theme.colSurface
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
                color: root.barTransparency ? Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity) : Theme.colSurface
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
                            Behavior on width { NumberAnimation { duration: 500; easing.type: controlsPill.actionsExpanded ? Easing.OutBack : Easing.InOutCubic; easing.overshoot: 1.5 } }
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
                            Behavior on width { NumberAnimation { duration: 500; easing.type: (controlsHover.hovered || controlsPill.actionsExpanded) ? Easing.OutBack : Easing.InOutCubic; easing.overshoot: 1.5 } }
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
                            Behavior on width { NumberAnimation { duration: 500; easing.type: controlsPill.actionsExpanded ? Easing.OutBack : Easing.InOutCubic; easing.overshoot: 1.5 } }
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
                            Behavior on width { NumberAnimation { duration: 500; easing.type: (controlsHover.hovered || controlsPill.actionsExpanded) ? Easing.OutBack : Easing.InOutCubic; easing.overshoot: 1.5 } }
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
                height: clockPill.hasDropdown ? 800 : 34
                implicitWidth: clockPill.width
                implicitHeight: clockPill.hasDropdown ? 800 : 34
                
                onHeightChanged: {
                    console.log("clockWrapper height changed:", height, "mapped to window:", mapToItem(null, 0, 0, width, height))
                }
                
                Rectangle {
                    id: clockPill
                    y: 0
                    radius: 18
                    height: hasDropdown ? Math.min(600, Math.max(34, dropdownCol.height + 16)) : 34
                    Behavior on height { NumberAnimation { duration: 400; easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack; easing.overshoot: 0.5 } }
                    color: root.barTransparency ? Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity) : Theme.colSurface
                    width: hasDropdown ? 380 : clockRow.implicitWidth + 32
                    Behavior on width { NumberAnimation { duration: 400; easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack; easing.overshoot: 0.5 } }
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
            // Power Pill (#custom-power)
            Rectangle {
                id: powerPill
                radius: 18
                implicitHeight: 34
                color: powerHover.hovered ? Theme.colError : Theme.colPrimary
                Behavior on color { ColorAnimation { duration: 500 } }
                implicitWidth: powerRow.implicitWidth + 32
                clip: true
                
                property bool actionsExpanded: false
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: powerPill.actionsExpanded = !powerPill.actionsExpanded
                    cursorShape: Qt.PointingHandCursor
                }

                Row {
                    id: powerRow
                    anchors.centerIn: parent
                    spacing: 0
                    
                    // Slide-left Revealer
                    Item {
                        id: powerRevealer
                        height: 34
                        width: (powerHover.hovered || powerPill.actionsExpanded) ? innerContent.implicitWidth : 0
                        clip: true
                        Behavior on width { NumberAnimation { duration: 500; easing.type: (powerHover.hovered || powerPill.actionsExpanded) ? Easing.OutBack : Easing.InOutCubic; easing.overshoot: 1.5 } }
                        
                        Row {
                            id: innerContent
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            
                            // State 1: Hover Text
                            Text {
                                text: "Power "
                                color: bg
                                font.family: Theme.defaultFontFamily
                                font.weight: Theme.defaultFontWeight
                                font.pixelSize: Theme.defaultFontSize
                                visible: !powerPill.actionsExpanded
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            // State 2: Clicked Actions
                            Row {
                                spacing: 14
                                visible: powerPill.actionsExpanded
                                anchors.verticalCenter: parent.verticalCenter

                                // Sleep
                                Item {
                                    width: sleepIconText.implicitWidth + sleepLabelText.implicitWidth + 4; height: 34
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Text { id: sleepIconText; text: "\ueaf8"; color: bg; font.family: fontName; font.pixelSize: Theme.defaultFontSize; font.weight: 600; height: 34; verticalAlignment: Text.AlignVCenter }
                                        Text { id: sleepLabelText; text: "Sleep"; color: bg; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: 600; height: 34; verticalAlignment: Text.AlignVCenter }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { mouse.accepted = true; Quickshell.execDetached(["bash", "-c", "systemctl suspend"]); } }
                                }

                                // Logout
                                Item {
                                    width: logoutIconText.implicitWidth + logoutLabelText.implicitWidth + 4; height: 34
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Text { id: logoutIconText; text: "\ueba8"; color: bg; font.family: fontName; font.pixelSize: Theme.defaultFontSize; font.weight: 600; height: 34; verticalAlignment: Text.AlignVCenter }
                                        Text { id: logoutLabelText; text: "Logout"; color: bg; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: 600; height: 34; verticalAlignment: Text.AlignVCenter }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { mouse.accepted = true; Quickshell.execDetached(["bash", "-c", "loginctl kill-session $XDG_SESSION_ID"]); } }
                                }

                                // Reboot
                                Item {
                                    width: rebootIconText.implicitWidth + rebootLabelText.implicitWidth + 4; height: 34
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Text { id: rebootIconText; text: "\ueb13"; color: bg; font.family: fontName; font.pixelSize: Theme.defaultFontSize; font.weight: 600; height: 34; verticalAlignment: Text.AlignVCenter }
                                        Text { id: rebootLabelText; text: "Reboot"; color: bg; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: 600; height: 34; verticalAlignment: Text.AlignVCenter }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { mouse.accepted = true; Quickshell.execDetached(["bash", "-c", "systemctl reboot"]); } }
                                }

                                // Shutdown
                                Item {
                                    width: shutdownIconText.implicitWidth + shutdownLabelText.implicitWidth + 4; height: 34
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Text { id: shutdownIconText; text: "\ueb0d"; color: bg; font.family: fontName; font.pixelSize: Theme.defaultFontSize; font.weight: 600; height: 34; verticalAlignment: Text.AlignVCenter }
                                        Text { id: shutdownLabelText; text: "Shutdown"; color: bg; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: 600; height: 34; verticalAlignment: Text.AlignVCenter }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { mouse.accepted = true; Quickshell.execDetached(["bash", "-c", "systemctl poweroff"]); } }
                                }
                            }
                        }
                    }
                    
                    // Main Icon
                    Text {
                        text: "\ueb0d"
                        color: bg
                        font.family: fontName
                        font.weight: Theme.defaultFontWeight
                        font.pixelSize: Theme.defaultFontSize
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !powerPill.actionsExpanded
                    }
                }

                HoverHandler { 
                    id: powerHover 
                    onHoveredChanged: {
                        if (!hovered && powerPill.actionsExpanded) {
                            powerPill.actionsExpanded = false;
                        }
                    }
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
            
            property int targetHeight: bar.ccOpen ? 615 : (bar.isMusicPlaying ? (archPill.isExpanded ? 340 : 34) : 34)
            
            y: bar.ccOpen ? (modelData.height - targetHeight) / 2 : 10
            anchors.horizontalCenter: parent.horizontalCenter
            radius: bar.ccOpen ? 18 : (archPill.isExpanded ? 28 : 18)
            width: bar.ccOpen ? 362 : (bar.isMusicPlaying ? (archPill.isExpanded ? 220 : 160) : archText.implicitWidth + 32)
            height: targetHeight
            
            Behavior on y { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
            Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
            Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
            Behavior on radius { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
            
            property real morphProgress: bar.ccOpen ? 1.0 : 0.0
            Behavior on morphProgress { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
            
            property real currentAlpha: root.barOpacity + (root.ccOpacity - root.barOpacity) * archPill.morphProgress
            color: root.barTransparency ? Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, currentAlpha) : Theme.colSurface
            
            property color c1: Theme.colPrimary
            property color c2: Theme.colSecondary

            SequentialAnimation on c1 {
                loops: Animation.Infinite
                ColorAnimation { to: Theme.colSecondary; duration: 2000 }
                ColorAnimation { to: Theme.colPrimary; duration: 2000 }
            }

            SequentialAnimation on c2 {
                loops: Animation.Infinite
                ColorAnimation { to: Theme.colPrimary; duration: 2000 }
                ColorAnimation { to: Theme.colSecondary; duration: 2000 }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                visible: archPill.morphProgress < 1.0
                
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(archPill.c1.r, archPill.c1.g, archPill.c1.b, 1.0 - archPill.morphProgress) }
                    GradientStop { position: 1.0; color: Qt.rgba(archPill.c2.r, archPill.c2.g, archPill.c2.b, 1.0 - archPill.morphProgress) }
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: !bar.ccOpen && bar.isMusicPlaying
                onClicked: archPill.isExpanded = !archPill.isExpanded
            }
            
            // Center label (Arch logo + name)
            Row {
                id: archText
                anchors.centerIn: parent
                spacing: 6
                opacity: bar.ccOpen ? 0.0 : (bar.isMusicPlaying ? 0.0 : 1.0)
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Text { text: ""; color: Theme.colSurfaceContainerHigh; font.family: Theme.monoFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight }
                Text { text: "Arch"; color: Theme.colSurfaceContainerHigh; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight }
            }

            // Music Island Container
            Item {
                anchors.fill: parent
                opacity: bar.ccOpen ? 0.0 : (bar.isMusicPlaying ? 1.0 : 0.0)
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
                        width: 24; height: 24
                        anchors.left: parent.left; anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle { id: artMaskSmall; anchors.fill: parent; radius: 12; visible: false }
                        Image {
                            anchors.fill: parent; source: (bar.activePlayer && bar.activePlayer.trackArtUrl) ? bar.activePlayer.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop; layer.enabled: true; layer.effect: OpacityMask { maskSource: artMaskSmall }
                        }
                    }

                    Row {
                        width: 15; height: 14; spacing: 3
                        anchors.left: parent.left; anchors.leftMargin: 40
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 3; height: 12; radius: 1.5; color: "#1E1E2E"; SequentialAnimation on height { loops: Animation.Infinite; running: !archPill.isExpanded; NumberAnimation { to: 4; duration: 300; easing.type: Easing.InOutSine } NumberAnimation { to: 12; duration: 350; easing.type: Easing.InOutSine } } }
                        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 3; height: 12; radius: 1.5; color: "#1E1E2E"; SequentialAnimation on height { loops: Animation.Infinite; running: !archPill.isExpanded; NumberAnimation { to: 14; duration: 400; easing.type: Easing.InOutSine } NumberAnimation { to: 6; duration: 300; easing.type: Easing.InOutSine } } }
                        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 3; height: 12; radius: 1.5; color: "#1E1E2E"; SequentialAnimation on height { loops: Animation.Infinite; running: !archPill.isExpanded; NumberAnimation { to: 8; duration: 350; easing.type: Easing.InOutSine } NumberAnimation { to: 14; duration: 400; easing.type: Easing.InOutSine } } }
                    }
                    
                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: (bar.activePlayer && bar.activePlayer.isPlaying) ? "\ueb0c" : "\ueb2a"
                        font.family: "tabler-icons"; font.pixelSize: 15; color: "#1E1E2E"
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
                        anchors.top: parent.top; anchors.topMargin: 12
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
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; radius: 2; color: "white"; opacity: 0.7; SequentialAnimation on height { loops: Animation.Infinite; running: archPill.isExpanded; NumberAnimation{to:8;duration:300;easing.type:Easing.InOutSine} NumberAnimation{to:16;duration:350;easing.type:Easing.InOutSine} } }
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; radius: 2; color: "white"; opacity: 0.7; SequentialAnimation on height { loops: Animation.Infinite; running: archPill.isExpanded; NumberAnimation{to:18;duration:400;easing.type:Easing.InOutSine} NumberAnimation{to:6;duration:300;easing.type:Easing.InOutSine} } }
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; radius: 2; color: "white"; opacity: 0.7; SequentialAnimation on height { loops: Animation.Infinite; running: archPill.isExpanded; NumberAnimation{to:12;duration:250;easing.type:Easing.InOutSine} NumberAnimation{to:22;duration:450;easing.type:Easing.InOutSine} } }
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; radius: 2; color: "white"; opacity: 0.7; SequentialAnimation on height { loops: Animation.Infinite; running: archPill.isExpanded; NumberAnimation{to:24;duration:350;easing.type:Easing.InOutSine} NumberAnimation{to:10;duration:300;easing.type:Easing.InOutSine} } }
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; radius: 2; color: "white"; opacity: 0.7; SequentialAnimation on height { loops: Animation.Infinite; running: archPill.isExpanded; NumberAnimation{to:14;duration:300;easing.type:Easing.InOutSine} NumberAnimation{to:26;duration:400;easing.type:Easing.InOutSine} } }
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; radius: 2; color: "white"; opacity: 0.7; SequentialAnimation on height { loops: Animation.Infinite; running: archPill.isExpanded; NumberAnimation{to:6;duration:450;easing.type:Easing.InOutSine} NumberAnimation{to:18;duration:350;easing.type:Easing.InOutSine} } }
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; radius: 2; color: "white"; opacity: 0.7; SequentialAnimation on height { loops: Animation.Infinite; running: archPill.isExpanded; NumberAnimation{to:20;duration:300;easing.type:Easing.InOutSine} NumberAnimation{to:8;duration:400;easing.type:Easing.InOutSine} } }
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; radius: 2; color: "white"; opacity: 0.7; SequentialAnimation on height { loops: Animation.Infinite; running: archPill.isExpanded; NumberAnimation{to:10;duration:350;easing.type:Easing.InOutSine} NumberAnimation{to:24;duration:300;easing.type:Easing.InOutSine} } }
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; radius: 2; color: "white"; opacity: 0.7; SequentialAnimation on height { loops: Animation.Infinite; running: archPill.isExpanded; NumberAnimation{to:22;duration:400;easing.type:Easing.InOutSine} NumberAnimation{to:12;duration:350;easing.type:Easing.InOutSine} } }
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; radius: 2; color: "white"; opacity: 0.7; SequentialAnimation on height { loops: Animation.Infinite; running: archPill.isExpanded; NumberAnimation{to:8;duration:300;easing.type:Easing.InOutSine} NumberAnimation{to:16;duration:400;easing.type:Easing.InOutSine} } }
                            }
                        }
                        
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 2
                            Text {
                                text: bar.activePlayer ? bar.activePlayer.trackTitle : ""
                                font.pixelSize: 15; font.weight: 600; color: "#1E1E2E"
                                font.family: Theme.defaultFontFamily
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 180; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                            }
                            Text {
                                text: bar.activePlayer ? bar.activePlayer.trackArtist : ""
                                font.pixelSize: 12; color: "#1E1E2E"; opacity: 0.7
                                font.family: Theme.defaultFontFamily
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 180; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                            }
                        }
                        
                        Item {
                            width: 180; height: 4
                            anchors.horizontalCenter: parent.horizontalCenter
                            Rectangle { anchors.fill: parent; color: "#1E1E2E"; opacity: 0.2; radius: 2 }
                            Rectangle { 
                                height: 4; radius: 2; color: "#1E1E2E"
                                width: parent.width * (bar.activePlayer && bar.activePlayer.length > 0 ? (bar.activePlayer.position / bar.activePlayer.length) : 0)
                            }
                        }
                        
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 22
                            Text { text: "\ueb20"; font.family: "tabler-icons"; font.pixelSize: 18; color: "#1E1E2E"; anchors.verticalCenter: parent.verticalCenter }
                            Rectangle {
                                width: 44; height: 44; radius: 22; color: "#1E1E2E"
                                Text { anchors.centerIn: parent; text: (bar.activePlayer && bar.activePlayer.isPlaying) ? "\ueb0c" : "\ueb2a"; font.family: "tabler-icons"; font.pixelSize: 20; color: "#f5c2e7" }
                            }
                            Text { text: "\ueb21"; font.family: "tabler-icons"; font.pixelSize: 18; color: "#1E1E2E"; anchors.verticalCenter: parent.verticalCenter }
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
            MouseArea {
                anchors.fill: parent
                enabled: !bar.ccOpen
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (bar.isMusicPlaying) {
                        archPill.isExpanded = !archPill.isExpanded;
                    } else {
                        bar.ccOpen = true;
                    }
                }
            }
        }
