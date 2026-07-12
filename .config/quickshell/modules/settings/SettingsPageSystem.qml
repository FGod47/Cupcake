import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../theme"
import "../common"

Item {
    id: systemPageRoot

    // =====================================================================
    // Reusable inline components (matching Dock page style)
    // =====================================================================
    component SettingsCard: Rectangle {
        default property alias content: innerCol.data
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        implicitHeight: innerCol.implicitHeight + 40
        Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        color: Theme.showCardBackground ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03) : "transparent"
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

    component SettingsRow: RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        spacing: 12
    }

    component SystemListItem: SettingsRow {
        id: listItem

        property string iconName: ""
        property string title: ""
        property string subtitle: ""
        property int pageIndex: -1

        RowLayout {
            spacing: 12
            Rectangle {
                width: 32; height: 32; radius: 16
                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                Text {
                    anchors.centerIn: parent
                    text: listItem.iconName
                    color: Theme.colOnSurfaceVariant
                    font.family: "tabler-icons"
                    font.pixelSize: 16
                }
            }
            ColumnLayout {
                spacing: 1
                Text { text: listItem.title; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                Text { text: listItem.subtitle; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
            }
        }

        Item { Layout.fillWidth: true }

        Text {
            text: "\uea61"
            font.family: "tabler-icons"
            font.pixelSize: 16
            color: Theme.colOnSurfaceVariant
            opacity: 0.5
            Layout.alignment: Qt.AlignVCenter
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (listItem.pageIndex !== -1) {
                    var p = systemPageRoot;
                    while (p) {
                        if (p.currentIndex !== undefined) {
                            p.currentIndex = listItem.pageIndex;
                            break;
                        }
                        p = p.parent;
                    }
                }
            }
        }
    }

    // =====================================================================
    // Main UI Layout
    // =====================================================================
    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: Math.min(parent.width, 1000)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 24

            Item { Layout.preferredHeight: 8 }

            // TOP CARD — Device Identity
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 144
                radius: 12
                color: Theme.showCardBackground ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03) : "transparent"
                border.width: 1
                border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    RowLayout {
                        spacing: 16
                        Rectangle {
                            Layout.preferredWidth: 64
                            Layout.preferredHeight: 64
                            radius: 12
                            color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.15)
                            Text { anchors.centerIn: parent; text: "\ueb02"; font.family: "tabler-icons"; font.pixelSize: 32; color: Theme.colPrimary }
                        }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "cupcake-pc"; font.family: Theme.defaultFontFamily; font.pixelSize: 18; font.weight: 700; color: Theme.colOnSurface }
                            Text { text: "Arch Linux — Hyprland"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; color: Theme.colOnSurfaceVariant }
                            Text {
                                text: "Rename this device"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 12
                                font.weight: 600
                                color: Theme.colPrimary
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }

                    RowLayout {
                        spacing: 24
                        RowLayout {
                            spacing: 8
                            Rectangle {
                                width: 28; height: 28; radius: 6
                                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.06)
                            }
                            ColumnLayout {
                                spacing: 0
                                Text { text: "Arch Linux"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: 600; color: Theme.colOnSurface }
                                Text { text: "View system info"; font.family: Theme.defaultFontFamily; font.pixelSize: 10; color: Theme.colOnSurfaceVariant }
                            }
                        }
                        RowLayout {
                            spacing: 8
                            Rectangle {
                                width: 28; height: 28; radius: 6
                                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.06)
                                Text { anchors.centerIn: parent; text: "\uea64"; font.family: "tabler-icons"; font.pixelSize: 14; color: Theme.colPrimary }
                            }
                            ColumnLayout {
                                spacing: 0
                                Text { text: "Backups"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: 600; color: Theme.colOnSurface }
                                Text { text: "Last backup 3h ago"; font.family: Theme.defaultFontFamily; font.pixelSize: 10; color: Theme.colOnSurfaceVariant }
                            }
                        }
                        RowLayout {
                            spacing: 8
                            Rectangle {
                                width: 28; height: 28; radius: 6
                                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.06)
                                Text { anchors.centerIn: parent; text: "\uea2d"; font.family: "tabler-icons"; font.pixelSize: 14; color: Theme.colPrimary }
                            }
                            ColumnLayout {
                                spacing: 0
                                Text { text: "Updates"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: 600; color: Theme.colOnSurface }
                                Text { text: "Checked 7h ago"; font.family: Theme.defaultFontFamily; font.pixelSize: 10; color: Theme.colOnSurfaceVariant }
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }
                }
            }

            // 1. DEVICE CARD
            SettingsCard {
                SectionLabel { text: "Device" }

                SystemListItem { iconName: "\uea89"; title: "Display"; subtitle: "Monitors, brightness, night light, display profile"; pageIndex: 18 }
                SystemListItem { iconName: "\ueb4f"; title: "Sound"; subtitle: "Volume levels, output, input, sound devices" }
                SystemListItem { iconName: "\ueb0d"; title: "Power & battery"; subtitle: "Sleep, battery usage, power profiles"; pageIndex: 13 }
                SystemListItem { iconName: "\ueadc"; title: "Storage"; subtitle: "Disk usage, drives, mount points" }
            }

            // 2. APPS & NOTIFICATIONS CARD
            SettingsCard {
                SectionLabel { text: "Apps & Notifications" }

                SystemListItem { iconName: "\uea35"; title: "Notifications"; subtitle: "Alerts from apps and system"; pageIndex: 6 }
                SystemListItem { iconName: "\ueb07"; title: "Focus mode"; subtitle: "Do not disturb, automatic rules" }
                SystemListItem { iconName: "\uea6e"; title: "Clipboard"; subtitle: "Clipboard history, sync, clear" }
                SystemListItem { iconName: "\ueae2"; title: "Multitasking"; subtitle: "Workspaces, window snapping, task switching" }
            }

            // 3. CONNECTIVITY CARD
            SettingsCard {
                SectionLabel { text: "Connectivity" }

                SystemListItem { iconName: "\ueb13"; title: "File sharing"; subtitle: "Local network sharing, received files" }
                SystemListItem { iconName: "\uea5c"; title: "Screen mirroring"; subtitle: "Cast this display to another device" }
                SystemListItem { iconName: "\ueb02"; title: "Remote desktop"; subtitle: "Remote access users and permissions" }
            }

            // 4. SYSTEM CARD
            SettingsCard {
                SectionLabel { text: "System" }

                SystemListItem { iconName: "\uea3a"; title: "Package updates"; subtitle: "Update channel, pacman/AUR sources" }
                SystemListItem { iconName: "\ueb53"; title: "Troubleshoot"; subtitle: "Recommended fixes, logs, diagnostics" }
                SystemListItem { iconName: "\uea67"; title: "Recovery"; subtitle: "Reset settings, advanced startup options" }
                SystemListItem { iconName: "\ueac5"; title: "About"; subtitle: "Device specs, hostname, kernel version" }
            }

            Item { Layout.preferredHeight: 24 }
        }
    }
}
