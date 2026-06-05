import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: notifPanel
    anchors {
        top: true
        right: true
        bottom: true
    }
    
    margins {
        top: 24
        right: 24
        bottom: 24
    }
    width: 340
    color: "transparent"
    visible: globalState.notifPanelVisible
    
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

    Item {
        anchors.fill: parent
        
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
        opacity: notifPanel.visible ? 1 : 0
        
        Rectangle {
            anchors.fill: parent
            color: "#181825"
            radius: 24
            border.color: "#33ffffff"
            border.width: 1
            clip: true
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                
                // Header Row
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Notifications"
                        color: "#cdd6f4"
                        font.family: "Inter"
                        font.pixelSize: 20
                        font.weight: 600
                        Layout.fillWidth: true
                    }
                    
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: closeHover.hovered ? "#313244" : "transparent"
                        Text {
                            text: ""
                            color: "#cdd6f4"
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 20
                            anchors.centerIn: parent
                        }
                        HoverHandler { id: closeHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: globalState.notifPanelVisible = false
                        }
                    }
                }
                
                // Header Separator
                Rectangle {
                    Layout.fillWidth: true
                    height: 2
                    color: "#22ffffff"
                    radius: 1
                }
                
                // Notification List
                ListView {
                    id: notifList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 8
                    ScrollBar.vertical: ScrollBar { active: false; policy: ScrollBar.AlwaysOff }
                    
                    model: globalState.notifications ? globalState.notifications.values : null
                    
                    // Empty State
                    Item {
                        anchors.centerIn: parent
                        width: parent.width
                        height: 200
                        visible: notifList.count === 0
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 16
                            Text {
                                text: "󰂚"
                                color: "#45475a"
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 64
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "No Notifications"
                                color: "#45475a"
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 20
                                font.weight: 600
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                    
                    delegate: Item {
                        width: notifList.width
                        height: cardContainer.implicitHeight
                        
                        Item {
                            id: cardContainer
                            width: notifList.width
                            implicitHeight: card.height
                            
                            NotificationCard {
                                id: card
                                notificationData: modelData
                                inPanel: true
                            }
                        }
                    }
                }
            }
        }
        
        // Floating Clear All Button
        Rectangle {
            visible: notifList.count > 0
            width: 48; height: 48; radius: 16
            color: clearHover.hovered ? "#f38ba8" : "#313244"
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 24
            
            Text {
                text: "󰎟" // Trash / Clear All icon
                color: clearHover.hovered ? "#11111b" : "#cdd6f4"
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 24
                anchors.centerIn: parent
            }
            HoverHandler { id: clearHover }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (globalState.notifications) {
                        var arr = globalState.notifications.values;
                        for (var i = arr.length - 1; i >= 0; i--) {
                            arr[i].dismiss();
                        }
                    }
                }
            }
        }
    }
}
