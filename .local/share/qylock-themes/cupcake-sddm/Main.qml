import QtQuick 2.15
import QtQuick.Controls 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#121214"

    property string fontName: "Google Sans, Inter, SF Pro Display, -apple-system, sans-serif"
    property color textColor: "#ffffff"

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

    Connections {
        target: sddm
        function onLoginFailed() {
            passwordInput.text = "";
            passwordContainer.border.color = "#ff5555";
            failAnimation.restart();
        }
        function onLoginSucceeded() { }
    }

    // ── 1. BACKGROUND WALLPAPER ──────────────────────────────────────────
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
    }

    // ── 2. TOP CAMERA NOTCH TAB ──────────────────────────────────────────
    Rectangle {
        id: topNotch
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: 144
        height: 28
        color: "#000000"
        radius: 0
        bottomLeftRadius: 14
        bottomRightRadius: 14
        z: 10

        Rectangle {
            anchors.centerIn: parent
            width: 8
            height: 8
            radius: 4
            color: "#1a1a1a"
            border.width: 1
            border.color: "#282828"
        }
    }

    // ── 3. TOP RIGHT CONTROLS (Session & Layout) ────────────────────────
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

    // ── 4. LOCKSCREEN DATE & CLOCK (iOS 16 Inspired Typography) ─────────
    Item {
        id: clockSection
        z: 8
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.09
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: parent.width * 0.02
        width: 320
        height: 170

        Column {
            anchors.centerIn: parent
            spacing: -4

            // Date Text ("Thu May 7")
            Text {
                id: dateLabel
                text: Qt.formatDate(new Date(), "ddd MMM d")
                font.family: fontName
                font.pixelSize: 23
                font.weight: Font.Medium
                color: "#ffffff"
                opacity: 0.92
                anchors.horizontalCenter: parent.horizontalCenter
                style: Text.Raised
                styleColor: "#40000000"
            }

            // Big Lockscreen Time ("4:52" / 12-Hour)
            Text {
                id: timeLabel
                text: get12HourTime()
                font.family: fontName
                font.pixelSize: 114
                font.weight: Font.DemiBold
                font.letterSpacing: -2.5
                color: "#ffffff"
                opacity: 0.88
                anchors.horizontalCenter: parent.horizontalCenter
                style: Text.Raised
                styleColor: "#50000000"
            }
        }
    }

    // ── 5. USER PROFILE & PASSWORD LOGIN (Bottom Center) ─────────────────
    Item {
        id: userLoginSection
        z: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height * 0.075
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: parent.width * 0.02
        width: 240
        height: 160

        Column {
            anchors.centerIn: parent
            spacing: 10
            width: parent.width

            // User Avatar
            Rectangle {
                id: avatarCircle
                width: 52
                height: 52
                radius: 26
                color: "#25000000"
                border.width: 1.5
                border.color: avatarMa.containsMouse ? "#70ffffff" : "#40ffffff"
                anchors.horizontalCenter: parent.horizontalCenter
                clip: true
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Image {
                    id: avatarImg
                    anchors.fill: parent
                    source: "avatar.png"
                    smooth: true
                    fillMode: Image.PreserveAspectCrop
                }

                MouseArea {
                    id: avatarMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: usersCycleSelectNext()
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
                style: Text.Raised
                styleColor: "#40000000"

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: usersCycleSelectNext()
                }
            }

            // Pill Password Input Field
            Rectangle {
                id: passwordContainer
                width: 174
                height: 32
                radius: 16
                color: passwordInput.activeFocus ? "#48000000" : "#30000000"
                border.width: 1
                border.color: passwordInput.activeFocus ? "#55ffffff" : "#30ffffff"
                anchors.horizontalCenter: parent.horizontalCenter
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
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    font.family: fontName
                    font.pixelSize: 13
                    color: "#ffffff"
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    focus: true
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
