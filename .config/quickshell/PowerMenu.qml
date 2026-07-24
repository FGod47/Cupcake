import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "theme"
import "modules/common"
import "modules/settings"

PanelWindow {
    id: powerMenu
    visible: false

    anchors {
        top: true
        right: true
    }
    margins {
        top: 50
        right: 10
    }
    
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    width: 280
    height: 70

    Rectangle {
        anchors.fill: parent
        color: Theme.colSurface
        radius: 10
        border.color: Theme.colOutline
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            Button {
                text: "\ueb0d" // ti-power
                font.pixelSize: 22
                Layout.fillWidth: true
                onClicked: {
                    powerMenu.visible = false
                    Quickshell.execDetached(["bash", "-c", "zenity --question --title 'Shutdown' --text 'Are you sure you want to shutdown?' --width=300 --height=150 && systemctl poweroff"])
                }
                background: Rectangle { color: "transparent" }
                contentItem: Text {
                    text: parent.text
                    color: Theme.colOnSurface
                    font.family: "tabler-icons"
                    font.pixelSize: parent.font.pixelSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                text: "\ueb13" // ti-refresh
                font.pixelSize: 22
                Layout.fillWidth: true
                onClicked: {
                    powerMenu.visible = false
                    Quickshell.execDetached(["bash", "-c", "zenity --question --title 'Reboot' --text 'Are you sure you want to reboot?' --width=300 --height=150 && systemctl reboot"])
                }
                background: Rectangle { color: "transparent" }
                contentItem: Text {
                    text: parent.text
                    color: Theme.colOnSurface
                    font.family: "tabler-icons"
                    font.pixelSize: parent.font.pixelSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                text: "\ueaf8" // ti-moon
                font.pixelSize: 22
                Layout.fillWidth: true
                onClicked: {
                    powerMenu.visible = false
                    Quickshell.execDetached(["bash", "-c", "systemctl suspend"])
                }
                background: Rectangle { color: "transparent" }
                contentItem: Text {
                    text: parent.text
                    color: Theme.colOnSurface
                    font.family: "tabler-icons"
                    font.pixelSize: parent.font.pixelSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                text: "\ueae2" // ti-lock
                font.pixelSize: 22
                Layout.fillWidth: true
                onClicked: {
                    powerMenu.visible = false
                    Quickshell.execDetached(["bash", "-c", "hyprlock"])
                }
                background: Rectangle { color: "transparent" }
                contentItem: Text {
                    text: parent.text
                    color: Theme.colOnSurface
                    font.family: "tabler-icons"
                    font.pixelSize: parent.font.pixelSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                text: "\ueba8" // ti-logout
                font.pixelSize: 22
                Layout.fillWidth: true
                onClicked: {
                    powerMenu.visible = false
                    Quickshell.execDetached(["bash", "-c", "loginctl kill-session $XDG_SESSION_ID"])
                }
                background: Rectangle { color: "transparent" }
                contentItem: Text {
                    text: parent.text
                    color: Theme.colOnSurface
                    font.family: "tabler-icons"
                    font.pixelSize: parent.font.pixelSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
