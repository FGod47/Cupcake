import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../theme"
import "../common"

Item {
    id: systemPageRoot
    anchors.fill: parent

    Flickable {
        anchors.fill: parent
        contentHeight: contentCol.implicitHeight + 40
        clip: true
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: contentCol
            width: parent.width - 20
            spacing: 24

            // "Distro" Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 16

                RowLayout {
                    spacing: 12
                    Text { text: ""; font.family: "tabler-icons"; font.pixelSize: 20; color: Theme.colPrimary }
                    Text { text: "System & OS"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 18; font.weight: Font.DemiBold }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: distroLayout.implicitHeight + 40
                    color: cBgElevated
                    radius: 12
                    border.color: cBorderSoft
                    border.width: 1

                    ColumnLayout {
                        id: distroLayout
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 24
                            
                            // Arch Logo
                            Text {
                                text: "󰣇"
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 80
                                color: Theme.colPrimary
                            }

                            ColumnLayout {
                                spacing: 4
                                Text {
                                    id: distroNameText
                                    text: "Arch Linux"
                                    color: cText
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 24
                                    font.weight: Font.Bold
                                }
                                Text {
                                    id: kernelText
                                    text: "Linux Kernel"
                                    color: cTextDim
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 14
                                }
                                
                                Process {
                                    command: ["bash", "-c", "grep PRETTY_NAME /etc/os-release | cut -d'\"' -f2"]
                                    running: true
                                    stdout: StdioCollector { onStreamFinished: { if (text.trim() !== "") distroNameText.text = text.trim() } }
                                }
                                Process {
                                    command: ["uname", "-r"]
                                    running: true
                                    stdout: StdioCollector { onStreamFinished: { if (text.trim() !== "") kernelText.text = "Linux " + text.trim() } }
                                }
                            }
                        }

                        // Pill Buttons Grid
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: 12
                            rowSpacing: 12

                            component LinkBtn: Rectangle {
                                property string icon: ""
                                property string label: ""
                                property string url: ""
                                Layout.fillWidth: true
                                implicitHeight: 44
                                radius: 22
                                color: btnArea.pressed ? cSurfaceActive : (btnArea.containsMouse ? cSurfaceHover : cSurface)
                                border.color: cBorderSoft
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Text { text: parent.parent.icon; font.family: "tabler-icons"; font.pixelSize: 16; color: Theme.colPrimary }
                                    Text { text: parent.parent.label; font.family: Theme.defaultFontFamily; font.pixelSize: 13; color: cText; font.weight: Font.Medium }
                                }

                                MouseArea {
                                    id: btnArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Qt.openUrlExternally(parent.url)
                                }
                            }

                            LinkBtn { icon: ""; label: "Arch Wiki"; url: "https://wiki.archlinux.org/" }
                            LinkBtn { icon: ""; label: "Pacman Guide"; url: "https://wiki.archlinux.org/title/Pacman" }
                            LinkBtn { icon: ""; label: "AUR Packages"; url: "https://aur.archlinux.org/" }
                            LinkBtn { icon: ""; label: "Forums"; url: "https://bbs.archlinux.org/" }
                        }
                    }
                }
            }

            // "Dotfiles" Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 16

                RowLayout {
                    spacing: 12
                    Text { text: ""; font.family: "tabler-icons"; font.pixelSize: 20; color: Theme.colPrimary }
                    Text { text: "Desktop Environment"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 18; font.weight: Font.DemiBold }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: dotsLayout.implicitHeight + 40
                    color: cBgElevated
                    radius: 12
                    border.color: cBorderSoft
                    border.width: 1

                    ColumnLayout {
                        id: dotsLayout
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 24
                            
                            // Cupcake / Quickshell Logo
                            Text {
                                text: ""
                                font.family: "tabler-icons"
                                font.pixelSize: 80
                                color: Theme.colPrimary
                            }

                            ColumnLayout {
                                spacing: 4
                                Text {
                                    text: "Cupcake Desktop"
                                    color: cText
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 24
                                    font.weight: Font.Bold
                                }
                                Text {
                                    text: "Powered by Hyprland & Quickshell"
                                    color: cTextDim
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 14
                                }
                            }
                        }

                        // Pill Buttons Grid
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: 12
                            rowSpacing: 12

                            LinkBtn { icon: ""; label: "Quickshell Docs"; url: "https://quickshell.outfoxxed.me/" }
                            LinkBtn { icon: ""; label: "Hyprland Wiki"; url: "https://wiki.hyprland.org/" }
                            LinkBtn { icon: ""; label: "Report Issue"; url: "https://github.com/cupcake" }
                            LinkBtn { icon: ""; label: "Customize"; url: "https://github.com/cupcake" }
                        }
                    }
                }
            }
        }
    }
}
