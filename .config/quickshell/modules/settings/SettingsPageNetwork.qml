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

    property bool wifiRadioEnabled: true
    property string wifiDeviceName: "Wi-Fi"
    property string wifiDeviceState: "Checking..."

    property bool ethernetEnabled: false
    property string ethernetDeviceState: "Checking..."
    property string ethernetDetails: "Checking..."
    property string ethernetDeviceName: "enp6s0"

    property bool hotspotEnabled: false
    property string hotspotSsid: ""

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
        id: wifiRadioProcess
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "enabled") root.wifiRadioEnabled = true;
                else root.wifiRadioEnabled = false;
            }
        }
    }

    Process {
        id: wifiDeviceProcess
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "d"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                let ethFound = false;
                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].split(":");
                    if (parts.length >= 4 && parts[1] === "wifi" && parts[0].indexOf("p2p") === -1) {
                        root.wifiDeviceName = "Wi-Fi (" + parts[0] + ")";
                        if (parts[3] === "Hotspot") {
                            root.wifiDeviceState = "Broadcasting Hotspot";
                        } else {
                            root.wifiDeviceState = parts[2].charAt(0).toUpperCase() + parts[2].slice(1);
                        }
                    }
                    if (parts.length >= 4 && parts[1] === "ethernet") {
                        ethFound = true;
                        root.ethernetDeviceName = parts[0];
                        root.ethernetEnabled = (parts[2] === "connected" || parts[2] === "connecting");
                        root.ethernetDeviceState = parts[2].charAt(0).toUpperCase() + parts[2].slice(1);
                        if (parts[2] === "connected") {
                            root.ethernetDetails = parts[3] + " \u00B7 " + parts[0];
                        } else {
                            root.ethernetDetails = "Not connected";
                        }
                    }
                }
                if (!ethFound) {
                    root.ethernetDeviceState = "No device";
                    root.ethernetDetails = "N/A";
                    root.ethernetEnabled = false;
                }
            }
        }
    }

    ListModel { id: wifiModel }

    Process {
        id: wifiProcess
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
        running: root.wifiRadioEnabled
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                let oldExpanded = {};
                let oldPasswords = {};
                for (let i = 0; i < wifiModel.count; i++) {
                    const item = wifiModel.get(i);
                    if (item.expanded) {
                        oldExpanded[item.ssid] = true;
                        oldPasswords[item.ssid] = item.password;
                    }
                }
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
                    if (ssid === root.hotspotSsid) continue; // Don't show our own hotspot in the wifi list
                    if (seen[ssid]) continue;
                    seen[ssid] = true;
                    
                    const isExpanded = oldExpanded[ssid] ? true : false;
                    const savedPwd = oldPasswords[ssid] ? oldPasswords[ssid] : "";
                    wifiModel.append({ ssid, inUse, isSecure, signal, expanded: isExpanded, password: savedPwd });
                }
            }
        }
    }


    Timer {
        interval: 5000
        running: root.visible
        repeat: true
        onTriggered: {
            wifiRadioProcess.running = true;
            wifiDeviceProcess.running = true;
            hotspotDetailsProcess.running = true;
            if (root.wifiRadioEnabled) {
                let anyExpanded = false;
                for (let i = 0; i < wifiModel.count; i++) {
                    if (wifiModel.get(i).expanded) {
                        anyExpanded = true;
                        break;
                    }
                }
                if (!anyExpanded) {
                    wifiProcess.running = true;
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

                // Wi-Fi header row (clickable to collapse)
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
                            Text { text: root.wifiDeviceName; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: root.wifiRadioEnabled ? root.wifiDeviceState : "Turned off"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }

                    // Rescan button
                    Rectangle {
                        visible: root.wifiRadioEnabled
                        width: 32; height: 32; radius: 8
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                        Text { anchors.centerIn: parent; text: "\ueb13"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 15 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { wifiDeviceProcess.running = true; wifiProcess.running = true; } }
                    }

                    ToggleSwitch {
                        id: wifiSwitch
                        checked: root.wifiRadioEnabled
                        onToggled: {
                            Quickshell.execDetached(["nmcli", "radio", "wifi", checked ? "on" : "off"])
                            root.wifiRadioEnabled = checked
                            if (checked) { wifiProcess.running = true; wifiDeviceProcess.running = true; }
                        }
                    }

                    // Collapse chevron
                    Text {
                        id: wifiChevron
                        text: "\uea5e"
                        font.family: "tabler-icons"; font.pixelSize: 18
                        color: Theme.colOnSurfaceVariant; opacity: 0.5
                        rotation: root.wifiExpanded ? 0 : -90
                        Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        MouseArea {
                            anchors.fill: parent
                            width: 200; height: 44
                            anchors.horizontalCenter: undefined
                            anchors.verticalCenter: undefined
                            x: -180; y: -14
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.wifiExpanded = !root.wifiExpanded
                        }
                    }
                }

                // Connected network(s)
                Repeater {
                    visible: root.wifiExpanded && root.wifiRadioEnabled
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
                        Text { text: "\ueae2"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.4 }
                        Text { text: "\uea5f"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.35 }
                    }
                }

                // Other networks
                Repeater {
                    visible: root.wifiExpanded && root.wifiRadioEnabled
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
                                        text: model.signal > 66 ? "\ueb52" : (model.signal > 33 ? "\ueba5" : "\uecfa")
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
                            Text { visible: model.isSecure; text: "\ueae2"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.4 }
                            Text { text: "\uea5f"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.35 }

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
                                    text: model.password
                                    onTextChanged: {
                                        if (text !== model.password) {
                                            wifiModel.setProperty(index, "password", text)
                                        }
                                    }
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

                SettingsRow {
                    visible: root.wifiExpanded && root.wifiRadioEnabled
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12)
                            Text { anchors.centerIn: parent; text: "\ueb92"; color: Theme.colPrimary; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Disable MAC Randomization"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Fixes connection issues for MediaTek Wi-Fi chips"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch {
                        id: macRandToggle
                        checked: false
                        onToggled: {
                            if (checked) {
                                Quickshell.execDetached(["bash", "-c", "echo -e '[device-mac-randomization]\\nwifi.scan-rand-mac-address=no\\n[connection-mac-randomization]\\nwifi.cloned-mac-address=preserve' | pkexec tee /etc/NetworkManager/conf.d/mac-randomization.conf && pkexec systemctl restart NetworkManager"]);
                            } else {
                                Quickshell.execDetached(["bash", "-c", "pkexec rm -f /etc/NetworkManager/conf.d/mac-randomization.conf && pkexec systemctl restart NetworkManager"]);
                            }
                        }
                    }
                }

                Process {
                    command: ["bash", "-c", "test -f /etc/NetworkManager/conf.d/mac-randomization.conf && echo 1 || echo 0"]
                    running: true
                    stdout: StdioCollector {
                        onStreamFinished: {
                            if (text.trim() === "1") macRandToggle.checked = true;
                            else macRandToggle.checked = false;
                        }
                    }
                }

                // Add network link
                Text {
                    visible: root.wifiExpanded && root.wifiRadioEnabled
                    text: "+ Add network manually"
                    color: Theme.colPrimary
                    font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                }
            }

            // ── Mobile Hotspot ────────────────────────────────────────────
            SettingsCard {
                SectionLabel { text: "Mobile Hotspot" }

                SettingsRow {
                    id: hotspotSettingsRow

                    Item {
                        implicitWidth: leftContentRow.implicitWidth
                        implicitHeight: leftContentRow.implicitHeight
                        
                        RowLayout {
                            id: leftContentRow
                            spacing: 12
                            Rectangle {
                                width: 32; height: 32; radius: 16
                                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                                Text { anchors.centerIn: parent; text: "\ued1b"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                            }
                            ColumnLayout {
                                spacing: 1
                                Text { text: "Mobile Hotspot"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                                Text { text: root.hotspotEnabled ? "On" : "Off"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let p = root;
                                while (p && !p.hasOwnProperty("currentIndex")) p = p.parent;
                                if (p.currentIndex !== undefined) {
                                    p.currentIndex = 23;
                                }
                            }
                        }
                    }
                    
                    Item { Layout.fillWidth: true } // spacer

                    ToggleSwitch {
                        id: hotspotToggle
                        checked: root.hotspotEnabled
                        onToggled: {
                            if (root.hotspotEnabled) {
                                let proc = Qt.createQmlObject('import Quickshell.Io; Process { command: ["nmcli", "connection", "down", "Hotspot"]; running: true }', root);
                                root.hotspotEnabled = false;
                            } else {
                                let proc = Qt.createQmlObject('import Quickshell.Io; Process { command: ["bash", "-c", "nmcli connection up Hotspot || nmcli device wifi hotspot ssid cupcake-hotspot password cupcake-password"]; running: true }', root);
                                root.hotspotEnabled = true;
                            }
                        }
                    }
                    
                    Text {
                        text: "\uea61" // chevron-right
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 18
                        opacity: 0.6
                        Layout.alignment: Qt.AlignVCenter
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let p = root;
                                while (p && !p.hasOwnProperty("currentIndex")) p = p.parent;
                                if (p.currentIndex !== undefined) {
                                    p.currentIndex = 23;
                                }
                            }
                        }
                    }
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
                            Text { anchors.centerIn: parent; text: "\uebd9"; color: Theme.colPrimary; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Wired connection"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: root.ethernetDetails; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 74; height: 24; radius: 6
                        color: root.ethernetEnabled ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                        Text { anchors.centerIn: parent; text: root.ethernetEnabled ? "Connected" : "Disabled"; color: root.ethernetEnabled ? Theme.colPrimary : Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Medium }
                    }
                    ToggleSwitch {
                        id: ethToggle
                        checked: root.ethernetEnabled
                        onToggled: {
                            if (root.ethernetEnabled) {
                                let proc = Qt.createQmlObject('import Quickshell.Io; Process { command: ["nmcli", "device", "disconnect", root.ethernetDeviceName]; running: true; onExited: wifiDeviceProcess.running = true }', root);
                            } else {
                                let proc = Qt.createQmlObject('import Quickshell.Io; Process { command: ["nmcli", "device", "connect", root.ethernetDeviceName]; running: true; onExited: wifiDeviceProcess.running = true }', root);
                            }
                            root.ethernetEnabled = checked;
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\ueb13"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
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
                            Text { anchors.centerIn: parent; text: "\ued58"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Work VPN"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Disconnected"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text { text: "Connect"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    Text { text: "\uea5f"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.35 }
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
                            Text { anchors.centerIn: parent; text: "\ueab9"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
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
                            Text { anchors.centerIn: parent; text: "\ueab9"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
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
                            Text { anchors.centerIn: parent; text: "\ueb6f"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
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
