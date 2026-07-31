// ClockDropdown.qml
// A floating pill that animates from the clock text position in the solid bar,
// expanding downward to reveal a compact clock + calendar.
// Controlled via globalState.solidBoardOpen.

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell
import "../../theme"
import "../common"

Item {
    id: root

    property real screenW: 1920
    // Bar geometry — matches BarSolid: barX=100, barW=screenW-200
    readonly property real barRightEdge: screenW - 100  // right edge of the solid bar

    // Dropdown width — compact, right-aligned with bar
    readonly property real dropW: 280
    readonly property real dropX: barRightEdge - dropW  // right-aligned to bar
    readonly property real dropY: 50                    // just below bar

    // Precise position of the clock text triggering this dropdown
    // The solid bar right edge is screenW - 100.
    // The RowLayout has 12px right margin, 26px power pill, 12px spacing, 8px bullet, 12px spacing, then the clock text (~130px).
    // So the clock text starts roughly 200px from the bar right edge.
    readonly property real triggerX: barRightEdge - 200
    readonly property real triggerY: 18   // solidBar is at y=10 with height=40 (center is 30) -> 30 - (24/2) = 18
    readonly property real triggerW: 130
    readonly property real triggerH: 24

    // Collapsed pill — sits perfectly over the clock text
    readonly property real collapsedW: triggerW + 24
    readonly property real collapsedH: triggerH + 12
    readonly property real collapsedX: triggerX - 12
    readonly property real collapsedY: triggerY - 6

    property bool isOpen: globalState.solidBoardOpen

    // Expose inner card for BarSolid's mask Region
    property alias dropdownCard: card

    SystemClock { id: timeClock; precision: SystemClock.Minutes }

    // ── Floating card ─────────────────────────────────────────────────
    Rectangle {
        id: card

        x: root.isOpen ? root.dropX      : root.collapsedX
        y: root.isOpen ? root.dropY      : root.collapsedY
        width:  root.isOpen ? root.dropW  : root.collapsedW
        height: root.isOpen ? contentCol.implicitHeight + 24 : root.collapsedH

        radius: root.isOpen ? 16 : height / 2
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

        // Top highlight
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 4; anchors.rightMargin: 4
            height: 1; radius: 1
            color: Qt.rgba(1, 1, 1, 0.10)
        }

        ColumnLayout {
            id: contentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 10

            // ── Morphing Clock Header ──────────────────────
            Item {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                implicitHeight: bigClockRow.implicitHeight

                // Small bar clock (fades out and scales up as it opens)
                Text {
                    id: smallClock
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(timeClock.date, "MMM dd • hh:mm AP")
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: Theme.defaultFontSize
                    font.weight: Theme.defaultFontWeight
                    color: Theme.colOnSurface
                    opacity: root.isOpen ? 0.0 : 1.0
                    scale: root.isOpen ? 1.6 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 250 } }
                    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                }

                // Big accented clock (fades in and scales up to normal size)
                Row {
                    id: bigClockRow
                    anchors.centerIn: parent
                    spacing: 6
                    
                    opacity: root.isOpen ? 1.0 : 0.0
                    scale: root.isOpen ? 1.0 : 0.7
                    Behavior on opacity { NumberAnimation { duration: 350 } }
                    Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }

                    Text {
                        text: Qt.formatDateTime(timeClock.date, "hh")
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 36
                        font.weight: Font.Bold
                        color: Theme.colPrimary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: ":"
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 36
                        font.weight: Font.Bold
                        color: Theme.colOnSurface
                        opacity: 0.4
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: Qt.formatDateTime(timeClock.date, "mm")
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 36
                        font.weight: Font.Bold
                        color: Theme.colOnSurface
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1
                        Text {
                            text: Qt.formatDateTime(timeClock.date, "AP")
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Theme.colPrimary
                        }
                        Text {
                            text: Qt.formatDateTime(timeClock.date, "ddd, MMM dd")
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            color: Theme.colOnSurface
                            opacity: 0.55
                        }
                    }
                }
            }

            // ── Thin separator ──────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.1)
                opacity: root.isOpen ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 160 } }
            }

            // ── Inline calendar ─────────────────────────────────────
            Column {
                Layout.fillWidth: true
                spacing: 6
                opacity: root.isOpen ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 160 } }

                property date currentDate: new Date()

                // Month header
                Row {
                    width: parent.width
                    Text {
                        text: Qt.formatDateTime(parent.parent.currentDate, "MMMM yyyy")
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: Theme.colOnSurface
                        width: parent.width - 48
                    }
                    Row {
                        spacing: 4
                        MouseArea {
                            width: 20; height: 20
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let d = new Date(parent.parent.parent.currentDate);
                                d.setMonth(d.getMonth() - 1);
                                parent.parent.parent.currentDate = d;
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "\uea60"
                                font.family: "tabler-icons"
                                font.pixelSize: 13
                                color: Theme.colOnSurface
                                opacity: 0.6
                            }
                        }
                        MouseArea {
                            width: 20; height: 20
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let d = new Date(parent.parent.parent.currentDate);
                                d.setMonth(d.getMonth() + 1);
                                parent.parent.parent.currentDate = d;
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "\uea61"
                                font.family: "tabler-icons"
                                font.pixelSize: 13
                                color: Theme.colOnSurface
                                opacity: 0.6
                            }
                        }
                    }
                }

                // Day of week header
                Row {
                    width: parent.width
                    Repeater {
                        model: ["Su","Mo","Tu","We","Th","Fr","Sa"]
                        Text {
                            width: (contentCol.width - 24) / 7
                            text: modelData
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 10
                            color: Theme.colOnSurface
                            opacity: 0.4
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // Calendar grid
                Grid {
                    id: calGrid
                    width: parent.width
                    columns: 7
                    spacing: 2

                    property date currentDate: parent.currentDate
                    property int month: currentDate.getMonth()
                    property int year: currentDate.getFullYear()
                    property int firstDayOfWeek: new Date(year, month, 1).getDay()
                    property int daysInMonth: new Date(year, month + 1, 0).getDate()
                    property int daysInPrevMonth: new Date(year, month, 0).getDate()
                    property int totalCells: Math.ceil((firstDayOfWeek + daysInMonth) / 7) * 7

                    Repeater {
                        model: calGrid.totalCells
                        delegate: Item {
                            width: (contentCol.width - 24) / 7
                            height: width

                            property int cellDay: {
                                let idx = index - calGrid.firstDayOfWeek;
                                if (idx < 0) return calGrid.daysInPrevMonth + idx + 1;
                                if (idx >= calGrid.daysInMonth) return idx - calGrid.daysInMonth + 1;
                                return idx + 1;
                            }
                            property bool isCurrentMonth: {
                                let idx = index - calGrid.firstDayOfWeek;
                                return idx >= 0 && idx < calGrid.daysInMonth;
                            }
                            property bool isToday: {
                                let now = new Date();
                                return isCurrentMonth &&
                                       cellDay === now.getDate() &&
                                       calGrid.month === now.getMonth() &&
                                       calGrid.year === now.getFullYear();
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - 2
                                height: width
                                radius: width / 2
                                color: isToday ? Theme.colPrimary : "transparent"
                            }
                            Text {
                                anchors.centerIn: parent
                                text: cellDay
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 10
                                font.weight: isToday ? Font.Bold : Font.Normal
                                color: isToday ? Theme.colOnPrimary : (isCurrentMonth ? Theme.colOnSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.25))
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }
            }
        }
    }

    // Click-outside to close
    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: root.isOpen
        onClicked: globalState.solidBoardOpen = false
    }
}
