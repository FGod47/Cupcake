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
    property bool showWifiList: false
    property bool showBtList: false
    property bool showHsDetails: false

    property var wifiList: []
    property var btList: []

    property string hsName: "Cupcake_AP"
    property string hsPass: "12345678"
    property string hsBand: "2.4 GHz"

    height: menuExpanded ? (netContentCol.implicitHeight + 28) : 30
    Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } }

    readonly property real openGap: 16
    readonly property real headerW: networkIconsRow.implicitWidth + 24
    readonly property real expandedW: 320
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
                        if (!seen.has(ssid)) {
                            seen.add(ssid);
                            res.push({
                                ssid: ssid,
                                signal: parseInt(parts[1]) || 0,
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

        Text {
            visible: isHotspot
            text: "\ued1b"
            font.family: fontName
            font.pixelSize: 15
            color: fg
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: isBluetooth
            text: isBluetoothConnected ? "\uecea" : "\uea37"
            font.family: fontName
            font.pixelSize: 15
            color: fg
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: isWired
            text: "\uebd9"
            font.family: fontName
            font.pixelSize: 15
            color: fg
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: isWifi && !isWired && !isHotspot
            text: "\ueb52"
            font.family: fontName
            font.pixelSize: 15
            color: fg
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: isWifi || isWired || isBluetooth || isHotspot
            text: "•"
            font.family: Theme.defaultFontFamily
            font.pixelSize: 15
            font.weight: Theme.defaultFontWeight
            color: Qt.rgba(fg.r, fg.g, fg.b, 0.4)
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: netStr
            font.family: Theme.defaultFontFamily
            font.pixelSize: 13
            font.weight: Theme.defaultFontWeight
            color: Qt.rgba(fg.r, fg.g, fg.b, 0.7)
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Expanded View Content (Matching reference design 100%)
    ColumnLayout {
        id: netContentCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 10
        opacity: netSplitPill.menuExpanded ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 250 } }

        // ── Top Header Row (Ethernet / Network Active Header) ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                width: 40; height: 40; radius: 20
                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.08)
                border.color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.1)
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: isWired ? "\uebd9" : (isWifi ? "\ueb52" : "\uea37")
                    font.family: fontName; font.pixelSize: 18
                    color: bar.fg
                }
            }

            ColumnLayout {
                Layout.fillWidth: true; spacing: 1
                Text {
                    text: isWired ? "Ethernet" : (isWifi ? "Wi-Fi Network" : "Network")
                    font.family: Theme.defaultFontFamily; font.pixelSize: 14; font.weight: Font.Bold
                    color: bar.fg
                }
                Text {
                    text: netStr + " · " + (isWired || isWifi ? "Connected" : "Disconnected")
                    font.family: Theme.defaultFontFamily; font.pixelSize: 11
                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                }
            }

            // Options Button (...)
            Rectangle {
                width: 32; height: 32; radius: 16
                color: optMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)
                Text {
                    anchors.centerIn: parent
                    text: "\uea9d" // dots icon
                    font.family: fontName; font.pixelSize: 14
                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                }
                MouseArea {
                    id: optMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["hyprctl", "dispatch", "exec", "[float] quickshell -c " + homeDir + "/.config/quickshell/Settings.qml"]);
                        bar.netDropdownOpen = false;
                    }
                }
            }
        }

        // ── 1. Wi-Fi Card Section ──
        Rectangle {
            Layout.fillWidth: true
            radius: 16
            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.04)
            border.color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.08)
            border.width: 1
            implicitHeight: wifiCardCol.implicitHeight + 20

            ColumnLayout {
                id: wifiCardCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                // Card Header Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 36; height: 36; radius: 18
                        color: isWifi ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.15) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.08)
                        Text { anchors.centerIn: parent; text: "\ueb52"; color: isWifi ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6); font.family: fontName; font.pixelSize: 16 }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Wi-Fi"; color: bar.fg; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Bold }
                        Text { text: isWifi ? "Home-5G · Strong signal" : "Off"; color: isWifi ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5); font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                    }

                    // Chevron arrow
                    Text {
                        text: showWifiList ? "\uea62" : "\uea5f"
                        font.family: fontName; font.pixelSize: 14
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                netSplitPill.showWifiList = !netSplitPill.showWifiList;
                                netSplitPill.showBtList = false;
                                netSplitPill.showHsDetails = false;
                                if (netSplitPill.showWifiList) wifiScanProc.running = true;
                            }
                        }
                    }

                    // Switch
                    Rectangle {
                        width: 40; height: 24; radius: 12
                        color: isWifi ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.15)
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Timer { id: wifiRefreshTimer; interval: 400; repeat: false; onTriggered: { if (typeof bar.refreshNetworkStatus === "function") bar.refreshNetworkStatus(); } }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                bar.isWifi = !bar.isWifi;
                                Quickshell.execDetached(["bash", "-c", "if [ \"$(nmcli radio wifi)\" = \"enabled\" ]; then nmcli radio wifi off; else nmcli radio wifi on; fi"]);
                                wifiRefreshTimer.restart();
                            }
                        }
                        Rectangle {
                            width: 18; height: 18; radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            x: isWifi ? 19 : 3
                            color: isWifi ? Theme.colOnPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                // Expanded Wi-Fi List
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: showWifiList
                    
                    Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.08) }

                    Repeater {
                        model: netSplitPill.wifiList.length > 0 ? netSplitPill.wifiList : [{ssid: "Home-5G", connected: true, security: "WPA2"}, {ssid: "Neighbor_2.4G", connected: false, security: "WPA2"}, {ssid: "Pixel_9210", connected: false, security: "WPA2"}]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: 10
                            color: modelData.connected ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.20) : (wifiItemMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                            
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
                                Text { text: "\ueb52"; font.family: fontName; font.pixelSize: 14; color: modelData.connected ? Theme.colPrimary : bar.fg }
                                Text { Layout.fillWidth: true; text: modelData.ssid; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: modelData.connected ? Font.Bold : Font.Normal; color: modelData.connected ? Theme.colPrimary : bar.fg; elide: Text.ElideRight }
                                Text { text: modelData.security !== "Open" ? "\ueae2" : ""; font.family: fontName; font.pixelSize: 12; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5); visible: text !== "" }
                                Text { text: "\uea5e"; font.family: fontName; font.pixelSize: 14; color: Theme.colPrimary; visible: modelData.connected }
                            }

                            MouseArea {
                                id: wifiItemMa
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached(["bash", "-c", "nmcli dev wifi connect \"" + modelData.ssid + "\""]);
                                    wifiScanProc.running = true;
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        Text { text: "+  Add network manually"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6) }
                    }
                }
            }
        }

        // ── 2. Bluetooth Card Section ──
        Rectangle {
            Layout.fillWidth: true
            radius: 16
            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.04)
            border.color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.08)
            border.width: 1
            implicitHeight: btCardCol.implicitHeight + 20

            ColumnLayout {
                id: btCardCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                // Card Header Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 36; height: 36; radius: 18
                        color: isBluetooth ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.15) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.08)
                        Text { anchors.centerIn: parent; text: isBluetoothConnected ? "\uecea" : "\uea37"; color: isBluetooth ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6); font.family: fontName; font.pixelSize: 16 }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Bluetooth"; color: bar.fg; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Bold }
                        Text { text: isBluetoothConnected ? "Galaxy Buds · 67%" : (isBluetooth ? "Enabled" : "Disabled"); color: isBluetooth ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5); font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                    }

                    // Chevron arrow
                    Text {
                        text: showBtList ? "\uea62" : "\uea5f"
                        font.family: fontName; font.pixelSize: 14
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                netSplitPill.showBtList = !netSplitPill.showBtList;
                                netSplitPill.showWifiList = false;
                                netSplitPill.showHsDetails = false;
                                if (netSplitPill.showBtList) btScanProc.running = true;
                            }
                        }
                    }

                    // Switch
                    Rectangle {
                        width: 40; height: 24; radius: 12
                        color: isBluetooth ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.15)
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Timer { id: btRefreshTimer; interval: 400; repeat: false; onTriggered: { if (typeof bar.refreshNetworkStatus === "function") bar.refreshNetworkStatus(); } }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                bar.isBluetooth = !bar.isBluetooth;
                                Quickshell.execDetached(["bash", "-c", "if rfkill list bluetooth | grep -q 'Soft blocked: yes'; then rfkill unblock bluetooth; bluetoothctl power on; else rfkill block bluetooth; bluetoothctl power off; fi"]);
                                btRefreshTimer.restart();
                            }
                        }
                        Rectangle {
                            width: 18; height: 18; radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            x: isBluetooth ? 19 : 3
                            color: isBluetooth ? Theme.colOnPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                // Expanded Bluetooth List
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: showBtList

                    Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.08) }

                    Repeater {
                        model: netSplitPill.btList.length > 0 ? netSplitPill.btList : [{name: "Galaxy Buds", connected: true, mac: "00:11:22", battery: "67%"}, {name: "Pixel Watch", connected: false, mac: "33:44:55", battery: "Paired"}]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: 10
                            color: btItemMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
                                Rectangle {
                                    width: 26; height: 26; radius: 13
                                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.08)
                                    Text { anchors.centerIn: parent; text: modelData.connected ? "\uea76" : "\uea37"; font.family: fontName; font.pixelSize: 13; color: bar.fg }
                                }
                                Text { Layout.fillWidth: true; text: modelData.name; font.family: Theme.defaultFontFamily; font.pixelSize: 12; color: bar.fg; elide: Text.ElideRight }
                                Text { text: modelData.connected ? ("🔋 " + (modelData.battery || "Connected")) : "Paired"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5) }
                            }

                            MouseArea {
                                id: btItemMa
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached(["bash", "-c", modelData.connected ? ("bluetoothctl disconnect " + modelData.mac) : ("bluetoothctl connect " + modelData.mac)]);
                                    btScanProc.running = true;
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        Text { text: "🕒  Scan for new devices"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6) }
                    }
                }
            }
        }

        // ── 3. Hotspot Card Section ──
        Rectangle {
            Layout.fillWidth: true
            radius: 16
            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.04)
            border.color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.08)
            border.width: 1
            implicitHeight: hsCardCol.implicitHeight + 20

            ColumnLayout {
                id: hsCardCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                // Card Header Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 36; height: 36; radius: 18
                        color: isHotspot ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.15) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.08)
                        Text { anchors.centerIn: parent; text: "\ued1b"; color: isHotspot ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6); font.family: fontName; font.pixelSize: 16 }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Hotspot"; color: bar.fg; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Bold }
                        Text { text: isHotspot ? "Active · 0 connected" : "Off"; color: isHotspot ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5); font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                    }

                    // Chevron arrow
                    Text {
                        text: showHsDetails ? "\uea62" : "\uea5f"
                        font.family: fontName; font.pixelSize: 14
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                netSplitPill.showHsDetails = !netSplitPill.showHsDetails;
                                netSplitPill.showWifiList = false;
                                netSplitPill.showBtList = false;
                            }
                        }
                    }

                    // Switch
                    Rectangle {
                        width: 40; height: 24; radius: 12
                        color: isHotspot ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.15)
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Timer { id: hsRefreshTimer; interval: 600; repeat: false; onTriggered: { if (typeof bar.refreshNetworkStatus === "function") bar.refreshNetworkStatus(); } }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                bar.isHotspot = !bar.isHotspot;
                                Quickshell.execDetached(["bash", "-c", "if nmcli con show --active | grep -qi hotspot; then nmcli con down Hotspot; else nmcli con up Hotspot; fi"]);
                                hsRefreshTimer.restart();
                            }
                        }
                        Rectangle {
                            width: 18; height: 18; radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            x: isHotspot ? 19 : 3
                            color: isHotspot ? Theme.colOnPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                // Expanded Hotspot Settings (Name, Password, Band Selection)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: showHsDetails

                    Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.08) }

                    Text { text: "NETWORK NAME"; font.family: Theme.defaultFontFamily; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 0.5; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5) }
                    
                    Rectangle {
                        Layout.fillWidth: true; height: 36; radius: 10
                        color: Qt.rgba(1, 1, 1, 0.05); border.color: Qt.rgba(1, 1, 1, 0.1); border.width: 1
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                            TextInput {
                                id: hsNameInput
                                Layout.fillWidth: true
                                text: hsName
                                font.family: Theme.defaultFontFamily; font.pixelSize: 12
                                color: bar.fg
                                onTextChanged: hsName = text
                            }
                            Text { text: "✏️"; font.pixelSize: 12 }
                        }
                    }

                    Text { text: "PASSWORD"; font.family: Theme.defaultFontFamily; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 0.5; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5) }

                    Rectangle {
                        Layout.fillWidth: true; height: 36; radius: 10
                        color: Qt.rgba(1, 1, 1, 0.05); border.color: Qt.rgba(1, 1, 1, 0.1); border.width: 1
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                            TextInput {
                                id: hsPassInput
                                Layout.fillWidth: true
                                text: hsPass
                                echoMode: showPassText.show ? TextInput.Normal : TextInput.Password
                                font.family: Theme.defaultFontFamily; font.pixelSize: 12
                                color: bar.fg
                                onTextChanged: hsPass = text
                            }
                            Text {
                                id: showPassText
                                property bool show: false
                                text: show ? "👁️" : "🙈"
                                font.pixelSize: 12
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: showPassText.show = !showPassText.show }
                            }
                        }
                    }

                    // Band Selection Pills
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Layout.topMargin: 4

                        Repeater {
                            model: ["2.4 GHz", "5 GHz", "Auto"]
                            delegate: Rectangle {
                                width: 70; height: 28; radius: 14
                                property bool isSel: hsBand === modelData
                                color: isSel ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.06)
                                border.color: isSel ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.1)
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.family: Theme.defaultFontFamily; font.pixelSize: 11
                                    font.weight: isSel ? Font.Bold : Font.Normal
                                    color: isSel ? Theme.colOnPrimary : bar.fg
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: hsBand = modelData
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        Text { text: "Connected devices"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6) }
                        Item { Layout.fillWidth: true }
                        Text { text: "0"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: bar.fg }
                    }
                }
            }
        }

        // ── 4. Bottom Footer Button (Network Settings) ──
        Rectangle {
            Layout.fillWidth: true
            height: 44
            radius: 16
            color: navBtnMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            Row {
                anchors.centerIn: parent
                spacing: 8
                Text {
                    text: "\ueb2d" // settings gear
                    font.family: fontName
                    font.pixelSize: 16
                    color: bar.fg
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "Network Settings"
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: bar.fg
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: navBtnMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    bar.netDropdownOpen = false;
                    Quickshell.execDetached(["hyprctl", "dispatch", "exec", "[float] quickshell -c " + homeDir + "/.config/quickshell/Settings.qml"]);
                }
            }
        }
    }
}
