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
    y: isAttached ? (bar.midY + bar.barHeight) : (bar.midY + bar.barHeight + 8)
    Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

    property bool menuExpanded: bar.dropdownOpen
    property bool showSinkList: false
    readonly property real expandedW: 280
    property real contentW: expandedW

    readonly property real padTop: isAttached ? 22 : 14
    readonly property real padSide: isAttached ? 26 : 14
    readonly property real padBottom: isAttached ? 22 : 14

    x: bar.barX + bar.barW - contentW - 130
    width: contentW
    height: menuExpanded ? (volBrightContentCol.implicitHeight + padTop + padBottom) : 0

    Behavior on x      { NumberAnimation { duration: 280; easing.type: Easing.OutExpo } }
    Behavior on width  { NumberAnimation { duration: 280; easing.type: Easing.OutExpo } }
    Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.OutExpo } }

    property real openProgress: menuExpanded ? 1.0 : 0.0
    property real scaleProgress: menuExpanded ? 1.0 : 0.0
    Behavior on openProgress  { NumberAnimation { duration: 260; easing.type: Easing.OutExpo } }
    Behavior on scaleProgress { NumberAnimation { duration: 260; easing.type: Easing.OutExpo } }

    opacity: openProgress
    visible: opacity > 0.01

    Item {
        id: animContainer
        anchors.fill: parent
        transformOrigin: volBrightSplitPill.isAttached ? Item.Top : Item.Center
        scale: volBrightSplitPill.isAttached ? volBrightSplitPill.scaleProgress : 1.0
        opacity: volBrightSplitPill.openProgress

        // ── Attached Mode Shape ──────────────────────────────────
        Shape {
            id: bgShape
            anchors.fill: parent
            visible: volBrightSplitPill.isAttached
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
            visible: !volBrightSplitPill.isAttached
            radius: 16
            color: bar.pillColor
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

        // ── Expanded Sliders View ────────────────────────────────
        ColumnLayout {
            id: volBrightContentCol
            x: volBrightSplitPill.padSide
            y: volBrightSplitPill.padTop
            width: parent.width - (volBrightSplitPill.padSide * 2)
            spacing: 14
            opacity: volBrightSplitPill.menuExpanded ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

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
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true
                    handle: Rectangle {
                        x: ddBrightSlider.leftPadding + ddBrightSlider.visualPosition * (ddBrightSlider.availableWidth - width)
                        y: ddBrightSlider.height / 2 - height / 2
                        width: 14; height: 14; radius: 7
                        color: Theme.colPrimary
                    }
                    background: Rectangle {
                        x: ddBrightSlider.leftPadding
                        y: ddBrightSlider.height / 2 - height / 2
                        implicitWidth: 100
                        implicitHeight: 6
                        width: ddBrightSlider.availableWidth
                        height: implicitHeight
                        radius: 3
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.2)
                        Rectangle {
                            width: ddBrightSlider.visualPosition * parent.width
                            height: parent.height
                            color: Theme.colPrimary
                            radius: 3
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
                    onPressedChanged: {
                        if (!pressed) {
                            ddDdcTimer.stop()
                            Quickshell.execDetached(["ddcutil", "setvcp", "10", Math.round(value).toString()])
                        }
                    }
                }
            }

            // Volume Slider Row
            Row {
                Layout.fillWidth: true
                spacing: 8

                // Mute / Unmute Button
                Item {
                    width: 22; height: 22
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        text: bar.getVolumeIcon(bar.volStr, bar.isVolMuted)
                        font.family: fontName
                        font.pixelSize: 18
                        color: bar.isVolMuted ? Theme.colError : bar.fg
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
                            bar.isVolMuted = !bar.isVolMuted;
                        }
                    }
                }

                Slider {
                    id: ddVolSlider
                    width: parent.width - 56
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true
                    handle: Rectangle {
                        x: ddVolSlider.leftPadding + ddVolSlider.visualPosition * (ddVolSlider.availableWidth - width)
                        y: ddVolSlider.height / 2 - height / 2
                        width: 14; height: 14; radius: 7
                        color: bar.isVolMuted ? Theme.colError : Theme.colPrimary
                    }
                    background: Rectangle {
                        x: ddVolSlider.leftPadding
                        y: ddVolSlider.height / 2 - height / 2
                        implicitWidth: 100
                        implicitHeight: 6
                        width: ddVolSlider.availableWidth
                        height: implicitHeight
                        radius: 3
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.2)
                        Rectangle {
                            width: ddVolSlider.visualPosition * parent.width
                            height: parent.height
                            color: bar.isVolMuted ? Theme.colError : Theme.colPrimary
                            radius: 3
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
                Item {
                    width: 22; height: 22
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        text: volBrightSplitPill.showSinkList ? "\uea62" : "\uea5f"
                        font.family: fontName
                        font.pixelSize: 16
                        color: volBrightSplitPill.showSinkList ? Theme.colPrimary : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                    }
                    MouseArea {
                        anchors.fill: parent
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

            // Audio Output Devices Picker List
            ColumnLayout {
                id: sinkListCol
                Layout.fillWidth: true
                spacing: 6
                opacity: volBrightSplitPill.showSinkList ? 1.0 : 0.0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 250 } }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.15)
                }

                Text {
                    text: "AUDIO OUTPUT"
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                    Layout.topMargin: 4
                }

                Repeater {
                    model: bar.sinkList
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 34
                        radius: 17
                        property bool isActiveSink: modelData.name === bar.activeSinkName
                        color: sinkItemMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : (isActiveSink ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.20) : Qt.rgba(1, 1, 1, 0.04))
                        border.color: isActiveSink ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.35) : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
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
