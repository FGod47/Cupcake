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
            width: 18; height: 18
            radius: 9
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

    // =========================================================
    // Network data
    // =========================================================

    ListModel { id: wifiModel }

    Process {
        id: refreshProcess
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

                    wifiModel.append({
                        ssid: ssid,
                        inUse: inUse,
                        isSecure: isSecure,
                        security: security,
                        signal: signal,
                        expanded: false,
                        password: ""
                    });
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
            spacing: 24

            // ── Wi-Fi toggle card ──────────────────────────────────
            SettingsCard {
                SectionLabel { text: "Network & Internet" }

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
                        Item { Layout.fillWidth: true }

                        // Rescan button
                        Rectangle {
                            width: 32; height: 32; radius: 8
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\ueb38"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 15 }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: refreshProcess.running = true
                            }
                        }

                        ToggleSwitch {
                            id: wifiSwitch
                            checked: true
                            onToggled: Quickshell.execDetached(["nmcli", "radio", "wifi", checked ? "on" : "off"])
                        }
                    }
                }
            }

            // ── Network list card ──────────────────────────────────
            SettingsCard {
                SectionLabel { text: "Available Networks" }

                Repeater {
                    model: wifiModel

                    delegate: ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        // Divider between items
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            visible: index > 0
                            color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.08)
                        }

                        // Main row
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            Layout.bottomMargin: model.expanded ? 4 : 8
                            spacing: 12

                            // Signal / connection icon
                            Rectangle {
                                width: 32; height: 32; radius: 16
                                color: model.inUse
                                    ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.15)
                                    : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                                Text {
                                    anchors.centerIn: parent
                                    text: "\ueb52"
                                    color: model.inUse ? Theme.colPrimary : Theme.colOnSurfaceVariant
                                    font.family: "tabler-icons"; font.pixelSize: 16
                                }
                            }

                            ColumnLayout {
                                spacing: 1
                                Text {
                                    text: model.ssid
                                    color: Theme.colOnSurface
                                    font.family: Theme.monoFontFamily; font.pixelSize: 13
                                    font.weight: model.inUse ? Font.Bold : Font.Medium
                                }
                                Text {
                                    text: model.inUse ? "Connected" : (model.isSecure ? "Secured" : "Open network")
                                    color: model.inUse ? Theme.colPrimary : Theme.colOnSurfaceVariant
                                    font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.85
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Lock icon
                            Text {
                                visible: model.isSecure && !model.inUse
                                text: "\ueb04"
                                color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 15; opacity: 0.5
                            }

                            // Chevron
                            Text {
                                visible: !model.inUse
                                text: model.expanded ? "\uea61" : "\uea62"
                                color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 15; opacity: 0.4
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (model.inUse) return;
                                    for (let i = 0; i < wifiModel.count; i++) {
                                        if (i !== index) wifiModel.setProperty(i, "expanded", false);
                                    }
                                    if (!model.isSecure) {
                                        Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", model.ssid]);
                                        refreshProcess.running = true;
                                    } else {
                                        wifiModel.setProperty(index, "expanded", !model.expanded);
                                    }
                                }
                            }
                        }

                        // Password row (expanded)
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.bottomMargin: 8
                            spacing: 8
                            visible: model.expanded
                            clip: true

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                                radius: 8
                                border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                                border.width: 1

                                TextInput {
                                    id: pwdInput
                                    anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.colOnSurface
                                    font.family: Theme.defaultFontFamily; font.pixelSize: 12
                                    echoMode: TextInput.Password
                                    clip: true
                                    onTextChanged: wifiModel.setProperty(index, "password", text)
                                }
                                Text {
                                    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                                    text: "Wi-Fi password..."
                                    color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 12; opacity: 0.5
                                    visible: pwdInput.text === ""
                                }
                            }

                            Rectangle {
                                width: 80; height: 36; radius: 8
                                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.9)
                                Text {
                                    anchors.centerIn: parent
                                    text: "Connect"; color: Theme.colSurface
                                    font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.Medium
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const ssid = model.ssid;
                                        const pw   = model.password;
                                        if (model.isSecure) {
                                            Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", ssid, "password", pw]);
                                        } else {
                                            Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", ssid]);
                                        }
                                        wifiModel.setProperty(index, "expanded", false);
                                        refreshProcess.running = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Advanced card ──────────────────────────────────────
            SettingsCard {
                SectionLabel { text: "Advanced" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\uebb2"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Advanced Network Configuration"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Open system connection editor"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                        Item { Layout.fillWidth: true }
                        Text { text: "\uea62"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16; opacity: 0.4 }
                    }
                    // clickable overlay using a z-stacked MouseArea without anchors conflict
                    MouseArea {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["nm-connection-editor"])
                    }
                }
            }

            Item { Layout.preferredHeight: 32 }
        }
    }
}
