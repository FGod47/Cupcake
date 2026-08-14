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
    
    readonly property bool isAttached: Theme.barDropdownStyle === "Attached"

    // Multi-mode Y position
    y: isAttached ? (bar.midY + bar.barHeight) : (bar.midY + bar.barHeight + 8)
    Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.InOutExpo } }
    
    property bool menuExpanded: globalState.solidBoardOpen
    readonly property real expandedW: 275
    property real contentW: expandedW
    
    // Balanced spacious padding constants
    readonly property real padTop: isAttached ? 24 : 16
    readonly property real padSide: isAttached ? 30 : 16
    readonly property real padBottom: isAttached ? 24 : 16

    readonly property real targetH: clockContentCol.implicitHeight + padTop + padBottom

    // Positioned aligned with clock section right edge
    x: clockItem.x + clockItem.width + contentLayout.x + solidBar.x - contentW
    width: contentW
    height: menuExpanded ? targetH : 0

    // Signature smooth animations
    Behavior on height {
        NumberAnimation {
            duration: 450
            easing.type: Easing.InOutExpo
        }
    }
    Behavior on width {
        NumberAnimation {
            duration: 400
            easing.type: Easing.InOutExpo
        }
    }
    Behavior on x {
        NumberAnimation {
            duration: 400
            easing.type: Easing.InOutExpo
        }
    }

    property real openProgress: menuExpanded ? 1.0 : 0.0
    Behavior on openProgress {
        NumberAnimation {
            duration: 320
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
        }
    }

    opacity: openProgress
    visible: height > 0 || opacity > 0.01

    // ── Dropdown Container ──────────────────────────────────────────
    Item {
        id: animContainer
        anchors.fill: parent
        clip: true

        // ── Attached Mode: Seamless Inverted Notch Cutout ──────────
        Shape {
            id: bgShape
            anchors.fill: parent
            visible: clockSplitPill.isAttached
            property color shapeColor: bar.pillColor
            readonly property real r: 16
            readonly property real w: width
            readonly property real h: Math.max(height, 1)

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: bgShape.shapeColor
                startX: 0
                startY: 0

                // Top-Left Inverted Concave Arc
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

                // Top-Right Inverted Concave Arc
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

        // ── Floating Mode: Floating Rounded Rectangle Pill ────────
        Rectangle {
            id: bgRect
            anchors.fill: parent
            visible: !clockSplitPill.isAttached
            radius: 16
            color: bar.pillColor
        }

        MouseArea {
            id: clockSplitPillMa
            anchors.fill: parent
            enabled: globalState.solidBoardOpen
            hoverEnabled: true
            onClicked: {
                // Keep open on interaction
            }
        }

        // ── Inner Content Wrapper (Reveals smoothly without squishing) ──
        Item {
            id: contentWrapper
            anchors.fill: parent
            clip: true
            opacity: clockSplitPill.menuExpanded ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
            }

            // ── Expanded Calendar & Clock View ────────────────────────────────
            ColumnLayout {
                id: clockContentCol
                x: clockSplitPill.padSide
                y: clockSplitPill.padTop
                width: parent.width - (clockSplitPill.padSide * 2)
                spacing: 12

                // Spacious Header (Time + Date)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: Qt.formatDateTime(timeClock.date, "hh:mm")
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        color: bar.fg
                    }

                    Rectangle {
                        width: 1
                        height: 16
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.25)
                    }

                    Text {
                        Layout.fillWidth: true
                        text: Qt.formatDateTime(timeClock.date, "ddd, dd MMM").toUpperCase()
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.5
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.65)
                        elide: Text.ElideRight
                    }
                }

                // Subtle divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.08)
                }

                // Inline Compact Calendar
                Column {
                    id: calCol
                    Layout.fillWidth: true
                    spacing: 8

                    property date currentDate: new Date()

                    // Month header with switch buttons
                    RowLayout {
                        width: parent.width
                        
                        Text {
                            Layout.fillWidth: true
                            text: Qt.formatDateTime(calCol.currentDate, "MMMM yyyy")
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: bar.fg
                        }

                        Row {
                            spacing: 4
                            MouseArea {
                                width: 22; height: 22
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
                                    color: bar.fg
                                    opacity: 0.65
                                }
                            }
                            MouseArea {
                                width: 22; height: 22
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
                                    color: bar.fg
                                    opacity: 0.65
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
                                width: clockContentCol.width / 7
                                text: modelData
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: bar.fg
                                opacity: 0.45
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    // Calendar grid
                    Grid {
                        id: clockCalGrid
                        width: parent.width
                        columns: 7
                        spacing: 0

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
                                width: clockContentCol.width / 7
                                height: 25

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
                                    width: 22
                                    height: 22
                                    radius: 11
                                    color: isToday ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.20) : "transparent"
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: cellDay
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 11
                                    font.weight: isToday ? Font.Bold : Font.Normal
                                    color: isToday ? bar.fg : (isCurrentMonth ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.85) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.25))
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
