import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "theme"

PanelWindow {
    id: aiWindow
    exclusionMode: ExclusionMode.Ignore
    
    // Anchor to the right edge of the screen
    anchors {
        top: true
        bottom: true
        left: true
    }

    implicitWidth: 470
    color: "transparent"
    visible: globalState.aiPanelVisible || container.x > -460
    margins.top: 10
    margins.bottom: 10

    // Main sliding container
    Rectangle {
        id: container
        width: 450
        height: parent.height
        radius: 24
        color: Theme.colSurface
        border.color: "#80000000"
        border.width: 1
        clip: true

        // Slide animation based on globalState visibility
        x: globalState.aiPanelVisible ? 10 : -470
        Behavior on x {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutBack // Smooth bouncy slide-in
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            // Header
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "✨ Gemini AI"
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 22
                    font.weight: 700
                    color: Theme.colPrimary
                    Layout.fillWidth: true
                }
                
                // Close Button
                Rectangle {
                    width: 30; height: 30; radius: 15
                    color: closeMouse.containsMouse ? Theme.colSurfaceContainerHigh : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: "JetBrainsMono Nerd Font Propo"
                        color: Theme.colOnSurface
                        font.pixelSize: 16
                    }
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: globalState.aiPanelVisible = false
                    }
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.colOutline
                opacity: 0.3
            }

            // Chat View (Placeholder)
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                ColumnLayout {
                    width: parent.width
                    spacing: 20

                    // Placeholder AI message
                    Rectangle {
                        Layout.alignment: Qt.AlignLeft
                        Layout.maximumWidth: container.width - 80
                        Layout.preferredHeight: aiMsg.implicitHeight + 30
                        radius: 16
                        color: Theme.colSurfaceContainerHigh
                        
                        Text {
                            id: aiMsg
                            anchors.fill: parent
                            anchors.margins: 15
                            text: "Hello! I'm your native Quickshell AI assistant.\n\nI'm ready to help you write code, answer questions, and control your Cupcake desktop. What would you like to build today?"
                            color: Theme.colOnSurface
                            font.pixelSize: 14
                            font.family: "Inter"
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            // Input Area
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                radius: 25
                color: Theme.colSurfaceContainerHigh
                border.color: Theme.colOutline
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 5

                    TextField {
                        id: promptInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: "Ask Gemini anything..."
                        color: Theme.colOnSurface
                        font.pixelSize: 14
                        font.family: "Inter"
                        background: Item {} // Remove default background
                        verticalAlignment: TextInput.AlignVCenter
                        leftPadding: 15
                    }

                    Rectangle {
                        width: 40; height: 40; radius: 20
                        color: Theme.colPrimary
                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: Theme.colOnPrimary
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 16
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }
    }
}
