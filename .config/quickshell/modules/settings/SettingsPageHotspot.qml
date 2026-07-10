import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import Quickshell
import Quickshell.Io
import "../common"

Item {
    id: root

    property bool wifiExpanded: true

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
    
    property bool hotspotEnabled: false

    Process {
        id: hotspotStatusProcess
        command: ["bash", "-c", "nmcli -t -f TYPE,STATE,CONNECTION d | grep -i 'wifi:connected' | grep -qi -E 'hotspot' && echo 'on' || echo 'off'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "on") root.hotspotEnabled = true;
                else root.hotspotEnabled = false;
            }
        }
    }

    property string hotspotSsid: ""
    property string hotspotPassword: ""
    property bool showHotspotPassword: false
    property string hotspotConnectedClients: "0"

    Process {
        id: hotspotClientsProcess
        command: ["bash", "-c", "DEV=$(nmcli -t -f DEVICE,CONNECTION d | grep ':Hotspot$' | cut -d: -f1); if [ -n \"$DEV\" ]; then ip neigh show dev \"$DEV\" 2>/dev/null | grep -c lladdr || echo 0; else echo 0; fi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") root.hotspotConnectedClients = text.trim();
            }
        }
    }

    Process {
        id: hotspotDetailsProcess
        command: ["bash", "-c", "nmcli -g 802-11-wireless.ssid connection show Hotspot 2>/dev/null || echo 'cupcake-hotspot'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") root.hotspotSsid = text.trim();
            }
        }
    }

    Process {
        id: hotspotPassProcess
        command: ["bash", "-c", "nmcli -s -g 802-11-wireless-security.psk connection show Hotspot 2>/dev/null || echo '12345678'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") root.hotspotPassword = text.trim();
            }
        }
    }

    Timer {
        interval: 5000
        running: root.visible
        repeat: true
        onTriggered: {
            hotspotStatusProcess.running = true;
            hotspotDetailsProcess.running = true;
            hotspotPassProcess.running = true;
            hotspotClientsProcess.running = true;
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

            // ── Mobile Hotspot ────────────────────────────────────────────
            SettingsCard {
                SectionLabel { text: "Mobile Hotspot" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: root.hotspotEnabled ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\ued1b"; color: root.hotspotEnabled ? Theme.colPrimary : Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Wi-Fi Hotspot"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: root.hotspotEnabled ? "Sharing connection..." : "Off"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    
                    ToggleSwitch {
                        checked: root.hotspotEnabled
                        onToggled: {
                            root.hotspotEnabled = checked;
                            if (checked) {
                                // Stop BT scanning first — MT7921 combo chip can't run
                                // AP mode and BT discovery simultaneously on 2.4GHz
                                Quickshell.execDetached(["bash", "-c",
                                    "bluetoothctl scan off 2>/dev/null; " +
                                    "sleep 0.5; " +
                                    "nmcli connection up Hotspot 2>/dev/null || nmcli device wifi hotspot"
                                ]);
                            } else {
                                Quickshell.execDetached(["bash", "-c", "nmcli connection down Hotspot || nmcli connection down hotspot"]);
                            }
                            hotspotStatusProcess.running = true;
                        }
                    }
                }
                
                Item { Layout.preferredHeight: 8 }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Text { text: "\ueac3"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        Text { text: "Network name"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13 }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 8
                        StyledTextField {
                            id: ssidField
                            text: root.hotspotSsid
                            placeholderText: "Hotspot Name"
                            horizontalAlignment: TextInput.AlignRight
                            Layout.preferredWidth: 150
                            onEditingFinished: {
                                if (text.trim() !== "" && text !== root.hotspotSsid) {
                                    root.hotspotSsid = text.trim();
                                    Quickshell.execDetached(["bash", "-c", 'nmcli connection modify Hotspot "$1" "$2"; if nmcli -t -f TYPE,STATE,CONNECTION d | grep -i "wifi:connected" | grep -qi "hotspot"; then nmcli connection up Hotspot; fi', "--", "wifi.ssid", root.hotspotSsid]);
                                }
                            }
                        }
                        Rectangle {
                            Layout.preferredWidth: 28; Layout.preferredHeight: 28
                            radius: 14
                            color: Theme.colPrimary
                            visible: ssidField.text !== root.hotspotSsid
                            Text { anchors.centerIn: parent; text: "\uea5e"; color: Theme.colOnPrimary; font.family: "tabler-icons"; font.pixelSize: 16 }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (ssidField.text.trim() !== "") {
                                        root.hotspotSsid = ssidField.text.trim();
                                        Quickshell.execDetached(["bash", "-c", 'nmcli connection modify Hotspot "$1" "$2"; if nmcli -t -f TYPE,STATE,CONNECTION d | grep -i "wifi:connected" | grep -qi "hotspot"; then nmcli connection up Hotspot; fi', "--", "wifi.ssid", root.hotspotSsid]);
                                    }
                                }
                            }
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Text { text: "\ueac7"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        Text { text: "Password"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13 }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 8
                        StyledTextField {
                            id: passField
                            text: root.hotspotPassword
                            placeholderText: "Password"
                            font.letterSpacing: root.showHotspotPassword ? 0 : 2
                            echoMode: root.showHotspotPassword ? TextInput.Normal : TextInput.Password
                            horizontalAlignment: TextInput.AlignRight
                            Layout.preferredWidth: 120
                            onEditingFinished: {
                                if (text.trim() !== "" && text !== root.hotspotPassword) {
                                    root.hotspotPassword = text.trim();
                                    Quickshell.execDetached(["bash", "-c", 'nmcli connection modify Hotspot "$1" "$2"; if nmcli -t -f TYPE,STATE,CONNECTION d | grep -i "wifi:connected" | grep -qi "hotspot"; then nmcli connection up Hotspot; fi', "--", "wifi-sec.psk", root.hotspotPassword]);
                                }
                            }
                        }
                        MouseArea {
                            Layout.preferredWidth: 24; Layout.preferredHeight: 24
                            cursorShape: Qt.PointingHandCursor
                            Text {
                                anchors.centerIn: parent
                                text: root.showHotspotPassword ? "\uecf0" : "\uea9a"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                            onClicked: root.showHotspotPassword = !root.showHotspotPassword
                        }
                        Rectangle {
                            Layout.preferredWidth: 28; Layout.preferredHeight: 28
                            radius: 14
                            color: Theme.colPrimary
                            visible: passField.text !== root.hotspotPassword
                            Text { anchors.centerIn: parent; text: "\uea5e"; color: Theme.colOnPrimary; font.family: "tabler-icons"; font.pixelSize: 16 }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (passField.text.trim() !== "") {
                                        root.hotspotPassword = passField.text.trim();
                                        Quickshell.execDetached(["bash", "-c", 'nmcli connection modify Hotspot "$1" "$2"; if nmcli -t -f TYPE,STATE,CONNECTION d | grep -i "wifi:connected" | grep -qi "hotspot"; then nmcli connection up Hotspot; fi', "--", "wifi-sec.psk", root.hotspotPassword]);
                                    }
                                }
                            }
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Text { text: "\uebf2"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        Text { text: "Connected devices"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13 }
                    }
                    Item { Layout.fillWidth: true }
                    Text { text: root.hotspotEnabled ? root.hotspotConnectedClients : "0"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 13 }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Text { text: "\uf548"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        Text { text: "Auto-disable when idle"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13 }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch { checked: true }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Text { text: "\uea38"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        Text { text: "Maximize compatibility"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13 }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch { checked: false }
                }
            }


            
        }
    }
}
