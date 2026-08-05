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

    property string wifiSSID: "Disconnected"
    property int wifiSignal: 85
    property string wifiIp: "192.168.1.87"

    property string wiredIp: "192.168.1.42"

    property string btDeviceName: ""
    property int btBattery: 67

    property string hsName: "Pixel_9210_AP"
    property string hsIp: "10.42.0.1"

    onMenuExpandedChanged: {
        if (menuExpanded) {
            statusProc.running = true;
            wifiScanProc.running = true;
            btScanProc.running = true;
        }
    }

    height: menuExpanded ? (netContentCol.implicitHeight + 24) : 30
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

    // Real Status Processor
    Process {
        id: statusProc
        running: netSplitPill.menuExpanded
        command: ["bash", "-c", "nmcli -t -f NAME,TYPE,DEVICE,STATE con show --active; echo '---ip---'; ip -4 addr show; echo '---bt---'; bluetoothctl devices Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                let parts = text.split("---ip---");
                let nmOut = parts[0] || "";
                let rest = parts[1] || "";
                let restParts = rest.split("---bt---");
                let ipOut = restParts[0] || "";
                let btOut = restParts[1] || "";

                // Wi-Fi SSID (excluding Hotspot)
                let lines = nmOut.split('\n');
                let foundWifi = false;
                for (let line of lines) {
                    if (line.includes(":802-11-wireless") && !line.toLowerCase().includes("hotspot")) {
                        netSplitPill.wifiSSID = line.split(':')[0].trim();
                        foundWifi = true;
                        break;
                    }
                }
                if (!foundWifi) netSplitPill.wifiSSID = "Disconnected";

                // IP Addresses
                let ipMatches = ipOut.match(/inet\s+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/g);
                if (ipMatches) {
                    for (let ipStr of ipMatches) {
                        let cleanIp = ipStr.replace("inet ", "").trim();
                        if (cleanIp !== "127.0.0.1") {
                            if (cleanIp.startsWith("10.42.")) netSplitPill.hsIp = cleanIp;
                            else if (cleanIp.startsWith("192.168.")) {
                                netSplitPill.wifiIp = cleanIp;
                                netSplitPill.wiredIp = cleanIp;
                            }
                        }
                    }
                }

                // Bluetooth Connected Device
                let btMatch = btOut.match(/Device\s+([0-9A-Fa-f:]+)\s+(.+)/);
                if (btMatch) {
                    netSplitPill.btDeviceName = btMatch[1].trim();
                } else {
                    netSplitPill.btDeviceName = "";
                }
            }
        }
    }

    Timer {
        interval: 3000
        running: netSplitPill.menuExpanded
        repeat: true
        onTriggered: statusProc.running = true
    }

    // Scanners
    Process {
        id: wifiScanProc
        command: ["bash", "-c", "nmcli -t -f SSID,SIGNAL,SECURITY,IN-USE dev wifi list"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                let lines = text.trim().split('\n');
                let res = [];
                let seen = new Set();
                for (let l of lines) {
                    let parts = l.split(':');
                    if (parts.length >= 4 && parts[0].trim() !== "") {
                        let ssid = parts[0].trim();
                        let sig = parseInt(parts[1]) || 0;
                        if (parts[3].includes("*")) netSplitPill.wifiSignal = sig;
                        if (!seen.has(ssid)) {
                            seen.add(ssid);
                            res.push({
                                ssid: ssid,
                                signal: sig,
                                security: parts[2] || "Open",
                                connected: parts[3].includes("*")
                            });
                        }
                    }
                }
                netSplitPill.wifiList = res;
            }
        }
    }

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
        Text { visible: isWifi && !isWired && !isHotspot; text: "\ueb52"; font.family: fontName; font.pixelSize: 15; color: fg; anchors.verticalCenter: parent.verticalCenter }
        Text { visible: isWifi || isWired || isBluetooth || isHotspot; text: "•"; font.family: Theme.defaultFontFamily; font.pixelSize: 15; font.weight: Theme.defaultFontWeight; color: Qt.rgba(fg.r, fg.g, fg.b, 0.4); anchors.verticalCenter: parent.verticalCenter }
        Text { text: netStr; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Theme.defaultFontWeight; color: Qt.rgba(fg.r, fg.g, fg.b, 0.7); anchors.verticalCenter: parent.verticalCenter }
    }

    // Expanded View Dashboard
    ColumnLayout {
        id: netContentCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 12
        opacity: netSplitPill.menuExpanded ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 250 } }

        // ── 1. Top Segmented Tab Bar ──
        Rectangle {
            Layout.fillWidth: true
            height: 40
            radius: 20
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
                            radius: 17
                            color: activeTab === modelData.tabIndex ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.25) : "transparent"
                            border.color: activeTab === modelData.tabIndex ? Theme.colPrimary : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.family: fontName
                                font.pixelSize: 16
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
            width: 140
            height: 140

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
                    let radius = 60;
                    let startAngle = -Math.PI / 2;
                    let endAngle = startAngle + (percentage * 2 * Math.PI);

                    ctx.beginPath();
                    ctx.arc(cx, cy, radius, 0, 2 * Math.PI);
                    ctx.lineWidth = 8;
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08);
                    ctx.stroke();

                    if (percentage > 0) {
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, startAngle, endAngle);
                        ctx.lineWidth = 8;
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
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.2)
                    Text { anchors.centerIn: parent; text: "\uecea"; font.family: fontName; font.pixelSize: 14; color: Theme.colPrimary }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: btBattery + "%"
                    font.family: Theme.defaultFontFamily; font.pixelSize: 18; font.weight: Font.Bold; color: bar.fg
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Battery"
                    font.family: Theme.defaultFontFamily; font.pixelSize: 10; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                }
            }
        }

        // ── 3. Connection Title + Icon + Enable Switch Header Row ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 34; height: 34; radius: 17
                color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.18)
                border.color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.3)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: activeTab === 0 ? "\uebd9" : (activeTab === 1 ? "\ueb52" : (activeTab === 2 ? "\ued1b" : "\uea37"))
                    font.family: fontName; font.pixelSize: 16
                    color: Theme.colPrimary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true; spacing: 1
                Text {
                    text: activeTab === 0 ? "Wired" : (activeTab === 1 ? (wifiSSID !== "Disconnected" ? wifiSSID : "Wi-Fi") : (activeTab === 2 ? "Hotspot" : (btDeviceName !== "" ? btDeviceName : "Bluetooth")))
                    font.family: Theme.defaultFontFamily; font.pixelSize: 14; font.weight: Font.Bold; color: bar.fg
                }
                Text {
                    text: activeTab === 0 ? (wiredIp + " · " + netStr) : (activeTab === 1 ? (wifiIp + " · " + netStr) : (activeTab === 2 ? (hsIp + " · 0 devices") : (btDeviceName !== "" ? ("Connected · " + btBattery + "% battery") : "Disabled")))
                    font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                }
            }

            // Enable Toggle Switch right at the Name side!
            Rectangle {
                width: 44; height: 24; radius: 12
                color: (activeTab === 0 ? isWired : (activeTab === 1 ? isWifi : (activeTab === 2 ? isHotspot : isBluetooth))) ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.15)
                Behavior on color { ColorAnimation { duration: 200 } }

                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (activeTab === 0) bar.isWired = !bar.isWired;
                        else if (activeTab === 1) {
                            bar.isWifi = !bar.isWifi;
                            Quickshell.execDetached(["bash", "-c", "if [ \"$(nmcli radio wifi)\" = \"enabled\" ]; then nmcli radio wifi off; else nmcli radio wifi on; fi"]);
                        } else if (activeTab === 2) {
                            bar.isHotspot = !bar.isHotspot;
                            Quickshell.execDetached(["bash", "-c", "if nmcli con show --active | grep -qi hotspot; then nmcli con down Hotspot; else nmcli con up Hotspot; fi"]);
                        } else if (activeTab === 3) {
                            bar.isBluetooth = !bar.isBluetooth;
                            Quickshell.execDetached(["bash", "-c", "if rfkill list bluetooth | grep -q 'Soft blocked: yes'; then rfkill unblock bluetooth; bluetoothctl power on; else rfkill block bluetooth; bluetoothctl power off; fi"]);
                        }
                    }
                }

                Rectangle {
                    width: 18; height: 18; radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    x: (activeTab === 0 ? isWired : (activeTab === 1 ? isWifi : (activeTab === 2 ? isHotspot : isBluetooth))) ? 23 : 3
                    color: (activeTab === 0 ? isWired : (activeTab === 1 ? isWifi : (activeTab === 2 ? isHotspot : isBluetooth))) ? Theme.colOnPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                    Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }
            }
        }

        // ── 4. Dual Stat Cards (Show ONLY on the active internet connection tab) ──
        RowLayout {
            visible: (activeTab === 0 && isWired) || (activeTab === 1 && isWifi && wifiSSID !== "Disconnected") || (activeTab === 2 && isHotspot)
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true; height: 54; radius: 12
                color: Qt.rgba(1, 1, 1, 0.04); border.color: Qt.rgba(1, 1, 1, 0.08); border.width: 1
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 8; spacing: 1
                    Text { text: "DOWNLOAD"; font.family: Theme.defaultFontFamily; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 0.5; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5) }
                    Text { text: (typeof bar.netRxStr !== "undefined" && bar.netRxStr !== "") ? bar.netRxStr : netStr; font.family: Theme.defaultFontFamily; font.pixelSize: 14; font.weight: Font.Bold; color: bar.fg }
                }
            }

            Rectangle {
                Layout.fillWidth: true; height: 54; radius: 12
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
            spacing: 6

            // Tab 0: Wired
            Text {
                visible: activeTab === 0
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6; Layout.bottomMargin: 6
                text: "No additional devices or networks nearby"
                font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.4)
            }

            // Tab 1: Wi-Fi Networks
            Repeater {
                model: activeTab === 1 ? (netSplitPill.wifiList.length > 0 ? netSplitPill.wifiList : [{ssid: "Home-5G", connected: true, security: "WPA2"}, {ssid: "Neighbor_2.4G", connected: false, security: "WPA2"}, {ssid: "Pixel_9210", connected: false, security: "WPA2"}]) : []
                delegate: Rectangle {
                    Layout.fillWidth: true; height: 36; radius: 10
                    color: modelData.connected ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.22) : (wifiItemMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03))
                    border.color: modelData.connected ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.06); border.width: 1

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
                        Text { text: "\ueb52"; font.family: fontName; font.pixelSize: 14; color: modelData.connected ? Theme.colPrimary : bar.fg }
                        Text { Layout.fillWidth: true; text: modelData.ssid; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: modelData.connected ? Font.Bold : Font.Normal; color: modelData.connected ? Theme.colPrimary : bar.fg; elide: Text.ElideRight }
                        Text { text: modelData.security !== "Open" ? "\ueae2" : ""; font.family: fontName; font.pixelSize: 12; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5); visible: text !== "" }
                        Text { text: "\uea5e"; font.family: fontName; font.pixelSize: 14; color: Theme.colPrimary; visible: modelData.connected }
                    }

                    MouseArea {
                        id: wifiItemMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { Quickshell.execDetached(["bash", "-c", "nmcli dev wifi connect \"" + modelData.ssid + "\""]); wifiScanProc.running = true; }
                    }
                }
            }

            // Tab 2: Hotspot
            Text {
                visible: activeTab === 2
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6; Layout.bottomMargin: 6
                text: "No additional devices or networks nearby"
                font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.4)
            }

            // Tab 3: Bluetooth
            Repeater {
                model: activeTab === 3 ? (netSplitPill.btList.length > 0 ? netSplitPill.btList : [{name: "Galaxy Buds", connected: true, mac: "00:11:22", battery: "67%"}, {name: "Pixel Watch", connected: false, mac: "33:44:55", battery: "Paired"}]) : []
                delegate: Rectangle {
                    Layout.fillWidth: true; height: 36; radius: 10
                    color: modelData.connected ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.22) : (btItemMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03))
                    border.color: modelData.connected ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.06); border.width: 1

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
                        Text { Layout.fillWidth: true; text: modelData.name; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: modelData.connected ? Font.Bold : Font.Normal; color: modelData.connected ? Theme.colPrimary : bar.fg; elide: Text.ElideRight }
                        Text { text: modelData.connected ? (modelData.battery || "67%") : "Paired"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5) }
                        Text { text: "\uea5e"; font.family: fontName; font.pixelSize: 14; color: Theme.colPrimary; visible: modelData.connected }
                    }

                    MouseArea {
                        id: btItemMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { Quickshell.execDetached(["bash", "-c", modelData.connected ? ("bluetoothctl disconnect " + modelData.mac) : ("bluetoothctl connect " + modelData.mac)]); btScanProc.running = true; }
                    }
                }
            }
        }
    }
}
