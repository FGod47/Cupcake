import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../theme"

PanelWindow {
    id: notifWindow
    property var modelData
    screen: modelData

    anchors {
        top: true
        right: true
    }

    implicitWidth: 360
    implicitHeight: 750
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region {
        Region { item: notifDetachedPod }
    }

    readonly property real screenW: (screen && screen.width > 0) ? screen.width : 1920
    readonly property real barHeight: Theme.barHeight !== undefined ? Theme.barHeight : 30
    readonly property real topMargin: Math.max(8, Theme.barGap !== undefined ? Theme.barGap : 8)
    readonly property real rightMargin: Math.max(8, topMargin)
    readonly property color fg: Theme.colOnSurface
    property real barOpacity: Theme.barOpacity !== undefined ? Theme.barOpacity : 0.85
    property bool barTransparency: Theme.barTransparency !== undefined ? Theme.barTransparency : true
    property color bg: Theme.colSurfaceContainer
    readonly property color pillColor: Theme.isPitchBlack
        ? (notifWindow.barOpacity < 1.0 ? Qt.rgba(0, 0, 0, notifWindow.barOpacity) : "#000000")
        : (notifWindow.barTransparency ? Qt.rgba(bg.r, bg.g, bg.b, notifWindow.barOpacity) : Qt.rgba(bg.r, bg.g, bg.b, 1.0))
    readonly property real startRadius: Theme.barRadius !== undefined ? Theme.barRadius : 16
    readonly property string fontName: Theme.appFontMono !== "" ? Theme.appFontMono : (globalState ? globalState.tablerIconsFamily : "tabler-icons")

    // Dynamic Island Notification state & Synchronized Multi-Stage Motion
    property var notifPopups: (globalState && globalState.popups) ? globalState.popups : []
    property bool hasNotifPopup: notifPopups.length > 0 && !globalState.hideIsland

    // ── TWO-STAGE CHOREOGRAPHY: YELLOW DOT FADES IN PLACE -> CARD BLOOMS ──
    property real notifDotProgress: 0.0
    property real notifExpandProgress: 0.0
    readonly property real notifProgress: notifExpandProgress

    onNotifProgressChanged: {
        if (globalState) {
            globalState.notifProgress = notifProgress;
        }
    }

    SequentialAnimation {
        id: notifOpenSeq
        running: false
        ScriptAction {
            script: {
                notifCloseSeq.stop();
                notifWindow.notifDotProgress = 0.0;
                notifWindow.notifExpandProgress = 0.0;
            }
        }
        // 1. Yellow dot pill slowly fades and blooms in place
        NumberAnimation {
            target: notifWindow
            property: "notifDotProgress"
            from: 0.0
            to: 1.0
            duration: 900
            easing.type: Easing.OutCubic
        }
        // 2. Deliberate pause so the glowing yellow dot pill is admired
        PauseAnimation { duration: 650 }
        // 3. Fluidly bloom and expand outward into full notification
        NumberAnimation {
            target: notifWindow
            property: "notifExpandProgress"
            from: 0.0
            to: 1.0
            duration: 1100
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]
        }
    }

    SequentialAnimation {
        id: notifCloseSeq
        running: false
        ScriptAction {
            script: {
                notifOpenSeq.stop();
            }
        }
        NumberAnimation {
            target: notifWindow
            property: "notifExpandProgress"
            to: 0.0
            duration: 750
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: notifWindow
            property: "notifDotProgress"
            to: 0.0
            duration: 450
            easing.type: Easing.InQuad
        }
    }

    onHasNotifPopupChanged: {
        if (hasNotifPopup) {
            notifCloseSeq.stop();
            notifOpenSeq.restart();
        } else {
            notifOpenSeq.stop();
            notifCloseSeq.restart();
        }
    }

    visible: notifDotProgress > 0.001

    Item {
        id: notifDetachedPod
        readonly property bool hasNotif: notifWindow.hasNotifPopup
        readonly property var popupsList: notifWindow.notifPopups ? notifWindow.notifPopups : []
        property var cachedPopups: []
        onPopupsListChanged: {
            if (popupsList && popupsList.length > 0) {
                cachedPopups = popupsList;
            }
        }
        readonly property var effectivePopups: {
            let list = (popupsList && popupsList.length > 0) ? popupsList : cachedPopups;
            if (!list || list.length === 0) return [];
            return list.filter(p => p && (
                (p.summary && p.summary.toString().trim().length > 0) ||
                (p.body && p.body.toString().trim().length > 0) ||
                (p.appName && p.appName.toString().trim().length > 0)
            ));
        }
        property bool showAllNotifs: false
        readonly property int cardCount: (effectivePopups.length > 0 && notifWindow.notifDotProgress > 0.01) ? (showAllNotifs ? effectivePopups.length : Math.min(3, effectivePopups.length)) : 0

        readonly property real maxScreenH: (notifWindow.screen && notifWindow.screen.height > 0) ? (notifWindow.screen.height - notifWindow.topMargin - 60) : 700
        readonly property real fullW: 320
        readonly property real minW: notifWindow.barHeight
        readonly property real currentW: minW + (fullW - minW) * notifWindow.notifExpandProgress

        readonly property real footerH: (effectivePopups.length > 3) ? 34 : 0
        readonly property real maxListH: maxScreenH - footerH
        readonly property real targetListH: Math.min(maxListH, notifStackCol.implicitHeight)
        readonly property real targetTotalH: targetListH + ((hasNotif || notifWindow.notifExpandProgress > 0.01) ? footerH : 0)
        readonly property color cardBg: notifWindow.pillColor

        onHasNotifChanged: {
            if (!hasNotif) {
                showAllNotifs = false;
                notifFlickable.contentY = 0;
            }
        }

        width: currentW
        height: (hasNotif || notifWindow.notifExpandProgress > 0.01) ? (notifWindow.barHeight + (targetTotalH - notifWindow.barHeight) * notifWindow.notifExpandProgress) : notifWindow.barHeight
        y: notifWindow.topMargin
        anchors.right: parent.right
        anchors.rightMargin: notifWindow.rightMargin

        opacity: notifWindow.notifDotProgress
        scale: 0.85 + 0.15 * notifWindow.notifDotProgress
        transformOrigin: Item.Right
        visible: notifWindow.notifDotProgress > 0.001
        clip: true

        // 1. SCROLLABLE LIST OF CARDS
        Flickable {
            id: notifFlickable
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: notifDetachedPod.targetListH
            contentWidth: width
            contentHeight: notifStackCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            WheelHandler {
                onWheel: (event) => {
                    let delta = event.angleDelta.y;
                    notifFlickable.contentY = Math.max(0, Math.min(notifFlickable.contentHeight - notifFlickable.height, notifFlickable.contentY - delta));
                }
            }

            // Scrollbar Indicator
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 2
                width: 3
                radius: 1.5
                color: Qt.rgba(notifWindow.fg.r, notifWindow.fg.g, notifWindow.fg.b, 0.4)
                visible: notifFlickable.contentHeight > notifFlickable.height
                y: notifFlickable.contentHeight > notifFlickable.height ? (notifFlickable.contentY * (notifFlickable.height - height) / (notifFlickable.contentHeight - notifFlickable.height)) : 0
                height: notifFlickable.contentHeight > 0 ? Math.max(20, notifFlickable.height * (notifFlickable.height / notifFlickable.contentHeight)) : 20
                opacity: (notifFlickable.moving || notifDetachedPod.showAllNotifs) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // Stack of Notification Cards
            ColumnLayout {
                id: notifStackCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 6

                Repeater {
                    model: notifDetachedPod.cardCount
                    delegate: Rectangle {
                        id: cardItem
                        readonly property int itemIdx: index
                        readonly property var notifData: (notifDetachedPod.effectivePopups && itemIdx < notifDetachedPod.effectivePopups.length) ? notifDetachedPod.effectivePopups[itemIdx] : null
                        readonly property bool isCardHovered: cardMa.containsMouse || dismissCardMa.containsMouse

                        function getCleanAppTag(notif) {
                            if (!notif) return "SYSTEM";
                            let summary = (notif.summary || "").toLowerCase();
                            let body = (notif.body || "").toLowerCase();
                            let app = (notif.appName || "").trim();
                            if (summary.includes("screenshot") || body.includes("/screenshot/")) return "SCREENSHOT";
                            if (app.toLowerCase() === "notify-send" || app === "") return "SYSTEM";
                            return app.toUpperCase();
                        }

                        function getCompactPreview(notif) {
                            if (!notif) return "";
                            let summary = (notif.summary || "").replace(/[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{2600}-\u{27BF}]/gu, '').trim();
                            let body = (notif.body || "").replace(/[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{2600}-\u{27BF}]/gu, '').trim();
                            let app = (notif.appName || "").toLowerCase();

                            // 1. File paths (e.g. screenshots / downloads / images) -> show clean filename only
                            if (body.startsWith("/") || body.includes("/Screenshot/") || body.includes("/Pictures/") || body.includes("/Downloads/")) {
                                let parts = body.split('/');
                                let filename = parts[parts.length - 1] || "";
                                if (filename.length > 0) {
                                    return "Saved • " + filename;
                                }
                            }

                            // 2. Chat / Messenger (e.g. Alex: "Are we still meeting for coffee?")
                            if (body && summary && body !== summary) {
                                if (["telegram", "discord", "slack", "signal", "whatsapp", "messages"].indexOf(app) !== -1 || summary.length <= 18) {
                                    return summary + ": " + body;
                                }
                                return summary + " • " + body;
                            }

                            return summary || body || (app ? (app.charAt(0).toUpperCase() + app.slice(1)) : "Notification");
                        }

                        function getExpandedHeading(notif) {
                            if (!notif) return "";
                            let summary = (notif.summary || "").replace(/[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{2600}-\u{27BF}]/gu, '').trim();
                            let body = (notif.body || "").replace(/[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{2600}-\u{27BF}]/gu, '').trim();
                            if (summary.toLowerCase().includes("screenshot") || body.includes("/Screenshot/")) {
                                return "Screenshot Saved";
                            }
                            return summary || "Notification";
                        }

                        function getLocationDir(notif) {
                            if (!notif) return "";
                            let body = (notif.body || "").replace(/[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{2600}-\u{27BF}]/gu, '').trim();
                            if (body.startsWith("/") && (body.includes(".png") || body.includes(".jpg") || body.includes(".jpeg"))) {
                                let lastSlash = body.lastIndexOf('/');
                                let dir = body.substring(0, lastSlash);
                                return dir ? (dir + "/") : "";
                            }
                            return "";
                        }

                        function getFilename(notif) {
                            if (!notif) return "";
                            let body = (notif.body || "").replace(/[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{2600}-\u{27BF}]/gu, '').trim();
                            if (body.startsWith("/") && (body.includes(".png") || body.includes(".jpg") || body.includes(".jpeg"))) {
                                let parts = body.split('/');
                                return parts[parts.length - 1] || body;
                            }
                            return "";
                        }

                        function getRegularBody(notif) {
                            if (!notif) return "";
                            let body = (notif.body || "").replace(/[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{2600}-\u{27BF}]/gu, '').trim();
                            let summary = (notif.summary || "").replace(/[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{2600}-\u{27BF}]/gu, '').trim();
                            if (body === summary) return "";
                            return body;
                        }
                        
                        Layout.fillWidth: true
                        Layout.preferredHeight: isCardHovered ? (notifWindow.barHeight + expandedDetailsCol.implicitHeight + 14) : notifWindow.barHeight
                        implicitHeight: Layout.preferredHeight
                        radius: notifWindow.notifExpandProgress > 0.6 ? (isCardHovered ? 15 : notifWindow.startRadius) : (notifWindow.barHeight / 2)
                        color: notifDetachedPod.cardBg
                        border.width: isCardHovered ? 1 : 0
                        border.color: isCardHovered ? Qt.rgba(notifWindow.fg.r, notifWindow.fg.g, notifWindow.fg.b, 0.25) : "transparent"
                        clip: true
                        opacity: 1.0

                        Behavior on Layout.preferredHeight {
                            NumberAnimation {
                                duration: 720
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]
                            }
                        }
                        Behavior on radius { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        Behavior on border.color { ColorAnimation { duration: 250 } }

                        // 1. Header & Controls Row (Clean RowLayout with fixed full width for instant unmasking!)
                        RowLayout {
                            id: headerRow
                            anchors.left: parent.left
                            anchors.top: parent.top
                            width: notifDetachedPod.fullW - 26
                            height: notifWindow.barHeight
                            anchors.leftMargin: Math.round(13 * notifWindow.notifExpandProgress + ((notifWindow.barHeight - 6) / 2) * (1.0 - notifWindow.notifExpandProgress))
                            spacing: 8

                            Item {
                                width: 6
                                height: 6
                                Layout.alignment: Qt.AlignVCenter

                                // Ambient golden halo glow during float-up
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: (cardItem.notifData && cardItem.notifData.urgency === 2) ? "#E06C75" : "#E5C07B"
                                    opacity: Math.max(0.0, (1.0 - notifWindow.notifExpandProgress) * 0.45 * notifWindow.notifDotProgress)
                                    scale: 0.8 + 0.4 * notifWindow.notifDotProgress
                                }

                                // Crisp indicator dot
                                Rectangle {
                                    id: urgencyDot
                                    anchors.centerIn: parent
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: (cardItem.notifData && cardItem.notifData.urgency === 2) ? "#E06C75" : "#E5C07B"
                                    scale: 0.6 + 0.4 * notifWindow.notifDotProgress
                                }
                            }

                            Text {
                                id: notifAppTag
                                text: cardItem.getCleanAppTag(cardItem.notifData)
                                font.family: Theme.appFontMono
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.4
                                color: Qt.rgba(notifWindow.fg.r, notifWindow.fg.g, notifWindow.fg.b, 0.55)
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Compact Preview Text (Saved • 08-16-09-27-43.png)
                            Text {
                                id: inlinePreviewText
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: cardItem.getCompactPreview(cardItem.notifData)
                                font.family: Theme.appFontMono
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: notifWindow.fg
                                elide: Text.ElideRight
                                opacity: cardItem.isCardHovered ? 0.0 : 1.0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            // Circle Countdown Timer Ring
                            Shape {
                                width: 14
                                height: 14
                                Layout.alignment: Qt.AlignVCenter
                                layer.enabled: true
                                layer.samples: 4
                                opacity: cardItem.isCardHovered ? 0.35 : 0.9
                                Behavior on opacity { NumberAnimation { duration: 150 } }

                                ShapePath {
                                    strokeColor: Qt.rgba(notifWindow.fg.r, notifWindow.fg.g, notifWindow.fg.b, 0.15)
                                    strokeWidth: 1.5
                                    fillColor: "transparent"
                                    capStyle: ShapePath.RoundCap

                                    PathAngleArc {
                                        centerX: 7
                                        centerY: 7
                                        radiusX: 5
                                        radiusY: 5
                                        startAngle: 0
                                        sweepAngle: 360
                                    }
                                }

                                ShapePath {
                                    strokeColor: (cardItem.notifData && cardItem.notifData.urgency === 2) ? "#E06C75" : Theme.colPrimary
                                    strokeWidth: 1.5
                                    fillColor: "transparent"
                                    capStyle: ShapePath.RoundCap

                                    PathAngleArc {
                                        centerX: 7
                                        centerY: 7
                                        radiusX: 5
                                        radiusY: 5
                                        startAngle: -90
                                        sweepAngle: -360 * cardItem.timerProgress
                                    }
                                }
                            }

                            // Dismiss button (✕)
                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                color: dismissCardMa.containsMouse ? Qt.rgba(notifWindow.fg.r, notifWindow.fg.g, notifWindow.fg.b, 0.16) : "transparent"
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "\ueb55"
                                    font.family: notifWindow.fontName
                                    font.pixelSize: 9
                                    color: Qt.rgba(notifWindow.fg.r, notifWindow.fg.g, notifWindow.fg.b, 0.5)
                                }

                                MouseArea {
                                    id: dismissCardMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        try {
                                            if (cardItem.notifData && typeof cardItem.notifData.dismiss === "function") cardItem.notifData.dismiss();
                                        } catch (e) {}
                                        let curList = notifDetachedPod.popupsList.slice();
                                        curList.splice(cardItem.itemIdx, 1);
                                        if (globalState) globalState.popups = curList;
                                    }
                                }
                            }
                        }

                        // 2. Expanded Details Section (Smooth downward reveal on hover, pristine collapse!)
                        ColumnLayout {
                            id: expandedDetailsCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: headerRow.bottom
                            anchors.leftMargin: 13
                            anchors.rightMargin: 13
                            anchors.topMargin: 2
                            spacing: 6
                            visible: opacity > 0.01
                            opacity: cardItem.isCardHovered ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                            // Category Heading (e.g. "Screenshot Saved" or Notification Title)
                            Text {
                                text: cardItem.getExpandedHeading(cardItem.notifData)
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: notifWindow.fg
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            // Secondary Directory / Subtitle (e.g. "~/Pictures/Screenshot/")
                            Text {
                                text: cardItem.getLocationDir(cardItem.notifData)
                                font.family: Theme.appFontMono
                                font.pixelSize: 10
                                font.weight: Font.Normal
                                color: Qt.rgba(notifWindow.fg.r, notifWindow.fg.g, notifWindow.fg.b, 0.55)
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                visible: text.length > 0
                            }

                            // Filename or Description Body (e.g. "08-16-09-27-43.png")
                            Text {
                                text: cardItem.getFilename(cardItem.notifData) || cardItem.getRegularBody(cardItem.notifData)
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 11
                                font.weight: Font.Normal
                                color: Qt.rgba(notifWindow.fg.r, notifWindow.fg.g, notifWindow.fg.b, 0.8)
                                Layout.fillWidth: true
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                visible: text.length > 0
                            }

                            // Interactive Action Buttons Row (if notification has native actions)
                            RowLayout {
                                id: actionsRow
                                Layout.fillWidth: true
                                Layout.topMargin: 4
                                spacing: 8
                                visible: !!(cardItem.notifData && cardItem.notifData.actions && cardItem.notifData.actions.length > 0)

                                Repeater {
                                    model: (cardItem.notifData && cardItem.notifData.actions) ? cardItem.notifData.actions : []
                                    delegate: Rectangle {
                                        id: actionBtn
                                        required property var modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        height: 24
                                        radius: 6
                                        color: actionBtnMa.containsMouse ? Qt.rgba(notifWindow.fg.r, notifWindow.fg.g, notifWindow.fg.b, 0.18) : Qt.rgba(notifWindow.fg.r, notifWindow.fg.g, notifWindow.fg.b, 0.08)
                                        border.width: 1
                                        border.color: Qt.rgba(notifWindow.fg.r, notifWindow.fg.g, notifWindow.fg.b, 0.12)
                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: actionBtn.modelData.text || actionBtn.modelData.identifier || "Action"
                                            font.family: Theme.defaultFontFamily
                                            font.pixelSize: 10
                                            font.weight: Font.Medium
                                            color: notifWindow.fg
                                            elide: Text.ElideRight
                                            width: parent.width - 8
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        MouseArea {
                                            id: actionBtnMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (actionBtn.modelData && actionBtn.modelData.invoke) {
                                                    actionBtn.modelData.invoke();
                                                }
                                                try { if (cardItem.notifData && typeof cardItem.notifData.dismiss === "function") cardItem.notifData.dismiss(); } catch(e){}
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // MouseArea for card hover & click action
                        MouseArea {
                            id: cardMa
                            anchors.fill: parent
                            hoverEnabled: true
                            z: -1
                            onClicked: {
                                if (cardItem.notifData) {
                                    if (cardItem.notifData.defaultAction) {
                                        cardItem.notifData.defaultAction.invoke();
                                    }
                                    try { if (typeof cardItem.notifData.dismiss === "function") cardItem.notifData.dismiss(); } catch(e){}
                                }
                            }
                        }

                        // Local countdown timer
                        property real timerProgress: 1.0
                        Timer {
                            id: cardCountdownTimer
                            interval: 50
                            running: notifDetachedPod.hasNotif && !cardItem.isCardHovered
                            repeat: true
                            onTriggered: {
                                let totalMs = (cardItem.notifData && cardItem.notifData.timeout > 0) ? cardItem.notifData.timeout : 7000;
                                cardItem.timerProgress = Math.max(0.0, cardItem.timerProgress - (50 / totalMs));
                                if (cardItem.timerProgress <= 0.001) {
                                    cardCountdownTimer.stop();
                                    try { if (cardItem.notifData && typeof cardItem.notifData.dismiss === "function") cardItem.notifData.dismiss(); } catch(e){}
                                }
                            }
                        }
                    }
                }
            }
        }

        // 2. FOOTER ROW (Shown when more than 3 notifications are queued)
        Rectangle {
            id: notifFooter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: notifDetachedPod.footerH
            visible: notifDetachedPod.footerH > 0 && notifWindow.notifExpandProgress > 0.5
            color: "transparent"
            clip: true

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                height: 1
                color: Qt.rgba(notifWindow.fg.r, notifWindow.fg.g, notifWindow.fg.b, 0.10)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14

                Text {
                    text: notifDetachedPod.showAllNotifs ? "Show Less" : ("+ " + (notifDetachedPod.effectivePopups.length - 3) + " more")
                    font.family: Theme.appFontMono
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    color: Qt.rgba(notifWindow.fg.r, notifWindow.fg.g, notifWindow.fg.b, 0.6)
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 52
                    height: 20
                    radius: 10
                    color: clearAllMa.containsMouse ? Qt.rgba(notifWindow.fg.r, notifWindow.fg.g, notifWindow.fg.b, 0.15) : "transparent"
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: "Clear"
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 10
                        color: Qt.rgba(notifWindow.fg.r, notifWindow.fg.g, notifWindow.fg.b, 0.6)
                    }

                    MouseArea {
                        id: clearAllMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            for (let i = 0; i < notifDetachedPod.effectivePopups.length; i++) {
                                try { if (notifDetachedPod.effectivePopups[i] && typeof notifDetachedPod.effectivePopups[i].dismiss === "function") notifDetachedPod.effectivePopups[i].dismiss(); } catch(e){}
                            }
                            if (globalState) globalState.popups = [];
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: {
                    notifDetachedPod.showAllNotifs = !notifDetachedPod.showAllNotifs;
                }
            }
        }
    }
}
