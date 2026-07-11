import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../theme"
import "../common"

Item {
    id: ccUi
    width: 362
    height: wifiPageOpen ? 420 : 330

    Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

    signal requestClose()

    property bool wifiPageOpen: false

    // Colors matching the theme (Catppuccin Mocha)
    property color bgBase: Theme.colBackground
    property color bgMantle: Qt.rgba(Theme.colSurfaceContainer.r, Theme.colSurfaceContainer.g, Theme.colSurfaceContainer.b, 0.60)
    property color bgSurface0: Qt.rgba(Theme.colSurfaceContainerHigh.r, Theme.colSurfaceContainerHigh.g, Theme.colSurfaceContainerHigh.b, 0.45)
    property color bgSurface1: Theme.colSurfaceVariant
    property color textText: Theme.colOnSurface
    property color textSubtext0: Theme.colOnSurfaceVariant
    property color textSubtext1: Theme.colOnSurfaceVariant
    property color colGreen: Theme.colPrimary
    property color colGreenDim: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.20)

    property string uptimeStr: "Up 0m"
    property bool wifiActive: false
    property string wifiSSID: "Disconnected"
    property bool btActive: false
    property string btDevice: "Not connected"
    property bool eeActive: false
    property string eeStatus: "Inactive"

    // Background data for WiFi list
    property bool wifiRadioEnabled: false
    property string wifiDeviceName: "Wi-Fi"
    property string wifiDeviceState: wifiActive ? "Connected" : "Disconnected"

    Process {
        id: wifiRadioProcess
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        running: ccUi.visible
        stdout: StdioCollector {
            onStreamFinished: {
                wifiRadioEnabled = (text.trim() === "enabled")
            }
        }
    }

    Rectangle {
        id: controlsCard
        anchors.fill: parent
        color: bgMantle
        radius: 20

        // =====================================================================
        // PAGE 0: Main Control Center
        // =====================================================================
        Item {
            id: mainCcPage
            anchors.fill: parent
            anchors.margins: 14
            visible: opacity > 0.0
            opacity: ccUi.wifiPageOpen ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                spacing: 16

                // Header Row
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "\uea70  " + uptimeStr
                        font.family: "tabler-icons, " + Theme.defaultFontFamily
                        color: textSubtext0
                        font.pixelSize: 13
                        Layout.fillWidth: true
                    }

                    Row {
                        spacing: 16

                        // Settings Launcher
                        Text {
                            text: "\ueb20"
                            font.family: "tabler-icons"
                            color: textSubtext0
                            font.pixelSize: 16
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached("quickshell -p ~/.config/quickshell/Settings.qml")
                                    ccUi.requestClose()
                                }
                            }
                        }
                    }
                }

                // Sliders Row
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // Brightness Slider
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Text { text: "\uec4e"; font.family: "tabler-icons"; color: textSubtext0; font.pixelSize: 16 }
                        Slider {
                            id: backlightSlider
                            Layout.fillWidth: true
                            from: 0; to: 100; value: 69

                            background: Rectangle {
                                x: backlightSlider.leftPadding
                                y: backlightSlider.topPadding + backlightSlider.availableHeight / 2 - height / 2
                                width: backlightSlider.availableWidth
                                height: 5
                                radius: 2.5
                                color: bgSurface1
                                Rectangle {
                                    width: backlightSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: colGreen
                                    radius: 2.5
                                }
                            }
                            handle: Rectangle {
                                x: backlightSlider.leftPadding + backlightSlider.visualPosition * (backlightSlider.availableWidth - width)
                                y: backlightSlider.topPadding + backlightSlider.availableHeight / 2 - height / 2
                                width: 14; height: 14; radius: 7
                                color: "#ffffff"
                            }

                            Timer {
                                id: ddcTimer
                                interval: 150; repeat: false
                                property int targetValue: 100
                                onTriggered: Quickshell.execDetached(["ddcutil", "setvcp", "10", Math.round(targetValue).toString(), "--noverify"])
                            }
                            onMoved: { ddcTimer.targetValue = value; ddcTimer.restart() }
                            onPressedChanged: { if (!pressed) { ddcTimer.stop(); Quickshell.execDetached(["ddcutil", "setvcp", "10", Math.round(value).toString()]) } }
                        }
                        Text { text: Math.round(backlightSlider.value) + "%"; color: textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 12; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight }
                        Text { text: "\ueb30"; font.family: "tabler-icons"; color: textSubtext0; font.pixelSize: 16 }
                    }

                    // Volume Slider
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Text { text: "\uf1c3"; font.family: "tabler-icons"; color: textSubtext0; font.pixelSize: 16 }
                        Slider {
                            id: volumeSlider
                            Layout.fillWidth: true
                            from: 0; to: 100; value: 45

                            background: Rectangle {
                                x: volumeSlider.leftPadding
                                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                width: volumeSlider.availableWidth
                                height: 5
                                radius: 2.5
                                color: bgSurface1
                                Rectangle {
                                    width: volumeSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: colGreen
                                    radius: 2.5
                                }
                            }
                            handle: Rectangle {
                                x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                width: 14; height: 14; radius: 7
                                color: "#ffffff"
                            }

                            onMoved: Quickshell.execDetached(`pamixer --set-volume ${Math.round(value)}`)
                        }
                        Text { text: Math.round(volumeSlider.value) + "%"; color: textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 12; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight }
                        Text { text: "\ueb51"; font.family: "tabler-icons"; color: textSubtext0; font.pixelSize: 16 }
                    }
                }

                // Toggles Grid
                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    rowSpacing: 10
                    columnSpacing: 10

                    Rectangle {
                        id: wifiToggle
                        Layout.fillWidth: true; Layout.preferredHeight: 82
                        color: wifiRadioEnabled ? colGreenDim : bgSurface0
                        radius: 16
                        border.color: wifiRadioEnabled ? colGreen : bgSurface1
                        border.width: 1

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            Text { text: "\ueb52"; color: wifiRadioEnabled ? colGreen : textSubtext0; font.family: "tabler-icons"; font.pixelSize: 16 }
                            Text { text: "Wi-Fi"; color: textText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 700 }
                            Text { text: wifiActive ? wifiSSID : (wifiRadioEnabled ? "Disconnected" : "Disabled"); color: wifiRadioEnabled ? colGreen : textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                ccUi.wifiPageOpen = true
                                wifiPageDelayTimer.restart()
                            }
                        }
                    }

                    // Bluetooth Toggle
                    Rectangle {
                        id: btToggle
                        Layout.fillWidth: true; Layout.preferredHeight: 82
                        color: btActive ? colGreenDim : bgSurface0
                        radius: 16
                        border.color: btActive ? colGreen : bgSurface1
                        border.width: 1

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            Text { text: "\uea37"; color: btActive ? colGreen : textSubtext0; font.family: "tabler-icons"; font.pixelSize: 16 }
                            Text { text: "Bluetooth"; color: textText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 700 }
                            Text { text: btDevice; color: btActive ? colGreen : textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(btActive ? "bluetoothctl power off" : "bluetoothctl power on")
                        }
                    }

                    // EasyEffects Toggle
                    Rectangle {
                        id: eeToggle
                        Layout.fillWidth: true; Layout.preferredHeight: 82
                        color: eeActive ? colGreenDim : bgSurface0
                        radius: 16
                        border.color: eeActive ? colGreen : bgSurface1
                        border.width: 1

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            Text { text: "\uf6d7"; color: eeActive ? colGreen : textSubtext0; font.family: "tabler-icons"; font.pixelSize: 16 }
                            Text { text: "EasyEffects"; color: textText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 700 }
                            Text { text: eeStatus; color: eeActive ? colGreen : textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(eeActive ? "pkill easyeffects" : "easyeffects --daemon")
                        }
                    }

                    // Firewall Toggle
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 82
                        color: bgSurface0
                        radius: 16
                        border.color: bgSurface1
                        border.width: 1

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            Text { text: "\uec2c"; color: textSubtext0; font.family: "tabler-icons"; font.pixelSize: 16 }
                            Text { text: "Firewall"; color: textText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 700 }
                            Text { text: "Inactive"; color: textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                        }
                    }

                    // Cast Toggle
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 82
                        color: bgSurface0
                        radius: 16
                        border.color: bgSurface1
                        border.width: 1

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            Text { text: "\uea56"; color: textSubtext0; font.family: "tabler-icons"; font.pixelSize: 16 }
                            Text { text: "Cast"; color: textText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 700 }
                            Text { text: "Inactive"; color: textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                        }
                    }

                    // Anti-flash Toggle
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 82
                        color: bgSurface0
                        radius: 16
                        border.color: bgSurface1
                        border.width: 1

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            Text { text: "\uea2e"; color: textSubtext0; font.family: "tabler-icons"; font.pixelSize: 16 }
                            Text { text: "Anti-flash"; color: textText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 700 }
                            Text { text: "Inactive"; color: textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // PAGE 1: Wi-Fi Manager Page
        // =====================================================================
        Item {
            id: wifiCcPage
            anchors.fill: parent
            anchors.margins: 14
            visible: opacity > 0.0
            opacity: ccUi.wifiPageOpen ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                // Header Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // Back Button
                    Text {
                        text: "\uea60"
                        font.family: "tabler-icons"
                        color: textSubtext0
                        font.pixelSize: 18
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: ccUi.wifiPageOpen = false
                        }
                    }

                    Text {
                        text: "Wi-Fi Networks"
                        font.family: Theme.defaultFontFamily
                        font.weight: Font.Bold
                        color: textText
                        font.pixelSize: 14
                        Layout.fillWidth: true
                    }

                    // Rescan Button
                    Rectangle {
                        id: wifiRescanButton
                        property bool isScanning: false
                        width: 28; height: 28; radius: 6
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)

                        Timer {
                            id: wifiRescanTimer
                            interval: 3000
                            running: false
                            repeat: false
                            onTriggered: {
                                wifiRescanButton.isScanning = false;
                                wifiProcess.running = true;
                            }
                        }

                        Text {
                            anchors.centerIn: parent; text: "\ueb13"
                            color: wifiRescanButton.isScanning ? colGreen : textSubtext0
                            font.family: "tabler-icons"; font.pixelSize: 14
                            RotationAnimation on rotation {
                                running: wifiRescanButton.isScanning
                                loops: Animation.Infinite
                                from: 0; to: 360
                                duration: 1000
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!wifiRescanButton.isScanning) {
                                    wifiRescanButton.isScanning = true;
                                    wifiRescanProcess.running = true;
                                    wifiRescanTimer.running = true;
                                }
                            }
                        }
                    }

                    // WiFi Power Switch
                    Rectangle {
                        id: wifiSwitch
                        width: 38; height: 22; radius: height / 2
                        color: wifiRadioEnabled ? colGreen : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.15)
                        border.width: wifiRadioEnabled ? 0 : 1
                        border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.1)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Rectangle {
                            width: 18; height: 18; radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            x: wifiRadioEnabled ? parent.width - width - 2 : 2
                            color: wifiRadioEnabled ? Theme.colSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.8)
                            Behavior on x { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                wifiRadioEnabled = !wifiRadioEnabled
                                Quickshell.execDetached(["nmcli", "radio", "wifi", wifiRadioEnabled ? "on" : "off"])
                                if (wifiRadioEnabled) { wifiProcess.running = true; }
                            }
                        }
                    }
                }

                // WiFi List
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: availableWidth

                    ColumnLayout {
                        width: parent.width
                        spacing: 8

                        // Network List Repeater
                        Repeater {
                            model: wifiModel
                            delegate: ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 44
                                    color: model.inUse ? Qt.rgba(colGreen.r, colGreen.g, colGreen.b, 0.12) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                                    radius: 12
                                    border.color: model.inUse ? colGreen : "transparent"
                                    border.width: model.inUse ? 1 : 0

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 12

                                        // Signal Icon
                                        Text {
                                            text: model.signal > 66 ? "\ueb52" : (model.signal > 33 ? "\ueba5" : "\uecfa")
                                            color: model.inUse ? colGreen : textText
                                            font.family: "tabler-icons"
                                            font.pixelSize: 16
                                        }

                                        ColumnLayout {
                                            spacing: 1
                                            Layout.fillWidth: true
                                            Text {
                                                text: model.ssid
                                                color: textText
                                                font.family: Theme.defaultFontFamily
                                                font.pixelSize: 13
                                                font.weight: Font.Medium
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                text: model.inUse ? "Connected" : (model.isSecure ? "Secured" : "Open")
                                                color: model.inUse ? colGreen : textSubtext0
                                                font.family: Theme.defaultFontFamily
                                                font.pixelSize: 11
                                                opacity: 0.8
                                            }
                                        }

                                        // Secured Icon
                                        Text {
                                            visible: model.isSecure && !model.inUse
                                            text: "\ueae2"
                                            color: textSubtext0
                                            font.family: "tabler-icons"
                                            font.pixelSize: 14
                                            opacity: 0.5
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: !model.inUse && !model.expanded
                                        onClicked: {
                                            for (let i = 0; i < wifiModel.count; i++) wifiModel.setProperty(i, "expanded", false);
                                            if (!model.isSecure) {
                                                Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", model.ssid]);
                                                wifiProcess.running = true;
                                            } else {
                                                wifiModel.setProperty(index, "expanded", true);
                                            }
                                        }
                                    }
                                }

                                // Expanded password row
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 8
                                    Layout.rightMargin: 8
                                    spacing: 8
                                    visible: model.expanded

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 34
                                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                                        radius: 8
                                        border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.12)
                                        border.width: 1

                                        TextInput {
                                            id: pwdIn
                                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                            verticalAlignment: TextInput.AlignVCenter
                                            color: textText
                                            font.family: Theme.defaultFontFamily
                                            font.pixelSize: 12
                                            echoMode: TextInput.Password
                                            clip: true
                                            text: model.password
                                            onTextChanged: {
                                                if (text !== model.password) {
                                                    wifiModel.setProperty(index, "password", text)
                                                }
                                            }
                                        }
                                        Text {
                                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                            text: "Password..."
                                            color: textSubtext0
                                            font.family: Theme.defaultFontFamily
                                            font.pixelSize: 12
                                            opacity: 0.5
                                            visible: pwdIn.text === ""
                                        }
                                    }

                                    Rectangle {
                                        width: 76; height: 34; radius: 8
                                        color: colGreen
                                        Text { anchors.centerIn: parent; text: "Connect"; color: Theme.colBackground; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.Medium }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", model.ssid, "password", model.password]);
                                                wifiModel.setProperty(index, "expanded", false);
                                                wifiProcess.running = true;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // WiFi scanner model & processes
    ListModel { id: wifiModel }

    Process {
        id: wifiProcess
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,SSID,SECURITY", "d", "w"]
        running: ccUi.wifiPageOpen && wifiRadioEnabled
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
                const lines = textStr.split("\n");
                let seen = {};
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];
                    if (line === "") continue;
                    const net      = line.split(":");
                    const inUse    = net[0] === "yes";
                    const signal   = parseInt(net[1]) || 0;
                    const ssid     = net[2] || "";
                    const security = net[3] || "";
                    const isSecure = security.length > 0 && security !== "--";
                    if (ssid === "" || ssid === "--") continue;
                    if (seen[ssid]) continue;
                    seen[ssid] = true;

                    const isExpanded = oldExpanded[ssid] ? true : false;
                    const savedPwd = oldPasswords[ssid] ? oldPasswords[ssid] : "";
                    wifiModel.append({ ssid, inUse, isSecure, signal, expanded: isExpanded, password: savedPwd });
                }
            }
        }
    }

    Process {
        id: wifiRescanProcess
        command: ["nmcli", "device", "wifi", "rescan"]
    }

    onWifiRadioEnabledChanged: {
        if (wifiRadioEnabled && ccUi.wifiPageOpen) {
            wifiProcess.running = true
        }
    }

    property bool ccActive: false

    Timer {
        id: activationDelay
        interval: 650
        running: ccUi.visible
        repeat: false
        onTriggered: ccActive = true
    }

    onVisibleChanged: {
        if (!visible) {
            ccActive = false
            activationDelay.stop()
        }
    }

    Timer {
        id: wifiPageDelayTimer
        interval: 420
        repeat: false
        onTriggered: {
            if (ccUi.wifiPageOpen && wifiRadioEnabled) {
                wifiProcess.running = true
            }
        }
    }

    Timer {
        id: slowTimer
        interval: 10000
        running: ccUi.ccActive
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            updateUptime.running = true
            updateToggles.running = true
            wifiRadioProcess.running = true
            if (ccUi.wifiPageOpen && wifiRadioEnabled) {
                wifiProcess.running = true
            }
        }
    }

    Timer {
        id: fastTimer
        interval: 3000
        running: ccUi.ccActive
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            updateVolume.running = true
            updateBrightness.running = true
        }
    }

    Process {
        id: updateVolume
        command: ["pamixer", "--get-volume"]
        stdout: StdioCollector { id: updateVolumeStdout }
        onExited: {
            if (!volumeSlider.pressed) {
                var vol = parseInt((updateVolumeStdout.text || "").trim())
                if (!isNaN(vol)) volumeSlider.value = vol
            }
        }
    }

    Process {
        id: updateBrightness
        command: ["ddcutil", "getvcp", "10", "--terse"]
        stdout: StdioCollector { id: updateBrightnessStdout }
        onExited: {
            if (!backlightSlider.pressed) {
                let match = (updateBrightnessStdout.text || "").match(/VCP\s+10\s+[A-Za-z]+\s+(\d+)/);
                if (match && match[1]) {
                    let bright = parseInt(match[1]);
                    if (!isNaN(bright)) backlightSlider.value = bright
                }
            }
        }
    }

    Process {
        id: updateUptime
        command: ["uptime", "-p"]
        stdout: StdioCollector { id: uptimeStdout }
        onExited: {
            let clean = (uptimeStdout.text || "").trim();
            clean = clean.replace("up ", "");
            clean = clean.replace(" hours", "h").replace(" hour", "h");
            clean = clean.replace(" minutes", "m").replace(" minute", "m");
            clean = clean.replace(",", "");
            uptimeStr = "Up " + clean;
        }
    }

    Process {
        id: updateToggles
        command: ["bash", "-c", "nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes'; bluetoothctl show | grep 'Powered:'; pgrep easyeffects"]
        stdout: StdioCollector { id: togglesStdout }
        onExited: {
            let lines = (togglesStdout.text || "").split("\n");

            wifiActive = false;
            wifiSSID = "Disconnected";
            for (let i=0; i<lines.length; i++) {
                if (lines[i].startsWith("yes:")) {
                    wifiActive = true;
                    wifiSSID = lines[i].split(":")[1] || "Connected";
                    break;
                }
            }

            btActive = false;
            btDevice = "Not connected";
            for (let i=0; i<lines.length; i++) {
                if (lines[i].includes("Powered: yes")) {
                    btActive = true;
                    btDevice = "Enabled";
                    break;
                }
            }

            eeActive = false;
            eeStatus = "Inactive";
            for (let i=0; i<lines.length; i++) {
                if (lines[i].trim() !== "" && !isNaN(parseInt(lines[i])) && !lines[i].includes("Powered") && !lines[i].includes("yes:")) {
                    eeActive = true;
                    eeStatus = "Active";
                    break;
                }
            }
        }
    }
}
