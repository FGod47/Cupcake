import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import "../../theme"
import "../common"
import Quickshell.Services.UPower

Item {
    id: ccUi
    width: 362
    height: 615

    signal requestClose()

    property bool wifiPageOpen: false
    property bool btPageOpen: false
    property bool showWarning: false

    property bool nightActive: false
    property bool airplaneActive: false
    property bool firewallActive: false
    property bool antiflashActive: false

    Process {
        id: nlQuickProc
        command: ["hyprctl", "hyprsunset", "temperature", "3400"]
        running: false
    }
    Process {
        id: nlQuickReset
        command: ["hyprctl", "hyprsunset", "identity"]
        running: false
    }
    function applyNightLightQuick(on) {
        if (on) {
            nlQuickProc.running = false;
            Qt.callLater(function() { nlQuickProc.running = true; });
        } else {
            nlQuickReset.running = false;
            Qt.callLater(function() { nlQuickReset.running = true; });
        }
    }

    Timer {
        id: warningTimer
        interval: 3000
        repeat: false
        onTriggered: ccUi.showWarning = false
    }

    // Colors matching the theme (Catppuccin Mocha)
    property color bgBase: Theme.colBackground
    property color bgMantle: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
    property color bgSurface0: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
    property color bgSurface1: Theme.colSurfaceVariant
    property color textText: Theme.colOnSurface
    property color textSubtext0: Theme.colOnSurfaceVariant
    property color textSubtext1: Theme.colOnSurfaceVariant
    property color colGreen: Theme.colPrimary
    property color colGreenDim: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.20)

    property string uptimeStr: "Up 0m"
    property bool wifiActive: false
    property string wifiSSID: "Disconnected"
    property bool eeActive: false
    property string eeStatus: "Inactive"

    // Background data for WiFi list
    property bool wifiRadioEnabled: false
    property string wifiDeviceName: "Wi-Fi"
    property string wifiDeviceState: wifiActive ? "Connected" : "Disconnected"

    property bool hotspotActive: false

    Process {
        id: hotspotStatusProcess
        command: ["bash", "-c", "nmcli -t -f TYPE,STATE,CONNECTION d | grep -i 'wifi:connected' | grep -qi -E 'hotspot' && echo 'on' || echo 'off'"]
        running: ccUi.ccActive
        stdout: StdioCollector {
            onStreamFinished: {
                hotspotActive = (text.trim() === "on")
            }
        }
    }

    Timer {
        id: hotspotQueryTimer
        interval: 2000
        repeat: false
        onTriggered: hotspotStatusProcess.running = true
    }

    // Bluetooth data
    property bool btRadioEnabled: Bluetooth.defaultAdapter?.enabled ?? false
    property string btConnectedDeviceName: {
        if (!Bluetooth.devices) return ""
        let conn = Bluetooth.devices.values.find(d => d.connected)
        return conn ? conn.name : ""
    }

    property list<var> pairedDevices: {
        if (!Bluetooth.devices) return []
        let arr = Bluetooth.devices.values.filter(d => d.paired)
        arr.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            return (a.name || "").localeCompare(b.name || "")
        })
        return arr
    }

    property list<var> availableDevices: {
        if (!Bluetooth.devices) return []
        let arr = Bluetooth.devices.values.filter(d => !d.paired && d.name)
        arr.sort((a, b) => {
            const macRegex = /^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$/
            const aIsMac = macRegex.test(a.name || "")
            const bIsMac = macRegex.test(b.name || "")
            if (aIsMac !== bIsMac) return aIsMac ? 1 : -1
            return (a.name || "").localeCompare(b.name || "")
        })
        return arr
    }

    function getDeviceIcon(device) {
        let iconName = device.icon || ""
        if (iconName.includes("headset") || iconName.includes("headphones") || iconName.includes("audio"))
            return "\ueabd" // headphones
        if (iconName.includes("phone"))
            return "\uea8a" // mobile
        if (iconName.includes("mouse"))
            return "\ueaf9" // mouse
        if (iconName.includes("keyboard"))
            return "\uebd6" // keyboard
        if (iconName.includes("printer"))
            return "\ueb0e" // printer
        return "\uea37" // default bluetooth
    }

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
        color: "transparent"
        radius: 20
        clip: true

        // =====================================================================
        // PAGE 0: Main Control Center
        // =====================================================================
        Item {
            id: mainCcPage
            anchors.top: parent.top
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            visible: opacity > 0.0
            opacity: (ccUi.wifiPageOpen || ccUi.btPageOpen) ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                // Header Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Item { width: 4 } // Left spacing before clock

                    // Clock + date (top left)
                    ColumnLayout {
                        spacing: 2

                        Text {
                            text: Qt.formatDateTime(new Date(), "hh:mm")
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 42
                            font.weight: Font.Bold
                            color: textText
                        }
                        Text {
                            text: Qt.formatDateTime(new Date(), "dddd · MMM d")
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 12
                            color: textSubtext0
                        }
                    }

                    // Spacer to push uptime and settings to the far right corner
                    Item {
                        Layout.fillWidth: true
                    }

                    // Uptime pill
                    Rectangle {
                        visible: true
                        Layout.preferredHeight: 28
                        Layout.preferredWidth: uptimePillText.contentWidth + 24
                        Layout.alignment: Qt.AlignTop
                        radius: 14
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
                        Text {
                            id: uptimePillText
                            anchors.centerIn: parent
                            text: "\uea70  " + uptimeStr.replace("Up ", "Uptime ")
                            font.family: "tabler-icons, " + Theme.defaultFontFamily
                            color: textSubtext0
                            font.pixelSize: 12
                        }
                    }

                    Item { width: 4 }

                    // Settings Launcher
                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 14
                        Layout.alignment: Qt.AlignTop
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: "\ueb20"
                            font.family: "tabler-icons"
                            color: textSubtext0
                            font.pixelSize: 15
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["quickshell", "-p", Quickshell.env("HOME") + "/.config/quickshell/Settings.qml"])
                                ccUi.requestClose()
                            }
                        }
                    }
                }

                // Clock timer to update every minute
                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: {} // binding on Qt.formatDateTime auto-updates
                }

                // Columns Row (Left: WiFi/BT/Hotspot, Right: Brightness/Volume)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // Left Column (WiFi, BT, Hotspot)
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 220
                        spacing: 12

                        // Wi-Fi
                        Rectangle {
                            id: wifiToggle
                            Layout.fillWidth: true
                            Layout.preferredHeight: 96
                            color: wifiRadioEnabled ? colGreenDim : bgSurface0
                            radius: 20

                            clip: true



                            Column {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 4
                                Text { text: "\ueb52"; color: wifiRadioEnabled ? colGreen : textSubtext0; font.family: "tabler-icons"; font.pixelSize: 18 }
                                Text { text: "Wi-Fi"; color: textText; font.family: Theme.defaultFontFamily; font.pixelSize: 14; font.weight: 700 }
                                Text { text: wifiActive ? wifiSSID : (wifiRadioEnabled ? "Disconnected" : "Disabled"); color: wifiRadioEnabled ? colGreen : textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width - 16 }
                            }

                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: ccUi.wifiPageOpen = true
                            }
                        }

                        // Bluetooth
                        Rectangle {
                            id: btToggle
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            color: btRadioEnabled ? colGreenDim : bgSurface0
                            radius: 20


                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                Rectangle {
                                    width: 36; height: 36; radius: 18
                                    color: btRadioEnabled ? Qt.rgba(colGreen.r, colGreen.g, colGreen.b, 0.2) : Qt.rgba(textSubtext0.r, textSubtext0.g, textSubtext0.b, 0.1)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "\uea37"
                                        color: btRadioEnabled ? colGreen : textSubtext0
                                        font.family: "tabler-icons"
                                        font.pixelSize: 16
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text { text: "Bluetooth"; color: textText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 700 }
                                    Text { text: btConnectedDeviceName !== "" ? btConnectedDeviceName : (btRadioEnabled ? "Enabled" : "Disabled"); color: btRadioEnabled ? colGreen : textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: ccUi.btPageOpen = true
                            }
                        }

                        // Hotspot
                        Rectangle {
                            id: hotspotToggle
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            color: hotspotActive ? colGreenDim : bgSurface0
                            radius: 20


                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                Rectangle {
                                    width: 36; height: 36; radius: 18
                                    color: hotspotActive ? Qt.rgba(colGreen.r, colGreen.g, colGreen.b, 0.2) : Qt.rgba(textSubtext0.r, textSubtext0.g, textSubtext0.b, 0.1)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "\ued1b"
                                        color: hotspotActive ? colGreen : textSubtext0
                                        font.family: "tabler-icons"
                                        font.pixelSize: 16
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text { text: "Hotspot"; color: textText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 700 }
                                    Text { text: hotspotActive ? "Active" : "Off"; color: hotspotActive ? colGreen : textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!wifiRadioEnabled) {
                                        ccUi.showWarning = true
                                        warningTimer.restart()
                                        return
                                    }

                                    if (hotspotActive) {
                                        Quickshell.execDetached(["bash", "-c", "nmcli connection down Hotspot || nmcli connection down hotspot"])
                                    } else {
                                        Quickshell.execDetached(["bash", "-c", "nmcli connection up Hotspot || nmcli connection up hotspot"])
                                    }
                                    hotspotActive = !hotspotActive
                                    hotspotQueryTimer.restart()
                                }
                            }
                        }
                    }

                    // Right card — Power Profile
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 220
                        Layout.preferredHeight: 236
                        color: bgSurface0
                        radius: 20

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 8

                            Item { Layout.fillHeight: true }

                            Text {
                                text: "Power Profile"
                                color: textText
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 15
                                font.weight: 700
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Item { Layout.fillHeight: true }

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 80; height: 80; radius: 40
                                color: PowerProfiles.profile !== PowerProfile.Balanced ? colGreenDim : Qt.rgba(textSubtext0.r, textSubtext0.g, textSubtext0.b, 0.1)

                                Text {
                                    anchors.centerIn: parent
                                    text: switch(PowerProfiles.profile) {
                                        case PowerProfile.PowerSaver: return "\ueb07"
                                        case PowerProfile.Balanced: return "\ueb39"
                                        case PowerProfile.Performance: return "\ueaab"
                                    }
                                    color: PowerProfiles.profile !== PowerProfile.Balanced ? colGreen : textSubtext0
                                    font.family: "tabler-icons"
                                    font.pixelSize: 40
                                }
                            }

                            Item { Layout.fillHeight: true }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: switch(PowerProfiles.profile) {
                                    case PowerProfile.PowerSaver: return "Power Saver"
                                    case PowerProfile.Balanced: return "Balanced"
                                    case PowerProfile.Performance: return "Performance"
                                    default: return "Unknown"
                                }
                                color: PowerProfiles.profile !== PowerProfile.Balanced ? colGreen : textSubtext0
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 13
                                font.weight: 600
                            }
                            
                            Item { Layout.fillHeight: true }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (PowerProfiles.hasPerformanceProfile) {
                                    switch(PowerProfiles.profile) {
                                        case PowerProfile.PowerSaver: PowerProfiles.profile = PowerProfile.Balanced; break;
                                        case PowerProfile.Balanced: PowerProfiles.profile = PowerProfile.Performance; break;
                                        case PowerProfile.Performance: PowerProfiles.profile = PowerProfile.PowerSaver; break;
                                    }
                                } else {
                                    PowerProfiles.profile = PowerProfiles.profile == PowerProfile.Balanced ? PowerProfile.PowerSaver : PowerProfile.Balanced;
                                }
                            }
                        }
                    }
                }

                MusicWidget {}

                // Bottom Row of 5 Quick Toggles
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Night Light
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56

                        Rectangle {
                            anchors.centerIn: parent
                            width: 56; height: 56; radius: 28
                            color: nightActive ? colGreenDim : bgSurface0

                            Text {
                                anchors.centerIn: parent
                                text: "\ueaf8"
                                font.family: "tabler-icons"
                                font.pixelSize: 24
                                color: nightActive ? colGreen : textSubtext0
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    nightActive = !nightActive;
                                    ccUi.applyNightLightQuick(nightActive);
                                }
                            }
                        }
                    }

                    // Firewall
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56

                        Rectangle {
                            anchors.centerIn: parent
                            width: 56; height: 56; radius: 28
                            color: firewallActive ? colGreenDim : bgSurface0

                            Text {
                                anchors.centerIn: parent
                                text: "\uec2c"
                                font.family: "tabler-icons"
                                font.pixelSize: 24
                                color: firewallActive ? colGreen : textSubtext0
                            }
                            MouseArea { anchors.fill: parent; onClicked: firewallActive = !firewallActive }
                        }
                    }

                    // Effects
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56

                        Rectangle {
                            anchors.centerIn: parent
                            width: 56; height: 56; radius: 28
                            color: eeActive ? colGreenDim : bgSurface0

                            Text {
                                anchors.centerIn: parent
                                text: "\uf6d7"
                                font.family: "tabler-icons"
                                font.pixelSize: 24
                                color: eeActive ? colGreen : textSubtext0
                            }
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(eeActive ? "pkill easyeffects" : "easyeffects --daemon") }
                        }
                    }

                    // Anti-flash
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56

                        Rectangle {
                            anchors.centerIn: parent
                            width: 56; height: 56; radius: 28
                            color: antiflashActive ? colGreenDim : bgSurface0

                            Text {
                                anchors.centerIn: parent
                                text: "\uea2e"
                                font.family: "tabler-icons"
                                font.pixelSize: 24
                                color: antiflashActive ? colGreen : textSubtext0
                            }
                            MouseArea { anchors.fill: parent; onClicked: antiflashActive = !antiflashActive }
                        }
                    }

                    // Airplane
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56

                        Rectangle {
                            anchors.centerIn: parent
                            width: 56; height: 56; radius: 28
                            color: airplaneActive ? colGreenDim : bgSurface0

                            Text {
                                anchors.centerIn: parent
                                text: "\ueb6f"
                                font.family: "tabler-icons"
                                font.pixelSize: 24
                                color: airplaneActive ? colGreen : textSubtext0
                            }
                            MouseArea { anchors.fill: parent; onClicked: { airplaneActive = !airplaneActive; Quickshell.execDetached(airplaneActive ? "rfkill block all" : "rfkill unblock all") } }
                        }
                    }
                }

                // Spacing at the bottom of the card
                Item {
                    Layout.preferredHeight: 12
                    Layout.fillWidth: true
                }
            }
        }

        // =====================================================================
        // PAGE 1: Wi-Fi Manager Page
        // =====================================================================
        Item {
            id: wifiCcPage
            anchors.top: parent.top
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 14
            height: 572
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
                                    height: 52
                                    color: model.inUse ? Qt.rgba(colGreen.r, colGreen.g, colGreen.b, 0.12) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                                    radius: 12


                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 14

                                        // Signal Icon
                                        Rectangle {
                                            width: 32; height: 32; radius: 16
                                            color: model.inUse ? colGreen : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
                                            Text {
                                                anchors.centerIn: parent
                                                text: model.inUse ? "\ueb52" : (model.signal > 66 ? "\ueb52" : (model.signal > 33 ? "\ueba5" : "\uecfa"))
                                                color: model.inUse ? Theme.colSurface : textText
                                                font.family: "tabler-icons"
                                                font.pixelSize: 16
                                            }
                                        }

                                        ColumnLayout {
                                            spacing: 2
                                            Layout.fillWidth: true
                                            Text {
                                                text: model.ssid
                                                color: textText
                                                font.family: Theme.defaultFontFamily
                                                font.pixelSize: 14
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

        // =====================================================================
        // PAGE 2: Bluetooth Manager Page
        // =====================================================================
        Item {
            id: btCcPage
            anchors.top: parent.top
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 14
            height: 572
            visible: opacity > 0.0
            opacity: ccUi.btPageOpen ? 1.0 : 0.0
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
                            onClicked: ccUi.btPageOpen = false
                        }
                    }

                    Text {
                        text: "Bluetooth Devices"
                        font.family: Theme.defaultFontFamily
                        font.weight: Font.Bold
                        color: textText
                        font.pixelSize: 14
                        Layout.fillWidth: true
                    }

                    // Rescan/Discovering Button
                    Rectangle {
                        id: btRescanButton
                        width: 28; height: 28; radius: 6
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)

                        Text {
                            anchors.centerIn: parent; text: "\ueb13"
                            color: Bluetooth.defaultAdapter?.discovering ? colGreen : textSubtext0
                            font.family: "tabler-icons"; font.pixelSize: 14
                            RotationAnimation on rotation {
                                running: Bluetooth.defaultAdapter?.discovering ?? false
                                loops: Animation.Infinite
                                from: 0; to: 360
                                duration: 1000
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Bluetooth.defaultAdapter) {
                                    Bluetooth.defaultAdapter.discovering = !Bluetooth.defaultAdapter.discovering
                                }
                            }
                        }
                    }

                    // Bluetooth Power Switch
                    Rectangle {
                        id: btSwitch
                        width: 38; height: 22; radius: height / 2
                        color: btRadioEnabled ? colGreen : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.15)
                        border.width: btRadioEnabled ? 0 : 1
                        border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.1)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Rectangle {
                            width: 18; height: 18; radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            x: btRadioEnabled ? parent.width - width - 2 : 2
                            color: btRadioEnabled ? Theme.colSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.8)
                            Behavior on x { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Bluetooth.defaultAdapter) {
                                    Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                                }
                            }
                        }
                    }
                }

                // Bluetooth Devices List
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: availableWidth

                    ColumnLayout {
                        width: parent.width
                        spacing: 8

                        // Paired Devices Header
                        Text {
                            visible: pairedDevices.length > 0
                            text: "PAIRED"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 0.6
                            color: textSubtext0
                            opacity: 0.6
                        }

                        // Paired Devices List
                        Repeater {
                            model: pairedDevices
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 44
                                color: modelData.connected ? Qt.rgba(colGreen.r, colGreen.g, colGreen.b, 0.12) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                                radius: 12

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 12

                                    Text {
                                        text: ccUi.getDeviceIcon(modelData)
                                        color: modelData.connected ? colGreen : textText
                                        font.family: "tabler-icons"
                                        font.pixelSize: 16
                                    }

                                    ColumnLayout {
                                        spacing: 1
                                        Layout.fillWidth: true
                                        Text {
                                            text: modelData.name || "Unknown device"
                                            color: textText
                                            font.family: Theme.defaultFontFamily
                                            font.pixelSize: 13
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: modelData.connected ? "Connected" : "Paired"
                                            color: modelData.connected ? colGreen : textSubtext0
                                            font.family: Theme.defaultFontFamily
                                            font.pixelSize: 11
                                            opacity: 0.8
                                        }
                                    }

                                    // Action / Disconnect Button
                                    Rectangle {
                                        width: 52; height: 24; radius: 6
                                        color: modelData.connected ? Qt.rgba(Theme.colError.r, Theme.colError.g, Theme.colError.b, 0.12) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.07)
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.connected ? "Disconnect" : "Connect"
                                            color: modelData.connected ? Theme.colError : textSubtext0
                                            font.family: Theme.defaultFontFamily; font.pixelSize: 10; font.weight: Font.Medium
                                        }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData.connected) modelData.disconnect()
                                                else modelData.connect()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true; height: 4; visible: pairedDevices.length > 0 && availableDevices.length > 0 }

                        // Available Devices Header
                        Text {
                            visible: availableDevices.length > 0
                            text: "AVAILABLE"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 0.6
                            color: textSubtext0
                            opacity: 0.6
                        }

                        // Available Devices List
                        Repeater {
                            model: availableDevices
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 44
                                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                                radius: 12

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 12

                                    Text {
                                        text: ccUi.getDeviceIcon(modelData)
                                        color: textText
                                        font.family: "tabler-icons"
                                        font.pixelSize: 16
                                    }

                                    ColumnLayout {
                                        spacing: 1
                                        Layout.fillWidth: true
                                        Text {
                                            text: modelData.name || "Unknown device"
                                            color: textText
                                            font.family: Theme.defaultFontFamily
                                            font.pixelSize: 13
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: "Available"
                                            color: textSubtext0
                                            font.family: Theme.defaultFontFamily
                                            font.pixelSize: 11
                                            opacity: 0.8
                                        }
                                    }

                                    // Action / Connect Button
                                    Rectangle {
                                        width: 52; height: 24; radius: 6
                                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.07)
                                        Text {
                                            anchors.centerIn: parent
                                            text: "Pair"
                                            color: textSubtext0
                                            font.family: Theme.defaultFontFamily; font.pixelSize: 10; font.weight: Font.Medium
                                        }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                modelData.connect()
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
        id: slowTimer
        interval: 10000
        running: ccUi.ccActive
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            updateUptime.running = true
            updateToggles.running = true
            wifiRadioProcess.running = true
            hotspotStatusProcess.running = true
            if (ccUi.wifiPageOpen && wifiRadioEnabled) {
                wifiProcess.running = true
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
        command: ["bash", "-c", "nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes'; pgrep easyeffects"]
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

            eeActive = false;
            eeStatus = "Inactive";
            for (let i=0; i<lines.length; i++) {
                if (lines[i].trim() !== "" && !isNaN(parseInt(lines[i])) && !lines[i].includes("yes:")) {
                    eeActive = true;
                    eeStatus = "Active";
                    break;
                }
            }
        }
    }
}
