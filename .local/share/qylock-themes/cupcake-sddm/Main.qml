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

    property string fontName: "Google Sans, Inter, SF Pro Display, -apple-system, sans-serif"
    property color textColor: "#ffffff"
    property bool isLoginPromptVisible: false

    property int currentUsersIndex: (userModel && userModel.lastIndex !== undefined) ? userModel.lastIndex : 0
    property int currentSessionsIndex: (sessionModel && sessionModel.lastIndex !== undefined) ? sessionModel.lastIndex : 0
    property int usernameRole: Qt.UserRole + 1
    property int realNameRole: Qt.UserRole + 2
    property int sessionNameRole: Qt.UserRole + 4

    property string currentUsername: (userModel && userModel.count > 0) ? (userModel.data(userModel.index(currentUsersIndex, 0), usernameRole) || "cupcake") : "cupcake"
    property string currentRealName: (userModel && userModel.count > 0) ? (userModel.data(userModel.index(currentUsersIndex, 0), realNameRole) || currentUsername) : "Debojyoti Chakraborty"
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
            radius: root.isLoginPromptVisible ? 42 : 0
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

        // Session Pill (e.g. Hyprland)
        Rectangle {
            height: 30
            width: sessionRow.implicitWidth + 24
            radius: 15
            color: sessionMa.containsMouse ? "#45000000" : "#28000000"
            border.width: 1
            border.color: sessionMa.containsMouse ? "#50ffffff" : "#25ffffff"
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Row {
                id: sessionRow
                anchors.centerIn: parent
                spacing: 6

                Image {
                    source: "data:image/svg+xml;utf8,<svg width='14' height='14' viewBox='0 0 24 24' fill='none' stroke='white' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><rect x='2' y='3' width='20' height='14' rx='2' ry='2'></rect><line x1='8' y1='21' x2='16' y2='21'></line><line x1='12' y1='17' x2='12' y2='21'></line></svg>"
                    width: 14
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: 0.8
                }

                Text {
                    text: currentSession
                    color: "#ffffff"
                    font.family: fontName
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: 0.9
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

    function get12HourTime() {
        let d = new Date();
        let hours = d.getHours();
        let minutes = d.getMinutes();
        let h12 = hours % 12 || 12;
        let mStr = minutes < 10 ? ("0" + minutes) : minutes;
        return h12 + ":" + mStr;
    }

    // ── 4. LOCKSCREEN DATE & CLOCK ──────────────────────────────────────
    // ── 4. LOCKSCREEN DATE & CLOCK (Frosted Glassy Translucent Typography) ─
    Item {
        id: clockSection
        z: 8
        anchors.top: parent.top
        anchors.topMargin: root.isLoginPromptVisible ? (parent.height * 0.065) : (parent.height * 0.09)
        Behavior on anchors.topMargin { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: parent.width * 0.02
        width: 380
        height: 180

        Column {
            anchors.centerIn: parent
            spacing: -4

            // Date Text ("Thu May 7")
            Text {
                id: dateLabel
                text: Qt.formatDate(new Date(), "ddd MMM d")
                font.family: fontName
                font.pixelSize: 24
                font.weight: Font.Medium
                color: "#ffffff"
                opacity: 0.92
                anchors.horizontalCenter: parent.horizontalCenter
                style: Text.Raised
                styleColor: "#40000000"
            }

            // Frosted Glass Big Lockscreen Time ("4:52")
            Item {
                id: glassClockContainer
                width: timeLabel.implicitWidth
                height: timeLabel.implicitHeight
                anchors.horizontalCenter: parent.horizontalCenter

                // 1. Frosted Blurred Wallpaper Layer clipped to digits
                Item {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.effect: OpacityMask { maskSource: timeMaskItem }

                    Image {
                        id: clockBgCrop
                        width: root.width
                        height: root.height
                        x: -clockSection.x - (clockSection.width - glassClockContainer.width)/2
                        y: -clockSection.y - 20
                        source: config.background || "background.png"
                        fillMode: Image.PreserveAspectCrop
                        smooth: true

                        layer.enabled: true
                        layer.effect: FastBlur {
                            radius: 36
                            cached: true
                        }
                    }

                    // Glass milky tint inside digits
                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(1, 1, 1, 0.45)
                    }
                }

                // 2. Alpha Mask for the digits
                Item {
                    id: timeMaskItem
                    anchors.fill: parent
                    visible: false

                    Text {
                        anchors.centerIn: parent
                        text: root.get12HourTime()
                        font.family: fontName
                        font.pixelSize: 116
                        font.weight: Font.DemiBold
                        font.letterSpacing: -2.5
                        color: "#ffffff"
                    }
                }

                // 3. Specular Glass Specular Sheen & Soft Rim
                Text {
                    id: timeLabel
                    anchors.centerIn: parent
                    text: root.get12HourTime()
                    font.family: fontName
                    font.pixelSize: 116
                    font.weight: Font.DemiBold
                    font.letterSpacing: -2.5
                    color: Qt.rgba(1, 1, 1, 0.35)
                    style: Text.Raised
                    styleColor: Qt.rgba(0, 0, 0, 0.25)
                }
            }
        }
    }

    // ── 5. USER PROFILE & INTERACTIVE SLIDE-UP LOGIN SECTION ────────────
    Item {
        id: userLoginSection
        z: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.isLoginPromptVisible ? (parent.height * 0.11) : (parent.height * 0.055)
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: parent.width * 0.02
        width: 260
        height: 200

        Column {
            anchors.centerIn: parent
            spacing: root.isLoginPromptVisible ? 10 : 8
            Behavior on spacing { NumberAnimation { duration: 250 } }
            width: parent.width

            // User Avatar
            Rectangle {
                id: avatarCircle
                width: root.isLoginPromptVisible ? 56 : 64
                height: width
                radius: width / 2
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                color: "#25000000"
                border.width: 1.5
                border.color: avatarMa.containsMouse ? "#80ffffff" : "#45ffffff"
                anchors.horizontalCenter: parent.horizontalCenter
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Rectangle {
                    id: avatarMask
                    anchors.fill: parent
                    radius: parent.radius
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
                font.pixelSize: root.isLoginPromptVisible ? 13 : 14
                font.weight: Font.DemiBold
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: 0.95
                style: Text.Raised
                styleColor: "#40000000"
                Behavior on font.pixelSize { NumberAnimation { duration: 200 } }

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

            // Upward Chevron / Unlock Hint (Visible when Resting)
            Item {
                id: unlockHint
                anchors.horizontalCenter: parent.horizontalCenter
                width: 120
                height: 28
                visible: opacity > 0.01
                opacity: !root.isLoginPromptVisible ? 0.85 : 0.0
                scale: !root.isLoginPromptVisible ? 1.0 : 0.7
                Behavior on opacity { NumberAnimation { duration: 250 } }
                Behavior on scale { NumberAnimation { duration: 250 } }

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
                        
                        SequentialAnimation on y {
                            loops: Animation.Infinite
                            running: !root.isLoginPromptVisible
                            NumberAnimation { to: -3; duration: 600; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
                        }
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
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.showLoginPrompt()
                }
            }

            // Pill Password Input Field (Revealed on Slide-Up)
            Rectangle {
                id: passwordContainer
                width: 180
                height: root.isLoginPromptVisible ? 34 : 0
                radius: 17
                clip: true
                visible: opacity > 0.01
                opacity: root.isLoginPromptVisible ? 1.0 : 0.0
                scale: root.isLoginPromptVisible ? 1.0 : 0.85
                color: passwordInput.activeFocus ? "#48000000" : "#30000000"
                border.width: 1
                border.color: passwordInput.activeFocus ? "#60ffffff" : "#30ffffff"
                anchors.horizontalCenter: parent.horizontalCenter
                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                SequentialAnimation {
                    id: failAnimation
                    NumberAnimation { target: passwordContainer; property: "anchors.horizontalCenterOffset"; from: 0; to: -10; duration: 45; easing.type: Easing.OutQuad }
                    NumberAnimation { target: passwordContainer; property: "anchors.horizontalCenterOffset"; to: 10; duration: 45; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: passwordContainer; property: "anchors.horizontalCenterOffset"; to: -8; duration: 45; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: passwordContainer; property: "anchors.horizontalCenterOffset"; to: 8; duration: 45; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: passwordContainer; property: "anchors.horizontalCenterOffset"; to: 0; duration: 45; easing.type: Easing.OutQuad }
                    ColorAnimation { target: passwordContainer; property: "border.color"; from: "#ff5555"; to: "#30ffffff"; duration: 600 }
                }

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    font.family: fontName
                    font.pixelSize: 13
                    color: "#ffffff"
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    cursorVisible: activeFocus && text.length > 0
                    clip: true

                    onAccepted: {
                        if (text !== "") {
                            sddm.login(currentUsername, text, currentSessionsIndex);
                        }
                    }
                }

                Text {
                    id: placeholderText
                    text: "Enter Password"
                    anchors.centerIn: parent
                    color: "#90ffffff"
                    font.family: fontName
                    font.pixelSize: 11
                    font.weight: Font.Normal
                    visible: passwordInput.text === ""
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.IBeamCursor
                    onClicked: passwordInput.forceActiveFocus()
                }
            }
        }
    }

    // ── 6. BOTTOM RIGHT POWER CONTROLS ───────────────────────────────────
    Row {
        z: 10
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        anchors.right: parent.right
        anchors.rightMargin: 36
        spacing: 12

        // Reboot Button
        Rectangle {
            width: 36
            height: 36
            radius: 18
            color: rebootMa.containsMouse ? "#45000000" : "#22000000"
            border.width: 1
            border.color: rebootMa.containsMouse ? "#50ffffff" : "#20ffffff"
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Image {
                source: "data:image/svg+xml;utf8,<svg width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='white' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8'></path><polyline points='3 3 3 8 8 8'></polyline></svg>"
                width: 16
                height: 16
                anchors.centerIn: parent
                opacity: 0.85
            }

            MouseArea {
                id: rebootMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sddm.reboot()
            }
        }

        // Power Off Button
        Rectangle {
            width: 36
            height: 36
            radius: 18
            color: powerMa.containsMouse ? "#45000000" : "#22000000"
            border.width: 1
            border.color: powerMa.containsMouse ? "#50ffffff" : "#20ffffff"
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Image {
                source: "data:image/svg+xml;utf8,<svg width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='white' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M18.36 6.64a9 9 0 1 1-12.73 0'></path><line x1='12' y1='2' x2='12' y2='12'></line></svg>"
                width: 16
                height: 16
                anchors.centerIn: parent
                opacity: 0.85
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
            timeLabel.text = get12HourTime();
            dateLabel.text = Qt.formatDate(new Date(), "ddd MMM d");
        }
    }
}
