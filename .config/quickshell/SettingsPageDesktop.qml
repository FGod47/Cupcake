import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "theme"

Item {
    id: root
    property string activeTab: "widgets"
    
    property int gapsIn: 3
    property int gapsOut: 8

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.gaps_in"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { let v = parseInt(text.trim()); if (!isNaN(v)) root.gapsIn = v; }
            }
        }
    }

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.gaps_out"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { let v = parseInt(text.trim()); if (!isNaN(v)) root.gapsOut = v; }
            }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16
        
        SettingsSegmentedControl {
            Layout.fillWidth: true
            model: [
                { label: "Widgets", value: "widgets" },
                { label: "Screen Corners", value: "screen-corners" },
                { label: "Window Gaps", value: "window-gaps" }
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
                    visible: root.activeTab === "widgets"
                    
                    ColumnLayout {
                        width: Math.min(parent.width, 1000)
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 24
                        
                        SettingsCard {
                            title: "Widgets Settings"
                            icon: ""
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Widgets"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Widgets"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                    visible: root.activeTab === "screen-corners"
                    
                    ColumnLayout {
                        width: Math.min(parent.width, 1000)
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 24
                        
                        SettingsCard {
                            title: "Screen Corners Settings"
                            icon: ""
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Screen Corners Enabled"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Screen Corners Enabled"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                                }
                                StyledSwitch {
                                    checked: false
                                    onCheckedChanged: {}
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Screen Corners Size"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Screen Corners Size"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                    visible: root.activeTab === "window-gaps"
                    
                    ColumnLayout {
                        width: Math.min(parent.width, 1000)
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 24
                        
                        SettingsCard {
                            title: "Window Gaps Settings"
                            icon: ""
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Inner Gaps"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Space between windows"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                                }
                                StyledSlider {
                                    Layout.preferredWidth: 150
                                    from: 0; to: 30; stepSize: 1
                                    value: root.gapsIn
                                    onValueChanged: { root.gapsIn = value; }
                                    onPressedChanged: {
                                        if (!pressed) {
                                            Quickshell.execDetached(["bash", "-c", "echo '" + Math.round(root.gapsIn) + "' > ~/.config/cupcake/.gaps_in && ~/.local/bin/apply-gaps"]);
                                        }
                                    }
                                }
                                Text { text: Math.round(root.gapsIn) + "px"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 12; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Outer Gaps"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Space between windows and screen edges"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                                }
                                StyledSlider {
                                    Layout.preferredWidth: 150
                                    from: 0; to: 60; stepSize: 1
                                    value: root.gapsOut
                                    onValueChanged: { root.gapsOut = value; }
                                    onPressedChanged: {
                                        if (!pressed) {
                                            Quickshell.execDetached(["bash", "-c", "echo '" + Math.round(root.gapsOut) + "' > ~/.config/cupcake/.gaps_out && ~/.local/bin/apply-gaps"]);
                                        }
                                    }
                                }
                                Text { text: Math.round(root.gapsOut) + "px"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 12; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight }
                            }
                        }
                    }
                }
        }
    }
}
