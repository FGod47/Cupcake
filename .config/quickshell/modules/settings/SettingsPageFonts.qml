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

            // --- Shell fonts section ---
            NCard {
                sectionTitle: "Shell fonts"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uec50" }
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

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb5a" }
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

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueaf2" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Font size"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Change the size of standard shell text"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StepperCounter {
                        from: 8
                        to: 32
                        stepSize: 1
                        suffix: "px"
                        value: Theme.defaultFontSize
                        onValueModified: (v) => {
                            Theme.defaultFontSize = v;
                            bashProcess.command = ["bash", "-c", "echo '" + Math.round(v) + "' > ~/.config/cupcake/.font_size"];
                            bashProcess.running = true;
                        }
                    }
                }
            } // end Shell fonts card

            // --- Application fonts section ---
            NCard {
                sectionTitle: "Application fonts"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uec50" }
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

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb5a" }
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

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueaf2" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "App font size"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Size of standard GTK/Qt application text"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StepperCounter {
                        from: 8
                        to: 32
                        stepSize: 1
                        suffix: "px"
                        value: Theme.appFontSize
                        onValueModified: (v) => {
                            Theme.appFontSize = v;
                            Quickshell.execDetached(["bash", "-c", "echo '" + Math.round(v) + "' > ~/.config/cupcake/.app_font_size && ~/.local/bin/apply-fonts"]);
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 8 }
        }
    }
}
