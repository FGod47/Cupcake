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
    Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

    property bool menuExpanded: globalState.powerDropdownOpen
    readonly property real openGap: 12
    property real contentW: 145

    x: bar.barX + bar.barW - contentW - 4
    width: contentW
    height: menuExpanded ? (powerMenu.implicitHeight + 20) : 0

    Behavior on x      { NumberAnimation { duration: 280; easing.type: Easing.OutExpo } }
    Behavior on width  { NumberAnimation { duration: 280; easing.type: Easing.OutExpo } }
    Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.OutExpo } }

    property real openProgress: menuExpanded ? 1.0 : 0.0
    property real scaleProgress: menuExpanded ? 1.0 : 0.0
    Behavior on openProgress  { NumberAnimation { duration: 260; easing.type: Easing.OutExpo } }
    Behavior on scaleProgress { NumberAnimation { duration: 260; easing.type: Easing.OutExpo } }

    opacity: openProgress
    visible: opacity > 0.01

    FontLoader {
        id: powerIconFont
        source: Qt.resolvedUrl("file://" + Quickshell.env("HOME") + "/.local/share/fonts/tabler-icons.ttf")
    }

    Item {
        id: animContainer
        anchors.fill: parent
        transformOrigin: powerSplitPill.isAttached ? Item.Top : Item.Center
        scale: powerSplitPill.isAttached ? powerSplitPill.scaleProgress : 1.0
        opacity: powerSplitPill.openProgress

        // ── Attached Mode Shape ──────────────────────────────────
        Shape {
            id: bgShape
            anchors.fill: parent
            visible: powerSplitPill.isAttached
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

                PathArc {
                    x: bgShape.r
                    y: bgShape.r
                    radiusX: bgShape.r
                    radiusY: bgShape.r
                    direction: PathArc.Clockwise
                }
                PathLine {
                    x: bgShape.r
                    y: Math.max(bgShape.r, bgShape.h - bgShape.r)
                }
                PathQuad {
                    x: 2 * bgShape.r
                    y: bgShape.h
                    controlX: bgShape.r
                    controlY: bgShape.h
                }
                PathLine {
                    x: Math.max(2 * bgShape.r, bgShape.w - 2 * bgShape.r)
                    y: bgShape.h
                }
                PathQuad {
                    x: bgShape.w - bgShape.r
                    y: Math.max(bgShape.r, bgShape.h - bgShape.r)
                    controlX: bgShape.w - bgShape.r
                    controlY: bgShape.h
                }
                PathLine {
                    x: bgShape.w - bgShape.r
                    y: bgShape.r
                }
                PathArc {
                    x: bgShape.w
                    y: 0
                    radiusX: bgShape.r
                    radiusY: bgShape.r
                    direction: PathArc.Clockwise
                }
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
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

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
