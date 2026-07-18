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

    component SectionLabel: Text {
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 0.4
        color: Theme.colOnSurface
        opacity: 0.45
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
        color: Qt.rgba(0, 0, 0, 0.28)
        radius: 8
        height: 30
        width: segRow.implicitWidth + 4
        Row {
            id: segRow
            anchors.centerIn: parent
            spacing: 1
            Repeater {
                model: seg.options
                delegate: Rectangle {
                    required property string modelData
                    property bool active: modelData === seg.current
                    height: 26
                    width: segLabel.implicitWidth + 24
                    radius: 6
                    color: active ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.92) : "transparent"
                    Text {
                        id: segLabel
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

    // =====================================================================
    // Main layout
    // =====================================================================

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

            Item { Layout.preferredHeight: 8 }

            // --- Mode section ---

                SettingsCard {
                SectionLabel { text: "Mode" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
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
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
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
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
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
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                            Text {
                                anchors.centerIn: parent
                                text: ""
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
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
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
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
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
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
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
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
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
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
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
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
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
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
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
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
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
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
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
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
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

            Item { Layout.preferredHeight: 8 }
        }
    }
}

