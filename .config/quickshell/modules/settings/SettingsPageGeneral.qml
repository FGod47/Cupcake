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
    property color cIconBg:  Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)

    // Layout & Style Properties
    property int gapsIn:       3
    property int gapsOut:      8
    property int borderSize:   3
    property int rounding:     10
    property bool bordersEnabled: true
    property int overviewTabs: 5
    property real overviewScale: 0.14

    // Animation Properties
    property bool animationsEnabled: true
    property string animationPreset: "Balanced"
    property real animWindowsSpeed: 5.0
    property real animWorkspacesSpeed: 3.5
    property real animFadeSpeed: 2.5
    property string animBezier: "overshot"
    property string animStyle: "Slide"

    readonly property var availableBeziers: [
        "overshot",
        "md3_decel",
        "easeOutExpo",
        "crazyshot",
        "fluent_decel",
        "smoothOut",
        "easeInOutCirc",
        "linear"
    ]

    readonly property var availablePresets: [
        "Balanced",
        "Fast",
        "Bouncy",
        "Smooth",
        "Minimal"
    ]

    // --- Layout Processes ---
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
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.overview_tabs"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { let v = parseInt(text.trim()); if (!isNaN(v) && v > 0) root.overviewTabs = v; }
        }
    }
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.overview_scale"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { let v = parseFloat(text.trim()); if (!isNaN(v) && v > 0) root.overviewScale = v; }
        }
    }

    // --- Animation Processes ---
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.animations_enabled"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { if (text.trim() === "false") root.animationsEnabled = false; }
        }
    }
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.animation_preset"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { if (text.trim() !== "") root.animationPreset = text.trim(); }
        }
    }
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.anim_windows_speed"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { let v = parseFloat(text.trim()); if (!isNaN(v) && v > 0) root.animWindowsSpeed = v; }
        }
    }
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.anim_workspaces_speed"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { let v = parseFloat(text.trim()); if (!isNaN(v) && v > 0) root.animWorkspacesSpeed = v; }
        }
    }
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.anim_fade_speed"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { let v = parseFloat(text.trim()); if (!isNaN(v) && v > 0) root.animFadeSpeed = v; }
        }
    }
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.anim_bezier"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { if (text.trim() !== "") root.animBezier = text.trim(); }
        }
    }
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.anim_style"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let s = text.trim().toLowerCase();
                if (s.startsWith("popin")) root.animStyle = "Popin";
                else if (s.startsWith("slidevert")) root.animStyle = "SlideVert";
                else root.animStyle = "Slide";
            }
        }
    }

    // --- Action Functions ---
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
            "hyprctl reload config-only"
        ])
    }

    function applyAnimations() {
        let styleVal = "slide";
        if (root.animStyle === "Popin") styleVal = "popin 80%";
        else if (root.animStyle === "SlideVert") styleVal = "slidevert";

        Quickshell.execDetached(["bash", "-c",
            "echo '" + (root.animationsEnabled ? "true" : "false") + "' > ~/.config/cupcake/.animations_enabled && " +
            "echo '" + root.animationPreset + "' > ~/.config/cupcake/.animation_preset && " +
            "echo '" + root.animWindowsSpeed + "' > ~/.config/cupcake/.anim_windows_speed && " +
            "echo '" + root.animWorkspacesSpeed + "' > ~/.config/cupcake/.anim_workspaces_speed && " +
            "echo '" + root.animFadeSpeed + "' > ~/.config/cupcake/.anim_fade_speed && " +
            "echo '" + root.animBezier + "' > ~/.config/cupcake/.anim_bezier && " +
            "echo '" + styleVal + "' > ~/.config/cupcake/.anim_style && " +
            "~/.local/bin/apply-animations"
        ]);
    }

    function setPreset(presetName) {
        root.animationPreset = presetName;
        if (presetName === "Fast") {
            root.animWindowsSpeed = 2.5;
            root.animWorkspacesSpeed = 2.5;
            root.animFadeSpeed = 2.0;
            root.animBezier = "easeOutExpo";
            root.animStyle = "Popin";
        } else if (presetName === "Bouncy") {
            root.animWindowsSpeed = 5.5;
            root.animWorkspacesSpeed = 4.0;
            root.animFadeSpeed = 3.0;
            root.animBezier = "crazyshot";
            root.animStyle = "Popin";
        } else if (presetName === "Smooth") {
            root.animWindowsSpeed = 4.0;
            root.animWorkspacesSpeed = 4.5;
            root.animFadeSpeed = 3.0;
            root.animBezier = "fluent_decel";
            root.animStyle = "Slide";
        } else if (presetName === "Minimal") {
            root.animWindowsSpeed = 3.0;
            root.animWorkspacesSpeed = 3.0;
            root.animFadeSpeed = 2.5;
            root.animBezier = "smoothOut";
            root.animStyle = "Slide";
        } else if (presetName === "Balanced") {
            root.animWindowsSpeed = 5.0;
            root.animWorkspacesSpeed = 3.5;
            root.animFadeSpeed = 2.5;
            root.animBezier = "overshot";
            root.animStyle = "Slide";
        }
        applyAnimations();
    }

    ScrollView {
        id: scrollView
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        anchors.fill: parent
        anchors.bottomMargin: 28
        leftPadding: 32
        rightPadding: 32
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 20

            // =========================================================
            // 1. WINDOW GAPS
            // =========================================================
            NCard {
                sectionTitle: "Window Gaps"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueae9" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Inner gaps"; color: root.cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Space between tiled windows"; color: root.cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 10
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 0; to: 40; stepSize: 1
                            value: root.gapsIn
                            onValueChanged: root.gapsIn = Math.round(value)
                            onPressedChanged: { if (!pressed) root.applyGaps() }
                        }
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb19" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Outer gaps"; color: root.cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Space between windows and screen edges"; color: root.cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 10
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 0; to: 60; stepSize: 1
                            value: root.gapsOut
                            onValueChanged: root.gapsOut = Math.round(value)
                            onPressedChanged: { if (!pressed) root.applyGaps() }
                        }
                    }
                }
            }

            // =========================================================
            // 2. WINDOW STYLE
            // =========================================================
            NCard {
                sectionTitle: "Window Style"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb45" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Window borders"; color: root.cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Show borders around windows"; color: root.cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        id: borderSwitch
                        checked: root.bordersEnabled
                        onToggled: {
                            root.bordersEnabled = checked
                            root.applyBorder()
                        }
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb7a" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Corner rounding"; color: root.cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Radius applied to all window corners"; color: root.cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 10
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 0; to: 30; stepSize: 1
                            value: root.rounding
                            onValueChanged: root.rounding = Math.round(value)
                            onPressedChanged: { if (!pressed) root.applyRounding() }
                        }
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb45" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Border size"; color: root.cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Thickness of window borders"; color: root.cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 10
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 0; to: 10; stepSize: 1
                            value: root.borderSize
                            onValueChanged: root.borderSize = Math.round(value)
                            onPressedChanged: { if (!pressed) root.applyBorder() }
                        }
                    }
                }
            }

            // =========================================================
            // 3. HYPRLAND ANIMATIONS & MOTION
            // =========================================================
            NCard {
                sectionTitle: "Hyprland Animations"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea12" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Enable Animations"; color: root.cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Master switch for all Hyprland window motion and transitions"; color: root.cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.animationsEnabled
                        onToggled: (v) => {
                            root.animationsEnabled = v;
                            root.applyAnimations();
                        }
                    }
                }
            }

            // Presets
            NCard {
                sectionTitle: "Animation Presets"
                visible: root.animationsEnabled

                Item { Layout.preferredHeight: 6 }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: flowPresets.implicitHeight

                    Flow {
                        id: flowPresets
                        anchors.fill: parent
                        spacing: 8

                        Repeater {
                            model: root.availablePresets
                            delegate: Rectangle {
                                id: presetPill
                                required property string modelData
                                property bool active: root.animationPreset === modelData
                                property bool hovered: presetMa.containsMouse

                                radius: 8
                                height: 28
                                width: presetText.implicitWidth + 26
                                color: active ? root.cAccent : (hovered ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08) : root.cBgCard)
                                border.color: active ? root.cAccent : root.cBorder
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    id: presetText
                                    anchors.centerIn: parent
                                    text: presetPill.modelData
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: presetPill.active ? Theme.colOnPrimary : root.cTextDim
                                }

                                MouseArea {
                                    id: presetMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setPreset(presetPill.modelData)
                                }
                            }
                        }
                    }
                }

                Item { Layout.preferredHeight: 8 }
            }

            // Window Motion & Physics Sliders
            NCard {
                sectionTitle: "Window Motion & Physics"
                visible: root.animationsEnabled

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueaf4" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Window Animation Style"; color: root.cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Visual transition style when windows open or change"; color: root.cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: ["Slide", "Popin", "SlideVert"]
                        current: root.animStyle
                        onSelected: (v) => {
                            root.animStyle = v;
                            root.animationPreset = "Custom";
                            root.applyAnimations();
                        }
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueaf2" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Window Speed"; color: root.cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Duration and responsiveness for opening & closing windows"; color: root.cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 10
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 1.0; to: 10.0; stepSize: 0.5
                            value: root.animWindowsSpeed
                            onValueChanged: root.animWindowsSpeed = value
                            onPressedChanged: {
                                if (!pressed) {
                                    root.animationPreset = "Custom";
                                    root.applyAnimations();
                                }
                            }
                        }
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea41" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Workspace Slide Speed"; color: root.cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Transition duration when switching between virtual desktops"; color: root.cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 10
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 1.0; to: 10.0; stepSize: 0.5
                            value: root.animWorkspacesSpeed
                            onValueChanged: root.animWorkspacesSpeed = value
                            onPressedChanged: {
                                if (!pressed) {
                                    root.animationPreset = "Custom";
                                    root.applyAnimations();
                                }
                            }
                        }
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb13" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Fade Transition Speed"; color: root.cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Cross-fade opacity speed for surfaces and overlays"; color: root.cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 10
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 1.0; to: 8.0; stepSize: 0.5
                            value: root.animFadeSpeed
                            onValueChanged: root.animFadeSpeed = value
                            onPressedChanged: {
                                if (!pressed) {
                                    root.animationPreset = "Custom";
                                    root.applyAnimations();
                                }
                            }
                        }
                    }
                }
            }

            // Animation Curves (Beziers)
            NCard {
                sectionTitle: "Animation Curves (Beziers)"
                visible: root.animationsEnabled

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb00" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Easing Curve"; color: root.cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Mathematical Bezier curve controlling acceleration and damping"; color: root.cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox {
                        model: root.availableBeziers
                        currentIndex: {
                            for (let i = 0; i < root.availableBeziers.length; i++) {
                                if (root.availableBeziers[i] === root.animBezier) return i;
                            }
                            return 0;
                        }
                        onActivated: (idx) => {
                            root.animBezier = model[idx];
                            root.animationPreset = "Custom";
                            root.applyAnimations();
                        }
                    }
                }
            }

            // =========================================================
            // 4. OVERVIEW
            // =========================================================
            NCard {
                sectionTitle: "Overview"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea41" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Workspace tabs"; color: root.cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Amount of workspaces to show in overview"; color: root.cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 10
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 1; to: 20; stepSize: 1
                            value: root.overviewTabs
                            onValueChanged: { root.overviewTabs = Math.round(value); }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c", "echo '" + root.overviewTabs + "' > ~/.config/cupcake/.overview_tabs && quickshell ipc -p ~/.config/quickshell/shell.qml call opacity setOverviewTabs " + root.overviewTabs]);
                                }
                            }
                        }
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea61" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Tabs scale"; color: root.cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Adjust the size of the overview tabs"; color: root.cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 10
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 0.05; to: 0.30; stepSize: 0.01
                            value: root.overviewScale
                            onValueChanged: { root.overviewScale = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c", "echo '" + root.overviewScale + "' > ~/.config/cupcake/.overview_scale && quickshell ipc -p ~/.config/quickshell/shell.qml call opacity setOverviewScale " + root.overviewScale]);
                                }
                            }
                        }
                    }
                }
            }

            Item { height: 16 }
        }
    }
}
