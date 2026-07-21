import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import Quickshell.Io
import Quickshell

Item {
    id: root

    // ── colours ───────────────────────────────────────────────────────────────
    property color cText:    Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.88)
    property color cTextDim: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.6)
    property color cAccent:  Theme.colPrimary
    property color cBgCard:  Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
    property color cBorder:  Qt.rgba(Theme.colOutline.r,   Theme.colOutline.g,   Theme.colOutline.b,   0.08)
    property color cDivider: Qt.rgba(Theme.colOutline.r,   Theme.colOutline.g,   Theme.colOutline.b,   0.15)
    property color cIconBg:  Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)

    // ── state ─────────────────────────────────────────────────────────────────
    property int gapsIn:     3
    property int gapsOut:    8
    property int borderSize: 3
    property int rounding:   10

    // ── load ──────────────────────────────────────────────────────────────────
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
        command: ["bash", "-c", "hyprctl getoption decoration:rounding -j | grep -o '\"int\": [0-9]*' | grep -o '[0-9]*'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { let v = parseInt(text.trim()); if (!isNaN(v) && v >= 0) root.rounding = v; }
        }
    }

    // ── apply helpers ─────────────────────────────────────────────────────────
    function applyGaps() {
        Quickshell.execDetached(["bash", "-c",
            "echo " + root.gapsIn  + " > ~/.config/cupcake/.gaps_in && " +
            "echo " + root.gapsOut + " > ~/.config/cupcake/.gaps_out && " +
            "~/.local/bin/apply-gaps"
        ]);
    }
    function applyBorder() {
        Quickshell.execDetached(["bash", "-c",
            "echo " + root.borderSize + " > ~/.config/cupcake/.border_size && " +
            "~/.local/bin/apply-borders"
        ]);
    }
    function applyRounding() {
        Quickshell.execDetached(["bash", "-c",
            "sed -i 's/rounding = [0-9]*/rounding = " + root.rounding + "/' ~/.config/hypr/decoration.lua && " +
            "hyprctl reload"
        ]);
    }

    // ── reusable ──────────────────────────────────────────────────────────────
    component SettingsCard: Rectangle {
        default property alias content: cardCol.data
        property string sectionTitle: ""
        Layout.fillWidth: true
        implicitHeight: cardCol.implicitHeight + (hdr.visible ? hdr.height + 28 : 32)
        color: root.cBgCard
        radius: 12
        border.color: root.cBorder
        border.width: 1

        RowLayout {
            id: hdr
            anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 16; leftMargin: 20; rightMargin: 20 }
            visible: sectionTitle !== ""
            spacing: 8
            Text {
                text: sectionTitle
                color: Theme.colOnSurfaceVariant
                font { family: Theme.defaultFontFamily; pixelSize: 11; weight: Font.DemiBold; letterSpacing: 0.8; capitalization: Font.AllUppercase }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: root.cDivider }
        }
        ColumnLayout {
            id: cardCol
            anchors { top: hdr.visible ? hdr.bottom : parent.top; topMargin: hdr.visible ? 12 : 16; left: parent.left; right: parent.right; leftMargin: 20; rightMargin: 20; bottomMargin: 16 }
            spacing: 0
        }
    }

    component SettingsRow: Rectangle {
        default property alias rowContent: innerRow.data
        Layout.fillWidth: true
        implicitHeight: innerRow.implicitHeight + 20
        color: "transparent"
        radius: 8
        RowLayout {
            id: innerRow
            anchors { fill: parent; topMargin: 10; bottomMargin: 10 }
            spacing: 12
        }
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 1; color: root.cDivider; opacity: 0.6
        }
    }

    // ── main layout ───────────────────────────────────────────────────────────
    ScrollView {
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        anchors.fill: parent
        anchors.bottomMargin: 28
        leftPadding: 32; rightPadding: 32
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 20

            // ── Window Gaps ───────────────────────────────────────────────────
            SettingsCard {
                sectionTitle: "Window Gaps"

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: root.cIconBg
                            Text { anchors.centerIn: parent; text: "\ueae9"; color: root.cTextDim; font { family: "tabler-icons"; pixelSize: 16 } }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Inner gaps"; color: root.cText; font { family: Theme.defaultFontFamily; pixelSize: 13; weight: Font.Medium } }
                            Text { text: "Space between tiled windows"; color: root.cTextDim; font { family: Theme.defaultFontFamily; pixelSize: 11 }; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 10
                        Rectangle {
                            width: 36; height: 24; radius: 6
                            color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12)
                            Text { anchors.centerIn: parent; text: root.gapsIn + "px"; color: root.cAccent; font { family: Theme.defaultFontFamily; pixelSize: 12; weight: Font.DemiBold } }
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
                            Text { anchors.centerIn: parent; text: "\ueb19"; color: root.cTextDim; font { family: "tabler-icons"; pixelSize: 16 } }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Outer gaps"; color: root.cText; font { family: Theme.defaultFontFamily; pixelSize: 13; weight: Font.Medium } }
                            Text { text: "Space between windows and screen edges"; color: root.cTextDim; font { family: Theme.defaultFontFamily; pixelSize: 11 }; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 10
                        Rectangle {
                            width: 36; height: 24; radius: 6
                            color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12)
                            Text { anchors.centerIn: parent; text: root.gapsOut + "px"; color: root.cAccent; font { family: Theme.defaultFontFamily; pixelSize: 12; weight: Font.DemiBold } }
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

            // ── Window Style ──────────────────────────────────────────────────
            SettingsCard {
                sectionTitle: "Window Style"

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: root.cIconBg
                            Text { anchors.centerIn: parent; text: "\ueb7a"; color: root.cTextDim; font { family: "tabler-icons"; pixelSize: 16 } }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Corner rounding"; color: root.cText; font { family: Theme.defaultFontFamily; pixelSize: 13; weight: Font.Medium } }
                            Text { text: "Radius applied to all window corners"; color: root.cTextDim; font { family: Theme.defaultFontFamily; pixelSize: 11 }; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 10
                        Rectangle {
                            width: 36; height: 24; radius: 6
                            color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12)
                            Text { anchors.centerIn: parent; text: root.rounding + "px"; color: root.cAccent; font { family: Theme.defaultFontFamily; pixelSize: 12; weight: Font.DemiBold } }
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
                            Text { anchors.centerIn: parent; text: "\ueb45"; color: root.cTextDim; font { family: "tabler-icons"; pixelSize: 16 } }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Border size"; color: root.cText; font { family: Theme.defaultFontFamily; pixelSize: 13; weight: Font.Medium } }
                            Text { text: "Thickness of window borders"; color: root.cTextDim; font { family: Theme.defaultFontFamily; pixelSize: 11 }; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 10
                        Rectangle {
                            width: 36; height: 24; radius: 6
                            color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12)
                            Text { anchors.centerIn: parent; text: root.borderSize + "px"; color: root.cAccent; font { family: Theme.defaultFontFamily; pixelSize: 12; weight: Font.DemiBold } }
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
