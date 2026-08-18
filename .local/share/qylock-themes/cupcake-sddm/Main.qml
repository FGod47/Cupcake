import QtQuick
import QtQuick.Controls
import SddmComponents 2.0
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#121214"
    focus: true

    property int cfgClockBlurRadius: (config && config.clockBlurRadius !== undefined && config.clockBlurRadius !== "") ? parseInt(config.clockBlurRadius) : 48
    property int cfgBgBlurRadius: (config && config.blurRadius !== undefined && config.blurRadius !== "") ? parseInt(config.blurRadius) : 42
    property real cfgGlassSheen: (config && config.glassSheen !== undefined && config.glassSheen !== "") ? (parseFloat(config.glassSheen) / 100.0) : 0.48
    property int cfgClockFontSize: (config && config.clockFontSize !== undefined && config.clockFontSize !== "") ? parseInt(config.clockFontSize) : 124
    property bool cfgShowDate: (config && config.showDate !== undefined) ? (config.showDate === "true" || config.showDate === true) : true
    property bool cfgShowSession: (config && config.showSession !== undefined) ? (config.showSession === "true" || config.showSession === true) : true
    property bool cfgShowPower: (config && config.showPower !== undefined) ? (config.showPower === "true" || config.showPower === true) : true
    property bool cfgShowAvatar: (config && config.showAvatar !== undefined) ? (config.showAvatar === "true" || config.showAvatar === true) : true
    property bool cfgShowNotifications: (config && config.showNotifications !== undefined) ? (config.showNotifications === "true" || config.showNotifications === true) : true
    property bool cfgTime24h: (config && config.timeFormat24h !== undefined) ? (config.timeFormat24h === "true" || config.timeFormat24h === true) : false

    FontLoader {
        id: astronautClockFont
        source: "fonts/" + ((config && config.clockFont && config.clockFont !== "") ? config.clockFont : "OpenSans-ExtraBold.ttf")
    }

    property string fontName: "Open Sans, Inter, sans-serif"
    property string clockFontFamily: astronautClockFont.name || "Open Sans"
    property color textColor: "#ffffff"
    property bool isLoginPromptVisible: false

    property int currentUsersIndex: (userModel && userModel.lastIndex !== undefined) ? userModel.lastIndex : 0
    property int currentSessionsIndex: (sessionModel && sessionModel.lastIndex !== undefined) ? sessionModel.lastIndex : 0
    property int usernameRole: Qt.UserRole + 1
    property int realNameRole: Qt.UserRole + 2
    property int sessionNameRole: Qt.UserRole + 4

    property string currentUsername: (userModel && userModel.count > 0) ? (userModel.data(userModel.index(currentUsersIndex, 0), usernameRole) || "zero") : "zero"
    property string currentRealName: (userModel && userModel.count > 0) ? (userModel.data(userModel.index(currentUsersIndex, 0), realNameRole) || currentUsername) : "Zero"
    property string currentSession: (sessionModel && sessionModel.rowCount() > 0) ? (sessionModel.data(sessionModel.index(currentSessionsIndex, 0), sessionNameRole) || "Hyprland") : "Hyprland"

    function sessionsCycleSelectNext() {
        if (!sessionModel || sessionModel.rowCount() === 0) return;
        if (currentSessionsIndex >= sessionModel.rowCount() - 1) { currentSessionsIndex = 0; }
        else { currentSessionsIndex++; }
    }

    function usersCycleSelectNext() {
        if (!userModel || userModel.count === 0) return;
        if (currentUsersIndex >= userModel.count - 1) { currentUsersIndex = 0; }
        else { currentUsersIndex++; }
    }

    function showLoginPrompt() {
        isLoginPromptVisible = true;
        passwordInput.forceActiveFocus();
    }

    function hideLoginPrompt() {
        isLoginPromptVisible = false;
        passwordInput.text = "";
        root.forceActiveFocus();
    }

    Keys.onPressed: (event) => {
        if (!isLoginPromptVisible) {
            if (event.key === Qt.Key_Up || event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                showLoginPrompt();
                event.accepted = true;
            }
        } else {
            if (event.key === Qt.Key_Escape || (event.key === Qt.Key_Down && passwordInput.text === "")) {
                hideLoginPrompt();
                event.accepted = true;
            }
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            passwordInput.text = "";
            passwordContainer.border.color = "#ff5555";
            failAnimation.restart();
        }
        function onLoginSucceeded() { }
    }

    // ── 1. BACKGROUND WALLPAPER (With Smooth Dynamic FastBlur) ─────────────
    Item {
        id: bgContainer
        anchors.fill: parent

        Image {
            id: bgImage
            anchors.fill: parent
            source: config.background || "background.png"
            smooth: true
            fillMode: Image.PreserveAspectCrop
        }

        FastBlur {
            id: bgBlur
            anchors.fill: bgImage
            source: bgImage
            radius: root.isLoginPromptVisible ? root.cfgBgBlurRadius : 0
            cached: true
            Behavior on radius { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
        }

        // Dark dim overlay on blur
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.isLoginPromptVisible ? 0.38 : 0.0
            Behavior on opacity { NumberAnimation { duration: 380 } }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (!root.isLoginPromptVisible) {
                    root.showLoginPrompt();
                } else {
                    root.hideLoginPrompt();
                }
            }
        }
    }

    // ── 2. TOP RIGHT CONTROLS (Session & Layout) ────────────────────────
    Row {
        z: 10
        anchors.top: parent.top
        anchors.topMargin: 24
        anchors.right: parent.right
        anchors.rightMargin: 36
        spacing: 12
        visible: root.cfgShowSession && !(sddm && sddm.isLockScreen === true)

        // Frosted Glass Session Pill (e.g. Hyprland)
        Item {
            id: sessionPill
            height: 32
            width: sessionRow.implicitWidth + 26

            // Frosted Glass Blurred Layer
            Item {
                anchors.fill: parent
                layer.enabled: true
                layer.effect: OpacityMask { maskSource: sessionMask }

                Image {
                    width: root.width
                    height: root.height
                    x: -(root.width - sessionPill.width - 36)
                    y: -24
                    source: bgImage.source
                    fillMode: Image.PreserveAspectCrop
                    smooth: true

                    layer.enabled: true
                    layer.effect: FastBlur {
                        radius: 36
                        cached: true
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: sessionMa.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.12)
                    border.width: 1.5
                    border.color: sessionMa.containsMouse ? Qt.rgba(1, 1, 1, 0.70) : Qt.rgba(1, 1, 1, 0.38)
                    radius: 16
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                }
            }

            Rectangle {
                id: sessionMask
                anchors.fill: parent
                radius: 16
                visible: false
            }

            Row {
                id: sessionRow
                anchors.centerIn: parent
                spacing: 6

                Image {
                    source: "data:image/svg+xml;utf8,<svg width='14' height='14' viewBox='0 0 24 24' fill='none' stroke='white' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><rect x='2' y='3' width='20' height='14' rx='2' ry='2'></rect><line x1='8' y1='21' x2='16' y2='21'></line><line x1='12' y1='17' x2='12' y2='21'></line></svg>"
                    width: 14
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: 0.9
                }

                Text {
                    text: currentSession
                    color: "#ffffff"
                    font.family: fontName
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: 0.95
                }
            }

            MouseArea {
                id: sessionMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sessionsCycleSelectNext()
            }
        }
    }

    function getDisplayTime() {
        let d = new Date();
        if (root.cfgTime24h) {
            let h = d.getHours();
            let m = d.getMinutes();
            return (h < 10 ? "0" + h : h) + ":" + (m < 10 ? "0" + m : m);
        } else {
            let hours = d.getHours();
            let minutes = d.getMinutes();
            let h12 = hours % 12 || 12;
            let mStr = minutes < 10 ? ("0" + minutes) : minutes;
            return h12 + ":" + mStr;
        }
    }

    // ── 4. LOCKSCREEN DATE & CLOCK ──────────────────────────────────────
    // ── 4. LOCKSCREEN DATE & CLOCK (Frosted Glass Masked Typography) ───
    Item {
        id: clockSection
        z: 8
        anchors.top: parent.top
        anchors.topMargin: root.isLoginPromptVisible ? (parent.height * 0.065) : (parent.height * 0.09)
        Behavior on anchors.topMargin { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: parent.width * 0.02
        width: 420
        height: 180

        Column {
            id: clockColumn
            anchors.centerIn: parent
            spacing: -6

            // True Frosted Glass Blurred Date ("Thu May 7")
            Item {
                id: glassDateContainer
                visible: root.cfgShowDate
                width: dateMaskText.implicitWidth
                height: dateMaskText.implicitHeight
                anchors.horizontalCenter: parent.horizontalCenter

                Item {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.effect: OpacityMask { maskSource: dateMaskText }

                    // 1. Pixel-aligned blurred wallpaper layer
                    Image {
                        width: root.width
                        height: root.height
                        x: -( (root.width - glassDateContainer.width)/2 + (root.width * 0.02) )
                        y: -( clockSection.y + clockColumn.y + glassDateContainer.y )
                        source: bgImage.source
                        fillMode: Image.PreserveAspectCrop
                        smooth: true

                        layer.enabled: true
                        layer.effect: FastBlur {
                            radius: root.cfgClockBlurRadius
                            cached: true
                        }
                    }

                    // 2. Frosted milky specular glass gradient
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.cfgGlassSheen * 1.1) }
                            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, root.cfgGlassSheen * 0.45) }
                            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, root.cfgGlassSheen * 0.75) }
                        }
                    }
                }

                // 3. Alpha Mask Source
                Text {
                    id: dateMaskText
                    anchors.centerIn: parent
                    text: Qt.formatDate(new Date(), "ddd MMM d")
                    font.family: root.clockFontFamily
                    font.pixelSize: Math.round(root.cfgClockFontSize * 0.20)
                    font.weight: Font.Bold
                    font.bold: true
                    font.letterSpacing: 0.5
                    color: "#ffffff"
                    visible: false
                }

                // 4. Clean Specular Overlay
                Text {
                    id: dateLabel
                    anchors.centerIn: parent
                    text: Qt.formatDate(new Date(), "ddd MMM d")
                    font.family: root.clockFontFamily
                    font.pixelSize: Math.round(root.cfgClockFontSize * 0.20)
                    font.weight: Font.Bold
                    font.bold: true
                    font.letterSpacing: 0.5
                    color: Qt.rgba(1, 1, 1, 0.15)
                }
            }

            // True Frosted Glass Blurred Clock
            Item {
                id: glassClockContainer
                width: timeMaskText.implicitWidth
                height: timeMaskText.implicitHeight
                anchors.horizontalCenter: parent.horizontalCenter

                Item {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.effect: OpacityMask { maskSource: timeMaskText }

                    // 1. Pixel-aligned blurred wallpaper layer
                    Image {
                        id: clockBlurBg
                        width: root.width
                        height: root.height
                        x: -( (root.width - glassClockContainer.width)/2 + (root.width * 0.02) )
                        y: -( clockSection.y + clockColumn.y + glassClockContainer.y )
                        source: bgImage.source
                        fillMode: Image.PreserveAspectCrop
                        smooth: true

                        layer.enabled: true
                        layer.effect: FastBlur {
                            radius: root.cfgClockBlurRadius
                            cached: true
                        }
                    }

                    // 2. Frosted milky specular glass gradient
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.cfgGlassSheen) }
                            GradientStop { position: 0.4; color: Qt.rgba(1, 1, 1, root.cfgGlassSheen * 0.38) }
                            GradientStop { position: 0.8; color: Qt.rgba(1, 1, 1, root.cfgGlassSheen * 0.25) }
                            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, root.cfgGlassSheen * 0.65) }
                        }
                    }
                }

                // 3. Alpha Mask Source
                Text {
                    id: timeMaskText
                    anchors.centerIn: parent
                    text: root.getDisplayTime()
                    font.family: root.clockFontFamily
                    font.pixelSize: root.cfgClockFontSize
                    font.weight: Font.ExtraBold
                    font.bold: true
                    font.letterSpacing: -2.0
                    color: "#ffffff"
                    visible: false
                }

                // 4. Clean Specular Overlay
                Text {
                    id: timeLabel
                    anchors.centerIn: parent
                    text: root.getDisplayTime()
                    font.family: root.clockFontFamily
                    font.pixelSize: root.cfgClockFontSize
                    font.weight: Font.ExtraBold
                    font.bold: true
                    font.letterSpacing: -2.0
                    color: Qt.rgba(1, 1, 1, 0.12)
                }
            }
        }
    }

    // ── 5. USER PROFILE & INTERACTIVE SLIDE-UP LOGIN SECTION ────────────
    Item {
        id: userLoginSection
        z: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.isLoginPromptVisible ? (parent.height * 0.12) : (parent.height * 0.065)
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: parent.width * 0.02
        width: 260
        height: 150

        Column {
            id: loginColumn
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12
            width: parent.width

            // ── Frosted Glass Notifications Pod (Above Avatar) ──
            Item {
                id: notifPodContainer
                visible: root.cfgShowNotifications && (typeof notificationModel !== "undefined" && notificationModel && notificationModel.count > 0) && !root.isLoginPromptVisible
                width: 320
                height: visible ? (Math.min(notificationModel.count, 2) * 58 + ((Math.min(notificationModel.count, 2) - 1) * 6)) : 0
                anchors.horizontalCenter: parent.horizontalCenter
                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 250 } }
                clip: true

                Column {
                    anchors.fill: parent
                    spacing: 6

                    Repeater {
                        model: (typeof notificationModel !== "undefined" && notificationModel) ? Math.min(notificationModel.count, 2) : 0
                        delegate: Item {
                            id: notifItem
                            width: notifPodContainer.width
                            height: 58

                            // 1. Frosted Glass Blurred Layer
                            Item {
                                anchors.fill: parent
                                layer.enabled: true
                                layer.effect: OpacityMask { maskSource: notifMask }

                                Image {
                                    width: root.width
                                    height: root.height
                                    x: -( (root.width - notifPodContainer.width)/2 + (root.width * 0.02) )
                                    y: -( userLoginSection.y + loginColumn.y + notifPodContainer.y + notifItem.y )
                                    source: bgImage.source
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true

                                    layer.enabled: true
                                    layer.effect: FastBlur {
                                        radius: root.cfgClockBlurRadius
                                        cached: true
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    gradient: Gradient {
                                        orientation: Gradient.Vertical
                                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.cfgGlassSheen * 0.45) }
                                        GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, root.cfgGlassSheen * 0.18) }
                                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, root.cfgGlassSheen * 0.32) }
                                    }
                                    border.width: 1.5
                                    border.color: notifHoverArea.containsMouse ? Qt.rgba(1, 1, 1, 0.70) : Qt.rgba(1, 1, 1, 0.35)
                                    radius: 16
                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                }
                            }

                            Rectangle {
                                id: notifMask
                                anchors.fill: parent
                                radius: 16
                                visible: false
                            }

                            // 2. Notification Content
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                // App Icon / Category Disc
                                Rectangle {
                                    width: 34; height: 34; radius: 17
                                    color: Qt.rgba(1, 1, 1, 0.18)
                                    border.width: 1; border.color: Qt.rgba(255, 255, 255, 0.3)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "\uea35"
                                        font.family: "tabler-icons"
                                        font.pixelSize: 16
                                        color: "#ffffff"
                                    }
                                }

                                // Text Stack (Title + Snippet)
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: (notificationModel && notificationModel.get(index)) ? (notificationModel.get(index).summary || notificationModel.get(index).appName || "Notification") : "Notification"
                                            font.family: root.fontName
                                            font.pixelSize: 12
                                            font.weight: Font.Bold
                                            color: "#ffffff"
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: (notificationModel && notificationModel.get(index) && notificationModel.get(index).timeStr) ? notificationModel.get(index).timeStr : "now"
                                            font.family: root.fontName
                                            font.pixelSize: 10
                                            color: Qt.rgba(1, 1, 1, 0.65)
                                        }
                                    }

                                    Text {
                                        text: (notificationModel && notificationModel.get(index)) ? (notificationModel.get(index).body || "") : ""
                                        font.family: root.fontName
                                        font.pixelSize: 11
                                        color: Qt.rgba(1, 1, 1, 0.85)
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        maximumLineCount: 1
                                    }
                                }
                            }

                            MouseArea {
                                id: notifHoverArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!root.isLoginPromptVisible) root.showLoginPrompt();
                                }
                            }
                        }
                    }
                }
            }

            // User Avatar
            Rectangle {
                id: avatarCircle
                visible: root.cfgShowAvatar
                width: 58
                height: 58
                radius: 29
                color: "#25000000"
                border.width: 2.0
                border.color: avatarMa.containsMouse ? "#ffffff" : Qt.rgba(1, 1, 1, 0.60)
                anchors.horizontalCenter: parent.horizontalCenter
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Rectangle {
                    id: avatarMask
                    anchors.fill: parent
                    radius: 29
                    visible: false
                }

                Item {
                    anchors.fill: parent
                    anchors.margins: 1.5
                    layer.enabled: true
                    layer.effect: OpacityMask { maskSource: avatarMask }

                    Image {
                        id: avatarImg
                        anchors.fill: parent
                        source: "avatar.png"
                        smooth: true
                        fillMode: Image.PreserveAspectCrop
                    }
                }

                MouseArea {
                    id: avatarMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!root.isLoginPromptVisible) {
                            root.showLoginPrompt();
                        } else {
                            usersCycleSelectNext();
                        }
                    }
                }
            }

            // User Name Label
            Text {
                id: userNameLabel
                text: currentRealName
                color: "#ffffff"
                font.family: fontName
                font.pixelSize: 13
                font.weight: Font.DemiBold
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: 0.95

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!root.isLoginPromptVisible) {
                            root.showLoginPrompt();
                        } else {
                            usersCycleSelectNext();
                        }
                    }
                }
            }

            // Fixed-Height Action Slot (Smooth Cross-Fade & Float)
            Item {
                id: actionSlot
                anchors.horizontalCenter: parent.horizontalCenter
                width: 190
                height: 34

                // Resting State: Swipe Up / Press Enter Hint
                Item {
                    id: unlockHint
                    anchors.fill: parent
                    opacity: root.isLoginPromptVisible ? 0.0 : 0.85
                    y: root.isLoginPromptVisible ? -8 : 0
                    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        // Up Arrow Icon
                        Image {
                            source: "data:image/svg+xml;utf8,<svg width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='white' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'><polyline points='18 15 12 9 6 15'></polyline></svg>"
                            width: 16
                            height: 16
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: hintMa.containsMouse ? 1.0 : 0.75
                        }

                        Text {
                            text: "Swipe up or press Enter"
                            font.family: fontName
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: "#ffffff"
                            opacity: hintMa.containsMouse ? 0.95 : 0.65
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    MouseArea {
                        id: hintMa
                        anchors.fill: parent
                        enabled: !root.isLoginPromptVisible
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showLoginPrompt()
                    }
                }

                // Active State: Frosted Glass Pill Password Input Field
                Item {
                    id: passwordContainer
                    anchors.fill: parent
                    opacity: root.isLoginPromptVisible ? 1.0 : 0.0
                    y: root.isLoginPromptVisible ? 0 : 8
                    scale: root.isLoginPromptVisible ? 1.0 : 0.92
                    Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

                    // Frosted Glass Blur Layer
                    Item {
                        anchors.fill: parent
                        layer.enabled: true
                        layer.effect: OpacityMask { maskSource: passPillMask }

                        Image {
                            width: root.width
                            height: root.height
                            x: -( (root.width - 190)/2 + (root.width * 0.02) )
                            y: -( root.height - (root.isLoginPromptVisible ? (root.height * 0.12) : (root.height * 0.065)) - 34 )
                            source: bgImage.source
                            fillMode: Image.PreserveAspectCrop
                            smooth: true

                            layer.enabled: true
                            layer.effect: FastBlur {
                                radius: 42
                                cached: true
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: passwordInput.activeFocus ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.12)
                            border.width: 1.5
                            border.color: passwordInput.activeFocus ? Qt.rgba(1, 1, 1, 0.85) : Qt.rgba(1, 1, 1, 0.42)
                            radius: 17
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                        }
                    }

                    Rectangle {
                        id: passPillMask
                        anchors.fill: parent
                        radius: 17
                        visible: false
                    }

                    SequentialAnimation {
                        id: failAnimation
                        NumberAnimation { target: passwordContainer; property: "anchors.horizontalCenterOffset"; from: 0; to: -10; duration: 45; easing.type: Easing.OutQuad }
                        NumberAnimation { target: passwordContainer; property: "anchors.horizontalCenterOffset"; to: 10; duration: 45; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: passwordContainer; property: "anchors.horizontalCenterOffset"; to: -8; duration: 45; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: passwordContainer; property: "anchors.horizontalCenterOffset"; to: 8; duration: 45; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: passwordContainer; property: "anchors.horizontalCenterOffset"; to: 0; duration: 45; easing.type: Easing.OutQuad }
                        ColorAnimation { target: passwordContainer; property: "border.color"; from: "#ff5555"; to: "#30ffffff"; duration: 600 }
                    }

                    // Invisible TextInput handling physical keyboard input
                    TextInput {
                        id: passwordInput
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        verticalAlignment: TextInput.AlignVCenter
                        horizontalAlignment: TextInput.AlignHCenter
                        font.family: fontName
                        font.pixelSize: 13
                        color: "transparent"
                        echoMode: TextInput.Normal
                        cursorVisible: false
                        clip: true
                        enabled: root.isLoginPromptVisible

                        onAccepted: {
                            if (text !== "") {
                                sddm.login(currentUsername, text, currentSessionsIndex);
                            }
                        }
                    }

                    // Placeholder text when empty
                    Text {
                        id: placeholderText
                        text: "Enter Password"
                        anchors.centerIn: parent
                        color: "#90ffffff"
                        font.family: fontName
                        font.pixelSize: 11
                        font.weight: Font.Normal
                        visible: passwordInput.text === "" && root.isLoginPromptVisible
                    }

                    // Dynamic Animated Pop-In Password Dots
                    Row {
                        id: dotsRow
                        anchors.centerIn: parent
                        spacing: 7
                        visible: passwordInput.text.length > 0 && root.isLoginPromptVisible

                        Repeater {
                            model: passwordInput.text.length

                            delegate: Rectangle {
                                id: passDot
                                width: 8
                                height: 8
                                radius: 4
                                color: "#ffffff"

                                Component.onCompleted: dotSpringAnim.restart()

                                SequentialAnimation {
                                    id: dotSpringAnim
                                    NumberAnimation {
                                        target: passDot
                                        property: "scale"
                                        from: 0.1
                                        to: 1.35
                                        duration: 110
                                        easing.type: Easing.OutQuad
                                    }
                                    NumberAnimation {
                                        target: passDot
                                        property: "scale"
                                        to: 1.0
                                        duration: 90
                                        easing.type: Easing.InOutQuad
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.isLoginPromptVisible
                        cursorShape: Qt.IBeamCursor
                        onClicked: passwordInput.forceActiveFocus()
                    }
                }
            }
        }
    }

    // ── 6. BOTTOM RIGHT POWER CONTROLS ───────────────────────────────────
    Row {
        id: powerControlsRow
        z: 10
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        anchors.right: parent.right
        anchors.rightMargin: 36
        spacing: 12
        visible: root.cfgShowPower && !(sddm && sddm.isLockScreen === true)

        // Frosted Glass Reboot Button
        Item {
            id: rebootBtn
            width: 38
            height: 38

            Item {
                anchors.fill: parent
                layer.enabled: true
                layer.effect: OpacityMask { maskSource: rebootMask }

                Image {
                    width: root.width
                    height: root.height
                    x: -(root.width - 36 - 38 - 12 - 38)
                    y: -(root.height - 28 - 38)
                    source: bgImage.source
                    fillMode: Image.PreserveAspectCrop
                    smooth: true

                    layer.enabled: true
                    layer.effect: FastBlur {
                        radius: 36
                        cached: true
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: rebootMa.containsMouse ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(1, 1, 1, 0.12)
                    border.width: 1.5
                    border.color: rebootMa.containsMouse ? Qt.rgba(1, 1, 1, 0.80) : Qt.rgba(1, 1, 1, 0.38)
                    radius: 19
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                }
            }

            Rectangle {
                id: rebootMask
                anchors.fill: parent
                radius: 19
                visible: false
            }

            Image {
                source: "data:image/svg+xml;utf8,<svg width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='white' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8'></path><polyline points='3 3 3 8 8 8'></polyline></svg>"
                width: 16
                height: 16
                anchors.centerIn: parent
                opacity: rebootMa.containsMouse ? 1.0 : 0.85
            }

            MouseArea {
                id: rebootMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sddm.reboot()
            }
        }

        // Frosted Glass Power Off Button
        Item {
            id: powerBtn
            width: 38
            height: 38

            Item {
                anchors.fill: parent
                layer.enabled: true
                layer.effect: OpacityMask { maskSource: powerMask }

                Image {
                    width: root.width
                    height: root.height
                    x: -(root.width - 36 - 38)
                    y: -(root.height - 28 - 38)
                    source: bgImage.source
                    fillMode: Image.PreserveAspectCrop
                    smooth: true

                    layer.enabled: true
                    layer.effect: FastBlur {
                        radius: 36
                        cached: true
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: powerMa.containsMouse ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(1, 1, 1, 0.12)
                    border.width: 1.5
                    border.color: powerMa.containsMouse ? Qt.rgba(1, 1, 1, 0.80) : Qt.rgba(1, 1, 1, 0.38)
                    radius: 19
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                }
            }

            Rectangle {
                id: powerMask
                anchors.fill: parent
                radius: 19
                visible: false
            }

            Image {
                source: "data:image/svg+xml;utf8,<svg width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='white' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M18.36 6.64a9 9 0 1 1-12.73 0'></path><line x1='12' y1='2' x2='12' y2='12'></line></svg>"
                width: 16
                height: 16
                anchors.centerIn: parent
                opacity: powerMa.containsMouse ? 1.0 : 0.85
            }

            MouseArea {
                id: powerMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sddm.powerOff()
            }
        }
    }

    // ── 7. TIME UPDATE TICKER ───────────────────────────────────────────
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var t = getDisplayTime();
            var d = Qt.formatDate(new Date(), "ddd MMM d");
            timeLabel.text = t;
            timeMaskText.text = t;
            dateLabel.text = d;
            dateMaskText.text = d;
        }
    }
}
