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

// =====================================================================
    // Reusable inline components
    // =====================================================================


    component SettingsCard: Rectangle {
        default property alias content: cardCol.data
        property string sectionTitle: ""
        Layout.fillWidth: true
        radius: 12
        color: cSurface
        border.color: cBorder
        border.width: 1
        implicitHeight: cardCol.implicitHeight + (sectionTitle !== "" ? 56 : 32)
        Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        clip: true

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
                color: cTextDim
                font.family: Theme.defaultFontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
                font.capitalization: Font.AllUppercase
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: cBorder }
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
    // Main UI Layout
    // =====================================================================
    ScrollView {
        id: scrollView
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: Math.min(parent.width, 1000)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20

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


            Item { Layout.preferredHeight: 8 }
        }
    }
}
