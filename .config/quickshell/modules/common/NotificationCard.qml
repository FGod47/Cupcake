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

    // Dynamic Category Detection
    property string notifCategory: {
        let sum = wrapper.notificationData ? wrapper.notificationData.summary.toLowerCase() : "";
        let app = wrapper.notificationData ? wrapper.notificationData.appName.toLowerCase() : "";
        let urg = wrapper.notificationData ? wrapper.notificationData.urgency : 1;
        
        if (sum.includes("battery") || app.includes("power")) return "battery";
        if (sum.includes("screenshot") || app.includes("grim") || app.includes("screenshot")) return "screenshot";
        if (sum.includes("music") || app.includes("spotify") || app.includes("player")) return "music";
        if (sum.includes("update") || app.includes("pacman") || app.includes("yay")) return "update";
        if (urg === 2 || sum.includes("fail") || sum.includes("error")) return "error";
        
        return "default";
    }

    property color accentColor: {
        switch (notifCategory) {
            case "screenshot": return Theme.colSuccess;
            case "music": return "#b185fa";
            case "update": return Theme.colSuccess;
            case "battery": return Theme.colWarning;
            case "error": return Theme.colError;
            default: return Theme.colPrimary;
        }
    }

    property bool isPill: notifCategory === "music" || notifCategory === "battery"

    Rectangle {
        id: toastCard
        property bool expanded: false

        width: wrapper.width
        height: mainCol.height + 24

        color: {
            if (notifCategory === "error") return Qt.rgba(Theme.colError.r, Theme.colError.g, Theme.colError.b, 0.08);
            return Qt.rgba(Theme.colSurfaceContainerHigh.r, Theme.colSurfaceContainerHigh.g, Theme.colSurfaceContainerHigh.b, root.globalOpacity);
        }
        
        clip: true
        radius: isPill ? height / 2 : 16
        
        border.color: {
            if (notifCategory === "error") return Qt.rgba(Theme.colError.r, Theme.colError.g, Theme.colError.b, 0.3);
            if (notifCategory === "battery") return Qt.rgba(Theme.colWarning.r, Theme.colWarning.g, Theme.colWarning.b, 0.3);
            if (notifCategory === "update") return Qt.rgba(Theme.colSuccess.r, Theme.colSuccess.g, Theme.colSuccess.b, 0.2);
            return Qt.rgba(1, 1, 1, 0.05);
        }
        border.width: 1

        x: 0
        y: wrapper.inPanel ? 0 : -150
        Component.onCompleted: { if (!wrapper.inPanel) y = 0; }
        Behavior on y { enabled: !swipeArea.pressed; NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
        Behavior on x { enabled: !swipeArea.pressed; NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }

        // Left Accent Bar removed per user request

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
                    try { if (wrapper.notificationData) wrapper.notificationData.dismiss() } catch(e){}
                }
            }
            onReleased: event => {
                if (!containsMouse && !wrapper.inPanel) globalState.popupHovered = false;
                if (Math.abs(toastCard.x) < 150) {
                    toastCard.x = 0
                } else {
                    if (!wrapper.inPanel) globalState.popups = globalState.popups.filter(n => n !== wrapper.notificationData)
                    try { if (wrapper.notificationData) wrapper.notificationData.dismiss() } catch(e){}
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

        Column {
            id: mainCol
            anchors.left: parent.left
            anchors.leftMargin: wrapper.inPanel ? 12 : 16
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.top: parent.top
            anchors.topMargin: 12
            spacing: 12

            // Top Section (Icon + Text + Controls)
            Item {
                width: parent.width
                height: Math.max(textCol.height, iconRect.height)

                // App icon (Left)
                Rectangle {
                    id: iconRect
                    width: isPill ? 40 : 36
                    height: isPill ? 40 : 36
                    radius: isPill ? width / 2 : 10
                    color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
                    border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3)
                    border.width: 1
                    anchors.left: parent.left
                    anchors.top: parent.top

                    Image {
                        id: iconImg
                        anchors.fill: parent
                        anchors.margins: isPill ? 10 : 8
                        source: {
                            if (!wrapper.notificationData) return "";
                            if (wrapper.notificationData.image) return wrapper.notificationData.image;
                            if (wrapper.notificationData.appIcon) {
                                if (wrapper.notificationData.appIcon.startsWith("/")) return "file://" + wrapper.notificationData.appIcon;
                                return "image://icon/" + wrapper.notificationData.appIcon;
                            }
                            return "";
                        }
                        sourceSize: Qt.size(24, 24)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        visible: status === Image.Ready
                    }
                    Text {
                        text: {
                            if (notifCategory === "screenshot") return ""; // camera
                            if (notifCategory === "music") return ""; // music
                            if (notifCategory === "update") return ""; // refresh
                            if (notifCategory === "battery") return ""; // battery
                            if (notifCategory === "error") return ""; // bluetooth-off (as example) or alert
                            return ""; // bell
                        }
                        color: accentColor
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
                    anchors.right: topRightControls.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        id: summaryText
                        width: parent.width
                        text: wrapper.notificationData ? wrapper.notificationData.summary : ""
                        color: Theme.colOnSurface
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        clip: true
                    }

                    Text {
                        id: bodyText
                        width: parent.width
                        text: wrapper.notificationData ? wrapper.notificationData.body : ""
                        color: Theme.colOnSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        wrapMode: toastCard.expanded ? Text.Wrap : Text.NoWrap
                        elide: toastCard.expanded ? Text.ElideNone : Text.ElideRight
                        maximumLineCount: toastCard.expanded ? 10 : 1
                        visible: text !== ""
                        clip: true
                    }
                }

                Row {
                    id: topRightControls
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    
                    Text {
                        id: timeText
                        text: wrapper.notificationData && wrapper.notificationData.time ? "just now" : "" // simplified for UI match
                        color: Theme.colOnSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                        visible: notifCategory === "screenshot"
                    }

                    // Battery Percentage Pill
                    Rectangle {
                        width: batteryPctText.implicitWidth + 16
                        height: 24
                        radius: 12
                        color: Qt.rgba(Theme.colWarning.r, Theme.colWarning.g, Theme.colWarning.b, 0.15)
                        anchors.verticalCenter: parent.verticalCenter
                        visible: notifCategory === "battery"
                        Text {
                            id: batteryPctText
                            text: "12%" // mock or extract from notificationData.percentage if available
                            color: Theme.colWarning
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            anchors.centerIn: parent
                        }
                    }

                    // Copy / Retry Inline Buttons (Action 0)
                    Rectangle {
                        property var action: (wrapper.notificationData && wrapper.notificationData.actions && wrapper.notificationData.actions.length > 0) ? wrapper.notificationData.actions[0] : null
                        visible: (notifCategory === "music" || notifCategory === "error") && action !== null
                        width: inlineActionText.implicitWidth + 24
                        height: 28
                        radius: isPill ? 14 : 8
                        color: inlineActionMouse.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2) : Qt.rgba(1,1,1,0.05)
                        border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3)
                        border.width: 1
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            id: inlineActionText
                            text: parent.action ? parent.action.text : (notifCategory === "music" ? "Copy" : "Retry")
                            color: accentColor
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            anchors.centerIn: parent
                        }
                        MouseArea {
                            id: inlineActionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (parent.action) parent.action.invoke()
                        }
                    }

                    Item {
                        width: 26
                        height: 26
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !isPill && notifCategory !== "error" && notifCategory !== "update" && (bodyText.truncated || toastCard.expanded || (wrapper.notificationData && wrapper.notificationData.actions && wrapper.notificationData.actions.length > 0))

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: expandMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.05)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            id: expandChevronText
                            text: "" // chevron-down
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
                        width: 26
                        height: 26
                        anchors.verticalCenter: parent.verticalCenter
                        visible: notifCategory !== "battery" // battery has no close button

                        Rectangle {
                            anchors.fill: parent
                            radius: isPill ? 13 : 6
                            color: closeMouse.containsMouse ? Qt.rgba(1, 0.2, 0.2, 0.2) : Qt.rgba(1, 1, 1, 0.05)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            text: "" // close x
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
                                try { if (wrapper.notificationData) wrapper.notificationData.dismiss() } catch(e){}
                            }
                        }
                    }
                }
            }

            // Progress Bar (Update)
            Item {
                width: parent.width
                height: 4
                visible: notifCategory === "update"
                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: Qt.rgba(1,1,1,0.1)
                    Rectangle {
                        width: parent.width * 0.6 // Mock progress 60%
                        height: parent.height
                        radius: 2
                        color: accentColor
                    }
                }
            }

            // Bottom Actions Row (Update, or expanded generic)
            Flow {
                width: parent.width
                spacing: 8
                visible: notifCategory === "update" || (toastCard.expanded && notifCategory !== "music" && notifCategory !== "error")
                
                Repeater {
                    model: wrapper.notificationData ? wrapper.notificationData.actions : null
                    delegate: Rectangle {
                        property bool isFirst: index === 0
                        color: {
                            if (isFirst && notifCategory === "update") return ah.hovered ? Qt.lighter(Theme.colSuccess, 1.1) : Theme.colSuccess;
                            if (isFirst) return ah.hovered ? Qt.lighter(Theme.colPrimary, 1.1) : Theme.colPrimary;
                            return ah.hovered ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.05);
                        }
                        border.color: isFirst ? "transparent" : Qt.rgba(1, 1, 1, 0.1)
                        border.width: isFirst ? 0 : 1
                        radius: 8
                        width: Math.max(100, al.implicitWidth + 24)
                        height: 32
                        
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
