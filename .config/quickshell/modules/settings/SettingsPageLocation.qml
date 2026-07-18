import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import "../common"

Item {
    id: root
    property string activeTab: "location"
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16
        
        SettingsSegmentedControl {
            Layout.fillWidth: true
            model: [
                { label: "Location", value: "location" },
                        { label: "Weather", value: "weather" },
                        { label: "Night Light", value: "night-light" }
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
                    visible: root.activeTab === "location"
                    
                    ColumnLayout {
                        width: Math.min(parent.width, 1000)
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 24
                        
                        SettingsCard {
                            title: "Location Settings"
                            icon: "\ueb20"
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Location Auto Locate"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Location Auto Locate"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Location Address"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Location Address"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                                }
                                StyledTextField {
                                    Layout.preferredWidth: 150
                                    placeholderText: "Enter value..."
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Sunset"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Sunset"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                                }
                                StyledTextField {
                                    Layout.preferredWidth: 150
                                    placeholderText: "Enter value..."
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Sunrise"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Sunrise"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                                }
                                StyledTextField {
                                    Layout.preferredWidth: 150
                                    placeholderText: "Enter value..."
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Latitude"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Latitude"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Longitude"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Longitude"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                    visible: root.activeTab === "weather"
                    
                    ColumnLayout {
                        width: Math.min(parent.width, 1000)
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 24
                        
                        SettingsCard {
                            title: "Weather Settings"
                            icon: "\ueb20"
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Weather"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Weather"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Weather Unit"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Weather Unit"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                                }
                                SettingsSegmentedControl {
                                    Layout.preferredWidth: 200
                                    model: [ { label: "Option 1", value: 1 }, { label: "Option 2", value: 2 } ]
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Weather Effects"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Weather Effects"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Weather Refresh Interval"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Weather Refresh Interval"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                    visible: root.activeTab === "night-light"
                    
                    ColumnLayout {
                        width: Math.min(parent.width, 1000)
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 24
                        
                        SettingsCard {
                            title: "Night Light Settings"
                            icon: "\ueb20"
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Night Light"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Night Light"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Night Light"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Night Light"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Force Night Light"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Force Night Light"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Day Temperature"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Day Temperature"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Night Temperature"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Night Temperature"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                                }
                                StyledSwitch {
                                    checked: false
                                    onCheckedChanged: {}
                                }
                            }
                        }
                    }
                }
        }
    }
}
