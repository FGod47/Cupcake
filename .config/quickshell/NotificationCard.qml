import QtQuick
import QtQuick.Layouts
import Quickshell
import "theme"

Item {
    id: wrapper
    property var notificationData
    property bool inPanel: false

    width: parent ? parent.width : 320
    height: toastCard.height
    
    Behavior on y {
        enabled: !wrapper.inPanel
        NumberAnimation { duration: 400; easing.type: Easing.OutQuart }
    }

    Rectangle {
        id: toastCard
        property bool expanded: false

        width: wrapper.width
        // Use mainRow.height (explicitly set) NOT implicitHeight (0 for Item)
        height: mainRow.height + 20

        color: Theme.colSurface
        clip: true
        radius: 16
        border.color: Theme.colPrimary
        border.width: 1

        x: 0
        y: wrapper.inPanel ? 0 : -150
        Component.onCompleted: {
            if (!wrapper.inPanel) {
                y = 0;
            }
        }
        Behavior on y {
            enabled: !swipeArea.pressed
            NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 0.5 }
        }
        Behavior on x {
            enabled: !swipeArea.pressed
            NumberAnimation { duration: 300; easing.type: Easing.OutQuart }
        }

        MouseArea {
            id: swipeArea
            property int startY
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: pressed ? Qt.ClosedHandCursor : undefined
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            preventStealing: true
            onEntered: { if (!wrapper.inPanel && notificationData && notificationData.timer) notificationData.timer.stop() }
            onExited:  { if (!pressed && !wrapper.inPanel && notificationData && notificationData.timer) notificationData.timer.start() }
            drag.target: toastCard
            drag.axis: Drag.XAxis
            onPressed: event => {
                if (!wrapper.inPanel && notificationData && notificationData.timer) notificationData.timer.stop()
                startY = event.y
                if (event.button === Qt.MiddleButton) {
                    if (!wrapper.inPanel) globalState.popups = globalState.popups.filter(n => n !== notificationData)
                    if (notificationData) notificationData.close()
                }
            }
            onReleased: event => {
                if (!containsMouse && !wrapper.inPanel && notificationData && notificationData.timer) notificationData.timer.start()
                if (Math.abs(toastCard.x) < 150) {
                    toastCard.x = 0
                } else {
                    if (!wrapper.inPanel) globalState.popups = globalState.popups.filter(n => n !== notificationData)
                    if (notificationData) notificationData.close()
                }
            }
            onPositionChanged: event => {
                if (pressed) {
                    const diffY = event.y - startY
                    if (Math.abs(diffY) > 30) toastCard.expanded = diffY > 0
                }
            }
            onClicked: event => {
                if (event.button !== Qt.LeftButton) return
                const actions = notificationData ? notificationData.actions : []
                if (actions && actions.length > 0) actions[0].invoke()
            }
        }

        Item {
            id: mainRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            // Height tracks the text column so the icon can center against it
            height: textCol.height

            // App icon — vertically centered against the whole card
            Rectangle {
                id: iconRect
                width: 40; height: 40
                radius: 20
                color: Theme.colOutline
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                Image {
                    id: iconImg
                    anchors.fill: parent
                    anchors.margins: 2
                    source: notificationData && notificationData.appIcon
                        ? (notificationData.appIcon.startsWith("/")
                            ? "file://" + notificationData.appIcon
                            : "image://icon/" + notificationData.appIcon)
                        : ""
                    sourceSize: Qt.size(40, 40)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: status === Image.Ready
                }
                Text {
                    text: "\uf0f3"
                    color: Theme.colOnSurface
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 18
                    anchors.centerIn: parent
                    visible: !iconImg.visible
                }
            }

            // Text column
            Column {
                id: textCol
                anchors.left: iconRect.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 2

                // ── Top row: AppName • Title  [time] ────────────────────────
                Item {
                    width: parent.width
                    height: appTitleRow.implicitHeight

                    Row {
                        id: appTitleRow
                        anchors.left: parent.left
                        anchors.right: timeText.left
                        anchors.rightMargin: 6
                        spacing: 0

                        Text {
                            id: appNameText
                            text: notificationData ? notificationData.appName : ""
                            color: Theme.colOnSurfaceVariant
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                        Text {
                            text: " • "
                            color: Theme.colOnSurfaceVariant
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 11
                            visible: appNameText.text !== ""
                        }
                        Text {
                            id: summaryText
                            text: notificationData ? notificationData.summary : ""
                            color: Theme.colOnSurface
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 12
                            font.bold: true
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            width: appTitleRow.width - appNameText.implicitWidth - (appNameText.text !== "" ? separatorDot.implicitWidth : 0)
                        }
                        Text {
                            id: separatorDot
                            visible: false  // just used for width measurement
                            text: " • "
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 11
                        }
                    }

                    Text {
                        id: timeText
                        text: notificationData ? Qt.formatTime(new Date(notificationData.time / 1000), "hh:mm") : ""
                        color: Theme.colOnSurfaceVariant
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 10
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // ── Body preview (collapsed, 1 line) ────────────────────────
                Text {
                    width: parent.width
                    text: notificationData ? notificationData.body : ""
                    color: Theme.colOnSurfaceVariant
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    visible: text !== ""
                    height: (!toastCard.expanded && text !== "") ? implicitHeight : 0
                    opacity: toastCard.expanded ? 0 : 1
                    clip: true
                    Behavior on height  { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                // ── Full body (expanded, wrapping) ──────────────────────────
                Text {
                    width: parent.width
                    text: notificationData ? notificationData.body : ""
                    color: Theme.colOnSurfaceVariant
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    textFormat: Text.StyledText
                    visible: text !== ""
                    onLinkActivated: Qt.openUrlExternally(link)
                    height: (toastCard.expanded && text !== "") ? implicitHeight : 0
                    opacity: toastCard.expanded ? 1 : 0
                    clip: true
                    Behavior on height  { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                // ── Action buttons (expanded) ────────────────────────────────
                Flow {
                    width: parent.width
                    spacing: 6
                    height: (toastCard.expanded && notificationData && notificationData.actions && notificationData.actions.length > 0) ? implicitHeight : 0
                    opacity: toastCard.expanded ? 1 : 0
                    clip: true
                    Behavior on height  { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    Repeater {
                        model: notificationData ? notificationData.actions : null
                        delegate: Rectangle {
                            color: ah.hovered ? Theme.colOnSurfaceVariant : Theme.colOutline
                            radius: 6
                            width: al.implicitWidth + 16; height: 26
                            Text { id: al; text: modelData.text; color: Theme.colOnSurface; font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 11; anchors.centerIn: parent }
                            HoverHandler { id: ah }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: modelData.invoke() }
                        }
                    }
                }
            }
        }
    }
}
