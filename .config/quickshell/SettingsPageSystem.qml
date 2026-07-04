import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "theme"

Item {
    id: root
    
    // =====================================================================
    // Reusable inline components based on the reference UI
    // =====================================================================

    component SectionLabel: Text {
        font.family: Theme.defaultFontFamily
        font.pixelSize: 11
        font.weight: Math.min(900, Theme.defaultFontWeight + 200)
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
                        font.weight: 500
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
            font.weight: 500
            color: active ? Theme.colSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.65)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: pill.clicked()
        }
    }

    component SettingsRow: RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        spacing: 12
    }

    // =====================================================================
    // Main Content
    // =====================================================================

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: Math.min(parent.width, 1000)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 24
            
            Item { Layout.preferredHeight: 8 }

            // --- Shell Fonts section ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 8

                SectionLabel { text: "Shell Fonts" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Text { text: "󰙄"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 16 }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Default Font"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "Main font used throughout the interface"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox {
                        id: defaultFontCombo
                        Layout.preferredWidth: 200
                        model: ["Inter"]
                        currentIndex: model.indexOf(Theme.defaultFontFamily) !== -1 ? model.indexOf(Theme.defaultFontFamily) : 0
                        onActivated: (index) => {
                            let font = model[index];
                            Theme.defaultFontFamily = font;
                            Quickshell.execDetached(["bash", "-c", "echo '" + font + "' > ~/.config/cupcake/.font_default"]);
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
                        Text { text: "󰙄"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 16 }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Monospaced Font"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "Font used for numbers and stats display"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox {
                        id: monoFontCombo
                        Layout.preferredWidth: 200
                        model: ["JetBrainsMono Nerd Font Propo"]
                        currentIndex: model.indexOf(Theme.monoFontFamily) !== -1 ? model.indexOf(Theme.monoFontFamily) : 0
                        onActivated: (index) => {
                            let font = model[index];
                            Theme.monoFontFamily = font;
                            Quickshell.execDetached(["bash", "-c", "echo '" + font + "' > ~/.config/cupcake/.font_mono"]);
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
                        Text { text: "󰖶"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 16 }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Font Weight"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "Change the boldness of the interface text"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox {
                        id: fontWeightCombo
                        Layout.preferredWidth: 200
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
                            Quickshell.execDetached(["bash", "-c", "echo '" + w + "' > ~/.config/cupcake/.font_weight"]);
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Text { text: "󰖰"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 16 }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Default Font Size"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "Change the size of standard text"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        StyledSlider {
                            Layout.preferredWidth: 200
                            from: 8; to: 32; stepSize: 1
                            value: Theme.defaultFontSize
                            onValueChanged: { Theme.defaultFontSize = value; }
                            onPressedChanged: { if (!pressed) Quickshell.execDetached(["bash", "-c", "echo '" + Math.round(value) + "' > ~/.config/cupcake/.font_size"]); }
                        }
                        Text { text: Theme.defaultFontSize + "px"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Math.min(900, Theme.defaultFontWeight + 200); Layout.preferredWidth: 32 }
                        Text {
                            text: "󰑐"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 16
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Theme.defaultFontSize = 14; Quickshell.execDetached(["bash", "-c", "echo '14' > ~/.config/cupcake/.font_size"]); } }
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Text { text: "󰖰"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 16 }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Monospaced Font Size"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "Change the size of monospaced text"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        StyledSlider {
                            Layout.preferredWidth: 200
                            from: 50; to: 200; stepSize: 5
                            value: Theme.monoFontScale * 100
                            onValueChanged: { Theme.monoFontScale = value / 100.0; }
                            onPressedChanged: { if (!pressed) Quickshell.execDetached(["bash", "-c", "echo '" + (value / 100.0) + "' > ~/.config/cupcake/.font_mono_scale"]); }
                        }
                        Text { text: Math.round(Theme.monoFontScale * 100) + "%"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Math.min(900, Theme.defaultFontWeight + 200); Layout.preferredWidth: 32 }
                        Text {
                            text: "󰑐"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 16
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Theme.monoFontScale = 1.0; Quickshell.execDetached(["bash", "-c", "echo '1.0' > ~/.config/cupcake/.font_mono_scale"]); } }
                        }
                    }
                }
            }

            // --- Application Fonts section ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.topMargin: 16
                spacing: 8

                SectionLabel { text: "Application Fonts" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Text { text: "󰙄"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 16 }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "App Default Font"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "Main font for GTK/Qt applications"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox {
                        id: appDefaultFontCombo
                        Layout.preferredWidth: 200
                        model: ["Inter"]
                        currentIndex: model.indexOf(Theme.appFontFamily) !== -1 ? model.indexOf(Theme.appFontFamily) : 0
                        onActivated: (index) => {
                            let font = model[index];
                            Theme.appFontFamily = font;
                            Quickshell.execDetached(["bash", "-c", "echo '" + font + "' > ~/.config/cupcake/.app_font_default && ~/.local/bin/apply-fonts"]);
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
                        Text { text: "󰙄"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 16 }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "App Monospaced Font"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "Monospaced font for GTK/Qt applications"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox {
                        id: appMonoFontCombo
                        Layout.preferredWidth: 200
                        model: ["JetBrainsMono Nerd Font Propo"]
                        currentIndex: model.indexOf(Theme.appMonoFamily) !== -1 ? model.indexOf(Theme.appMonoFamily) : 0
                        onActivated: (index) => {
                            let font = model[index];
                            Theme.appMonoFamily = font;
                            Quickshell.execDetached(["bash", "-c", "echo '" + font + "' > ~/.config/cupcake/.app_font_mono && ~/.local/bin/apply-fonts"]);
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
                        Text { text: "󰖶"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 16 }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "App Font Weight"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "Boldness of GTK/Qt application text"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox {
                        id: appFontWeightCombo
                        Layout.preferredWidth: 200
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
                            Quickshell.execDetached(["bash", "-c", "echo '" + w + "' > ~/.config/cupcake/.app_font_weight && ~/.local/bin/apply-fonts"]);
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Text { text: "󰖰"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 16 }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "App Default Font Size"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "Size of standard GTK/Qt application text"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        StyledSlider {
                            Layout.preferredWidth: 200
                            from: 8; to: 32; stepSize: 1
                            value: Theme.appFontSize
                            onValueChanged: { Theme.appFontSize = value; }
                            onPressedChanged: { if (!pressed) Quickshell.execDetached(["bash", "-c", "echo '" + Math.round(value) + "' > ~/.config/cupcake/.app_font_size && ~/.local/bin/apply-fonts"]); }
                        }
                        Text { text: Theme.appFontSize + "px"; color: Theme.colOnSurfaceVariant; font.family: Theme.appFontFamily; font.pixelSize: 12; font.weight: Math.min(900, Theme.appFontWeight + 200); Layout.preferredWidth: 32 }
                        Text {
                            text: "󰑐"; color: Theme.colOnSurfaceVariant; font.family: Theme.appMonoFamily; font.weight: Theme.appFontWeight; font.pixelSize: 16
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Theme.appFontSize = 14; Quickshell.execDetached(["bash", "-c", "echo '14' > ~/.config/cupcake/.app_font_size && ~/.local/bin/apply-fonts"]); } }
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Text { text: "󰖰"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 16 }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "App Monospaced Font Size"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "Size of monospaced GTK/Qt application text"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        StyledSlider {
                            Layout.preferredWidth: 200
                            from: 50; to: 200; stepSize: 5
                            value: Theme.appMonoScale * 100
                            onValueChanged: { Theme.appMonoScale = value / 100.0; }
                            onPressedChanged: { if (!pressed) Quickshell.execDetached(["bash", "-c", "echo '" + (value / 100.0) + "' > ~/.config/cupcake/.app_font_mono_scale && ~/.local/bin/apply-fonts"]); }
                        }
                        Text { text: Math.round(Theme.appMonoScale * 100) + "%"; color: Theme.colOnSurfaceVariant; font.family: Theme.appFontFamily; font.pixelSize: 12; font.weight: Math.min(900, Theme.appFontWeight + 200); Layout.preferredWidth: 32 }
                        Text {
                            text: "󰑐"; color: Theme.colOnSurfaceVariant; font.family: Theme.appMonoFamily; font.weight: Theme.appFontWeight; font.pixelSize: 16
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Theme.appMonoScale = 1.0; Quickshell.execDetached(["bash", "-c", "echo '1.0' > ~/.config/cupcake/.app_font_mono_scale && ~/.local/bin/apply-fonts"]); } }
                        }
                    }
                }
            }
            
            // --- Language section ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.topMargin: 16
                spacing: 8

                SectionLabel { text: "Language" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Text { text: "󰊿"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 16 }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Application Language"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "Language used in the application's interface"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox {
                        Layout.preferredWidth: 200
                        model: ["Automatic (en)"]
                    }
                }
            }
            
            // SETUP WIZARD BUTTON
            Rectangle {
                Layout.topMargin: 16
                Layout.fillWidth: true
                Layout.minimumWidth: 200
                Layout.maximumWidth: 350
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 38
                color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.8)
                radius: 8
                Text {
                    anchors.centerIn: parent
                    text: "Launch the setup wizard"
                    color: Theme.colOnPrimary
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: Theme.defaultFontSize
                    font.weight: Math.min(900, Theme.defaultFontWeight + 200)
                }
            }

            Item { Layout.preferredHeight: 24 } // Bottom padding
        }
    }
}
