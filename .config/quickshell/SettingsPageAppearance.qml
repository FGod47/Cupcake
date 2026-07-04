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


    component SettingsCard: Rectangle {
        default property alias content: innerCol.data
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        implicitHeight: innerCol.implicitHeight + 40
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
        anchors.topMargin: 0
        anchors.bottomMargin: 30
        anchors.leftMargin: 0
        anchors.rightMargin: 24
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 24



            // --- Mode section ---

                SettingsCard {
                SectionLabel { text: "Mode" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb3f"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
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

                }

                SettingsCard {
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
                
                }

            // --- Quick Toggles section ---

                SettingsCard {
                SectionLabel { text: "Quick Toggles" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb13"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
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
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "󰑐"
                                color: Theme.colOnSurfaceVariant
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 16
                            }
                        }
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

                SettingsCard {
                SectionLabel { text: "Blur" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb0a"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
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
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueaad"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
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
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb54"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        Text { text: "Strength"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 0; to: 1.0; stepSize: 0.01
                            value: root.blurStrength
                            onValueChanged: { root.blurStrength = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    let size = Math.max(1, Math.round(root.blurStrength * 20));
                                    bashProcess.command = ["bash", "-c", "sed -i 's/^BLUR_SIZE=.*/BLUR_SIZE=" + size + "/' ~/.config/cupcake/.transparency_values && ~/.local/bin/apply-transparency"]; bashProcess.running = true;
                                }
                            }
                        }
                        
                        Text { 
                            text: Math.round(root.blurStrength * 100) + "%"
                            color: Theme.colOnSurfaceVariant
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 12
                            Layout.preferredWidth: 32
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }

            // --- Fonts section ---
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                implicitHeight: fontColumn.implicitHeight + 40
                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                radius: 12

                ColumnLayout {
                    id: fontColumn
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 8

                SectionLabel { text: "Shell fonts" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 30; height: 30; radius: 15; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\uebc5"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 13 } }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Default font"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "Main font used throughout the interface"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox {
                        id: defaultFontCombo
                        Layout.preferredWidth: 160
                        model: ["Inter"]
                        currentIndex: model.indexOf(Theme.defaultFontFamily) !== -1 ? model.indexOf(Theme.defaultFontFamily) : 0
                        onActivated: (index) => {
                            let font = model[index];
                            Theme.defaultFontFamily = font;
                            bashProcess.command = ["bash", "-c", "echo '" + font + "' > ~/.config/cupcake/.font_default"]; bashProcess.running = true;
                        }
                        
                        Process {
                            command: ["bash", "-c", "fc-list : family | cut -d, -f1 | sort | uniq"]
                            running: true
                            stdout: StdioCollector {
                                onStreamFinished: {
                                    if (text.trim() !== "") {
                                        let fonts = text.trim().split("\n");
                                        defaultFontCombo.model = fonts;
                                        defaultFontCombo.currentIndex = defaultFontCombo.model.indexOf(Theme.defaultFontFamily) !== -1 ? defaultFontCombo.model.indexOf(Theme.defaultFontFamily) : 0;
                                    }
                                }
                            }
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 30; height: 30; radius: 15; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\uebc5"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 13 } }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Monospaced font"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "Font used for numbers and stats display"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox {
                        id: monoFontCombo
                        Layout.preferredWidth: 160
                        model: ["JetBrainsMono Nerd Font Propo"]
                        currentIndex: model.indexOf(Theme.monoFontFamily) !== -1 ? model.indexOf(Theme.monoFontFamily) : 0
                        onActivated: (index) => {
                            let font = model[index];
                            Theme.monoFontFamily = font;
                            bashProcess.command = ["bash", "-c", "echo '" + font + "' > ~/.config/cupcake/.font_mono"]; bashProcess.running = true;
                        }
                        
                        Process {
                            command: ["bash", "-c", "fc-list : spacing=100:family | cut -d, -f1 | sort | uniq"]
                            running: true
                            stdout: StdioCollector {
                                onStreamFinished: {
                                    if (text.trim() !== "") {
                                        let fonts = text.trim().split("\n");
                                        monoFontCombo.model = fonts;
                                        monoFontCombo.currentIndex = monoFontCombo.model.indexOf(Theme.monoFontFamily) !== -1 ? monoFontCombo.model.indexOf(Theme.monoFontFamily) : 0;
                                    }
                                }
                            }
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 30; height: 30; radius: 15; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\uf2b1"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 13 } }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Font weight"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "Change the boldness of the interface text"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox {
                        id: fontWeightCombo
                        Layout.preferredWidth: 160
                        model: ["Light (300)", "Regular (400)", "Medium (500)", "SemiBold (600)", "Bold (700)", "ExtraBold (800)"]
                        Component.onCompleted: {
                            if (Theme.defaultFontWeight <= 300) currentIndex = 0;
                            else if (Theme.defaultFontWeight <= 400) currentIndex = 1;
                            else if (Theme.defaultFontWeight <= 500) currentIndex = 2;
                            else if (Theme.defaultFontWeight <= 600) currentIndex = 3;
                            else if (Theme.defaultFontWeight <= 700) currentIndex = 4;
                            else currentIndex = 5;
                        }
                        onActivated: (index) => {
                            let w = 500;
                            if (index === 0) w = 300;
                            else if (index === 1) w = 400;
                            else if (index === 2) w = 500;
                            else if (index === 3) w = 600;
                            else if (index === 4) w = 700;
                            else if (index === 5) w = 800;
                            Theme.defaultFontWeight = w;
                            bashProcess.command = ["bash", "-c", "echo '" + w + "' > ~/.config/cupcake/.font_weight"]; bashProcess.running = true;
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 30; height: 30; radius: 15; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\u2212"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 13 } }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Default font size"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "Change the size of standard text"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 8; to: 32; stepSize: 1
                            value: Theme.defaultFontSize
                            onValueChanged: { Theme.defaultFontSize = value; }
                            onPressedChanged: { if (!pressed) bashProcess.command = ["bash", "-c", "echo '" + Math.round(value) + "' > ~/.config/cupcake/.font_size"]; bashProcess.running = true; }
                        }
                        Text { text: Theme.defaultFontSize + "px"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Math.min(900, Theme.defaultFontWeight + 200); Layout.preferredWidth: 32 }
                        Rectangle { width: 20; height: 20; radius: 10; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\ueb13"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 9 } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Theme.defaultFontSize = 14; bashProcess.command = ["bash", "-c", "echo '14' > ~/.config/cupcake/.font_size"]; bashProcess.running = true; } }
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 30; height: 30; radius: 15; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\u2212"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 13 } }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Monospaced font size"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "Change the size of monospaced text"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 50; to: 200; stepSize: 5
                            value: Theme.monoFontScale * 100
                            onValueChanged: { Theme.monoFontScale = value / 100.0; }
                            onPressedChanged: { if (!pressed) bashProcess.command = ["bash", "-c", "echo '" + (value / 100.0) + "' > ~/.config/cupcake/.font_mono_scale"]; bashProcess.running = true; }
                        }
                        Text { text: Math.round(Theme.monoFontScale * 100) + "%"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Math.min(900, Theme.defaultFontWeight + 200); Layout.preferredWidth: 32 }
                        Rectangle { width: 20; height: 20; radius: 10; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\ueb13"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 9 } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Theme.monoFontScale = 1.0; bashProcess.command = ["bash", "-c", "echo '1.0' > ~/.config/cupcake/.font_mono_scale"]; bashProcess.running = true; } }
                        }
                    }
                }
            
                Item { Layout.fillWidth: true; implicitHeight: 16 }

                SectionLabel { text: "Application fonts" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 30; height: 30; radius: 15; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\uebc5"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 13 } }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "App default font"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "Main font for GTK/Qt applications"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox {
                        id: appDefaultFontCombo
                        Layout.preferredWidth: 160
                        model: ["Inter"]
                        currentIndex: model.indexOf(Theme.appFontFamily) !== -1 ? model.indexOf(Theme.appFontFamily) : 0
                        onActivated: (index) => {
                            let font = model[index];
                            Theme.appFontFamily = font;
                            bashProcess.command = ["bash", "-c", "echo '" + font + "' > ~/.config/cupcake/.app_font_default && ~/.local/bin/apply-fonts"]; bashProcess.running = true;
                        }
                        
                        Process {
                            command: ["bash", "-c", "fc-list : family | cut -d, -f1 | sort | uniq"]
                            running: true
                            stdout: StdioCollector {
                                onStreamFinished: {
                                    if (text.trim() !== "") {
                                        let fonts = text.trim().split("\n");
                                        appDefaultFontCombo.model = fonts;
                                        appDefaultFontCombo.currentIndex = appDefaultFontCombo.model.indexOf(Theme.appFontFamily) !== -1 ? appDefaultFontCombo.model.indexOf(Theme.appFontFamily) : 0;
                                    }
                                }
                            }
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 30; height: 30; radius: 15; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\uebc5"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 13 } }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "App monospaced font"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "Monospaced font for GTK/Qt applications"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox {
                        id: appMonoFontCombo
                        Layout.preferredWidth: 160
                        model: ["JetBrainsMono Nerd Font Propo"]
                        currentIndex: model.indexOf(Theme.appMonoFamily) !== -1 ? model.indexOf(Theme.appMonoFamily) : 0
                        onActivated: (index) => {
                            let font = model[index];
                            Theme.appMonoFamily = font;
                            bashProcess.command = ["bash", "-c", "echo '" + font + "' > ~/.config/cupcake/.app_font_mono && ~/.local/bin/apply-fonts"]; bashProcess.running = true;
                        }
                        
                        Process {
                            command: ["bash", "-c", "fc-list : spacing=100:family | cut -d, -f1 | sort | uniq"]
                            running: true
                            stdout: StdioCollector {
                                onStreamFinished: {
                                    if (text.trim() !== "") {
                                        let fonts = text.trim().split("\n");
                                        appMonoFontCombo.model = fonts;
                                        appMonoFontCombo.currentIndex = appMonoFontCombo.model.indexOf(Theme.appMonoFamily) !== -1 ? appMonoFontCombo.model.indexOf(Theme.appMonoFamily) : 0;
                                    }
                                }
                            }
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 30; height: 30; radius: 15; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\uf2b1"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 13 } }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "App font weight"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "Boldness of GTK/Qt application text"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox {
                        id: appFontWeightCombo
                        Layout.preferredWidth: 160
                        model: ["Light (300)", "Regular (400)", "Medium (500)", "SemiBold (600)", "Bold (700)", "ExtraBold (800)"]
                        Component.onCompleted: {
                            if (Theme.appFontWeight <= 300) currentIndex = 0;
                            else if (Theme.appFontWeight <= 400) currentIndex = 1;
                            else if (Theme.appFontWeight <= 500) currentIndex = 2;
                            else if (Theme.appFontWeight <= 600) currentIndex = 3;
                            else if (Theme.appFontWeight <= 700) currentIndex = 4;
                            else currentIndex = 5;
                        }
                        onActivated: (index) => {
                            let w = 500;
                            if (index === 0) w = 300;
                            else if (index === 1) w = 400;
                            else if (index === 2) w = 500;
                            else if (index === 3) w = 600;
                            else if (index === 4) w = 700;
                            else if (index === 5) w = 800;
                            Theme.appFontWeight = w;
                            bashProcess.command = ["bash", "-c", "echo '" + w + "' > ~/.config/cupcake/.app_font_weight && ~/.local/bin/apply-fonts"]; bashProcess.running = true;
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 30; height: 30; radius: 15; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\u2212"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 13 } }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "App default font size"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "Size of standard GTK/Qt application text"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 8; to: 32; stepSize: 1
                            value: Theme.appFontSize
                            onValueChanged: { Theme.appFontSize = value; }
                            onPressedChanged: { if (!pressed) bashProcess.command = ["bash", "-c", "echo '" + Math.round(value) + "' > ~/.config/cupcake/.app_font_size && ~/.local/bin/apply-fonts"]; bashProcess.running = true; }
                        }
                        Text { text: Theme.appFontSize + "px"; color: Theme.colOnSurfaceVariant; font.family: Theme.appFontFamily; font.pixelSize: 12; font.weight: Math.min(900, Theme.appFontWeight + 200); Layout.preferredWidth: 32 }
                        Rectangle { width: 20; height: 20; radius: 10; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\ueb13"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 9 } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Theme.appFontSize = 14; bashProcess.command = ["bash", "-c", "echo '14' > ~/.config/cupcake/.app_font_size && ~/.local/bin/apply-fonts"]; bashProcess.running = true; } }
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 30; height: 30; radius: 15; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\u2212"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 13 } }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "App monospaced font size"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "Size of monospaced GTK/Qt application text"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 50; to: 200; stepSize: 5
                            value: Theme.appMonoScale * 100
                            onValueChanged: { Theme.appMonoScale = value / 100.0; }
                            onPressedChanged: { if (!pressed) bashProcess.command = ["bash", "-c", "echo '" + (value / 100.0) + "' > ~/.config/cupcake/.app_font_mono_scale && ~/.local/bin/apply-fonts"]; bashProcess.running = true; }
                        }
                        Text { text: Math.round(Theme.appMonoScale * 100) + "%"; color: Theme.colOnSurfaceVariant; font.family: Theme.appFontFamily; font.pixelSize: 12; font.weight: Math.min(900, Theme.appFontWeight + 200); Layout.preferredWidth: 32 }
                        Rectangle { width: 20; height: 20; radius: 10; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\ueb13"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 9 } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Theme.appMonoScale = 1.0; bashProcess.command = ["bash", "-c", "echo '1.0' > ~/.config/cupcake/.app_font_mono_scale && ~/.local/bin/apply-fonts"]; bashProcess.running = true; } }
                        }
                    }
                }
            }
            }
        }
    }
}
