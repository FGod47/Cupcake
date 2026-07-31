// ClockDropdown.qml
// A floating pill that animates from the clock text position in the solid bar,
// expanding downward to reveal a ClockWidget + CalendarWidget.
// Usage: place as a sibling of solidBar inside PanelWindow.
// Controlled via globalState.solidBoardOpen.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../common"
import "../solidboard"

Item {
    id: root

    // The bar's screen width so we can position correctly
    property real screenW: 1920
    // X-position of the clock text in the bar (right side, approximate)
    // The pill will animate from a small pill near the clock to a full dropdown
    property real clockX: screenW - 260   // roughly where clock text sits
    property real clockY: 8              // same top as the bar pill

    // Final expanded size & position
    readonly property real expandedW: 356
    readonly property real expandedH: clockWidget.implicitHeight + calWidget.implicitHeight + 32 + 16
    readonly property real expandedX: screenW - expandedW - 12
    readonly property real expandedY: 50   // just below the bar

    // Collapsed (pill) size — small pill sitting at clock position
    readonly property real collapsedW: 140
    readonly property real collapsedH: 26

    property bool isOpen: globalState.solidBoardOpen

    // Expose inner card for BarSolid's mask Region
    property alias dropdownCard: card

    // ── Floating card ─────────────────────────────────────────────────
    Rectangle {
        id: card

        x: root.isOpen ? root.expandedX : root.clockX
        y: root.isOpen ? root.expandedY : root.clockY
        width:  root.isOpen ? root.expandedW  : root.collapsedW
        height: root.isOpen ? root.expandedH  : root.collapsedH

        radius: root.isOpen ? 20 : height / 2
        clip: true

        color: Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b,
                       Theme.isDark ? 0.92 : 0.97)
        border.color: Qt.rgba(1, 1, 1, Theme.isDark ? 0.10 : 0.06)
        border.width: 1

        opacity: root.isOpen ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on x      { NumberAnimation { duration: 520; easing.type: Easing.OutBack; easing.overshoot: 1.0 } }
        Behavior on y      { NumberAnimation { duration: 520; easing.type: Easing.OutBack; easing.overshoot: 1.0 } }
        Behavior on width  { NumberAnimation { duration: 520; easing.type: Easing.OutBack; easing.overshoot: 1.0 } }
        Behavior on height { NumberAnimation { duration: 520; easing.type: Easing.OutBack; easing.overshoot: 1.0 } }
        Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        // Top highlight line
        Rectangle {
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: 6; anchors.rightMargin: 6
            height: 1; radius: 1
            color: Qt.rgba(1, 1, 1, 0.12)
        }

        // Content fades in after card expands
        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            opacity: root.isOpen ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            ClockWidget {
                id: clockWidget
                Layout.fillWidth: true
                // Override fixed width from ClockWidget so it fills the card
                width: parent.width
                implicitWidth: parent.width
                // Remove the card-style bg — parent card handles it
                color: "transparent"
                border.width: 0
            }

            CalendarWidget {
                id: calWidget
                Layout.fillWidth: true
                width: parent.width
                implicitWidth: parent.width
                color: "transparent"
                border.width: 0
            }
        }
    }

    // Click-outside to close (covers bar area above the dropdown)
    MouseArea {
        id: closeArea
        anchors.fill: parent
        z: -1
        enabled: root.isOpen
        onClicked: globalState.solidBoardOpen = false
    }
}
