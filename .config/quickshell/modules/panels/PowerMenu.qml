import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../theme"
import "../common"
import "../settings"

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
                text: "󰐥" // Poweroff
                font.pixelSize: 22
                Layout.fillWidth: true
                onClicked: {
                    powerMenu.visible = false
                    Quickshell.execDetached(["bash", "-c", "systemctl poweroff"])
                }
                background: Rectangle { color: "transparent" }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.pixelSize: parent.font.pixelSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                text: "󰜉" // Reboot
                font.pixelSize: 22
                Layout.fillWidth: true
                onClicked: {
                    powerMenu.visible = false
                    Quickshell.execDetached(["bash", "-c", "systemctl reboot"])
                }
                background: Rectangle { color: "transparent" }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.pixelSize: parent.font.pixelSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                text: "󰤄" // Suspend
                font.pixelSize: 22
                Layout.fillWidth: true
                onClicked: {
                    powerMenu.visible = false
                    Quickshell.execDetached(["bash", "-c", "systemctl suspend"])
                }
                background: Rectangle { color: "transparent" }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.pixelSize: parent.font.pixelSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                text: "󰌾" // Lock
                font.pixelSize: 22
                Layout.fillWidth: true
                onClicked: {
                    powerMenu.visible = false
                    Quickshell.execDetached(["bash", "-c", "hyprlock"])
                }
                background: Rectangle { color: "transparent" }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.pixelSize: parent.font.pixelSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                text: "󰍃" // Logout
                font.pixelSize: 22
                Layout.fillWidth: true
                onClicked: {
                    powerMenu.visible = false
                    Quickshell.execDetached(["bash", "-c", "loginctl kill-session $XDG_SESSION_ID"])
                }
                background: Rectangle { color: "transparent" }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.pixelSize: parent.font.pixelSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
