import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "theme"

Item {
    id: root
    property string activeTab: "theme"
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16
        
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            clip: true
            
            ColumnLayout {
                width: Math.min(parent.width, 1000)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 24
                
                SettingsCard {
                    title: "Mode"
                    surfaceColor: Theme.colSurfaceContainer
                    outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                    primaryColor: Theme.colPrimary
                    onSurfaceColor: Theme.colOnSurface
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "󰖔"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 18 } // moon icon
                        ColumnLayout {
                            Layout.fillWidth: true
                            Text { text: "UI Style"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                        }
                        SettingsSegmentedControl {
                            Layout.preferredWidth: 240
                            model: [ { label: "Glass", value: "1" }, { label: "Liquid", value: "2" }, { label: "Classic", value: "3" } ]
                            currentValue: "2"
                        }
                    }
                }

                SettingsCard {
                    title: "Accent"
                    surfaceColor: Theme.colSurfaceContainer
                    outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                    primaryColor: Theme.colPrimary
                    onSurfaceColor: Theme.colOnSurface
                    
                    RowLayout {
                        Layout.fillWidth: true
                        SettingsSegmentedControl {
                            Layout.fillWidth: true
                            model: [ 
                                { label: "Tonal Spot", value: "1" }, 
                                { label: "Content", value: "2" }, 
                                { label: "Expressive", value: "3" },
                                { label: "Fidelity", value: "4" },
                                { label: "Fruit Salad", value: "5" },
                                { label: "Monochrome", value: "6" },
                                { label: "Neutral", value: "7" },
                                { label: "Rainbow", value: "8" }
                            ]
                            currentValue: "1"
                        }
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "󰒓"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 18 } // accent icon
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { text: "Dynamic Accent"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                            Text { text: "Manual"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 12; opacity: 0.8 }
                        }
                        StyledSwitch {
                            checked: true
                        }
                    }
                }

                SettingsCard {
                    title: "Quick Toggles"
                    surfaceColor: Theme.colSurfaceContainer
                    outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                    primaryColor: Theme.colPrimary
                    onSurfaceColor: Theme.colOnSurface
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "󰢹"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 18 } // toggle icon
                        ColumnLayout {
                            Layout.fillWidth: true
                            Text { text: "Toggle Style"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                        }
                        SettingsSegmentedControl {
                            Layout.preferredWidth: 160
                            model: [ { label: "Glass", value: 1 }, { label: "Android", value: 2 } ]
                            currentValue: 2
                        }
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "󰎍"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 18 } // script icon
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { text: "Accent Script"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                        }
                        Text { 
                            text: "~/.config/quickshell-glass/extract-accent.sh"
                            color: Theme.colOnSurfaceVariant
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 12
                            opacity: 0.8 
                        }
                    }
                }

                SettingsCard {
                    title: "Blur"
                    surfaceColor: Theme.colSurfaceContainer
                    outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                    primaryColor: Theme.colPrimary
                    onSurfaceColor: Theme.colOnSurface
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "󰖰"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 18 } // blur icon
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { text: "Background Blur"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                            Text { text: "Strength: 77%"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 12; opacity: 0.8 }
                        }
                        StyledSwitch {
                            checked: true
                        }
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "󰧼"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 18 } // strength icon
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { text: "Strength"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                        }
                        
                        StyledSlider {
                            Layout.fillWidth: true
                            Layout.maximumWidth: 300
                            from: 0; to: 100; value: 77
                        }
                        
                        Text {
                            text: "77%"
                            color: Theme.colOnSurfaceVariant
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 12
                        }
                    }
                }
                
                SettingsCard {
                    title: "Fonts"
                    surfaceColor: Theme.colSurfaceContainer
                    outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                    primaryColor: Theme.colPrimary
                    onSurfaceColor: Theme.colOnSurface
                }
            }
        }
    }
}
