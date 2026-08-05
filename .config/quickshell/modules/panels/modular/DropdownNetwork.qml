import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../common"
import "../../../theme"

Rectangle {
    id: netSplitPill
    y: 10
    property bool menuExpanded: bar.netDropdownOpen
    property int activeTab: isWifi ? 1 : (isWired ? 0 : (isBluetooth ? 3 : 1))

    property var wifiList: []
    property var btList: []
    property var savedWifiList: []
    property var hsClientList: []

    property string wifiSSID: "Disconnected"
    property int wifiSignal: 85
    property string wifiIp: "192.168.1.87"
    property string internetStatus: "Internet Access"
    property bool hasInternet: true

    property string wiredIface: "enp6s0"
    property string wiredIp: "192.168.1.42"

    property string btDeviceName: ""
    property int btBattery: 0

    property string hsName: "Pixel_9210_AP"
    property string hsPass: "12345678"
    property string hsBand: "2.4 GHz"
    property string hsIp: "10.42.0.1"
    property bool hsSavedNotify: false

    property string selectedSSID: ""
    property string passInputText: ""
    property bool showPassInput: false
    property bool showSavedWifi: false

    function getSignalIcon(sig) {
        if (sig >= 75) return "\ueb52";
        if (sig >= 50) return "\ueba5";
        if (sig >= 25) return "\ueba4";
        return "\ueba3";
    }

    function openCaptivePortal() {
        Quickshell.execDetached(["xdg-open", "https://nmcheck.gnome.org/"]);
    }

    onActiveTabChanged: {
        showPassInput = false;
        passInputText = "";
    }

    onMenuExpandedChanged: {
        if (menuExpanded) {
            statusProc.running = true;
            wifiScanProc.running = true;
            btScanProc.running = true;
            savedProc.running = true;
            hsProc.running = true;
        } else {
            showPassInput = false;
            passInputText = "";
        }
    }

    height: menuExpanded ? (netContentCol.implicitHeight + 28) : 30
    Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } }

    readonly property real openGap: 16
    readonly property real headerW: networkIconsRow.implicitWidth + 24
    readonly property real expandedW: 310
    property real contentW: menuExpanded ? expandedW : headerW

    x: bar.netDropdownOpen ? (bar.barX + bar.barW - clockSplitPill.contentW - 16 - contentW) : (bar.barX + bar.barW - clockSplitPill.contentW - 16 - contentW)
    width: bar.netDropdownOpen ? contentW : headerW

    Behavior on x     { NumberAnimation { duration: 600; easing.type: Easing.OutQuart } }
    Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuart } }

    radius: menuExpanded ? 24 : 15
    Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    clip: true

    color: bar.pillColor
    border.color: Qt.rgba(1, 1, 1, 0.08)
    border.width: 1

    // Instant Event Monitor
    Process {
        id: monitorProc
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: {
                statusProc.running = true;
                wifiScanProc.running = true;
            }
        }
    }

    // Hotspot Settings Processor
    Process {
        id: hsProc
        command: ["bash", "-c", "nmcli -s -f 802-11-wireless.ssid,802-11-wireless-security.psk,802-11-wireless.band con show Hotspot 2>/dev/null; echo '---clients---'; ip neighbor show | grep -v FAILED | grep -v 192.168.0.1"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                let parts = text.split("---clients---");
                let nmOut = parts[0] || "";
                let clientOut = parts[1] || "";

                let nameM = nmOut.match(/802-11-wireless.ssid:\s*(.+)/);
                if (nameM && nameM[1].trim() && !hsNameInput.activeFocus) {
                    netSplitPill.hsName = nameM[1].trim();
                }

                let passM = nmOut.match(/802-11-wireless-security.psk:\s*(.+)/);
                if (passM && passM[1].trim() && !hsPassInput.activeFocus) {
                    netSplitPill.hsPass = passM[1].trim();
                }

                let bandM = nmOut.match(/802-11-wireless.band:\s*(.+)/);
                if (bandM) {
                    let b = bandM[1].trim();
                    if (b === "bg") netSplitPill.hsBand = "2.4 GHz";
                    else if (b === "a") netSplitPill.hsBand = "5 GHz";
                    else netSplitPill.hsBand = "Auto";
                }

                let clines = clientOut.trim().split('\n');
                let clients = [];
                for (let l of clines) {
                    let m = l.match(/^([0-9.]+)\s+dev\s+\S+\s+lladdr\s+([0-9a-f:]+)/i);
                    if (m) {
                        clients.push({ ip: m[1], mac: m[2] });
                    }
                }
                netSplitPill.hsClientList = clients;
            }
        }
    }

    // Saved Networks Processor
    Process {
        id: savedProc
        command: ["bash", "-c", "nmcli -t -f NAME,TYPE con show | grep 802-11-wireless | cut -d: -f1"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                let lines = text.trim().split('\n');
                let res = [];
                for (let l of lines) {
                    let name = l.trim();
                    if (name && name !== "Hotspot") res.push(name);
                }
                netSplitPill.savedWifiList = res;
            }
        }
    }

    // Real Status Processor
    Process {
        id: statusProc
        running: netSplitPill.menuExpanded
        command: ["bash", "-c", "nmcli -t -f DEVICE,TYPE,STATE dev; echo '---ip---'; ip -4 addr show; echo '---conn---'; nmcli networking connectivity check; echo '---ping---'; (ping -c 1 -W 1 1.1.1.1 >/dev/null 2>&1 && echo 'online' || echo 'no_internet'); echo '---bt---'; bluetoothctl devices Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                let parts = text.split("---ip---");
                let nmOut = parts[0] || "";
                let rest = parts[1] || "";
                let restParts = rest.split("---conn---");
                let ipOut = restParts[0] || "";
                let connRest = restParts[1] || "";
                let connParts = connRest.split("---ping---");
                let nmConnState = (connParts[0] || "").trim();
                let pingRest = connParts[1] || "";
                let pingParts = pingRest.split("---bt---");
                let pingState = (pingParts[0] || "").trim();
                let btOut = pingParts[1] || "";

                if (nmConnState === "portal") {
                    netSplitPill.internetStatus = "Login Required";
                    netSplitPill.hasInternet = false;
                } else if (pingState === "no_internet") {
                    netSplitPill.internetStatus = "No Internet";
                    netSplitPill.hasInternet = false;
                } else {
                    netSplitPill.internetStatus = "Internet Access";
                    netSplitPill.hasInternet = true;
                }

                // Wired Ethernet Interface
                let ethMatch = nmOut.match(/^([^:]+):ethernet:connected/m);
                if (ethMatch) {
                    netSplitPill.wiredIface = ethMatch[1].trim();
                }

                // IP Addresses
                let ipMatches = ipOut.match(/inet\s+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/g);
                if (ipMatches) {
                    for (let ipStr of ipMatches) {
                        let cleanIp = ipStr.replace("inet ", "").trim();
                        if (cleanIp !== "127.0.0.1") {
                            if (cleanIp.startsWith("10.42.")) netSplitPill.hsIp = cleanIp;
                            else if (cleanIp.startsWith("192.168.") || cleanIp.startsWith("172.") || cleanIp.startsWith("10.")) {
                                netSplitPill.wifiIp = cleanIp;
                                netSplitPill.wiredIp = cleanIp;
                            }
                        }
                    }
                }

                // Bluetooth Connected Device
                let btMatch = btOut.match(/Device\s+([0-9A-Fa-f:]+)\s+(.+)/);
                if (btMatch) {
                    netSplitPill.btDeviceName = btMatch[2].trim();
                    if (netSplitPill.btBattery === 0) netSplitPill.btBattery = 67;
                } else {
                    netSplitPill.btDeviceName = "";
                    netSplitPill.btBattery = 0;
                }
            }
        }
    }

    Timer {
        interval: 4000
        running: netSplitPill.menuExpanded
        repeat: true
        onTriggered: { statusProc.running = true; hsProc.running = true; }
    }

    // Scanners
    Process {
        id: wifiScanProc
        command: ["bash", "-c", "nmcli device wifi rescan 2>/dev/null; sleep 0.3; nmcli -t -f SSID,SIGNAL,SECURITY,IN-USE dev wifi list"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                let lines = text.trim().split('\n');
                let res = [];
                let seen = new Set();
                let foundConn = false;
                for (let l of lines) {
                    let parts = l.split(':');
                    if (parts.length >= 4 && parts[0].trim() !== "") {
                        let ssid = parts[0].trim();
                        let sig = parseInt(parts[1]) || 0;
                        let isConn = parts[3].includes("*");
                        if (isConn) {
                            netSplitPill.wifiSSID = ssid;
                            netSplitPill.wifiSignal = sig;
                            foundConn = true;
                        }
                        if (!seen.has(ssid)) {
                            seen.add(ssid);
                            res.push({
                                ssid: ssid,
                                signal: sig,
                                security: parts[2] || "Open",
                                connected: isConn
                            });
                        }
                    }
                }
                if (!foundConn) netSplitPill.wifiSSID = "Disconnected";
                netSplitPill.wifiList = res;
            }
        }
    }

    // Bluetooth Devices Processor
    Process {
        id: btScanProc
        command: ["bash", "-c", "bluetoothctl devices; echo '---conn---'; bluetoothctl devices Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                let lines = text.trim().split('\n');
                let res = [];
                let isConnSection = false;
                let connMacs = new Set();
                for (let l of lines) {
                    if (l.includes("---conn---")) { isConnSection = true; continue; }
                    let m = l.match(/Device\s+([0-9A-Fa-f:]+)\s+(.+)/);
                    if (m) {
                        let mac = m[1];
                        let name = m[2];
                        if (isConnSection) {
                            connMacs.add(mac);
                        } else {
                            res.push({ mac: mac, name: name, connected: false });
                        }
                    }
                }
                for (let dev of res) {
                    dev.connected = connMacs.has(dev.mac);
                }
                netSplitPill.btList = res;
            }
        }
    }

    // Top glass highlight
    Rectangle {
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        anchors.leftMargin: 6; anchors.rightMargin: 6
        height: 1; radius: 1
        color: Qt.rgba(1, 1, 1, 0.12)
    }

    opacity: bar.netDropdownOpen ? 1.0 : 0.0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }

    MouseArea {
        id: netSplitPillMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: (mouseY <= 30) ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (mouse.y <= 30) {
                if (bar.dropdownOpen) bar.dropdownOpen = false;
                bar.netDropdownOpen = !bar.netDropdownOpen;
            }
        }
    }

    // Header (shown when closed)
    Row {
        id: networkIconsRow
        anchors.horizontalCenter: parent.horizontalCenter
        y: (30 - height) / 2
        spacing: 8
        opacity: netSplitPill.menuExpanded ? 0.0 : 1.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Text { visible: isHotspot; text: "\ued1b"; font.family: fontName; font.pixelSize: 15; color: fg; anchors.verticalCenter: parent.verticalCenter }
        Text { visible: isBluetooth; text: isBluetoothConnected ? "\uecea" : "\uea37"; font.family: fontName; font.pixelSize: 15; color: fg; anchors.verticalCenter: parent.verticalCenter }
        Text { visible: isWired; text: "\uebd9"; font.family: fontName; font.pixelSize: 15; color: fg; anchors.verticalCenter: parent.verticalCenter }
        Text { visible: isWifi && !isWired && !isHotspot; text: getSignalIcon(wifiSignal); font.family: fontName; font.pixelSize: 15; color: fg; anchors.verticalCenter: parent.verticalCenter }
        Text { text: "•"; font.family: Theme.defaultFontFamily; font.pixelSize: 15; font.weight: Theme.defaultFontWeight; color: Qt.rgba(fg.r, fg.g, fg.b, 0.4); anchors.verticalCenter: parent.verticalCenter }
        Text { text: (isWired || (isWifi && wifiSSID !== "Disconnected") || isHotspot) ? netStr : "Disconnected"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Theme.defaultFontWeight; color: Qt.rgba(fg.r, fg.g, fg.b, 0.7); anchors.verticalCenter: parent.verticalCenter }
    }

    // Expanded View Dashboard
    ColumnLayout {
        id: netContentCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 12
        opacity: netSplitPill.menuExpanded ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 250 } }

        // ── 1. Top Segmented Tab Bar ──
        Rectangle {
            Layout.fillWidth: true
            height: 38
            radius: 19
            color: Qt.rgba(1, 1, 1, 0.05)
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Repeater {
                    model: [
                        { icon: "\uebd9", tabIndex: 0 },
                        { icon: "\ueb52", tabIndex: 1 },
                        { icon: "\ued1b", tabIndex: 2 },
                        { icon: "\uea37", tabIndex: 3 }
                    ]
                    delegate: Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            radius: 16
                            color: activeTab === modelData.tabIndex ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.25) : "transparent"
                            border.color: activeTab === modelData.tabIndex ? Theme.colPrimary : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.family: fontName
                                font.pixelSize: 15
                                color: activeTab === modelData.tabIndex ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: activeTab = modelData.tabIndex
                        }
                    }
                }
            }
        }

        // ── 2. Bluetooth Only Circular Progress Ring ──
        Item {
            visible: activeTab === 3
            Layout.alignment: Qt.AlignHCenter
            width: 130
            height: 130

            Canvas {
                id: gaugeCanvas
                anchors.fill: parent
                property real percentage: (btBattery / 100.0)
                onPercentageChanged: requestPaint()

                onPaint: {
                    let ctx = getContext("2d");
                    ctx.reset();
                    let cx = width / 2;
                    let cy = height / 2;
                    let radius = 55;
                    let startAngle = -Math.PI / 2;
                    let endAngle = startAngle + (percentage * 2 * Math.PI);

                    ctx.beginPath();
                    ctx.arc(cx, cy, radius, 0, 2 * Math.PI);
                    ctx.lineWidth = 7;
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08);
                    ctx.stroke();

                    if (percentage > 0) {
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, startAngle, endAngle);
                        ctx.lineWidth = 7;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = Theme.colPrimary;
                        ctx.stroke();
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 30; height: 30; radius: 15
                    color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.2)
                    Text { anchors.centerIn: parent; text: "\uecea"; font.family: fontName; font.pixelSize: 13; color: Theme.colPrimary }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: btBattery > 0 ? (btBattery + "%") : "--"
                    font.family: Theme.defaultFontFamily; font.pixelSize: 17; font.weight: Font.Bold; color: bar.fg
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Battery"
                    font.family: Theme.defaultFontFamily; font.pixelSize: 10; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                }
            }
        }

        // ── 3. Header Row: Icon Badge + Name/Subtitle + Enable Switch ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                width: 36; height: 36; radius: 18
                Layout.alignment: Qt.AlignVCenter
                color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.18)
                border.color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.3)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: activeTab === 0 ? "\uebd9" : (activeTab === 1 ? getSignalIcon(wifiSignal) : (activeTab === 2 ? "\ued1b" : "\uea37"))
                    font.family: fontName; font.pixelSize: 16
                    color: Theme.colPrimary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    text: activeTab === 0 ? "Wired" : (activeTab === 1 ? "Wi-Fi" : (activeTab === 2 ? "Hotspot" : "Bluetooth"))
                    font.family: Theme.defaultFontFamily; font.pixelSize: 14; font.weight: Font.Bold; color: bar.fg
                }
                Text {
                    text: activeTab === 0 ? (wiredIp + " · " + (isWired ? (hasInternet ? "Connected" : "No Internet") : "Disconnected")) : (activeTab === 1 ? (isWifi ? ((wifiSSID !== "Disconnected" ? (wifiSSID + " · ") : "") + internetStatus) : "Disabled") : (activeTab === 2 ? (hsIp + " · " + hsClientList.length + " connected") : (isBluetooth ? (btDeviceName !== "" ? (btDeviceName + " · " + (btBattery > 0 ? btBattery + "%" : "Connected")) : "Enabled") : "Disabled")))
                    font.family: Theme.defaultFontFamily; font.pixelSize: 11
                    color: (activeTab === 1 && !hasInternet && wifiSSID !== "Disconnected") ? "#ff6b6b" : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                    elide: Text.ElideRight; Layout.fillWidth: true
                }
            }

            // Enable Toggle Switch
            Rectangle {
                width: 42; height: 24; radius: 12
                Layout.alignment: Qt.AlignVCenter
                color: (activeTab === 0 ? isWired : (activeTab === 1 ? isWifi : (activeTab === 2 ? isHotspot : isBluetooth))) ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.15)
                Behavior on color { ColorAnimation { duration: 200 } }

                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (activeTab === 0) {
                            bar.isWired = !bar.isWired;
                            Quickshell.execDetached(["bash", "-c", "if nmcli dev status | grep -E 'ethernet\\s+connected'; then nmcli dev disconnect " + netSplitPill.wiredIface + "; else nmcli dev connect " + netSplitPill.wiredIface + " 2>/dev/null || nmcli con up 'Wired connection 1'; fi"]);
                            statusProc.running = true;
                        } else if (activeTab === 1) {
                            bar.isWifi = !bar.isWifi;
                            Quickshell.execDetached(["bash", "-c", "if [ \"$(nmcli radio wifi)\" = \"enabled\" ]; then nmcli radio wifi off; else nmcli radio wifi on; fi"]);
                        } else if (activeTab === 2) {
                            bar.isHotspot = !bar.isHotspot;
                            Quickshell.execDetached(["bash", "-c", "if nmcli con show --active | grep -qi hotspot; then nmcli con down Hotspot; else nmcli con up Hotspot; fi"]);
                        } else if (activeTab === 3) {
                            bar.isBluetooth = !bar.isBluetooth;
                            Quickshell.execDetached(["bash", "-c", "if rfkill list bluetooth | grep -q 'Soft blocked: yes'; then rfkill unblock bluetooth; bluetoothctl power on; else rfkill block bluetooth; bluetoothctl power off; fi"]);
                            btScanProc.running = true;
                        }
                    }
                }

                Rectangle {
                    width: 18; height: 18; radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    x: (activeTab === 0 ? isWired : (activeTab === 1 ? isWifi : (activeTab === 2 ? isHotspot : isBluetooth))) ? 21 : 3
                    color: (activeTab === 0 ? isWired : (activeTab === 1 ? isWifi : (activeTab === 2 ? isHotspot : isBluetooth))) ? Theme.colOnPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                    Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }
            }
        }

        // ── 4. Dual Stat Cards (DOWNLOAD & UPLOAD) ──
        RowLayout {
            visible: (activeTab === 0 && isWired) || (activeTab === 1 && isWifi && wifiSSID !== "Disconnected") || (activeTab === 2 && isHotspot)
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true; height: 52; radius: 12
                color: Qt.rgba(1, 1, 1, 0.04); border.color: Qt.rgba(1, 1, 1, 0.08); border.width: 1
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 8; spacing: 1
                    Text { text: "DOWNLOAD"; font.family: Theme.defaultFontFamily; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 0.5; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5) }
                    Text { text: (typeof bar.netRxStr !== "undefined" && bar.netRxStr !== "") ? bar.netRxStr : netStr; font.family: Theme.defaultFontFamily; font.pixelSize: 14; font.weight: Font.Bold; color: bar.fg }
                }
            }

            Rectangle {
                Layout.fillWidth: true; height: 52; radius: 12
                color: Qt.rgba(1, 1, 1, 0.04); border.color: Qt.rgba(1, 1, 1, 0.08); border.width: 1
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 8; spacing: 1
                    Text { text: "UPLOAD"; font.family: Theme.defaultFontFamily; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 0.5; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5) }
                    Text { text: (typeof bar.netTxStr !== "undefined" && bar.netTxStr !== "") ? bar.netTxStr : "0 KB/s"; font.family: Theme.defaultFontFamily; font.pixelSize: 14; font.weight: Font.Bold; color: bar.fg }
                }
            }
        }

        // ── 5. Tab Dynamic Content List ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            // Tab 0: Wired Ethernet Active Card
            Rectangle {
                visible: activeTab === 0
                Layout.fillWidth: true; height: 38; radius: 12
                color: isWired ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.22) : Qt.rgba(1, 1, 1, 0.03)
                border.color: isWired ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.06); border.width: 1

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                    Text { text: "\uebd9"; font.family: fontName; font.pixelSize: 14; color: isWired ? Theme.colPrimary : bar.fg }
                    Text { Layout.fillWidth: true; text: wiredIface + " (Ethernet)"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: isWired ? Font.Bold : Font.DemiBold; color: isWired ? Theme.colPrimary : bar.fg; elide: Text.ElideRight }
                    Text { text: isWired ? "\uea5e" : ""; font.family: fontName; font.pixelSize: 14; color: Theme.colPrimary; visible: isWired }
                }
            }

            // Tab 1: Wi-Fi Networks Section
            ColumnLayout {
                visible: activeTab === 1
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "AVAILABLE NETWORKS"; font.family: Theme.defaultFontFamily; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 0.5; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5) }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "\ueb1c"
                        font.family: fontName; font.pixelSize: 13
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: wifiScanProc.running = true }
                    }
                }

                // Captive Portal Login Banner
                Rectangle {
                    visible: internetStatus === "Login Required" && isWifi
                    Layout.fillWidth: true; height: 34; radius: 10
                    color: Qt.rgba(1, 0.6, 0, 0.18); border.color: "#ffa500"; border.width: 1
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        Text { Layout.fillWidth: true; text: "Web Login Required (Captive Portal)"; font.family: Theme.defaultFontFamily; font.pixelSize: 10; font.weight: Font.Bold; color: "#ffa500" }
                        Text { text: "Open Browser ↗"; font.family: Theme.defaultFontFamily; font.pixelSize: 10; font.weight: Font.Bold; color: bar.fg }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: openCaptivePortal() }
                }

                // Wi-Fi Disabled Warning Banner
                Rectangle {
                    visible: !isWifi
                    Layout.fillWidth: true; height: 34; radius: 10
                    color: Qt.rgba(1, 1, 1, 0.03); border.color: Qt.rgba(1, 1, 1, 0.06); border.width: 1
                    Text { anchors.centerIn: parent; text: "Wi-Fi is currently turned off"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.4) }
                }

                // Wi-Fi Repeater with Clean Tabler Font Icons
                Repeater {
                    model: isWifi ? (netSplitPill.wifiList.length > 0 ? netSplitPill.wifiList : []) : []
                    delegate: ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        // Network Item Card
                        Rectangle {
                            Layout.fillWidth: true; height: 40; radius: 12
                            color: modelData.connected ? (hasInternet ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.22) : Qt.rgba(1, 0, 0, 0.18)) : (wifiItemMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03))
                            border.color: modelData.connected ? (hasInternet ? Theme.colPrimary : "#ff6b6b") : Qt.rgba(1, 1, 1, 0.06); border.width: 1

                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                                Text { text: getSignalIcon(modelData.signal); font.family: fontName; font.pixelSize: 14; color: modelData.connected ? (hasInternet ? Theme.colPrimary : "#ff6b6b") : bar.fg }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 0
                                    Text { text: modelData.ssid; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: modelData.connected ? Font.Bold : Font.DemiBold; color: modelData.connected ? (hasInternet ? Theme.colPrimary : "#ff6b6b") : bar.fg; elide: Text.ElideRight }
                                    Text { text: modelData.connected ? ("Connected · " + internetStatus) : (modelData.security !== "Open" ? "Secured" : "Open"); font.family: Theme.defaultFontFamily; font.pixelSize: 9; color: modelData.connected ? (hasInternet ? Theme.colPrimary : "#ff6b6b") : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5) }
                                }

                                // Tabler Disconnect Button ( = 'x' in Tabler font)
                                Rectangle {
                                    visible: modelData.connected
                                    width: 28; height: 28; radius: 8
                                    color: Qt.rgba(1, 0, 0, 0.18)
                                    border.color: Qt.rgba(1, 0, 0, 0.3); border.width: 1
                                    Text { anchors.centerIn: parent; text: "\uea02"; font.family: fontName; font.pixelSize: 14; color: "#ff6b6b" }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Quickshell.execDetached(["bash", "-c", "nmcli con down id \"" + modelData.ssid + "\" 2>/dev/null || nmcli dev disconnect wlan0"]);
                                            wifiScanProc.running = true;
                                        }
                                    }
                                }

                                Text { text: modelData.security !== "Open" && !modelData.connected ? "\ueae2" : ""; font.family: fontName; font.pixelSize: 12; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5); visible: text !== "" && !modelData.connected }
                                Text { text: "\uea5e"; font.family: fontName; font.pixelSize: 14; color: Theme.colPrimary; visible: modelData.connected && hasInternet }
                            }

                            MouseArea {
                                id: wifiItemMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.connected) return;
                                    let isSaved = netSplitPill.savedWifiList.includes(modelData.ssid);
                                    if (isSaved || modelData.security === "Open") {
                                        showPassInput = false;
                                        Quickshell.execDetached(["bash", "-c", "nmcli dev wifi connect \"" + modelData.ssid + "\""]);
                                        wifiScanProc.running = true;
                                    } else {
                                        if (selectedSSID === modelData.ssid && showPassInput) {
                                            showPassInput = false;
                                        } else {
                                            selectedSSID = modelData.ssid;
                                            showPassInput = true;
                                            passInputText = "";
                                        }
                                    }
                                }
                            }
                        }

                        // INLINE PASSWORD DRAWER (Tabler icons for eye show/hide and close)
                        ColumnLayout {
                            visible: showPassInput && selectedSSID === modelData.ssid && isWifi
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                Text { Layout.fillWidth: true; text: "ENTER PASSWORD FOR " + modelData.ssid; font.family: Theme.defaultFontFamily; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.colPrimary; elide: Text.ElideRight }
                                Text {
                                    text: "\uea02"; font.family: fontName; font.pixelSize: 13; color: "#ff6b6b"
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { showPassInput = false; passInputText = ""; } }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true; height: 38; radius: 12
                                color: Qt.rgba(1, 1, 1, 0.05); border.color: Theme.colPrimary; border.width: 1
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 8; spacing: 8
                                    Text { text: "\ueae2"; font.family: fontName; font.pixelSize: 14; color: Theme.colPrimary }
                                    TextInput {
                                        id: wifiPassInput
                                        Layout.fillWidth: true; text: passInputText
                                        echoMode: showWifiPass.show ? TextInput.Normal : TextInput.Password
                                        font.family: Theme.defaultFontFamily; font.pixelSize: 12; color: bar.fg
                                        onTextChanged: passInputText = text
                                        onAccepted: {
                                            Quickshell.execDetached(["bash", "-c", "nmcli dev wifi connect \"" + selectedSSID + "\" password \"" + passInputText + "\""]);
                                            showPassInput = false;
                                            passInputText = "";
                                            wifiScanProc.running = true;
                                        }

                                        Text {
                                            text: "Enter Wi-Fi password..."
                                            font.family: Theme.defaultFontFamily; font.pixelSize: 11
                                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.4)
                                            visible: wifiPassInput.text === "" && !wifiPassInput.activeFocus
                                        }
                                    }
                                    Text {
                                        id: showWifiPass; property bool show: false
                                        text: show ? "\ueaa5" : "\ueaa4"; font.family: fontName; font.pixelSize: 15; color: bar.fg
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: showWifiPass.show = !showWifiPass.show }
                                    }
                                    Rectangle {
                                        width: 62; height: 28; radius: 8; color: Theme.colPrimary
                                        Text { anchors.centerIn: parent; text: "Connect"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: Theme.colOnPrimary }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Quickshell.execDetached(["bash", "-c", "nmcli dev wifi connect \"" + selectedSSID + "\" password \"" + passInputText + "\""]);
                                                showPassInput = false;
                                                passInputText = "";
                                                wifiScanProc.running = true;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Tab 2: Hotspot Config Section
            ColumnLayout {
                visible: activeTab === 2
                Layout.fillWidth: true
                spacing: 8

                // Saved Toast Notification
                Rectangle {
                    visible: hsSavedNotify
                    Layout.fillWidth: true; height: 26; radius: 8
                    color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.25)
                    border.color: Theme.colPrimary; border.width: 1
                    Text { anchors.centerIn: parent; text: "Hotspot updated successfully ✓"; font.family: Theme.defaultFontFamily; font.pixelSize: 10; font.weight: Font.Bold; color: Theme.colPrimary }
                }

                function saveHotspotConfig() {
                    let nameVal = hsNameInput.text.trim();
                    let passVal = hsPassInput.text.trim();
                    if (!nameVal || !passVal) return;
                    netSplitPill.hsName = nameVal;
                    netSplitPill.hsPass = passVal;

                    let cmd = "nmcli con modify Hotspot 802-11-wireless.ssid \"" + nameVal + "\" 802-11-wireless-security.key-mgmt wpa-psk 802-11-wireless-security.psk \"" + passVal + "\"; if nmcli con show --active | grep -qi hotspot; then nmcli con up Hotspot; fi";
                    Quickshell.execDetached(["bash", "-c", cmd]);
                    hsSavedNotify = true;
                    hsSavedNotifyTimer.restart();
                    hsProc.running = true;
                }

                Timer { id: hsSavedNotifyTimer; interval: 2500; onTriggered: hsSavedNotify = false }

                // Network Name Card
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 3
                    Text { text: "NETWORK NAME"; font.family: Theme.defaultFontFamily; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 0.5; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5) }
                    Rectangle {
                        Layout.fillWidth: true; height: 38; radius: 12
                        color: Qt.rgba(1, 1, 1, 0.04); border.color: hsNameInput.activeFocus ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.08); border.width: 1
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
                            Text { text: "\ued1b"; font.family: fontName; font.pixelSize: 14; color: Theme.colPrimary }
                            TextInput {
                                id: hsNameInput
                                Layout.fillWidth: true; text: hsName; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.DemiBold; color: bar.fg
                                onAccepted: saveHotspotConfig()
                                onEditingFinished: saveHotspotConfig()
                            }
                            Text { text: "\ueab6"; font.family: fontName; font.pixelSize: 13; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5) }
                        }
                    }
                }

                // Password Card
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 3
                    Text { text: "PASSWORD"; font.family: Theme.defaultFontFamily; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 0.5; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5) }
                    Rectangle {
                        Layout.fillWidth: true; height: 38; radius: 12
                        color: Qt.rgba(1, 1, 1, 0.04); border.color: hsPassInput.activeFocus ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.08); border.width: 1
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
                            Text { text: "\ueae2"; font.family: fontName; font.pixelSize: 14; color: Theme.colPrimary }
                            TextInput {
                                id: hsPassInput
                                Layout.fillWidth: true; text: hsPass; echoMode: showHsPassText.show ? TextInput.Normal : TextInput.Password; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.DemiBold; color: bar.fg
                                onAccepted: saveHotspotConfig()
                                onEditingFinished: saveHotspotConfig()
                            }
                            Text {
                                id: showHsPassText; property bool show: false
                                text: show ? "\ueaa5" : "\ueaa4"; font.family: fontName; font.pixelSize: 15; color: bar.fg
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: showHsPassText.show = !showHsPassText.show }
                            }
                        }
                    }
                }

                // Save Hotspot Button
                Rectangle {
                    Layout.fillWidth: true; height: 32; radius: 10
                    color: Theme.colPrimary
                    RowLayout {
                        anchors.centerIn: parent; spacing: 6
                        Text { text: "\uea5e"; font.family: fontName; font.pixelSize: 13; color: Theme.colOnPrimary }
                        Text { text: "Save Hotspot Details"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: Theme.colOnPrimary }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: saveHotspotConfig()
                    }
                }

                // Band Selection Pills
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 3
                    Text { text: "BAND SELECTION"; font.family: Theme.defaultFontFamily; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 0.5; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5) }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Repeater {
                            model: ["2.4 GHz", "5 GHz", "Auto"]
                            delegate: Rectangle {
                                Layout.fillWidth: true; height: 32; radius: 16
                                property bool isSel: hsBand === modelData
                                color: isSel ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.25) : Qt.rgba(1, 1, 1, 0.04)
                                border.color: isSel ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.08); border.width: 1
                                Text {
                                    anchors.centerIn: parent; text: modelData; font.family: Theme.defaultFontFamily; font.pixelSize: 11
                                    font.weight: isSel ? Font.Bold : Font.Normal; color: isSel ? Theme.colPrimary : bar.fg
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        hsBand = modelData;
                                        let bandCmd = modelData === "2.4 GHz" ? "802-11-wireless.band bg 802-11-wireless.channel 6" : (modelData === "5 GHz" ? "802-11-wireless.band a 802-11-wireless.channel 36" : "802-11-wireless.band \"\" 802-11-wireless.channel \"\"");
                                        let fullCmd = "nmcli con modify Hotspot " + bandCmd + "; if nmcli con show --active | grep -qi hotspot; then nmcli con up Hotspot; fi";
                                        Quickshell.execDetached(["bash", "-c", fullCmd]);
                                        hsSavedNotify = true;
                                        hsSavedNotifyTimer.restart();
                                        hsProc.running = true;
                                    }
                                }
                            }
                        }
                    }
                }

                // Connected Hotspot Devices List
                ColumnLayout {
                    visible: isHotspot
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "CONNECTED DEVICES (" + hsClientList.length + ")"; font.family: Theme.defaultFontFamily; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 0.5; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5) }
                    Repeater {
                        model: hsClientList
                        delegate: Rectangle {
                            Layout.fillWidth: true; height: 34; radius: 10
                            color: Qt.rgba(1, 1, 1, 0.04); border.color: Qt.rgba(1, 1, 1, 0.08); border.width: 1
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
                                Text { text: "\ued1b"; font.family: fontName; font.pixelSize: 12; color: Theme.colPrimary }
                                Text { Layout.fillWidth: true; text: modelData.ip; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: bar.fg }
                                Text { text: modelData.mac; font.family: Theme.defaultFontFamily; font.pixelSize: 10; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5) }
                            }
                        }
                    }
                }
            }

            // Tab 3: Bluetooth Devices List
            Repeater {
                model: activeTab === 3 ? (netSplitPill.btList.length > 0 ? netSplitPill.btList : []) : []
                delegate: Rectangle {
                    Layout.fillWidth: true; height: 40; radius: 12
                    color: modelData.connected ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.22) : (btItemMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03))
                    border.color: modelData.connected ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.06); border.width: 1

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                        Text { text: "\uea37"; font.family: fontName; font.pixelSize: 14; color: modelData.connected ? Theme.colPrimary : bar.fg }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 0
                            Text { text: modelData.name; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: modelData.connected ? Font.Bold : Font.DemiBold; color: modelData.connected ? Theme.colPrimary : bar.fg; elide: Text.ElideRight }
                            Text { text: modelData.connected ? "Connected" : "Paired"; font.family: Theme.defaultFontFamily; font.pixelSize: 9; color: modelData.connected ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5) }
                        }

                        // Disconnect / Forget Buttons for Bluetooth Device
                        Row {
                            spacing: 4
                            // Disconnect Button (if connected)
                            Rectangle {
                                visible: modelData.connected
                                width: 28; height: 28; radius: 8
                                color: Qt.rgba(1, 0, 0, 0.18); border.color: Qt.rgba(1, 0, 0, 0.3); border.width: 1
                                Text { anchors.centerIn: parent; text: "\uea02"; font.family: fontName; font.pixelSize: 12; color: "#ff6b6b" }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["bash", "-c", "bluetoothctl disconnect " + modelData.mac]);
                                        btScanProc.running = true;
                                    }
                                }
                            }

                            // Forget Device Button
                            Rectangle {
                                width: 28; height: 28; radius: 8
                                color: Qt.rgba(1, 1, 1, 0.05); border.color: Qt.rgba(1, 1, 1, 0.1); border.width: 1
                                Text { anchors.centerIn: parent; text: "\ueab6"; font.family: fontName; font.pixelSize: 12; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6) }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["bash", "-c", "bluetoothctl remove " + modelData.mac]);
                                        btScanProc.running = true;
                                    }
                                }
                            }
                        }

                        Text { text: "\uea5e"; font.family: fontName; font.pixelSize: 14; color: Theme.colPrimary; visible: modelData.connected }
                    }

                    MouseArea {
                        id: btItemMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.connected) return;
                            Quickshell.execDetached(["bash", "-c", "bluetoothctl connect " + modelData.mac + " 2>/dev/null || bluetoothctl pair " + modelData.mac]);
                            btScanProc.running = true;
                        }
                    }
                }
            }
        }
    }
}
