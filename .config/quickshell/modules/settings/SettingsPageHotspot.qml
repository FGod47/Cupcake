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
        color: Theme.showCardBackground ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03) : "transparent"
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
            }

            // ── Configuration ──────────────────────────────────────────────
            SettingsCard {
                id: configCard
                property bool isEditing: false

                RowLayout {
                    Layout.fillWidth: true
                    SectionLabel { text: "Configuration"; Layout.fillWidth: true }
                    Rectangle {
                        width: 60; height: 22; radius: 11
                        color: configCard.isEditing
                            ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.15)
                            : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.06)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: configCard.isEditing ? "\uea5e" : "\ueb04"
                                color: configCard.isEditing ? Theme.colPrimary : Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"; font.pixelSize: 12
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                            Text {
                                text: configCard.isEditing ? "Done" : "Edit"
                                color: configCard.isEditing ? Theme.colPrimary : Theme.colOnSurfaceVariant
                                font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Medium
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (configCard.isEditing) {
                                    // Save on Done
                                    if (ssidInput.text.trim() !== "" && ssidInput.text !== root.hotspotSsid) {
                                        root.hotspotSsid = ssidInput.text.trim();
                                        Quickshell.execDetached(["bash", "-c", 'nmcli connection modify Hotspot "$1" "$2"; if nmcli -t -f TYPE,STATE,CONNECTION d | grep -i "wifi:connected" | grep -qi "hotspot"; then nmcli connection up Hotspot; fi', "--", "wifi.ssid", root.hotspotSsid]);
                                    }
                                    if (passInput.text.trim() !== "" && passInput.text !== root.hotspotPassword) {
                                        root.hotspotPassword = passInput.text.trim();
                                        Quickshell.execDetached(["bash", "-c", 'nmcli connection modify Hotspot "$1" "$2"; if nmcli -t -f TYPE,STATE,CONNECTION d | grep -i "wifi:connected" | grep -qi "hotspot"; then nmcli connection up Hotspot; fi', "--", "wifi-sec.psk", root.hotspotPassword]);
                                    }
                                }
                                configCard.isEditing = !configCard.isEditing;
                            }
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\ueac3"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        Text { text: "Network name"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13 }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 8
                        // SSID field — full-width dark bg rounded like Wi-Fi password field
                        Rectangle {
                            Layout.preferredWidth: 250; Layout.preferredHeight: 34
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            radius: 8
                            border.color: ssidInput.activeFocus
                                ? Theme.colPrimary
                                : Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.12)
                            border.width: ssidInput.activeFocus ? 2 : 1
                            TextInput {
                                id: ssidInput
                                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                verticalAlignment: TextInput.AlignVCenter
                                color: Theme.colOnSurface
                                font.family: Theme.defaultFontFamily; font.pixelSize: 13
                                text: root.hotspotSsid
                                clip: true
                                readOnly: !configCard.isEditing
                                opacity: configCard.isEditing ? 1.0 : 0.6
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                                onEditingFinished: {
                                    if (text.trim() !== "" && text !== root.hotspotSsid) {
                                        root.hotspotSsid = text.trim();
                                        Quickshell.execDetached(["bash", "-c", 'nmcli connection modify Hotspot "$1" "$2"; if nmcli -t -f TYPE,STATE,CONNECTION d | grep -i "wifi:connected" | grep -qi "hotspot"; then nmcli connection up Hotspot; fi', "--", "wifi.ssid", root.hotspotSsid]);
                                    }
                                }
                            }
                        }
                        Rectangle {
                            Layout.preferredWidth: 28; Layout.preferredHeight: 28
                            radius: 14
                            color: Theme.colPrimary
                            visible: ssidInput.text !== root.hotspotSsid
                            Text { anchors.centerIn: parent; text: "\uea5e"; color: Theme.colOnPrimary; font.family: "tabler-icons"; font.pixelSize: 16 }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (ssidInput.text.trim() !== "") {
                                        root.hotspotSsid = ssidInput.text.trim();
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
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\ueac7"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        Text { text: "Password"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13 }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 8
                        // Password field — dark bg, rounded, eye icon inside on the right
                        Rectangle {
                            Layout.preferredWidth: 250; Layout.preferredHeight: 34
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            radius: 8
                            border.color: passInput.activeFocus
                                ? Theme.colPrimary
                                : Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.12)
                            border.width: passInput.activeFocus ? 2 : 1

                            TextInput {
                                id: passInput
                                anchors { fill: parent; leftMargin: 10; rightMargin: 36 }
                                verticalAlignment: TextInput.AlignVCenter
                                color: Theme.colOnSurface
                                font.family: Theme.defaultFontFamily; font.pixelSize: 13
                                echoMode: root.showHotspotPassword ? TextInput.Normal : TextInput.Password
                                text: root.hotspotPassword
                                clip: true
                                readOnly: !configCard.isEditing
                                opacity: configCard.isEditing ? 1.0 : 0.6
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                                onEditingFinished: {
                                    if (text.trim() !== "" && text !== root.hotspotPassword) {
                                        root.hotspotPassword = text.trim();
                                        Quickshell.execDetached(["bash", "-c", 'nmcli connection modify Hotspot "$1" "$2"; if nmcli -t -f TYPE,STATE,CONNECTION d | grep -i "wifi:connected" | grep -qi "hotspot"; then nmcli connection up Hotspot; fi', "--", "wifi-sec.psk", root.hotspotPassword]);
                                    }
                                }
                            }

                            // Eye toggle inside field on the right
                            MouseArea {
                                width: 30; height: parent.height
                                anchors.right: parent.right
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.showHotspotPassword = !root.showHotspotPassword
                                Text {
                                    anchors.centerIn: parent
                                    text: root.showHotspotPassword ? "\uecf0" : "\uea9a"
                                    color: Theme.colOnSurfaceVariant
                                    font.family: "tabler-icons"; font.pixelSize: 16
                                }
                            }
                        }
                        // Save button when changed
                        Rectangle {
                            Layout.preferredWidth: 28; Layout.preferredHeight: 28
                            radius: 14
                            color: Theme.colPrimary
                            visible: passInput.text !== root.hotspotPassword
                            Text { anchors.centerIn: parent; text: "\uea5e"; color: Theme.colOnPrimary; font.family: "tabler-icons"; font.pixelSize: 16 }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (passInput.text.trim() !== "") {
                                        root.hotspotPassword = passInput.text.trim();
                                        Quickshell.execDetached(["bash", "-c", 'nmcli connection modify Hotspot "$1" "$2"; if nmcli -t -f TYPE,STATE,CONNECTION d | grep -i "wifi:connected" | grep -qi "hotspot"; then nmcli connection up Hotspot; fi', "--", "wifi-sec.psk", root.hotspotPassword]);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Status & Advanced ─────────────────────────────────────────
            SettingsCard {
                SectionLabel { text: "Status & Advanced" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\uebf2"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        Text { text: "Connected devices"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13 }
                    }
                    Item { Layout.fillWidth: true }
                    Text { text: root.hotspotEnabled ? root.hotspotConnectedClients : "0"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\uf548"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        Text { text: "Auto-disable when idle"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13 }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch { checked: true }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\uea38"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        Text { text: "Maximize compatibility"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13 }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch { checked: false }
                }
            }


            
        }
    }
}
