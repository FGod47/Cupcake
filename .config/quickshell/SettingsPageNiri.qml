import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "theme"

Item {
    id: root
    property string activeTab: "overview"
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16
        
        SettingsSegmentedControl {
            Layout.fillWidth: true
            model: [
                { label: "Overview", value: "overview" },
                        { label: "Backdrop", value: "backdrop" }
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
                    visible: root.activeTab === "overview"
                    
                    ColumnLayout {
                        width: parent.width
                        spacing: 24
                        
                        SettingsCard {
                            title: "Overview Settings"
                            icon: ""
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Niri Overview Type To Launch"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Niri Overview Type To Launch"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                    visible: root.activeTab === "backdrop"
                    
                    ColumnLayout {
                        width: parent.width
                        spacing: 24
                        
                        SettingsCard {
                            title: "Backdrop Settings"
                            icon: ""
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Enabled"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Enabled"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Blur Intensity"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Blur Intensity"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Tint Intensity"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Tint Intensity"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
