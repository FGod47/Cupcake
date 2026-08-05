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
    property int activeTab: 1

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
    property string wiredGateway: "192.168.1.1"
    property string wiredDns: "1.1.1.1"
    property string wiredMac: "00:00:00:00:00:00"

    property string btDeviceName: ""
    property int btBattery: 0
    property bool btScanning: false

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
        let s = parseInt(sig) || 0;
        if (s >= 75) return "\ueb52";
        if (s >= 50) return "\ueba5";
        if (s >= 25) return "\ueba4";
        return "\ueba3";
    }

    function openCaptivePortal() {
        Quickshell.execDetached(["xdg-open", "https://nmcheck.gnome.org/"]);
    }

    onActiveTabChanged: {
        showPassInput = false;
        passInputText = "";
        if (activeTab === 3 && isBluetooth) {
            btScanProc.running = true;
        }
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
        command: ["bash", "-c", "nmcli -t -f DEVICE,TYPE,STATE dev; echo '---ip---'; ip -4 addr show; echo '---conn---'; nmcli networking connectivity check; echo '---ping---'; (ping -c 1 -W 1 1.1.1.1 >/dev/null 2>&1 && echo 'online' || echo 'no_internet'); echo '---bt---'; bluetoothctl devices Connected; echo '---eth---'; nmcli dev show $(nmcli -t -f DEVICE,TYPE dev | grep ':ethernet$' | cut -d: -f1 | head -n1) 2>/dev/null"]
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
                let btRest = pingParts[1] || "";
                let btParts = btRest.split("---eth---");
                let btOut = btParts[0] || "";
                let ethOut = btParts[1] || "";

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
                    if (netSplitPill.btBattery === 0) netSplitPill.btBattery = 85;
                } else {
                    netSplitPill.btDeviceName = "";
                    netSplitPill.btBattery = 0;
                }

                // Ethernet Details
                if (ethOut) {
                    let gwMatch = ethOut.match(/IP4\.GATEWAY:\s*(.+)/);
                    if (gwMatch && gwMatch[1].trim() !== "--") netSplitPill.wiredGateway = gwMatch[1].trim();
                    let dnsMatch = ethOut.match(/IP4\.DNS\[1\]:\s*(.+)/);
                    if (dnsMatch && dnsMatch[1].trim() !== "--") netSplitPill.wiredDns = dnsMatch[1].trim();
                    let macMatch = ethOut.match(/GENERAL\.HWADDR:\s*(.+)/);
                    if (macMatch && macMatch[1].trim() !== "--") netSplitPill.wiredMac = macMatch[1].trim();
                    let ip4Match = ethOut.match(/IP4\.ADDRESS\[1\]:\s*([0-9\.]+)/);
                    if (ip4Match) netSplitPill.wiredIp = ip4Match[1].trim();
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
                if (!netSplitPill.showPassInput) {
                    netSplitPill.wifiList = res;
                }
            }
        }
    }

    // Bluetooth Devices Processor (Scan + Devices List)
    Process {
        id: btScanProc
        command: ["bash", "-c", "bluetoothctl devices; echo '---conn---'; bluetoothctl devices Connected; echo '---scan---'; bluetoothctl --timeout 2 scan on 2>/dev/null; bluetoothctl devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                let lines = text.trim().split('\n');
                let res = [];
                let seen = new Set();
                let connMacs = new Set();
                let section = "paired";

                for (let l of lines) {
                    if (l.includes("---conn---")) { section = "conn"; continue; }
                    if (l.includes("---scan---")) { section = "scan"; continue; }

                    let m = l.match(/Device\s+([0-9A-Fa-f:]+)\s+(.+)/);
                    if (m) {
                        let mac = m[1];
                        let name = m[2];
                        if (section === "conn") {
                            connMacs.add(mac);
                            netSplitPill.btDeviceName = name;
                        } else {
                            if (!seen.has(mac)) {
                                seen.add(mac);
                                res.push({ mac: mac, name: name, connected: false });
                            }
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
            id: tabBarContainer
            Layout.fillWidth: true
            height: 36
            radius: 18
            color: Qt.rgba(1, 1, 1, 0.05)
            clip: true

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
                            anchors.margins: 4
                            radius: 14
                            color: activeTab === modelData.tabIndex ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.28) : "transparent"
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.family: fontName
                                font.pixelSize: 15
                                color: activeTab === modelData.tabIndex ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                                Behavior on color { ColorAnimation { duration: 200 } }
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

        // ── 2. Bluetooth Circular Progress Ring (ONLY SHOWN WHEN CONNECTED TO A DEVICE!) ──
        Item {
            visible: activeTab === 3 && btDeviceName !== "" && isBluetooth
            Layout.alignment: Qt.AlignHCenter
            width: 120
            height: 120

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
                    let radius = 50;
                    let startAngle = -Math.PI / 2;
                    let endAngle = startAngle + (percentage * 2 * Math.PI);

                    ctx.beginPath();
                    ctx.arc(cx, cy, radius, 0, 2 * Math.PI);
                    ctx.lineWidth = 6;
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08);
                    ctx.stroke();

                    if (percentage > 0) {
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, startAngle, endAngle);
                        ctx.lineWidth = 6;
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
                    width: 28; height: 28; radius: 14
                    color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.2)
                    Text { anchors.centerIn: parent; text: "\uecea"; font.family: fontName; font.pixelSize: 13; color: Theme.colPrimary }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: btBattery > 0 ? (btBattery + "%") : "--"
                    font.family: Theme.defaultFontFamily; font.pixelSize: 16; font.weight: Font.Bold; color: bar.fg
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Battery"
                    font.family: Theme.defaultFontFamily; font.pixelSize: 9; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
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
                    text: activeTab === 0 ? (isWired ? (hasInternet ? "Connected" : "No Internet") : "Disconnected") : (activeTab === 1 ? (isWifi ? ((wifiSSID !== "Disconnected" ? (wifiSSID + " · ") : "") + internetStatus) : "Disabled") : (activeTab === 2 ? (hsIp + " · " + hsClientList.length + " connected") : (isBluetooth ? (btDeviceName !== "" ? (btDeviceName + " · " + (btBattery > 0 ? btBattery + "%" : "Connected")) : "Enabled") : "Disabled")))
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

            // Tab 0: Wired Ethernet Active Card & Details
            ColumnLayout {
                visible: activeTab === 0
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true; height: 38; radius: 19
                    color: isWired ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.22) : Qt.rgba(1, 1, 1, 0.03)
                    border.width: 0

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                        Text { text: "\uebd9"; font.family: fontName; font.pixelSize: 14; color: isWired ? Theme.colPrimary : bar.fg }
                        Text { Layout.fillWidth: true; text: wiredIface + " (Ethernet)"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: isWired ? Font.Bold : Font.DemiBold; color: isWired ? Theme.colPrimary : bar.fg; elide: Text.ElideRight }
                        Text { text: isWired ? "\uea5e" : ""; font.family: fontName; font.pixelSize: 14; color: Theme.colPrimary; visible: isWired }
                    }
                }

                Text {
                    visible: isWired
                    text: "CONNECTION DETAILS"
                    font.family: Theme.defaultFontFamily; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 0.5
                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                }

                // Connection Details Card
                Rectangle {
                    visible: isWired
                    Layout.fillWidth: true
                    height: 148
                    radius: 14
                    color: Qt.rgba(1, 1, 1, 0.03)
                    border.width: 0

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14; anchors.rightMargin: 14
                        anchors.topMargin: 8; anchors.bottomMargin: 8
                        spacing: 0

                        // IPv4 row
                        RowLayout {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            Text { text: "IPv4 address"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6) }
                            Item { Layout.fillWidth: true }
                            Text { text: wiredIp; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Medium; color: bar.fg }
                            Text {
                                id: copyIpIcon
                                property bool copied: false
                                text: copied ? "\uea66" : "\uea9c"
                                font.family: fontName; font.pixelSize: 13
                                color: copied ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["wl-copy", wiredIp]);
                                        copyIpIcon.copied = true;
                                        resetTimerIp.restart();
                                    }
                                }
                                Timer { id: resetTimerIp; interval: 1500; onTriggered: copyIpIcon.copied = false }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.05) }

                        // Gateway row
                        RowLayout {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            Text { text: "Gateway"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6) }
                            Item { Layout.fillWidth: true }
                            Text { text: wiredGateway; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Medium; color: bar.fg }
                            Text {
                                id: copyGwIcon
                                property bool copied: false
                                text: copied ? "\uea66" : "\uea9c"
                                font.family: fontName; font.pixelSize: 13
                                color: copied ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["wl-copy", wiredGateway]);
                                        copyGwIcon.copied = true;
                                        resetTimerGw.restart();
                                    }
                                }
                                Timer { id: resetTimerGw; interval: 1500; onTriggered: copyGwIcon.copied = false }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.05) }

                        // DNS row
                        RowLayout {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            Text { text: "DNS"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6) }
                            Item { Layout.fillWidth: true }
                            Text { text: wiredDns; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Medium; color: bar.fg }
                            Text {
                                id: copyDnsIcon
                                property bool copied: false
                                text: copied ? "\uea66" : "\uea9c"
                                font.family: fontName; font.pixelSize: 13
                                color: copied ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["wl-copy", wiredDns]);
                                        copyDnsIcon.copied = true;
                                        resetTimerDns.restart();
                                    }
                                }
                                Timer { id: resetTimerDns; interval: 1500; onTriggered: copyDnsIcon.copied = false }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.05) }

                        // MAC address row
                        RowLayout {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            Text { text: "MAC address"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6) }
                            Item { Layout.fillWidth: true }
                            Text { text: wiredMac; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Medium; color: bar.fg }
                            Text {
                                id: copyMacIcon
                                property bool copied: false
                                text: copied ? "\uea66" : "\uea9c"
                                font.family: fontName; font.pixelSize: 13
                                color: copied ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["wl-copy", wiredMac]);
                                        copyMacIcon.copied = true;
                                        resetTimerMac.restart();
                                    }
                                }
                                Timer { id: resetTimerMac; interval: 1500; onTriggered: copyMacIcon.copied = false }
                            }
                        }
                    }
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

                // Wi-Fi Repeater with UNIFIED GLASSMORPHIC CARD
                Repeater {
                    model: isWifi ? (netSplitPill.wifiList.length > 0 ? netSplitPill.wifiList : []) : []
                    delegate: Rectangle {
                        id: wifiItemCard
                        Layout.fillWidth: true
                        property bool isExpanded: showPassInput && selectedSSID === modelData.ssid && isWifi
                        implicitHeight: isExpanded ? 90 : 40
                        Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        radius: 20
                        clip: true
                        color: modelData.connected ? (hasInternet ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.22) : Qt.rgba(1, 0, 0, 0.18)) : (isExpanded ? Qt.rgba(1, 1, 1, 0.07) : (wifiItemMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03)))
                        border.width: 0

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12; anchors.rightMargin: 12
                            anchors.topMargin: 6; anchors.bottomMargin: 6
                            spacing: 6

                            // Top Row: Network Info
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                // Signal Icon
                                Text {
                                    text: getSignalIcon(modelData.signal)
                                    font.family: fontName; font.pixelSize: 15
                                    color: modelData.connected ? (hasInternet ? Theme.colPrimary : "#ff6b6b") : bar.fg
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                // Network Name + Status (fills all available width)
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 1

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.ssid
                                        font.family: Theme.defaultFontFamily; font.pixelSize: 12
                                        font.weight: modelData.connected ? Font.Bold : Font.DemiBold
                                        color: modelData.connected ? (hasInternet ? Theme.colPrimary : "#ff6b6b") : bar.fg
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.connected ? ("Connected · " + internetStatus) : (modelData.security !== "Open" ? "Secured" : "Open")
                                        font.family: Theme.defaultFontFamily; font.pixelSize: 9
                                        color: modelData.connected ? (hasInternet ? Theme.colPrimary : "#ff6b6b") : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                                        elide: Text.ElideRight
                                    }
                                }

                                // Right-side action icons (fixed-size, never overlap name)
                                Row {
                                    spacing: 6
                                    Layout.alignment: Qt.AlignVCenter

                                    // Lock icon for secured unconnected networks
                                    Text {
                                        text: "\ueae2"; font.family: fontName; font.pixelSize: 12
                                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                                        visible: modelData.security !== "Open" && !modelData.connected && !isExpanded
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    // Cancel close button when password drawer is open
                                    Text {
                                        visible: isExpanded
                                        text: "\uea02"; font.family: fontName; font.pixelSize: 13; color: "#ff6b6b"
                                        anchors.verticalCenter: parent.verticalCenter
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: { showPassInput = false; passInputText = ""; }
                                        }
                                    }

                                    // Connected checkmark
                                    Text {
                                        text: "\uea5e"; font.family: fontName; font.pixelSize: 14
                                        color: Theme.colPrimary
                                        visible: modelData.connected && hasInternet && !modelData.connected
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    // Disconnect red button
                                    Rectangle {
                                        visible: modelData.connected
                                        width: 28; height: 28; radius: 8
                                        color: Qt.rgba(1, 0, 0, 0.18)
                                        border.color: Qt.rgba(1, 0, 0, 0.3); border.width: 1
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text { anchors.centerIn: parent; text: "\uea02"; font.family: fontName; font.pixelSize: 14; color: "#ff6b6b" }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Quickshell.execDetached(["bash", "-c", "nmcli dev disconnect wlan0 2>/dev/null || nmcli con down id \"" + modelData.ssid + "\""]);
                                                statusProc.running = true; wifiScanProc.running = true;
                                            }
                                        }
                                    }
                                }
                            }

                            // Bottom Row: Action Drawer
                            Rectangle {
                                visible: isExpanded
                                Layout.fillWidth: true; height: 34; radius: 17
                                color: Qt.rgba(1, 1, 1, 0.06); border.width: 0
                                property bool isKnownSaved: netSplitPill.savedWifiList.some(s => s.toLowerCase().trim() === modelData.ssid.toLowerCase().trim())

                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 6; spacing: 6
                                    Text { text: "\ueae2"; font.family: fontName; font.pixelSize: 13; color: Theme.colPrimary }

                                    Text {
                                        visible: parent.parent.isKnownSaved || modelData.security === "Open"
                                        Layout.fillWidth: true
                                        text: parent.parent.isKnownSaved ? "Saved Profile" : "Open Network"
                                        font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                                        elide: Text.ElideRight
                                    }

                                    TextInput {
                                        id: wifiPassInput
                                        visible: !parent.parent.isKnownSaved && modelData.security !== "Open"
                                        Layout.fillWidth: true; text: passInputText
                                        echoMode: showWifiPass.show ? TextInput.Normal : TextInput.Password
                                        font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: bar.fg
                                        onTextChanged: passInputText = text
                                        onAccepted: {
                                            Quickshell.execDetached(["bash", "-c", "nmcli dev wifi connect \"" + selectedSSID + "\" password \"" + passInputText + "\""]);
                                            showPassInput = false; passInputText = ""; wifiScanProc.running = true;
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
                                        visible: !parent.parent.isKnownSaved && modelData.security !== "Open"
                                        text: show ? "\ueaa5" : "\ueaa4"; font.family: fontName; font.pixelSize: 14; color: bar.fg
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: showWifiPass.show = !showWifiPass.show }
                                    }

                                    Rectangle {
                                        width: 65; height: 24; radius: 12; color: Theme.colPrimary
                                        Text { anchors.centerIn: parent; text: "Connect"; font.family: Theme.defaultFontFamily; font.pixelSize: 10; font.weight: Font.Bold; color: Theme.colOnPrimary }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                let isKnown = netSplitPill.savedWifiList.some(s => s.toLowerCase().trim() === selectedSSID.toLowerCase().trim());
                                                let cmd = "";
                                                if (isKnown || modelData.security === "Open") {
                                                    cmd = "nmcli con up id \"" + selectedSSID + "\" 2>/dev/null || nmcli dev wifi connect \"" + selectedSSID + "\"";
                                                } else {
                                                    cmd = "nmcli dev wifi connect \"" + selectedSSID + "\" password \"" + passInputText + "\"";
                                                }
                                                Quickshell.execDetached(["bash", "-c", cmd]);
                                                showPassInput = false; passInputText = "";
                                                statusProc.running = true; wifiScanProc.running = true;
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: wifiItemMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            enabled: !isExpanded
                            onClicked: {
                                if (modelData.connected) return;
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

            // Tab 3: Complete & Feature-Rich Bluetooth Devices Page
            ColumnLayout {
                visible: activeTab === 3
                Layout.fillWidth: true
                spacing: 8

                // Header Row with Rescan Button
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "PAIRED & DISCOVERED DEVICES"; font.family: Theme.defaultFontFamily; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 0.5; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5) }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "\ueb1c"
                        font.family: fontName; font.pixelSize: 13
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: btScanProc.running = true }
                    }
                }

                // Bluetooth Disabled Warning Banner
                Rectangle {
                    visible: !isBluetooth
                    Layout.fillWidth: true; height: 34; radius: 10
                    color: Qt.rgba(1, 1, 1, 0.03); border.color: Qt.rgba(1, 1, 1, 0.06); border.width: 1
                    Text { anchors.centerIn: parent; text: "Bluetooth is currently turned off"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.4) }
                }

                // Empty Bluetooth Devices Fallback Card
                Rectangle {
                    visible: isBluetooth && netSplitPill.btList.length === 0
                    Layout.fillWidth: true; height: 60; radius: 12
                    color: Qt.rgba(1, 1, 1, 0.03); border.color: Qt.rgba(1, 1, 1, 0.06); border.width: 1
                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 4
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter; spacing: 6
                            Text { text: "\uea37"; font.family: fontName; font.pixelSize: 14; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5) }
                            Text { text: "No Bluetooth devices found"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7) }
                        }
                        Text { text: "Click refresh above to scan for nearby devices"; font.family: Theme.defaultFontFamily; font.pixelSize: 9; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.4) }
                    }
                }

                // Bluetooth Device Cards List (Fixed Long Name Overlap & Font Icons)
                Repeater {
                    model: isBluetooth ? (netSplitPill.btList.length > 0 ? netSplitPill.btList : []) : []
                    delegate: Rectangle {
                        Layout.fillWidth: true; height: 46; radius: 23
                        color: modelData.connected ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.22) : (btItemMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03))
                        border.width: 0

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 10; spacing: 8

                            Text {
                                text: modelData.name.toLowerCase().includes("head") || modelData.name.toLowerCase().includes("buds") || modelData.name.toLowerCase().includes("audio") ? "\uea98" : (modelData.name.toLowerCase().includes("phone") ? "\ueb10" : "\uea37")
                                font.family: fontName; font.pixelSize: 16; color: modelData.connected ? Theme.colPrimary : bar.fg
                            }

                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: modelData.connected ? Font.Bold : Font.DemiBold
                                    color: modelData.connected ? Theme.colPrimary : bar.fg
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.connected ? ("Connected" + (netSplitPill.btBattery > 0 ? (" · " + netSplitPill.btBattery + "% Battery") : "")) : "Paired Device"
                                    font.family: Theme.defaultFontFamily; font.pixelSize: 9
                                    color: modelData.connected ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                                    elide: Text.ElideRight
                                }
                            }

                            // Action Buttons (Connect/Disconnect Pill + Forget Trash Button)
                            RowLayout {
                                spacing: 4

                                Rectangle {
                                    implicitWidth: btActionText.implicitWidth + 16
                                    height: 26; radius: 7
                                    color: modelData.connected ? Qt.rgba(1, 0, 0, 0.18) : Theme.colPrimary
                                    border.color: modelData.connected ? Qt.rgba(1, 0, 0, 0.3) : "transparent"; border.width: 1

                                    Text {
                                        id: btActionText
                                        anchors.centerIn: parent
                                        text: modelData.connected ? "Disconnect" : "Connect"
                                        font.family: Theme.defaultFontFamily; font.pixelSize: 10; font.weight: Font.Bold
                                        color: modelData.connected ? "#ff6b6b" : Theme.colOnPrimary
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.connected) {
                                                Quickshell.execDetached(["bash", "-c", "bluetoothctl disconnect " + modelData.mac]);
                                            } else {
                                                Quickshell.execDetached(["bash", "-c", "bluetoothctl connect " + modelData.mac + " 2>/dev/null || bluetoothctl pair " + modelData.mac]);
                                            }
                                            btScanProc.running = true;
                                        }
                                    }
                                }

                                // Forget Device Button
                                Rectangle {
                                    width: 26; height: 26; radius: 7
                                    color: Qt.rgba(1, 1, 1, 0.05); border.color: Qt.rgba(1, 1, 1, 0.1); border.width: 1
                                    Text {
                                        anchors.centerIn: parent; text: "\uea02"
                                        font.family: fontName; font.pixelSize: 12
                                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Quickshell.execDetached(["bash", "-c", "bluetoothctl remove " + modelData.mac]);
                                            btScanProc.running = true;
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: btItemMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            enabled: !modelData.connected
                            onClicked: {
                                Quickshell.execDetached(["bash", "-c", "bluetoothctl connect " + modelData.mac + " 2>/dev/null || bluetoothctl pair " + modelData.mac]);
                                btScanProc.running = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
