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

    property color cText:       Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.88)
    property color cTextDim:    Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.6)
    property color cAccent:     Theme.colPrimary
    property color cBgElevated: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)

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
    // Main UI Layout
    // =====================================================================
    ScrollView {
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        id: scrollView
        anchors.fill: parent
        leftPadding: 32
        rightPadding: 32
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
                        Rectangle { width: 32; height: 32; radius: 10; color: cBgElevated; Text { anchors.centerIn: parent; text: "\uec50"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Default font"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Main font used throughout the interface"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
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
                        Rectangle { width: 32; height: 32; radius: 10; color: cBgElevated; Text { anchors.centerIn: parent; text: "\uec50"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Monospaced font"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Font used for numbers and stats display"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
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
                        Rectangle { width: 32; height: 32; radius: 10; color: cBgElevated; Text { anchors.centerIn: parent; text: "\ueb5a"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Font weight"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Change the boldness of the interface text"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
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
                        Rectangle { width: 32; height: 32; radius: 10; color: cBgElevated; Text { anchors.centerIn: parent; text: "\ueaf2"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 } }
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
                        Rectangle { width: 32; height: 32; radius: 10; color: cBgElevated; Text { anchors.centerIn: parent; text: "\ueaf2"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 } }
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
                            Layout.preferredWidth: 220
                            from: 50; to: 200; stepSize: 5
                            value: Theme.monoFontScale * 100
                            onValueChanged: { Theme.monoFontScale = value / 100.0; }
                            onPressedChanged: { if (!pressed) bashProcess.command = ["bash", "-c", "echo '" + (value / 100.0) + "' > ~/.config/cupcake/.font_mono_scale"]; bashProcess.running = true; }
                        }
                        
                    }
                }
            } // end Shell fonts card


            SettingsCard {
                sectionTitle: "Application fonts"

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 32; height: 32; radius: 10; color: cBgElevated; Text { anchors.centerIn: parent; text: "\uec50"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "App default font"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Main font for GTK/Qt applications"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
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
                        Rectangle { width: 32; height: 32; radius: 10; color: cBgElevated; Text { anchors.centerIn: parent; text: "\uec50"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "App monospaced font"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Monospaced font for GTK/Qt applications"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
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
                        Rectangle { width: 32; height: 32; radius: 10; color: cBgElevated; Text { anchors.centerIn: parent; text: "\ueb5a"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 } }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "App font weight"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Boldness of GTK/Qt application text"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
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
                        Rectangle { width: 32; height: 32; radius: 10; color: cBgElevated; Text { anchors.centerIn: parent; text: "\ueaf2"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 } }
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
                        Rectangle { width: 32; height: 32; radius: 10; color: cBgElevated; Text { anchors.centerIn: parent; text: "\ueaf2"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 16 } }
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
                            Layout.preferredWidth: 220
                            from: 50; to: 200; stepSize: 5
                            value: Theme.appMonoScale * 100
                            onValueChanged: { Theme.appMonoScale = value / 100.0; }
                            onPressedChanged: { if (!pressed) bashProcess.command = ["bash", "-c", "echo '" + (value / 100.0) + "' > ~/.config/cupcake/.app_font_mono_scale && ~/.local/bin/apply-fonts"]; bashProcess.running = true; }
                        }
                        
                    }
                }
            }


            Item { Layout.preferredHeight: 8 }
        }
    }
}
