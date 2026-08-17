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
    readonly property string fontName: bar.fontName

    y: bar.isBottom ? (solidBar.y - height - (isAttached ? 0 : 8)) : (isAttached ? (bar.midY + bar.barHeight) : (bar.midY + bar.barHeight + 8))
    Behavior on y { enabled: !bar.isBottom; NumberAnimation { duration: 350; easing.type: Easing.InOutExpo } }

    property bool menuExpanded: bar.netDropdownOpen
    readonly property int currentTab: bar.netDropdownTab // 1: Wi-Fi, 3: Bluetooth, 2: Hotspot, 0: Ethernet

    property var wifiList: []
    property var btList: []
    property var savedWifiList: []
    property var hsClientList: []

    property string wifiSSID: "Disconnected"
    property int wifiSignal: 85
    property string wifiIp: "192.168.0.103"
    property string internetStatus: "Internet Access"
    property bool hasInternet: true

    property string wiredIface: "enp6s0"
    property string wiredIp: "192.168.0.103"
    property string wiredGateway: "192.168.0.1"
    property string wiredDns: "1.1.1.1"
    property string wiredMac: "CC:28:AA:CA:FD:C3"

    property string btDeviceName: ""
    property int btBattery: 0
    property bool isScanning: false

    property string hsName: "cupcake"
    property string hsPass: "87654322"
    property string hsBand: "2.4 GHz"
    property string hsIp: "10.42.0.1"

    property string selectedSSID: ""
    property string passInputText: ""
    property bool showPassInput: false

    function getSignalIcon(sig) {
        let s = parseInt(sig) || 0;
        if (s >= 75) return "\ueb52";
        if (s >= 50) return "\ueba5";
        if (s >= 25) return "\ueba4";
        return "\ueba3";
    }

    onCurrentTabChanged: {
        showPassInput = false;
        passInputText = "";
        if (currentTab === 3 && bar.isBluetooth) {
            btScanProc.running = true;
        } else if (currentTab === 1 && bar.isWifi) {
            wifiScanProc.running = true;
        }
    }

    onMenuExpandedChanged: {
        if (menuExpanded) {
            statusProc.running = true;
            wifiScanProc.running = true;
            btScanProc.running = true;
            hsProc.running = true;
        } else {
            showPassInput = false;
            passInputText = "";
        }
    }

    readonly property real expandedW: 290
    property real contentW: expandedW

    readonly property real padTop: isAttached ? 0 : 14
    readonly property real padSide: isAttached ? 24 : 14
    readonly property real padBottom: isAttached ? 16 : 14

    readonly property real targetH: netContentCol.implicitHeight + padTop + padBottom

    // Align dropdown right edge to next section boundary (Hardware container)
    x: hardwareContainer.x + contentLayout.x + solidBar.x - contentW
    width: contentW
    height: menuExpanded ? targetH : 0

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

    // ── Pill Switch Component (Minimal Clean) ────────────────────
    component PillSwitch: Rectangle {
        id: switchRoot
        property bool checked: false
        signal toggled()

        width: 38
        height: 20
        radius: 10
        color: checked
               ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.22)
               : (switchMa.containsMouse ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.10) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.06))
        border.color: checked ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.3) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.12)
        border.width: 1

        Rectangle {
            width: 14
            height: 14
            radius: 7
            anchors.verticalCenter: parent.verticalCenter
            x: switchRoot.checked ? (parent.width - width - 3) : 3
            color: switchRoot.checked ? bar.fg : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        MouseArea {
            id: switchMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: switchRoot.toggled()
        }

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    // ── Tag Badge Component ──────────────────────────────────────
    component StatusTag: Rectangle {
        property alias tagText: tagLabel.text
        property color textColor: "#4EBA6F"
        property color badgeColor: Qt.rgba(0.3, 0.75, 0.4, 0.15)

        height: 18
        width: tagLabel.implicitWidth + 12
        radius: 5
        color: badgeColor

        Text {
            id: tagLabel
            anchors.centerIn: parent
            font.family: Theme.defaultFontFamily
            font.pixelSize: 9
            font.weight: Font.Bold
            font.letterSpacing: 0.5
            color: parent.textColor
        }
    }

    Item {
        id: animContainer
        anchors.fill: parent
        clip: false
        layer.enabled: true
        layer.samples: 8
        layer.smooth: true

        // ── Attached Mode Shape ──────────────────────────────────
        Shape {
            id: bgShape
            anchors.fill: parent
            visible: netSplitPill.isAttached
            property color shapeColor: bar.pillColor
            readonly property real r: 16
            readonly property real w: width
            readonly property real h: Math.max(height, 1)

            layer.enabled: true
            layer.samples: 8
            layer.smooth: true

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
                PathArc {
                    x: 2 * bgShape.r
                    y: bgShape.h
                    radiusX: bgShape.r
                    radiusY: bgShape.r
                    direction: PathArc.Counterclockwise
                }
                PathLine {
                    x: Math.max(2 * bgShape.r, bgShape.w - 2 * bgShape.r)
                    y: bgShape.h
                }
                PathArc {
                    x: bgShape.w - bgShape.r
                    y: Math.max(bgShape.r, bgShape.h - bgShape.r)
                    radiusX: bgShape.r
                    radiusY: bgShape.r
                    direction: PathArc.Counterclockwise
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
            antialiasing: true
            border.width: 1
            border.color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.12)
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
            command: ["bash", "-c", "nmcli -t -f DEVICE,TYPE,STATE dev; echo '---ip---'; ip -4 addr show; echo '---conn---'; nmcli networking connectivity check; echo '---bt---'; bluetoothctl devices Connected; echo '---eth---'; nmcli dev show $(nmcli -t -f DEVICE,TYPE dev | grep ':ethernet$' | cut -d: -f1 | head -n1) 2>/dev/null"]
            stdout: StdioCollector {
                onStreamFinished: {
                    if (!text) return;
                    let parts = text.split("---ip---");
                    let nmOut = parts[0] || "";
                    let rest = parts[1] || "";
                    let restParts = rest.split("---conn---");
                    let ipOut = restParts[0] || "";
                    let connRest = restParts[1] || "";
                    let connParts = connRest.split("---bt---");
                    let nmConnState = (connParts[0] || "").trim();
                    let btRest = connParts[1] || "";
                    let btParts = btRest.split("---eth---");
                    let btOut = btParts[0] || "";
                    let ethOut = btParts[1] || "";

                    netSplitPill.hasInternet = nmConnState === "full";

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
            onStarted: netSplitPill.isScanning = true
            onExited: netSplitPill.isScanning = false
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
            onStarted: netSplitPill.isScanning = true
            onExited: netSplitPill.isScanning = false
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

        // ── Inner Content Wrapper ────────────────────────────────
        Item {
            id: contentWrapper
            anchors.fill: parent
            clip: true
            opacity: netSplitPill.menuExpanded ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
            }

            ColumnLayout {
                id: netContentCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: netSplitPill.padSide
                anchors.rightMargin: netSplitPill.padSide
                anchors.topMargin: netSplitPill.padTop
                spacing: 12

                // ═════════════════════════════════════════════════════
                //  TAB 1: WI-FI VIEW
                // ═════════════════════════════════════════════════════
                ColumnLayout {
                    visible: netSplitPill.currentTab === 1
                    Layout.fillWidth: true
                    spacing: 12

                    // Category Header
                    RowLayout {
                        Layout.fillWidth: true
                        height: 18
                        spacing: 6

                        Text {
                            text: "\ueb52"
                            font.family: netSplitPill.fontName
                            font.pixelSize: 13
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                        }

                        Text {
                            text: "WI-FI"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 0.8
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                            Layout.fillWidth: true
                        }

                        Item {
                            width: 20; height: 20
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb13"
                                font.family: netSplitPill.fontName
                                font.pixelSize: 13
                                color: scanMa.containsMouse ? bar.fg : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                                rotation: netSplitPill.isScanning ? 360 : 0
                                Behavior on rotation { NumberAnimation { duration: 800; loops: Animation.Infinite } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            MouseArea {
                                id: scanMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: wifiScanProc.running = true
                            }
                        }
                    }

                    // Main Status & Switch Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Column {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: {
                                    if (bar.isWifi && netSplitPill.wifiSSID !== "Disconnected") return netSplitPill.wifiSSID;
                                    if (bar.isWifi) return "Wi-Fi Scanning...";
                                    return "Wi-Fi Disabled";
                                }
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 14
                                font.weight: Font.Bold
                                color: bar.fg
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: {
                                    if (bar.isWifi && netSplitPill.wifiSSID !== "Disconnected") return "Connected • " + netSplitPill.wifiIp;
                                    if (bar.isWifi) return "Not connected";
                                    return "Off";
                                }
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 11
                                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        PillSwitch {
                            checked: bar.isWifi
                            onToggled: {
                                Quickshell.execDetached(["nmcli", "radio", "wifi", bar.isWifi ? "off" : "on"]);
                                bar.isWifi = !bar.isWifi;
                            }
                        }
                    }

                    // Available Network Item Card
                    Column {
                        visible: bar.isWifi
                        Layout.fillWidth: true
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: netSplitPill.wifiList.slice(0, 3)
                            delegate: Rectangle {
                                id: wifiItemRoot
                                width: parent.width
                                property bool isConn: modelData.connected
                                property bool isSelected: netSplitPill.showPassInput && netSplitPill.selectedSSID === modelData.ssid

                                height: isSelected ? 80 : 44
                                radius: 10
                                clip: true
                                color: isConn
                                       ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.08)
                                       : (isSelected ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.06) : (wifiRowMa.containsMouse ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.05) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.03)))
                                border.color: isConn
                                              ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.16)
                                              : (isSelected ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.22) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.05))
                                border.width: 1

                                Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 120 } }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    anchors.topMargin: 8
                                    anchors.bottomMargin: 8
                                    spacing: 6

                                    // Header Row
                                    RowLayout {
                                        Layout.fillWidth: true
                                        height: 28
                                        spacing: 8

                                        Text {
                                            visible: modelData.security && modelData.security !== "--"
                                            text: "\ueae2"
                                            font.family: netSplitPill.fontName
                                            font.pixelSize: 13
                                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                                        }

                                        Text {
                                            text: modelData.ssid
                                            font.family: Theme.defaultFontFamily
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                            color: bar.fg
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: "5GHz"
                                            font.family: Theme.defaultFontFamily
                                            font.pixelSize: 10
                                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.4)
                                        }

                                        Item { Layout.fillWidth: true }

                                        // Join / Disconnect Button
                                        Rectangle {
                                            width: isConn ? 74 : 46
                                            height: 26
                                            radius: 6
                                            color: isConn ? Qt.rgba(1, 0.35, 0.35, 0.15) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.12)
                                            border.color: isConn ? Qt.rgba(1, 0.35, 0.35, 0.28) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.18)
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: isConn ? "Disconnect" : "Join"
                                                font.family: Theme.defaultFontFamily
                                                font.pixelSize: 11
                                                font.weight: Font.DemiBold
                                                color: isConn ? "#E06C75" : bar.fg
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (isConn) {
                                                        Quickshell.execDetached(["nmcli", "dev", "disconnect", "wlan0"]);
                                                        wifiScanProc.running = true;
                                                    } else {
                                                        if (modelData.security === "--" || modelData.security === "Open") {
                                                            Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", modelData.ssid]);
                                                            wifiScanProc.running = true;
                                                        } else {
                                                            netSplitPill.selectedSSID = modelData.ssid;
                                                            netSplitPill.showPassInput = true;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Inline Password Row
                                    RowLayout {
                                        Layout.fillWidth: true
                                        visible: wifiItemRoot.isSelected
                                        opacity: wifiItemRoot.isSelected ? 1.0 : 0.0
                                        spacing: 6

                                        TextField {
                                            id: passInputField
                                            Layout.fillWidth: true
                                            height: 26
                                            placeholderText: "Password..."
                                            echoMode: TextInput.Password
                                            color: bar.fg
                                            font.family: Theme.defaultFontFamily
                                            font.pixelSize: 11
                                            background: Rectangle {
                                                radius: 6
                                                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.08)
                                                border.color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.2)
                                                border.width: 1
                                            }
                                            onAccepted: joinBtn.triggered()
                                        }

                                        Rectangle {
                                            id: joinBtn
                                            width: 48
                                            height: 26
                                            radius: 6
                                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.22)
                                            border.color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.3)
                                            border.width: 1
                                            signal triggered()
                                            onTriggered: {
                                                Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", modelData.ssid, "password", passInputField.text]);
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
                                                color: bar.fg
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: joinBtn.triggered()
                                            }
                                        }

                                        Rectangle {
                                            width: 26
                                            height: 26
                                            radius: 6
                                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.08)
                                            Text {
                                                anchors.centerIn: parent
                                                text: "\ueb55"
                                                font.family: netSplitPill.fontName
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

                                MouseArea {
                                    id: wifiRowMa
                                    anchors.fill: parent
                                    enabled: !wifiItemRoot.isSelected
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (isConn) return;
                                        if (modelData.security === "--" || modelData.security === "Open") {
                                            Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", modelData.ssid]);
                                            wifiScanProc.running = true;
                                        } else {
                                            netSplitPill.selectedSSID = modelData.ssid;
                                            netSplitPill.showPassInput = true;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.06)
                    }

                    // Footer Row
                    RowLayout {
                        Layout.fillWidth: true
                        height: 20

                        Text {
                            text: "Wi-Fi settings"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            color: wifiFooterMa.containsMouse ? bar.fg : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "\uea1c"
                            font.family: netSplitPill.fontName
                            font.pixelSize: 12
                            color: wifiFooterMa.containsMouse ? bar.fg : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.4)
                        }

                        MouseArea {
                            id: wifiFooterMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                bar.netDropdownOpen = false;
                                Quickshell.execDetached(["bash", "-c", "quickshell --open-settings 2>/dev/null || quickshell"]);
                            }
                        }
                    }
                }

                // ═════════════════════════════════════════════════════
                //  TAB 3: BLUETOOTH VIEW
                // ═════════════════════════════════════════════════════
                ColumnLayout {
                    visible: netSplitPill.currentTab === 3
                    Layout.fillWidth: true
                    spacing: 12

                    // Category Header
                    RowLayout {
                        Layout.fillWidth: true
                        height: 18
                        spacing: 6

                        Text {
                            text: "\uea37"
                            font.family: netSplitPill.fontName
                            font.pixelSize: 13
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                        }

                        Text {
                            text: "BLUETOOTH"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 0.8
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                            Layout.fillWidth: true
                        }

                        Item {
                            width: 20; height: 20
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb13"
                                font.family: netSplitPill.fontName
                                font.pixelSize: 13
                                color: btScanMa.containsMouse ? bar.fg : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                                rotation: netSplitPill.isScanning ? 360 : 0
                                Behavior on rotation { NumberAnimation { duration: 800; loops: Animation.Infinite } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            MouseArea {
                                id: btScanMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: btScanProc.running = true
                            }
                        }
                    }

                    // Main Status & Switch Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Column {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "Bluetooth"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 14
                                font.weight: Font.Bold
                                color: bar.fg
                            }

                            Text {
                                text: {
                                    if (bar.isBluetooth && netSplitPill.btDeviceName !== "") return netSplitPill.btDeviceName + (netSplitPill.btBattery > 0 ? " • " + netSplitPill.btBattery + "%" : "");
                                    if (bar.isBluetooth) return "Ready to pair";
                                    return "Off";
                                }
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 11
                                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        PillSwitch {
                            checked: bar.isBluetooth
                            onToggled: {
                                Quickshell.execDetached(["bluetoothctl", "power", bar.isBluetooth ? "off" : "on"]);
                                bar.isBluetooth = !bar.isBluetooth;
                            }
                        }
                    }

                    // Paired Devices List
                    ColumnLayout {
                        visible: bar.isBluetooth && netSplitPill.btList.length > 0
                        Layout.fillWidth: true
                        spacing: 5

                        Repeater {
                            model: netSplitPill.btList.slice(0, 3)
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                radius: 10
                                property bool isConn: modelData.connected
                                color: isConn
                                       ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.08)
                                       : (btItemMa.containsMouse ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.05) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.025))
                                border.color: isConn ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.16) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.05)
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 8

                                    Text {
                                        text: (modelData.name && (modelData.name.includes("head") || modelData.name.includes("WH-") || modelData.name.includes("AirPods"))) ? "\uea76" : "\uea37"
                                        font.family: netSplitPill.fontName
                                        font.pixelSize: 13
                                        color: isConn ? bar.fg : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text {
                                            text: modelData.name || modelData.mac
                                            font.family: Theme.defaultFontFamily
                                            font.pixelSize: 12
                                            font.weight: isConn ? Font.Bold : Font.Normal
                                            color: bar.fg
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }
                                        Text {
                                            text: isConn ? "connected" : "paired"
                                            font.family: Theme.defaultFontFamily
                                            font.pixelSize: 10
                                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                                        }
                                    }

                                    Rectangle {
                                        width: isConn ? 74 : 54
                                        height: 24
                                        radius: 6
                                        color: isConn ? Qt.rgba(1, 0.35, 0.35, 0.15) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.10)
                                        border.color: isConn ? Qt.rgba(1, 0.35, 0.35, 0.28) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.16)
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: isConn ? "Disconnect" : "Connect"
                                            font.family: Theme.defaultFontFamily
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                            color: isConn ? "#E06C75" : bar.fg
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Quickshell.execDetached(["bash", "-c", "bluetoothctl " + (isConn ? "disconnect " : "connect ") + modelData.mac]);
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

                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.06)
                    }

                    // Footer Row
                    RowLayout {
                        Layout.fillWidth: true
                        height: 20

                        Text {
                            text: "Bluetooth settings"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            color: btFooterMa.containsMouse ? bar.fg : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "\uea1c"
                            font.family: netSplitPill.fontName
                            font.pixelSize: 12
                            color: btFooterMa.containsMouse ? bar.fg : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.4)
                        }

                        MouseArea {
                            id: btFooterMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                bar.netDropdownOpen = false;
                                Quickshell.execDetached(["bash", "-c", "quickshell --open-settings 2>/dev/null || quickshell"]);
                            }
                        }
                    }
                }

                // ═════════════════════════════════════════════════════
                //  TAB 2: PERSONAL HOTSPOT VIEW
                // ═════════════════════════════════════════════════════
                ColumnLayout {
                    visible: netSplitPill.currentTab === 2
                    Layout.fillWidth: true
                    spacing: 12

                    // Category Header
                    RowLayout {
                        Layout.fillWidth: true
                        height: 18
                        spacing: 6

                        Text {
                            text: "\ued1b"
                            font.family: netSplitPill.fontName
                            font.pixelSize: 13
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                        }

                        Text {
                            text: "PERSONAL HOTSPOT"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 0.8
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                            Layout.fillWidth: true
                        }
                    }

                    // Main Status & Switch Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Column {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "Personal hotspot"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 14
                                font.weight: Font.Bold
                                color: bar.fg
                            }

                            Text {
                                text: bar.isHotspot ? (netSplitPill.hsName + " • " + netSplitPill.hsClientList.length + " connected") : "Off"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 11
                                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        PillSwitch {
                            checked: bar.isHotspot
                            onToggled: {
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

                    // Details Rows
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Layout.leftMargin: 2
                        Layout.rightMargin: 2

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Network name"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 11
                                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: netSplitPill.hsName
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: bar.fg
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Password"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 11
                                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: netSplitPill.hsPass
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: "#E0A96D"
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.06)
                    }

                    // Footer Row
                    RowLayout {
                        Layout.fillWidth: true
                        height: 20

                        Text {
                            text: "Hotspot settings"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            color: hsFooterMa.containsMouse ? bar.fg : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "\uea1c"
                            font.family: netSplitPill.fontName
                            font.pixelSize: 12
                            color: hsFooterMa.containsMouse ? bar.fg : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.4)
                        }

                        MouseArea {
                            id: hsFooterMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                bar.netDropdownOpen = false;
                                Quickshell.execDetached(["bash", "-c", "quickshell --open-settings 2>/dev/null || quickshell"]);
                            }
                        }
                    }
                }

                // ═════════════════════════════════════════════════════
                //  TAB 0: WIRED ETHERNET VIEW
                // ═════════════════════════════════════════════════════
                ColumnLayout {
                    visible: netSplitPill.currentTab === 0
                    Layout.fillWidth: true
                    spacing: 12

                    // Category Header
                    RowLayout {
                        Layout.fillWidth: true
                        height: 18
                        spacing: 6

                        Text {
                            text: "\uebd9"
                            font.family: netSplitPill.fontName
                            font.pixelSize: 13
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                        }

                        Text {
                            text: "WIRED ETHERNET"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 0.8
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                            Layout.fillWidth: true
                        }
                    }

                    // Main Status Row with Connected Tag
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Column {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "Wired ethernet"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 14
                                font.weight: Font.Bold
                                color: bar.fg
                            }

                            Text {
                                text: netSplitPill.wiredIp || "192.168.0.103"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 11
                                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                            }
                        }

                        StatusTag {
                            visible: bar.isWired
                            tagText: "Connected"
                            textColor: "#4EBA6F"
                            badgeColor: Qt.rgba(0.3, 0.75, 0.4, 0.15)
                        }
                    }

                    // Details Rows
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 7
                        Layout.leftMargin: 2
                        Layout.rightMargin: 2

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Interface"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5) }
                            Item { Layout.fillWidth: true }
                            Text { text: netSplitPill.wiredIface; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.DemiBold; color: bar.fg }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "IPv4 address"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5) }
                            Item { Layout.fillWidth: true }
                            Text { text: netSplitPill.wiredIp || "192.168.0.103"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.DemiBold; color: bar.fg }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Gateway"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5) }
                            Item { Layout.fillWidth: true }
                            Text { text: netSplitPill.wiredGateway || "192.168.0.1"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.DemiBold; color: bar.fg }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Hardware MAC"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5) }
                            Item { Layout.fillWidth: true }
                            Text { text: netSplitPill.wiredMac || "CC:28:AA:CA:FD:C3"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.DemiBold; color: bar.fg }
                        }
                    }

                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.06)
                    }

                    // Footer Row
                    RowLayout {
                        Layout.fillWidth: true
                        height: 20

                        Text {
                            text: "Network settings"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            color: ethFooterMa.containsMouse ? bar.fg : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "\uea1c"
                            font.family: netSplitPill.fontName
                            font.pixelSize: 12
                            color: ethFooterMa.containsMouse ? bar.fg : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.4)
                        }

                        MouseArea {
                            id: ethFooterMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                bar.netDropdownOpen = false;
                                Quickshell.execDetached(["bash", "-c", "quickshell --open-settings 2>/dev/null || quickshell"]);
                            }
                        }
                    }
                }
            }
        }
    }
}
