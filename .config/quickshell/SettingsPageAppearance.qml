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
        
        SettingsSegmentedControl {
            Layout.fillWidth: true
            model: [
                { label: "Theme", value: "theme" },
                        { label: "Interface", value: "interface" },
                        { label: "Motion", value: "motion" },
                        { label: "Effects", value: "effects" }
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
                    visible: root.activeTab === "theme"
                    
                    ColumnLayout {
                        width: parent.width
                        spacing: 24
                        
                        SettingsCard {
                            title: "Theme Settings"
                            icon: ""
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Theme Mode"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Theme Mode"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Palette Source"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Palette Source"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Builtin Palette"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Builtin Palette"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                                }
                                StyledComboBox {
                                    Layout.preferredWidth: 150
                                    model: ["Option 1", "Option 2"]
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Wallpaper Generation Scheme"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Wallpaper Generation Scheme"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                                }
                                StyledComboBox {
                                    Layout.preferredWidth: 150
                                    model: ["Option 1", "Option 2"]
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Community Palette"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Community Palette"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Custom Palette"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Custom Palette"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                    visible: root.activeTab === "interface"
                    
                    ColumnLayout {
                        width: parent.width
                        spacing: 24
                        
                        SettingsCard {
                            title: "Interface Settings"
                            icon: ""
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Ui Scale"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Ui Scale"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                                }
                                StyledSlider {
                                    Layout.preferredWidth: 150
                                    from: 0; to: 100; value: 50
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Corner Roundness"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Corner Roundness"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                                }
                                StyledSlider {
                                    Layout.preferredWidth: 150
                                    from: 0; to: 100; value: 50
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "App Icon Colorize"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "App Icon Colorize"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                                }
                                Rectangle {
                                    width: 24; height: 24; radius: 12
                                    color: Theme.colPrimary
                                    border.color: Theme.colOutline
                                    border.width: 1
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "App Icon Color"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "App Icon Color"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                                }
                                Rectangle {
                                    width: 24; height: 24; radius: 12
                                    color: Theme.colPrimary
                                    border.color: Theme.colOutline
                                    border.width: 1
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Font Family"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Font Family"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Language"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Language"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                                }
                                StyledComboBox {
                                    Layout.preferredWidth: 150
                                    model: ["Option 1", "Option 2"]
                                }
                            }
                        }
                    }
                }

                ScrollView {
                    anchors.fill: parent
                    contentWidth: availableWidth
                    clip: true
                    visible: root.activeTab === "motion"
                    
                    ColumnLayout {
                        width: parent.width
                        spacing: 24
                        
                        SettingsCard {
                            title: "Motion Settings"
                            icon: ""
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Animations"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Animations"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Animation Speed"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Animation Speed"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                    visible: root.activeTab === "effects"
                    
                    ColumnLayout {
                        width: parent.width
                        spacing: 24
                        
                        SettingsCard {
                            title: "Effects Settings"
                            icon: ""
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Shadow Direction"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Global Shadow Direction"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                                }
                                StyledComboBox {
                                    Layout.preferredWidth: 150
                                    model: ["Option 1", "Option 2"]
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Shadow Alpha"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Global Shadow Alpha"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
