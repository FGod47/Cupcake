import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "../../theme"
import "../common"

Item {
    id: root
    
    // Battery State
    property string batteryPercent: "Unknown"
    property string batteryStatus: "Unknown"
    property int batteryValue: 0
    property bool hasBattery: false
    
    // Mock settings
    property string powerMode: "balanced"
    property bool autoBrightness: true
    property bool wifiStandby: true
    property bool suspendLid: false
    property string screenTimeout: "5 min"

    Process {
        id: batCommand
        command: ["bash", "-c", "bat=$(ls /sys/class/power_supply | grep -i bat | head -n 1); if [ -n \"$bat\" ]; then echo \"$(cat /sys/class/power_supply/$bat/capacity)|$(cat /sys/class/power_supply/$bat/status)\"; else echo 'No Battery'; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim();
                if (out === "No Battery" || out === "") {
                    root.hasBattery = false;
                } else {
                    root.hasBattery = true;
                    let parts = out.split("|");
                    root.batteryValue = parseInt(parts[0]);
                    root.batteryPercent = parts[0] + "%";
                    let st = parts[1];
                    root.batteryStatus = st === "Charging" ? "Charging - ~1h left"
                        : (st === "Discharging" ? "Discharging - ~3h left" : st);
                }
            }
        }
    }

    Timer {
        interval: 10000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: batCommand.running = true
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        
        ColumnLayout {
            width: Math.min(parent.width, 1000)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 24
            
            Item { Layout.preferredHeight: 8 }

            // TITLE ROW
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                spacing: 12
                Text { text: "\ueb0d"; color: Theme.colPrimary; font.family: "tabler-icons"; font.pixelSize: 24; font.weight: Font.Bold }
                Text { text: "Power & Battery"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 20; font.weight: Font.Bold }
            }

            // BATTERY MAIN CARD
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                implicitHeight: 120
                color: Theme.showCardBackground ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03) : "transparent"
                border.width: 1
                border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04)
                radius: 12

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Text { text: "\uea38"; color: Theme.colPrimary; font.family: "tabler-icons"; font.pixelSize: 20; Layout.alignment: Qt.AlignTop }
                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true
                            Text { text: "Battery"; font.family: Theme.defaultFontFamily; font.pixelSize: 16; font.weight: Font.Bold; color: Theme.colOnSurface }
                            Text { text: root.hasBattery ? root.batteryStatus : "Not available"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; color: Theme.colOnSurfaceVariant }
                        }
                        Text { 
                            text: root.hasBattery ? root.batteryPercent : "--"
                            color: Theme.colPrimary
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 28
                            font.weight: Font.Medium
                        }
                    }

                    // Progress Bar
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.1)
                            Rectangle {
                                width: parent.width * (root.hasBattery ? (root.batteryValue / 100.0) : 0)
                                height: parent.height
                                radius: 3
                                color: Theme.colPrimary
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "0%"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 10 }
                            Item { Layout.fillWidth: true }
                            Text { text: "100%"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 10 }
                        }
                    }
                }
            }

            // INFO CARDS ROW
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 12

                // Screen On
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 70
                    color: Theme.showCardBackground ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03) : "transparent"
                    border.width: 1
                    border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04)
                    radius: 12
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 4
                        Text { text: "Screen on"; font.family: Theme.defaultFontFamily; font.pixelSize: 10; color: Theme.colOnSurfaceVariant; font.weight: Font.DemiBold }
                        Text { text: "3h 24m"; font.family: Theme.defaultFontFamily; font.pixelSize: 16; color: Theme.colOnSurface }
                    }
                }
                
                // Standby
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 70
                    color: Theme.showCardBackground ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03) : "transparent"
                    border.width: 1
                    border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04)
                    radius: 12
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 4
                        Text { text: "Standby"; font.family: Theme.defaultFontFamily; font.pixelSize: 10; color: Theme.colOnSurfaceVariant; font.weight: Font.DemiBold }
                        Text { text: "18h 40m"; font.family: Theme.defaultFontFamily; font.pixelSize: 16; color: Theme.colOnSurface }
                    }
                }

                // Health
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 70
                    color: Theme.showCardBackground ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03) : "transparent"
                    border.width: 1
                    border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04)
                    radius: 12
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 4
                        Text { text: "Health"; font.family: Theme.defaultFontFamily; font.pixelSize: 10; color: Theme.colOnSurfaceVariant; font.weight: Font.DemiBold }
                        Text { text: "Good"; font.family: Theme.defaultFontFamily; font.pixelSize: 16; color: Theme.colPrimary }
                    }
                }
            }

            // POWER MODE
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 12

                Text {
                    text: "POWER MODE"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.4
                    color: Theme.colOnSurface
                    opacity: 0.45
                }

                // Custom Segmented Control for Power Mode
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: Theme.showCardBackground ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03) : "transparent"
                    border.width: 1
                    border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04)
                    radius: height / 2

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 4

                        // Saver
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: height / 2
                            color: root.powerMode === "saver" ? Theme.colPrimary : "transparent"
                            border.width: 1
                            border.color: root.powerMode === "saver" ? "transparent" : Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.1)
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Text { text: "\ueaef"; font.family: "tabler-icons"; font.pixelSize: 14; color: root.powerMode === "saver" ? Theme.colOnPrimary : Theme.colOnSurfaceVariant }
                                Text { text: "Saver"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: root.powerMode === "saver" ? Font.DemiBold : Font.Normal; color: root.powerMode === "saver" ? Theme.colOnPrimary : Theme.colOnSurfaceVariant }
                            }
                            MouseArea { anchors.fill: parent; onClicked: root.powerMode = "saver"; cursorShape: Qt.PointingHandCursor }
                        }
                        
                        // Balanced
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: height / 2
                            color: root.powerMode === "balanced" ? Theme.colPrimary : "transparent"
                            border.width: 1
                            border.color: root.powerMode === "balanced" ? "transparent" : Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.1)
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Text { text: "\uea03"; font.family: "tabler-icons"; font.pixelSize: 14; color: root.powerMode === "balanced" ? Theme.colOnPrimary : Theme.colOnSurfaceVariant }
                                Text { text: "Balanced"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: root.powerMode === "balanced" ? Font.DemiBold : Font.Normal; color: root.powerMode === "balanced" ? Theme.colOnPrimary : Theme.colOnSurfaceVariant }
                            }
                            MouseArea { anchors.fill: parent; onClicked: root.powerMode = "balanced"; cursorShape: Qt.PointingHandCursor }
                        }

                        // Performance
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: height / 2
                            color: root.powerMode === "performance" ? Theme.colPrimary : "transparent"
                            border.width: 1
                            border.color: root.powerMode === "performance" ? "transparent" : Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.1)
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Text { text: "\ueb1d"; font.family: "tabler-icons"; font.pixelSize: 14; color: root.powerMode === "performance" ? Theme.colOnPrimary : Theme.colOnSurfaceVariant }
                                Text { text: "Performance"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: root.powerMode === "performance" ? Font.DemiBold : Font.Normal; color: root.powerMode === "performance" ? Theme.colOnPrimary : Theme.colOnSurfaceVariant }
                            }
                            MouseArea { anchors.fill: parent; onClicked: root.powerMode = "performance"; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
            }

            // SETTINGS LIST CARD
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                implicitHeight: settingsCol.implicitHeight + 16
                color: Theme.showCardBackground ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03) : "transparent"
                border.width: 1
                border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04)
                radius: 12
                
                ColumnLayout {
                    id: settingsCol
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 0

                    // Screen Timeout
                    Item {
                        Layout.fillWidth: true; implicitHeight: 64
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 16
                            Text { text: "\ueaf8"; font.family: "tabler-icons"; font.pixelSize: 18; color: Theme.colPrimary }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Text { text: "Screen timeout"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.colOnSurface }
                                Text { text: "Dim after inactivity"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                            }
                            Rectangle {
                                width: 80; height: 32; radius: 16; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                                RowLayout {
                                    anchors.centerIn: parent; spacing: 6
                                    Text { text: root.screenTimeout; font.family: Theme.defaultFontFamily; font.pixelSize: 12; color: Theme.colOnSurfaceVariant }
                                    Text { text: "\uea61"; font.family: "tabler-icons"; font.pixelSize: 14; color: Theme.colOnSurfaceVariant }
                                }
                            }
                        }
                        Rectangle { width: parent.width; height: 1; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04); anchors.bottom: parent.bottom; visible: true }
                    }

                    // Auto brightness
                    Item {
                        Layout.fillWidth: true; implicitHeight: 64
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 16
                            Text { text: "\uea4f"; font.family: "tabler-icons"; font.pixelSize: 18; color: Theme.colPrimary }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Text { text: "Auto brightness"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.colOnSurface }
                                Text { text: "Adjust based on ambient light"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                            }
                            StyledSwitch { checked: root.autoBrightness; onCheckedChanged: root.autoBrightness = checked }
                        }
                        Rectangle { width: parent.width; height: 1; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04); anchors.bottom: parent.bottom; visible: true }
                    }

                    // Wi-Fi on standby
                    Item {
                        Layout.fillWidth: true; implicitHeight: 64
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 16
                            Text { text: "\ueb52"; font.family: "tabler-icons"; font.pixelSize: 18; color: Theme.colPrimary }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Text { text: "Wi-Fi on standby"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.colOnSurface }
                                Text { text: "Keep connection when sleeping"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                            }
                            StyledSwitch { checked: root.wifiStandby; onCheckedChanged: root.wifiStandby = checked }
                        }
                        Rectangle { width: parent.width; height: 1; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04); anchors.bottom: parent.bottom; visible: true }
                    }

                    // Suspend on lid close
                    Item {
                        Layout.fillWidth: true; implicitHeight: 64
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 16
                            Text { text: "\uea89"; font.family: "tabler-icons"; font.pixelSize: 18; color: Theme.colPrimary }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Text { text: "Suspend on lid close"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.colOnSurface }
                                Text { text: "Sleep when laptop is closed"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                            }
                            StyledSwitch { checked: root.suspendLid; onCheckedChanged: root.suspendLid = checked }
                        }
                    }
                }
            }

            // QUICK ACTIONS
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 12

                Text {
                    text: "QUICK ACTIONS"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.4
                    color: Theme.colOnSurface
                    opacity: 0.45
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // Sleep
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 70
                        color: Theme.showCardBackground ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03) : "transparent"
                        border.width: 1
                        border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04)
                        radius: 12
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\ueaf8"; font.family: "tabler-icons"; font.pixelSize: 18; color: Theme.colOnSurfaceVariant }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Sleep"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; color: Theme.colOnSurfaceVariant }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["bash", "-c", "systemctl suspend"]) }
                    }

                    // Reboot
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 70
                        color: Theme.showCardBackground ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03) : "transparent"
                        border.width: 1
                        border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04)
                        radius: 12
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\ueb13"; font.family: "tabler-icons"; font.pixelSize: 18; color: Theme.colOnSurfaceVariant }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Reboot"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; color: Theme.colOnSurfaceVariant }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["bash", "-c", "zenity --question --title 'Reboot' --text 'Are you sure you want to reboot?' && systemctl reboot"]) }
                    }

                    // Shutdown
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 70
                        color: Qt.rgba(Theme.colError.r, Theme.colError.g, Theme.colError.b, 0.05)
                        border.width: 1
                        border.color: Qt.rgba(Theme.colError.r, Theme.colError.g, Theme.colError.b, 0.2)
                        radius: 12
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\ueb0d"; font.family: "tabler-icons"; font.pixelSize: 18; color: Theme.colError }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Shutdown"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; color: Theme.colError }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["bash", "-c", "zenity --question --title 'Shutdown' --text 'Are you sure you want to shut down?' && systemctl poweroff"]) }
                    }
                }
            }
            
            Item { Layout.preferredHeight: 24 }
        }
    }
}
