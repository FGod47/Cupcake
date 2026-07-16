import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import Quickshell.Io
import Quickshell
import "../common"

Item {
    id: root
    Process { id: bashProcess }
    
    // Properties simulating the backend state for this page
    property string uiStyle: "Liquid"
    property string accent: "Tonal Spot"
    property string colorMode: "Dark"

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.color_mode"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let s = text.trim().toLowerCase();
                if (s === "light") root.colorMode = "Light";
                else root.colorMode = "Dark";
            }
        }
    }
    
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
    property real globalOpacity: 0.90
    property int blurPasses: 3
    property bool barTransparency: true
    property real barOpacity: 0.50
    property real dockOpacity: 0.50
    property real launcherOpacity: 0.80
    property real wallpaperOpacity: 0.80
    property real settingsOpacity: 0.80

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.bar_opacity"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { let v = parseFloat(text.trim()); if (!isNaN(v)) root.barOpacity = v; }
            }
        }
    }

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.dock_opacity"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { let v = parseFloat(text.trim()); if (!isNaN(v)) root.dockOpacity = v; }
            }
        }
    }

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.launcher_opacity"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { let v = parseFloat(text.trim()); if (!isNaN(v)) root.launcherOpacity = v; }
            }
        }
    }

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.wallpaper_opacity"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { let v = parseFloat(text.trim()); if (!isNaN(v)) root.wallpaperOpacity = v; }
            }
        }
    }

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.settings_opacity"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { let v = parseFloat(text.trim()); if (!isNaN(v)) root.settingsOpacity = v; }
            }
        }
    }

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
                        if (lines[i].startsWith('OPACITY=')) {
                            root.globalOpacity = parseFloat(lines[i].split('=')[1]);
                        }
                        if (lines[i].startsWith('BLUR_PASSES=')) {
                            root.blurPasses = parseInt(lines[i].split('=')[1]);
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
        default property alias content: cardCol.data
        Layout.fillWidth: true
        radius: 12
        color: cSurface
        border.color: cBorder
        border.width: 1
        implicitHeight: cardCol.implicitHeight + 32
        Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        clip: true

        ColumnLayout {
            id: cardCol
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.bottomMargin: 16
            spacing: 0
        }
    }

    component SectionLabel: RowLayout {
        property string text: ""
        Layout.fillWidth: true
        Layout.bottomMargin: 8
        spacing: 8
        Text {
            text: parent.text
            color: cTextDim
            font.family: Theme.defaultFontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 0.8
            font.capitalization: Font.AllUppercase
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: cBorder }
    }

    component ToggleSwitch: Rectangle {
        id: tog
        property bool checked: false
        signal toggled(bool checked)
        width: 44; height: 24; radius: 12
        color: checked ? cAccent : cBorderSoft
        Behavior on color { ColorAnimation { duration: 150 } }
        Rectangle {
            width: 18; height: 18; radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: tog.checked ? parent.width - width - 3 : 3
            color: "white"
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: { tog.checked = !tog.checked; tog.toggled(tog.checked) }
        }
    }

    component SegmentedControl: Rectangle {
        id: seg
        property var options: []
        property string current: options.length > 0 ? options[0] : ""
        signal selected(string value)

        color: cBgElevated
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
                    color: active ? cAccent : "transparent"

                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: modelData
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: active ? "white" : cTextDim
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
        color: active ? cAccent : cBgElevated

        Text {
            id: pillText
            anchors.centerIn: parent
            text: pill.label
            font.family: Theme.defaultFontFamily
            font.pixelSize: 12
            font.weight: Font.Medium
            color: active ? "white" : cTextDim
        }

        MouseArea {
            anchors.fill: parent
            onClicked: pill.clicked()
            cursorShape: Qt.PointingHandCursor
        }
    }

    component SettingsRow: Rectangle {
        default property alias content: innerRow.data
        Layout.fillWidth: true
        implicitHeight: innerRow.implicitHeight + 20
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
            id: innerRow
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
            color: cBorder
            opacity: 0.6
        }
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
        anchors.rightMargin: 0
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 24

            Item { Layout.preferredHeight: 8 }

            // --- Mode section ---

                SettingsCard {
                SectionLabel { text: "Mode" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: cBgElevated
                            Text {
                                anchors.centerIn: parent
                                text: root.colorMode === "Light" ? "\ueb30" : "\ueb2e"
                                color: cTextDim
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Color Mode"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Switch between light and dark theme"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: ["Light", "Dark"]
                        current: root.colorMode
                        onSelected: (v) => {
                            root.colorMode = v;
                            Quickshell.execDetached(["bash", "-c", "echo '" + v.toLowerCase() + "' > ~/.config/cupcake/.color_mode && ~/.local/bin/set-theme"]);
                        }
                    }
                }


            }

            // --- Accent section ---
                SettingsCard {
                SectionLabel { text: "Accent" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: cBgElevated
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb3b"
                                color: cTextDim
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Color Scheme"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Choose the accent palette for the interface"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: ["Tonal Spot", "Content", "Expressive", "Fidelity", "Fruit Salad", "Monochrome", "Neutral", "Rainbow"]
                        delegate: Pill {
                            required property string modelData
                            label: modelData
                            active: root.accent === modelData
                            onClicked: {
                                root.accent = modelData;
                                Quickshell.execDetached(["bash", "-c", "echo '" + modelData + "' > ~/.config/cupcake/.color_scheme && ~/.local/bin/set-theme"]);
                            }
                        }
                    }
                } 
                
                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: cBgElevated
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb3b"
                                color: cTextDim
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Dynamic Accent"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Derive accent color from the current wallpaper"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch {
                        checked: root.dynamicAccent
                        onToggled: (c) => {
                            root.dynamicAccent = c;
                            Quickshell.execDetached(["bash", "-c", "echo '" + c + "' > ~/.config/cupcake/.dynamic_accent && ~/.local/bin/set-theme"]);
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
                            width: 32; height: 32; radius: 10
                            color: cBgElevated
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb13"
                                color: cTextDim
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Toggle style"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Choose the visual style for toggle switches"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
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
                            width: 32; height: 32; radius: 10
                            color: cBgElevated
                            Text {
                                anchors.centerIn: parent
                                text: "󰑐"
                                color: cTextDim
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Accent script"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Script path used to apply the accent color"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
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
                SectionLabel { text: "Transparency & Blur" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: cBgElevated
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb13"
                                color: cTextDim
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Background blur"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Enable frosted-glass blur behind panels"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch {
                        checked: root.backgroundBlur
                        onToggled: (c) => {
                            root.backgroundBlur = c;
                            Theme.globalTransparency = c;
                            Quickshell.execDetached(["bash", "-c", "echo " + c + " > ~/.config/cupcake/.transparency && ~/.local/bin/apply-transparency"]);
                        }
                    }
                }


                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: cBgElevated
                            Text {
                                anchors.centerIn: parent
                                text: "\ueaa2"
                                color: cTextDim
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Strength"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Adjust the intensity of the blur effect"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
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
                                    Quickshell.execDetached(["bash", "-c", "sed -i 's/^BLUR_SIZE=.*/BLUR_SIZE=" + size + "/' ~/.config/cupcake/.transparency_values && ~/.local/bin/apply-transparency"]);
                                }
                            }
                        }
                        
                        Text { 
                            text: Math.round(root.blurStrength * 100) + "%"
                            color: cTextDim
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 12
                            Layout.preferredWidth: 32
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: cBgElevated
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb00"
                                color: cTextDim
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Opacity"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Global translucency level for all surfaces"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 0.1; to: 1.0; stepSize: 0.05
                            value: root.globalOpacity
                            onValueChanged: { root.globalOpacity = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c", "sed -i 's/^OPACITY=.*/OPACITY=" + root.globalOpacity.toFixed(2) + "/' ~/.config/cupcake/.transparency_values && ~/.local/bin/apply-transparency"]);
                                }
                            }
                        }
                        
                        Text { 
                            text: Math.round(root.globalOpacity * 100) + "%"
                            color: cTextDim
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 12
                            Layout.preferredWidth: 32
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: cBgElevated
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb00"
                                color: cTextDim
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Passes"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Number of blur iterations — higher is smoother"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 1; to: 5; stepSize: 1
                            value: root.blurPasses
                            onValueChanged: { root.blurPasses = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c", "sed -i 's/^BLUR_PASSES=.*/BLUR_PASSES=" + Math.round(root.blurPasses) + "/' ~/.config/cupcake/.transparency_values && ~/.local/bin/apply-transparency"]);
                                }
                            }
                        }
                        
                        Text { 
                            text: Math.round(root.blurPasses)
                            color: cTextDim
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 12
                            Layout.preferredWidth: 32
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }

            SettingsCard {
                SectionLabel { text: "Quickshell Opacity" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: cBgElevated
                            Text {
                                anchors.centerIn: parent
                                text: "\uead7"
                                color: cTextDim
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Quickshell blur"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Enable transparency for the top bar and dock"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch {
                        checked: root.barTransparency
                        onToggled: (c) => {
                            root.barTransparency = c;
                            Theme.quickshellTransparency = c;
                            Quickshell.execDetached(["bash", "-c", "echo " + c + " > ~/.config/cupcake/.bar_transparency && ~/.local/bin/apply-transparency"]);
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: cBgElevated
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb00"
                                color: cTextDim
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Top Bar opacity"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Background fill opacity of the status bar"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 0.1; to: 1.0; stepSize: 0.05
                            value: root.barOpacity
                            onValueChanged: { root.barOpacity = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c", "echo '" + root.barOpacity.toFixed(2) + "' > ~/.config/cupcake/.bar_opacity"]);
                                }
                            }
                        }
                        
                        Text { 
                            text: Math.round(root.barOpacity * 100) + "%"
                            color: cTextDim
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 12
                            Layout.preferredWidth: 32
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: cBgElevated
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb00"
                                color: cTextDim
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Dock opacity"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Background fill opacity of the application dock"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 0.1; to: 1.0; stepSize: 0.05
                            value: root.dockOpacity
                            onValueChanged: { root.dockOpacity = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c", "echo '" + root.dockOpacity.toFixed(2) + "' > ~/.config/cupcake/.dock_opacity"]);
                                }
                            }
                        }
                        
                        Text { 
                            text: Math.round(root.dockOpacity * 100) + "%"
                            color: cTextDim
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 12
                            Layout.preferredWidth: 32
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: cBgElevated
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb00"
                                color: cTextDim
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "App Launcher opacity"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Background fill opacity of the app launcher"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 0.1; to: 1.0; stepSize: 0.05
                            value: root.launcherOpacity
                            onValueChanged: { root.launcherOpacity = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c", "echo '" + root.launcherOpacity.toFixed(2) + "' > ~/.config/cupcake/.launcher_opacity"]);
                                }
                            }
                        }
                        
                        Text { 
                            text: Math.round(root.launcherOpacity * 100) + "%"
                            color: cTextDim
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 12
                            Layout.preferredWidth: 32
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: cBgElevated
                            Text {
                                anchors.centerIn: parent
                                text: "\ueacb"
                                color: cTextDim
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Wall Switcher opacity"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Background fill opacity of the wallpaper picker"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 0.1; to: 1.0; stepSize: 0.05
                            value: root.wallpaperOpacity
                            onValueChanged: { root.wallpaperOpacity = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c", "echo '" + root.wallpaperOpacity.toFixed(2) + "' > ~/.config/cupcake/.wallpaper_opacity"]);
                                }
                            }
                        }
                        
                        Text { 
                            text: Math.round(root.wallpaperOpacity * 100) + "%"
                            color: cTextDim
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 12
                            Layout.preferredWidth: 32
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: cBgElevated
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb00"
                                color: cTextDim
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Settings app opacity"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Background fill opacity of this settings panel"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 0.1; to: 1.0; stepSize: 0.05
                            value: root.settingsOpacity
                            onValueChanged: { root.settingsOpacity = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c", "echo '" + root.settingsOpacity.toFixed(2) + "' > ~/.config/cupcake/.settings_opacity"]);
                                }
                            }
                        }
                        
                        Text { 
                            text: Math.round(root.settingsOpacity * 100) + "%"
                            color: cTextDim
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 12
                            Layout.preferredWidth: 32
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                SettingsRow {
                    Item { Layout.fillWidth: true }
                    Pill {
                        label: "Sync all opacities to Top Bar"
                        active: true
                        onClicked: {
                            let v = root.barOpacity;
                            root.dockOpacity = v;
                            if (root.osdOpacity !== undefined) root.osdOpacity = v;
                            root.launcherOpacity = v;
                            root.wallpaperOpacity = v;
                            root.settingsOpacity = v;
                            
                            let cmd = "echo '" + v.toFixed(2) + "' > ~/.config/cupcake/.dock_opacity && " +
                                      "echo '" + v.toFixed(2) + "' > ~/.config/cupcake/.launcher_opacity && " +
                                      "echo '" + v.toFixed(2) + "' > ~/.config/cupcake/.wallpaper_opacity && " +
                                      "echo '" + v.toFixed(2) + "' > ~/.config/cupcake/.settings_opacity && " +
                                      "echo '" + v.toFixed(2) + "' > ~/.config/cupcake/.osd_opacity";
                            
                            Quickshell.execDetached(["bash", "-c", cmd]);
                        }
                    }
                }
            }

            // --- Fonts section ---
            SettingsCard {
                sectionTitle: "Shell fonts"

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 32; height: 32; radius: 16; color: cBgElevated; Text { anchors.centerIn: parent; text: "\uec50"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Default font"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Main font used throughout the interface"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox { blurSource: scrollView
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
                        Rectangle { width: 32; height: 32; radius: 16; color: cBgElevated; Text { anchors.centerIn: parent; text: "\uec50"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Monospaced font"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Font used for numbers and stats display"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox { blurSource: scrollView
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
                        Rectangle { width: 32; height: 32; radius: 16; color: cBgElevated; Text { anchors.centerIn: parent; text: "\ueb5a"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Font weight"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Change the boldness of the interface text"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox { blurSource: scrollView
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
                        Rectangle { width: 32; height: 32; radius: 16; color: cBgElevated; Text { anchors.centerIn: parent; text: "\ueaf2"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Default font size"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Change the size of standard text"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        Rectangle { width: 20; height: 20; radius: 10; color: cBgElevated; Text { anchors.centerIn: parent; text: "\ueb13"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 9 } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Theme.defaultFontSize = 14; bashProcess.command = ["bash", "-c", "echo '14' > ~/.config/cupcake/.font_size"]; bashProcess.running = true; } }
                        }
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 8; to: 32; stepSize: 1
                            value: Theme.defaultFontSize
                            onValueChanged: { Theme.defaultFontSize = value; }
                            onPressedChanged: { if (!pressed) bashProcess.command = ["bash", "-c", "echo '" + Math.round(value) + "' > ~/.config/cupcake/.font_size"]; bashProcess.running = true; }
                        }
                        Text { text: Theme.defaultFontSize + "px"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Math.min(900, Theme.defaultFontWeight + 200); Layout.preferredWidth: 32 }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 32; height: 32; radius: 16; color: cBgElevated; Text { anchors.centerIn: parent; text: "\ueaf2"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Monospaced font size"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Change the size of monospaced text"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        Rectangle { width: 20; height: 20; radius: 10; color: cBgElevated; Text { anchors.centerIn: parent; text: "\ueb13"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 9 } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Theme.monoFontScale = 1.0; bashProcess.command = ["bash", "-c", "echo '1.0' > ~/.config/cupcake/.font_mono_scale"]; bashProcess.running = true; } }
                        }
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 50; to: 200; stepSize: 5
                            value: Theme.monoFontScale * 100
                            onValueChanged: { Theme.monoFontScale = value / 100.0; }
                            onPressedChanged: { if (!pressed) bashProcess.command = ["bash", "-c", "echo '" + (value / 100.0) + "' > ~/.config/cupcake/.font_mono_scale"]; bashProcess.running = true; }
                        }
                        Text { text: Math.round(Theme.monoFontScale * 100) + "%"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Math.min(900, Theme.defaultFontWeight + 200); Layout.preferredWidth: 32 }
                    }
            } // end Shell fonts card

            SettingsCard {
                sectionTitle: "Application fonts"

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 32; height: 32; radius: 16; color: cBgElevated; Text { anchors.centerIn: parent; text: "\uec50"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "App default font"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Main font for GTK/Qt applications"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox { blurSource: scrollView
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
                        Rectangle { width: 32; height: 32; radius: 16; color: cBgElevated; Text { anchors.centerIn: parent; text: "\uec50"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "App monospaced font"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Monospaced font for GTK/Qt applications"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox { blurSource: scrollView
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
                        Rectangle { width: 32; height: 32; radius: 16; color: cBgElevated; Text { anchors.centerIn: parent; text: "\ueb5a"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "App font weight"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Boldness of GTK/Qt application text"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox { blurSource: scrollView
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
                        Rectangle { width: 32; height: 32; radius: 16; color: cBgElevated; Text { anchors.centerIn: parent; text: "\ueaf2"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "App default font size"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Size of standard GTK/Qt application text"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        Rectangle { width: 20; height: 20; radius: 10; color: cBgElevated; Text { anchors.centerIn: parent; text: "\ueb13"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 9 } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Theme.appFontSize = 14; bashProcess.command = ["bash", "-c", "echo '14' > ~/.config/cupcake/.app_font_size && ~/.local/bin/apply-fonts"]; bashProcess.running = true; } }
                        }
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 8; to: 32; stepSize: 1
                            value: Theme.appFontSize
                            onValueChanged: { Theme.appFontSize = value; }
                            onPressedChanged: { if (!pressed) Quickshell.execDetached(["bash", "-c", "echo '" + Math.round(value) + "' > ~/.config/cupcake/.app_font_size && ~/.local/bin/apply-fonts"]); }
                        }
                        Text { text: Theme.appFontSize + "px"; color: cTextDim; font.family: Theme.appFontFamily; font.pixelSize: 12; font.weight: Math.min(900, Theme.appFontWeight + 200); Layout.preferredWidth: 32 }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 32; height: 32; radius: 16; color: cBgElevated; Text { anchors.centerIn: parent; text: "\ueaf2"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "App monospaced font size"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Size of monospaced GTK/Qt application text"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        Rectangle { width: 20; height: 20; radius: 10; color: cBgElevated; Text { anchors.centerIn: parent; text: "\ueb13"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 9 } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Theme.appMonoScale = 1.0; bashProcess.command = ["bash", "-c", "echo '1.0' > ~/.config/cupcake/.app_font_mono_scale && ~/.local/bin/apply-fonts"]; bashProcess.running = true; } }
                        }
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 50; to: 200; stepSize: 5
                            value: Theme.appMonoScale * 100
                            onValueChanged: { Theme.appMonoScale = value / 100.0; }
                            onPressedChanged: { if (!pressed) bashProcess.command = ["bash", "-c", "echo '" + (value / 100.0) + "' > ~/.config/cupcake/.app_font_mono_scale && ~/.local/bin/apply-fonts"]; bashProcess.running = true; }
                        }
                        Text { text: Math.round(Theme.appMonoScale * 100) + "%"; color: cTextDim; font.family: Theme.appFontFamily; font.pixelSize: 12; font.weight: Math.min(900, Theme.appFontWeight + 200); Layout.preferredWidth: 32 }
                    }
                }
            }
        }
    }
}
}
