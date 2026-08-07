import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell.Widgets
import Quickshell.Io
import Quickshell
import "../../../theme"

Rectangle {
    id: powerSplitPill
    y: 10
    property bool menuExpanded: globalState.powerDropdownOpen
    height: menuExpanded ? (powerMenu.implicitHeight + 20) : 30
    Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutQuart } }

    readonly property real openGap: 12
    property real contentW: 145

    x: globalState.powerDropdownOpen ? (bar.barX + bar.barW - contentW) : (globalState.solidBoardOpen ? (bar.barX + bar.barW - 36) : (bar.barX + bar.barW - 40))
    width: globalState.powerDropdownOpen ? contentW : (globalState.solidBoardOpen ? 36 : 30)

    Behavior on x     { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
    Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
    radius: menuExpanded ? 16 : 15
    Behavior on radius { NumberAnimation { duration: 300 } }
    clip: true

    color: bar.pillColor

    opacity: (globalState.powerDropdownOpen || globalState.solidBoardOpen) ? 1.0 : 0.0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }

    FontLoader {
        id: powerIconFont
        source: Qt.resolvedUrl("file://" + Quickshell.env("HOME") + "/.local/share/fonts/tabler-icons.ttf")
    }

    MouseArea {
        id: powerSplitPillMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: (mouseY <= 30) ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (mouse.y <= 30) {
                if (globalState.powerDropdownOpen) {
                    globalState.powerDropdownOpen = false;
                } else {
                    bar.dropdownOpen = false;
                    bar.netDropdownOpen = false;
                    globalState.solidBoardOpen = false;
                    globalState.powerDropdownOpen = true;
                }
            }
        }
    }

    // ── Collapsed Header (Power Icon + Text) ────────────────────
    Row {
        id: powerOptionsRow
        anchors.horizontalCenter: parent.horizontalCenter
        y: (30 - height) / 2
        spacing: 4
        opacity: powerSplitPill.menuExpanded ? 0.0 : 1.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Item {
            width: 22; height: 26
            anchors.verticalCenter: parent.verticalCenter
            Text {
                anchors.centerIn: parent
                text: "\ueb0d"
                font.family: powerIconFont.name
                font.pixelSize: 15
                color: (powerSplitPillMa.containsMouse && powerSplitPillMa.mouseY <= 30) ? Theme.colError : bar.fg
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
        Text {
            id: powerPillTextLabel
            anchors.verticalCenter: parent.verticalCenter
            text: "Power"
            font.family: Theme.defaultFontFamily
            font.pixelSize: 12
            font.weight: Font.Medium
            color: (powerSplitPillMa.containsMouse && powerSplitPillMa.mouseY <= 30) ? Theme.colError : bar.fg
            Behavior on color { ColorAnimation { duration: 150 } }
            opacity: globalState.powerDropdownOpen ? (powerSplitPill.menuExpanded ? 0.0 : 1.0) : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

    // ── Expanded Power Menu ─────────────────────────────────────
    Column {
        id: powerMenu
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 3
        opacity: powerSplitPill.menuExpanded ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 250 } }

        // Category Header
        Item {
            width: parent.width
            height: 18

            Text {
                text: "POWER"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        component PowerMenuItem: Item {
            id: itemRoot
            property string icon: ""
            property string label: ""
            property bool isCancel: false
            signal triggered()

            width: parent.width
            height: 30

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: itemMa.containsMouse
                       ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.10)
                       : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            // Normal Item with Icon + Text
            Row {
                visible: !itemRoot.isCancel
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 8
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: itemRoot.icon
                    font.family: powerIconFont.name
                    font.pixelSize: 14
                    color: itemMa.containsMouse ? bar.fg : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.8)
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: itemRoot.label
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: itemMa.containsMouse ? bar.fg : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.85)
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
            }

            // Cancel Item (Centered)
            Text {
                visible: itemRoot.isCancel
                anchors.centerIn: parent
                text: itemRoot.label
                font.family: Theme.defaultFontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                color: itemMa.containsMouse ? bar.fg : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.65)
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            MouseArea {
                id: itemMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: itemRoot.triggered()
            }
        }

        // Section 1: Lock & Sleep
        PowerMenuItem {
            icon: "\ueae2"
            label: "Lock"
            onTriggered: {
                globalState.powerDropdownOpen = false;
                Quickshell.execDetached(["bash", "-c", "hyprlock"]);
            }
        }

        PowerMenuItem {
            icon: "\ueb0d"
            label: "Sleep"
            onTriggered: {
                globalState.powerDropdownOpen = false;
                Quickshell.execDetached(["bash", "-c", "systemctl suspend"]);
            }
        }

        // Separator 1
        Item {
            width: parent.width
            height: 7
            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 8
                height: 1
                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.12)
            }
        }

        // Section 2: Restart & Shut Down
        PowerMenuItem {
            icon: "\ueb13"
            label: "Restart"
            onTriggered: {
                globalState.powerDropdownOpen = false;
                Quickshell.execDetached(["bash", "-c", "systemctl reboot"]);
            }
        }

        PowerMenuItem {
            icon: "\ueb0d"
            label: "Shut Down"
            onTriggered: {
                globalState.powerDropdownOpen = false;
                Quickshell.execDetached(["bash", "-c", "systemctl poweroff"]);
            }
        }

        // Separator 2
        Item {
            width: parent.width
            height: 7
            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 8
                height: 1
                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.12)
            }
        }

        // Section 3: Cancel
        PowerMenuItem {
            label: "Cancel"
            isCancel: true
            onTriggered: {
                globalState.powerDropdownOpen = false;
            }
        }
    }
}
