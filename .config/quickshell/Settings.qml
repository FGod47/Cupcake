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
                    font.pixelSize: 28
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 12
                    Layout.bottomMargin: 24
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: 8
                    color: Theme.colPrimary
                    Text {
                        anchors.centerIn: parent
                        text: "  Wallpapers"
                        color: Theme.colOnPrimary
                        font.pixelSize: 16
                        font.bold: true
                    }
                }

                Item { Layout.fillHeight: true } // Spacer
                
                Text {
                    text: "Powered by Quickshell"
                    color: Theme.colOnSurfaceVariant
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

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                Text {
                    text: "Select Wallpaper"
                    color: Theme.colOnSurface
                    font.pixelSize: 32
                    font.bold: true
                }

                Text {
                    text: "Clicking a wallpaper will instantly apply it and regenerate your dynamic material colors."
                    color: Theme.colOnSurfaceVariant
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
                                    // Run set-theme and restart quickshell
                                    Quickshell.execDetached(["/home/one/.local/bin/set-theme", filePath])
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
