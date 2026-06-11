import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "theme"

PanelWindow {
    id: dockWindow
    anchors {
        bottom: true
    }
    
    // In Wayland Layer Shell, if left and right are not anchored, it auto-centers horizontally!
    
    required property var modelData
    screen: modelData
    
    // Make the window exact size of the dock + 12px bottom padding
    implicitWidth: dockLayout.implicitWidth + 32
    implicitHeight: 48 + 24
    
    color: "transparent"
    exclusiveZone: 0 // 0 means do not reserve space, float over maximized apps

    // Use Region mask to restrict Wayland input exclusively to the visual dock!
    // This allows clicks to pass through to the desktop when the dock is hidden.
    mask: Region {
        item: hoverRegion
    }

    Item {
        anchors.fill: parent

        Item {
            id: hoverRegion
            width: parent.width
            
            // Slide up when hovered, down when hidden
            y: hoverHandler.hovered ? 0 : 66
            Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

            // Crucial: The height expands to reach the bottom of the screen as it slides up,
            // ensuring the mouse (which is at the bottom of the screen) stays inside the hover area!
            height: parent.height - y

            HoverHandler {
                id: hoverHandler
            }

            Rectangle {
                id: visualDock
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: 64
                color: Theme.colSurfaceContainer
                radius: 20
                border.color: Theme.colPrimary
                border.width: 1

            RowLayout {
                id: dockLayout
                anchors.centerIn: parent
                spacing: 12

                // Launcher Button
                Rectangle {
                    width: 48
                    height: 48
                    radius: 12
                    color: Theme.colPrimary
                    
                    Text {
                        anchors.centerIn: parent
                        text: "" // App grid icon
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 24
                        color: Theme.colOnPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.scale = 1.05
                        onExited: parent.scale = 1.0
                        onClicked: Quickshell.execDetached(["/home/one/.config/cupcake/scripts/toggle_app_launcher.sh"])
                        Behavior on scale { NumberAnimation { duration: 150 } }
                    }
                }

                // Divider
                Rectangle {
                    width: 2
                    height: 32
                    color: Theme.colSurfaceVariant
                    radius: 1
                }

                // Running Apps
                Repeater {
                    model: ToplevelManager.toplevels

                    delegate: Rectangle {
                        required property var modelData
                        
                        width: 48
                        height: 48
                        radius: 12
                        color: "transparent"
                        
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width
                            height: parent.height
                            radius: 12
                            color: Theme.colSurfaceContainerHigh
                            opacity: modelData.activated ? 1.0 : (mouseArea.containsMouse ? 0.5 : 0.0)
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        // Indicator pill
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottomMargin: 2
                            width: modelData.activated ? 24 : 8
                            height: 3
                            radius: 2
                            color: Theme.colPrimary
                            Behavior on width { NumberAnimation { duration: 200 } }
                        }

                        Image {
                            anchors.centerIn: parent
                            width: 32
                            height: 32
                            // Try to load the icon via quickshell's icon protocol
                            source: modelData.appId ? "image://icon/" + modelData.appId : ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                modelData.activate()
                            }
                        }
                    }
                }
            }
            }
        }
    }
}
