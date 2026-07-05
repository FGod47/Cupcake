import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "theme"
import Quickshell
import Quickshell.Io

Item {
    id: root

    // =========================================================
    // Inline components
    // =========================================================

    component SettingsCard: Rectangle {
        default property alias content: innerCol.data
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        implicitHeight: innerCol.implicitHeight + 32
        Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
        radius: 14
        clip: true
        ColumnLayout {
            id: innerCol
            anchors.fill: parent
            anchors.margins: 20
            spacing: 0
        }
    }

    component ToggleSwitch: Rectangle {
        id: sw
        property bool checked: false
        signal toggled(bool checked)
        width: 44; height: 26
        radius: height / 2
        color: checked ? "#4ade80" : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.18)
        Behavior on color { ColorAnimation { duration: 150 } }
        Rectangle {
            width: 22; height: 22; radius: 11
            anchors.verticalCenter: parent.verticalCenter
            x: sw.checked ? parent.width - width - 2 : 2
            color: "white"
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: { sw.checked = !sw.checked; sw.toggled(sw.checked) }
        }
    }

    component SectionLabel: Text {
        Layout.fillWidth: true
        Layout.topMargin: 12
        Layout.bottomMargin: 6
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 1.0
        color: Theme.colOnSurfaceVariant
        opacity: 0.55
    }

    component Divider: Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: 52
        height: 1
        color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.08)
    }

    component StatusBadge: Rectangle {
        property string label: "Connected"
        property color badgeColor: Qt.rgba(0.29, 0.86, 0.50, 0.18)
        property color textColor: "#4ade80"
        radius: 6
        width: badgeText.implicitWidth + 16
        height: 26
        color: badgeColor
        Text {
            id: badgeText
            anchors.centerIn: parent
            text: parent.label
            color: parent.textColor
            font.family: Theme.defaultFontFamily
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }

    // =========================================================
    // Background data processes
    // =========================================================

    ListModel { id: wifiModel }
    ListModel { id: btPairedModel }
    ListModel { id: btNearbyModel }

    Process {
        id: wifiProcess
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
        running: true
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                wifiModel.clear();
                const textStr = text.trim();
                if (textStr === "") return;
                const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const rep  = new RegExp("\\\\:", "g");
                const rep2 = new RegExp(PLACEHOLDER, "g");
                const lines = textStr.split("\n");
                let seen = {};
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];
                    if (line === "") continue;
                    const net      = line.replace(rep, PLACEHOLDER).split(":");
                    const inUse    = net[0] === "yes";
                    const signal   = parseInt(net[1]) || 0;
                    const ssid     = net[3] ? net[3].replace(rep2, ":") : "";
                    const security = net[5] ? net[5].replace(rep2, ":") : "";
                    const isSecure = security.length > 0 && security !== "--";
                    if (ssid === "" || ssid === "--") continue;
                    if (seen[ssid]) continue;
                    seen[ssid] = true;
                    wifiModel.append({ ssid, inUse, isSecure, security, signal, expanded: false, password: "" });
                }
            }
        }
    }

    Process {
        id: ethernetProcess
        command: ["nmcli", "-g", "DEVICE,TYPE,STATE,CONNECTION,IP4.ADDRESS", "dev"]
        running: true
        environment: ({ LANG: "C", LC_ALL: "C" })
        property string ethernetName: ""
        property string ethernetIp: ""
        property bool ethernetConnected: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].split(":");
                    if (parts[1] === "ethernet") {
                        ethernetProcess.ethernetConnected = parts[2] === "connected";
                        ethernetProcess.ethernetName = parts[3] || "Wired connection";
                    }
                }
            }
        }
    }

    // =========================================================
    // UI
    // =========================================================

    ScrollView {
        anchors.fill: parent
        anchors.bottomMargin: 30
        anchors.rightMargin: 24
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 20

            // ── Wi-Fi ─────────────────────────────────────────────
            SettingsCard {
                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 8
                    spacing: 10
                    Text { text: "\ueb52"; color: Theme.colOnSurface; font.family: "tabler-icons"; font.pixelSize: 20 }
                    Text { text: "Wi-Fi"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 15; font.weight: Font.Bold; Layout.fillWidth: true }
                    ToggleSwitch {
                        id: wifiSwitch
                        checked: true
                        onToggled: Quickshell.execDetached(["nmcli", "radio", "wifi", checked ? "on" : "off"])
                    }
                }

                // Connected section
                SectionLabel { text: "CONNECTED"; visible: wifiModel.count > 0 }

                Repeater {
                    model: wifiModel
                    delegate: Loader {
                        active: model.inUse
                        Layout.fillWidth: true
                        sourceComponent: ColumnLayout {
                            spacing: 0

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 4; Layout.bottomMargin: 4
                                spacing: 12

                                Rectangle {
                                    width: 36; height: 36; radius: 10
                                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.06)
                                    Text { anchors.centerIn: parent; text: "\ueb52"; color: Theme.colPrimary; font.family: "tabler-icons"; font.pixelSize: 17 }
                                }

                                ColumnLayout {
                                    spacing: 1
                                    Text { text: model.ssid; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.SemiBold }
                                    Text { text: "Connected · Secured"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.7 }
                                }

                                Item { Layout.fillWidth: true }

                                StatusBadge { label: "Strong" }

                                Text { text: "\ueb04"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.5 }
                                Text { text: "\uea62"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.4 }
                            }
                        }
                    }
                }

                // Other Networks section
                SectionLabel { text: "OTHER NETWORKS" }

                Repeater {
                    model: wifiModel
                    delegate: Loader {
                        active: !model.inUse
                        Layout.fillWidth: true
                        sourceComponent: ColumnLayout {
                            spacing: 0

                            Divider { visible: index > 0 }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 6; Layout.bottomMargin: 6
                                spacing: 12

                                Rectangle {
                                    width: 36; height: 36; radius: 10
                                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                                    Text {
                                        anchors.centerIn: parent
                                        text: model.signal > 0 ? "\ueb52" : "\ueb53"
                                        color: Theme.colOnSurfaceVariant
                                        font.family: "tabler-icons"; font.pixelSize: 17
                                    }
                                }

                                ColumnLayout {
                                    spacing: 1
                                    Text { text: model.ssid; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                                    Text {
                                        text: model.isSecure ? "Secured" : "Open network"
                                        color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.7
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Text { visible: model.isSecure; text: "\ueb04"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.45 }
                                Text { text: "\uea62"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.35 }
                            }

                            // Expanded password row
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.bottomMargin: 6
                                spacing: 8
                                visible: model.expanded

                                Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: 36
                                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                                    radius: 8
                                    border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15); border.width: 1
                                    TextInput {
                                        id: pwdInput2
                                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 12
                                        echoMode: TextInput.Password; clip: true
                                        onTextChanged: wifiModel.setProperty(index, "password", text)
                                    }
                                    Text {
                                        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                                        text: "Wi-Fi password..."; color: Theme.colOnSurfaceVariant
                                        font.family: Theme.defaultFontFamily; font.pixelSize: 12; opacity: 0.5
                                        visible: pwdInput2.text === ""
                                    }
                                }

                                Rectangle {
                                    width: 80; height: 36; radius: 8
                                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.9)
                                    Text { anchors.centerIn: parent; text: "Connect"; color: Theme.colSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.Medium }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (model.isSecure)
                                                Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", model.ssid, "password", model.password]);
                                            else
                                                Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", model.ssid]);
                                            wifiModel.setProperty(index, "expanded", false);
                                            wifiProcess.running = true;
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                width: parent.width; height: 48
                                cursorShape: Qt.PointingHandCursor
                                enabled: !model.expanded
                                onClicked: {
                                    for (let i = 0; i < wifiModel.count; i++)
                                        wifiModel.setProperty(i, "expanded", false);
                                    if (!model.isSecure) {
                                        Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", model.ssid]);
                                        wifiProcess.running = true;
                                    } else {
                                        wifiModel.setProperty(index, "expanded", true);
                                    }
                                }
                            }
                        }
                    }
                }

                // Add network manually link
                Text {
                    Layout.topMargin: 12
                    text: "+ Add network manually"
                    color: Theme.colPrimary
                    font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium
                    opacity: 0.9
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                }
            }

            // ── Bluetooth ─────────────────────────────────────────
            SettingsCard {
                property bool btEnabled: true

                RowLayout {
                    Layout.fillWidth: true; Layout.bottomMargin: 8; spacing: 10
                    Text { text: "\uea37"; color: Theme.colOnSurface; font.family: "tabler-icons"; font.pixelSize: 20 }
                    Text { text: "Bluetooth"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 15; font.weight: Font.Bold; Layout.fillWidth: true }
                    ToggleSwitch {
                        id: btSwitch; checked: true
                        onToggled: Quickshell.execDetached(["bluetoothctl", checked ? "power on" : "power off"])
                    }
                }

                SectionLabel { text: "MY DEVICES" }

                // Sony headphones
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0
                    RowLayout {
                        Layout.fillWidth: true; Layout.topMargin: 4; Layout.bottomMargin: 4; spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\uea64"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout { spacing: 1
                            Text { text: "Sony WH-1000XM5"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.SemiBold }
                            Text { text: "Connected · Battery 82%"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.7 }
                        }
                        Item { Layout.fillWidth: true }
                        StatusBadge { label: "Connected" }
                        Text { text: "\uea62"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.4 }
                    }
                }

                Divider {}

                // MX Keys
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0
                    RowLayout {
                        Layout.fillWidth: true; Layout.topMargin: 4; Layout.bottomMargin: 4; spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\uead3"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout { spacing: 1
                            Text { text: "MX Keys"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.SemiBold }
                            Text { text: "Paired · Not connected"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.7 }
                        }
                        Item { Layout.fillWidth: true }
                        StatusBadge { label: "Paired"; badgeColor: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08); textColor: Theme.colOnSurfaceVariant }
                        Text { text: "\uea62"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.4 }
                    }
                }

                SectionLabel { text: "NEARBY DEVICES"; Layout.topMargin: 16 }

                // MX Master 3S
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0
                    RowLayout {
                        Layout.fillWidth: true; Layout.topMargin: 4; Layout.bottomMargin: 4; spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\uead0"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout { spacing: 1
                            Text { text: "MX Master 3S"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Available"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.7 }
                        }
                        Item { Layout.fillWidth: true }
                        Text { text: "Pair"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                        Text { text: "\uea62"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.4 }
                    }
                }

                Divider {}

                // DualSense
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0
                    RowLayout {
                        Layout.fillWidth: true; Layout.topMargin: 4; Layout.bottomMargin: 4; spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\uebce"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout { spacing: 1
                            Text { text: "DualSense Controller"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Available"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.7 }
                        }
                        Item { Layout.fillWidth: true }
                        Text { text: "Pair"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                        Text { text: "\uea62"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.4 }
                    }
                }
            }

            // ── Ethernet ──────────────────────────────────────────
            SettingsCard {
                RowLayout {
                    Layout.fillWidth: true; Layout.bottomMargin: 8; spacing: 10
                    Text { text: "\uebb3"; color: Theme.colOnSurface; font.family: "tabler-icons"; font.pixelSize: 20 }
                    Text { text: "Ethernet"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 15; font.weight: Font.Bold; Layout.fillWidth: true }
                }

                RowLayout {
                    Layout.fillWidth: true; Layout.topMargin: 4; Layout.bottomMargin: 4; spacing: 12
                    Rectangle {
                        width: 36; height: 36; radius: 10
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                        Text { anchors.centerIn: parent; text: "\uebb3"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 17 }
                    }
                    ColumnLayout { spacing: 1
                        Text { text: "Wired connection"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.SemiBold }
                        Text { text: "Connected · 1 Gbps · 192.168.1.42"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.7 }
                    }
                    Item { Layout.fillWidth: true }
                    StatusBadge { label: "Connected" }
                }

                Divider { Layout.leftMargin: 0 }

                RowLayout {
                    Layout.fillWidth: true; Layout.topMargin: 8; Layout.bottomMargin: 4; spacing: 12
                    Rectangle {
                        width: 36; height: 36; radius: 10
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                        Text { anchors.centerIn: parent; text: "\ueb38"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 17 }
                    }
                    ColumnLayout { spacing: 1
                        Text { text: "Connect automatically"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                        Text { text: "Use this connection whenever a cable is plugged in"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.7 }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch { checked: true }
                }
            }

            // ── VPN ───────────────────────────────────────────────
            SettingsCard {
                RowLayout {
                    Layout.fillWidth: true; Layout.bottomMargin: 8; spacing: 10
                    Text { text: "\ueb61"; color: Theme.colOnSurface; font.family: "tabler-icons"; font.pixelSize: 20 }
                    Text { text: "VPN"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 15; font.weight: Font.Bold; Layout.fillWidth: true }
                }

                RowLayout {
                    Layout.fillWidth: true; Layout.topMargin: 4; Layout.bottomMargin: 4; spacing: 12
                    Rectangle {
                        width: 36; height: 36; radius: 10
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                        Text { anchors.centerIn: parent; text: "\ueb61"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 17 }
                    }
                    ColumnLayout { spacing: 1
                        Text { text: "Work VPN"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                        Text { text: "Disconnected"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.7 }
                    }
                    Item { Layout.fillWidth: true }
                    Text { text: "Connect"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    Text { text: "\uea62"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.4 }
                }

                Text {
                    Layout.topMargin: 8
                    text: "+ Add VPN connection"
                    color: Theme.colPrimary
                    font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                }
            }

            // ── Proxy & DNS ───────────────────────────────────────
            SettingsCard {
                RowLayout {
                    Layout.fillWidth: true; Layout.bottomMargin: 8; spacing: 10
                    Text { text: "\uebcc"; color: Theme.colOnSurface; font.family: "tabler-icons"; font.pixelSize: 20 }
                    Text { text: "Proxy & DNS"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 15; font.weight: Font.Bold; Layout.fillWidth: true }
                }

                // Proxy row
                RowLayout {
                    Layout.fillWidth: true; Layout.topMargin: 4; Layout.bottomMargin: 4; spacing: 12
                    Rectangle {
                        width: 36; height: 36; radius: 10
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                        Text { anchors.centerIn: parent; text: "\uebcc"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 17 }
                    }
                    ColumnLayout { spacing: 1
                        Text { text: "Proxy"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.SemiBold }
                        Text { text: "Route traffic through a proxy server"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.7 }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 90; height: 30; radius: 6
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.06)
                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                            Text { text: "Off"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 12; Layout.fillWidth: true }
                            Text { text: "\uea5f"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 13 }
                        }
                    }
                }

                Divider { Layout.leftMargin: 0 }

                // DNS row
                RowLayout {
                    Layout.fillWidth: true; Layout.topMargin: 4; Layout.bottomMargin: 4; spacing: 12
                    Rectangle {
                        width: 36; height: 36; radius: 10
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                        Text { anchors.centerIn: parent; text: "\uebcc"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 17 }
                    }
                    ColumnLayout { spacing: 1
                        Text { text: "DNS server"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.SemiBold }
                        Text { text: "Override the DNS server provided by your network"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.7 }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 110; height: 30; radius: 6
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.06)
                        border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.12); border.width: 1
                        TextInput {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            verticalAlignment: TextInput.AlignVCenter
                            text: "Automatic"; color: Theme.colOnSurface
                            font.family: Theme.defaultFontFamily; font.pixelSize: 12; clip: true
                        }
                    }
                }

                Divider { Layout.leftMargin: 0 }

                // Airplane mode
                RowLayout {
                    Layout.fillWidth: true; Layout.topMargin: 4; Layout.bottomMargin: 4; spacing: 12
                    Rectangle {
                        width: 36; height: 36; radius: 10
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                        Text { anchors.centerIn: parent; text: "\uea12"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 17 }
                    }
                    ColumnLayout { spacing: 1
                        Text { text: "Airplane mode"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.SemiBold }
                        Text { text: "Disable all wireless connections"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.7 }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch {
                        checked: false
                        onToggled: Quickshell.execDetached(["nmcli", "radio", "all", checked ? "off" : "on"])
                    }
                }
            }

            Item { Layout.preferredHeight: 32 }
        }
    }
}
