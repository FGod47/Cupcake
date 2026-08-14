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

    property var wifiList: []
    property var savedWifiList: []
    property var hsClientList: []

    property string wifiSSID: "Disconnected"
    property int wifiSignal: 85
    property string wifiIp: "192.168.1.87"
    property string internetStatus: "Internet Access"
    property bool hasInternet: true

    property string wiredIface: "enp6s0"
    property string wiredIp: "192.168.1.42"

    property string hsName: "Cupcake_AP"
    property string hsPass: "12345678"
    property string hsBand: "2.4 GHz"
    property string hsIp: "10.42.0.1"

    property string selectedSSID: ""
    property string passInputText: ""
    property bool showPassInput: false
    property bool isScanning: false

    function getSignalIcon(sig) {
        let s = parseInt(sig) || 0;
        if (s >= 75) return "\ueb52";
        if (s >= 50) return "\ueba5";
        if (s >= 25) return "\ueba4";
        return "\ueba3";
    }

    onMenuExpandedChanged: {
        if (menuExpanded) {
            statusProc.running = true;
            wifiScanProc.running = true;
            hsProc.running = true;
        } else {
            showPassInput = false;
            passInputText = "";
        }
    }

    readonly property real expandedW: 300
    property real contentW: expandedW

    readonly property real padTop: isAttached ? 22 : 14
    readonly property real padSide: isAttached ? 20 : 14
    readonly property real padBottom: isAttached ? 20 : 14

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
            id: statusProc
            running: netSplitPill.menuExpanded
            command: ["bash", "-c", "nmcli -t -f DEVICE,TYPE,STATE dev; echo '---ip---'; ip -4 addr show; echo '---conn---'; nmcli networking connectivity check"]
            stdout: StdioCollector {
                onStreamFinished: {
                    if (!text) return;
                    let parts = text.split("---ip---");
                    let nmOut = parts[0] || "";
                    let rest = parts[1] || "";
                    let restParts = rest.split("---conn---");
                    let ipOut = restParts[0] || "";
                    let nmConnState = (restParts[1] || "").trim();

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

            // ── Clean Uncluttered Network Layout ─────────────────────
            ColumnLayout {
                id: netContentCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: netSplitPill.padSide
                anchors.rightMargin: netSplitPill.padSide
                anchors.topMargin: netSplitPill.padTop
                spacing: 12

                // ── 1. Top Active Connection Hero Card ─────────────────
                Rectangle {
                    Layout.fillWidth: true
                    height: 56
                    radius: 12
                    color: Qt.rgba(1, 1, 1, 0.06)
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        // Active Icon Badge
                        Rectangle {
                            width: 34
                            height: 34
                            radius: 17
                            color: (bar.isWifi && netSplitPill.wifiSSID !== "Disconnected") || bar.isWired
                                   ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.22)
                                   : Qt.rgba(1, 1, 1, 0.08)
                            border.color: (bar.isWifi && netSplitPill.wifiSSID !== "Disconnected") || bar.isWired
                                          ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.4)
                                          : "transparent"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: bar.isWired ? "\uebd9" : "\ueb52"
                                font.family: fontName
                                font.pixelSize: 16
                                color: (bar.isWifi && netSplitPill.wifiSSID !== "Disconnected") || bar.isWired
                                       ? Theme.colPrimary
                                       : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                            }
                        }

                        // Status Info
                        Column {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: {
                                    if (bar.isWired) return "Wired Connection";
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
                                    if (bar.isWired) return "Connected • " + netSplitPill.wiredIp;
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

                        // Nordic Toggle Switch
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

                // ── 2. Nearby Networks Section Header ──────────────────
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

                    // Refresh / Scan Button
                    Item {
                        width: 20
                        height: 20
                        Text {
                            id: scanIcon
                            anchors.centerIn: parent
                            text: "\ueb13"
                            font.family: fontName
                            font.pixelSize: 13
                            color: scanMa.containsMouse ? bar.fg : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.55)
                            Behavior on color { ColorAnimation { duration: 120 } }
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

                // ── 3. Password Entry Card (When Connecting) ───────────
                Rectangle {
                    visible: netSplitPill.showPassInput && bar.isWifi
                    Layout.fillWidth: true
                    height: 74
                    radius: 10
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.35)
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
                }

                // ── 4. Wi-Fi List Rows ─────────────────────────────────
                ColumnLayout {
                    visible: bar.isWifi
                    Layout.fillWidth: true
                    spacing: 3

                    Repeater {
                        model: netSplitPill.wifiList.slice(0, 5)
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 34
                            radius: 8
                            property bool isConn: modelData.connected
                            color: isConn
                                   ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.15)
                                   : (wifiRowMa.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent")
                            Behavior on color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
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

                            MouseArea {
                                id: wifiRowMa
                                anchors.fill: parent
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

                // ── 5. Subtle Bottom Divider ───────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.08)
                }

                // ── 6. Bottom Actions (Hotspot + Settings) ─────────────
                RowLayout {
                    Layout.fillWidth: true

                    // Hotspot Pill Toggle
                    Rectangle {
                        height: 26
                        width: hsRow.implicitWidth + 16
                        radius: 13
                        color: bar.isHotspot
                               ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.22)
                               : (hsPillMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06))
                        border.color: bar.isHotspot ? Theme.colPrimary : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            id: hsRow
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: "\ued1b"
                                font.family: fontName
                                font.pixelSize: 11
                                color: bar.isHotspot ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Hotspot"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: bar.isHotspot ? Theme.colPrimary : bar.fg
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: hsPillMa
                            anchors.fill: parent
                            hoverEnabled: true
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

                    Item { Layout.fillWidth: true }

                    // Settings Link
                    Item {
                        width: settingsRow.implicitWidth
                        height: 24

                        Row {
                            id: settingsRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                text: "Settings"
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
