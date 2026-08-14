import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../common"
import "../../../theme"

Item {
    id: netSplitPill

    readonly property bool isAttached: Theme.barDropdownStyle === "Attached"
    y: isAttached ? (bar.midY + bar.barHeight) : (bar.midY + bar.barHeight + 8)
    Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.InOutExpo } }

    property bool menuExpanded: bar.netDropdownOpen
    property int activeTab: 1  // 0: Ethernet, 1: Wi-Fi, 2: Hotspot, 3: Bluetooth

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

    onActiveTabChanged: {
        showPassInput = false;
        passInputText = "";
        if (activeTab === 3 && bar.isBluetooth) {
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

    readonly property real expandedW: 320
    property real contentW: expandedW

    readonly property real padTop: isAttached ? 22 : 14
    readonly property real padSide: isAttached ? 24 : 14
    readonly property real padBottom: isAttached ? 22 : 14

    readonly property real targetH: netContentCol.implicitHeight + padTop + padBottom

    x: bar.barX + bar.barW - contentW - 140
    width: contentW
    height: menuExpanded ? targetH : 0

    // Carousel Wallpaper Switcher signature InOutExpo & BezierSpline curves
    Behavior on height {
        NumberAnimation {
            duration: 500
            easing.type: Easing.InOutExpo
        }
    }
    Behavior on width {
        NumberAnimation {
            duration: 400
            easing.type: Easing.InOutExpo
        }
    }
    Behavior on x {
        NumberAnimation {
            duration: 400
            easing.type: Easing.InOutExpo
        }
    }

    property real openProgress: menuExpanded ? 1.0 : 0.0
    Behavior on openProgress {
        NumberAnimation {
            duration: 350
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
        }
    }

    opacity: openProgress
    visible: height > 0 || opacity > 0.01

    Item {
        id: animContainer
        anchors.fill: parent
        clip: true

        // ── Attached Mode Shape ──────────────────────────────────
        Shape {
            id: bgShape
            anchors.fill: parent
            visible: netSplitPill.isAttached
            property color shapeColor: bar.pillColor
            readonly property real r: 16
            readonly property real w: width
            readonly property real h: Math.max(height, 1)

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: bgShape.shapeColor
                startX: 0
                startY: 0

                PathArc {
                    x: bgShape.r
                    y: bgShape.r
                    radiusX: bgShape.r
                    radiusY: bgShape.r
                    direction: PathArc.Clockwise
                }
                PathLine {
                    x: bgShape.r
                    y: Math.max(bgShape.r, bgShape.h - bgShape.r)
                }
                PathQuad {
                    x: 2 * bgShape.r
                    y: bgShape.h
                    controlX: bgShape.r
                    controlY: bgShape.h
                }
                PathLine {
                    x: Math.max(2 * bgShape.r, bgShape.w - 2 * bgShape.r)
                    y: bgShape.h
                }
                PathQuad {
                    x: bgShape.w - bgShape.r
                    y: Math.max(bgShape.r, bgShape.h - bgShape.r)
                    controlX: bgShape.w - bgShape.r
                    controlY: bgShape.h
                }
                PathLine {
                    x: bgShape.w - bgShape.r
                    y: bgShape.r
                }
                PathArc {
                    x: bgShape.w
                    y: 0
                    radiusX: bgShape.r
                    radiusY: bgShape.r
                    direction: PathArc.Clockwise
                }
                PathLine {
                    x: 0
                    y: 0
                }
            }
        }

        // ── Floating Mode Shape ──────────────────────────────────
        Rectangle {
            id: bgRect
            anchors.fill: parent
            visible: !netSplitPill.isAttached
            radius: 16
            color: bar.pillColor
        }

        // ── Background Linux Network Process Handlers ────────────
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
                    if (nameM && nameM[1].trim()) netSplitPill.hsName = nameM[1].trim();

                    let passM = nmOut.match(/802-11-wireless-security.psk:\s*(.+)/);
                    if (passM && passM[1].trim()) netSplitPill.hsPass = passM[1].trim();

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
                        if (m) clients.push({ ip: m[1], mac: m[2] });
                    }
                    netSplitPill.hsClientList = clients;
                }
            }
        }

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

                    let ethMatch = nmOut.match(/^([^:]+):ethernet:connected/m);
                    if (ethMatch) netSplitPill.wiredIface = ethMatch[1].trim();

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

                    let btMatch = btOut.match(/Device\s+([0-9A-Fa-f:]+)\s+(.+)/);
                    if (btMatch) {
                        netSplitPill.btDeviceName = btMatch[2].trim();
                        if (netSplitPill.btBattery === 0) netSplitPill.btBattery = 85;
                    } else {
                        netSplitPill.btDeviceName = "";
                        netSplitPill.btBattery = 0;
                    }

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
                    if (!netSplitPill.showPassInput) netSplitPill.wifiList = res;
                }
            }
        }

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

                    for (let dev of res) dev.connected = connMacs.has(dev.mac);
                    netSplitPill.btList = res;
                }
            }
        }

        MouseArea {
            id: netSplitPillMa
            anchors.fill: parent
            enabled: bar.netDropdownOpen
            hoverEnabled: true
            onClicked: {
                // Keep open on interaction
            }
        }

        // ── Inner Content Wrapper (Reveals smoothly without squishing) ──
        Item {
            id: contentWrapper
            anchors.fill: parent
            clip: true
            opacity: netSplitPill.menuExpanded ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
            }

            // ── Nordic Minimalist Layout ─────────────────────────────
            ColumnLayout {
                id: netContentCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: netSplitPill.padSide
                anchors.rightMargin: netSplitPill.padSide
                anchors.topMargin: netSplitPill.padTop
                spacing: 12

                // ── 1. Compact Mode Tabs ─────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: [
                            { id: 1, name: "Wi-Fi", icon: "\ueb52" },
                            { id: 3, name: "Bluetooth", icon: "\uea37" },
                            { id: 2, name: "Hotspot", icon: "\ued1b" },
                            { id: 0, name: "Ethernet", icon: "\uebd9" }
                        ]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 26
                            radius: 13
                            property bool isSel: netSplitPill.activeTab === modelData.id
                            color: isSel ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.22) : (tabMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                            border.color: isSel ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.45) : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 5
                                Text {
                                    text: modelData.icon
                                    font.family: fontName
                                    font.pixelSize: 11
                                    color: isSel ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: modelData.name
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 11
                                    font.weight: isSel ? Font.DemiBold : Font.Normal
                                    color: isSel ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: tabMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: netSplitPill.activeTab = modelData.id
                            }
                        }
                    }
                }

                // ── 2. Nordic Header Card with Toggle Switch ─────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Column {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: {
                                if (netSplitPill.activeTab === 1) return "Wi-Fi";
                                if (netSplitPill.activeTab === 3) return "Bluetooth";
                                if (netSplitPill.activeTab === 2) return "Hotspot";
                                return "Ethernet";
                            }
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            color: bar.fg
                        }

                        Text {
                            text: {
                                if (netSplitPill.activeTab === 1) {
                                    return (bar.isWifi && netSplitPill.wifiSSID !== "Disconnected") ? netSplitPill.wifiSSID : (bar.isWifi ? "Scanning..." : "Disabled");
                                } else if (netSplitPill.activeTab === 3) {
                                    return (bar.isBluetooth && netSplitPill.btDeviceName !== "") ? netSplitPill.btDeviceName : (bar.isBluetooth ? "Active" : "Disabled");
                                } else if (netSplitPill.activeTab === 2) {
                                    return bar.isHotspot ? (netSplitPill.hsName + " • " + netSplitPill.hsClientList.length + " connected") : "Disabled";
                                } else {
                                    return bar.isWired ? (netSplitPill.wiredIp || "Connected") : "Disconnected";
                                }
                            }
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 12
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }

                    // Nordic Toggle Switch
                    Rectangle {
                        width: 40
                        height: 22
                        radius: 11
                        property bool checked: {
                            if (netSplitPill.activeTab === 1) return bar.isWifi;
                            if (netSplitPill.activeTab === 3) return bar.isBluetooth;
                            if (netSplitPill.activeTab === 2) return bar.isHotspot;
                            return bar.isWired;
                        }
                        color: checked ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.15)
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            x: parent.checked ? (parent.width - width - 2) : 2
                            color: "#FFFFFF"
                            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (netSplitPill.activeTab === 1) {
                                    Quickshell.execDetached(["nmcli", "radio", "wifi", bar.isWifi ? "off" : "on"]);
                                    bar.isWifi = !bar.isWifi;
                                } else if (netSplitPill.activeTab === 3) {
                                    Quickshell.execDetached(["bluetoothctl", "power", bar.isBluetooth ? "off" : "on"]);
                                    bar.isBluetooth = !bar.isBluetooth;
                                } else if (netSplitPill.activeTab === 2) {
                                    if (bar.isHotspot) {
                                        Quickshell.execDetached(["nmcli", "con", "down", "Hotspot"]);
                                        bar.isHotspot = false;
                                    } else {
                                        Quickshell.execDetached(["bash", "-c", "nmcli con up Hotspot 2>/dev/null || nmcli dev wifi hotspot ssid " + netSplitPill.hsName + " password " + netSplitPill.hsPass]);
                                        bar.isHotspot = true;
                                    }
                                }
                            }
                        }
                    }
                }

                // Action Pill Row (Scan / Saved)
                Row {
                    spacing: 6
                    visible: netSplitPill.activeTab === 1 || netSplitPill.activeTab === 3

                    Rectangle {
                        height: 24
                        width: scanRow.implicitWidth + 16
                        radius: 12
                        color: scanMa.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.08)
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            id: scanRow
                            anchors.centerIn: parent
                            spacing: 5
                            Text {
                                text: "\ueb13"
                                font.family: fontName
                                font.pixelSize: 11
                                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.8)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Scan"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.85)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: scanMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (netSplitPill.activeTab === 1) wifiScanProc.running = true;
                                else btScanProc.running = true;
                            }
                        }
                    }

                    Rectangle {
                        visible: netSplitPill.activeTab === 1
                        height: 24
                        width: savedText.implicitWidth + 16
                        radius: 12
                        color: netSplitPill.showSavedWifi ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.22) : (savedMa.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.08))
                        border.color: netSplitPill.showSavedWifi ? Theme.colPrimary : "transparent"
                        border.width: 1

                        Text {
                            id: savedText
                            anchors.centerIn: parent
                            text: "Saved"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: netSplitPill.showSavedWifi ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.85)
                        }

                        MouseArea {
                            id: savedMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                netSplitPill.showSavedWifi = !netSplitPill.showSavedWifi;
                                if (netSplitPill.showSavedWifi) savedProc.running = true;
                            }
                        }
                    }
                }

                // Subtle Hairline Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.08)
                }

                // ── 3. Wi-Fi Device / Network List ───────────────────
                ColumnLayout {
                    visible: netSplitPill.activeTab === 1
                    Layout.fillWidth: true
                    spacing: 4

                    // Password Entry Card
                    Rectangle {
                        visible: netSplitPill.showPassInput
                        Layout.fillWidth: true
                        height: 80
                        radius: 12
                        color: Qt.rgba(1, 1, 1, 0.06)
                        border.color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.3)
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            Text {
                                text: "Connect to " + netSplitPill.selectedSSID
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                color: bar.fg
                            }

                            RowLayout {
                                width: parent.width
                                spacing: 6

                                TextField {
                                    id: passInputField
                                    Layout.fillWidth: true
                                    height: 28
                                    placeholderText: "Password..."
                                    echoMode: TextInput.Password
                                    color: bar.fg
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 11
                                    background: Rectangle {
                                        radius: 6
                                        color: Qt.rgba(1, 1, 1, 0.1)
                                    }
                                    onAccepted: connectBtn.triggered()
                                }

                                Rectangle {
                                    id: connectBtn
                                    width: 54
                                    height: 28
                                    radius: 6
                                    color: Theme.colPrimary
                                    signal triggered()
                                    onTriggered: {
                                        Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", netSplitPill.selectedSSID, "password", passInputField.text]);
                                        netSplitPill.showPassInput = false;
                                        passInputField.text = "";
                                        wifiScanProc.running = true;
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Join"
                                        font.family: Theme.defaultFontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                        color: "#FFFFFF"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: connectBtn.triggered()
                                    }
                                }

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 6
                                    color: Qt.rgba(1, 1, 1, 0.08)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "\uea76"
                                        font.family: fontName
                                        font.pixelSize: 12
                                        color: bar.fg
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            netSplitPill.showPassInput = false;
                                            passInputField.text = "";
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Available Wi-Fi Items
                    Repeater {
                        model: netSplitPill.showSavedWifi ? netSplitPill.savedWifiList : netSplitPill.wifiList.slice(0, 5)
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: 10
                            property string itemSSID: netSplitPill.showSavedWifi ? modelData : modelData.ssid
                            property bool isConn: !netSplitPill.showSavedWifi && modelData.connected
                            property int sigVal: netSplitPill.showSavedWifi ? 80 : modelData.signal

                            color: isConn
                                   ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.16)
                                   : (wifiItemMa.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent")
                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                Text {
                                    text: netSplitPill.getSignalIcon(sigVal)
                                    font.family: fontName
                                    font.pixelSize: 14
                                    color: isConn ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: itemSSID
                                        font.family: Theme.defaultFontFamily
                                        font.pixelSize: 12
                                        font.weight: isConn ? Font.Bold : Font.Normal
                                        color: isConn ? Theme.colPrimary : bar.fg
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                    Text {
                                        text: isConn ? "Connected" : (netSplitPill.showSavedWifi ? "Saved" : (modelData.security && modelData.security !== "--" ? "Secured" : "Open"))
                                        font.family: Theme.defaultFontFamily
                                        font.pixelSize: 10
                                        color: isConn ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                                    }
                                }

                                Text {
                                    visible: !netSplitPill.showSavedWifi && modelData.security && modelData.security !== "--" && !isConn
                                    text: "\ueae2"
                                    font.family: fontName
                                    font.pixelSize: 12
                                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.4)
                                }

                                Text {
                                    visible: isConn
                                    text: "Disconnect"
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: Theme.colError
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Quickshell.execDetached(["nmcli", "dev", "disconnect", "wlan0"]);
                                            wifiScanProc.running = true;
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: wifiItemMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (isConn) return;
                                    if (netSplitPill.showSavedWifi || (modelData.security === "--" || modelData.security === "Open")) {
                                        Quickshell.execDetached(["nmcli", "con", "up", itemSSID]);
                                        wifiScanProc.running = true;
                                    } else {
                                        netSplitPill.selectedSSID = itemSSID;
                                        netSplitPill.showPassInput = true;
                                    }
                                }
                            }
                        }
                    }
                }

                // ── 4. Bluetooth Devices List ────────────────────────
                ColumnLayout {
                    visible: netSplitPill.activeTab === 3
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: netSplitPill.btList.slice(0, 5)
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 38
                            radius: 10
                            property bool isConn: modelData.connected
                            color: isConn
                                   ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.16)
                                   : (btItemMa.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent")
                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                Text {
                                    text: (modelData.name && (modelData.name.includes("head") || modelData.name.includes("WH-") || modelData.name.includes("AirPods"))) ? "\uea76" : "\uea37"
                                    font.family: fontName
                                    font.pixelSize: 14
                                    color: isConn ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: modelData.name || modelData.mac
                                        font.family: Theme.defaultFontFamily
                                        font.pixelSize: 12
                                        font.weight: isConn ? Font.Bold : Font.Normal
                                        color: isConn ? Theme.colPrimary : bar.fg
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                    Text {
                                        text: isConn ? ("connected" + (netSplitPill.btBattery > 0 ? " • " + netSplitPill.btBattery + "%" : "")) : "paired • trusted"
                                        font.family: Theme.defaultFontFamily
                                        font.pixelSize: 10
                                        color: isConn ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                                    }
                                }

                                Text {
                                    text: isConn ? "Disconnect" : "Connect"
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: isConn ? Theme.colError : Theme.colPrimary
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Quickshell.execDetached(["bash", "-c", "bluetoothctl " + (isConn ? "disconnect " : "connect ") + modelData.mac]);
                                            btScanProc.running = true;
                                        }
                                    }
                                }

                                Text {
                                    text: "\uea6a"
                                    font.family: fontName
                                    font.pixelSize: 12
                                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.4)
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Quickshell.execDetached(["bash", "-c", "bluetoothctl remove " + modelData.mac]);
                                            btScanProc.running = true;
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: btItemMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached(["bash", "-c", "bluetoothctl " + (modelData.connected ? "disconnect " : "connect ") + modelData.mac]);
                                    btScanProc.running = true;
                                }
                            }
                        }
                    }
                }

                // ── 5. Ethernet Status View ──────────────────────────
                ColumnLayout {
                    visible: netSplitPill.activeTab === 0
                    Layout.fillWidth: true
                    spacing: 6

                    component EthInfoRow: RowLayout {
                        property string label: ""
                        property string val: ""
                        Layout.fillWidth: true
                        Text {
                            text: label
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: val
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: bar.fg
                        }
                    }

                    EthInfoRow { label: "Interface"; val: netSplitPill.wiredIface }
                    EthInfoRow { label: "IPv4 Address"; val: netSplitPill.wiredIp || "--" }
                    EthInfoRow { label: "Gateway"; val: netSplitPill.wiredGateway || "--" }
                    EthInfoRow { label: "DNS Server"; val: netSplitPill.wiredDns || "--" }
                    EthInfoRow { label: "Hardware MAC"; val: netSplitPill.wiredMac || "--" }
                }

                // ── 6. Hotspot Configuration View ────────────────────
                ColumnLayout {
                    visible: netSplitPill.activeTab === 2
                    Layout.fillWidth: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "SSID Name"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: netSplitPill.hsName
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: bar.fg
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Password"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: netSplitPill.hsPass
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: Theme.colPrimary
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Band Frequency"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: netSplitPill.hsBand
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: bar.fg
                        }
                    }
                }
            }
        }
    }
}
