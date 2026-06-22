import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "theme"

Item {
    id: root
    property string activeTab: "calendar"
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16
        
        SettingsSegmentedControl {
            Layout.fillWidth: true
            model: [
                { label: "Calendar", value: "calendar" },
                        { label: "Audio", value: "audio" },
                        { label: "Brightness", value: "brightness" },
                        { label: "Media", value: "media" }
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
                    visible: root.activeTab === "calendar"
                    
                    ColumnLayout {
                        width: parent.width
                        spacing: 24
                        
                        SettingsCard {
                            title: "Calendar Settings"
                            icon: ""
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Calendar"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Calendar"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Calendar Refresh Interval"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Calendar Refresh Interval"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                    visible: root.activeTab === "audio"
                    
                    ColumnLayout {
                        width: parent.width
                        spacing: 24
                        
                        SettingsCard {
                            title: "Audio Settings"
                            icon: ""
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Audio Overdrive"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Audio Overdrive"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Shell Sounds"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Shell Sounds"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Sound Volume"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Sound Volume"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Volume Change Sound"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Volume Change Sound"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Notification Sound"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Notification Sound"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                                }
                                StyledTextField {
                                    Layout.preferredWidth: 150
                                    placeholderText: "Enter value..."
                                }
                            }
                        }
                    }
                }

                ScrollView {
                    anchors.fill: parent
                    contentWidth: availableWidth
                    clip: true
                    visible: root.activeTab === "brightness"
                    
                    ColumnLayout {
                        width: parent.width
                        spacing: 24
                        
                        SettingsCard {
                            title: "Brightness Settings"
                            icon: ""
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Minimum Brightness"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Minimum Brightness"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                    visible: root.activeTab === "media"
                    
                    ColumnLayout {
                        width: parent.width
                        spacing: 24
                        
                        SettingsCard {
                            title: "Media Settings"
                            icon: ""
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Mpris Blacklist"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Mpris Blacklist"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
