import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../common"
import "../../../theme"

    Rectangle {
        id: netSplitPill
        y: 10
        property bool menuExpanded: bar.netDropdownOpen
        height: menuExpanded ? (netContentCol.implicitHeight + 28) : 30
        Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutQuart } }

        readonly property real openGap: 16
        readonly property real headerW: networkIconsRow.implicitWidth + 24
        readonly property real expandedW: 240
        property real contentW: menuExpanded ? expandedW : headerW

        x: bar.netDropdownOpen ? (bar.barX + bar.barW - clockSplitPill.contentW - 16 - contentW) : (bar.barX + bar.barW - clockSplitPill.contentW - 16 - contentW)
        width: bar.netDropdownOpen ? contentW : headerW

        Behavior on x     { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }

        radius: menuExpanded ? 16 : 15
        Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        clip: true

        color: bar.pillColor
        border.color: Qt.rgba(1, 1, 1, 0.10)
        border.width: 1

        // Top glass highlight
        Rectangle {
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: 4; anchors.rightMargin: 4
            height: 1; radius: 1
            color: Qt.rgba(1, 1, 1, 0.10)
        }

        opacity: bar.netDropdownOpen ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }

        MouseArea {
            id: netSplitPillMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: (mouseY <= 30) ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (mouse.y <= 30) {
                    if (bar.dropdownOpen) bar.dropdownOpen = false;
                    bar.netDropdownOpen = !bar.netDropdownOpen;
                }
            }
        }

        // Header (shown when closed or in transit)
        Row {
            id: networkIconsRow
            anchors.horizontalCenter: parent.horizontalCenter
            y: (30 - height) / 2
            spacing: 8
            opacity: netSplitPill.menuExpanded ? 0.0 : 1.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250 } }

            Text {
                visible: isHotspot
                text: "\ued1b"
                font.family: fontName
                font.pixelSize: 15
                color: fg
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                visible: isBluetooth
                text: isBluetoothConnected ? "\uecea" : "\uea37"
                font.family: fontName
                font.pixelSize: 15
                color: fg
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                visible: isWired
                text: "\uebd9"
                font.family: fontName
                font.pixelSize: 15
                color: fg
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                visible: isWifi && !isWired && !isHotspot
                text: "\ueb52"
                font.family: fontName
                font.pixelSize: 15
                color: fg
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                visible: isWifi || isWired || isBluetooth || isHotspot
                text: "•"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 15
                font.weight: Theme.defaultFontWeight
                color: Qt.rgba(fg.r, fg.g, fg.b, 0.4)
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: netStr
                font.family: Theme.defaultFontFamily
                font.pixelSize: 13
                font.weight: Theme.defaultFontWeight
                color: Qt.rgba(fg.r, fg.g, fg.b, 0.7)
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Expanded View Content
        ColumnLayout {
            id: netContentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 12
            opacity: netSplitPill.menuExpanded ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 300 } }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: isWifi ? "\ueb52" : (isWired ? "\uebd9" : "\uea37")
                    font.family: fontName
                    font.pixelSize: 18
                    color: bar.fg
                    Layout.alignment: Qt.AlignVCenter
                }

                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Text {
                        text: isWifi ? "Wi-Fi Network" : (isWired ? "Ethernet" : "Network")
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: bar.fg
                    }
                    Text {
                        text: netStr + " speed"
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 11
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.1)
            }

            Column {
                Layout.fillWidth: true
                spacing: 4

                // Wi-Fi Toggle List Item
                Item {
                    width: parent.width; height: 40
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 10
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            MouseArea {
                                id: wifiRowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached(["hyprctl", "dispatch", "exec", "[float] quickshell -c " + homeDir + "/.config/quickshell/Settings.qml"]);
                                    bar.netDropdownOpen = false;
                                }
                            }
                            RowLayout {
                                anchors.fill: parent
                                spacing: 10
                                Rectangle {
                                    width: 28; height: 28; radius: 8
                                    color: isWifi ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.1) : Qt.rgba(1, 1, 1, 0.05)
                                    Text { anchors.centerIn: parent; text: "\ueb52"; color: isWifi ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5); font.family: fontName; font.pixelSize: 13 }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 0
                                    Text { text: "Wi-Fi"; color: bar.fg; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.DemiBold }
                                    Text { text: isWifi ? "Connected" : "Disconnected"; color: isWifi ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5); font.family: Theme.defaultFontFamily; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                            }
                        }
                        Rectangle {
                            width: 36; height: 20; radius: 10
                            color: isWifi ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.15)
                            border.color: Qt.rgba(1, 1, 1, 0.05); border.width: 1
                            Behavior on color { ColorAnimation { duration: 250 } }
                            MouseArea {
                                id: wifiToggleMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    bar.isWifi = !bar.isWifi;
                                    Quickshell.execDetached(["bash", "-c", "if [ \"$(nmcli radio wifi)\" = \"enabled\" ]; then nmcli radio wifi off; else nmcli radio wifi on; fi"]);
                                    if (typeof bar.refreshNetworkStatus === "function") bar.refreshNetworkStatus();
                                }
                            }
                            Rectangle {
                                property bool isExpanded: wifiToggleMa.pressed || wifiToggleMa.containsMouse
                                width: isExpanded ? 16 : 12; height: 12; radius: 6
                                anchors.verticalCenter: parent.verticalCenter
                                x: isWifi ? (isExpanded ? 16 : 20) : 4
                                color: isWifi ? Theme.colOnPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                                Behavior on color { ColorAnimation { duration: 250 } }
                                Behavior on x { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
                                Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
                            }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.06) }

                // Bluetooth Toggle List Item
                Item {
                    width: parent.width; height: 40
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 10
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            MouseArea {
                                id: btRowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached(["hyprctl", "dispatch", "exec", "[float] quickshell -c " + homeDir + "/.config/quickshell/Settings.qml"]);
                                    bar.netDropdownOpen = false;
                                }
                            }
                            RowLayout {
                                anchors.fill: parent
                                spacing: 10
                                Rectangle {
                                    width: 28; height: 28; radius: 8
                                    color: isBluetooth ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.1) : Qt.rgba(1, 1, 1, 0.05)
                                    Text { anchors.centerIn: parent; text: isBluetoothConnected ? "\uecea" : "\uea37"; color: isBluetooth ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5); font.family: fontName; font.pixelSize: 13 }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 0
                                    Text { text: "Bluetooth"; color: bar.fg; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.DemiBold }
                                    Text { text: isBluetoothConnected ? "Connected" : (isBluetooth ? "Enabled" : "Disabled"); color: isBluetooth ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5); font.family: Theme.defaultFontFamily; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                            }
                        }
                        Rectangle {
                            width: 36; height: 20; radius: 10
                            color: isBluetooth ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.15)
                            border.color: Qt.rgba(1, 1, 1, 0.05); border.width: 1
                            Behavior on color { ColorAnimation { duration: 250 } }
                            MouseArea {
                                id: btToggleMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    bar.isBluetooth = !bar.isBluetooth;
                                    Quickshell.execDetached(["bash", "-c", "if rfkill list bluetooth | grep -q 'Soft blocked: yes'; then rfkill unblock bluetooth; bluetoothctl power on; else rfkill block bluetooth; bluetoothctl power off; fi"]);
                                    if (typeof bar.refreshNetworkStatus === "function") bar.refreshNetworkStatus();
                                }
                            }
                            Rectangle {
                                property bool isExpanded: btToggleMa.pressed || btToggleMa.containsMouse
                                width: isExpanded ? 16 : 12; height: 12; radius: 6
                                anchors.verticalCenter: parent.verticalCenter
                                x: isBluetooth ? (isExpanded ? 16 : 20) : 4
                                color: isBluetooth ? Theme.colOnPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                                Behavior on color { ColorAnimation { duration: 250 } }
                                Behavior on x { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
                                Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
                            }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.06) }

                // Hotspot Toggle List Item
                Item {
                    width: parent.width; height: 40
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 10
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            MouseArea {
                                id: hotspotRowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached(["hyprctl", "dispatch", "exec", "[float] quickshell -c " + homeDir + "/.config/quickshell/Settings.qml"]);
                                    bar.netDropdownOpen = false;
                                }
                            }
                            RowLayout {
                                anchors.fill: parent
                                spacing: 10
                                Rectangle {
                                    width: 28; height: 28; radius: 8
                                    color: isHotspot ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.1) : Qt.rgba(1, 1, 1, 0.05)
                                    Text { anchors.centerIn: parent; text: "\ued1b"; color: isHotspot ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5); font.family: fontName; font.pixelSize: 13 }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 0
                                    Text { text: "Hotspot"; color: bar.fg; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.DemiBold }
                                    Text { text: isHotspot ? "Active" : "Disabled"; color: isHotspot ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5); font.family: Theme.defaultFontFamily; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                            }
                        }
                        Rectangle {
                            width: 36; height: 20; radius: 10
                            color: isHotspot ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.15)
                            border.color: Qt.rgba(1, 1, 1, 0.05); border.width: 1
                            Behavior on color { ColorAnimation { duration: 250 } }
                            MouseArea {
                                id: hotspotToggleMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    bar.isHotspot = !bar.isHotspot;
                                    Quickshell.execDetached(["bash", "-c", "if nmcli con show --active | grep -qi hotspot; then nmcli con down Hotspot; else nmcli con up Hotspot; fi"]);
                                    if (typeof bar.refreshNetworkStatus === "function") bar.refreshNetworkStatus();
                                }
                            }
                            Rectangle {
                                property bool isExpanded: hotspotToggleMa.pressed || hotspotToggleMa.containsMouse
                                width: isExpanded ? 16 : 12; height: 12; radius: 6
                                anchors.verticalCenter: parent.verticalCenter
                                x: isHotspot ? (isExpanded ? 16 : 20) : 4
                                color: isHotspot ? Theme.colOnPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                                Behavior on color { ColorAnimation { duration: 250 } }
                                Behavior on x { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
                                Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8
                    color: navMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.08)
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "\ueb2d"
                            font.family: fontName
                            font.pixelSize: 14
                            color: bar.fg
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Network Settings"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: bar.fg
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: navMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            bar.netDropdownOpen = false;
                            Quickshell.execDetached(["hyprctl", "dispatch", "exec", "[float] quickshell -c " + homeDir + "/.config/quickshell/Settings.qml"]);
                        }
                    }
                }
            }
        }
    }
