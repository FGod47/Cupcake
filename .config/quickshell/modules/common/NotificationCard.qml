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
        height: Math.max(textCol.height, iconRect.height) + 20

        color: Qt.rgba(Theme.colSurfaceContainerHigh.r, Theme.colSurfaceContainerHigh.g, Theme.colSurfaceContainerHigh.b, root.globalOpacity)
        clip: true
        radius: 16
        border.color: Qt.rgba(1, 1, 1, 0.05)
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
            anchors.leftMargin: wrapper.inPanel ? 10 : 12
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.top: parent.top
            anchors.topMargin: 10
            height: Math.max(textCol.height, iconRect.height)

            // App icon (Left)
            Rectangle {
                id: iconRect
                width: 36; height: 36
                radius: 10
                color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.1)
                border.color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.3)
                border.width: 1
                anchors.left: parent.left
                anchors.top: parent.top

                Image {
                    id: iconImg
                    anchors.fill: parent
                    anchors.margins: 10
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
                    sourceSize: Qt.size(22, 22)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: status === Image.Ready
                }
                Text {
                    text: "\uea35" // ti-bell
                    color: Theme.colPrimary
                    font.family: "tabler-icons"
                    font.pixelSize: 20
                    anchors.centerIn: parent
                    visible: !iconImg.visible
                }
            }

            // Text column
            Column {
                id: textCol
                anchors.left: iconRect.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 4

                // Top row: AppName • Title + Controls
                Item {
                    width: parent.width
                    height: Math.max(combinedTitleText.implicitHeight, topRightControls.implicitHeight)

                    Text {
                        id: combinedTitleText
                        anchors.left: parent.left
                        anchors.right: topRightControls.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        textFormat: Text.RichText
                        text: {
                            let app = wrapper.notificationData ? wrapper.notificationData.appName : ""
                            let sum = wrapper.notificationData ? wrapper.notificationData.summary : ""
                            let out = ""
                            if (app) out += `<font color="${Theme.colOnSurfaceVariant}">${app} &bull; </font>`
                            out += `<b>${sum}</b>`
                            return out
                        }
                        color: Theme.colOnSurface
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        clip: true
                    }

                    Row {
                        id: topRightControls
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        
                        Text {
                            id: timeText
                            text: wrapper.notificationData && wrapper.notificationData.time ? Qt.formatTime(new Date(wrapper.notificationData.time / 1000), "hh:mm") : ""
                            color: Theme.colOnSurfaceVariant
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                            visible: text !== ""
                        }

                        Item {
                            width: 24
                            height: 24
                            anchors.verticalCenter: parent.verticalCenter
                            visible: wrapper.notificationData && (wrapper.notificationData.body !== "" || (wrapper.notificationData.actions && wrapper.notificationData.actions.length > 0))

                            Rectangle {
                                anchors.fill: parent
                                radius: 6
                                color: expandMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.05)
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            Text {
                                id: expandChevronText
                                text: "\uea5f" // always chevron-down
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                                anchors.centerIn: parent
                                rotation: toastCard.expanded ? -180 : 0
                                Behavior on rotation { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                            }

                            MouseArea {
                                id: expandMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: toastCard.expanded = !toastCard.expanded
                            }
                        }

                        Item {
                            width: 24
                            height: 24
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                anchors.fill: parent
                                radius: 6
                                color: closeMouse.containsMouse ? Qt.rgba(1, 0.2, 0.2, 0.2) : Qt.rgba(1, 1, 1, 0.05)
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            Text {
                                text: "\ueb55" // close x
                                color: closeMouse.containsMouse ? Theme.colError : Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 14
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: closeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!wrapper.inPanel) globalState.popups = globalState.popups.filter(n => n !== wrapper.notificationData)
                                    if (wrapper.notificationData) wrapper.notificationData.close()
                                }
                            }
                        }
                    }
                }

                // Body preview (collapsed, 1 line)
                Text {
                    width: parent.width
                    text: wrapper.notificationData ? wrapper.notificationData.body : ""
                    color: Theme.colOnSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    visible: text !== ""
                    height: (!toastCard.expanded && text !== "") ? implicitHeight : 0
                    opacity: toastCard.expanded ? 0 : 1
                    clip: true
                    Behavior on height  { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                // Full body (expanded, wrapping)
                Text {
                    width: parent.width
                    text: wrapper.notificationData ? wrapper.notificationData.body : ""
                    color: Theme.colOnSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
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

                // Action buttons (expanded)
                Flow {
                    width: parent.width
                    spacing: 8
                    height: (toastCard.expanded && wrapper.notificationData && wrapper.notificationData.actions && wrapper.notificationData.actions.length > 0) ? implicitHeight : 0
                    opacity: toastCard.expanded ? 1 : 0
                    clip: true
                    Behavior on height  { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    Repeater {
                        model: wrapper.notificationData ? wrapper.notificationData.actions : null
                        delegate: Rectangle {
                            property bool isFirst: index === 0
                            color: ah.hovered ? (isFirst ? Qt.lighter(Theme.colPrimary, 1.2) : Qt.rgba(1, 1, 1, 0.15)) : (isFirst ? Theme.colPrimary : Qt.rgba(1, 1, 1, 0.05))
                            border.color: isFirst ? "transparent" : Qt.rgba(1, 1, 1, 0.1)
                            border.width: isFirst ? 0 : 1
                            radius: 8
                            width: al.implicitWidth + 24; height: 32
                            
                            Text { 
                                id: al; 
                                text: modelData.text; 
                                color: isFirst ? Theme.colOnPrimary : Theme.colOnSurface; 
                                font.family: Theme.fontFamily; 
                                font.pixelSize: 12; 
                                font.bold: isFirst
                                anchors.centerIn: parent 
                            }
                            HoverHandler { id: ah }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: modelData.invoke() }
                        }
                    }
                }
            }
        }
    }
}
