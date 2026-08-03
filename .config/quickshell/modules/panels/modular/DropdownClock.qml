import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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

    Rectangle {
        id: clockSplitPill
        y: 10
        property bool menuExpanded: globalState.solidBoardOpen
        height: menuExpanded ? (clockContentCol.implicitHeight + 24) : 30
        Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutQuart } }

        readonly property real openGap: 16
        readonly property real headerW: clockOptionsRow.implicitWidth + 24
        readonly property real expandedW: 280
        property real contentW: menuExpanded ? expandedW : headerW

        x: globalState.solidBoardOpen ? (bar.barX + bar.barW - 36 - 16 - contentW) : (bar.barX + bar.barW - contentW)
        width: contentW

        Behavior on x     { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }

        radius: menuExpanded ? 16 : 15
        Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        clip: true

        color: bar.pillColor
        border.color: Qt.rgba(1, 1, 1, 0.10)
        border.width: 1

        // Top glass highlight
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 4; anchors.rightMargin: 4
            height: 1; radius: 1
            color: Qt.rgba(1, 1, 1, 0.10)
        }

        opacity: (globalState.solidBoardOpen || bar.dropdownOpen || bar.netDropdownOpen) ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }

        MouseArea {
            id: clockSplitPillMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: (mouseY <= 30) ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (mouse.y <= 30) {
                    if (globalState.solidBoardOpen) {
                        globalState.solidBoardOpen = false;
                    } else {
                        bar.dropdownOpen = false;
                        bar.netDropdownOpen = false;
                        globalState.powerDropdownOpen = false;
                        globalState.solidBoardOpen = true;
                    }
                }
            }
        }

        // ── Header (Tray + Clock & Date Text + Power Icon when dropdown open) ──────
        Row {
            id: clockOptionsRow
            anchors.horizontalCenter: parent.horizontalCenter
            y: (30 - height) / 2
            spacing: 4
            opacity: clockSplitPill.menuExpanded ? 0.0 : 1.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250 } }

            // Hardware Icons (Brightness & Volume) — shown in this pill when Network separates
            Row {
                id: hwRow
                spacing: 12
                anchors.verticalCenter: parent.verticalCenter
                opacity: bar.netDropdownOpen ? 1.0 : 0.0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                MouseArea {
                    id: bMouseClock
                    width: childrenRect.width
                    height: 20
                    anchors.verticalCenter: parent.verticalCenter
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        bar.netDropdownOpen = false;
                        bar.dropdownOpen = true;
                    }

                    Row {
                        height: 20
                        spacing: bMouseClock.containsMouse ? 4 : 0
                        Behavior on spacing { NumberAnimation { duration: 200 } }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: bar.getBrightnessIcon(bar.brightStr)
                            font.family: fontName
                            font.pixelSize: Theme.defaultFontSize
                            color: bar.fg
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: bar.brightStr + "%"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: Theme.defaultFontSize
                            font.weight: Theme.defaultFontWeight
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                            width: bMouseClock.containsMouse ? implicitWidth : 0
                            clip: true
                            Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutSine } }
                        }
                    }
                }

                MouseArea {
                    id: vMouseClock
                    width: childrenRect.width
                    height: 20
                    anchors.verticalCenter: parent.verticalCenter
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        bar.netDropdownOpen = false;
                        bar.dropdownOpen = true;
                    }

                    Row {
                        height: 20
                        spacing: vMouseClock.containsMouse ? 4 : 0
                        Behavior on spacing { NumberAnimation { duration: 200 } }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: bar.getVolumeIcon(bar.volStr, bar.isVolMuted)
                            font.family: fontName
                            font.pixelSize: Theme.defaultFontSize
                            color: bar.isVolMuted ? Theme.colError : bar.fg
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: bar.volStr + "%"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: Theme.defaultFontSize
                            font.weight: Theme.defaultFontWeight
                            color: bar.isVolMuted ? Theme.colError : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                            width: vMouseClock.containsMouse ? implicitWidth : 0
                            clip: true
                            Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutSine } }
                        }
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "•"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 15
                font.weight: Theme.defaultFontWeight
                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.4)
                opacity: bar.netDropdownOpen ? 1.0 : 0.0
                visible: opacity > 0
            }

            // System Tray — shown in this pill when Vol/Bright or Network separates
            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter
                opacity: (bar.dropdownOpen || bar.netDropdownOpen) ? 1.0 : 0.0
                visible: opacity > 0 && sysTrayRepeaterClock.count > 0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Repeater {
                    id: sysTrayRepeaterClock
                    model: SystemTray.items
                    delegate: Item {
                        width: 13
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        IconImage {
                            anchors.centerIn: parent
                            source: modelData.icon || ""
                            width: 13
                            height: 13
                            layer.enabled: true
                            layer.effect: ColorOverlay { color: bar.fg }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.LeftButton) modelData.activate();
                                else if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                                    var pos = mapToItem(bar.contentItem, mouse.x, mouse.y);
                                    modelData.display(bar, pos.x, pos.y);
                                }
                            }
                        }
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "•"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 15
                font.weight: Theme.defaultFontWeight
                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.4)
                opacity: (bar.dropdownOpen || bar.netDropdownOpen) && sysTrayRepeaterClock.count > 0 ? 1.0 : 0.0
                visible: opacity > 0
            }

            MouseArea {
                id: clockSplitMouse
                width: childrenRect.width
                height: 20
                anchors.verticalCenter: parent.verticalCenter
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    bar.dropdownOpen = false;
                    bar.netDropdownOpen = false;
                    globalState.solidBoardOpen = true;
                }
                
                Row {
                    height: 20
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: clockSplitMouse.containsMouse ? 4 : 0
                    Behavior on spacing { NumberAnimation { duration: 200 } }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDateTime(timeClock.date, "MMM dd")
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: Theme.defaultFontSize
                        font.weight: Theme.defaultFontWeight
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                        width: clockSplitMouse.containsMouse ? implicitWidth : 0
                        clip: true
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutSine } }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "•"
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 15
                        font.weight: Theme.defaultFontWeight
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.4)
                        width: clockSplitMouse.containsMouse ? implicitWidth : 0
                        clip: true
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutSine } }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDateTime(timeClock.date, "hh:mm AP")
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: Theme.defaultFontSize
                        font.weight: Theme.defaultFontWeight
                        color: bar.fg
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "•"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 15
                font.weight: Theme.defaultFontWeight
                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.4)
                opacity: (bar.dropdownOpen || bar.netDropdownOpen) ? 1.0 : 0.0
                visible: opacity > 0
            }

            Item {
                width: 22; height: 26
                anchors.verticalCenter: parent.verticalCenter
                opacity: (bar.dropdownOpen || bar.netDropdownOpen) ? 1.0 : 0.0
                visible: opacity > 0
                Text {
                    anchors.centerIn: parent
                    text: "\ueb0d"
                    font.family: bar.fontName
                    font.pixelSize: 15
                    color: pma.containsMouse ? Theme.colError : bar.fg
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                MouseArea {
                    id: pma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        bar.dropdownOpen = false;
                        bar.netDropdownOpen = false;
                        globalState.powerDropdownOpen = true;
                    }
                }
            }
        }

        // ── Expanded Calendar & Clock View ────────────────────────────────
        ColumnLayout {
            id: clockContentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 10
            opacity: clockSplitPill.menuExpanded ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 300 } }

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

            // Separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.1)
            }

            // Inline Calendar
            Column {
                Layout.fillWidth: true
                spacing: 6

                property date currentDate: new Date()

                // Month header
                Row {
                    width: parent.width
                    Text {
                        text: Qt.formatDateTime(parent.currentDate, "MMMM yyyy")
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
                                let d = new Date(parent.parent.currentDate);
                                d.setMonth(d.getMonth() - 1);
                                parent.parent.currentDate = d;
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
                                let d = new Date(parent.parent.currentDate);
                                d.setMonth(d.getMonth() + 1);
                                parent.parent.currentDate = d;
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
                            width: (clockContentCol.width - 24) / 7
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
                            width: (clockContentCol.width - 24) / 7
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
