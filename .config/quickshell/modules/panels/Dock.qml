import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../common"
import "../settings"

PanelWindow {
    id: dockWindow
    readonly property string homeDir: Quickshell.env("HOME")
    anchors {
        bottom: true
    }
    
    // In Wayland Layer Shell, if left and right are not anchored, it auto-centers horizontally!
    
    required property var modelData
    screen: modelData
    
    // Make the window exact size of the dock + edge margin
    implicitWidth: dockLayout.implicitWidth + (globalState.dockMainAxisPadding + globalState.dockEndsMargin) * 2
    implicitHeight: visualDock.height + globalState.dockEdgeMargin
    
    color: "transparent"
    exclusiveZone: globalState.dockReserveSpace ? ((globalState.dockAutoHide && !hoverHandler.hovered) ? 0 : implicitHeight) : 0 // 0 means do not reserve space, float over maximized apps

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
            
            // Slide up when hovered, down when hidden (leave 1px invisible trigger area)
            y: (globalState.dockAutoHide && !hoverHandler.hovered) ? parent.height - 1 : 0
            Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

            // Crucial: The height expands to reach the bottom of the screen as it slides up,
            // ensuring the mouse (which is at the bottom of the screen) stays inside the hover area!
            height: parent.height - y

            HoverHandler {
                id: hoverHandler
            }

            Rectangle {
                id: visualDock
                y: (globalState.dockAutoHide && !hoverHandler.hovered) ? 1 : 0 // Push completely out of window bounds when hidden
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: globalState.dockIconSize + globalState.dockCrossAxisPadding * 2
                color: Qt.rgba(Theme.colSurfaceContainer.r, Theme.colSurfaceContainer.g, Theme.colSurfaceContainer.b, globalState.dockOpacity)
                radius: globalState.dockRadius
            }

            RowLayout {
                id: dockLayout
                anchors.centerIn: visualDock
                spacing: globalState.dockItemSpacing

                // Start Launcher
                RowLayout {
                    visible: globalState.dockLauncherPosition !== "End"
                    spacing: globalState.dockItemSpacing

                    Item {
                        width: globalState.dockIconSize; height: globalState.dockIconSize

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.max(24, globalState.dockIconSize - 6); height: Math.max(24, globalState.dockIconSize - 6); radius: width / 2
                            color: mouseAreaStartLauncher.containsMouse ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.22) : Qt.rgba(1, 1, 1, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\uebb6"
                                font.family: "tabler-icons"
                                font.pixelSize: Math.max(12, parent.width * 0.5)
                                color: Theme.colPrimary
                            }
                            scale: mouseAreaStartLauncher.containsMouse ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150 } }
                            
                            MouseArea {
                                id: mouseAreaStartLauncher
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached([dockWindow.homeDir + "/.config/cupcake/scripts/toggle_app_launcher.sh"])
                            }
                        }
                    }

                    Rectangle { width: 2; height: 32; color: Theme.colSurfaceVariant; radius: 1 }
                }

                // Pinned Apps
                Repeater {
                    model: globalState.dockPinnedAppsEnabled ? globalState.dockPinnedApps : []

                    delegate: Rectangle {
                        id: pinnedDelegate
                        required property var modelData
                        
                        // Find if this pinned app is currently running
                        property var toplevel: null

                        Instantiator {
                            model: ToplevelManager.toplevels
                            delegate: QtObject {
                                required property var modelData
                                property var tl: modelData
                                Component.onCompleted: {
                                    if (tl && tl.appId === pinnedDelegate.modelData.appId) {
                                        pinnedDelegate.toplevel = tl;
                                    }
                                }
                                Component.onDestruction: {
                                    if (pinnedDelegate.toplevel === tl) {
                                        pinnedDelegate.toplevel = null;
                                    }
                                }
                            }
                        }
                        
                        property bool isRunning: toplevel !== null
                        property bool isActive: isRunning && toplevel.activated
                        
                        width: globalState.dockIconSize; height: globalState.dockIconSize; radius: Math.min(12, globalState.dockIconSize / 4)
                        color: "transparent"
                        
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottomMargin: 2
                            width: isActive ? Math.min(24, globalState.dockIconSize / 2) : (isRunning ? 8 : 0)
                            height: 3; radius: 2
                            color: Theme.colPrimary
                            Behavior on width { NumberAnimation { duration: 200 } }
                            visible: globalState.dockShowDots
                        }

                        Image {
                            anchors.centerIn: parent
                            width: Math.max(16, globalState.dockIconSize - 16); height: Math.max(16, globalState.dockIconSize - 16)
                            source: "image://icon/" + modelData.appId
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            scale: mouseAreaPinned.containsMouse ? (globalState.dockMagnificationEnabled ? globalState.dockMagnificationScale : 1.0) : 1.0
                            Behavior on scale { NumberAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: mouseAreaPinned
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (isRunning) toplevel.activate();
                                else Quickshell.execDetached(["bash", "-c", modelData.exec]);
                            }
                        }
                    }
                }

                // Secondary Divider (Only visible if there are unpinned running apps)
                Rectangle {
                    width: 2; height: 32; radius: 1
                    color: Theme.colSurfaceVariant
                    visible: {
                        var hasUnpinned = false;
                        var pinnedIds = [];
                        if (globalState.dockPinnedAppsEnabled) {
                            for (var j = 0; j < globalState.dockPinnedApps.length; j++) {
                                pinnedIds.push(globalState.dockPinnedApps[j].appId);
                            }
                        }
                        for (var i = 0; i < ToplevelManager.toplevels.length; i++) {
                            if (!pinnedIds.includes(ToplevelManager.toplevels[i].appId)) {
                                hasUnpinned = true;
                                break;
                            }
                        }
                        return hasUnpinned;
                    }
                }

                // Running Apps (Unpinned)
                Repeater {
                    model: ToplevelManager.toplevels

                    delegate: Rectangle {
                        required property var modelData
                        
                        property bool isPinned: {
                            if (!globalState.dockPinnedAppsEnabled) return false;
                            for (var j = 0; j < globalState.dockPinnedApps.length; j++) {
                                if (globalState.dockPinnedApps[j].appId === modelData.appId) return true;
                            }
                            return false;
                        }
                        
                        visible: !isPinned
                        width: visible ? globalState.dockIconSize : 0
                        height: globalState.dockIconSize; radius: Math.min(12, globalState.dockIconSize / 4)
                        color: "transparent"
                        

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottomMargin: 2
                            width: modelData.activated ? Math.min(24, globalState.dockIconSize / 2) : 8
                            height: 3; radius: 2
                            color: Theme.colPrimary
                            Behavior on width { NumberAnimation { duration: 200 } }
                            visible: !isPinned && globalState.dockShowDots
                        }

                        Image {
                            anchors.centerIn: parent
                            width: Math.max(16, globalState.dockIconSize - 16); height: Math.max(16, globalState.dockIconSize - 16)
                            source: modelData.appId ? "image://icon/" + modelData.appId : ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            visible: !isPinned
                            scale: mouseAreaUnpinned.containsMouse ? (globalState.dockMagnificationEnabled ? globalState.dockMagnificationScale : 1.0) : 1.0
                            Behavior on scale { NumberAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: mouseAreaUnpinned
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.activate()
                            visible: !isPinned
                        }
                    }
                }

                // End Launcher
                RowLayout {
                    visible: globalState.dockLauncherPosition === "End"
                    spacing: globalState.dockItemSpacing

                    Rectangle { width: 2; height: Math.max(16, globalState.dockIconSize - 16); color: Theme.colSurfaceVariant; radius: 1 }

                    Item {
                        width: globalState.dockIconSize; height: globalState.dockIconSize

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.max(24, globalState.dockIconSize - 6); height: Math.max(24, globalState.dockIconSize - 6); radius: width / 2
                            color: mouseAreaEndLauncher.containsMouse ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.22) : Qt.rgba(1, 1, 1, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\uebb6"
                                font.family: "tabler-icons"
                                font.pixelSize: Math.max(12, parent.width * 0.5)
                                color: Theme.colPrimary
                            }
                            scale: mouseAreaEndLauncher.containsMouse ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150 } }
                            
                            MouseArea {
                                id: mouseAreaEndLauncher
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached([dockWindow.homeDir + "/.config/cupcake/scripts/toggle_app_launcher.sh"])
                            }
                        }
                    }
                }
            }
        }
    }
}
