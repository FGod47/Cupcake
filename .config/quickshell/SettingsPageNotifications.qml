import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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
                        { label: "Toasts", value: "toasts" },
                        { label: "Filtering", value: "filtering" }
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
                        
                        SettingsCard {
                            title: "General Settings"
                            icon: ""
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Daemon"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Daemon"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Show App Name"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Show App Name"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Show Actions"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Show Actions"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Collapse On Dismiss"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Collapse On Dismiss"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                    visible: root.activeTab === "toasts"
                    
                    ColumnLayout {
                        width: parent.width
                        spacing: 24
                        
                        SettingsCard {
                            title: "Toasts Settings"
                            icon: ""
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Layer"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Layer"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Position"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Position"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Scale"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Scale"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Offset X"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Offset X"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Offset Y"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Offset Y"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Toast Opacity"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Toast Opacity"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Monitors"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Monitors"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                    visible: root.activeTab === "filtering"
                    
                    ColumnLayout {
                        width: parent.width
                        spacing: 24
                        
                        SettingsCard {
                            title: "Filtering Settings"
                            icon: ""
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Filters"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Filters"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
