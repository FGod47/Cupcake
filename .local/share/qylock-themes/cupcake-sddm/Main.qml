import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 640
    height: 480

    property string fontName: "Google Sans, Inter, Google Sans Flex, sans-serif"
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
        id: mainFrame
        anchors.fill: parent

        Rectangle {
            id: background
            anchors.fill: parent
            color: "#000000"
            Image {
                id: image
                anchors.fill: parent
                source: config.background || "background.png"
                smooth: true
                fillMode: Image.PreserveAspectCrop
                z: 3
            }
            Rectangle {
                z: 4
                anchors.fill: parent
                color: "transparent" // transparent overlay to let custom gradient shine in full purity
            }
        }

        // TOP BAR (Position: absolute, top: 40px, left/right: 56px)
        Item {
            z: 5
            anchors.top: parent.top
            anchors.topMargin: 40
            anchors.left: parent.left
            anchors.leftMargin: 56
            anchors.right: parent.right
            anchors.rightMargin: 56
            height: 40

            Text {
                id: topDate
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: "#b9c6bd"
                font.pixelSize: 16
                font.family: fontName
                font.weight: Font.Normal
                text: Qt.formatDate(new Date(), "ddd, MMM dd")
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 28

                Row {
                    spacing: 8
                    Image {
                        source: "data:image/svg+xml;utf8,<svg width='18' height='18' viewBox='0 0 24 24' fill='none' stroke='#b9c6bd' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round'><rect x='2' y='4' width='20' height='16' rx='2' ry='2'></rect><line x1='6' y1='8' x2='6' y2='8'></line><line x1='10' y1='8' x2='10' y2='8'></line><line x1='14' y1='8' x2='14' y2='8'></line><line x1='18' y1='8' x2='18' y2='8'></line><line x1='6' y1='12' x2='6' y2='12'></line><line x1='10' y1='12' x2='10' y2='12'></line><line x1='14' y1='12' x2='14' y2='12'></line><line x1='18' y1='12' x2='18' y2='12'></line><line x1='8' y1='16' x2='16' y2='16'></line></svg>"
                        width: 18; height: 18; anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        color: "#b9c6bd"
                        font.pixelSize: 16
                        font.family: fontName
                        font.weight: Font.Normal
                        text: "EN"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    width: sessionRow.width
                    height: sessionRow.height
                    onClicked: sessionsCycleSelectNext()
                    Row {
                        id: sessionRow
                        spacing: 8
                        Image {
                            source: "data:image/svg+xml;utf8,<svg width='18' height='18' viewBox='0 0 24 24' fill='none' stroke='#b9c6bd' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round'><rect x='2' y='3' width='20' height='14' rx='2' ry='2'></rect><line x1='8' y1='21' x2='16' y2='21'></line><line x1='12' y1='17' x2='12' y2='21'></line></svg>"
                            width: 18; height: 18; anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            color: "#b9c6bd"
                            font.pixelSize: 16
                            font.family: fontName
                            font.weight: Font.Normal
                            text: currentSession
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }

        // CLOCK (Centered horizontally, top: 70px)
        Column {
            id: clockColumn
            z: 5
            anchors.top: parent.top
            anchors.topMargin: 70
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Text {
                id: timeLabel
                color: "#f5f8f3"
                font.pixelSize: 76
                font.weight: Font.Light
                font.family: fontName
                font.letterSpacing: -1.5
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(new Date(), "hh:mm")
            }
            Text {
                id: dateLabel
                color: "#93a390"
                font.pixelSize: 16
                font.family: fontName
                font.weight: Font.Normal
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(new Date(), "dddd, MMMM d")
            }
        }

        // AVATAR + FORM BLOCK (Centered horizontally, top: 470px)
        Column {
            z: 5
            anchors.top: parent.top
            anchors.topMargin: 470
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0
            width: 400

            // AVATAR
            Rectangle {
                width: 76; height: 76
                radius: 38
                color: "#33453a"
                anchors.horizontalCenter: parent.horizontalCenter
                
                Image {
                    source: "data:image/svg+xml;utf8,<svg width='30' height='30' viewBox='0 0 24 24' fill='none' stroke='#b9c6bd' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round'><path d='M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2'></path><circle cx='12' cy='7' r='4'></circle></svg>"
                    width: 30; height: 30
                    anchors.centerIn: parent
                }

                Rectangle {
                    width: 12; height: 12
                    radius: 6
                    color: "#9ed36f"
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 2
                    border.color: "#12190f"
                    border.width: 2
                }
            }

            Item { width: 1; height: 12 } // 12px gap below avatar

            // USERNAME
            Text {
                text: currentUsername
                color: "#f5f8f3"
                font.pixelSize: 16
                font.weight: Font.Medium
                font.family: fontName
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Item { width: 1; height: 34 } // 34px gap to form container

            // PASSWORD INPUT (300px wide, dark translucent)
            Rectangle {
                id: passwordInputContainer
                width: 300
                height: 45
                radius: 10
                color: "#0dffffff" // rgba(255,255,255,0.05)
                border.color: "#0fffffff" // rgba(255,255,255,0.06)
                border.width: 1
                anchors.horizontalCenter: parent.horizontalCenter

                SequentialAnimation on border.color {
                    id: failAnimation
                    running: false
                    ColorAnimation { from: "#ff4a4a"; to: "#0fffffff"; duration: 800 }
                }

                Image {
                    source: "data:image/svg+xml;utf8,<svg width='15' height='15' viewBox='0 0 24 24' fill='none' stroke='#93a390' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round'><rect x='3' y='11' width='18' height='11' rx='2' ry='2'></rect><path d='M7 11V7a5 5 0 0 1 10 0v4'></path></svg>"
                    width: 15; height: 15
                    anchors.left: parent.left
                    anchors.leftMargin: 13
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextInput {
                    id: passwordInput
                    anchors.left: parent.left
                    anchors.right: eyeIconMA.left
                    anchors.leftMargin: 40
                    anchors.rightMargin: 15
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 16
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
                    width: 30; height: 30
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    Image {
                        id: eyeIcon
                        source: eyeIconMA.pressed 
                            ? "data:image/svg+xml;utf8,<svg width='15' height='15' viewBox='0 0 24 24' fill='none' stroke='#93a390' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round'><path d='M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z'></path><circle cx='12' cy='12' r='3'></circle></svg>"
                            : "data:image/svg+xml;utf8,<svg width='15' height='15' viewBox='0 0 24 24' fill='none' stroke='#93a390' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round'><path d='M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24'></path><line x1='1' y1='1' x2='23' y2='23'></line></svg>"
                        width: 15; height: 15
                        anchors.centerIn: parent
                    }
                }
            }

            Item { width: 1; height: 18 } // 18px gap: password input -> sign in button

            // SIGN IN BUTTON (300px wide, solid #9ed36f background, dark text #16210f)
            Rectangle {
                width: 300
                height: 45
                radius: 10
                color: "#9ed36f"
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
                        color: "#16210f"
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        font.family: fontName
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Image {
                        source: "data:image/svg+xml;utf8,<svg width='14' height='14' viewBox='0 0 24 24' fill='none' stroke='#16210f' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round'><line x1='5' y1='12' x2='19' y2='12'></line><polyline points='12 5 19 12 12 19'></polyline></svg>"
                        width: 14; height: 14; anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Item { width: 1; height: 22 } // 22px gap: sign in button -> switch user

            // SWITCH USER (Centered below)
            MouseArea {
                width: 200; height: 25
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: usersCycleSelectNext()
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Image {
                        source: "data:image/svg+xml;utf8,<svg width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='#93a390' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round'><path d='M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2'></path><circle cx='9' cy='7' r='4'></circle><path d='M23 21v-2a4 4 0 0 0-3-3.87'></path><path d='M16 3.13a4 4 0 0 1 0 7.75'></path></svg>"
                        width: 16; height: 16; anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Switch user"
                        color: "#93a390"
                        font.pixelSize: 15
                        font.family: fontName
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        // BOTTOM-RIGHT CONTROLS (Position: absolute, bottom: 44px, right: 56px, 16px gap)
        Row {
            z: 5
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 44
            anchors.right: parent.right
            anchors.rightMargin: 56
            spacing: 16

            Rectangle {
                width: 48; height: 48; radius: 24
                color: "#15ffffff" // translucent bg
                border.color: "#10ffffff" // 1px border
                border.width: 1
                Image {
                    source: "data:image/svg+xml;utf8,<svg width='20' height='20' viewBox='0 0 24 24' fill='none' stroke='#b9c6bd' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round'><path d='M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8'></path><polyline points='3 3 3 8 8 8'></polyline></svg>"
                    width: 20; height: 20; anchors.centerIn: parent
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: sddm.reboot()
                }
            }
            Rectangle {
                width: 48; height: 48; radius: 24
                color: "#15ffffff" // translucent bg
                border.color: "#10ffffff" // 1px border
                border.width: 1
                Image {
                    source: "data:image/svg+xml;utf8,<svg width='20' height='20' viewBox='0 0 24 24' fill='none' stroke='#b9c6bd' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round'><path d='M18.36 6.64a9 9 0 1 1-12.73 0'></path><line x1='12' y1='2' x2='12' y2='12'></line></svg>"
                    width: 20; height: 20; anchors.centerIn: parent
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: sddm.powerOff()
                }
            }
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                timeLabel.text = Qt.formatTime(new Date(), "hh:mm")
                topDate.text = Qt.formatDate(new Date(), "ddd, MMM dd")
                dateLabel.text = Qt.formatDate(new Date(), "dddd, MMMM d")
            }
        }
    }
}
