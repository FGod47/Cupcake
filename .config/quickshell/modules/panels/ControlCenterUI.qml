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
    property int extraHeight: volSliderBg.isExpanded ? (12 + audioListModel.count * 44) : 0
    property int animatedExtraHeight: extraHeight
    Behavior on animatedExtraHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    
    property int connectionsHeight: volSliderBg.isExpanded ? 64 : 180
    Behavior on connectionsHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    
    height: 660 + Math.max(0, animatedExtraHeight - (180 - connectionsHeight))

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
        // =====================================================================
        // PAGE 0: Main Control Center
        // =====================================================================
        Item {
            id: mainCcPage
            anchors.top: parent.top
            anchors.topMargin: 20
            anchors.left: parent.left
            anchors.leftMargin: 22
            anchors.right: parent.right
            anchors.rightMargin: 22
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            visible: opacity > 0.0
            opacity: (ccUi.wifiPageOpen || ccUi.btPageOpen) ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    
                    ColumnLayout {
                        spacing: -8
                        Layout.leftMargin: 12
                        Layout.topMargin: -8
                        Text {
                            text: Qt.formatDateTime(new Date(), "hh:mm")
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 46
                            font.weight: Font.Medium
                            color: textText
                        }
                        Text {
                            text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: textSubtext0
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        spacing: 8
                        Layout.alignment: Qt.AlignRight | Qt.AlignTop
                        Layout.topMargin: 12
                        
                        // Settings icon
                        Rectangle {
                            Layout.alignment: Qt.AlignRight
                            width: 34; height: 34; radius: 17
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                            Text { anchors.centerIn: parent; text: "\ueb20"; font.family: "tabler-icons"; font.pixelSize: 16; color: textSubtext0 }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { Quickshell.execDetached(["quickshell", "-p", Quickshell.env("HOME") + "/.config/quickshell/Settings.qml"]); ccUi.requestClose() }
                            }
                        }
                    }
                }

                // Connections Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: ccUi.connectionsHeight
                    clip: true
                    radius: 20
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                    
                    Column {
                        opacity: (ccUi.connectionsHeight - 64) / 116
                        visible: opacity > 0
                        anchors.fill: parent
                        
                        // Wi-Fi
                        Item {
                            width: parent.width; height: 60
                            MouseArea { id: wifiRowMa; hoverEnabled: true; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ccUi.wifiPageOpen = true }
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12
                                Rectangle {
                                    width: 32; height: 32; radius: 10
                                    color: wifiRadioEnabled ? Qt.rgba(colGreen.r, colGreen.g, colGreen.b, 0.1) : Qt.rgba(textText.r, textText.g, textText.b, 0.05)
                                    Text { anchors.centerIn: parent; text: "\ueb52"; color: wifiRadioEnabled ? colGreen : textSubtext0; font.family: "tabler-icons"; font.pixelSize: 15 }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 2
                                    Text { text: "Wi-Fi"; color: textText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    Text { text: wifiActive ? wifiSSID : (wifiRadioEnabled ? "Disconnected" : "Disabled"); color: wifiRadioEnabled ? colGreen : textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                                // Soft switch
                                Rectangle {
                                    width: 44; height: 24; radius: 12
                                    color: wifiRadioEnabled ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.15)
                                    border.color: Qt.rgba(1, 1, 1, 0.05); border.width: 1
                                    Behavior on color { ColorAnimation { duration: 250 } }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Quickshell.execDetached(["nmcli", "radio", "wifi", wifiRadioEnabled ? "off" : "on"]); wifiRadioEnabled = !wifiRadioEnabled } }
                                    Rectangle {
                                        property bool isExpanded: wifiRowMa.pressed || wifiRowMa.containsMouse
                                        width: isExpanded ? 20 : 14; height: 14; radius: 7
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: wifiRadioEnabled ? (isExpanded ? 18 : 24) : 6
                                        color: wifiRadioEnabled ? Theme.colOnPrimary : Theme.colBackground
                                        Behavior on color { ColorAnimation { duration: 250 } }
                                        Behavior on x { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
                                        Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
                                    }
                                }
                            }
                            // MouseArea moved to top
                            Rectangle { width: parent.width; height: 1; anchors.bottom: parent.bottom; color: Qt.rgba(textText.r, textText.g, textText.b, 0.06) }
                        }

                        // Bluetooth
                        Item {
                            width: parent.width; height: 60
                            MouseArea { id: btRowMa; hoverEnabled: true; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ccUi.btPageOpen = true }
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12
                                Rectangle {
                                    width: 32; height: 32; radius: 10
                                    color: btRadioEnabled ? Qt.rgba(colGreen.r, colGreen.g, colGreen.b, 0.1) : Qt.rgba(textText.r, textText.g, textText.b, 0.05)
                                    Text { anchors.centerIn: parent; text: "\uea37"; color: btRadioEnabled ? colGreen : textSubtext0; font.family: "tabler-icons"; font.pixelSize: 15 }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 2
                                    Text { text: "Bluetooth"; color: textText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    Text { text: btConnectedDeviceName !== "" ? btConnectedDeviceName : (btRadioEnabled ? "Enabled" : "Disabled"); color: btRadioEnabled ? colGreen : textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                                Rectangle {
                                    width: 44; height: 24; radius: 12
                                    color: btRadioEnabled ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.15)
                                    border.color: Qt.rgba(1, 1, 1, 0.05); border.width: 1
                                    Behavior on color { ColorAnimation { duration: 250 } }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Quickshell.execDetached(["rfkill", btRadioEnabled ? "block" : "unblock", "bluetooth"]); btRadioEnabled = !btRadioEnabled } }
                                    Rectangle {
                                        property bool isExpanded: btRowMa.pressed || btRowMa.containsMouse
                                        width: isExpanded ? 20 : 14; height: 14; radius: 7
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: btRadioEnabled ? (isExpanded ? 18 : 24) : 6
                                        color: btRadioEnabled ? Theme.colOnPrimary : Theme.colBackground
                                        Behavior on color { ColorAnimation { duration: 250 } }
                                        Behavior on x { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
                                        Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
                                    }
                                }
                            }
                            // MouseArea moved to top
                            Rectangle { width: parent.width; height: 1; anchors.bottom: parent.bottom; color: Qt.rgba(textText.r, textText.g, textText.b, 0.06) }
                        }

                        // Hotspot
                        Item {
                            width: parent.width; height: 60
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12
                                Rectangle {
                                    width: 32; height: 32; radius: 10
                                    color: hotspotActive ? Qt.rgba(colGreen.r, colGreen.g, colGreen.b, 0.1) : Qt.rgba(textText.r, textText.g, textText.b, 0.05)
                                    Text { anchors.centerIn: parent; text: "\ued1b"; color: hotspotActive ? colGreen : textSubtext0; font.family: "tabler-icons"; font.pixelSize: 15 }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 2
                                    Text { text: "Hotspot"; color: textText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    Text { text: hotspotActive ? "Active" : "Disabled"; color: hotspotActive ? colGreen : textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                                Rectangle {
                                    width: 44; height: 24; radius: 12
                                    color: hotspotActive ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.15)
                                    border.color: Qt.rgba(1, 1, 1, 0.05); border.width: 1
                                    Behavior on color { ColorAnimation { duration: 250 } }
                                    Rectangle {
                                        property bool isExpanded: hotspotRowMa.pressed || hotspotRowMa.containsMouse
                                        width: isExpanded ? 20 : 14; height: 14; radius: 7
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: hotspotActive ? (isExpanded ? 18 : 24) : 6
                                        color: hotspotActive ? Theme.colOnPrimary : Theme.colBackground
                                        Behavior on color { ColorAnimation { duration: 250 } }
                                        Behavior on x { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
                                        Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
                                    }
                                }
                            }
                            MouseArea { 
                                id: hotspotRowMa; hoverEnabled: true; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!wifiRadioEnabled) { ccUi.showWarning = true; warningTimer.restart(); return; }
                                    if (hotspotActive) { Quickshell.execDetached(["bash", "-c", "nmcli connection down Hotspot || nmcli connection down hotspot"]) }
                                    else { Quickshell.execDetached(["bash", "-c", "nmcli connection up Hotspot || nmcli connection up hotspot"]) }
                                    hotspotActive = !hotspotActive; hotspotQueryTimer.restart()
                                }
                            }
                        }
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12
                        opacity: (180 - ccUi.connectionsHeight) / 116
                        visible: opacity > 0
                        
                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true; radius: 12
                            color: wifiRadioEnabled ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.15) : Qt.rgba(textText.r, textText.g, textText.b, 0.05)
                            border.color: wifiRadioEnabled ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.3) : "transparent"; border.width: 1
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Quickshell.execDetached(["nmcli", "radio", "wifi", wifiRadioEnabled ? "off" : "on"]); wifiRadioEnabled = !wifiRadioEnabled } }
                            Text { anchors.centerIn: parent; text: "\ueb52"; color: wifiRadioEnabled ? Theme.colPrimary : textSubtext0; font.family: "tabler-icons"; font.pixelSize: 20 }
                        }
                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true; radius: 12
                            color: btRadioEnabled ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.15) : Qt.rgba(textText.r, textText.g, textText.b, 0.05)
                            border.color: btRadioEnabled ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.3) : "transparent"; border.width: 1
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Quickshell.execDetached(["rfkill", btRadioEnabled ? "block" : "unblock", "bluetooth"]); btRadioEnabled = !btRadioEnabled } }
                            Text { anchors.centerIn: parent; text: "\uea37"; color: btRadioEnabled ? Theme.colPrimary : textSubtext0; font.family: "tabler-icons"; font.pixelSize: 20 }
                        }
                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true; radius: 12
                            color: hotspotActive ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.15) : Qt.rgba(textText.r, textText.g, textText.b, 0.05)
                            border.color: hotspotActive ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.3) : "transparent"; border.width: 1
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (!wifiRadioEnabled) { ccUi.showWarning = true; warningTimer.restart(); return; } if (hotspotActive) { Quickshell.execDetached(["bash", "-c", "nmcli connection down Hotspot || nmcli connection down hotspot"]) } else { Quickshell.execDetached(["bash", "-c", "nmcli connection up Hotspot || nmcli connection up hotspot"]) } hotspotActive = !hotspotActive; hotspotQueryTimer.restart() } }
                            Text { anchors.centerIn: parent; text: "\ued1b"; color: hotspotActive ? Theme.colPrimary : textSubtext0; font.family: "tabler-icons"; font.pixelSize: 20 }
                        }
                    }
                }

                // Quick Toggles
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 76
                    radius: 38
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 0
                    
                    Repeater {
                        model: [
                            { icon: "\ueaf8", active: nightActive, title: "Night Light", action: function(){ nightActive = !nightActive; ccUi.applyNightLightQuick(nightActive); } },
                            { icon: "\uec2c", active: firewallActive, title: "Firewall", action: function(){ firewallActive = !firewallActive; } },
                            { icon: "\uf6d7", active: eeActive, title: "Effects", action: function(){ Quickshell.execDetached(eeActive ? "pkill easyeffects" : "easyeffects --daemon"); } },
                            { icon: Theme.isDark ? "\ueaf8" : "\ueb17", active: Theme.isDark, title: "Theme", action: function(){ Quickshell.execDetached(["bash", "-c", "echo '" + (Theme.isDark ? "light" : "dark") + "' > ~/.config/cupcake/.color_mode && ~/.local/bin/set-theme"]); } },
                            { icon: "\ueb6f", active: airplaneActive, title: "Airplane Mode", action: function(){ airplaneActive = !airplaneActive; Quickshell.execDetached(airplaneActive ? "rfkill block all" : "rfkill unblock all"); } }
                        ]
                        delegate: Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            
                            Rectangle {
                                anchors.centerIn: parent
                                width: 50; height: 50; radius: 25
                                color: modelData.active ? colGreen : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                                
                                Text { anchors.centerIn: parent; text: modelData.icon; color: modelData.active ? Theme.colBackground : textSubtext0; font.family: "tabler-icons"; font.pixelSize: 18 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: modelData.action() }
                            }
                        }
                    }
                }
                }



                // Power Profile
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 84
                    radius: 20
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                    
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 14; spacing: 10
                        Text { text: "POWER PROFILE"; color: textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 0.6 }
                        
                        Rectangle {
                            id: powerProfileContainer
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            radius: 17
                            color: Qt.rgba(0, 0, 0, 0.12)
                            
                            Rectangle {
                                id: activeProfileIndicator
                                property int margin: 3
                                width: (powerProfileContainer.width / 3) - (margin * 2)
                                height: parent.height - (margin * 2)
                                y: margin
                                
                                x: {
                                    let step = powerProfileContainer.width / 3;
                                    if (PowerProfiles.profile === PowerProfile.PowerSaver) return margin;
                                    if (PowerProfiles.profile === PowerProfile.Balanced) return step + margin;
                                    if (PowerProfiles.profile === PowerProfile.Performance) return (step * 2) + margin;
                                    return step + margin;
                                }
                                
                                radius: height / 2
                                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.15)
                                border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.3)
                                border.width: 1
                                
                                Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            }
                            
                            RowLayout {
                                anchors.fill: parent
                                spacing: 0
                                
                                Repeater {
                                    model: [
                                        { name: "Saver", type: PowerProfile.PowerSaver },
                                        { name: "Balanced", type: PowerProfile.Balanced },
                                        { name: "Performance", type: PowerProfile.Performance }
                                    ]
                                    delegate: Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.name
                                            color: PowerProfiles.profile === modelData.type ? textText : textSubtext0
                                            font.family: Theme.defaultFontFamily
                                            font.pixelSize: 12
                                            font.weight: PowerProfiles.profile === modelData.type ? Font.Bold : Font.DemiBold
                                        }
                                        
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: { PowerProfiles.profile = modelData.type }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }



                // Brightness Slider
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 26
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                    
                    MouseArea { anchors.fill: parent }
                    RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12
                                Text { text: backlightSlider.value < 33 ? "\ueb7d" : (backlightSlider.value < 66 ? "\uea3c" : "\ueb7e"); color: textSubtext0; font.family: "tabler-icons"; font.pixelSize: 16 }
                                
                                Slider {
                                    id: backlightSlider
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    from: 0; to: 100; value: 0
                                    
                                    background: Rectangle {
                                        x: backlightSlider.leftPadding; y: backlightSlider.topPadding + backlightSlider.availableHeight / 2 - height / 2
                                        width: backlightSlider.availableWidth; height: 14; radius: 7
                                        color: Qt.rgba(textText.r, textText.g, textText.b, 0.09)
                                        Rectangle { width: backlightSlider.visualPosition * parent.width; height: parent.height; color: colGreen; radius: 7 }
                                    }
                                    handle: Item {
                                        x: backlightSlider.leftPadding + backlightSlider.visualPosition * (backlightSlider.availableWidth - width)
                                        y: backlightSlider.topPadding + backlightSlider.availableHeight / 2 - height / 2
                                        width: 14; height: 14
                                    }
                                    
                                    Timer {
                                        id: ccDdcTimer
                                        interval: 500; repeat: false
                                        property int targetVal: 100
                                        onTriggered: Quickshell.execDetached(["ddcutil", "setvcp", "10", Math.round(targetVal).toString(), "--noverify"])
                                    }
                                    onMoved: { ccDdcTimer.targetVal = value; ccDdcTimer.restart(); backlightLabel.text = Math.round(value) + "%" }
                                    onPressedChanged: { if (!pressed) { ccDdcTimer.stop(); Quickshell.execDetached(["ddcutil", "setvcp", "10", Math.round(value).toString()]); backlightLabel.text = Math.round(value) + "%" } }
                                }
                                Text { id: backlightLabel; text: "0%"; color: textSubtext0; font.family: Theme.defaultFontFamily; font.weight: Font.Medium; font.pixelSize: 11; Layout.minimumWidth: 28; horizontalAlignment: Text.AlignRight }
                            }
                }
                
                // Volume Slider
                Rectangle {
                    id: volSliderBg
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52 + ccUi.animatedExtraHeight
                    radius: 26
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                    clip: true
                    
                    property bool isExpanded: false
                    property string defaultSink: ""
                    
                    ListModel { id: audioListModel }
                    Process {
                        id: audioLoadProc
                        command: ["bash", "-c", "pactl --format=json list sinks | jq -c 'map({name: .name, description: .description, index: .index})'"]
                        stdout: StdioCollector { id: audioLoadOut }
                        onExited: {
                            audioListModel.clear();
                            try {
                                let sinks = JSON.parse(audioLoadOut.text.trim());
                                for (let i = 0; i < sinks.length; i++) {
                                    audioListModel.append(sinks[i]);
                                }
                            } catch (e) {}
                        }
                    }
                    Process {
                        id: audioDefaultProc
                        command: ["bash", "-c", "pactl --format=json info | jq -r '.default_sink_name'"]
                        stdout: StdioCollector { id: audioDefaultOut }
                        onExited: { volSliderBg.defaultSink = audioDefaultOut.text.trim(); }
                    }
                    onIsExpandedChanged: { if (isExpanded) { audioLoadProc.running = true; audioDefaultProc.running = true; } }
                    
                    RowLayout {
                        id: volSliderRow
                        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                        anchors.margins: 16
                        height: 20
                        spacing: 12
                        
                        Text { text: volumeSlider.value === 0 ? "\uf1c3" : (volumeSlider.value < 50 ? "\ueb4f" : "\ueb51"); color: textSubtext0; font.family: "tabler-icons"; font.pixelSize: 16 }
                        
                        Slider {
                            id: volumeSlider
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            from: 0
                            to: 100
                            value: 0
                            
                            background: Rectangle {
                                x: volumeSlider.leftPadding
                                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                width: volumeSlider.availableWidth
                                height: 14
                                radius: 7
                                color: Qt.rgba(textText.r, textText.g, textText.b, 0.09)
                                Rectangle {
                                    width: volumeSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: colGreen
                                    radius: 7
                                }
                            }
                            handle: Item {
                                x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                width: 14
                                height: 14
                            }
                            
                            Timer {
                                id: ccVolTimer
                                interval: 50
                                repeat: false
                                property int targetVal: 100
                                onTriggered: Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.round(targetVal).toString() + "%"])
                            }
                            onMoved: { ccVolTimer.targetVal = value; ccVolTimer.restart(); volumeLabel.text = Math.round(value) + "%" }
                        }
                        Text { id: volumeLabel; text: "0%"; color: textSubtext0; font.family: Theme.defaultFontFamily; font.weight: Font.Medium; font.pixelSize: 11; Layout.minimumWidth: 28; horizontalAlignment: Text.AlignRight }
                        
                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            width: 24; height: 24; radius: 12
                            color: "transparent"
                            Text { anchors.centerIn: parent; text: "\uea5f"; font.family: "tabler-icons"; font.pixelSize: 16; color: textSubtext0; rotation: volSliderBg.isExpanded ? 90 : 0; Behavior on rotation { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } } }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onEntered: parent.color = Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.1); onExited: parent.color = "transparent"; onClicked: { volSliderBg.isExpanded = !volSliderBg.isExpanded; } }
                        }
                    }
                    
                    Column {
                        anchors.top: volSliderRow.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.topMargin: 16
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 8
                        visible: volSliderBg.isExpanded || opacity > 0.0
                        opacity: volSliderBg.isExpanded ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                        
                        Repeater {
                            model: audioListModel
                            delegate: Rectangle {
                                width: parent.width
                                height: 36
                                radius: 18
                                color: (volSliderBg.defaultSink === model.name) ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.15) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                                
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 10; spacing: 12
                                    Text { text: "\ueb51"; font.family: "tabler-icons"; font.pixelSize: 14; color: (volSliderBg.defaultSink === model.name) ? Theme.colPrimary : textSubtext0 }
                                    Text { text: model.description; color: (volSliderBg.defaultSink === model.name) ? Theme.colPrimary : textText; font.family: Theme.defaultFontFamily; font.weight: Font.Medium; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                }
                                
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: { Quickshell.execDetached(["pactl", "set-default-sink", model.name]); volSliderBg.defaultSink = model.name; volSliderBg.isExpanded = false; }
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                Image {
                    Layout.alignment: Qt.AlignHCenter
                    source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/cupcake-word-" + (Theme.isDark ? "light" : "dark") + ".svg"
                    sourceSize.height: 32
                    height: 32
                    fillMode: Image.PreserveAspectFit
                    opacity: 0.6
                }
            }
        }
        // =====================================================================
        // PAGE 1: Wi-Fi Manager Page
        // =====================================================================
        Rectangle {
            id: wifiCcPage
            anchors.top: parent.top
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 14
            height: 572
            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04)
            radius: 16
            clip: true
            visible: opacity > 0.0
            opacity: ccUi.wifiPageOpen ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Header Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // Back Button
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: wifiBackMa.containsMouse ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "\uea60"
                            font.family: "tabler-icons"
                            color: textSubtext0
                            font.pixelSize: 18
                        }
                        
                        MouseArea {
                            id: wifiBackMa
                            hoverEnabled: true
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

                    Rectangle {
                        width: parent.width
                        implicitHeight: wifiListCol.implicitHeight
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04)
                        radius: 16
                        clip: true

                        ColumnLayout {
                            id: wifiListCol
                            anchors.fill: parent
                            spacing: 0

                            // Network List Repeater
                            Repeater {
                            model: wifiModel
                            delegate: ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 52
                                    color: model.inUse ? Qt.rgba(colGreen.r, colGreen.g, colGreen.b, 0.12) : "transparent"
                                    
                                    Rectangle { anchors.fill: parent; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04); visible: wifiMa.containsMouse && !model.inUse && !model.expanded }


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
                                        id: wifiMa
                                        anchors.fill: parent
                                        hoverEnabled: true
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
                                    Layout.topMargin: 8
                                    Layout.bottomMargin: 12
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
                                
                                // Divider
                                Rectangle {
                                    Layout.fillWidth: true; height: 1
                                    color: Qt.rgba(textText.r, textText.g, textText.b, 0.05)
                                    visible: index < wifiModel.count - 1
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
        Rectangle {
            id: btCcPage
            anchors.top: parent.top
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 14
            height: 572
            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04)
            radius: 16
            clip: true
            visible: opacity > 0.0
            opacity: ccUi.btPageOpen ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Header Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // Back Button
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: btBackMa.containsMouse ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "\uea60"
                            font.family: "tabler-icons"
                            color: textSubtext0
                            font.pixelSize: 18
                        }
                        
                        MouseArea {
                            id: btBackMa
                            hoverEnabled: true
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
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: pairedListCol.implicitHeight
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04)
                            radius: 16
                            clip: true
                            visible: pairedDevices.length > 0
                            ColumnLayout {
                                id: pairedListCol
                                anchors.fill: parent
                                spacing: 0
                                Repeater {
                                    model: pairedDevices
                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        height: 44
                                        color: modelData.connected ? Qt.rgba(colGreen.r, colGreen.g, colGreen.b, 0.12) : "transparent"
                                        Rectangle { anchors.fill: parent; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04); visible: btMa.containsMouse }

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
                                            id: btMa
                                            hoverEnabled: true
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData.connected) modelData.disconnect()
                                                else modelData.connect()
                                            }
                                        }
                                    }
                                    
                                    // Divider
                                    Rectangle {
                                        Layout.fillWidth: true; height: 1
                                        color: Qt.rgba(textText.r, textText.g, textText.b, 0.05)
                                        visible: index < pairedDevices.length - 1
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
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: availListCol.implicitHeight
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04)
                            radius: 16
                            clip: true
                            visible: availableDevices.length > 0
                            ColumnLayout {
                                id: availListCol
                                anchors.fill: parent
                                spacing: 0
                                Repeater {
                                    model: availableDevices
                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        height: 44
                                        color: "transparent"
                                        Rectangle { anchors.fill: parent; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04); visible: btAvailMa.containsMouse }

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
                                            id: btAvailMa
                                            hoverEnabled: true
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                modelData.connect()
                                            }
                                        }
                                    }
                                    
                                    // Divider
                                    Rectangle {
                                        Layout.fillWidth: true; height: 1
                                        color: Qt.rgba(textText.r, textText.g, textText.b, 0.05)
                                        visible: index < availableDevices.length - 1
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

    Timer {
        id: fastSliderTimer
        interval: 1000
        running: ccUi.ccActive
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            updateVolume.running = true
        }
    }

    Process {
        id: updateVolume
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector { id: updateVolumeStdout }
        onExited: {
            if (typeof volumeSlider !== "undefined" && volumeSlider && !volumeSlider.pressed) {
                let text = (updateVolumeStdout.text || "").trim();
                let match = text.match(/Volume:\s+([\d\.]+)/);
                if (match && match[1]) {
                    var vol = Math.round(parseFloat(match[1]) * 100);
                    if (!isNaN(vol)) {
                        volumeSlider.value = vol
                        volumeLabel.text = vol + "%"
                    }
                }
            }
        }
    }

    Process {
        id: updateBrightness
        running: true
        command: ["ddcutil", "getvcp", "10", "--terse"]
        stdout: StdioCollector { id: updateBrightnessStdout }
        onExited: {
            if (typeof backlightSlider !== "undefined" && backlightSlider && !backlightSlider.pressed) {
                let text = (updateBrightnessStdout.text || "");
                let match = text.match(/VCP\s+10\s+[A-Za-z]+\s+(\d+)/);
                if (match && match[1]) {
                    let bright = parseInt(match[1]);
                    if (!isNaN(bright)) {
                        backlightSlider.value = bright
                        backlightLabel.text = bright + "%"
                    }
                }
            }
        }
    }
}
