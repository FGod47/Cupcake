// ==============================================================================
// ⚠️ STRICT DIRECTIVE / AGENT LOCK: THIS COMPONENT IS TOTALLY DISABLED
// THIS COMPONENT IS PRESERVED FOR ARCHIVAL PURPOSES ONLY. IT IS DECOUPLED FROM
// THE CUPCAKE RUNTIME. NO AGENT MAY TOUCH, REFACTOR, MODIFY, OR RE-ENABLE THIS
// FILE IN ANY WAY UNLESS THE USER EXPLICITLY INSTRUCTS YOU TO DO SO.
// ==============================================================================
// PowerDropdown.qml
// A floating pill that animates from the power icon in the solid bar,
// expanding downward to reveal power options — same pattern as ClockDropdown.
// Toggle via globalState.powerDropdownOpen.

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"
import "../common"

Item {
    id: root

    property real screenW: 1920

    // Bar geometry — matches BarSolid: barX=100, barW=screenW-200
    readonly property real barRightEdge: screenW - 100

    // Dropdown dimensions
    readonly property real dropW: 220
    readonly property real dropX: barRightEdge - dropW
    readonly property real dropY: 50

    // The power icon sits at the far right of the content RowLayout.
    // RowLayout right margin ~12px, power pill item ~26px wide.
    // So trigger is roughly at barRightEdge - 12 - 26 = barRightEdge - 38
    readonly property real triggerW: 26
    readonly property real triggerH: 26
    readonly property real triggerX: barRightEdge - 12 - triggerW
    readonly property real triggerY: 17   // bar top=10, height=30, center=25, (25 - 13) = 12 → ~17

    // Collapsed: a pill sitting perfectly over the power icon
    readonly property real collapsedW: triggerW + 16
    readonly property real collapsedH: triggerH + 8
    readonly property real collapsedX: triggerX - 8
    readonly property real collapsedY: triggerY - 4

    property bool isOpen: globalState.powerDropdownOpen

    // Expose inner card for BarSolid's mask Region
    property alias dropdownCard: card

    // ── Floating card ─────────────────────────────────────────────────
    Rectangle {
        id: card

        x: root.isOpen ? root.dropX      : root.collapsedX
        y: root.isOpen ? root.dropY      : root.collapsedY
        width:  root.isOpen ? root.dropW  : root.collapsedW
        height: root.isOpen ? contentCol.implicitHeight + 24 : root.collapsedH

        radius: root.isOpen ? 18 : height / 2
        clip: true

        color: Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b,
                       Theme.isDark ? 0.94 : 0.97)
        border.color: Qt.rgba(1, 1, 1, Theme.isDark ? 0.10 : 0.06)
        border.width: 1

        opacity: root.isOpen ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on x      { NumberAnimation { duration: 480; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
        Behavior on y      { NumberAnimation { duration: 480; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
        Behavior on width  { NumberAnimation { duration: 480; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
        Behavior on height { NumberAnimation { duration: 480; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
        Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180 } }

        // Top glass highlight
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 4; anchors.rightMargin: 4
            height: 1; radius: 1
            color: Qt.rgba(1, 1, 1, 0.10)
        }

        // ── Content ──────────────────────────────────────────────────
        ColumnLayout {
            id: contentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 6

            opacity: root.isOpen ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            // ── Header ──
            Text {
                Layout.fillWidth: true
                text: "Power"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Theme.colOnSurface
                opacity: 0.45
                topPadding: 2
                bottomPadding: 4
            }

            // ── Action buttons ──
            component PowerBtn: Rectangle {
                id: btn
                Layout.fillWidth: true
                height: 40
                radius: 12
                color: btnMa.containsMouse ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.07) : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }

                property string icon: ""
                property string label: ""
                property color accentColor: Theme.colPrimary
                property bool confirming: false

                signal triggered()

                Timer {
                    id: confirmTimer
                    interval: 3000
                    onTriggered: btn.confirming = false
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    spacing: 12

                    Rectangle {
                        width: 28; height: 28
                        radius: 8
                        color: btn.confirming
                               ? Qt.rgba(btn.accentColor.r, btn.accentColor.g, btn.accentColor.b, 0.15)
                               : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.07)
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: btn.icon
                            font.family: "tabler-icons"
                            font.pixelSize: 15
                            color: btn.confirming ? btn.accentColor
                                   : (btnMa.containsMouse ? btn.accentColor : Theme.colOnSurface)
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: btn.confirming ? "Sure?" : btn.label
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: btn.confirming ? btn.accentColor
                               : (btnMa.containsMouse ? Theme.colOnSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.85))
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }

                MouseArea {
                    id: btnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (btn.confirming) {
                            btn.confirming = false;
                            btn.triggered();
                        } else {
                            btn.confirming = true;
                            confirmTimer.restart();
                        }
                    }
                }
            }

            PowerBtn {
                icon: "\ueaf8"
                label: "Sleep"
                accentColor: Theme.colPrimary
                onTriggered: {
                    globalState.powerDropdownOpen = false;
                    Quickshell.execDetached(["bash", "-c", "systemctl suspend"]);
                }
            }

            PowerBtn {
                icon: "\ueba8"
                label: "Logout"
                accentColor: Theme.colPrimary
                onTriggered: {
                    globalState.powerDropdownOpen = false;
                    Quickshell.execDetached(["bash", "-c", "hyprctl dispatch exit"]);
                }
            }

            // Thin separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
                Layout.topMargin: 2
                Layout.bottomMargin: 2
            }

            PowerBtn {
                icon: "\ueb13"
                label: "Restart"
                accentColor: Theme.colOnSurface
                onTriggered: {
                    globalState.powerDropdownOpen = false;
                    Quickshell.execDetached(["bash", "-c", "systemctl reboot"]);
                }
            }

            PowerBtn {
                icon: "\ueb0d"
                label: "Shutdown"
                accentColor: Theme.colOnSurface
                onTriggered: {
                    globalState.powerDropdownOpen = false;
                    Quickshell.execDetached(["bash", "-c", "systemctl poweroff"]);
                }
            }
        }
    }

    // Click-outside to close
    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: root.isOpen
        onClicked: globalState.powerDropdownOpen = false
    }
}
