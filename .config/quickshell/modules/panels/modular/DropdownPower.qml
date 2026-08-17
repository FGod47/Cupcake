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
    y: bar.isBottom ? (solidBar.y - height - (isAttached ? 0 : 8)) : (isAttached ? (bar.midY + bar.barHeight) : (bar.midY + bar.barHeight + 8))
    Behavior on y { enabled: !bar.isBottom; NumberAnimation { duration: 350; easing.type: Easing.InOutExpo } }

    property bool menuExpanded: globalState.powerDropdownOpen
    readonly property real expandedW: 160
    property real contentW: expandedW

    readonly property real padTop: isAttached ? 0 : 14
    readonly property real padLeft: isAttached ? 24 : 14
    readonly property real padRight: isAttached ? 14 : 14
    readonly property real padBottom: isAttached ? 20 : 14

    readonly property real targetH: powerMenu.implicitHeight + padTop + padBottom

    // Flush and level with the bar's right edge
    x: bar.barX + bar.barW - contentW
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
        clip: false

        // ── Attached Mode Shape (Flat Top & Flush Right Edge) ────
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

                // 1. Left concave notch merging with bar flat underside
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
                    x: Math.max(2 * bgShape.r, bgShape.w - bgShape.r)
                    y: bgShape.h
                }
                // 5. Bottom-Right rounded corner
                PathQuad {
                    x: bgShape.w
                    y: Math.max(bgShape.r, bgShape.h - bgShape.r)
                    controlX: bgShape.w
                    controlY: bgShape.h
                }
                // 6. Right vertical straight edge directly up to the bar
                PathLine {
                    x: bgShape.w
                    y: 0
                }
                // 7. Top horizontal flat edge back to (0, 0)
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

        // ── Inner Content Wrapper ────────────────────────────────
        Item {
            id: contentWrapper
            anchors.fill: parent
            clip: true
            opacity: powerSplitPill.menuExpanded ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
            }

            Column {
                id: powerMenu
                x: powerSplitPill.padLeft
                y: powerSplitPill.padTop
                width: parent.width - powerSplitPill.padLeft - powerSplitPill.padRight
                spacing: 4

                // Clean Category Header
                Item {
                    width: parent.width
                    height: 18

                    Text {
                        text: "POWER"
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 0.5
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                component CleanPowerItem: Rectangle {
                    id: itemRoot
                    property string iconCode: ""
                    property string labelText: ""
                    property bool isDestructive: false
                    signal triggered()

                    width: parent.width
                    height: 32
                    radius: 8
                    color: itemMa.containsMouse
                           ? (isDestructive ? Qt.rgba(Theme.colError.r, Theme.colError.g, Theme.colError.b, 0.15) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.10))
                           : "transparent"
                    Behavior on color { ColorAnimation { duration: 130 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 9

                        Text {
                            text: itemRoot.iconCode
                            font.family: powerIconFont.name
                            font.pixelSize: 14
                            color: itemMa.containsMouse
                                   ? (isDestructive ? Theme.colError : bar.fg)
                                   : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.75)
                            Behavior on color { ColorAnimation { duration: 130 } }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: itemRoot.labelText
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: itemMa.containsMouse
                                   ? (isDestructive ? Theme.colError : bar.fg)
                                   : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.85)
                            Behavior on color { ColorAnimation { duration: 130 } }
                        }
                    }

                    MouseArea {
                        id: itemMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: itemRoot.triggered()
                    }
                }

                // 1. Lock
                CleanPowerItem {
                    iconCode: "\ueae2"
                    labelText: "Lock"
                    onTriggered: {
                        globalState.powerDropdownOpen = false;
                        Quickshell.execDetached(["bash", "-c", "hyprlock"]);
                    }
                }

                // 2. Log Out
                CleanPowerItem {
                    iconCode: "\ueba8"
                    labelText: "Log Out"
                    onTriggered: {
                        globalState.powerDropdownOpen = false;
                        Quickshell.execDetached(["bash", "-c", "hyprctl dispatch exit || loginctl terminate-user $USER"]);
                    }
                }

                // 3. Restart
                CleanPowerItem {
                    iconCode: "\ueb13"
                    labelText: "Restart"
                    onTriggered: {
                        globalState.powerDropdownOpen = false;
                        Quickshell.execDetached(["bash", "-c", "systemctl reboot"]);
                    }
                }

                // 4. Power Off
                CleanPowerItem {
                    iconCode: "\ueb0d"
                    labelText: "Power Off"
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
