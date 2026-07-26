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
    property color cText: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.88)
    property color cTextDim: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.6)
    property color cAccent: Theme.colPrimary
    property color cBgElevated: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)

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

    property string iconTheme: "Papirus-Dark"
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.icon_theme"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let s = text.trim();
                if (s !== "") root.iconTheme = s;
            }
        }
    }

    property string cursorTheme: "Bibata-Modern-Ice"
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.cursor_theme"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let s = text.trim();
                if (s !== "") root.cursorTheme = s;
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

    property string appLauncherStyle: "Hover"
    
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.applauncher_style"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let s = text.trim();
                if (s !== "") root.appLauncherStyle = s;
            }
        }
    }

    property string toggleStyle: "Android"
    property bool backgroundBlur: true
    property real blurStrength: 0.77
    property real globalOpacity: 0.90
    property int blurPasses: 3
    property bool barTransparency: true
    property bool xrayBlur: true
    property real barOpacity: 0.50
    property real dockOpacity: 0.50
    property real launcherOpacity: 0.80
    property real wallpaperOpacity: 0.80
    property real settingsOpacity: 0.80
    property real ccOpacity: 0.85
    property string wallpaperSwitcherStyle: "Carousel"

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.wallpaper_switcher_style"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let s = text.trim();
                if (s !== "") root.wallpaperSwitcherStyle = s;
            }
        }
    }

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
        command: ["cat", Theme.homeDir + "/.config/cupcake/.xray_blur"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim() === "false") { root.xrayBlur = false; }
                else { root.xrayBlur = true; }
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
            color: active ? Theme.colOnPrimary : cTextDim
        }

        MouseArea {
            anchors.fill: parent
            onClicked: pill.clicked()
            cursorShape: Qt.PointingHandCursor
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



            // --- Mode section ---

                NCard {
                sectionTitle: "Mode"

                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                            Text {
                                anchors.centerIn: parent
                                text: root.colorMode === "Light" ? "\ueb30" : "\ueaf8" // sun / moon
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

                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                            Text {
                                anchors.centerIn: parent
                                text: "\uedba" // layout-grid
                                color: cTextDim
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Icon theme"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Select your preferred icon pack"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox {
                        model: ["Papirus-Dark", "Papirus-Light", "Papirus", "Adwaita", "breeze", "breeze-dark"]
                        currentIndex: model.indexOf(root.iconTheme) !== -1 ? model.indexOf(root.iconTheme) : 0
                        onActivated: (idx) => {
                            let val = model[idx];
                            root.iconTheme = val;
                            Quickshell.execDetached(["bash", "-c", "echo '" + val + "' > ~/.config/cupcake/.icon_theme && ~/.local/bin/set-theme"]);
                        }
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                            Text {
                                anchors.centerIn: parent
                                text: "\uee6d" // cursor-text
                                color: cTextDim
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Cursor theme"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Select your preferred cursor style"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox {
                        model: ["Bibata-Modern-Ice", "Bibata-Modern-Classic", "Bibata-Modern-Amber", "Adwaita", "breeze"]
                        currentIndex: model.indexOf(root.cursorTheme) !== -1 ? model.indexOf(root.cursorTheme) : 0
                        onActivated: (idx) => {
                            let val = model[idx];
                            root.cursorTheme = val;
                            Quickshell.execDetached(["bash", "-c", "echo '" + val + "' > ~/.config/cupcake/.cursor_theme && ~/.local/bin/set-theme"]);
                        }
                    }
                }

            }

            // --- Accent section ---
                NCard {
                sectionTitle: "Accent"
                Item { Layout.preferredHeight: 8 }



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
                        
                        color: cAccent
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
                            model: ["Tonal Spot", "Content", "Expressive", "Fidelity", "Fruit Salad", "Monochrome", "Neutral", "Rainbow"]
                            delegate: Rectangle {
                                id: pillDel
                                required property string modelData
                                property bool active: root.accent === modelData
                                property bool hovered: accentMa.containsMouse
                                
                                radius: 8
                                height: 26
                                width: pText.implicitWidth + 24
                                color: active ? "transparent" : cBgElevated
                                
                                Text {
                                    id: pText
                                    anchors.centerIn: parent
                                    text: pillDel.modelData
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: pillDel.active ? Theme.colOnPrimary : cTextDim
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
                
                Item { Layout.preferredHeight: 8 }

                }

            // --- Quick Toggles section ---

                NCard {
                sectionTitle: "Quick Toggles"

                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: cTextDim
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Liquidify"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Enable bouncy jelly animations for UI elements"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: Theme.liquidify
                        onToggled: (v) => {
                            Theme.liquidify = v;
                            Quickshell.execDetached(["bash", "-c", "echo '" + (v ? "true" : "false") + "' > ~/.config/cupcake/.liquidify"]);
                        }
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb3e" // toggle-left
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

                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
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

            // --- UI Style section ---

            NCard {
                sectionTitle: "UI Style"

                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueacc" // layout-2 (app launcher style)
                                color: cTextDim
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "App launcher style"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Choose the layout style for the app launcher"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: ["Hug", "Hover"]
                        current: root.appLauncherStyle
                        onSelected: (v) => {
                            root.appLauncherStyle = v;
                            Quickshell.execDetached(["bash", "-c", "echo '" + v + "' > ~/.config/cupcake/.applauncher_style"]);
                        }
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueeb0" // layout-cards or similar
                                color: cTextDim
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Wallpaper switcher style"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Choose the layout style for the wallpaper switcher"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: ["Carousel", "Showcase"]
                        current: root.wallpaperSwitcherStyle
                        onSelected: (v) => {
                            root.wallpaperSwitcherStyle = v;
                            Quickshell.execDetached(["bash", "-c", "echo '" + v + "' > ~/.config/cupcake/.wallpaper_switcher_style"]);
                        }
                    }
                }
            }

            // --- Blur section ---

                NCard {
                sectionTitle: "Transparency & Blur"

                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
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
                    NToggle {
                        checked: root.backgroundBlur
                        onToggled: (c) => {
                            root.backgroundBlur = c;
                            Theme.globalTransparency = c;
                            Quickshell.execDetached(["bash", "-c", "echo " + c + " > ~/.config/cupcake/.transparency && ~/.local/bin/apply-transparency"]);
                        }
                    }
                }


                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                            Text {
                                anchors.centerIn: parent
                                text: "\uef8c" // blur strength slider
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

                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
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

                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
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

            NCard {
                sectionTitle: "Quickshell Opacity"

                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                            Text {
                                anchors.centerIn: parent
                                text: "\uead7" // layout-navbar (quickshell blur toggle)
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
                    NToggle {
                        checked: root.barTransparency
                        onToggled: (c) => {
                            root.barTransparency = c;
                            Theme.quickshellTransparency = c;
                            Quickshell.execDetached(["bash", "-c", "echo " + c + " > ~/.config/cupcake/.bar_transparency && ~/.local/bin/apply-transparency"]);
                        }
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                            Text {
                                anchors.centerIn: parent
                                text: "\uebc8" // scan (x-ray blur)
                                color: cTextDim
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "X-Ray Blur"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Blur the desktop wallpaper instead of underlying windows"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.xrayBlur
                        onToggled: (c) => {
                            root.xrayBlur = c;
                            Quickshell.execDetached(["bash", "-c", "echo " + c + " > ~/.config/cupcake/.xray_blur && ~/.local/bin/apply-transparency"]);
                        }
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
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
                            Text { text: "Top Bar opacity"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Background fill opacity of the status bar"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
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
                                    Quickshell.execDetached(["bash", "-c", "echo '" + root.barOpacity.toFixed(2) + "' > ~/.config/cupcake/.bar_opacity && quickshell ipc -p ~/.config/quickshell/shell.qml call opacity setBarOpacity " + root.barOpacity + " && ~/.local/bin/apply-transparency"]);
                                }
                            }
                        }
                        
                        
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueac2"
                                color: cTextDim
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Control Centre opacity"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Background fill opacity of the control centre"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
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
                                    Quickshell.execDetached(["bash", "-c", "echo '" + root.ccOpacity.toFixed(2) + "' > ~/.config/cupcake/.cc_opacity && quickshell ipc -p ~/.config/quickshell/shell.qml call opacity setCcOpacity " + root.ccOpacity + " && ~/.local/bin/apply-transparency"]);
                                }
                            }
                        }
                        
                        
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                            Text {
                                anchors.centerIn: parent
                                text: "\uea80"
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
                            Layout.preferredWidth: 220
                            from: 0.1; to: 1.0; stepSize: 0.05
                            value: root.dockOpacity
                            onValueChanged: { root.dockOpacity = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c", "echo '" + root.dockOpacity.toFixed(2) + "' > ~/.config/cupcake/.dock_opacity && quickshell ipc -p ~/.config/quickshell/shell.qml call opacity setDockOpacity " + root.dockOpacity + " && ~/.local/bin/apply-transparency"]);
                                }
                            }
                        }
                        
                        
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb1c"
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

                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
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

                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb20"
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

                NRow {
                    Item { Layout.fillWidth: true }
                    Pill {
                        label: "Sync all opacities to Top Bar"
                        active: true
                        onClicked: {
                            let v = root.barOpacity;
                            root.dockOpacity = v;
                            root.ccOpacity = v;
                            if (root.osdOpacity !== undefined) root.osdOpacity = v;
                            root.launcherOpacity = v;
                            root.wallpaperOpacity = v;
                            root.settingsOpacity = v;
                            
                            let cmd = "echo '" + v.toFixed(2) + "' > ~/.config/cupcake/.dock_opacity && " +
                                      "echo '" + v.toFixed(2) + "' > ~/.config/cupcake/.cc_opacity && " +
                                      "echo '" + v.toFixed(2) + "' > ~/.config/cupcake/.launcher_opacity && " +
                                      "echo '" + v.toFixed(2) + "' > ~/.config/cupcake/.wallpaper_opacity && " +
                                      "echo '" + v.toFixed(2) + "' > ~/.config/cupcake/.settings_opacity && " +
                                      "echo '" + v.toFixed(2) + "' > ~/.config/cupcake/.osd_opacity && " +
                                      "quickshell ipc -p ~/.config/quickshell/shell.qml call opacity setDockOpacity " + v + " && " +
                                      "quickshell ipc -p ~/.config/quickshell/shell.qml call opacity setCcOpacity " + v + " && " +
                                      "quickshell ipc -p ~/.config/quickshell/shell.qml call opacity setOsdOpacity " + v;
                            
                            Quickshell.execDetached(["bash", "-c", cmd]);
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 8 }
        }
    }
}

