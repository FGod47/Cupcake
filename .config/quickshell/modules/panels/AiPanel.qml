import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../../theme"
import "../common"
import "../settings"

PanelWindow {
    id: aiWindow
    readonly property string homeDir: Quickshell.env("HOME")
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
    margins.top: 50
    margins.bottom: 15

    property bool hasKey: false
    property bool isImageMode: false

    function sendMessage() {
        if (promptInput.text.trim() === "") return;
        
        var userText = promptInput.text.trim();
        
        if (!hasKey) {
            chatModel.append({ isUser: true, message: userText, imagePath: "" });
            chatModel.append({ isUser: false, message: "**Error:** You haven't added your API key yet!\n\nPlease open the Settings app (Super + P -> Settings), go to the AI tab, and save your key there.", imagePath: "" });
            promptInput.text = "";
            chatList.positionViewAtEnd();
            return;
        }

        chatModel.append({ isUser: true, message: userText, imagePath: "" });
        
        if (aiWindow.isImageMode) {
            chatModel.append({ isUser: false, message: "Generating image...", imagePath: "" });
            geminiProcess.command = ["python3", aiWindow.homeDir + "/.config/quickshell/gemini.py", "--image", userText];
        } else {
            chatModel.append({ isUser: false, message: "Thinking...", imagePath: "" });
            geminiProcess.command = ["python3", aiWindow.homeDir + "/.config/quickshell/gemini.py", userText];
        }
        
        promptInput.text = "";
        chatList.positionViewAtEnd();
        
        geminiProcess.running = true;
    }

    // Main sliding container (Custom styling)
    Rectangle {
        id: container
        width: 450
        height: parent.height
        radius: 30
        color: Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.globalOpacity) // Deep background
        clip: true

        states: [
            State {
                name: "open"
                when: globalState.aiPanelVisible
                PropertyChanges { target: container; x: 10 }
            },
            State {
                name: "closed"
                when: !globalState.aiPanelVisible
                PropertyChanges { target: container; x: -470 }
            }
        ]
        
        transitions: [
            Transition {
                from: "closed"; to: "open"
                NumberAnimation { properties: "x"; duration: 400; easing.type: Easing.OutExpo }
            },
            Transition {
                from: "open"; to: "closed"
                NumberAnimation { properties: "x"; duration: 400; easing.type: Easing.OutExpo }
            }
        ]

        ColumnLayout {
            anchors.fill: parent
            anchors.bottomMargin: chatModel.count > 0 ? 100 : 0
            spacing: 0

            // 1. HEADER (Custom layout)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                Layout.alignment: Qt.AlignTop
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15

                    // Gemini Icon
                    Text {
                        text: "\uf6d7" // ti-sparkles
                        font.family: "tabler-icons"
                        font.weight: Theme.defaultFontWeight; font.pixelSize: 24
                        color: Theme.colPrimary
                    }

                    // Spacer to push buttons to the right
                    Item { Layout.fillWidth: true }

                    // Clear Chat Button
                    Rectangle {
                        width: 36; height: 36; radius: 18
                        color: clearMouse.containsMouse ? Theme.colSurfaceContainerHigh : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "\ueb8b" // ti-eraser
                            font.family: "tabler-icons"
                            font.weight: Theme.defaultFontWeight; font.pixelSize: 18
                            color: Theme.colOnSurfaceVariant
                        }
                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                chatModel.clear();
                            }
                        }
                    }

                    // Settings Button
                    Rectangle {
                        width: 36; height: 36; radius: 18
                        color: settingsMouse.containsMouse ? Theme.colSurfaceContainerHigh : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "\ueb20" // ti-settings
                            font.family: "tabler-icons"
                            font.weight: Theme.defaultFontWeight; font.pixelSize: 18
                            color: Theme.colOnSurfaceVariant
                        }
                        MouseArea {
                            id: settingsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["bash", "-c", "echo 1 > /tmp/cupcake_settings"]);
                                Qt.quit();
                            }
                        }
                    }
                }
            }


            // 2. CHAT HISTORY (Custom bubble styling)
            ListModel {
                id: chatModel
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

            // The actual Chat List
            ListView {
                id: chatList
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: chatModel.count > 0
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
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 16
                        
                        // Spacer to push user messages to the right
                        Item {
                            Layout.fillWidth: true
                            visible: model.isUser
                        }

                        // AI Avatar (only show on left for AI)
                        Rectangle {
                            visible: !model.isUser
                            Layout.alignment: Qt.AlignTop
                            width: 32; height: 32; radius: 16
                            color: "transparent"
                            
                            Text {
                                anchors.centerIn: parent
                                text: "\uf6d7" // ti-sparkles
                                font.family: "tabler-icons"
                                font.weight: Theme.defaultFontWeight; font.pixelSize: 20
                                color: "#8AB4F8"
                            }
                        }

                        // Message Content
                        Item {
                            id: bubbleItem
                            Layout.maximumWidth: chatList.width - 100
                            Layout.preferredWidth: model.imagePath ? 320 : (msgText.implicitWidth + (model.isUser ? 24 : 8))
                            Layout.preferredHeight: model.imagePath ? 320 : (msgText.implicitHeight + (model.isUser ? 24 : 8))
                            
                            // User gets a pill background, AI gets transparent
                            Rectangle {
                                anchors.fill: parent
                                visible: model.isUser
                                radius: 18
                                color: Theme.colSurfaceContainerHigh
                            }

                            Image {
                                id: genImage
                                anchors.fill: parent
                                anchors.margins: 4
                                source: model.imagePath ? model.imagePath : ""
                                fillMode: Image.PreserveAspectFit
                                visible: model.imagePath ? true : false
                                
                                Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"
                                    border.color: Theme.colOutline
                                    border.width: 1
                                    radius: 12
                                }
                            }

                            Text {
                                id: msgText
                                anchors.fill: parent
                                anchors.margins: model.isUser ? 12 : 4
                                anchors.topMargin: model.isUser ? 12 : 6
                                text: model.message
                                visible: !model.imagePath
                                textFormat: Text.MarkdownText
                                wrapMode: Text.WordWrap
                                color: Theme.colOnSurface
                                font.weight: Theme.defaultFontWeight; font.pixelSize: 15
                                font.family: Theme.defaultFontFamily
                                lineHeight: 1.4
                                
                                onLinkActivated: Qt.openUrlExternally(link)
                            }
                        }

                        // Spacer to push AI messages to the left
                        Item {
                            Layout.fillWidth: true
                            visible: !model.isUser
                        }
                    }
                }
            }

        } // End of ColumnLayout

        // Empty State / Gemini Welcome (Absolute positioning)
        ColumnLayout {
            id: welcomeGroup
            anchors.horizontalCenter: parent.horizontalCenter
            y: inputBox.y - height - 30
            opacity: chatModel.count === 0 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 400 } }
            spacing: 8
            
            Text {
                id: helloText
                text: "Hello"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 48
                font.weight: 800
                visible: false
            }
            
            LinearGradient {
                Layout.alignment: Qt.AlignHCenter
                width: helloText.implicitWidth
                height: helloText.implicitHeight
                source: helloText
                start: Qt.point(0, 0)
                end: Qt.point(width, 0)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#5a7df8" }
                    GradientStop { position: 0.5; color: "#b966e5" }
                    GradientStop { position: 1.0; color: "#e86e7a" }
                }
            }
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "How can I help you today?"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 22
                font.weight: 600
                color: Theme.colOnSurfaceVariant
            }
        }

        // 3. INPUT BOX (Absolute positioning)
        Rectangle {
            id: inputBox
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            height: 60
            
            // Explicit Y positioning using States to prevent initial load drop-in bugs
            states: [
                State {
                    name: "empty"
                    when: chatModel.count === 0
                    PropertyChanges { target: inputBox; y: container.height * 0.58 }
                },
                State {
                    name: "chatting"
                    when: chatModel.count > 0
                    PropertyChanges { target: inputBox; y: container.height - 80 }
                }
            ]
            transitions: [
                Transition {
                    from: "empty"
                    to: "chatting"
                    NumberAnimation { property: "y"; duration: 500; easing.type: Easing.OutExpo }
                }
            ]

            radius: 30
            color: Theme.colSurfaceContainerHigh // Solid dark gray
            border.width: 0

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 10

                // Image Mode Toggle (+ icon)
                Rectangle {
                    width: 44; height: 44; radius: 22
                    color: aiWindow.isImageMode ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb0b" // ti-plus
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 18
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: aiWindow.isImageMode = !aiWindow.isImageMode
                    }
                }

                TextField {
                    id: promptInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: aiWindow.isImageMode ? "Describe an image..." : "Ask Gemini"
                    placeholderTextColor: Theme.colOnSurfaceVariant
                    color: Theme.colOnSurface
                    font.weight: Theme.defaultFontWeight; font.pixelSize: 16
                    font.family: Theme.defaultFontFamily
                    background: Item {}
                    verticalAlignment: TextInput.AlignVCenter
                    leftPadding: 5
                    
                    onAccepted: aiWindow.sendMessage()
                }

                // Model Selector Pill (Moved from Header)
                ComboBox {
                    id: modelCombo
                    Layout.preferredWidth: 110
                    Layout.preferredHeight: 36
                    Layout.alignment: Qt.AlignVCenter
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
                        color: Qt.rgba(1, 1, 1, 0.08)
                        radius: 18
                    }
                    
                    contentItem: Text {
                        text: modelCombo.currentText.replace("gemini-", "").replace("-flash", " Flash").replace("-pro", " Pro") + " "
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 13
                        font.weight: 600
                        color: Theme.colOnSurface
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }

                    popup: Popup {
                        y: -implicitHeight - 10
                        x: -120 // Shift left so it aligns nicer with the pill
                        width: 250
                        implicitHeight: contentItem.implicitHeight + 16
                        padding: 8

                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: modelCombo.popup.visible ? modelCombo.delegateModel : null
                            currentIndex: modelCombo.highlightedIndex
                            ScrollIndicator.vertical: ScrollIndicator { }
                        }

                        background: Rectangle {
                            color: Theme.colSurfaceContainerHigh
                            border.color: Theme.colOutline
                            border.width: 1
                            radius: 20
                        }
                    }

                    delegate: ItemDelegate {
                        width: modelCombo.popup.width - 16
                        height: 60
                        highlighted: modelCombo.highlightedIndex === index

                        background: Rectangle {
                            color: highlighted ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                            radius: 12
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 15

                            Text {
                                text: modelCombo.currentIndex === index ? "" : ""
                                font.family: Theme.monoFontFamily
                                font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                                color: Theme.colOnSurfaceVariant
                                Layout.preferredWidth: 20
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                
                                Text {
                                    text: modelData.replace("gemini-", "").replace("-flash", " Flash").replace("-pro", " Pro")
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 15
                                    font.weight: 600
                                    color: Theme.colOnSurface
                                }
                                
                                Text {
                                    text: {
                                        if (modelData.includes("3.5-flash")) return "All-around help";
                                        if (modelData.includes("flash-latest")) return "Fastest answers";
                                        if (modelData.includes("2.5-pro")) return "Advanced logic and code";
                                        if (modelData.includes("2.5-flash")) return "Fast performance";
                                        if (modelData.includes("2.0-flash")) return "Legacy fast model";
                                        if (modelData.includes("pro-latest")) return "Latest pro model";
                                        return "Standard";
                                    }
                                    font.family: Theme.defaultFontFamily
                                    font.weight: Theme.defaultFontWeight; font.pixelSize: 12
                                    color: Theme.colOnSurfaceVariant
                                }
                            }
                            
                            Rectangle {
                                visible: modelData.includes("3.5") || modelData.includes("latest")
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 20
                                radius: 10
                                color: "transparent"
                                border.color: Theme.colOutline
                                border.width: 1
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "New"
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 10
                                    font.weight: 600
                                    color: Theme.colOnSurfaceVariant
                                }
                            }
                        }
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

                // Send Button / Microphone
                Rectangle {
                    width: 44; height: 44; radius: 22
                    color: promptInput.text.length > 0 ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                    
                    Text {
                        anchors.centerIn: parent
                        text: promptInput.text.length > 0 ? "" : "" // Up arrow if typing, else Mic
                        color: promptInput.text.length > 0 ? Theme.colOnSurface : Theme.colOnSurfaceVariant
                        font.family: Theme.monoFontFamily
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

        // Backend AI Streaming Process
        Process {
            id: geminiProcess
            command: ["python3", aiWindow.homeDir + "/.config/quickshell/gemini.py", ""]
            running: false
            stdout: SplitParser {
                onRead: data => {
                    try {
                        var obj = JSON.parse(data);
                        var lastIdx = chatModel.count - 1;
                        var lastMsg = chatModel.get(lastIdx);
                        
                        if (lastMsg && !lastMsg.isUser) {
                            if (obj.image) {
                                chatModel.setProperty(lastIdx, "message", "");
                                chatModel.setProperty(lastIdx, "imagePath", obj.image);
                            } else if (obj.text) {
                                if (lastMsg.message === "Thinking..." || lastMsg.message === "Generating image...") {
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
