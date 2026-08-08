import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../common"

PanelWindow {
    id: islandWindow

    anchors {
        top: true
    }

    margins {
        top: 8
    }

    readonly property real screenW: screen ? screen.width : 1920
    implicitWidth: screenW
    implicitHeight: 400
    color: "transparent"

    WlrLayershell.namespace: "quickshell:notifisland"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    property var activePopups: (globalState && globalState.popups) ? globalState.popups : []
    property bool hasPopups: activePopups.length > 0 && !globalState.hideIsland
    property var topNotif: hasPopups ? activePopups[0] : null

    // Click-through mask: Only intercept clicks inside the animated island card
    mask: Region {
        Region { item: islandCard; active: islandWindow.hasPopups && islandCard.opacity > 0 }
    }

    Item {
        id: rootContainer
        anchors.fill: parent

        Rectangle {
            id: islandCard
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            // Dynamic width and height calculations
            width: hasPopups ? 380 : 160
            height: hasPopups ? Math.min(320, Math.max(48, notifContentCol.implicitHeight + 20)) : 0
            opacity: hasPopups ? 1.0 : 0.0

            radius: hasPopups ? 22 : 12
            color: Qt.rgba(Theme.colSurfaceContainer.r, Theme.colSurfaceContainer.g, Theme.colSurfaceContainer.b, globalState.notifPanelOpacity || 0.92)

            border.color: {
                if (topNotif && topNotif.urgency === 2) return Qt.rgba(Theme.colError.r, Theme.colError.g, Theme.colError.b, 0.4);
                return Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.25);
            }
            border.width: 1
            clip: true

            // Smooth fluid macOS/iPhone Dynamic Island spring animations
            Behavior on width {
                NumberAnimation {
                    duration: globalState.closingIsland ? 350 : 500
                    easing.type: globalState.closingIsland ? Easing.InOutQuart : Easing.OutBack
                    easing.overshoot: 0.4
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: globalState.closingIsland ? 350 : 500
                    easing.type: globalState.closingIsland ? Easing.InOutQuart : Easing.OutBack
                    easing.overshoot: 0.4
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            // Outer subtle glow shadow
            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                radius: parent.radius + 1
                color: "transparent"
                border.color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                z: -1
            }

            Column {
                id: notifContentCol
                anchors.top: parent.top
                anchors.topMargin: 10
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 10
                spacing: 8

                opacity: islandCard.height > 20 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Repeater {
                    model: islandWindow.hasPopups ? Math.min(islandWindow.activePopups.length, 3) : 0
                    delegate: Item {
                        width: notifContentCol.width
                        property bool isOverflow: islandWindow.activePopups.length > 3 && index === 2
                        height: isOverflow ? 32 : notifItemCard.height

                        NotificationCard {
                            id: notifItemCard
                            width: parent.width
                            notificationData: !parent.isOverflow ? islandWindow.activePopups[index] : null
                            inPanel: false
                            visible: !parent.isOverflow
                        }

                        Rectangle {
                            width: parent.width
                            height: 32
                            radius: 16
                            color: Qt.rgba(Theme.colSurfaceContainerHigh.r, Theme.colSurfaceContainerHigh.g, Theme.colSurfaceContainerHigh.b, 0.6)
                            border.color: Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1
                            visible: parent.isOverflow

                            Text {
                                anchors.centerIn: parent
                                text: "+" + (islandWindow.activePopups.length - 2) + " more notifications"
                                color: Theme.colPrimary
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }
                    }
                }
            }
        }
    }
}
