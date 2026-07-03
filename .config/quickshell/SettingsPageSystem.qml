import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "theme"

Item {
    id: root
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16
        
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ScrollView {
                anchors.fill: parent
                contentWidth: availableWidth
                clip: true
                
                ColumnLayout {
                    width: parent.width
                    spacing: 24
                    

                    // FONTS CARD
                    SettingsCard {
                        title: "Shell Fonts"
                        description: "Choose the fonts used throughout the interface."
                        surfaceColor: "transparent"
                        outlineColor: "transparent"
                        primaryColor: Theme.colPrimary
                        onSurfaceColor: Theme.colOnSurface
                        
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Default font"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                Text { text: "Main font used throughout the interface."; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12 }
                            }
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
                        
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Monospaced font"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                Text { text: "Monospaced font used for numbers and stats display."; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12 }
                            }
                                                        StyledComboBox {
                                id: monoFontCombo
                                Layout.preferredWidth: 240
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
                                                let fonts = text.trim().split("
");
                                                monoFontCombo.model = fonts;
                                                monoFontCombo.currentIndex = monoFontCombo.model.indexOf(Theme.monoFontFamily) !== -1 ? monoFontCombo.model.indexOf(Theme.monoFontFamily) : 0;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Font Weight"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                Text { text: "Change the boldness of the user interface text."; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                            }
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
                        
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Default font size"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                Text { text: "Increase or decrease the size of the standard text."; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12 }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 16
                                    StyledSlider {
                                        Layout.fillWidth: true
                                        from: 8; to: 32; stepSize: 1
                                        value: Theme.defaultFontSize
                                        onValueChanged: { Theme.defaultFontSize = value; }
                                        onPressedChanged: { if (!pressed) Quickshell.execDetached(["bash", "-c", "echo '" + Math.round(value) + "' > ~/.config/cupcake/.font_size"]); }
                                    }
                                    Text { text: Theme.defaultFontSize + "px"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Math.min(900, Theme.defaultFontWeight + 200); Layout.preferredWidth: 40 }
                                    Text {
                                        text: ""; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 16
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Theme.defaultFontSize = 14; Quickshell.execDetached(["bash", "-c", "echo '14' > ~/.config/cupcake/.font_size"]); } }
                                    }
                                }
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Monospaced font size"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                Text { text: "Increase or decrease the size of the monospaced text."; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12 }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 16
                                                                        StyledSlider {
                                        Layout.fillWidth: true
                                        from: 50; to: 200; stepSize: 5
                                        value: Theme.monoFontScale * 100
                                        onValueChanged: { Theme.monoFontScale = value / 100.0; }
                                        onPressedChanged: { if (!pressed) Quickshell.execDetached(["bash", "-c", "echo '" + (value / 100.0) + "' > ~/.config/cupcake/.font_mono_scale"]); }
                                    }
                                    Text { text: Math.round(Theme.monoFontScale * 100) + "%"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Math.min(900, Theme.defaultFontWeight + 200); Layout.preferredWidth: 40 }
                                    Text {
                                        text: ""; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 16
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Theme.monoFontScale = 1.0; Quickshell.execDetached(["bash", "-c", "echo '1.0' > ~/.config/cupcake/.font_mono_scale"]); } }
                                    }
                                }
                            }
                        }
                    }
                    
                    SettingsCard {
                        title: "Application Fonts"
                        description: "Choose the fonts used throughout the interface."
                        surfaceColor: "transparent"
                        outlineColor: "transparent"
                        primaryColor: Theme.colPrimary
                        onSurfaceColor: Theme.colOnSurface
                        
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Default font"; color: Theme.colOnSurface; font.family: Theme.appFontFamily; font.pixelSize: Theme.appFontSize; font.weight: Math.min(900, Theme.appFontWeight + 200) }
                                Text { text: "Main font used throughout the interface."; color: Theme.colOnSurfaceVariant; font.family: Theme.appFontFamily; font.weight: Theme.appFontWeight; font.pixelSize: 12 }
                            }
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
                        
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Monospaced font"; color: Theme.colOnSurface; font.family: Theme.appFontFamily; font.pixelSize: Theme.appFontSize; font.weight: Math.min(900, Theme.appFontWeight + 200) }
                                Text { text: "Monospaced font used for numbers and stats display."; color: Theme.colOnSurfaceVariant; font.family: Theme.appFontFamily; font.weight: Theme.appFontWeight; font.pixelSize: 12 }
                            }
                            StyledComboBox {
                                id: appMonoFontCombo
                                Layout.preferredWidth: 240
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
                        
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Font Weight"; color: Theme.colOnSurface; font.family: Theme.appFontFamily; font.pixelSize: Theme.appFontSize; font.weight: Math.min(900, Theme.appFontWeight + 200) }
                                Text { text: "Change the boldness of the user interface text."; color: Theme.colOnSurfaceVariant; font.family: Theme.appFontFamily; font.weight: Theme.appFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                            }
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
                        
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Default font size"; color: Theme.colOnSurface; font.family: Theme.appFontFamily; font.pixelSize: Theme.appFontSize; font.weight: Math.min(900, Theme.appFontWeight + 200) }
                                Text { text: "Increase or decrease the size of the standard text."; color: Theme.colOnSurfaceVariant; font.family: Theme.appFontFamily; font.weight: Theme.appFontWeight; font.pixelSize: 12 }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 16
                                    StyledSlider {
                                        Layout.fillWidth: true
                                        from: 8; to: 32; stepSize: 1
                                        value: Theme.appFontSize
                                        onValueChanged: { Theme.appFontSize = value; }
                                        onPressedChanged: { if (!pressed) Quickshell.execDetached(["bash", "-c", "echo '" + Math.round(value) + "' > ~/.config/cupcake/.app_font_size && ~/.local/bin/apply-fonts"]); }
                                    }
                                    Text { text: Theme.appFontSize + "px"; color: Theme.colOnSurfaceVariant; font.family: Theme.appFontFamily; font.pixelSize: 12; font.weight: Math.min(900, Theme.appFontWeight + 200); Layout.preferredWidth: 40 }
                                    Text {
                                        text: ""; color: Theme.colOnSurfaceVariant; font.family: Theme.appMonoFamily; font.weight: Theme.appFontWeight; font.pixelSize: 16
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Theme.appFontSize = 14; Quickshell.execDetached(["bash", "-c", "echo '14' > ~/.config/cupcake/.app_font_size && ~/.local/bin/apply-fonts"]); } }
                                    }
                                }
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Monospaced font size"; color: Theme.colOnSurface; font.family: Theme.appFontFamily; font.pixelSize: Theme.appFontSize; font.weight: Math.min(900, Theme.appFontWeight + 200) }
                                Text { text: "Increase or decrease the size of the monospaced text."; color: Theme.colOnSurfaceVariant; font.family: Theme.appFontFamily; font.weight: Theme.appFontWeight; font.pixelSize: 12 }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 16
                                                                        StyledSlider {
                                        Layout.fillWidth: true
                                        from: 50; to: 200; stepSize: 5
                                        value: Theme.appMonoScale * 100
                                        onValueChanged: { Theme.appMonoScale = value / 100.0; }
                                        onPressedChanged: { if (!pressed) Quickshell.execDetached(["bash", "-c", "echo '" + (value / 100.0) + "' > ~/.config/cupcake/.app_font_mono_scale && ~/.local/bin/apply-fonts"]); }
                                    }
                                    Text { text: Math.round(Theme.appMonoScale * 100) + "%"; color: Theme.colOnSurfaceVariant; font.family: Theme.appFontFamily; font.pixelSize: 12; font.weight: Math.min(900, Theme.appFontWeight + 200); Layout.preferredWidth: 40 }
                                    Text {
                                        text: ""; color: Theme.colOnSurfaceVariant; font.family: Theme.appMonoFamily; font.weight: Theme.appFontWeight; font.pixelSize: 16
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Theme.appMonoScale = 1.0; Quickshell.execDetached(["bash", "-c", "echo '1.0' > ~/.config/cupcake/.app_font_mono_scale && ~/.local/bin/apply-fonts"]); } }
                                    }
                                }
                            }
                        }
                    }
                    
                    
                    Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15) }
                    
                    // LANGUAGE CARD
                    SettingsCard {
                        title: "Language"
                        description: "Choose your preferred language for the application."
                        surfaceColor: "transparent"
                        outlineColor: "transparent"
                        primaryColor: Theme.colPrimary
                        onSurfaceColor: Theme.colOnSurface
                        
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Application Language"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                Text { text: "Select the language used in the application's interface."; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12 }
                            }
                            StyledComboBox {
                                Layout.preferredWidth: 200
                                model: ["Automatic (en)"]
                            }
                        }
                    }
                    
                    // SETUP WIZARD BUTTON
                    Rectangle {
                        Layout.topMargin: 8
                        Layout.preferredWidth: 200
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
                }
            }


        }
    }
}
