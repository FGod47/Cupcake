import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: popupWindow
    anchors {
        top: true
        right: true
    }

    margins {
        top: 45      // flush against the bottom of the 34px pill + 6px bar margin + 5px gap = ~45
        right: 80    // aligned left of power pill
    }

    // Mirror the clock pill's dynamic width exactly
    implicitWidth: globalState.activeNotifWidth > 0 ? globalState.activeNotifWidth : 380
    implicitHeight: popupColumn.implicitHeight + 16  // 16px bottom padding so radius shows

    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    // Only show when 2+ notifications are queued
    visible: globalState.popups && globalState.popups.length > 1

    // Background box — rounded bottom, straight top (merges with pill)
    Rectangle {
        width: parent.width
        height: parent.height
        color: "#27293F"
        radius: 18

        // Cover the top rounded corners so it looks flush with the pill
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 18
            color: "#27293F"
        }

        Column {
            id: popupColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 8
            }
            spacing: 6

            Repeater {
                // Show everything except the first (shown in pill)
                model: globalState.popups && globalState.popups.length > 1
                       ? globalState.popups.slice(1) : []

                delegate: NotificationCard {
                    width: popupColumn.width
                    notificationData: modelData
                    inPanel: false
                }
            }
        }
    }
}
