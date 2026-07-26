import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../../theme"
import "../common"

Item {
    id: root
    
    // Battery State
    property string batteryPercent: "Unknown"
    property string batteryStatus: "Unknown"
    property int batteryValue: 0
    property bool hasBattery: false
    
    // Real Power Profile State
    property string powerMode: {
        switch(PowerProfiles.profile) {
            case PowerProfile.PowerSaver: return "Power Saver"
            case PowerProfile.Balanced: return "Balanced"
            case PowerProfile.Performance: return "Performance"
            default: return "Balanced"
        }
    }
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
            NCard {
                sectionTitle: "Battery"

                NRow {
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

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uebd1" } // activity-heartbeat
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

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea4d" } // bolt
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


            NCard {
                sectionTitle: "Power Profile"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uebe4"; iconColor: Theme.colPrimary; bgColor: cBgElevated } // leaf
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Active profile"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: ["Power Saver", "Balanced", "Performance"]
                        current: root.powerMode
                        onSelected: (val) => {
                            if (val === "Power Saver") PowerProfiles.profile = PowerProfile.PowerSaver;
                            else if (val === "Balanced") PowerProfiles.profile = PowerProfile.Balanced;
                            else if (val === "Performance") PowerProfiles.profile = PowerProfile.Performance;
                            let icon = val === "Power Saver" ? "battery-low"
                                     : val === "Performance" ? "utilities-system-monitor"
                                     : "battery-good";
                            Quickshell.execDetached(["notify-send", "-a", "Power Manager", "-i", icon, "-t", "2500", "Power Profile", "Switched to " + val]);
                        }
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueafc" } // battery-2
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

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea74" } // cpu
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
            NCard {
                sectionTitle: "Screen & Display"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea4f" } // brightness-down
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

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea8d" } // device-desktop
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

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb18" } // refresh
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
            NCard {
                sectionTitle: "Suspend & Sleep"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueafd" } // battery-3
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

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb51" } // plug
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

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea89" } // device-laptop
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Wake on lid open"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: root.wakeLid; onToggled: (val) => root.wakeLid = val }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueafa" } // battery-off
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
            NCard {
                sectionTitle: "Charging"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb51"; iconColor: Theme.colPrimary; bgColor: cBgElevated } // plug
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Limit charging to extend battery life"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: root.limitCharge; onToggled: (val) => root.limitCharge = val }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea4c" } // battery-charging
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
            NCard {
                sectionTitle: "Advanced"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb39" } // usb
                        ColumnLayout {
                            spacing: 1
                            Text { text: "USB autosuspend"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                            Text { text: "Power down idle USB devices"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: root.usbAutosuspend; onToggled: (val) => root.usbAutosuspend = val }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea74" } // cpu
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

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb18" } // server / refresh
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
