import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "theme"

Item {
    id: root
    
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

    component SettingsRow: RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        spacing: 12
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

                SettingsCard {
            SectionLabel { text: "General" }
            
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\uea9a"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Enabled"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Show the dock on your desktop"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSwitch { checked: true; onCheckedChanged: {} }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\uebd3"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Active monitor only"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Only show the dock on the focused monitor"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSwitch { checked: false; onCheckedChanged: {} }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ufa59"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Monitors"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Choose which monitors display the dock"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSwitch { checked: true; onCheckedChanged: {} }
            }
        }

                SettingsCard {
            SectionLabel { text: "Behavior" }
            
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\uecf0"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Auto hide"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Hide the dock until the cursor reaches the edge"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSwitch { checked: false; onCheckedChanged: {} }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb2c"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Reserve space"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Keep windows from overlapping the dock"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSwitch { checked: false; onCheckedChanged: {} }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ued46"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Show running"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Mark running applications"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSwitch { checked: false; onCheckedChanged: {} }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\uefb1"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Show dots"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Use dots for running app markers"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSwitch { checked: true; onCheckedChanged: {} }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\uf554"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Show instance count"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Badge with open window count per app"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSwitch { checked: false; onCheckedChanged: {} }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\uedba"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Launcher position"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Place the launcher at the start or end"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                SettingsSegmentedControl { Layout.preferredWidth: 120; model: [ { label: "Start", value: 1 }, { label: "End", value: 2 } ] }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\uf1f6"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Launcher icon"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Icon for the app launcher button"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledTextField { Layout.preferredWidth: 160; placeholderText: "Enter icon name..." }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb56"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Magnification"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Enlarge icons on hover"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSwitch { checked: false; onCheckedChanged: {} }
            }
        }

                SettingsCard {
            SectionLabel { text: "Layout" }
            
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb20"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Position"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Position"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                SettingsSegmentedControl { Layout.preferredWidth: 200; model: [ { label: "Option 1", value: 1 }, { label: "Option 2", value: 2 } ] }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb20"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Icon Size"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Icon Size"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSlider { Layout.preferredWidth: 150; from: 0; to: 100; value: 50 }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb20"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Main Axis Padding"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Main Axis Padding"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSlider { Layout.preferredWidth: 150; from: 0; to: 100; value: 50 }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb20"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Cross Axis Padding"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Cross Axis Padding"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSlider { Layout.preferredWidth: 150; from: 0; to: 100; value: 50 }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb20"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Item Spacing"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Item Spacing"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSlider { Layout.preferredWidth: 150; from: 0; to: 100; value: 50 }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb20"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Ends Margin"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Ends Margin"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSlider { Layout.preferredWidth: 150; from: 0; to: 100; value: 50 }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb20"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Edge Margin"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Edge Margin"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSlider { Layout.preferredWidth: 150; from: 0; to: 100; value: 50 }
            }
        }

                SettingsCard {
            SectionLabel { text: "Shape" }
            
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb20"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Corner Radius"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Corner Radius"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSlider { Layout.preferredWidth: 150; from: 0; to: 100; value: 50 }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb20"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Corner Top Left"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Corner Top Left"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSlider { Layout.preferredWidth: 150; from: 0; to: 100; value: 50 }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb20"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Corner Top Right"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Corner Top Right"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSlider { Layout.preferredWidth: 150; from: 0; to: 100; value: 50 }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb20"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Corner Bottom Left"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Corner Bottom Left"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSlider { Layout.preferredWidth: 150; from: 0; to: 100; value: 50 }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb20"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Corner Bottom Right"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Corner Bottom Right"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSlider { Layout.preferredWidth: 150; from: 0; to: 100; value: 50 }
            }
        }

                SettingsCard {
            SectionLabel { text: "Effects" }
            
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb20"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Background Opacity"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Background Opacity"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSlider { Layout.preferredWidth: 150; from: 0; to: 100; value: 50 }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb20"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Shadow"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Shadow"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSwitch { checked: false; onCheckedChanged: {} }
            }
        }

                SettingsCard {
            SectionLabel { text: "Focus Styling" }
            
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb20"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Active Icon Scale"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Active Icon Scale"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSlider { Layout.preferredWidth: 150; from: 0; to: 100; value: 50 }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb20"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Inactive Icon Scale"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Inactive Icon Scale"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSlider { Layout.preferredWidth: 150; from: 0; to: 100; value: 50 }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb20"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Magnification Scale"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Magnification Scale"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSlider { Layout.preferredWidth: 150; from: 0; to: 100; value: 50 }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb20"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Active Icon Opacity"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Active Icon Opacity"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSlider { Layout.preferredWidth: 150; from: 0; to: 100; value: 50 }
            }
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb20"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Inactive Icon Opacity"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Inactive Icon Opacity"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSlider { Layout.preferredWidth: 150; from: 0; to: 100; value: 50 }
            }
        }

                SettingsCard {
            SectionLabel { text: "Pinned Apps" }
            
            SettingsRow {
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb20"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Pinned Apps"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600 }
                    Text { text: "Pinned Apps"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 350; wrapMode: Text.WordWrap; opacity: 0.8 }
                }
                StyledSwitch { checked: false; onCheckedChanged: {} }
            }
        }

            Item { Layout.preferredHeight: 24 }
        }
    }
}
