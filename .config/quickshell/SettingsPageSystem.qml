import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "theme"

Item {
    id: root
    property string activeTab: "general"
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16
        
        SettingsSegmentedControl {
            Layout.fillWidth: true
            model: [
                { label: "General", value: "general" },
                { label: "Battery", value: "battery" },
                { label: "Screen Time", value: "screen-time" },
                { label: "Monitor", value: "monitor" }
            ]
            currentValue: root.activeTab
            onValueChanged: (val, idx) => { root.activeTab = val; }
        }
        
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ScrollView {
                anchors.fill: parent
                contentWidth: availableWidth
                clip: true
                visible: root.activeTab === "general"
                
                ColumnLayout {
                    width: parent.width
                    spacing: 24
                    

                    // FONTS CARD
                    SettingsCard {
                        title: "Fonts"
                        description: "Choose the fonts used throughout the interface."
                        surfaceColor: "transparent"
                        outlineColor: "transparent"
                        primaryColor: Theme.colPrimary
                        onSurfaceColor: Theme.colOnSurface
                        
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Default font"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 14; font.bold: true }
                                Text { text: "Main font used throughout the interface."; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 12 }
                            }
                            StyledComboBox {
                                Layout.preferredWidth: 200
                                model: ["Fira Sans", Theme.defaultFontFamily, "Roboto"]
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Monospaced font"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 14; font.bold: true }
                                Text { text: "Monospaced font used for numbers and stats display."; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 12 }
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
                                Text { text: "Default font size"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 14; font.bold: true }
                                Text { text: "Increase or decrease the size of the standard text."; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 12 }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 16
                                                                        StyledSlider {
                                        Layout.fillWidth: true
                                        from: 50; to: 200; stepSize: 5
                                        value: Theme.defaultFontScale * 100
                                        onValueChanged: { Theme.defaultFontScale = value / 100.0; }
                                        onPressedChanged: { if (!pressed) Quickshell.execDetached(["bash", "-c", "echo '" + Theme.defaultFontScale + "' > ~/.config/cupcake/.font_default_scale"]); }
                                    }
                                    Text { text: Math.round(Theme.defaultFontScale * 100) + "%"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 40 }
                                    Text {
                                        text: ""; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 16
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Theme.defaultFontScale = 1.0; Quickshell.execDetached(["bash", "-c", "echo '1.0' > ~/.config/cupcake/.font_default_scale"]); } }
                                    }
                                }
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Monospaced font size"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 14; font.bold: true }
                                Text { text: "Increase or decrease the size of the monospaced text."; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 12 }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 16
                                                                        StyledSlider {
                                        Layout.fillWidth: true
                                        from: 50; to: 200; stepSize: 5
                                        value: Theme.monoFontScale * 100
                                        onValueChanged: { Theme.monoFontScale = value / 100.0; }
                                        onPressedChanged: { if (!pressed) Quickshell.execDetached(["bash", "-c", "echo '" + Theme.monoFontScale + "' > ~/.config/cupcake/.font_mono_scale"]); }
                                    }
                                    Text { text: Math.round(Theme.monoFontScale * 100) + "%"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 40 }
                                    Text {
                                        text: ""; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 16
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Theme.monoFontScale = 1.0; Quickshell.execDetached(["bash", "-c", "echo '1.0' > ~/.config/cupcake/.font_mono_scale"]); } }
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
                                Text { text: "Application Language"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 14; font.bold: true }
                                Text { text: "Select the language used in the application's interface."; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 12 }
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
                            font.pixelSize: 14
                            font.bold: true
                        }
                    }
                }
            }

            ScrollView {
                anchors.fill: parent
                contentWidth: availableWidth
                clip: true
                visible: root.activeTab === "battery"
                
                ColumnLayout {
                    width: parent.width
                    spacing: 24
                    
                    SettingsCard {
                        title: "Battery Settings"
                        icon: ""
                        surfaceColor: Theme.colSurfaceContainer
                        outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                        primaryColor: Theme.colPrimary
                        onSurfaceColor: Theme.colOnSurface
                        
                        
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Battery Warning Threshold"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 14; font.bold: true }
                                Text { text: "Battery Warning Threshold"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                            }
                            StyledSlider {
                                Layout.preferredWidth: 150
                                from: 0; to: 100; value: 50
                            }
                        }
                    }
                }
            }

            ScrollView {
                anchors.fill: parent
                contentWidth: availableWidth
                clip: true
                visible: root.activeTab === "screen-time"
                
                ColumnLayout {
                    width: parent.width
                    spacing: 24
                    
                    SettingsCard {
                        title: "Screen Time Settings"
                        icon: ""
                        surfaceColor: Theme.colSurfaceContainer
                        outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                        primaryColor: Theme.colPrimary
                        onSurfaceColor: Theme.colOnSurface
                        
                        
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Screen Time Enabled"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 14; font.bold: true }
                                Text { text: "Screen Time Enabled"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                            }
                            StyledSwitch {
                                checked: false
                                onCheckedChanged: {}
                            }
                        }
                    }
                }
            }

            ScrollView {
                anchors.fill: parent
                contentWidth: availableWidth
                clip: true
                visible: root.activeTab === "monitor"
                
                ColumnLayout {
                    width: parent.width
                    spacing: 24
                    
                    SettingsCard {
                        title: "Monitor Settings"
                        icon: ""
                        surfaceColor: Theme.colSurfaceContainer
                        outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                        primaryColor: Theme.colPrimary
                        onSurfaceColor: Theme.colOnSurface
                        
                        
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Brightness"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 14; font.bold: true }
                                Text { text: "Brightness"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                            }
                            StyledSlider {
                                Layout.preferredWidth: 150
                                from: 0; to: 100; value: 50
                            }
                        }
                    }
                }
            }
        }
    }
}
