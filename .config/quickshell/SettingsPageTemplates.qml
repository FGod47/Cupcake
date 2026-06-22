import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "theme"

Item {
    id: root
    property string activeTab: "built-in"
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16
        
        SettingsSegmentedControl {
            Layout.fillWidth: true
            model: [
                { label: "Built In", value: "built-in" },
                        { label: "Community", value: "community" }
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
                    visible: root.activeTab === "built-in"
                    
                    ColumnLayout {
                        width: parent.width
                        spacing: 24
                        
                        SettingsCard {
                            title: "Built In Settings"
                            icon: ""
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Enable Builtins"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Enable Builtins"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Builtin Ids"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Builtin Ids"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                    visible: root.activeTab === "community"
                    
                    ColumnLayout {
                        width: parent.width
                        spacing: 24
                        
                        SettingsCard {
                            title: "Community Settings"
                            icon: ""
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            
                            
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Enable Community Templates"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Enable Community Templates"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
                                    Text { text: "Community Ids"; color: Theme.colOnSurface; font.family: "Inter"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Community Ids"; color: Theme.colOnSurfaceVariant; font.family: "Inter"; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
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
