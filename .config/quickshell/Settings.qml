//@ pragma UseQApplication
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects
import Quickshell
import "theme"

ApplicationWindow {
    id: root
    visible: true
    title: "Cupcake Settings"
    minimumWidth: 800
    minimumHeight: 600
    width: 900
    height: 700
    color: Theme.colSurface
    font.family: "JetBrainsMono Nerd Font Propo"

    property int currentIndex: 0

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // Navigation Rail
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 220
            color: Theme.colSurfaceContainer
            radius: 16

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Text {
                    text: "🧁 Cupcake"
                    color: Theme.colOnSurface
                    font.family: root.font.family
                    font.pixelSize: 28
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 12
                    Layout.bottomMargin: 24
                }

                // Nav Buttons
                component NavButton: Rectangle {
                    property string iconText
                    property string labelText
                    property int pageIndex

                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: 8
                    color: root.currentIndex === pageIndex ? Theme.colPrimary : "transparent"
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12
                        Text {
                            text: iconText
                            color: root.currentIndex === pageIndex ? Theme.colOnPrimary : Theme.colOnSurface
                            font.family: root.font.family
                            font.pixelSize: 16
                            font.bold: true
                        }
                        Text {
                            text: labelText
                            color: root.currentIndex === pageIndex ? Theme.colOnPrimary : Theme.colOnSurface
                            font.family: root.font.family
                            font.pixelSize: 16
                            font.bold: true
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentIndex = pageIndex
                        onEntered: if (root.currentIndex !== pageIndex) parent.color = Theme.colSurfaceContainerHigh
                        onExited: if (root.currentIndex !== pageIndex) parent.color = "transparent"
                    }
                }

                NavButton { iconText: ""; labelText: "Wallpapers"; pageIndex: 0 }
                NavButton { iconText: ""; labelText: "Top Bar"; pageIndex: 1 }
                NavButton { iconText: ""; labelText: "System"; pageIndex: 2 }
                NavButton { iconText: ""; labelText: "Network"; pageIndex: 3 }

                Item { Layout.fillHeight: true } // Spacer
                
                Text {
                    text: "Powered by Quickshell"
                    color: Theme.colOnSurfaceVariant
                    font.family: root.font.family
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 8
                }
            }
        }

        // Content Area
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: Theme.colSurfaceContainerHigh
            radius: 16
            clip: true

            StackLayout {
                anchors.fill: parent
                currentIndex: root.currentIndex

                // PAGE 0: WALLPAPERS
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 16

                        Text {
                            text: "Select Wallpaper"
                            color: Theme.colOnSurface
                            font.family: root.font.family
                            font.pixelSize: 32
                            font.bold: true
                        }

                        Text {
                            text: "Clicking a wallpaper will instantly apply it and regenerate your dynamic material colors."
                            color: Theme.colOnSurfaceVariant
                            font.family: root.font.family
                            font.pixelSize: 14
                            Layout.bottomMargin: 16
                        }

                        GridView {
                            id: grid
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            cellWidth: 250
                            cellHeight: 180
                            clip: true

                            model: FolderListModel {
                                folder: "file:///home/one/.config/cupcake/themes/cupcake-dark/walls"
                                nameFilters: ["*.png", "*.jpg", "*.jpeg"]
                            }

                            delegate: Item {
                                width: grid.cellWidth
                                height: grid.cellHeight

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    radius: 12
                                    color: "transparent"
                                    border.color: mouseArea.containsMouse ? Theme.colPrimary : "transparent"
                                    border.width: 3

                                    Image {
                                        id: img
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        source: fileUrl
                                        fillMode: Image.PreserveAspectCrop
                                        Behavior on scale { NumberAnimation { duration: 150 } }
                                        scale: mouseArea.containsMouse ? 1.05 : 1.0

                                        layer.enabled: true
                                        layer.effect: OpacityMask {
                                            maskSource: Rectangle {
                                                width: img.width
                                                height: img.height
                                                radius: 9
                                            }
                                        }
                                    }
                                    
                                    MouseArea {
                                        id: mouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Quickshell.execDetached(["/home/one/.local/bin/set-theme", filePath])
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // PAGE 1: TOP BAR
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 16

                        Text {
                            text: "Top Bar Settings"
                            color: Theme.colOnSurface
                            font.family: root.font.family
                            font.pixelSize: 32
                            font.bold: true
                        }
                        
                        Text {
                            text: "Manage your Quickshell status bar"
                            color: Theme.colOnSurfaceVariant
                            font.family: root.font.family
                            font.pixelSize: 14
                            Layout.bottomMargin: 16
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            color: Theme.colSurfaceContainer
                            radius: 12
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                Text {
                                    text: "Restart Top Bar"
                                    color: Theme.colOnSurface
                                    font.family: root.font.family
                                    font.pixelSize: 16
                                    Layout.fillWidth: true
                                }
                                Button {
                                    text: "Restart"
                                    font.family: root.font.family
                                    onClicked: {
                                        Quickshell.execDetached(["/home/one/.config/cupcake/scripts/toggle_bar.sh"])
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // PAGE 2: SYSTEM
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 16

                        Text {
                            text: "System Controls"
                            color: Theme.colOnSurface
                            font.family: root.font.family
                            font.pixelSize: 32
                            font.bold: true
                        }
                        
                        Text {
                            text: "Power and Session management"
                            color: Theme.colOnSurfaceVariant
                            font.family: root.font.family
                            font.pixelSize: 14
                            Layout.bottomMargin: 16
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            color: Theme.colSurfaceContainer
                            radius: 12
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                Text {
                                    text: "Reload Hyprland Config"
                                    color: Theme.colOnSurface
                                    font.family: root.font.family
                                    font.pixelSize: 16
                                    Layout.fillWidth: true
                                }
                                Button {
                                    text: "Reload"
                                    font.family: root.font.family
                                    onClicked: Quickshell.execDetached(["hyprctl", "reload"])
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            color: Theme.colSurfaceContainer
                            radius: 12
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                Text {
                                    text: "Reboot System"
                                    color: Theme.colOnSurface
                                    font.family: root.font.family
                                    font.pixelSize: 16
                                    Layout.fillWidth: true
                                }
                                Button {
                                    text: "Reboot"
                                    font.family: root.font.family
                                    onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // PAGE 3: NETWORK
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 16

                        Text {
                            text: "Network Settings"
                            color: Theme.colOnSurface
                            font.family: root.font.family
                            font.pixelSize: 32
                            font.bold: true
                        }
                        
                        Text {
                            text: "Manage Wi-Fi and connections"
                            color: Theme.colOnSurfaceVariant
                            font.family: root.font.family
                            font.pixelSize: 14
                            Layout.bottomMargin: 16
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            color: Theme.colSurfaceContainer
                            radius: 12
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                Text {
                                    text: "Advanced Network Configuration"
                                    color: Theme.colOnSurface
                                    font.family: root.font.family
                                    font.pixelSize: 16
                                    Layout.fillWidth: true
                                }
                                Button {
                                    text: "Open GUI"
                                    font.family: root.font.family
                                    onClicked: Quickshell.execDetached(["nm-connection-editor"])
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            color: Theme.colSurfaceContainer
                            radius: 12
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                Text {
                                    text: "Wi-Fi Power State"
                                    color: Theme.colOnSurface
                                    font.family: root.font.family
                                    font.pixelSize: 16
                                    Layout.fillWidth: true
                                }
                                Button {
                                    text: "Turn On"
                                    font.family: root.font.family
                                    onClicked: Quickshell.execDetached(["nmcli", "radio", "wifi", "on"])
                                }
                                Button {
                                    text: "Turn Off"
                                    font.family: root.font.family
                                    onClicked: Quickshell.execDetached(["nmcli", "radio", "wifi", "off"])
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}
