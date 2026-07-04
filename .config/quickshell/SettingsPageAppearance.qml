import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "theme"
import Quickshell.Io
import Quickshell

Item {
    id: root
    Process { id: bashProcess }
    
    // Properties simulating the backend state for this page
    property string uiStyle: "Liquid"
    property string accent: "Tonal Spot"
    
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.color_scheme"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let s = text.trim();
                if (s !== "") root.accent = s;
            }
        }
    }

    property bool dynamicAccent: false
    
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.dynamic_accent"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.dynamicAccent = (text.trim() === "true");
            }
        }
    }

    property string toggleStyle: "Android"
    property bool backgroundBlur: true
    property real blurStrength: 0.77
    property bool barTransparency: true

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.bar_transparency"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "false") { root.barTransparency = false; }
                else { root.barTransparency = true; }
            }
        }
    }
    
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.transparency"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.backgroundBlur = (text.trim() === "true");
            }
        }
    }

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.transparency_values"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.length > 0) {
                    let lines = text.trim().split('\n');
                    for (let i = 0; i < lines.length; i++) {
                        if (lines[i].startsWith('BLUR_SIZE=')) {
                            let size = parseInt(lines[i].split('=')[1]);
                            root.blurStrength = size / 20.0;
                        }
                    }
                }
            }
        }
    }

    property string accentScriptPath: "#!/config/quickshell-glasscract-accent.sh"

    // =====================================================================
    // Reusable inline components
    // =====================================================================

    component SectionLabel: Text {
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 0.4
        color: Theme.colOnSurface
        opacity: 0.45
    }

    component ToggleSwitch: Rectangle {
        id: sw
        property bool checked: false
        signal toggled(bool checked)
        width: 38; height: 22
        radius: height / 2
        color: checked ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.15)
        border.width: checked ? 0 : 1
        border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.1)

        Behavior on color { ColorAnimation { duration: 120 } }

        Rectangle {
            width: 18; height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: sw.checked ? parent.width - width - 2 : 2
            color: sw.checked ? Theme.colSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.8)
            Behavior on x { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: { sw.checked = !sw.checked; sw.toggled(sw.checked) }
        }
    }

    component SegmentedControl: Rectangle {
        id: seg
        property var options: []
        property string current: options.length > 0 ? options[0] : ""
        signal selected(string value)

        color: Qt.rgba(0, 0, 0, 0.28)
        radius: 8
        height: 30
        width: row.implicitWidth + 4

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 1

            Repeater {
                model: seg.options
                delegate: Rectangle {
                    required property string modelData
                    property bool active: modelData === seg.current
                    height: 26
                    width: label.implicitWidth + 24
                    radius: 6
                    color: active ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.92) : "transparent"

                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: modelData
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: active ? Theme.colSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.5)
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: { seg.current = modelData; seg.selected(modelData) }
                    }
                }
            }
        }
    }

    component Pill: Rectangle {
        id: pill
        property string label: ""
        property bool active: false
        signal clicked()

        radius: 8
        height: 26
        width: pillText.implicitWidth + 24
        color: active ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.92) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)

        Text {
            id: pillText
            anchors.centerIn: parent
            text: pill.label
            font.family: Theme.defaultFontFamily
            font.pixelSize: 12
            font.weight: Font.Medium
            color: active ? Theme.colSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.65)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: pill.clicked()
            cursorShape: Qt.PointingHandCursor
        }
    }

    component SettingsRow: RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        spacing: 12
    }

    // =====================================================================
    // Main layout
    // =====================================================================

    ScrollView {
        id: scrollView
        anchors.fill: parent
        anchors.margins: 30
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 24

            // --- Header ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                
                Rectangle {
                    width: 42
                    height: 42
                    radius: 12
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    
                    Text {
                        anchors.centerIn: parent
                        text: "󰏘"
                        color: Theme.colOnSurface
                        font.family: Theme.monoFontFamily
                        font.pixelSize: 22
                    }
                }

                Text {
                    text: "Appearance"
                    color: Theme.colOnSurface
                    font.family: Theme.monoFontFamily
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                }
            }

            // --- Mode section ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.topMargin: 16
                spacing: 8

                SectionLabel { text: "Mode" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Text { text: "󰖶"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 16 }
                        Text { text: "UI Style"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: ["Glass", "Liquid", "Classic"]
                        current: root.uiStyle
                        onSelected: (v) => root.uiStyle = v
                    }
                }
            }

            // --- Accent section ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.topMargin: 16
                spacing: 8

                SectionLabel { text: "Accent" }

                Flow {
                    Layout.fillWidth: true
                    Layout.maximumWidth: scrollView.availableWidth - 40
                    spacing: 6

                    Repeater {
                        model: ["Tonal Spot", "Content", "Expressive", "Fidelity", "Fruit Salad", "Monochrome", "Neutral", "Rainbow"]
                        delegate: Pill {
                            required property string modelData
                            label: modelData
                            active: root.accent === modelData
                            onClicked: {
                                root.accent = modelData;
                                bashProcess.command = ["bash", "-c", "echo '" + modelData + "' > ~/.config/cupcake/.color_scheme && ~/.local/bin/set-theme"]; bashProcess.running = true;
                            }
                        }
                    }
                } 
                
                SettingsRow {
                    Layout.topMargin: 6
                    RowLayout {
                        spacing: 12
                        Text { text: "󰓎"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 16 }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Dynamic Accent"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Wallpaper"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch {
                        checked: root.dynamicAccent
                        onToggled: (c) => { root.dynamicAccent = c; bashProcess.command = ["bash", "-c", "echo '" + c + "' > ~/.config/cupcake/.dynamic_accent"]; bashProcess.running = true; }
                    }
                }
            }

            // --- Quick Toggles section ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.topMargin: 16
                spacing: 8

                SectionLabel { text: "Quick Toggles" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Text { text: "󰖰"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 16 }
                        Text { text: "Toggle style"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: ["Cloud", "Android"]
                        current: root.toggleStyle
                        onSelected: (v) => root.toggleStyle = v
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Text { text: "󰑐"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 16 }
                        Text { text: "Accent script"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        radius: 6
                        color: Qt.rgba(0,0,0,0.25)
                        implicitWidth: pathText.implicitWidth + 16
                        implicitHeight: 22
                        Text {
                            id: pathText
                            anchors.centerIn: parent
                            text: root.accentScriptPath
                            font.family: "monospace"
                            font.pixelSize: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.55)
                            elide: Text.ElideMiddle
                        }
                    }
                }
            }

            // --- Blur section ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.topMargin: 16
                spacing: 8

                SectionLabel { text: "Blur" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Text { text: "󰊿"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 16 }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Background blur"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "strength " + Math.round(root.blurStrength * 100) + "%"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch {
                        checked: root.backgroundBlur
                        onToggled: (c) => {
                            root.backgroundBlur = c;
                            Theme.globalTransparency = c;
                            bashProcess.command = ["bash", "-c", "echo " + c + " > ~/.config/cupcake/.transparency && ~/.local/bin/apply-transparency"]; bashProcess.running = true;
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Text { text: "󰝰"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 16 }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Quickshell blur"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "top bar & dock"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch {
                        checked: root.barTransparency
                        onToggled: (c) => {
                            root.barTransparency = c;
                            Theme.quickshellTransparency = c;
                            bashProcess.command = ["bash", "-c", "echo " + c + " > ~/.config/cupcake/.bar_transparency && ~/.local/bin/apply-transparency"]; bashProcess.running = true;
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Text { text: "󰖟"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 16 }
                        Text { text: "Strength"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        implicitHeight: 20

                        Rectangle {
                            id: track
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 34
                            height: 4
                            radius: 2
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.15)

                            Rectangle {
                                width: track.width * root.blurStrength
                                height: parent.height
                                radius: 2
                                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.7)
                            }

                            Rectangle {
                                x: track.width * root.blurStrength - 7
                                anchors.verticalCenter: parent.verticalCenter
                                width: 14; height: 14; radius: 7
                                color: Theme.colOnSurface

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    drag.target: parent
                                    drag.axis: Drag.XAxis
                                    drag.minimumX: -7
                                    drag.maximumX: track.width - 7
                                    onPositionChanged: {
                                        if (drag.active) {
                                            root.blurStrength = (parent.x + 7) / track.width;
                                        }
                                    }
                                    onReleased: {
                                        let size = Math.max(1, Math.round(root.blurStrength * 20));
                                        bashProcess.command = ["bash", "-c", "sed -i 's/^BLUR_SIZE=.*/BLUR_SIZE=" + size + "/' ~/.config/cupcake/.transparency_values && ~/.local/bin/apply-transparency"]; bashProcess.running = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true; implicitHeight: 40 }
        }
    }
}
