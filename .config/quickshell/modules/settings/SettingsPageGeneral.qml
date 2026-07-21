import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import Quickshell.Io
import Quickshell
import "../common"

Item {
    id: root

    property color cText:    Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.88)
    property color cTextDim: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.6)
    property color cAccent:  Theme.colPrimary
    property color cBgCard:  Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
    property color cBorder:  Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.08)
    property color cDivider: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
    property color cIconBg:  Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)

    property int gapsIn:       3
    property int gapsOut:      8
    property int borderSize:   3
    property int rounding:     10
    property bool bordersEnabled: true

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.gaps_in"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { let v = parseInt(text.trim()); if (!isNaN(v)) root.gapsIn = v; }
        }
    }
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.gaps_out"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { let v = parseInt(text.trim()); if (!isNaN(v)) root.gapsOut = v; }
        }
    }
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.border_size"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { let v = parseInt(text.trim()); if (!isNaN(v)) root.borderSize = v; }
        }
    }
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.borders"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { if (text.trim() === "false") root.bordersEnabled = false; }
        }
    }
    Process {
        command: ["bash", "-c", "hyprctl getoption decoration:rounding -j | grep -o '\"int\": [0-9]*' | grep -o '[0-9]*'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { let v = parseInt(text.trim()); if (!isNaN(v) && v >= 0) root.rounding = v; }
        }
    }

    function applyGaps() {
        Quickshell.execDetached(["bash", "-c",
            "echo " + root.gapsIn  + " > ~/.config/cupcake/.gaps_in && " +
            "echo " + root.gapsOut + " > ~/.config/cupcake/.gaps_out && " +
            "~/.local/bin/apply-gaps"
        ])
    }
    function applyBorder() {
        Quickshell.execDetached(["bash", "-c",
            "echo " + root.borderSize + " > ~/.config/cupcake/.border_size && " +
            "echo " + (root.bordersEnabled ? "true" : "false") + " > ~/.config/cupcake/.borders && " +
            "~/.local/bin/apply-borders"
        ])
    }
    function applyRounding() {
        Quickshell.execDetached(["bash", "-c",
            "sed -i 's/rounding = [0-9]*/rounding = " + root.rounding + "/' ~/.config/hypr/decoration.lua && " +
            "hyprctl reload"
        ])
    }

    // Copied exactly from SettingsPageAppearance.qml
    component SettingsCard: Rectangle {
        default property alias content: cardCol.data
        property string sectionTitle: ""
        Layout.fillWidth: true
        implicitHeight: cardCol.implicitHeight + (cardHeader.visible ? cardHeader.height + 28 : 32)
        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
        radius: 12
        border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.08)
        border.width: 1

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

    // Copied exactly from SettingsPageAppearance.qml
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

    ScrollView {
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        id: scrollView
        anchors.fill: parent
        anchors.bottomMargin: 28
        leftPadding: 32
        rightPadding: 32
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 20

            SettingsCard {
                sectionTitle: "Window Gaps"

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: root.cIconBg
                            Text { anchors.centerIn: parent; text: "\ueae9"; color: root.cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Inner gaps"; color: root.cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Space between tiled windows"; color: root.cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 10
                        Rectangle {
                            width: 36; height: 24; radius: 6
                            color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12)
                            Text { anchors.centerIn: parent; text: root.gapsIn + "px"; color: root.cAccent; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.DemiBold }
                        }
                        StyledSlider {
                            Layout.preferredWidth: 180
                            from: 0; to: 40; stepSize: 1
                            value: root.gapsIn
                            onValueChanged: root.gapsIn = Math.round(value)
                            onPressedChanged: { if (!pressed) root.applyGaps() }
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: root.cIconBg
                            Text { anchors.centerIn: parent; text: "\ueb19"; color: root.cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Outer gaps"; color: root.cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Space between windows and screen edges"; color: root.cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 10
                        Rectangle {
                            width: 36; height: 24; radius: 6
                            color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12)
                            Text { anchors.centerIn: parent; text: root.gapsOut + "px"; color: root.cAccent; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.DemiBold }
                        }
                        StyledSlider {
                            Layout.preferredWidth: 180
                            from: 0; to: 60; stepSize: 1
                            value: root.gapsOut
                            onValueChanged: root.gapsOut = Math.round(value)
                            onPressedChanged: { if (!pressed) root.applyGaps() }
                        }
                    }
                }
            }

            SettingsCard {
                sectionTitle: "Window Style"

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: root.cIconBg
                            Text { anchors.centerIn: parent; text: "\ueb45"; color: root.cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Window borders"; color: root.cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Show borders around windows"; color: root.cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledSwitch {
                        checked: root.bordersEnabled
                        onCheckedChanged: {
                            root.bordersEnabled = checked
                            root.applyBorder()
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: root.cIconBg
                            Text { anchors.centerIn: parent; text: "\ueb7a"; color: root.cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Corner rounding"; color: root.cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Radius applied to all window corners"; color: root.cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 10
                        Rectangle {
                            width: 36; height: 24; radius: 6
                            color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12)
                            Text { anchors.centerIn: parent; text: root.rounding + "px"; color: root.cAccent; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.DemiBold }
                        }
                        StyledSlider {
                            Layout.preferredWidth: 180
                            from: 0; to: 30; stepSize: 1
                            value: root.rounding
                            onValueChanged: root.rounding = Math.round(value)
                            onPressedChanged: { if (!pressed) root.applyRounding() }
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: root.cIconBg
                            Text { anchors.centerIn: parent; text: "\ueb45"; color: root.cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Border size"; color: root.cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Thickness of window borders"; color: root.cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 10
                        Rectangle {
                            width: 36; height: 24; radius: 6
                            color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12)
                            Text { anchors.centerIn: parent; text: root.borderSize + "px"; color: root.cAccent; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.DemiBold }
                        }
                        StyledSlider {
                            Layout.preferredWidth: 180
                            from: 0; to: 10; stepSize: 1
                            value: root.borderSize
                            onValueChanged: root.borderSize = Math.round(value)
                            onPressedChanged: { if (!pressed) root.applyBorder() }
                        }
                    }
                }
            }

            Item { height: 16 }
        }
    }
}
