import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "theme"

PanelWindow {
    id: aiWindow
    exclusionMode: ExclusionMode.Ignore
    
    anchors {
        top: true
        bottom: true
        left: true
    }

    implicitWidth: 470
    color: "transparent"
    visible: globalState.aiPanelVisible || container.x > -460
    margins.top: 15
    margins.bottom: 15

    // Main sliding container (End-4 exact styling)
    Rectangle {
        id: container
        width: 450
        height: parent.height
        radius: 30
        color: Theme.colBase // Deep background
        border.color: Theme.colOutlineVariant
        border.width: 1
        clip: true

        x: globalState.aiPanelVisible ? 10 : -470
        Behavior on x {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutExpo // End-4 style snappy slide
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // 1. HEADER (Exact End-4 layout)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15

                    // Gemini Icon
                    Text {
                        text: "✨"
                        font.pixelSize: 24
                        color: Theme.colPrimary
                    }

                    // Title
                    Text {
                        text: "Gemini"
                        font.family: "Inter"
                        font.pixelSize: 18
                        font.weight: 600
                        color: Theme.colOnSurface
                        Layout.fillWidth: true
                    }

                    // Clear Chat Button
                    Rectangle {
                        width: 36; height: 36; radius: 18
                        color: clearMouse.containsMouse ? Theme.colSurfaceContainerHigh : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰃢" // Broom icon
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 18
                            color: Theme.colOnSurfaceVariant
                        }
                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                chatModel.clear();
                                chatModel.append({ isUser: false, message: "Chat cleared. How can I help you today?" });
                            }
                        }
                    }

                    // Settings Button
                    Rectangle {
                        width: 36; height: 36; radius: 18
                        color: settingsMouse.containsMouse ? Theme.colSurfaceContainerHigh : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "" // Gear icon
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 18
                            color: Theme.colOnSurfaceVariant
                        }
                        MouseArea {
                            id: settingsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.colSurfaceContainerHighest
            }

            // 2. CHAT HISTORY (End-4 bubble styling)
            ListModel {
                id: chatModel
                ListElement {
                    isUser: false
                    message: "Hello! I am your native Cupcake AI Assistant.\n\nI look and feel exactly like the end-4 AGS panel, but I run entirely in Quickshell!\n\n**Try asking me a question!**"
                }
            }

            ListView {
                id: chatList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: chatModel
                spacing: 20
                topMargin: 20
                bottomMargin: 20
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    width: chatList.width
                    height: bubble.height

                    RowLayout {
                        anchors.left: model.isUser ? undefined : parent.left
                        anchors.right: model.isUser ? parent.right : undefined
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 15
                        
                        // AI Avatar (only show on left)
                        Rectangle {
                            visible: !model.isUser
                            Layout.alignment: Qt.AlignTop
                            width: 36; height: 36; radius: 18
                            color: Theme.colSurfaceContainerHigh
                            border.color: Theme.colOutlineVariant
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: "✨"
                                font.pixelSize: 18
                            }
                        }

                        // Message Bubble
                        Rectangle {
                            id: bubble
                            Layout.maximumWidth: chatList.width - 100
                            Layout.preferredHeight: msgText.implicitHeight + 24
                            radius: 18
                            // User bubbles are Primary colored, AI bubbles are Surface colored
                            color: model.isUser ? Theme.colPrimary : Theme.colSurfaceContainerHigh
                            
                            // Make bottom-right/bottom-left sharp for the tail effect
                            Rectangle {
                                visible: model.isUser
                                width: 18; height: 18
                                color: Theme.colPrimary
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                            }
                            Rectangle {
                                visible: !model.isUser
                                width: 18; height: 18
                                color: Theme.colSurfaceContainerHigh
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                            }

                            Text {
                                id: msgText
                                anchors.fill: parent
                                anchors.margins: 12
                                text: model.message
                                textFormat: Text.MarkdownText
                                wrapMode: Text.WordWrap
                                color: model.isUser ? Theme.colOnPrimary : Theme.colOnSurface
                                font.pixelSize: 14
                                font.family: "Inter"
                                
                                onLinkActivated: Qt.openUrlExternally(link)
                            }
                        }

                        // User Avatar (only show on right)
                        Rectangle {
                            visible: model.isUser
                            Layout.alignment: Qt.AlignTop
                            width: 36; height: 36; radius: 18
                            color: Theme.colSecondaryContainer
                            Text {
                                anchors.centerIn: parent
                                text: ""
                                font.family: "JetBrainsMono Nerd Font Propo"
                                color: Theme.colOnSecondaryContainer
                                font.pixelSize: 18
                            }
                        }
                    }
                }
            }

            // 3. INPUT BOX (End-4 floating pill style)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                Layout.margins: 20
                radius: 30
                color: Theme.colSurfaceContainer
                border.color: Theme.colOutlineVariant
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 10

                    TextField {
                        id: promptInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: "Message Gemini..."
                        placeholderTextColor: Theme.colOnSurfaceVariant
                        color: Theme.colOnSurface
                        font.pixelSize: 15
                        font.family: "Inter"
                        background: Item {} // Remove default QQC2 styling
                        verticalAlignment: TextInput.AlignVCenter
                        leftPadding: 15
                        
                        onAccepted: sendBtnMouse.onClicked()
                    }

                    // Send Button
                    Rectangle {
                        width: 44; height: 44; radius: 22
                        color: promptInput.text.length > 0 ? Theme.colPrimary : Theme.colSurfaceContainerHigh
                        
                        Text {
                            anchors.centerIn: parent
                            text: "" // Up arrow icon like End-4
                            color: promptInput.text.length > 0 ? Theme.colOnPrimary : Theme.colOnSurfaceVariant
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 18
                            font.weight: 800
                        }
                        
                        MouseArea {
                            id: sendBtnMouse
                            anchors.fill: parent
                            cursorShape: promptInput.text.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (promptInput.text.trim() === "") return;
                                
                                // Add user message
                                chatModel.append({ isUser: true, message: promptInput.text });
                                
                                // Add fake AI response for now
                                var userText = promptInput.text;
                                chatModel.append({ isUser: false, message: "Thinking..." });
                                
                                promptInput.text = "";
                                
                                // Scroll to bottom
                                chatList.positionViewAtEnd();
                            }
                        }
                    }
                }
            }
        }
    }
}
