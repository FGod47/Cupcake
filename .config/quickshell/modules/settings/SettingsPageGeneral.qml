import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import Quickshell.Io
import Quickshell

Item {
    id: root

    // ── colours ──────────────────────────────────────────────────────────────
    property color cText:      Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.88)
    property color cTextDim:   Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.6)
    property color cAccent:    Theme.colPrimary
    property color cBgCard:    Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
    property color cBorder:    Qt.rgba(Theme.colOutline.r,   Theme.colOutline.g,   Theme.colOutline.b,   0.08)
    property color cDivider:   Qt.rgba(Theme.colOutline.r,   Theme.colOutline.g,   Theme.colOutline.b,   0.12)
    property color cIconBg:    Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)

    // ── state ─────────────────────────────────────────────────────────────────
    property int gapsIn:    3
    property int gapsOut:   8
    property int borderSize: 3
    property int rounding:  10

    // ── load persisted values ─────────────────────────────────────────────────
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

    // ── helpers ───────────────────────────────────────────────────────────────
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
            "sed -i 's/rounding = .*/rounding = " + root.rounding + ",/' ~/.config/hypr/decoration.lua && " +
            "hyprctl reload"
        ]);
    }

    // ── reusable components ───────────────────────────────────────────────────
    component SettingsCard: Rectangle {
        default property alias content: col.data
        property string sectionTitle: ""

        Layout.fillWidth: true
        implicitHeight: col.implicitHeight + (hdr.visible ? hdr.height + 28 : 32)
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
            id: col
            anchors { top: hdr.visible ? hdr.bottom : parent.top; topMargin: hdr.visible ? 12 : 16; left: parent.left; right: parent.right; leftMargin: 20; rightMargin: 20; bottomMargin: 16 }
            spacing: 0
        }
    }

    component SettingsRow: RowLayout {
        Layout.fillWidth: true
        spacing: 12
        Layout.topMargin: 4
        Layout.bottomMargin: 4

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: root.cDivider
            visible: false // used as divider placeholder — rows use parent spacing
        }
    }

    component SliderRow: Item {
        id: sliderRow
        property string icon: ""
        property string label: ""
        property string description: ""
        property real   sliderFrom:  0
        property real   sliderTo:    100
        property real   sliderStep:  1
        property real   sliderValue: 0
        property string valueSuffix: ""
        signal moved(real v)

        Layout.fillWidth: true
        height: 64

        RowLayout {
            anchors.fill: parent
            spacing: 12

            // icon
            Rectangle {
                width: 32; height: 32; radius: 10
                color: root.cIconBg
                Text {
                    anchors.centerIn: parent
                    text: sliderRow.icon
                    color: root.cTextDim
                    font { family: "tabler-icons"; pixelSize: 16 }
                }
            }

            // label + description
            ColumnLayout {
                spacing: 1
                Text { text: sliderRow.label;       color: root.cText;    font { family: Theme.defaultFontFamily; pixelSize: 13; weight: Font.Medium } }
                Text { text: sliderRow.description; color: root.cTextDim; font { family: Theme.defaultFontFamily; pixelSize: 11 }; opacity: 0.8 }
            }

            Item { Layout.fillWidth: true }

            // value badge
            Rectangle {
                width: 36; height: 24; radius: 6
                color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12)
                Text {
                    anchors.centerIn: parent
                    text: Math.round(sliderRow.sliderValue) + sliderRow.valueSuffix
                    color: root.cAccent
                    font { family: Theme.defaultFontFamily; pixelSize: 12; weight: Font.DemiBold }
                }
            }

            // slider
            StyledSlider {
                Layout.preferredWidth: 180
                from:     sliderRow.sliderFrom
                to:       sliderRow.sliderTo
                stepSize: sliderRow.sliderStep
                value:    sliderRow.sliderValue
                onValueChanged: sliderRow.sliderValue = value
                onPressedChanged: { if (!pressed) sliderRow.moved(value) }
            }
        }

        // bottom divider
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 1
            color: root.cDivider
            visible: sliderRow.visible
        }
    }

    // ── layout ────────────────────────────────────────────────────────────────
    ScrollView {
        anchors.fill: parent
        anchors.margins: 24
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 20

            // ── Window Gaps ───────────────────────────────────────────────────
            SettingsCard {
                sectionTitle: "Window Gaps"

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    SliderRow {
                        icon: "\ueae9"
                        label: "Inner gaps"
                        description: "Space between tiled windows"
                        sliderFrom: 0; sliderTo: 40; sliderStep: 1
                        sliderValue: root.gapsIn
                        valueSuffix: "px"
                        onMoved: (v) => { root.gapsIn = Math.round(v); root.applyGaps(); }
                    }

                    SliderRow {
                        icon: "\ueb19"
                        label: "Outer gaps"
                        description: "Space between windows and screen edges"
                        sliderFrom: 0; sliderTo: 60; sliderStep: 1
                        sliderValue: root.gapsOut
                        valueSuffix: "px"
                        onMoved: (v) => { root.gapsOut = Math.round(v); root.applyGaps(); }
                    }
                }
            }

            // ── Window Style ──────────────────────────────────────────────────
            SettingsCard {
                sectionTitle: "Window Style"

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    SliderRow {
                        icon: "\ueb7a"
                        label: "Corner rounding"
                        description: "Radius applied to window corners"
                        sliderFrom: 0; sliderTo: 30; sliderStep: 1
                        sliderValue: root.rounding
                        valueSuffix: "px"
                        onMoved: (v) => { root.rounding = Math.round(v); root.applyRounding(); }
                    }

                    SliderRow {
                        icon: "\ueb45"
                        label: "Border size"
                        description: "Thickness of window borders"
                        sliderFrom: 0; sliderTo: 10; sliderStep: 1
                        sliderValue: root.borderSize
                        valueSuffix: "px"
                        onMoved: (v) => { root.borderSize = Math.round(v); root.applyBorder(); }
                    }
                }
            }

            Item { height: 16 }
        }
    }
}
