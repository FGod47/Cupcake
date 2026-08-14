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
    readonly property real expandedW: 155
    property real contentW: expandedW

    readonly property real padTop: isAttached ? 22 : 14
    readonly property real padLeft: isAttached ? 24 : 14
    readonly property real padRight: isAttached ? 14 : 14
    readonly property real padBottom: isAttached ? 22 : 14

    readonly property real targetH: powerMenu.implicitHeight + padTop + padBottom

    // Flush and level with the bar's right edge
    x: bar.barX + bar.barW - contentW
    width: contentW
    height: menuExpanded ? targetH : 0

    // Carousel Wallpaper Switcher signature InOutExpo & BezierSpline curves
    Behavior on height {
        NumberAnimation {
            duration: 500
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
            duration: 350
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

        // ── Attached Mode Shape (Left Concave Notch, Flush Right Edge) ────
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

                // 1. Left concave notch from bar underside
                PathArc {
                    x: bgShape.r
                    y: bgShape.r
                    radiusX: bgShape.r
                    radiusY: bgShape.r
                    direction: PathArc.Clockwise
                }
                // 2. Left straight edge
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
                // 4. Bottom straight edge
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
                // 6. Right edge straight up flush with the bar
                PathLine {
                    x: bgShape.w
                    y: 0
                }
                // 7. Close path to top-left
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

        // ── Inner Content Wrapper (Reveals smoothly without squishing) ──
        Item {
            id: contentWrapper
            anchors.fill: parent
            clip: true
            opacity: powerSplitPill.menuExpanded ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
            }

            // ── Expanded Power Menu ─────────────────────────────────────
            Column {
                id: powerMenu
                x: powerSplitPill.padLeft
                y: powerSplitPill.padTop
                width: parent.width - powerSplitPill.padLeft - powerSplitPill.padRight
                spacing: 4

                // Category Header
                Item {
                    width: parent.width
                    height: 20

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
                        radius: height / 2
                        color: itemMa.containsMouse
                               ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.12)
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
    }
}
