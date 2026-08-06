import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import "../../common"
import Qt5Compat.GraphicalEffects
import Quickshell.Widgets
import Quickshell
import Qt5Compat.GraphicalEffects
import Qt5Compat.GraphicalEffects
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects
import Qt5Compat.GraphicalEffects
import Quickshell.Wayland
import "../../../theme"

    Rectangle {
        id: powerSplitPill
        y: 10
        property bool menuExpanded: globalState.powerDropdownOpen
        height: menuExpanded ? (powerMenu.implicitHeight + 20) : 30
        Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutQuart } }

        readonly property real openGap: 12
        // Hardcode contentW to prevent binding loop caused by Column's implicitWidth depending on children's width
        property real contentW: 130

        // When closed: starts at the power icon location inside solidBar
        // When open: slides out to the right as solidBar shrinks
        x: globalState.powerDropdownOpen ? (bar.barX + bar.barW - contentW) : (globalState.solidBoardOpen ? (bar.barX + bar.barW - 36) : (bar.barX + bar.barW - 40))
        width: globalState.powerDropdownOpen ? contentW : (globalState.solidBoardOpen ? 36 : 30)

        Behavior on x     { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        radius: 15
        clip: true

        color: bar.pillColor
        border.color: Qt.rgba(1, 1, 1, 0.10)
        border.width: 1



        opacity: (globalState.powerDropdownOpen || globalState.solidBoardOpen) ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }

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

        // ── Header (Power Icon + Text) ──────────────────────────────
        Row {
            id: powerOptionsRow
            anchors.horizontalCenter: parent.horizontalCenter
            y: (30 - height) / 2
            spacing: 4
            opacity: powerSplitPill.menuExpanded ? 0.0 : 1.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250 } }

            Item {
                width: 22; height: 26
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    anchors.centerIn: parent
                    text: "\ueb0d"
                    font.family: bar.fontName
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
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }
        }

        // ── Expanded Menu (Vertical) ────────────────────────────────
        Column {
            id: powerMenu
            anchors.top: parent.top
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 4
            opacity: powerSplitPill.menuExpanded ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 300 } }

            component SplitMenuBtn: Item {
                id: splitBtn
                property string icon: ""
                property string label: ""
                property color accentCol: Theme.colError
                property bool confirming: false
                signal triggered()

                width: parent.width
                implicitWidth: innerRow.implicitWidth + 16
                height: 32

                Timer { id: splitConfirmTimer; interval: 3000; onTriggered: splitBtn.confirming = false }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: splitMa.containsMouse
                           ? Qt.rgba(splitBtn.accentCol.r, splitBtn.accentCol.g, splitBtn.accentCol.b, 0.18)
                           : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                Row {
                    id: innerRow
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: splitBtn.icon
                        font.family: bar.fontName
                        font.pixelSize: 14
                        color: splitMa.containsMouse ? splitBtn.accentCol : bar.fg
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: splitBtn.confirming ? "Sure?" : splitBtn.label
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: splitBtn.confirming ? splitBtn.accentCol
                               : (splitMa.containsMouse ? splitBtn.accentCol : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.75))
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }

                MouseArea {
                    id: splitMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (splitBtn.confirming) {
                            splitBtn.confirming = false;
                            splitBtn.triggered();
                        } else {
                            splitBtn.confirming = true;
                            splitConfirmTimer.restart();
                        }
                    }
                }
            }

            SplitMenuBtn {
                icon: "\ueaf8"; label: "Sleep"
                accentCol: Theme.colPrimary
                onTriggered: { globalState.powerDropdownOpen = false; Quickshell.execDetached(["bash","-c","systemctl suspend"]); }
            }
            SplitMenuBtn {
                icon: "\ueba8"; label: "Logout"
                accentCol: Theme.colPrimary
                onTriggered: { globalState.powerDropdownOpen = false; Quickshell.execDetached(["bash","-c","hyprctl dispatch exit"]); }
            }
            SplitMenuBtn {
                icon: "\ueb13"; label: "Restart"
                accentCol: Theme.colError
                onTriggered: { globalState.powerDropdownOpen = false; Quickshell.execDetached(["bash","-c","systemctl reboot"]); }
            }
            SplitMenuBtn {
                icon: "\ueb0d"; label: "Shutdown"
                accentCol: Theme.colError
                onTriggered: { globalState.powerDropdownOpen = false; Quickshell.execDetached(["bash","-c","systemctl poweroff"]); }
            }
        }
    }
