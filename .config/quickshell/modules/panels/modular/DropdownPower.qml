import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell.Widgets
import Quickshell.Io
import Quickshell
import "../../../theme"

Item {
    id: powerSplitPill

    readonly property bool isAttached: Theme.barDropdownStyle === "Attached"
    y: isAttached ? (bar.midY + bar.barHeight) : (bar.midY + bar.barHeight + 8)
    Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.InOutExpo } }

    property bool menuExpanded: globalState.powerDropdownOpen
    readonly property real expandedW: 180
    property real contentW: expandedW

    readonly property real padTop: isAttached ? 20 : 12
    readonly property real padSide: isAttached ? 24 : 12
    readonly property real padBottom: isAttached ? 14 : 12

    readonly property real targetH: powerRowLayout.implicitHeight + padTop + padBottom

    // Positioned cleanly under the bar's right section with symmetric concave curves
    x: bar.barX + bar.barW - contentW - 10
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

    FontLoader {
        id: powerIconFont
        source: Qt.resolvedUrl("file://" + Quickshell.env("HOME") + "/.local/share/fonts/tabler-icons.ttf")
    }

    Item {
        id: animContainer
        anchors.fill: parent
        clip: true

        // ── Attached Mode Shape (Symmetric Concave Curves) ───────
        Shape {
            id: bgShape
            anchors.fill: parent
            visible: powerSplitPill.isAttached
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

                // 1. Left concave notch
                PathArc {
                    x: bgShape.r
                    y: bgShape.r
                    radiusX: bgShape.r
                    radiusY: bgShape.r
                    direction: PathArc.Clockwise
                }
                // 2. Left vertical straight edge
                PathLine {
                    x: bgShape.r
                    y: Math.max(bgShape.r, bgShape.h - bgShape.r)
                }
                // 3. Bottom-Left rounded corner
                PathQuad {
                    x: 2 * bgShape.r
                    y: bgShape.h
                    controlX: bgShape.r
                    controlY: bgShape.h
                }
                // 4. Bottom horizontal edge
                PathLine {
                    x: Math.max(2 * bgShape.r, bgShape.w - 2 * bgShape.r)
                    y: bgShape.h
                }
                // 5. Bottom-Right rounded corner
                PathQuad {
                    x: bgShape.w - bgShape.r
                    y: Math.max(bgShape.r, bgShape.h - bgShape.r)
                    controlX: bgShape.w - bgShape.r
                    controlY: bgShape.h
                }
                // 6. Right vertical straight edge
                PathLine {
                    x: bgShape.w - bgShape.r
                    y: bgShape.r
                }
                // 7. Right concave notch
                PathArc {
                    x: bgShape.w
                    y: 0
                    radiusX: bgShape.r
                    radiusY: bgShape.r
                    direction: PathArc.Clockwise
                }
                // 8. Top flat edge closing
                PathLine {
                    x: 0
                    y: 0
                }
            }
        }

        // ── Floating Mode Shape ──────────────────────────────────
        Rectangle {
            id: bgRect
            anchors.fill: parent
            visible: !powerSplitPill.isAttached
            radius: 16
            color: bar.pillColor
        }

        MouseArea {
            id: powerSplitPillMa
            anchors.fill: parent
            enabled: globalState.powerDropdownOpen
            hoverEnabled: true
            onClicked: {
                // Keep open on interaction
            }
        }

        // ── Inner Content Wrapper (Horizontal Row of 4 Circular Buttons) ──
        Item {
            id: contentWrapper
            anchors.fill: parent
            clip: true
            opacity: powerSplitPill.menuExpanded ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
            }

            Row {
                id: powerRowLayout
                anchors.top: parent.top
                anchors.topMargin: powerSplitPill.padTop
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                component PowerCircleBtn: Item {
                    id: btnRoot
                    property string iconCode: ""
                    property string tooltipText: ""
                    property bool isDestructive: false
                    signal triggered()

                    width: 32
                    height: 32

                    Rectangle {
                        id: btnBg
                        anchors.fill: parent
                        radius: 16
                        color: btnMa.containsMouse
                               ? (isDestructive ? Qt.rgba(Theme.colError.r, Theme.colError.g, Theme.colError.b, 0.22) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.16))
                               : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.07)
                        border.color: btnMa.containsMouse
                                      ? (isDestructive ? Qt.rgba(Theme.colError.r, Theme.colError.g, Theme.colError.b, 0.4) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.2))
                                      : "transparent"
                        border.width: 1
                        scale: btnMa.containsMouse ? 1.08 : 1.0

                        Behavior on color { ColorAnimation { duration: 130 } }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

                        Text {
                            anchors.centerIn: parent
                            text: btnRoot.iconCode
                            font.family: powerIconFont.name
                            font.pixelSize: 15
                            color: btnMa.containsMouse
                                   ? (isDestructive ? Theme.colError : bar.fg)
                                   : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.8)
                            Behavior on color { ColorAnimation { duration: 130 } }
                        }
                    }

                    MouseArea {
                        id: btnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: btnRoot.triggered()
                    }
                }

                // 1. Lock
                PowerCircleBtn {
                    iconCode: "\ueae2"
                    tooltipText: "Lock"
                    onTriggered: {
                        globalState.powerDropdownOpen = false;
                        Quickshell.execDetached(["bash", "-c", "hyprlock"]);
                    }
                }

                // 2. Suspend / Sleep
                PowerCircleBtn {
                    iconCode: "\uea1e"
                    tooltipText: "Sleep"
                    onTriggered: {
                        globalState.powerDropdownOpen = false;
                        Quickshell.execDetached(["bash", "-c", "systemctl suspend"]);
                    }
                }

                // 3. Restart
                PowerCircleBtn {
                    iconCode: "\ueb13"
                    tooltipText: "Restart"
                    onTriggered: {
                        globalState.powerDropdownOpen = false;
                        Quickshell.execDetached(["bash", "-c", "systemctl reboot"]);
                    }
                }

                // 4. Power Off
                PowerCircleBtn {
                    iconCode: "\ueb0d"
                    tooltipText: "Shut Down"
                    isDestructive: true
                    onTriggered: {
                        globalState.powerDropdownOpen = false;
                        Quickshell.execDetached(["bash", "-c", "systemctl poweroff"]);
                    }
                }
            }
        }
    }
}
