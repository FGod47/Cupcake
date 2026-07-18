import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import "../common"

Item {
    id: root
    property string activeTab: "osd"
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16
        
        SettingsSegmentedControl {
            Layout.fillWidth: true
            model: [
                { label: "Osd", value: "osd" },
                        { label: "Kinds", value: "kinds" }
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
                    visible: root.activeTab === "osd"
                    
                    ColumnLayout {
                        width: Math.min(parent.width, 1000)
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 24
                        
                        SettingsCard {
                            title: "Osd Settings"
                            icon: "\ueb20"
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Osd Orientation"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Osd Orientation"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Osd Position"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Osd Position"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Osd Position Vertical"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Osd Position Vertical"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Osd Scale"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Osd Scale"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Osd Offset X"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Osd Offset X"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Osd Offset Y"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Osd Offset Y"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Osd Background Opacity"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Osd Background Opacity"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Osd Monitors"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Osd Monitors"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                    visible: root.activeTab === "kinds"
                    
                    ColumnLayout {
                        width: Math.min(parent.width, 1000)
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 24
                        
                        SettingsCard {
                            title: "Kinds Settings"
                            icon: "\ueb20"
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Osd Kinds Volume"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Osd Kinds Volume"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Osd Kinds Volume Output"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Osd Kinds Volume Output"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Osd Kinds Volume Input"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Osd Kinds Volume Input"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Osd Kinds Brightness"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Osd Kinds Brightness"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Osd Kinds Wifi"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Osd Kinds Wifi"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Osd Kinds Bluetooth"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Osd Kinds Bluetooth"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Osd Kinds Power Profile"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Osd Kinds Power Profile"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Osd Kinds Caffeine"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Osd Kinds Caffeine"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Osd Kinds Nightlight"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Osd Kinds Nightlight"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Osd Kinds Dnd"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Osd Kinds Dnd"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Osd Kinds Lock Keys"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Osd Kinds Lock Keys"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Osd Kinds Keyboard Layout"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Osd Kinds Keyboard Layout"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Osd Kinds Media"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Osd Kinds Media"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Osd Kinds Privacy"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                    Text { text: "Osd Kinds Privacy"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
