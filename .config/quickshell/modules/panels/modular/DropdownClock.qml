import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../common"
import "../../../theme"

Item {
    id: clockSplitPill
    
    // Attach directly to the bottom edge of the top bar
    y: bar.midY + bar.barHeight
    
    property bool menuExpanded: globalState.solidBoardOpen
    readonly property real expandedW: 320
    property real contentW: expandedW
    
    x: bar.barX + bar.barW - contentW - 40
    width: contentW
    height: menuExpanded ? (clockContentCol.implicitHeight + 28) : 0

    Behavior on x      { NumberAnimation { duration: 280; easing.type: Easing.OutExpo } }
    Behavior on width  { NumberAnimation { duration: 280; easing.type: Easing.OutExpo } }
    Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.OutExpo } }

    property real openProgress: menuExpanded ? 1.0 : 0.0
    property real scaleProgress: menuExpanded ? 1.0 : 0.0
    Behavior on openProgress  { NumberAnimation { duration: 260; easing.type: Easing.OutExpo } }
    Behavior on scaleProgress { NumberAnimation { duration: 260; easing.type: Easing.OutExpo } }

    opacity: openProgress
    visible: opacity > 0.01

    // ── Dropdown Container with Top-Down Curtain Unfolding ──────────
    Item {
        id: animContainer
        anchors.fill: parent
        transformOrigin: Item.Top
        scale: clockSplitPill.scaleProgress
        opacity: clockSplitPill.openProgress

        // ── Seamless Minflair Inverted Notch Cutout ─────────────────
        Shape {
            id: bgShape
            anchors.fill: parent
            property color shapeColor: bar.pillColor
            readonly property real r: 14
            readonly property real w: width
            readonly property real h: Math.max(height, 1)

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: bgShape.shapeColor
                startX: 0
                startY: 0

                // Top-Left Inverted Concave Arc (Flushes with Bar bottom)
                PathArc {
                    x: bgShape.r
                    y: bgShape.r
                    radiusX: bgShape.r
                    radiusY: bgShape.r
                    direction: PathArc.Clockwise
                }

                // Left Wall
                PathLine {
                    x: bgShape.r
                    y: Math.max(bgShape.r, bgShape.h - bgShape.r)
                }

                // Bottom-Left Smooth Curve
                PathQuad {
                    x: 2 * bgShape.r
                    y: bgShape.h
                    controlX: bgShape.r
                    controlY: bgShape.h
                }

                // Bottom Line
                PathLine {
                    x: Math.max(2 * bgShape.r, bgShape.w - 2 * bgShape.r)
                    y: bgShape.h
                }

                // Bottom-Right Smooth Curve
                PathQuad {
                    x: bgShape.w - bgShape.r
                    y: Math.max(bgShape.r, bgShape.h - bgShape.r)
                    controlX: bgShape.w - bgShape.r
                    controlY: bgShape.h
                }

                // Right Wall
                PathLine {
                    x: bgShape.w - bgShape.r
                    y: bgShape.r
                }

                // Top-Right Inverted Concave Arc (Flushes with Bar bottom)
                PathArc {
                    x: bgShape.w
                    y: 0
                    radiusX: bgShape.r
                    radiusY: bgShape.r
                    direction: PathArc.Clockwise
                }

                // Top Edge Connection
                PathLine {
                    x: 0
                    y: 0
                }
            }
        }

        MouseArea {
            id: clockSplitPillMa
            anchors.fill: parent
            enabled: globalState.solidBoardOpen
            hoverEnabled: true
            onClicked: {
                // Prevent click-through closing when interacting inside the calendar
            }
        }

        // ── Expanded Calendar & Clock View ────────────────────────────────
        ColumnLayout {
            id: clockContentCol
            x: 18
            y: 10
            width: parent.width - 36
            spacing: 10
            opacity: clockSplitPill.menuExpanded ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            // Big Accent Clock Header
            Item {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                implicitHeight: bigClockRow.implicitHeight

                Row {
                    id: bigClockRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: Qt.formatDateTime(timeClock.date, "hh AP").substring(0, 2)
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 34
                        font.weight: Font.Bold
                        color: Theme.colPrimary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: ":"
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 34
                        font.weight: Font.Bold
                        color: Theme.colOnSurface
                        opacity: 0.4
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: Qt.formatDateTime(timeClock.date, "mm")
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 34
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

            // Separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.1)
            }

            // Inline Calendar
            Column {
                id: calCol
                Layout.fillWidth: true
                spacing: 6

                property date currentDate: new Date()

                // Month header
                Row {
                    width: parent.width
                    Text {
                        text: Qt.formatDateTime(calCol.currentDate, "MMMM yyyy")
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
                                let d = new Date(calCol.currentDate);
                                d.setMonth(d.getMonth() - 1);
                                calCol.currentDate = d;
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
                                let d = new Date(calCol.currentDate);
                                d.setMonth(d.getMonth() + 1);
                                calCol.currentDate = d;
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
                            width: (clockContentCol.width) / 7
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
                    id: clockCalGrid
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
                        model: clockCalGrid.totalCells
                        delegate: Item {
                            width: (clockContentCol.width - 12) / 7
                            height: width

                            property int cellDay: {
                                let idx = index - clockCalGrid.firstDayOfWeek;
                                if (idx < 0) return clockCalGrid.daysInPrevMonth + idx + 1;
                                if (idx >= clockCalGrid.daysInMonth) return idx - clockCalGrid.daysInMonth + 1;
                                return idx + 1;
                            }
                            property bool isCurrentMonth: {
                                let idx = index - clockCalGrid.firstDayOfWeek;
                                return idx >= 0 && idx < clockCalGrid.daysInMonth;
                            }
                            property bool isToday: {
                                let now = new Date();
                                return isCurrentMonth &&
                                       cellDay === now.getDate() &&
                                       clockCalGrid.month === now.getMonth() &&
                                       clockCalGrid.year === now.getFullYear();
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
}
