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
    readonly property int currentTab: bar.netDropdownTab // 1: Wi-Fi, 3: Bluetooth, 2: Hotspot, 0: Ethernet

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
    property bool isScanning: false

    property string hsName: "Cupcake_AP"
    property string hsPass: "12345678"
    property string hsBand: "2.4 GHz"
    property string hsIp: "10.42.0.1"

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

    readonly property real expandedW: 320
    property real contentW: expandedW

    readonly property real padTop: isAttached ? 22 : 14
    readonly property real padSide: isAttached ? 26 : 14
    readonly property real padBottom: isAttached ? 22 : 14

    readonly property real targetH: netContentCol.implicitHeight + padTop + padBottom

    // Align dropdown right edge to next section boundary (Hardware container)
    x: hardwareContainer.x + contentLayout.x + solidBar.x - contentW
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

                    // Active Wi-Fi Row (Flat & seamless)
                    Item {
                        Layout.fillWidth: true
                        height: 48

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 12

                            Item {
                                width: 24
                                height: 24

                                Text {
                                    anchors.centerIn: parent
                                    text: "\ueb52"
                                    font.family: fontName
                                    font.pixelSize: 18
                                    color: bar.isWifi && netSplitPill.wifiSSID !== "Disconnected"
                                           ? Theme.colPrimary
                                           : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: {
                                        if (bar.isWifi && netSplitPill.wifiSSID !== "Disconnected") return netSplitPill.wifiSSID;
                                        if (bar.isWifi) return "Wi-Fi Scanning...";
                                        return "Wi-Fi Disabled";
                                    }
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                    color: bar.fg
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: {
                                        if (bar.isWifi && netSplitPill.wifiSSID !== "Disconnected") return "Connected • " + netSplitPill.wifiIp;
                                        if (bar.isWifi) return "Not connected";
                                        return "Turn on Wi-Fi to connect";
                                    }
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 11
                                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.55)
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            Rectangle {
                                width: 38
                                height: 22
                                radius: 11
                                color: bar.isWifi ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.15)
                                Behavior on color { ColorAnimation { duration: 200 } }

                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 9
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: bar.isWifi ? (parent.width - width - 2) : 2
                                    color: "#FFFFFF"
                                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["nmcli", "radio", "wifi", bar.isWifi ? "off" : "on"]);
                                        bar.isWifi = !bar.isWifi;
                                    }
                                }
                            }
                        }
                    }

                    // Section Header
                    RowLayout {
                        Layout.fillWidth: true
                        visible: bar.isWifi

                        Text {
                            text: "NEARBY NETWORKS"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                        }

                        Item { Layout.fillWidth: true }

                        Item {
                            width: 20
                            height: 20
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb13"
                                font.family: fontName
                                font.pixelSize: 13
                                color: scanMa.containsMouse ? bar.fg : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.55)
                                rotation: netSplitPill.isScanning ? 360 : 0
                                Behavior on rotation { NumberAnimation { duration: 800; loops: Animation.Infinite } }
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

                    // Available Wi-Fi Items (with Inline In-Place Password Expansion)
                    Column {
                        visible: bar.isWifi
                        Layout.fillWidth: true
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: netSplitPill.wifiList.slice(0, 5)
                            delegate: Rectangle {
                                id: wifiItemRoot
                                width: parent.width
                                property bool isConn: modelData.connected
                                property bool isSelected: netSplitPill.showPassInput && netSplitPill.selectedSSID === modelData.ssid
                                
                                height: isSelected ? 72 : 34
                                radius: 8
                                clip: true
                                color: isConn
                                       ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.15)
                                       : (isSelected ? Qt.rgba(1, 1, 1, 0.09) : (wifiRowMa.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"))
                                border.color: isSelected ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.35) : "transparent"
                                border.width: isSelected ? 1 : 0
                                
                                Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 120 } }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    anchors.topMargin: 6
                                    anchors.bottomMargin: 6
                                    spacing: 6

                                    // Header Row
                                    RowLayout {
                                        Layout.fillWidth: true
                                        height: 22
                                        spacing: 8

                                        Text {
                                            text: netSplitPill.getSignalIcon(modelData.signal)
                                            font.family: fontName
                                            font.pixelSize: 13
                                            color: isConn ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.75)
                                        }

                                        Text {
                                            visible: modelData.security && modelData.security !== "--" && !isConn
                                            text: "\ueae2"
                                            font.family: fontName
                                            font.pixelSize: 11
                                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.4)
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.ssid
                                            font.family: Theme.defaultFontFamily
                                            font.pixelSize: 12
                                            font.weight: isConn ? Font.Bold : Font.Normal
                                            color: isConn ? Theme.colPrimary : bar.fg
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: isConn ? "Disconnect" : (modelData.security && modelData.security !== "--" ? "5GHz" : "open")
                                            font.family: Theme.defaultFontFamily
                                            font.pixelSize: 11
                                            font.weight: isConn ? Font.Medium : Font.Normal
                                            color: isConn ? Theme.colError : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)

                                            MouseArea {
                                                anchors.fill: parent
                                                enabled: isConn
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    Quickshell.execDetached(["nmcli", "dev", "disconnect", "wlan0"]);
                                                    wifiScanProc.running = true;
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
                                                color: Qt.rgba(1, 1, 1, 0.12)
                                            }
                                            onAccepted: connectBtn.triggered()
                                        }

                                        Rectangle {
                                            id: connectBtn
                                            width: 50
                                            height: 26
                                            radius: 6
                                            color: Theme.colPrimary
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
                                                color: "#FFFFFF"
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: connectBtn.triggered()
                                            }
                                        }

                                        Rectangle {
                                            width: 26
                                            height: 26
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
                }

                // ═════════════════════════════════════════════════════
                //  TAB 3: BLUETOOTH VIEW
                // ═════════════════════════════════════════════════════
                ColumnLayout {
                    visible: netSplitPill.currentTab === 3
                    Layout.fillWidth: true
                    spacing: 12

                    // Active Bluetooth Row (Flat & seamless)
                    Item {
                        Layout.fillWidth: true
                        height: 48

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 12

                            Item {
                                width: 24
                                height: 24

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uea37"
                                    font.family: fontName
                                    font.pixelSize: 18
                                    color: bar.isBluetooth
                                           ? Theme.colPrimary
                                           : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: "Bluetooth"
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                    color: bar.fg
                                }

                                Text {
                                    text: {
                                        if (bar.isBluetooth && netSplitPill.btDeviceName !== "") return netSplitPill.btDeviceName + (netSplitPill.btBattery > 0 ? " • " + netSplitPill.btBattery + "%" : "");
                                        if (bar.isBluetooth) return "Active • Ready to pair";
                                        return "Bluetooth Disabled";
                                    }
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 11
                                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.55)
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            Rectangle {
                                width: 38
                                height: 22
                                radius: 11
                                color: bar.isBluetooth ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.15)
                                Behavior on color { ColorAnimation { duration: 200 } }

                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 9
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: bar.isBluetooth ? (parent.width - width - 2) : 2
                                    color: "#FFFFFF"
                                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["bluetoothctl", "power", bar.isBluetooth ? "off" : "on"]);
                                        bar.isBluetooth = !bar.isBluetooth;
                                    }
                                }
                            }
                        }
                    }

                    // Section Header
                    RowLayout {
                        Layout.fillWidth: true
                        visible: bar.isBluetooth

                        Text {
                            text: "PAIRED & NEARBY DEVICES"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                        }

                        Item { Layout.fillWidth: true }

                        Item {
                            width: 20
                            height: 20
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb13"
                                font.family: fontName
                                font.pixelSize: 13
                                color: btScanMa.containsMouse ? bar.fg : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.55)
                                rotation: netSplitPill.isScanning ? 360 : 0
                                Behavior on rotation { NumberAnimation { duration: 800; loops: Animation.Infinite } }
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

                    // Bluetooth Devices List
                    ColumnLayout {
                        visible: bar.isBluetooth
                        Layout.fillWidth: true
                        spacing: 3

                        Repeater {
                            model: netSplitPill.btList.slice(0, 5)
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 38
                                radius: 8
                                property bool isConn: modelData.connected
                                color: isConn
                                       ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.15)
                                       : (btRowMa.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent")
                                Behavior on color { ColorAnimation { duration: 120 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    Text {
                                        text: (modelData.name && (modelData.name.includes("head") || modelData.name.includes("WH-") || modelData.name.includes("AirPods"))) ? "\uea76" : "\uea37"
                                        font.family: fontName
                                        font.pixelSize: 14
                                        color: isConn ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.75)
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
                                            text: isConn ? "connected" : "paired • trusted"
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
                                    id: btRowMa
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
                }

                // ═════════════════════════════════════════════════════
                //  TAB 2: HOTSPOT VIEW
                // ═════════════════════════════════════════════════════
                ColumnLayout {
                    visible: netSplitPill.currentTab === 2
                    Layout.fillWidth: true
                    spacing: 12

                    // Active Hotspot Row (Flat & seamless)
                    Item {
                        Layout.fillWidth: true
                        height: 48

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 10

                            Item {
                                width: 24
                                height: 24

                                Text {
                                    anchors.centerIn: parent
                                    text: "\ued1b"
                                    font.family: fontName
                                    font.pixelSize: 18
                                    color: bar.isHotspot
                                           ? Theme.colPrimary
                                           : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: "Personal Hotspot"
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                    color: bar.fg
                                }

                                Text {
                                    text: bar.isHotspot ? (netSplitPill.hsName + " • " + netSplitPill.hsClientList.length + " connected") : "Hotspot Disabled"
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 11
                                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.55)
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            Rectangle {
                                width: 38
                                height: 22
                                radius: 11
                                color: bar.isHotspot ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.15)
                                Behavior on color { ColorAnimation { duration: 200 } }

                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 9
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: bar.isHotspot ? (parent.width - width - 2) : 2
                                    color: "#FFFFFF"
                                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
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

                    // Hotspot Details (Flat & seamless)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Layout.leftMargin: 4
                        Layout.rightMargin: 4

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Network Name"
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
                    }
                }

                // ═════════════════════════════════════════════════════
                //  TAB 0: ETHERNET VIEW
                // ═════════════════════════════════════════════════════
                ColumnLayout {
                    visible: netSplitPill.currentTab === 0
                    Layout.fillWidth: true
                    spacing: 12

                    // Active Ethernet Row (Flat & seamless)
                    Item {
                        Layout.fillWidth: true
                        height: 48

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 10

                            Item {
                                width: 24
                                height: 24

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uebd9"
                                    font.family: fontName
                                    font.pixelSize: 18
                                    color: bar.isWired
                                           ? Theme.colPrimary
                                           : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: "Wired Ethernet"
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                    color: bar.fg
                                }

                                Text {
                                    text: bar.isWired ? ("Connected • " + netSplitPill.wiredIp) : "Cable Disconnected"
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 11
                                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.55)
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                        }
                    }

                    // Ethernet Details Table (Flat & seamless)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Layout.leftMargin: 4
                        Layout.rightMargin: 4

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Interface"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6) }
                            Item { Layout.fillWidth: true }
                            Text { text: netSplitPill.wiredIface; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.DemiBold; color: bar.fg }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "IPv4 Address"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6) }
                            Item { Layout.fillWidth: true }
                            Text { text: netSplitPill.wiredIp || "--"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.DemiBold; color: bar.fg }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Gateway"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6) }
                            Item { Layout.fillWidth: true }
                            Text { text: netSplitPill.wiredGateway || "--"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.DemiBold; color: bar.fg }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Hardware MAC"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6) }
                            Item { Layout.fillWidth: true }
                            Text { text: netSplitPill.wiredMac || "--"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.DemiBold; color: bar.fg }
                        }
                    }
                }

                // ── Subtle Bottom Divider ────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.08)
                }

                // ── Bottom Utility Bar (Settings Link) ───────────────
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: {
                            if (netSplitPill.currentTab === 1) return "Wi-Fi Settings";
                            if (netSplitPill.currentTab === 3) return "Bluetooth Settings";
                            if (netSplitPill.currentTab === 2) return "Hotspot Settings";
                            return "Network Settings";
                        }
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 11
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                    }

                    Item { Layout.fillWidth: true }

                    Item {
                        width: settingsRow.implicitWidth
                        height: 24

                        Row {
                            id: settingsRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                text: "Configure"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: settingsMa.containsMouse ? bar.fg : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "\ueb20"
                                font.family: fontName
                                font.pixelSize: 12
                                color: settingsMa.containsMouse ? bar.fg : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: settingsMa
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
