import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../common"
import "../../../theme"

Item {
    id: volBrightSplitPill

    readonly property bool isAttached: Theme.barDropdownStyle === "Attached"
    y: bar.isBottom ? (solidBar.y - height - (isAttached ? 0 : 8)) : (isAttached ? (solidBar.y + solidBar.height) : (solidBar.y + solidBar.height + 8))
    Behavior on y { enabled: !bar.isBottom; NumberAnimation { duration: 350; easing.type: Easing.InOutExpo } }

    property bool menuExpanded: bar.dropdownOpen
    property bool showSinkList: false
    readonly property real expandedW: 280
    property real contentW: expandedW

    readonly property real padTop: isAttached ? 0 : 14
    readonly property real padSide: isAttached ? 26 : 14
    readonly property real padBottom: isAttached ? 22 : 14

    readonly property real targetH: volBrightContentCol.implicitHeight + padTop + padBottom

    // Align dropdown right edge to next section boundary (Tray or Clock)
    x: (sysTrayRepeater.count > 0 ? sysTrayRow.x : clockItem.x) + contentLayout.x + solidBar.x - contentW
    width: contentW
    height: menuExpanded ? targetH : 0

    // Carousel Wallpaper Switcher signature InOutExpo & BezierSpline curves
    Behavior on height {
        NumberAnimation {
            duration: 380
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]
        }
    }
    Behavior on width {
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

    Item {
        id: animContainer
        anchors.fill: parent
        clip: false
        layer.enabled: true
        layer.samples: 8
        layer.smooth: true

        // ── Attached Mode Shape ──────────────────────────────────
        Shape {
            id: bgShape
            anchors.fill: parent
            visible: volBrightSplitPill.isAttached
            property color shapeColor: bar.pillColor
            readonly property real r: 16
            readonly property real w: width
            readonly property real h: Math.max(height, 1)

            layer.enabled: true
            layer.samples: 8
            layer.smooth: true

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
                PathArc {
                    x: 2 * bgShape.r
                    y: bgShape.h
                    radiusX: bgShape.r
                    radiusY: bgShape.r
                    direction: PathArc.Counterclockwise
                }
                PathLine {
                    x: Math.max(2 * bgShape.r, bgShape.w - 2 * bgShape.r)
                    y: bgShape.h
                }
                PathArc {
                    x: bgShape.w - bgShape.r
                    y: Math.max(bgShape.r, bgShape.h - bgShape.r)
                    radiusX: bgShape.r
                    radiusY: bgShape.r
                    direction: PathArc.Counterclockwise
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
            visible: !volBrightSplitPill.isAttached
            radius: 16
            color: bar.pillColor
            antialiasing: true
            border.width: 1
            border.color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.12)
        }

        MouseArea {
            id: volBrightSplitPillMa
            anchors.fill: parent
            enabled: bar.dropdownOpen
            hoverEnabled: true
            onClicked: {
                // Keep open on interaction
            }
        }

        // ── Inner Content Wrapper (Reveals smoothly without squishing) ──
        Item {
            id: innerClipWrapper
            anchors.fill: parent
            clip: true

            ColumnLayout {
                id: volBrightContentCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: volBrightSplitPill.padTop
                anchors.leftMargin: volBrightSplitPill.padSide
                anchors.rightMargin: volBrightSplitPill.padSide
                spacing: 12

                // Clean Category Header
                Item {
                    Layout.fillWidth: true
                    height: 16

                    Text {
                        text: "VOLUME & BRIGHTNESS"
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 0.5
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                        anchors.left: parent.left
                        anchors.leftMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Brightness Slider Row
                Row {
                    Layout.fillWidth: true
                    spacing: 12
                    Text {
                        text: bar.getBrightnessIcon(bar.brightStr)
                        font.family: fontName
                        font.pixelSize: 18
                        color: bar.fg
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Slider {
                        id: ddBrightSlider
                        width: parent.width - 34
                        height: 22
                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: 0
                        rightPadding: 0
                        handle: Item { width: 0; height: 0; visible: false }
                        background: Rectangle {
                            x: 0
                            y: (parent.height - 6) / 2
                            width: parent.width
                            height: 6
                            radius: 3
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.2)
                            clip: true
                            Rectangle {
                                width: Math.max(0, ddBrightSlider.visualPosition * parent.width)
                                height: parent.height
                                color: Theme.colPrimary
                                radius: 3
                                visible: width > 0
                            }
                        }
                        from: 0; to: 100
                        value: parseFloat(bar.brightStr) || 0
                        Timer {
                            id: ddDdcTimer
                            interval: 500; repeat: false
                            property int targetValue: 100
                            onTriggered: Quickshell.execDetached(["ddcutil", "setvcp", "10", Math.round(targetValue).toString(), "--noverify"])
                        }
                        onMoved: { ddDdcTimer.targetValue = value; ddDdcTimer.restart(); bar.brightStr = Math.round(value).toString() }
                    }
                }

                // Volume Slider Row
                Row {
                    Layout.fillWidth: true
                    spacing: 12
                    Text {
                        text: bar.getVolumeIcon(bar.volStr, bar.isVolMuted)
                        font.family: fontName
                        font.pixelSize: 18
                        color: bar.isVolMuted ? Theme.colError : bar.fg
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                bar.isVolMuted = !bar.isVolMuted;
                                Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
                            }
                        }
                    }
                    Slider {
                        id: ddVolSlider
                        width: parent.width - 66
                        height: 22
                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: 0
                        rightPadding: 0
                        handle: Item { width: 0; height: 0; visible: false }
                        background: Rectangle {
                            x: 0
                            y: (parent.height - 6) / 2
                            width: parent.width
                            height: 6
                            radius: 3
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.2)
                            clip: true
                            Rectangle {
                                width: Math.max(0, ddVolSlider.visualPosition * parent.width)
                                height: parent.height
                                color: bar.isVolMuted ? Theme.colError : Theme.colPrimary
                                radius: 3
                                visible: width > 0
                            }
                        }
                        from: 0; to: 100
                        value: parseFloat(bar.volStr) || 0
                        Timer {
                            id: ddAudioVolTimer
                            interval: 50; repeat: false
                            property int targetVal: 100
                            onTriggered: Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.round(targetVal).toString() + "%"])
                        }
                        onMoved: { ddAudioVolTimer.targetVal = value; ddAudioVolTimer.restart(); bar.volStr = Math.round(value).toString() }
                    }

                    // Audio Output Sources Dropdown Toggle Button
                    Rectangle {
                        width: 24; height: 24; radius: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: sinkToggleMa.containsMouse ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.12) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "\uea5f"
                            font.family: fontName
                            font.pixelSize: 14
                            color: volBrightSplitPill.showSinkList ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                            rotation: volBrightSplitPill.showSinkList ? 180 : 0
                            Behavior on rotation {
                                NumberAnimation {
                                    duration: 320
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]
                                }
                            }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        MouseArea {
                            id: sinkToggleMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                volBrightSplitPill.showSinkList = !volBrightSplitPill.showSinkList;
                                if (volBrightSplitPill.showSinkList) {
                                    sinkFetchProc.running = true;
                                    activeSinkProc.running = true;
                                }
                            }
                        }
                    }
                }

                // Audio Output Devices Picker List (Accordion with Smooth Spring Expansion)
                Item {
                    id: sinkListContainer
                    Layout.fillWidth: true
                    Layout.preferredHeight: volBrightSplitPill.showSinkList ? sinkListCol.implicitHeight : 0
                    implicitHeight: Layout.preferredHeight
                    clip: true
                    opacity: volBrightSplitPill.showSinkList ? 1.0 : 0.0
                    visible: Layout.preferredHeight > 0 || opacity > 0.01

                    Behavior on Layout.preferredHeight {
                        NumberAnimation {
                            duration: 380
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.OutCubic
                        }
                    }

                    ColumnLayout {
                        id: sinkListCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 6

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.12)
                        }

                        Text {
                            text: "AUDIO OUTPUT"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 0.5
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                            Layout.topMargin: 2
                        }

                        Repeater {
                            model: bar.sinkList
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 34
                                radius: 17
                                property bool isActiveSink: modelData.name === bar.activeSinkName
                                color: sinkItemMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : (isActiveSink ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.18) : Qt.rgba(1, 1, 1, 0.04))
                                border.color: isActiveSink ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.35) : "transparent"
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: (modelData.name && (modelData.name.includes("hdmi") || modelData.name.includes("HDMI"))) ? "\ueb92" : ((modelData.name && modelData.name.includes("headphone")) ? "\uea76" : "")
                                        font.family: fontName
                                        font.pixelSize: 15
                                        color: isActiveSink ? Theme.colPrimary : bar.fg
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.description || modelData.name
                                        font.family: Theme.defaultFontFamily
                                        font.pixelSize: 11
                                        font.weight: isActiveSink ? Font.Bold : Font.Normal
                                        color: isActiveSink ? Theme.colPrimary : bar.fg
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: "\uea5e"
                                        font.family: fontName
                                        font.pixelSize: 14
                                        color: Theme.colPrimary
                                        visible: isActiveSink
                                    }
                                }

                                MouseArea {
                                    id: sinkItemMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["pactl", "set-default-sink", modelData.name]);
                                        bar.activeSinkName = modelData.name;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
