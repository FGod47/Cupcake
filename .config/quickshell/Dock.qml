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
        left: true
        right: true
    }
    
    required property var modelData
    screen: modelData
    
    implicitHeight: 74
    color: "transparent"
    exclusiveZone: implicitHeight // Reserve screen space

    Item {
        anchors.fill: parent

        Rectangle {
            anchors.centerIn: parent
            width: dockLayout.implicitWidth + 32
            height: dockLayout.implicitHeight + 16
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
