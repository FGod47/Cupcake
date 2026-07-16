import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import Quickshell
import Quickshell.Io
import "../common"

Item {
    id: root
    anchors.fill: parent

    // =========================================================================
    // State
    // =========================================================================
    property bool wifiExpanded: true
    property bool wifiRadioEnabled: true
    property string wifiDeviceName: "wlan0"
    property string wifiDeviceState: "Checking..."
    property bool ethernetEnabled: false
    property string ethernetDeviceState: "Checking..."
    property string ethernetDetails: "Not connected"
    property string ethernetDeviceName: "eth0"
    property bool hotspotEnabled: false
    property string hotspotSsid: ""
    property string localIp: ""
    property string publicIp: ""

    // =========================================================================
    // Color aliases from parent SettingsUI (inherits via QML scope)
    // =========================================================================

    // =========================================================================
    // Components
    // =========================================================================

    component NCard: Rectangle {
        default property alias content: cardCol.data
        property string sectionTitle: ""
        Layout.fillWidth: true
        radius: 12
        color: cSurface
        border.color: cBorder
        border.width: 1
        implicitHeight: cardCol.implicitHeight + (sectionTitle !== "" ? 56 : 32)
        Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        clip: true

        // Section header
        RowLayout {
            id: cardHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.topMargin: 16
            visible: sectionTitle !== ""
            spacing: 8

            Text {
                text: sectionTitle
                color: cTextDim
                font.family: Theme.defaultFontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
                font.capitalization: Font.AllUppercase
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: cBorder }
        }

        ColumnLayout {
            id: cardCol
            anchors.top: cardHeader.visible ? cardHeader.bottom : parent.top
            anchors.topMargin: cardHeader.visible ? 12 : 16
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.bottomMargin: 16
            spacing: 0
        }
    }

    component NRow: Rectangle {
        default property alias rowContent: innerLayout.data
        Layout.fillWidth: true
        implicitHeight: innerLayout.implicitHeight + 20
        color: "transparent"
        radius: 8

        property bool hoverable: false
        property bool hovered: hoverArea.containsMouse
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            id: innerLayout
            anchors.fill: parent
            anchors.leftMargin: 0
            anchors.rightMargin: 0
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            spacing: 12
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: parent.hoverable
        }

        // Bottom divider
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: cBorder
            opacity: 0.6
        }
    }

    component NIconBadge: Rectangle {
        property string icon: ""
        property color iconColor: cTextDim
        property color bgColor: cBgElevated
        width: 36; height: 36; radius: 10
        color: bgColor
        Text {
            anchors.centerIn: parent
            text: parent.icon
            font.family: "tabler-icons"
            font.pixelSize: 18
            color: parent.iconColor
        }
    }

    component NToggle: Rectangle {
        id: tog
        property bool checked: false
        signal toggled(bool val)
        width: 44; height: 24; radius: 12
        color: checked ? cAccent : cBorderSoft
        Behavior on color { ColorAnimation { duration: 150 } }
        Rectangle {
            width: 18; height: 18; radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: tog.checked ? parent.width - width - 3 : 3
            color: "white"
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            layer.enabled: true
            layer.effect: null
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: { tog.checked = !tog.checked; tog.toggled(tog.checked) }
        }
    }

    component SignalBars: Row {
        property int signal: 0
        spacing: 6
        Repeater {
            model: 4
            Rectangle {
                width: 6
                height: 4 + index * 5
                anchors.bottom: parent ? parent.bottom : undefined
                radius: 3
                color: {
                    const threshold = index * 25;
                    if (signal > threshold) return cAccent;
                    return Qt.rgba(cText.r, cText.g, cText.b, 0.15);
                }
            }
        }
    }

    // =========================================================================
    // Data processes
    // =========================================================================

    ListModel { id: wifiModel }

    Process {
        id: forgetProcess
        onExited: {
            savedNetworksProcess.running = true;
            wifiScanProcess.running = true;
        }
    }

    Process {
        id: wifiRadioProcess
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.wifiRadioEnabled = text.trim() === "enabled" }
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
                    if (parts.length >= 4 && parts[1] === "wifi" && !parts[0].includes("p2p")) {
                        root.wifiDeviceName = parts[0];
                        root.wifiDeviceState = parts[3] !== "" && parts[3] !== "--"
                            ? parts[3]
                            : parts[2].charAt(0).toUpperCase() + parts[2].slice(1);
                    }
                    if (parts.length >= 4 && parts[1] === "ethernet") {
                        ethFound = true;
                        root.ethernetDeviceName = parts[0];
                        root.ethernetEnabled = (parts[2] === "connected" || parts[2] === "connecting");
                        root.ethernetDeviceState = parts[2].charAt(0).toUpperCase() + parts[2].slice(1);
                        root.ethernetDetails = parts[2] === "connected"
                            ? (parts[3] + " · " + parts[0])
                            : "Not connected";
                    }
                }
                if (!ethFound) { root.ethernetEnabled = false; root.ethernetDetails = "No device"; }
            }
        }
    }

    Process {
        id: hotspotStatusProcess
        command: ["bash", "-c", "nmcli -t -f TYPE,STATE,CONNECTION d | grep -i 'wifi:connected' | grep -qi -E 'hotspot' && echo 'on' || echo 'off'"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.hotspotEnabled = text.trim() === "on" }
    }

    Process {
        id: hotspotDetailsProcess
        command: ["bash", "-c", "nmcli -g 802-11-wireless.ssid connection show Hotspot 2>/dev/null || echo 'cupcake-hotspot'"]
        running: true
        stdout: StdioCollector { onStreamFinished: { if (text.trim() !== "") root.hotspotSsid = text.trim() } }
    }

    Process {
        id: localIpProcess
        command: ["bash", "-c", "ip -4 addr show scope global | grep -oP '(?<=inet )\\d+\\.\\d+\\.\\d+\\.\\d+' | head -1"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.localIp = text.trim() || "—" }
    }

    property var savedNetworks: ({})

    Process {
        id: savedNetworksProcess
        command: ["bash", "-c", "nmcli -t -f TYPE,NAME connection show | grep '^802-11-wireless:' | sed 's/^802-11-wireless://'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let s = {};
                if (text) {
                    let lines = text.trim().split("\n");
                    for (let i = 0; i < lines.length; i++) if (lines[i]) s[lines[i]] = true;
                }
                root.savedNetworks = s;
            }
        }
    }

    Process {
        id: forgetProcess
        onExited: {
            savedNetworksProcess.running = true;
            wifiScanProcess.running = true;
        }
    }

    Process {
        id: wifiScanProcess
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
        running: root.wifiRadioEnabled
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                let oldExp = {}, oldPwd = {};
                for (let i = 0; i < wifiModel.count; i++) {
                    const it = wifiModel.get(i);
                    if (it.expanded) { oldExp[it.ssid] = true; oldPwd[it.ssid] = it.password; }
                }
                wifiModel.clear();
                const PLACEHOLDER = "___COLON___";
                const lines = text.trim().split("\n");
                let seen = {};
                for (let i = 0; i < lines.length; i++) {
                    if (!lines[i]) continue;
                    const net = lines[i].replace(/\\:/g, PLACEHOLDER).split(":");
                    const inUse    = net[0] === "yes";
                    const signal   = parseInt(net[1]) || 0;
                    const ssid     = net[3] ? net[3].replace(new RegExp(PLACEHOLDER, "g"), ":") : "";
                    const security = net[5] ? net[5].replace(new RegExp(PLACEHOLDER, "g"), ":") : "";
                    const isSecure = security.length > 0 && security !== "--";
                    const isSaved = !!root.savedNetworks[ssid];
                    if (!ssid || ssid === "--" || ssid === root.hotspotSsid || seen[ssid]) continue;
                    seen[ssid] = true;
                    wifiModel.append({ ssid, inUse, isSecure, isSaved, signal, isOutOfRange: false, expanded: !!oldExp[ssid], password: oldPwd[ssid] || "" });
                }
                for (let savedSsid in root.savedNetworks) {
                    if (!seen[savedSsid] && savedSsid !== root.hotspotSsid) {
                        wifiModel.append({ ssid: savedSsid, inUse: false, isSecure: true, isSaved: true, signal: 0, isOutOfRange: true, expanded: false, password: "" });
                    }
                }
            }
        }
    }

    Process { id: wifiRescanProcess; command: ["nmcli", "device", "wifi", "rescan"] }

    Timer {
        interval: 5000; running: root.visible; repeat: true
        onTriggered: {
            savedNetworksProcess.running = true;
            wifiRadioProcess.running = true;
            wifiDeviceProcess.running = true;
            hotspotStatusProcess.running = true;
            hotspotDetailsProcess.running = true;
            localIpProcess.running = true;
            if (root.wifiRadioEnabled) {
                let anyExpanded = false;
                for (let i = 0; i < wifiModel.count; i++) if (wifiModel.get(i).expanded) { anyExpanded = true; break; }
                if (!anyExpanded) wifiScanProcess.running = true;
            }
        }
    }

    // =========================================================================
    // UI
    // =========================================================================

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            width: parent.width
            spacing: 16

            // ── Status Hero Card ─────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 80
                radius: 14
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, Theme.isDark ? 0.18 : 0.12) }
                    GradientStop { position: 1.0; color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.04) }
                }
                border.color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.25)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 16

                    // Big wifi icon
                    Rectangle {
                        width: 48; height: 48; radius: 12
                        color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.15)
                        Text {
                            anchors.centerIn: parent
                            text: root.wifiRadioEnabled ? "\ueb52" : "\uecfa"
                            font.family: "tabler-icons"
                            font.pixelSize: 24
                            color: cAccent
                        }
                    }

                    ColumnLayout {
                        spacing: 3
                        Text {
                            text: root.wifiRadioEnabled ? root.wifiDeviceState : "Wi-Fi Off"
                            color: cText
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 15
                            font.weight: Font.SemiBold
                        }
                        Text {
                            text: root.localIp !== "" ? "IP: " + root.localIp + "  ·  " + root.wifiDeviceName : root.wifiDeviceName
                            color: cTextDim
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 12
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Rescan button
                    Rectangle {
                        id: rescanBtn
                        property bool scanning: false
                        width: 36; height: 36; radius: 8
                        color: rescanMa.containsMouse ? cSurfaceHover : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.1)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        visible: root.wifiRadioEnabled

                        Timer {
                            id: rescanTimer; interval: 3000; running: false; repeat: false
                            onTriggered: {
                                rescanBtn.scanning = false;
                                wifiDeviceProcess.running = true;
                                wifiScanProcess.running = true;
                                localIpProcess.running = true;
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "\ueb13"
                            font.family: "tabler-icons"
                            font.pixelSize: 16
                            color: rescanBtn.scanning ? cAccent : cTextDim
                            RotationAnimation on rotation {
                                running: rescanBtn.scanning
                                loops: Animation.Infinite; from: 0; to: 360; duration: 900
                            }
                        }
                        MouseArea {
                            id: rescanMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!rescanBtn.scanning) {
                                    rescanBtn.scanning = true;
                                    wifiRescanProcess.running = true;
                                    rescanTimer.running = true;
                                }
                            }
                        }
                    }

                    // Wi-Fi toggle
                    NToggle {
                        id: wifiToggle
                        checked: root.wifiRadioEnabled
                        onToggled: {
                            Quickshell.execDetached(["nmcli", "radio", "wifi", val ? "on" : "off"])
                            root.wifiRadioEnabled = val
                            if (val) { wifiScanProcess.running = true; wifiDeviceProcess.running = true; }
                        }
                    }
                }
            }

            // ── Wi-Fi Networks ───────────────────────────────────────────────
            NCard {
                sectionTitle: "Wi-Fi Networks"
                visible: root.wifiRadioEnabled

                // Connected network(s)
                Repeater {
                    model: wifiModel
                    delegate: Item {
                        visible: model.inUse
                        Layout.fillWidth: true
                        implicitHeight: connRow.implicitHeight + 20

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -2
                            radius: 10
                            color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.07)
                            border.color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.2)
                            border.width: 1
                        }

                        RowLayout {
                            id: connRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 12

                            NIconBadge {
                                icon: "\ueb52"
                                iconColor: cAccent
                                bgColor: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.15)
                            }

                            ColumnLayout {
                                spacing: 2
                                Text { text: model.ssid; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.SemiBold }
                                RowLayout {
                                    spacing: 6
                                    Rectangle {
                                        width: 6; height: 6; radius: 3
                                        color: "#4ade80"
                                    }
                                    Text { text: "Connected"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                                    Text { text: "·"; color: cTextFaint; font.pixelSize: 11 }
                                    Text { text: model.isSecure ? "Secured" : "Open"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Chip
                            Rectangle {
                                height: 22; radius: 6
                                width: chipText.implicitWidth + 16
                                color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.12)
                                Text {
                                    id: chipText
                                    anchors.centerIn: parent
                                    text: model.signal > 66 ? "Excellent" : (model.signal > 33 ? "Good" : "Weak")
                                    color: cAccent
                                    font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Medium
                                }
                            }

                            Rectangle {
                                height: 26; width: disconnectText.implicitWidth + 24; radius: 6
                                color: disconnectMa.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.15) : Qt.rgba(cText.r, cText.g, cText.b, 0.05)
                                border.color: disconnectMa.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.3) : "transparent"
                                border.width: 1
                                Text {
                                    id: disconnectText
                                    anchors.centerIn: parent
                                    text: "Disconnect"
                                    color: disconnectMa.containsMouse ? "#ff8f8f" : cTextDim
                                    font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Medium
                                }
                                MouseArea {
                                    id: disconnectMa
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached(["nmcli", "connection", "down", "id", model.ssid])
                                }
                            }
                        }
                    }
                }

                // Divider after connected
                Rectangle {
                    Layout.fillWidth: true; height: 1; color: cBorder; opacity: 0.6
                    visible: {
                        for (let i = 0; i < wifiModel.count; i++) if (wifiModel.get(i).inUse) return true;
                        return false;
                    }
                }

                // Other networks (in range)
                Repeater {
                    model: wifiModel
                    delegate: ColumnLayout {
                        visible: !model.inUse && !model.isOutOfRange
                        Layout.fillWidth: true
                        spacing: 0

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: otherRow.implicitHeight + 20
                            color: otherMa.containsMouse ? cSurfaceHover : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }
                            radius: 8

                            RowLayout {
                                id: otherRow
                                anchors.left: parent.left; anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 6; anchors.rightMargin: 6
                                spacing: 12

                                NIconBadge {
                                    icon: model.signal > 75 ? "\ueb52" : (model.signal > 40 ? "\ueba5" : (model.signal > 10 ? "\ueba4" : "\ueba3"))
                                    iconColor: cTextDim
                                    bgColor: cBgElevated
                                }
                                ColumnLayout {
                                    spacing: 2
                                    Text { text: model.ssid; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                                    Text { text: model.isSecure ? "Secured" : "Open network"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                                }
                                Item { Layout.fillWidth: true }
                                Rectangle {
                                    visible: model.isSaved
                                    height: 26; width: forgetText.implicitWidth + 24; radius: 6
                                    color: forgetMa.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.15) : Qt.rgba(cText.r, cText.g, cText.b, 0.05)
                                    border.color: forgetMa.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.3) : "transparent"
                                    border.width: 1
                                    Text {
                                        id: forgetText
                                        anchors.centerIn: parent
                                        text: "Forget"
                                        color: forgetMa.containsMouse ? "#ff8f8f" : cTextDim
                                        font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Medium
                                    }
                                    MouseArea {
                                        id: forgetMa
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            forgetProcess.exec(["nmcli", "connection", "delete", "id", model.ssid]);
                                        }
                                    }
                                }
                                Text { visible: !model.isSaved; text: "\uea5f"; font.family: "tabler-icons"; font.pixelSize: 14; color: cTextFaint }
                            }

                            MouseArea {
                                id: otherMa; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (model.expanded) {
                                        wifiModel.setProperty(index, "expanded", false);
                                    } else {
                                        for (let i = 0; i < wifiModel.count; i++) wifiModel.setProperty(i, "expanded", false);
                                        if (!model.isSecure || model.isSaved) { 
                                            Quickshell.execDetached(["nmcli", "connection", "up", model.ssid]); 
                                            wifiScanProcess.running = true; 
                                        } else {
                                            wifiModel.setProperty(index, "expanded", true);
                                        }
                                    }
                                }
                            }
                        }

                        // Password expand
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 48
                            Layout.bottomMargin: 4
                            Layout.preferredHeight: height
                            height: model.expanded ? 48 : 0
                            opacity: model.expanded ? 1 : 0
                            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            clip: true
                            color: "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.topMargin: 4
                                spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true; height: 36; radius: 8
                                    color: cBgElevated
                                    border.color: cBorder; border.width: 1

                                    TextInput {
                                        id: pwdInput
                                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13
                                        echoMode: TextInput.Password; clip: true
                                        text: model.password
                                        onTextChanged: { if (text !== model.password) wifiModel.setProperty(index, "password", text) }
                                    }
                                    Text {
                                        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                                        text: "Password"; color: cTextFaint
                                        font.family: Theme.defaultFontFamily; font.pixelSize: 13
                                        visible: pwdInput.text === ""
                                    }
                                }

                                Rectangle {
                                    width: 80; height: 36; radius: 8
                                    color: cAccent
                                    Text { anchors.centerIn: parent; text: "Connect"; color: "white"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (model.isSecure) Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", model.ssid, "password", model.password]);
                                            else Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", model.ssid]);
                                            wifiModel.setProperty(index, "expanded", false);
                                            wifiScanProcess.running = true;
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 36; height: 36; radius: 8
                                    color: cBgElevated; border.color: cBorder; border.width: 1
                                    Text { anchors.centerIn: parent; text: "\uea76"; font.family: "tabler-icons"; font.pixelSize: 16; color: cTextDim }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: wifiModel.setProperty(index, "expanded", false)
                                    }
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: cBorder; opacity: 0.4 }
                    }
                }

                // MAC Randomization
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: macRow.implicitHeight + 20
                    color: "transparent"
                    RowLayout {
                        id: macRow
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        NIconBadge { icon: "\ueb92"; iconColor: cTextDim; bgColor: cBgElevated }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Disable MAC Randomization"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Fixes connection issues for MediaTek Wi-Fi chips"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                        }
                        Item { Layout.fillWidth: true }
                        NToggle {
                            id: macRandToggle
                            onToggled: {
                                if (val) {
                                    Quickshell.execDetached(["bash", "-c", "echo -e '[device-mac-randomization]\\nwifi.scan-rand-mac-address=no\\n[connection-mac-randomization]\\nwifi.cloned-mac-address=preserve' | pkexec tee /etc/NetworkManager/conf.d/mac-randomization.conf && pkexec systemctl restart NetworkManager"]);
                                } else {
                                    Quickshell.execDetached(["bash", "-c", "pkexec rm -f /etc/NetworkManager/conf.d/mac-randomization.conf && pkexec systemctl restart NetworkManager"]);
                                }
                            }
                        }
                        Process {
                            command: ["bash", "-c", "test -f /etc/NetworkManager/conf.d/mac-randomization.conf && echo 1 || echo 0"]
                            running: true
                            stdout: StdioCollector { onStreamFinished: macRandToggle.checked = text.trim() === "1" }
                        }
                    }
                }

                // Add network
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 44; radius: 8
                    color: addMa.containsMouse ? cSurfaceHover : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; spacing: 8
                        Text { text: "\uea13"; font.family: "tabler-icons"; font.pixelSize: 16; color: cAccent }
                        Text { text: "Add network manually"; color: cAccent; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    }
                    MouseArea { id: addMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                }
            }

            // ── Saved Networks (out of range) ────────────────────────────────
            NCard {
                sectionTitle: "Saved Networks"
                visible: root.wifiRadioEnabled && (function() { for (let i = 0; i < wifiModel.count; i++) if (wifiModel.get(i).isOutOfRange) return true; return false; })()

                Repeater {
                    model: wifiModel
                    delegate: ColumnLayout {
                        visible: model.isOutOfRange
                        Layout.fillWidth: true
                        spacing: 0

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: savedRow.implicitHeight + 20
                            color: savedItemMa.containsMouse ? cSurfaceHover : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }
                            radius: 8

                            RowLayout {
                                id: savedRow
                                anchors.left: parent.left; anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 6; anchors.rightMargin: 6
                                spacing: 12

                                NIconBadge {
                                    icon: "\ueba3"
                                    iconColor: cTextFaint
                                    bgColor: cBgElevated
                                }
                                ColumnLayout {
                                    spacing: 2
                                    Text { text: model.ssid; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                                    Text { text: "Not in range"; color: cTextFaint; font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                                }
                                Item { Layout.fillWidth: true }
                                Rectangle {
                                    height: 26; width: savedForgetText.implicitWidth + 24; radius: 6
                                    color: savedForgetMa.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.15) : Qt.rgba(cText.r, cText.g, cText.b, 0.05)
                                    border.color: savedForgetMa.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.3) : "transparent"
                                    border.width: 1
                                    Text {
                                        id: savedForgetText
                                        anchors.centerIn: parent
                                        text: "Forget"
                                        color: savedForgetMa.containsMouse ? "#ff8f8f" : cTextDim
                                        font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Medium
                                    }
                                    MouseArea {
                                        id: savedForgetMa
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            forgetProcess.exec(["nmcli", "connection", "delete", "id", model.ssid]);
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: savedItemMa; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: cBorder; opacity: 0.4 }
                    }
                }
            }


            NCard {
                sectionTitle: "Wi-Fi"
                visible: !root.wifiRadioEnabled
                Rectangle {
                    Layout.fillWidth: true; height: 64; radius: 10
                    color: cBgElevated
                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 4
                        Text { Layout.alignment: Qt.AlignHCenter; text: "\uecfa"; font.family: "tabler-icons"; font.pixelSize: 22; color: cTextFaint }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Wi-Fi is turned off"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 12 }
                    }
                }
            }

            // ── Ethernet & Hotspot Row ────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                // Ethernet
                NCard {
                    Layout.fillWidth: true
                    sectionTitle: "Ethernet"
                    NRow {
                        NIconBadge {
                            icon: "\uebd9"
                            iconColor: root.ethernetEnabled ? cAccent : cTextDim
                            bgColor: root.ethernetEnabled ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.12) : cBgElevated
                        }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Wired"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: root.ethernetDetails; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                        }
                        Item { Layout.fillWidth: true }
                        NToggle {
                            checked: root.ethernetEnabled
                            onToggled: {
                                const cmd = val
                                    ? ["nmcli", "device", "connect", root.ethernetDeviceName]
                                    : ["nmcli", "device", "disconnect", root.ethernetDeviceName];
                                Quickshell.execDetached(cmd);
                                root.ethernetEnabled = val;
                            }
                        }
                    }
                }

                // Hotspot
                NCard {
                    Layout.fillWidth: true
                    sectionTitle: "Hotspot"
                    NRow {
                        NIconBadge {
                            icon: "\ued1b"
                            iconColor: root.hotspotEnabled ? cAccent : cTextDim
                            bgColor: root.hotspotEnabled ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.12) : cBgElevated
                        }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Mobile Hotspot"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text {
                                text: root.hotspotEnabled ? ("SSID: " + root.hotspotSsid) : "Off"
                                color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11
                            }
                        }
                        Item { Layout.fillWidth: true }
                        NToggle {
                            checked: root.hotspotEnabled
                            onToggled: {
                                if (root.hotspotEnabled) {
                                    Qt.createQmlObject('import Quickshell.Io; Process { command: ["nmcli","connection","down","Hotspot"]; running: true }', root);
                                } else {
                                    Qt.createQmlObject('import Quickshell.Io; Process { command: ["bash","-c","nmcli connection up Hotspot || nmcli device wifi hotspot ssid cupcake-hotspot password cupcake-password"]; running: true }', root);
                                }
                                root.hotspotEnabled = val;
                            }
                        }
                    }
                }
            }

            // ── VPN ───────────────────────────────────────────────────────────
            NCard {
                sectionTitle: "VPN"

                NRow {
                    NIconBadge { icon: "\ued58"; iconColor: cTextDim; bgColor: cBgElevated }
                    ColumnLayout {
                        spacing: 2
                        Text { text: "No VPN configured"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                        Text { text: "Add a VPN to route traffic securely"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        height: 30; radius: 8; width: vpnBtnText.implicitWidth + 20
                        color: vpnBtnMa.containsMouse ? cSurfaceHover : cBgElevated
                        border.color: cBorder; border.width: 1
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text { id: vpnBtnText; anchors.centerIn: parent; text: "Add VPN"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.Medium }
                        MouseArea { id: vpnBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
                    }
                }
            }

            // ── Proxy & DNS & Airplane ─────────────────────────────────────────
            NCard {
                sectionTitle: "Advanced"

                // Proxy
                NRow {
                    NIconBadge { icon: "\ueab9"; iconColor: cTextDim; bgColor: cBgElevated }
                    ColumnLayout {
                        spacing: 2
                        Text { text: "Proxy"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                        Text { text: "Route traffic through a proxy server"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        height: 30; radius: 8; width: 80
                        color: cBgElevated; border.color: cBorder; border.width: 1
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 8
                            Text { text: "Off"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 12; Layout.fillWidth: true }
                            Text { text: "\uea5f"; font.family: "tabler-icons"; font.pixelSize: 13; color: cTextFaint }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
                    }
                }

                // DNS
                NRow {
                    NIconBadge { icon: "\ueab9"; iconColor: cTextDim; bgColor: cBgElevated }
                    ColumnLayout {
                        spacing: 2
                        Text { text: "DNS Server"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                        Text { text: "Override the network-provided DNS"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        height: 30; radius: 8; width: 120
                        color: cBgElevated; border.color: dnsFocus.activeFocus ? cAccent : cBorder; border.width: dnsFocus.activeFocus ? 2 : 1
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                        TextInput {
                            id: dnsFocus
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            verticalAlignment: TextInput.AlignVCenter
                            text: "Automatic"; color: cText
                            font.family: Theme.monoFontFamily; font.pixelSize: 12; clip: true
                            onEditingFinished: {
                                let dns = text.trim() || "Automatic";
                                text = dns;
                                Quickshell.execDetached(["bash", "-c",
                                    'ACTIVE=$(nmcli -t -f NAME,TYPE connection show --active | grep 802-11-wireless | head -n1 | cut -d: -f1); ' +
                                    'if [ -n "$ACTIVE" ]; then ' +
                                    'if [ "' + dns + '" = "Automatic" ]; then nmcli con mod "$ACTIVE" ipv4.ignore-auto-dns no ipv4.dns ""; ' +
                                    'else nmcli con mod "$ACTIVE" ipv4.ignore-auto-dns yes ipv4.dns "' + dns + '"; fi; nmcli con up "$ACTIVE"; fi'
                                ]);
                            }
                        }
                    }
                }

                // Airplane mode
                NRow {
                    NIconBadge { icon: "\ueb6f"; iconColor: cTextDim; bgColor: cBgElevated }
                    ColumnLayout {
                        spacing: 2
                        Text { text: "Airplane Mode"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                        Text { text: "Disable all wireless connections"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: false
                        onToggled: Quickshell.execDetached(["nmcli", "radio", "all", val ? "off" : "on"])
                    }
                }
            }

            Item { Layout.preferredHeight: 24 }
        }
    }
}
