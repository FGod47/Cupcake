import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 640
    height: 480
    color: "black"

    property bool showLogin: false

    Keys.onPressed: (event) => {
        if (!showLogin) {
            showLogin = true;
            passwordInput.forceActiveFocus();
        }
    }

    Image {
        id: bgImage
        anchors.fill: parent
        source: "file:///tmp/lockbg.png"
        smooth: true
        fillMode: Image.PreserveAspectCrop
        z: 0

        onStatusChanged: {
            if (status === Image.Error) {
                source = config.background || "background.webp"
            }
        }
    }

    property string fontName: "Inter, sans-serif"
    property string themeGreen: "#8ed475" // from screenshot
    property color textColor: "#ffffff"

    property int currentUsersIndex: userModel.lastIndex
    property int currentSessionsIndex: sessionModel.lastIndex
    property int usernameRole: Qt.UserRole + 1
    property int realNameRole: Qt.UserRole + 2
    property int sessionNameRole: Qt.UserRole + 4
    
    property string currentUsername: userModel.data(userModel.index(currentUsersIndex, 0), usernameRole) || "cupcake"
    property string currentSession: sessionModel.data(sessionModel.index(currentSessionsIndex, 0), sessionNameRole) || "Hyprland"

    function bgFillMode() { return Image.PreserveAspectCrop; }

    function sessionsCycleSelectNext() {
        if (currentSessionsIndex >= sessionModel.rowCount() - 1) { currentSessionsIndex = 0; }
        else { currentSessionsIndex++; }
    }

    function usersCycleSelectNext() {
        if (currentUsersIndex >= userModel.count - 1) { currentUsersIndex = 0; }
        else { currentUsersIndex++; }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            passwordInput.text = ""
            passwordInputContainer.border.color = "#ff4a4a"
            failAnimation.restart()
        }
        function onLoginSucceeded() { }
    }

    Item {
        id: maskContainer
        anchors.fill: parent
        visible: false
        Rectangle {
            id: expandMask
            anchors.horizontalCenter: parent.horizontalCenter
            y: 10
            width: 130
            height: 34
            radius: 17
            color: "black"

            ParallelAnimation {
                running: true
                NumberAnimation { target: expandMask; property: "y"; to: -Math.max(root.width, root.height); duration: 2500; easing.type: Easing.InOutQuad }
                NumberAnimation { target: expandMask; property: "width"; to: Math.max(root.width, root.height) * 2.5; duration: 2500; easing.type: Easing.InOutQuad }
                NumberAnimation { target: expandMask; property: "height"; to: Math.max(root.width, root.height) * 2.5; duration: 2500; easing.type: Easing.InOutQuad }
                NumberAnimation { target: expandMask; property: "radius"; to: Math.max(root.width, root.height) * 1.25; duration: 2500; easing.type: Easing.InOutQuad }
            }
        }
    }

    Item {
        id: mainFrame
        anchors.fill: parent
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: maskContainer
        }

        Rectangle {
            id: background
            anchors.fill: parent
            color: "#000000"
            Image {
                id: image
                anchors.fill: parent
                source: "file:///tmp/lockbg.png"
                smooth: true
                fillMode: Image.PreserveAspectCrop
                z: 3

                onStatusChanged: {
                    if (status === Image.Error) {
                        source = config.background || "background.webp"
                    }
                }
            }
            Rectangle {
                z: 4
                anchors.fill: parent
                color: "#20000000" // subtle dark overlay for text readability
            }

            MouseArea {
                anchors.fill: parent
                enabled: !root.showLogin
                onClicked: {
                    root.showLogin = true;
                    passwordInput.forceActiveFocus();
                }
            }
        }

        Item {
            anchors.fill: parent
            scale: 0.8
            transformOrigin: Item.Center

            // TOP BAR REMOVED

        // CENTER COLUMN
        Column {
            z: 5
            anchors.centerIn: parent
            spacing: 20
            width: 400

            transform: Translate {
                y: root.showLogin ? -150 : 0
                Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }

            // CLOCK
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 5
                Text {
                    id: timeLabel
                    color: "#f5f5f5"
                    font.pixelSize: 180
                    font.weight: Font.Medium
                    font.family: fontName
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(new Date(), "hh:mm")
                }
                Text {
                    id: dateLabel
                    color: "#a0ffffff"
                    font.pixelSize: 32
                    font.family: fontName
                    font.weight: Font.Medium
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(new Date(), "dddd, MMMM d")
                }
            }
        } // End of CENTER COLUMN (Clock only)

        // LOGIN FORM
        Column {
            z: 5
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -60
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20
            width: 400

            // AVATAR AND USERNAME WRAPPER
            Item {
                width: parent.width
                height: avatarCol.implicitHeight
                anchors.horizontalCenter: parent.horizontalCenter
                
                scale: root.showLogin ? 1.3 : 1.0
                transformOrigin: Item.Bottom
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                Column {
                    id: avatarCol
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20

                    // AVATAR
                    Rectangle {
                        width: 90; height: 90
                        radius: 45
                        color: "#40ffffff" // placeholder for avatar bg
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        Image {
                            source: "data:image/svg+xml;utf8,<svg width='40' height='40' viewBox='0 0 24 24' fill='none' stroke='#f5f5f5' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2'></path><circle cx='12' cy='7' r='4'></circle></svg>"
                            width: 40; height: 40
                            anchors.centerIn: parent
                        }

                        Rectangle {
                            width: 16; height: 16
                            radius: 8
                            color: themeGreen
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.margins: 2
                            border.color: "#304030" // approx bg matching
                            border.width: 2
                        }
                    }

                    Text {
                        text: currentUsername
                        color: "#f5f5f5"
                        font.pixelSize: 24
                        font.weight: Font.DemiBold
                        font.family: fontName
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
            
            Item {
                width: parent.width
                height: root.showLogin ? 150 : 0
                opacity: root.showLogin ? 1 : 0
                visible: opacity > 0
                clip: true
                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                Column {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20
                    width: parent.width

                    Item { width: 1; height: 10 } // spacer

                    // PASSWORD INPUT
                    Rectangle {
                id: passwordInputContainer
                width: 260
                height: 45
                radius: 8
                color: "#15ffffff"
                border.color: "#30ffffff"
                border.width: 1
                anchors.horizontalCenter: parent.horizontalCenter

                SequentialAnimation on border.color {
                    id: failAnimation
                    running: false
                    ColorAnimation { from: "#ff4a4a"; to: "#30ffffff"; duration: 800 }
                }

                Image {
                    source: "data:image/svg+xml;utf8,<svg width='20' height='20' viewBox='0 0 24 24' fill='none' stroke='#808080' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><rect x='3' y='11' width='18' height='11' rx='2' ry='2'></rect><path d='M7 11V7a5 5 0 0 1 10 0v4'></path></svg>"
                    width: 20; height: 20
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextInput {
                    id: passwordInput
                    anchors.left: parent.left
                    anchors.right: eyeIconMA.left
                    anchors.leftMargin: 45
                    anchors.rightMargin: 15
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 18
                    font.family: fontName
                    color: "#ffffff"
                    echoMode: eyeIconMA.pressed ? TextInput.Normal : TextInput.Password
                    passwordCharacter: "•"
                    clip: true
                    focus: true
                    onAccepted: {
                        if (text != "") {
                            sddm.login(userModel.data(userModel.index(currentUsersIndex, 0), usernameRole) || "123test", text, currentSessionsIndex);
                        }
                    }
                }

                MouseArea {
                    id: eyeIconMA
                    width: 40; height: 40
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    Image {
                        id: eyeIcon
                        source: eyeIconMA.pressed 
                            ? "data:image/svg+xml;utf8,<svg width='20' height='20' viewBox='0 0 24 24' fill='none' stroke='#808080' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z'></path><circle cx='12' cy='12' r='3'></circle></svg>"
                            : "data:image/svg+xml;utf8,<svg width='20' height='20' viewBox='0 0 24 24' fill='none' stroke='#808080' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24'></path><line x1='1' y1='1' x2='23' y2='23'></line></svg>"
                        width: 20; height: 20
                        anchors.centerIn: parent
                    }
                }
            }

            // SIGN IN BUTTON
            Rectangle {
                width: 260
                height: 45
                radius: 8
                color: themeGreen
                anchors.horizontalCenter: parent.horizontalCenter

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (passwordInput.text != "") {
                            sddm.login(userModel.data(userModel.index(currentUsersIndex, 0), usernameRole) || "123test", passwordInput.text, currentSessionsIndex);
                        }
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 10
                    Text {
                        text: "Sign in"
                        color: "#1a1a1a"
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        font.family: fontName
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "→"
                        color: "#1a1a1a"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        font.family: fontName
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

                } // End of inner input Column
            } // End of wrapper Item
        }

        // BOTTOM RIGHT POWER OPTIONS REMOVED
            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    timeLabel.text = Qt.formatTime(new Date(), "hh:mm")
                    dateLabel.text = Qt.formatDate(new Date(), "dddd, MMMM d")
                }
            }
        }
    }
}
