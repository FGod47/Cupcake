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
    property string powerMode: "Balanced"
    property int saverThreshold: 20
    property bool cpuBoost: true
    property int dimScreen: 3
    property int offScreen: 8
    property bool lowerRefresh: true
    property int suspendBat: 15
    property int suspendAc: 45
    property bool wakeLid: true
    property string criticalBat: "Hibernate"
    property bool limitCharge: true
    property int chargeLimit: 80
    property bool usbAutosuspend: true
    property string aspm: "Powersave"
    property string powerBackend: "power-profiles-daemon"

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

    component SettingsCard: Rectangle {
        default property alias content: cardCol.data
        property string sectionTitle: ""
        Layout.fillWidth: true
        implicitHeight: cardCol.implicitHeight + (cardHeader.visible ? cardHeader.height + 28 : 32)
        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
        radius: 12
        border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.08)
        border.width: 1
        clip: true

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
                color: Theme.colOnSurfaceVariant
                font.family: Theme.defaultFontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
                font.capitalization: Font.AllUppercase
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15) }
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

    component SettingsRow: Rectangle {
        default property alias rowContent: innerLayout.data
        Layout.fillWidth: true
        implicitHeight: innerLayout.implicitHeight + 20
        color: "transparent"
        radius: 8

        property bool hoverable: false
        property bool hovered: hoverArea.containsMouse
        Behavior on color { ColorAnimation { duration: 120 } }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: parent.hoverable
        }

        RowLayout {
            id: innerLayout
            anchors.fill: parent
            anchors.leftMargin: 0
            anchors.rightMargin: 0
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            spacing: 12
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
            opacity: 0.6
        }
    }

    component PowerRowIcon: Rectangle {
        property string icon: ""
        property bool accent: false
        width: 32; height: 32; radius: 10
        color: Theme.colSurface
        Text {
            anchors.centerIn: parent
            text: parent.icon
            font.family: "tabler-icons"
            font.pixelSize: 16
            color: parent.accent ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.5)
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        leftPadding: 32; rightPadding: 32; topPadding: 32; bottomPadding: 32
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        
        ColumnLayout {
            width: Math.min(parent.width, 1000)
            spacing: 20

            // BATTERY
            SettingsCard {
                sectionTitle: "Battery"

                SettingsRow {
                    RowLayout {
                        spacing: 20
                        // Battery Shell
                        Item {
                            width: 64; height: 34
                            Rectangle {
                                anchors.fill: parent
                                anchors.rightMargin: 4
                                radius: 8
                                color: "transparent"
                                border.width: 2.5
                                border.color: Theme.colOutline
                                
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 3
                                    width: (parent.width - 6) * (root.batteryValue / 100.0)
                                    radius: 4
                                    color: Theme.colPrimary
                                    Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                }
                            }
                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 4
                                height: 12
                                radius: 2
                                color: Theme.colOutline
                            }
                        }
                        // Info
                        ColumnLayout {
                            spacing: 2
                            RowLayout {
                                spacing: 4
                                Text { text: root.hasBattery ? root.batteryValue : "--"; font.family: Theme.defaultFontFamily; font.pixelSize: 26; font.weight: Font.Black; font.letterSpacing: -0.5; color: Theme.colOnSurface }
                                Text { text: "%"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.colOnSurfaceVariant; Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 4 }
                            }
                            RowLayout {
                                spacing: 6
                                Rectangle { width: 6; height: 6; radius: 3; color: Theme.colPrimary; visible: root.hasBattery }
                                Text { text: root.hasBattery ? root.batteryStatus : "Not available"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; color: Theme.colOnSurfaceVariant }
                            }
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        PowerRowIcon { icon: "\uebd1" } // activity-heartbeat
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Battery health"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                            Text { text: "312 charge cycles"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        height: 22; width: statText.implicitWidth + 18; radius: 11; color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.14)
                        Text {
                            id: statText
                            anchors.centerIn: parent
                            text: "94% of design capacity"
                            font.family: Theme.monoFontFamily; font.pixelSize: 11; font.weight: Font.DemiBold; color: Theme.colPrimary
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        PowerRowIcon { icon: "\uea4d" } // bolt
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Power draw"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        height: 22; width: monoText.implicitWidth + 20; radius: 6; color: Qt.rgba(0,0,0,0.28)
                        Text {
                            id: monoText
                            anchors.centerIn: parent
                            text: "11.4 W"
                            font.family: Theme.monoFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant
                        }
                    }
                }
            }

            // POWER MENU
            SettingsCard {
                id: powerMenuCard
                sectionTitle: "Power Menu"
                
                property string currentStyle: "Island"
                Process {
                    id: initPowerMenu
                    command: ["bash", "-c", "cat ~/.config/cupcake/.power_confirmation_style 2>/dev/null || echo 'Island'"]
                    running: true
                    stdout: StdioCollector { onStreamFinished: { if (text.trim() !== "") powerMenuCard.currentStyle = text.trim() } }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        PowerRowIcon { icon: "\ueb0d" } // ti-power
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Confirmation style"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                            Text { text: "Visual layout for the shutdown confirmation"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        height: 32; width: 140; radius: 8
                        color: Theme.colSurfaceContainerHigh
                        border.color: Qt.rgba(255/255, 255/255, 255/255, 0.05); border.width: 1
                        
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 4; spacing: 4
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 6
                                color: powerMenuCard.currentStyle === "Island" ? Theme.colPrimary : "transparent"
                                Text { text: "Island"; color: powerMenuCard.currentStyle === "Island" ? Theme.colOnPrimary : Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 12; anchors.centerIn: parent }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Quickshell.execDetached(["bash", "-c", "echo 'Island' > ~/.config/cupcake/.power_confirmation_style"]); powerMenuCard.currentStyle = "Island"; } }
                            }
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 6
                                color: powerMenuCard.currentStyle === "Center" ? Theme.colPrimary : "transparent"
                                Text { text: "Center"; color: powerMenuCard.currentStyle === "Center" ? Theme.colOnPrimary : Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 12; anchors.centerIn: parent }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Quickshell.execDetached(["bash", "-c", "echo 'Center' > ~/.config/cupcake/.power_confirmation_style"]); powerMenuCard.currentStyle = "Center"; } }
                            }
                        }
                    }
                }
            }

            // POWER PROFILE
            SettingsCard {
                sectionTitle: "Power Profile"

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        PowerRowIcon { icon: "\uebe4"; accent: true } // leaf
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Active profile"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: ["Saver", "Balanced", "Performance"]
                        current: root.powerMode
                        onSelected: (val) => root.powerMode = val
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        PowerRowIcon { icon: "\ueafc" } // battery-2
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Automatically enable Saver below"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 12
                        StyledSlider {
                            Layout.preferredWidth: 140
                            from: 5; to: 50
                            value: root.saverThreshold
                            onMoved: root.saverThreshold = value
                        }
                        Text { text: root.saverThreshold + "%"; font.family: Theme.monoFontFamily; font.pixelSize: 12; color: Theme.colOnSurfaceVariant; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        PowerRowIcon { icon: "\uea74" } // cpu
                        ColumnLayout {
                            spacing: 1
                            Text { text: "CPU boost"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                            Text { text: "Allow short bursts above base clock"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: root.cpuBoost; onToggled: (val) => root.cpuBoost = val }
                }
            }

            // SCREEN & DISPLAY
            SettingsCard {
                sectionTitle: "Screen & Display"

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        PowerRowIcon { icon: "\uea4f" } // brightness-down
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Dim screen after idle"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 12
                        StyledSlider {
                            Layout.preferredWidth: 130
                            from: 1; to: 15
                            value: root.dimScreen
                            onMoved: root.dimScreen = value
                        }
                        Text { text: root.dimScreen + "m"; font.family: Theme.monoFontFamily; font.pixelSize: 12; color: Theme.colOnSurfaceVariant; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        PowerRowIcon { icon: "\uea8d" } // device-desktop
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Turn off screen after idle"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 12
                        StyledSlider {
                            Layout.preferredWidth: 130
                            from: 1; to: 30
                            value: root.offScreen
                            onMoved: root.offScreen = value
                        }
                        Text { text: root.offScreen + "m"; font.family: Theme.monoFontFamily; font.pixelSize: 12; color: Theme.colOnSurfaceVariant; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        PowerRowIcon { icon: "\ueb18" } // refresh
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Lower refresh rate on battery"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                            Text { text: "165Hz → 60Hz while unplugged"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: root.lowerRefresh; onToggled: (val) => root.lowerRefresh = val }
                }
            }

            // SUSPEND & SLEEP
            SettingsCard {
                sectionTitle: "Suspend & Sleep"

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        PowerRowIcon { icon: "\ueafd" } // battery-3
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Suspend after idle, on battery"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 12
                        StyledSlider {
                            Layout.preferredWidth: 130
                            from: 5; to: 60
                            value: root.suspendBat
                            onMoved: root.suspendBat = value
                        }
                        Text { text: root.suspendBat + "m"; font.family: Theme.monoFontFamily; font.pixelSize: 12; color: Theme.colOnSurfaceVariant; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        PowerRowIcon { icon: "\ueb51" } // plug
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Suspend after idle, on AC"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 12
                        StyledSlider {
                            Layout.preferredWidth: 130
                            from: 5; to: 120
                            value: root.suspendAc
                            onMoved: root.suspendAc = value
                        }
                        Text { text: root.suspendAc + "m"; font.family: Theme.monoFontFamily; font.pixelSize: 12; color: Theme.colOnSurfaceVariant; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        PowerRowIcon { icon: "\uea89" } // device-laptop
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Wake on lid open"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: root.wakeLid; onToggled: (val) => root.wakeLid = val }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        PowerRowIcon { icon: "\ueafa" } // battery-off
                        ColumnLayout {
                            spacing: 1
                            Text { text: "On critical battery"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: ["Suspend", "Hibernate", "Shut Down"]
                        current: root.criticalBat
                        onSelected: (val) => root.criticalBat = val
                    }
                }
            }

            // CHARGING
            SettingsCard {
                sectionTitle: "Charging"

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        PowerRowIcon { icon: "\ueb51"; accent: true } // plug
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Limit charging to extend battery life"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: root.limitCharge; onToggled: (val) => root.limitCharge = val }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        PowerRowIcon { icon: "\uea4c" } // battery-charging
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Charge limit"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 12
                        StyledSlider {
                            Layout.preferredWidth: 140
                            from: 50; to: 100
                            value: root.chargeLimit
                            onMoved: root.chargeLimit = value
                        }
                        Text { text: root.chargeLimit + "%"; font.family: Theme.monoFontFamily; font.pixelSize: 12; color: Theme.colOnSurfaceVariant; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
                    }
                }
            }

            // ADVANCED
            SettingsCard {
                sectionTitle: "Advanced"

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        PowerRowIcon { icon: "\ueb39" } // usb
                        ColumnLayout {
                            spacing: 1
                            Text { text: "USB autosuspend"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                            Text { text: "Power down idle USB devices"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: root.usbAutosuspend; onToggled: (val) => root.usbAutosuspend = val }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        PowerRowIcon { icon: "\uea74" } // cpu
                        ColumnLayout {
                            spacing: 1
                            Text { text: "PCIe power management (ASPM)"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: ["Default", "Powersave", "Performance"]
                        current: root.aspm
                        onSelected: (val) => root.aspm = val
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        PowerRowIcon { icon: "\ueb18" } // server / refresh
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Power management backend"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: ["power-profiles-daemon", "TLP"]
                        current: root.powerBackend
                        onSelected: (val) => root.powerBackend = val
                    }
                }
            }

        }
    }
}
