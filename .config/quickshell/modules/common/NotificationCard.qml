import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"

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

        color: Qt.rgba(Theme.colSurfaceContainerHigh.r, Theme.colSurfaceContainerHigh.g, Theme.colSurfaceContainerHigh.b, root.globalOpacity)
        clip: true
        radius: 16
        border.color: "#80000000" // sleek dark border
        border.width: 0

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
            enabled: wrapper.inPanel || !globalState.hideIsland
            onEntered: { if (!wrapper.inPanel) globalState.popupHovered = true; }
            onExited:  { if (!pressed && !wrapper.inPanel) globalState.popupHovered = false; }
            drag.target: toastCard
            drag.axis: Drag.XAxis
            onPressed: event => {
                if (!wrapper.inPanel) globalState.popupHovered = true;
                startY = event.y
                if (event.button === Qt.MiddleButton) {
                    if (!wrapper.inPanel) globalState.popups = globalState.popups.filter(n => n !== wrapper.notificationData)
                    if (wrapper.notificationData) wrapper.notificationData.close()
                }
            }
            onReleased: event => {
                if (!containsMouse && !wrapper.inPanel) {
                    globalState.popupHovered = false;
                }
                if (Math.abs(toastCard.x) < 150) {
                    toastCard.x = 0
                } else {
                    if (!wrapper.inPanel) globalState.popups = globalState.popups.filter(n => n !== wrapper.notificationData)
                    if (wrapper.notificationData) wrapper.notificationData.close()
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
                const actions = wrapper.notificationData ? wrapper.notificationData.actions : []
                if (actions && actions.length > 0) actions[0].invoke()
            }
        }

        Item {
            id: mainRow
            anchors.left: parent.left
            anchors.leftMargin: wrapper.inPanel ? 10 : 20
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.top: parent.top
            anchors.topMargin: 10
            // Height tracks the text column so the icon can center against it
            height: textCol.height

            // App icon — vertically centered against the whole card
            Rectangle {
                id: iconRect
                width: 40; height: 40
                radius: 20
                color: !iconImg.visible ? Theme.colPrimary : "transparent"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                Image {
                    id: iconImg
                    anchors.fill: parent
                    anchors.margins: 2
                    source: {
                        if (!wrapper.notificationData) return "";
                        if (wrapper.notificationData.image) return wrapper.notificationData.image;
                        if (wrapper.notificationData.appIcon) {
                            if (wrapper.notificationData.appIcon.startsWith("/")) {
                                return "file://" + wrapper.notificationData.appIcon;
                            }
                            return "image://icon/" + wrapper.notificationData.appIcon;
                        }
                        return "";
                    }
                    sourceSize: Qt.size(40, 40)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: status === Image.Ready
                }
                Text {
                    text: "\uea35" // ti-bell
                    color: Theme.colOnPrimary
                    font.family: "tabler-icons"
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
                            text: wrapper.notificationData ? wrapper.notificationData.appName : ""
                            color: Theme.colOnSurfaceVariant
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                        Text {
                            text: " • "
                            color: Theme.colOnSurfaceVariant
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 11
                            visible: appNameText.text !== ""
                        }
                        Text {
                            id: summaryText
                            text: wrapper.notificationData ? wrapper.notificationData.summary : ""
                            color: Theme.colOnSurface
                            font.family: Theme.monoFontFamily
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
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 11
                        }
                    }

                    Text {
                        id: timeText
                        text: wrapper.notificationData ? Qt.formatTime(new Date(wrapper.notificationData.time / 1000), "hh:mm") : ""
                        color: Theme.colOnSurfaceVariant
                        font.family: Theme.monoFontFamily
                        font.pixelSize: 10
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // ── Body preview (collapsed, 1 line) ────────────────────────
                Text {
                    width: parent.width
                    text: wrapper.notificationData ? wrapper.notificationData.body : ""
                    color: Theme.colOnSurfaceVariant
                    font.family: Theme.monoFontFamily
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
                    text: wrapper.notificationData ? wrapper.notificationData.body : ""
                    color: Theme.colOnSurfaceVariant
                    font.family: Theme.monoFontFamily
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
                    height: (toastCard.expanded && wrapper.notificationData && wrapper.notificationData.actions && wrapper.notificationData.actions.length > 0) ? implicitHeight : 0
                    opacity: toastCard.expanded ? 1 : 0
                    clip: true
                    Behavior on height  { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    Repeater {
                        model: wrapper.notificationData ? wrapper.notificationData.actions : null
                        delegate: Rectangle {
                            color: ah.hovered ? Theme.colOnSurfaceVariant : Theme.colOutline
                            radius: 6
                            width: al.implicitWidth + 16; height: 26
                            Text { id: al; text: modelData.text; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 11; anchors.centerIn: parent }
                            HoverHandler { id: ah }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: modelData.invoke() }
                        }
                    }
                }
            }
        }
    }
}
