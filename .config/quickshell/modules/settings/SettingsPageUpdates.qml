import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import Quickshell
import Quickshell.Io
import "../common"

Item {
    id: root
    anchors.fill: parent

    // =========================================================================
    // State
    // =========================================================================
    property bool isChecking: true
    property bool updatesAvailable: false
    property int updateCount: 0
    property string lastCheckTime: "Just now"

    // =========================================================================
    // Color aliases from parent SettingsUI
    // =========================================================================

    // =========================================================================
    // Components
    // =========================================================================

    component UCard: Rectangle {
        default property alias content: cardCol.data
        Layout.fillWidth: true
        radius: 12
        color: cSurface
        border.color: cBorder
        border.width: 1
        implicitHeight: cardCol.implicitHeight + 32
        Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        clip: true

        ColumnLayout {
            id: cardCol
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.bottomMargin: 16
            spacing: 0
        }
    }

    // =========================================================================
    // Data processes
    // =========================================================================

    ListModel { id: packagesModel }

    Process {
        id: checkUpdatesProc
        command: ["bash", "-c", "checkupdates"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                packagesModel.clear();
                const textStr = text.trim();
                if (textStr === "") {
                    root.updateCount = 0;
                    root.updatesAvailable = false;
                } else {
                    const lines = textStr.split("\n");
                    root.updateCount = lines.length;
                    root.updatesAvailable = true;
                    
                    for (let i = 0; i < lines.length; i++) {
                        // Format: package oldver -> newver
                        const parts = lines[i].split(" ");
                        if (parts.length >= 4) {
                            packagesModel.append({
                                name: parts[0],
                                oldVer: parts[1],
                                newVer: parts[3]
                            });
                        }
                    }
                }
                root.isChecking = false;
                
                const d = new Date();
                root.lastCheckTime = d.toLocaleTimeString(Qt.locale(), Locale.ShortFormat);
            }
        }
    }

    Timer {
        interval: 60 * 60 * 1000 // 1 hour
        running: root.visible
        repeat: true
        onTriggered: {
            root.isChecking = true;
            checkUpdatesProc.running = true;
        }
    }

    // =========================================================================
    // UI
    // =========================================================================

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            width: parent.width
            spacing: 16

            // ── Hero Banner ─────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 140
                radius: 14
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { 
                        position: 0.0; 
                        color: root.isChecking ? Qt.rgba(cTextDim.r, cTextDim.g, cTextDim.b, 0.1) :
                              (root.updatesAvailable ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, Theme.isDark ? 0.18 : 0.12) : Qt.rgba(0.29, 0.87, 0.50, 0.15)) 
                    }
                    GradientStop { 
                        position: 1.0; 
                        color: root.isChecking ? Qt.rgba(cTextDim.r, cTextDim.g, cTextDim.b, 0.03) :
                              (root.updatesAvailable ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.04) : Qt.rgba(0.29, 0.87, 0.50, 0.04)) 
                    }
                }
                border.color: root.isChecking ? cBorder : (root.updatesAvailable ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.25) : Qt.rgba(0.29, 0.87, 0.50, 0.25))
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 300 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    spacing: 20

                    // Big Icon
                    Rectangle {
                        width: 64; height: 64; radius: 32
                        color: root.isChecking ? cBgElevated : (root.updatesAvailable ? cAccent : "#4ade80")
                        Behavior on color { ColorAnimation { duration: 300 } }
                        
                        Text {
                            anchors.centerIn: parent
                            text: root.isChecking ? "\ueb13" : (root.updatesAvailable ? "\uea20" : "\uea5e")
                            font.family: "tabler-icons"
                            font.pixelSize: 32
                            color: root.isChecking ? cTextDim : "#ffffff"
                            
                            RotationAnimation on rotation {
                                running: root.isChecking
                                loops: Animation.Infinite; from: 0; to: 360; duration: 1000
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 4
                        Text {
                            text: root.isChecking ? "Checking for updates..." : 
                                 (root.updatesAvailable ? "Updates Available" : "You're up to date")
                            color: cText
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 22
                            font.weight: Font.Bold
                            font.letterSpacing: -0.5
                        }
                        Text {
                            text: root.isChecking ? "Fetching the latest repository data" : 
                                 (root.updatesAvailable ? root.updateCount + " packages can be upgraded" : "Your system has all the latest packages and security fixes.")
                            color: cTextDim
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 14
                        }
                        Item { Layout.preferredHeight: 4 }
                        Text {
                            text: "Last checked: " + root.lastCheckTime
                            color: cTextFaint
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 11
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Action Buttons
                    ColumnLayout {
                        spacing: 10
                        Layout.alignment: Qt.AlignVCenter

                        // Update Button
                        Rectangle {
                            visible: root.updatesAvailable && !root.isChecking
                            width: 140; height: 38; radius: 8
                            color: updateBtnMa.containsMouse ? Qt.rgba(cAccent.r*0.9, cAccent.g*0.9, cAccent.b*0.9, 1) : cAccent
                            Behavior on color { ColorAnimation { duration: 120 } }
                            RowLayout {
                                anchors.centerIn: parent; spacing: 8
                                Text { text: "\uea20"; font.family: "tabler-icons"; font.pixelSize: 16; color: "white" }
                                Text { text: "Install Updates"; color: "white"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.SemiBold }
                            }
                            MouseArea {
                                id: updateBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    // Launch kitty to run the update command
                                    Quickshell.execDetached(["kitty", "--class", "cupcake_updater", "-T", "System Update", "-e", "bash", "-c", "echo -e '\\033[1;34m[Cupcake Updater]\\033[0m Starting system update...'; sudo pacman -Syu; echo -e '\\n\\033[1;32mUpdates complete!\\033[0m Press enter to exit...'; read"]);
                                    
                                    // After clicking, check again soon to see if they updated
                                    checkUpdatesProc.running = true;
                                    root.isChecking = true;
                                }
                            }
                        }
                        
                        // Check Button
                        Rectangle {
                            visible: !root.isChecking
                            width: 140; height: 38; radius: 8
                            color: checkBtnMa.containsMouse ? cSurfaceHover : "transparent"
                            border.color: cBorder; border.width: 1
                            Behavior on color { ColorAnimation { duration: 120 } }
                            RowLayout {
                                anchors.centerIn: parent; spacing: 8
                                Text { text: "\ueb13"; font.family: "tabler-icons"; font.pixelSize: 16; color: cText }
                                Text { text: "Check Again"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            }
                            MouseArea {
                                id: checkBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.isChecking = true;
                                    packagesModel.clear();
                                    checkUpdatesProc.running = true;
                                }
                            }
                        }
                    }
                }
            }

            // ── Package List ─────────────────────────────────────────────
            UCard {
                visible: root.updatesAvailable
                
                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 8
                    Text {
                        text: "AVAILABLE UPGRADES"
                        color: cTextDim
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                    }
                }

                Repeater {
                    model: packagesModel
                    delegate: Item {
                        Layout.fillWidth: true
                        implicitHeight: 48
                        
                        Rectangle {
                            anchors.fill: parent; anchors.leftMargin: -10; anchors.rightMargin: -10; radius: 6
                            color: rowMa.containsMouse ? cSurfaceHover : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            spacing: 12

                            Rectangle {
                                width: 32; height: 32; radius: 8
                                color: cBgElevated
                                Text { anchors.centerIn: parent; text: "\ueb10"; font.family: "tabler-icons"; font.pixelSize: 16; color: cTextDim }
                            }

                            Text {
                                text: model.name
                                color: cText
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                Layout.preferredWidth: 200
                                elide: Text.ElideRight
                            }
                            
                            Rectangle {
                                height: 24; radius: 6
                                width: oldVerText.implicitWidth + 16
                                color: cBgElevated; border.color: cBorder; border.width: 1
                                Text {
                                    id: oldVerText
                                    anchors.centerIn: parent
                                    text: model.oldVer
                                    color: cTextDim
                                    font.family: Theme.monoFontFamily; font.pixelSize: 11
                                }
                            }
                            
                            Text { text: "\uea61"; font.family: "tabler-icons"; font.pixelSize: 14; color: cTextFaint }
                            
                            Rectangle {
                                height: 24; radius: 6
                                width: newVerText.implicitWidth + 16
                                color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.1)
                                border.color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.2); border.width: 1
                                Text {
                                    id: newVerText
                                    anchors.centerIn: parent
                                    text: model.newVer
                                    color: cAccent
                                    font.family: Theme.monoFontFamily; font.pixelSize: 11; font.weight: Font.Medium
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }

                        MouseArea { id: rowMa; anchors.fill: parent; hoverEnabled: true }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left; anchors.right: parent.right
                            height: 1; color: cBorder; opacity: 0.5
                            visible: index < packagesModel.count - 1
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 24 }
        }
    }
}
