import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "theme"

PanelWindow {
    id: aiWindow
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    
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

    property bool hasKey: false

    function sendMessage() {
        if (promptInput.text.trim() === "") return;
        
        var userText = promptInput.text.trim();
        
        if (!hasKey) {
            chatModel.append({ isUser: true, message: userText });
            chatModel.append({ isUser: false, message: "**Error:** You haven't added your API key yet!\n\nPlease open the Settings app (Super + P -> Settings), go to the AI tab, and save your key there." });
            promptInput.text = "";
            chatList.positionViewAtEnd();
            return;
        }

        chatModel.append({ isUser: true, message: userText });
        chatModel.append({ isUser: false, message: "Thinking..." });
        
        promptInput.text = "";
        chatList.positionViewAtEnd();
        
        geminiProcess.command = ["python3", "/home/one/.config/quickshell/gemini.py", userText];
        geminiProcess.running = true;
    }

    // Main sliding container (End-4 exact styling)
    Rectangle {
        id: container
        width: 450
        height: parent.height
        radius: 30
        color: Theme.colSurface // Deep background
        border.color: Theme.colOutline
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

                    // Model Selector (Replaces Title)
                    ComboBox {
                        id: modelCombo
                        Layout.fillWidth: true
                        Layout.maximumWidth: 220
                        Layout.preferredHeight: 36
                        model: [
                            "gemini-3.5-flash",
                            "gemini-flash-latest",
                            "gemini-2.5-pro",
                            "gemini-2.5-flash",
                            "gemini-2.0-flash",
                            "gemini-pro-latest"
                        ]
                        
                        indicator: Item {} // Hide default arrow
                        
                        background: Rectangle {
                            color: "transparent"
                        }
                        
                        contentItem: Text {
                            text: modelCombo.currentText + " " // Custom arrow
                            font.family: "Inter"
                            font.pixelSize: 18
                            font.weight: 600
                            color: Theme.colOnSurface
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                        
                        Process {
                            command: ["bash", "-c", "cat ~/.config/quickshell/gemini_model.txt 2>/dev/null"]
                            running: true
                            stdout: SplitParser {
                                onRead: data => {
                                    if (data.trim() !== "") {
                                        for (var i = 0; i < modelCombo.model.length; i++) {
                                            if (modelCombo.model[i] === data.trim()) {
                                                modelCombo.currentIndex = i;
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        Process {
                            id: saveModelProcess
                            running: false
                        }
                        
                        onActivated: {
                            saveModelProcess.command = ["bash", "-c", "echo '" + currentText + "' > ~/.config/quickshell/gemini_model.txt"];
                            saveModelProcess.running = true;
                        }
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
                color: Theme.colSurfaceContainerHigh
            }

            // 2. CHAT HISTORY (End-4 bubble styling)
            ListModel {
                id: chatModel
                ListElement {
                    isUser: false
                    message: "Hello! How can I help you today?"
                }
            }

            // Process to check if key exists
            Process {
                id: checkKeyProcess
                command: ["bash", "-c", "cat ~/.config/quickshell/gemini_key.txt 2>/dev/null"]
                running: true
                stdout: SplitParser {
                    onRead: data => {
                        if (data.length > 10) {
                            aiWindow.hasKey = true;
                        }
                    }
                }
            }

            ListView {
                id: chatList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: chatModel
                spacing: 24
                topMargin: 20
                bottomMargin: 20
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    width: chatList.width
                    height: Math.max(bubbleItem.height, 36)

                    RowLayout {
                        anchors.left: model.isUser ? undefined : parent.left
                        anchors.right: model.isUser ? parent.right : undefined
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 16
                        
                        // AI Avatar (only show on left for AI)
                        Rectangle {
                            visible: !model.isUser
                            Layout.alignment: Qt.AlignTop
                            width: 32; height: 32; radius: 16
                            color: "transparent"
                            
                            Text {
                                anchors.centerIn: parent
                                text: "✨"
                                font.pixelSize: 20
                                // Gemini gradient colors
                                color: "#8AB4F8"
                            }
                        }

                        // Message Content
                        Item {
                            id: bubbleItem
                            Layout.maximumWidth: chatList.width - 100
                            Layout.preferredHeight: msgText.implicitHeight + (model.isUser ? 24 : 8)
                            
                            // User gets a pill background, AI gets transparent
                            Rectangle {
                                anchors.fill: parent
                                visible: model.isUser
                                radius: 18
                                color: Theme.colSurfaceContainerHigh
                            }

                            Text {
                                id: msgText
                                anchors.fill: parent
                                anchors.margins: model.isUser ? 12 : 4
                                anchors.topMargin: model.isUser ? 12 : 6
                                text: model.message
                                textFormat: Text.MarkdownText
                                wrapMode: Text.WordWrap
                                color: Theme.colOnSurface
                                font.pixelSize: 15
                                font.family: "Inter"
                                lineHeight: 1.4
                                
                                onLinkActivated: Qt.openUrlExternally(link)
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
                border.color: Theme.colOutline
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
                        
                        onAccepted: aiWindow.sendMessage()
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
                            onClicked: aiWindow.sendMessage()
                        }
                    }
                }
            }
        }

        // Backend AI Streaming Process
        Process {
            id: geminiProcess
            command: ["python3", "/home/one/.config/quickshell/gemini.py", ""]
            running: false
            stdout: SplitParser {
                onRead: data => {
                    try {
                        var obj = JSON.parse(data);
                        var lastIdx = chatModel.count - 1;
                        var lastMsg = chatModel.get(lastIdx);
                        
                        if (lastMsg && !lastMsg.isUser) {
                            if (obj.text) {
                                if (lastMsg.message === "Thinking...") {
                                    chatModel.setProperty(lastIdx, "message", obj.text);
                                } else {
                                    chatModel.setProperty(lastIdx, "message", lastMsg.message + obj.text);
                                }
                            } else if (obj.error) {
                                chatModel.setProperty(lastIdx, "message", "**Error:**\n\n" + obj.error);
                            }
                        }
                    } catch(e) {}
                    chatList.positionViewAtEnd();
                }
            }
        }
    }
}
