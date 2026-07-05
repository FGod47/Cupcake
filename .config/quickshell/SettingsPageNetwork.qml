import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "theme"
import Quickshell
import Quickshell.Io

Item {
    id: root

    // =====================================================================
    // Reusable inline components — identical to SettingsPageAppearance
    // =====================================================================

    component SettingsCard: Rectangle {
        default property alias content: innerCol.data
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        implicitHeight: innerCol.implicitHeight + 40
        Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
        radius: 12
        clip: true
        ColumnLayout {
            id: innerCol
            anchors.fill: parent
            anchors.margins: 20
            spacing: 8
        }
    }

    component SectionLabel: Text {
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 0.4
        color: Theme.colOnSurface
        opacity: 0.45
    }

    component ToggleSwitch: Rectangle {
        id: sw
        property bool checked: false
        signal toggled(bool checked)
        width: 38; height: 22
        radius: height / 2
        color: checked ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.15)
        border.width: checked ? 0 : 1
        border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.1)
        Behavior on color { ColorAnimation { duration: 120 } }
        Rectangle {
            width: 18; height: 18; radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: sw.checked ? parent.width - width - 2 : 2
            color: sw.checked ? Theme.colSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.8)
            Behavior on x { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: { sw.checked = !sw.checked; sw.toggled(sw.checked) }
        }
    }

    component SettingsRow: RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        spacing: 12
    }

    // =====================================================================
    // Background data
    // =====================================================================

    ListModel { id: wifiModel }

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
                    wifiModel.append({ ssid, inUse, isSecure, signal, expanded: false, password: "" });
                }
            }
        }
    }

    // =====================================================================
    // UI
    // =====================================================================

    ScrollView {
        anchors.fill: parent
        anchors.topMargin: 0
        anchors.bottomMargin: 30
        anchors.leftMargin: 0
        anchors.rightMargin: 24
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 24

            // ── Wi-Fi ─────────────────────────────────────────────────────
            SettingsCard {
                SectionLabel { text: "Wi-Fi" }

                // Wi-Fi toggle row
                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\ueb52"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Wi-Fi"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Connect to wireless networks"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }

                    // Rescan button
                    Rectangle {
                        width: 32; height: 32; radius: 8
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                        Text { anchors.centerIn: parent; text: "\ueb38"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 15 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: wifiProcess.running = true }
                    }

                    ToggleSwitch {
                        id: wifiSwitch; checked: true
                        onToggled: Quickshell.execDetached(["nmcli", "radio", "wifi", checked ? "on" : "off"])
                    }
                }

                // Connected network(s)
                Repeater {
                    model: wifiModel
                    delegate: SettingsRow {
                        visible: model.inUse
                        RowLayout {
                            spacing: 12
                            Rectangle {
                                width: 32; height: 32; radius: 16
                                color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12)
                                Text { anchors.centerIn: parent; text: "\ueb52"; color: Theme.colPrimary; font.family: "tabler-icons"; font.pixelSize: 16 }
                            }
                            ColumnLayout {
                                spacing: 1
                                Text { text: model.ssid; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                                Text { text: "Connected · Secured"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                            }
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 60; height: 24; radius: 6
                            color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12)
                            Text { anchors.centerIn: parent; text: "Strong"; color: Theme.colPrimary; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Medium }
                        }
                        Text { text: "\ueb04"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.4 }
                        Text { text: "\uea62"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.35 }
                    }
                }

                // Other networks
                Repeater {
                    model: wifiModel
                    delegate: ColumnLayout {
                        visible: !model.inUse
                        Layout.fillWidth: true
                        spacing: 0

                        SettingsRow {
                            RowLayout {
                                spacing: 12
                                Rectangle {
                                    width: 32; height: 32; radius: 16
                                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                                    Text {
                                        anchors.centerIn: parent
                                        text: model.signal > 50 ? "\ueb52" : "\ueb53"
                                        color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16
                                    }
                                }
                                ColumnLayout {
                                    spacing: 1
                                    Text { text: model.ssid; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                                    Text { text: model.isSecure ? "Secured" : "Open network"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                                }
                            }
                            Item { Layout.fillWidth: true }
                            Text { visible: model.isSecure; text: "\ueb04"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.4 }
                            Text { text: "\uea62"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.35 }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                enabled: !model.expanded
                                onClicked: {
                                    for (let i = 0; i < wifiModel.count; i++) wifiModel.setProperty(i, "expanded", false);
                                    if (!model.isSecure) { Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", model.ssid]); wifiProcess.running = true; }
                                    else wifiModel.setProperty(index, "expanded", true);
                                }
                            }
                        }

                        // Expanded password row
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 44; Layout.rightMargin: 0; Layout.bottomMargin: 4
                            spacing: 8
                            visible: model.expanded
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 34
                                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                                radius: 8
                                border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.12); border.width: 1
                                TextInput {
                                    id: pwdIn
                                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 12
                                    echoMode: TextInput.Password; clip: true
                                    onTextChanged: wifiModel.setProperty(index, "password", text)
                                }
                                Text {
                                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                    text: "Password..."; color: Theme.colOnSurfaceVariant
                                    font.family: Theme.defaultFontFamily; font.pixelSize: 12; opacity: 0.5
                                    visible: pwdIn.text === ""
                                }
                            }
                            Rectangle {
                                width: 76; height: 34; radius: 8
                                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.88)
                                Text { anchors.centerIn: parent; text: "Connect"; color: Theme.colSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.Medium }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (model.isSecure) Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", model.ssid, "password", model.password]);
                                        else Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", model.ssid]);
                                        wifiModel.setProperty(index, "expanded", false);
                                        wifiProcess.running = true;
                                    }
                                }
                            }
                        }
                    }
                }

                // Add network link
                Text {
                    text: "+ Add network manually"
                    color: Theme.colPrimary
                    font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                }
            }

            // ── Bluetooth ─────────────────────────────────────────────────
            SettingsCard {
                SectionLabel { text: "Bluetooth" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\uea37"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Bluetooth"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Manage paired and nearby devices"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch {
                        checked: true
                        onToggled: Quickshell.execDetached(["bash", "-c", "bluetoothctl power " + (checked ? "on" : "off")])
                    }
                }

                // Sony WH-1000XM5
                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12)
                            Text { anchors.centerIn: parent; text: "\uea64"; color: Theme.colPrimary; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Sony WH-1000XM5"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Connected · Battery 82%"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 74; height: 24; radius: 6
                        color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12)
                        Text { anchors.centerIn: parent; text: "Connected"; color: Theme.colPrimary; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Medium }
                    }
                    Text { text: "\uea62"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.35 }
                }

                // MX Keys
                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\uead3"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "MX Keys"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Paired · Not connected"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 52; height: 24; radius: 6
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.07)
                        Text { anchors.centerIn: parent; text: "Paired"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Medium }
                    }
                    Text { text: "\uea62"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.35 }
                }

                // MX Master 3S
                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\uead0"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "MX Master 3S"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Available"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text { text: "Pair"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    Text { text: "\uea62"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.35 }
                }

                // DualSense
                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\uebce"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "DualSense Controller"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Available"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text { text: "Pair"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    Text { text: "\uea62"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.35 }
                }
            }

            // ── Ethernet ──────────────────────────────────────────────────
            SettingsCard {
                SectionLabel { text: "Ethernet" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12)
                            Text { anchors.centerIn: parent; text: "\uebb3"; color: Theme.colPrimary; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Wired connection"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Connected · 1 Gbps · 192.168.1.42"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 74; height: 24; radius: 6
                        color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12)
                        Text { anchors.centerIn: parent; text: "Connected"; color: Theme.colPrimary; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Medium }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\ueb38"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Connect automatically"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Use this connection whenever a cable is plugged in"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch { checked: true }
                }
            }

            // ── VPN ───────────────────────────────────────────────────────
            SettingsCard {
                SectionLabel { text: "VPN" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\ueb61"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Work VPN"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Disconnected"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text { text: "Connect"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    Text { text: "\uea62"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.35 }
                }

                Text {
                    text: "+ Add VPN connection"
                    color: Theme.colPrimary
                    font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
                }
            }

            // ── Proxy & DNS ───────────────────────────────────────────────
            SettingsCard {
                SectionLabel { text: "Proxy & DNS" }

                // Proxy
                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\uebcc"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Proxy"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Route traffic through a proxy server"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 90; height: 28; radius: 8
                        color: Qt.rgba(0, 0, 0, 0.28)
                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                            Text { text: "Off"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 12; Layout.fillWidth: true }
                            Text { text: "\uea5f"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 13 }
                        }
                    }
                }

                // DNS
                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\uebcc"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "DNS server"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Override the DNS server provided by your network"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 110; height: 28; radius: 8
                        color: Qt.rgba(0, 0, 0, 0.28)
                        border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.10); border.width: 1
                        TextInput {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            verticalAlignment: TextInput.AlignVCenter
                            text: "Automatic"; color: Theme.colOnSurface
                            font.family: Theme.defaultFontFamily; font.pixelSize: 12; clip: true
                        }
                    }
                }

                // Airplane mode
                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\uea12"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Airplane mode"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Disable all wireless connections"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
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
