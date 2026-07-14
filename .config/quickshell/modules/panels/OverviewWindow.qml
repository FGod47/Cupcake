pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import "../../theme"

Item {
    id: root

    // --- Required inputs from parent ---
    required property var toplevel       // ToplevelManager toplevel
    required property var windowData     // hyprctl clients JSON entry
    required property real scaleFactor   // workspace scale (e.g. 0.18)
    required property real xOffset       // pixel offset for this workspace cell (column)
    required property real yOffset       // pixel offset for this workspace cell (row)

    // --- Interaction state ---
    property bool hovered: false
    property bool pressed: false

    // --- Geometry ---
    property real targetW: (windowData?.size[0] ?? 100) * scaleFactor
    property real targetH: (windowData?.size[1] ?? 60)  * scaleFactor

    x: Math.max((windowData?.at[0] ?? 0) * scaleFactor, 0) + xOffset
    y: Math.max((windowData?.at[1] ?? 0) * scaleFactor, 0) + yOffset
    width:  targetW
    height: targetH

    // Corner radii
    property real topLeftRadius:     4
    property real topRightRadius:    4
    property real bottomLeftRadius:  4
    property real bottomRightRadius: 4

    Behavior on x      { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on y      { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on width  { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.width; height: root.height
            topLeftRadius:     root.topLeftRadius
            topRightRadius:    root.topRightRadius
            bottomRightRadius: root.bottomRightRadius
            bottomLeftRadius:  root.bottomLeftRadius
        }
    }

    // Live screencopy of the actual window
    ScreencopyView {
        anchors.fill: parent
        captureSource: root.toplevel
        live: true

        // Hover / press overlay
        Rectangle {
            anchors.fill: parent
            topLeftRadius:     root.topLeftRadius
            topRightRadius:    root.topRightRadius
            bottomRightRadius: root.bottomRightRadius
            bottomLeftRadius:  root.bottomLeftRadius
            color: root.pressed  ? Qt.rgba(1,1,1,0.15) :
                   root.hovered  ? Qt.rgba(1,1,1,0.07) :
                                   "transparent"
            border.color: Qt.rgba(1,1,1,0.10)
            border.width: 1
        }
    }
}
