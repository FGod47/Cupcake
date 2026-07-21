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
    property real osdOpacity: 0.95
    property real notifPanelOpacity: 0.90
    property real ccOpacity: 0.85

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
        command: ["cat", Theme.homeDir + "/.config/cupcake/.osd_opacity"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { let v = parseFloat(text.trim()); if (!isNaN(v)) root.osdOpacity = v; }
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
        command: ["cat", Theme.homeDir + "/.config/cupcake/.notif_panel_opacity"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { let v = parseFloat(text.trim()); if (!isNaN(v)) root.notifPanelOpacity = v; }
            }
        }
    }

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.cc_opacity"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { let v = parseFloat(text.trim()); if (!isNaN(v)) root.ccOpacity = v; }
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



    // =====================================================================
    // Reusable inline components
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





    component Pill: Rectangle {
        id: pill
        property string label: ""
        property bool active: false
        signal clicked()

        radius: 8
        height: 26
        width: pillText.implicitWidth + 24
        color: active ? (root.colorMode === "Light" ? "black" : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.92)) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)

        Text {
            id: pillText
            anchors.centerIn: parent
            text: pill.label
            font.family: Theme.defaultFontFamily
            font.pixelSize: 12
            font.weight: Font.Medium
            color: active ? (root.colorMode === "Light" ? "white" : Theme.colSurface) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.65)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: pill.clicked()
            cursorShape: Qt.PointingHandCursor
        }
    }

    component SettingsRow: ColumnLayout {
        default property alias content: innerRow.data
        Layout.fillWidth: true
        Layout.topMargin: Theme.rowSpacing
        Layout.bottomMargin: Theme.rowSpacing
        spacing: 12
        RowLayout {
            id: innerRow
            Layout.fillWidth: true
            spacing: 12
        }
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
            visible: Theme.showDividers
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
            id: mainCol
            width: parent.width
            spacing: 24



            // --- Mode section ---

                SettingsCard {
                sectionTitle: "Mode"

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: root.colorMode === "Light" ? "\ueb30" : "\ueb2e"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Color Mode"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Switch between light and dark theme"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
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
                sectionTitle: "Accent"

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb3b"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Color Scheme"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Choose the accent palette for the interface"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: flowLayout.implicitHeight

                    Rectangle {
                        id: accentHighlight
                        property Item activeItem: null
                        
                        x: activeItem ? activeItem.x : 0
                        y: activeItem ? activeItem.y : 0
                        width: activeItem ? activeItem.width : 0
                        height: activeItem ? activeItem.height : 0
                        
                        color: root.colorMode === "Light" ? "black" : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.92)
                        radius: 8
                        z: 1
                        
                        property bool activeHovered: activeItem && activeItem.hovered
                        scale: activeHovered ? 1.08 : 1.0
                        
                        Behavior on x { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
                        Behavior on y { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
                        Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
                        Behavior on height { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
                        Behavior on scale { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
                    }

                    Flow {
                        id: flowLayout
                        anchors.fill: parent
                        spacing: 6
                        z: 2

                        Repeater {
                            model: ["Tonal Spot", "Content", "Expressive", "Fidelity", "Fruit Salad", "Monochrome", "Neutral", "Rainbow", "Vibrant"]
                            delegate: Rectangle {
                                id: pillDel
                                required property string modelData
                                property bool active: root.accent === modelData
                                property bool hovered: accentMa.containsMouse
                                
                                radius: 8
                                height: 26
                                width: pText.implicitWidth + 24
                                color: active ? "transparent" : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
                                
                                Text {
                                    id: pText
                                    anchors.centerIn: parent
                                    text: pillDel.modelData
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: pillDel.active ? (root.colorMode === "Light" ? "white" : Theme.colSurface) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.65)
                                    Behavior on color { ColorAnimation { duration: 350 } }
                                }
                                
                                MouseArea {
                                    id: accentMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.accent = pillDel.modelData;
                                        Quickshell.execDetached(["bash", "-c", "echo '" + pillDel.modelData + "' > ~/.config/cupcake/.color_scheme && ~/.local/bin/set-theme"]);
                                    }
                                }
                                
                                onActiveChanged: {
                                    if (active) accentHighlight.activeItem = pillDel
                                }
                                
                                Component.onCompleted: {
                                    if (active) accentHighlight.activeItem = pillDel
                                }
                            }
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
                                text: "\ueb3b"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Dynamic Accent"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Derive accent color from the current wallpaper"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
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
                sectionTitle: "Quick Toggles"

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
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Toggle style"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Choose the visual style for toggle switches"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: ["Cloud", "Android"]
                        current: root.toggleStyle
                        onSelected: (v) => root.toggleStyle = v
                    }
                }

            }

            // --- Blur section ---

                SettingsCard {
                sectionTitle: "Transparency & Blur"

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
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Background blur"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Enable frosted-glass blur behind panels"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
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
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueaa2"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Strength"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Adjust the intensity of the blur effect"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        
                        StyledSlider {
                            Layout.preferredWidth: 220
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
                                text: "\ueb00"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Opacity"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Global translucency level for all surfaces"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 0.1; to: 1.0; stepSize: 0.05
                            value: root.globalOpacity
                            onValueChanged: { root.globalOpacity = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c", "sed -i 's/^OPACITY=.*/OPACITY=" + root.globalOpacity.toFixed(2) + "/' ~/.config/cupcake/.transparency_values && ~/.local/bin/apply-transparency"]);
                                }
                            }
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
                                text: "\ueb00"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Passes"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Number of blur iterations — higher is smoother"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 1; to: 5; stepSize: 1
                            value: root.blurPasses
                            onValueChanged: { root.blurPasses = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c", "sed -i 's/^BLUR_PASSES=.*/BLUR_PASSES=" + Math.round(root.blurPasses) + "/' ~/.config/cupcake/.transparency_values && ~/.local/bin/apply-transparency"]);
                                }
                            }
                        }
                        
                        
                    }
                }
            }

            SettingsCard {
                sectionTitle: "Quickshell Opacity"

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\uead7"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Quickshell blur"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Enable transparency for the top bar and dock"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
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
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb00"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Top Bar opacity"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Background fill opacity of the status bar"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 0.1; to: 1.0; stepSize: 0.05
                            value: root.barOpacity
                            onValueChanged: { root.barOpacity = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c", "echo '" + root.barOpacity.toFixed(2) + "' > ~/.config/cupcake/.bar_opacity && quickshell -i opacity setBarOpacity " + root.barOpacity]);
                                }
                            }
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
                                text: "\ueb00"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Control Centre opacity"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Background fill opacity of the control centre"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 0.1; to: 1.0; stepSize: 0.05
                            value: root.ccOpacity
                            onValueChanged: { root.ccOpacity = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c", "echo '" + root.ccOpacity.toFixed(2) + "' > ~/.config/cupcake/.cc_opacity && quickshell -i opacity setCcOpacity " + root.ccOpacity]);
                                }
                            }
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
                                text: "\ueb00"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Dock opacity"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Background fill opacity of the application dock"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 0.1; to: 1.0; stepSize: 0.05
                            value: root.dockOpacity
                            onValueChanged: { root.dockOpacity = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c", "echo '" + root.dockOpacity.toFixed(2) + "' > ~/.config/cupcake/.dock_opacity && quickshell -i opacity setDockOpacity " + root.dockOpacity]);
                                }
                            }
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
                                text: "\ueb00"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "OSD opacity"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Background fill opacity of the on-screen display"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 0.1; to: 1.0; stepSize: 0.05
                            value: root.osdOpacity
                            onValueChanged: { root.osdOpacity = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c", "echo '" + root.osdOpacity.toFixed(2) + "' > ~/.config/cupcake/.osd_opacity && quickshell -i opacity setOsdOpacity " + root.osdOpacity]);
                                }
                            }
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
                                text: "\ueb00"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "App Launcher opacity"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Background fill opacity of the app launcher"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 0.1; to: 1.0; stepSize: 0.05
                            value: root.launcherOpacity
                            onValueChanged: { root.launcherOpacity = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c", "echo '" + root.launcherOpacity.toFixed(2) + "' > ~/.config/cupcake/.launcher_opacity"]);
                                }
                            }
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
                                text: "\ueacb"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Wall Switcher opacity"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Background fill opacity of the wallpaper picker"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 0.1; to: 1.0; stepSize: 0.05
                            value: root.wallpaperOpacity
                            onValueChanged: { root.wallpaperOpacity = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c", "echo '" + root.wallpaperOpacity.toFixed(2) + "' > ~/.config/cupcake/.wallpaper_opacity"]);
                                }
                            }
                        }
                        
                        
                    }
                }

                // Moved Settings app opacity to Settings App tab

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb00"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Notification Panel opacity"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Background fill opacity of the notification panel"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 0.1; to: 1.0; stepSize: 0.05
                            value: root.notifPanelOpacity
                            onValueChanged: {
                                root.notifPanelOpacity = value;
                            }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c", "echo '" + root.notifPanelOpacity.toFixed(2) + "' > ~/.config/cupcake/.notif_panel_opacity && quickshell -i opacity setNotifOpacity " + root.notifPanelOpacity]);
                                }
                            }
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
                            root.osdOpacity = v;
                            root.ccOpacity = v;
                            root.launcherOpacity = v;
                            root.wallpaperOpacity = v;
                            root.settingsOpacity = v;
                            
                            let cmd = "echo '" + v.toFixed(2) + "' > ~/.config/cupcake/.dock_opacity && " +
                                      "echo '" + v.toFixed(2) + "' > ~/.config/cupcake/.launcher_opacity && " +
                                      "echo '" + v.toFixed(2) + "' > ~/.config/cupcake/.wallpaper_opacity && " +
                                      "echo '" + v.toFixed(2) + "' > ~/.config/cupcake/.settings_opacity && " +
                                      "echo '" + v.toFixed(2) + "' > ~/.config/cupcake/.cc_opacity && " +
                                      "echo '" + v.toFixed(2) + "' > ~/.config/cupcake/.osd_opacity";
                            
                            Quickshell.execDetached(["bash", "-c", cmd]);
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
                color: Theme.showCardBackground ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03) : "transparent"
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
                        Rectangle { width: 32; height: 32; radius: 16; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\uec50"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Default font"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Main font used throughout the interface"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox { blurSource: scrollView
                        id: defaultFontCombo
                        Layout.preferredWidth: 220
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
                        Rectangle { width: 32; height: 32; radius: 16; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\uec50"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Monospaced font"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Font used for numbers and stats display"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox { blurSource: scrollView
                        id: monoFontCombo
                        Layout.preferredWidth: 220
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
                        Rectangle { width: 32; height: 32; radius: 16; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\ueb5a"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Font weight"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Change the boldness of the interface text"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox { blurSource: scrollView
                        id: fontWeightCombo
                        Layout.preferredWidth: 220
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
                        Rectangle { width: 32; height: 32; radius: 16; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\ueaf2"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Default font size"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Change the size of standard text"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        Rectangle { width: 20; height: 20; radius: 10; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\ueb13"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 9 } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Theme.defaultFontSize = 14; bashProcess.command = ["bash", "-c", "echo '14' > ~/.config/cupcake/.font_size"]; bashProcess.running = true; } }
                        }
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 8; to: 32; stepSize: 1
                            value: Theme.defaultFontSize
                            onValueChanged: { Theme.defaultFontSize = value; }
                            onPressedChanged: { if (!pressed) bashProcess.command = ["bash", "-c", "echo '" + Math.round(value) + "' > ~/.config/cupcake/.font_size"]; bashProcess.running = true; }
                        }
                        
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 32; height: 32; radius: 16; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\ueaf2"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Monospaced font size"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Change the size of monospaced text"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        Rectangle { width: 20; height: 20; radius: 10; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\ueb13"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 9 } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Theme.monoFontScale = 1.0; bashProcess.command = ["bash", "-c", "echo '1.0' > ~/.config/cupcake/.font_mono_scale"]; bashProcess.running = true; } }
                        }
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 50; to: 200; stepSize: 5
                            value: Theme.monoFontScale * 100
                            onValueChanged: { Theme.monoFontScale = value / 100.0; }
                            onPressedChanged: { if (!pressed) bashProcess.command = ["bash", "-c", "echo '" + (value / 100.0) + "' > ~/.config/cupcake/.font_mono_scale"]; bashProcess.running = true; }
                        }
                        
                    }
                }
                }
            } // end Shell fonts card

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                implicitHeight: appFontColumn.implicitHeight + 40
                color: Theme.showCardBackground ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03) : "transparent"
                radius: 12

                ColumnLayout {
                    id: appFontColumn
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 8

                SectionLabel { text: "Application fonts" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 32; height: 32; radius: 16; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\uec50"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "App default font"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Main font for GTK/Qt applications"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox { blurSource: scrollView
                        id: appDefaultFontCombo
                        Layout.preferredWidth: 220
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
                        Rectangle { width: 32; height: 32; radius: 16; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\uec50"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "App monospaced font"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Monospaced font for GTK/Qt applications"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox { blurSource: scrollView
                        id: appMonoFontCombo
                        Layout.preferredWidth: 220
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
                        Rectangle { width: 32; height: 32; radius: 16; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\ueb5a"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "App font weight"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Boldness of GTK/Qt application text"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox { blurSource: scrollView
                        id: appFontWeightCombo
                        Layout.preferredWidth: 220
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
                        Rectangle { width: 32; height: 32; radius: 16; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\ueaf2"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "App default font size"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Size of standard GTK/Qt application text"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        Rectangle { width: 20; height: 20; radius: 10; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\ueb13"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 9 } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Theme.appFontSize = 14; bashProcess.command = ["bash", "-c", "echo '14' > ~/.config/cupcake/.app_font_size && ~/.local/bin/apply-fonts"]; bashProcess.running = true; } }
                        }
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 8; to: 32; stepSize: 1
                            value: Theme.appFontSize
                            onValueChanged: { Theme.appFontSize = value; }
                            onPressedChanged: { if (!pressed) Quickshell.execDetached(["bash", "-c", "echo '" + Math.round(value) + "' > ~/.config/cupcake/.app_font_size && ~/.local/bin/apply-fonts"]); }
                        }
                        
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 32; height: 32; radius: 16; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\ueaf2"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "App monospaced font size"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Size of monospaced GTK/Qt application text"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        Rectangle { width: 20; height: 20; radius: 10; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05); Text { anchors.centerIn: parent; text: "\ueb13"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 9 } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Theme.appMonoScale = 1.0; bashProcess.command = ["bash", "-c", "echo '1.0' > ~/.config/cupcake/.app_font_mono_scale && ~/.local/bin/apply-fonts"]; bashProcess.running = true; } }
                        }
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 50; to: 200; stepSize: 5
                            value: Theme.appMonoScale * 100
                            onValueChanged: { Theme.appMonoScale = value / 100.0; }
                            onPressedChanged: { if (!pressed) bashProcess.command = ["bash", "-c", "echo '" + (value / 100.0) + "' > ~/.config/cupcake/.app_font_mono_scale && ~/.local/bin/apply-fonts"]; bashProcess.running = true; }
                        }
                        
                    }
                }
            } // Close ColumnLayout
            } // Close Rectangle

            SettingsCard {
                sectionTitle: "Settings App Customization"
                
                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb00"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Settings app opacity"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Background fill opacity of this settings panel"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 0.1; to: 1.0; stepSize: 0.05
                            value: root.settingsOpacity
                            onValueChanged: { root.settingsOpacity = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c", "echo '" + root.settingsOpacity.toFixed(2) + "' > ~/.config/cupcake/.settings_opacity"]);
                                }
                            }
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
                                text: "\ueadc"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Slider thickness"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Thinness/thickness of sliders across the UI"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        
                        Rectangle {
                            width: 20; height: 20; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { 
                                anchors.centerIn: parent
                                text: "\ueb13"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 9
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Theme.sliderThickness = 2.0;
                                    Quickshell.execDetached(["bash", "-c", "echo '2' > ~/.config/cupcake/.slider_thickness"]);
                                }
                            }
                        }
                        
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 1; to: 10; stepSize: 1
                            value: Theme.sliderThickness
                            onValueChanged: { Theme.sliderThickness = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c", "echo '" + Math.round(Theme.sliderThickness) + "' > ~/.config/cupcake/.slider_thickness"]);
                                }
                            }
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
                                text: "\ueadc"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Show slider thumbs"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Display a circular thumb on sliders"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledSwitch {
                        checked: Theme.showSliderThumb
                        onCheckedChanged: {
                            if (checked !== Theme.showSliderThumb) {
                                Theme.showSliderThumb = checked;
                                Quickshell.execDetached(["bash", "-c", "echo '" + (checked ? "true" : "false") + "' > ~/.config/cupcake/.show_slider_thumb"]);
                            }
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
                                text: "\ueac4"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Show card backgrounds"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Display a subtle background fill on settings cards"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledSwitch {
                        checked: Theme.showCardBackground
                        onCheckedChanged: {
                            if (checked !== Theme.showCardBackground) {
                                Theme.showCardBackground = checked;
                                Quickshell.execDetached(["bash", "-c", "echo '" + (checked ? "true" : "false") + "' > ~/.config/cupcake/.show_card_background"]);
                            }
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
                                text: "\uea81"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Show option dividers"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Display a thin separator line between each option"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledSwitch {
                        checked: Theme.showDividers
                        onCheckedChanged: {
                            if (checked !== Theme.showDividers) {
                                Theme.showDividers = checked;
                                Quickshell.execDetached(["bash", "-c", "echo '" + (checked ? "true" : "false") + "' > ~/.config/cupcake/.show_dividers"]);
                            }
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
                                text: "\uea23"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Option spacing"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Adjust the vertical space between each option in the list"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        
                        Rectangle {
                            width: 20; height: 20; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { 
                                anchors.centerIn: parent
                                text: "\ueb13"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 9
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Theme.rowSpacing = 4.0;
                                    Quickshell.execDetached(["bash", "-c", "echo '4' > ~/.config/cupcake/.row_spacing"]);
                                }
                            }
                        }
                        
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 0; to: 16; stepSize: 1
                            value: Theme.rowSpacing
                            onValueChanged: { Theme.rowSpacing = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c", "echo '" + Math.round(Theme.rowSpacing) + "' > ~/.config/cupcake/.row_spacing"]);
                                }
                            }
                        }
                        
                        
                    }
                }
            }

        } // Close main ColumnLayout
    } // Close ScrollView
} // Close root Item
