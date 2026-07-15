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
    property bool isCheckingSys: true
    property bool sysUpdatesAvailable: false
    property int sysUpdateCount: 0
    property string lastSysCheckTime: "Just now"

    property bool isCheckingCupcake: true
    property bool cupcakeUpdatesAvailable: false
    property int cupcakeUpdateCount: 0
    property string lastCupcakeCheckTime: "Just now"

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
    ListModel { id: cupcakeLogsModel }

    Process {
        id: checkSysUpdatesProc
        command: ["bash", "-c", "checkupdates"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                packagesModel.clear();
                const textStr = text.trim();
                if (textStr === "") {
                    root.sysUpdateCount = 0;
                    root.sysUpdatesAvailable = false;
                } else {
                    const lines = textStr.split("\n");
                    root.sysUpdateCount = lines.length;
                    root.sysUpdatesAvailable = true;
                    
                    for (let i = 0; i < lines.length; i++) {
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
                root.isCheckingSys = false;
                const d = new Date();
                root.lastSysCheckTime = d.toLocaleTimeString(Qt.locale(), Locale.ShortFormat);
            }
        }
    }

    Process {
        id: checkCupcakeUpdatesProc
        command: ["bash", "-c", "cd ~/Cupcake && git fetch -q && git log --pretty=format:'%h|%s|%ar' HEAD..@{u} 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                cupcakeLogsModel.clear();
                const textStr = text.trim();
                if (textStr === "") {
                    root.cupcakeUpdateCount = 0;
                    root.cupcakeUpdatesAvailable = false;
                } else {
                    const lines = textStr.split("\n");
                    root.cupcakeUpdateCount = lines.length;
                    root.cupcakeUpdatesAvailable = true;
                    
                    for (let i = 0; i < lines.length; i++) {
                        const parts = lines[i].split("|");
                        if (parts.length >= 3) {
                            cupcakeLogsModel.append({
                                hash: parts[0],
                                subject: parts[1],
                                timeago: parts[2]
                            });
                        }
                    }
                }
                root.isCheckingCupcake = false;
                
                const d = new Date();
                root.lastCupcakeCheckTime = d.toLocaleTimeString(Qt.locale(), Locale.ShortFormat);
            }
        }
    }

    Timer {
        interval: 60 * 60 * 1000 // 1 hour
        running: root.visible
        repeat: true
        onTriggered: {
            root.isCheckingSys = true;
            root.isCheckingCupcake = true;
            checkSysUpdatesProc.running = true;
            checkCupcakeUpdatesProc.running = true;
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
            spacing: 24

            // ── Cupcake (Dotfiles) Update Hero ──────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 120
                radius: 14
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { 
                        position: 0.0; 
                        color: root.isCheckingCupcake ? Qt.rgba(cTextDim.r, cTextDim.g, cTextDim.b, 0.1) :
                              (root.cupcakeUpdatesAvailable ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, Theme.isDark ? 0.18 : 0.12) : Qt.rgba(0.29, 0.87, 0.50, 0.15)) 
                    }
                    GradientStop { 
                        position: 1.0; 
                        color: root.isCheckingCupcake ? Qt.rgba(cTextDim.r, cTextDim.g, cTextDim.b, 0.03) :
                              (root.cupcakeUpdatesAvailable ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.04) : Qt.rgba(0.29, 0.87, 0.50, 0.04)) 
                    }
                }
                border.color: root.isCheckingCupcake ? cBorder : (root.cupcakeUpdatesAvailable ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.25) : Qt.rgba(0.29, 0.87, 0.50, 0.25))
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 300 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    spacing: 20

                    // Cupcake Icon
                    Rectangle {
                        width: 56; height: 56; radius: 28
                        color: root.isCheckingCupcake ? cBgElevated : (root.cupcakeUpdatesAvailable ? cAccent : "#4ade80")
                        Behavior on color { ColorAnimation { duration: 300 } }
                        
                        Text {
                            anchors.centerIn: parent
                            text: root.isCheckingCupcake ? "\ueb13" : "\ueb7d" // cup/code icon
                            font.family: "tabler-icons"
                            font.pixelSize: 28
                            color: root.isCheckingCupcake ? cTextDim : "#ffffff"
                            
                            RotationAnimation on rotation {
                                running: root.isCheckingCupcake
                                loops: Animation.Infinite; from: 0; to: 360; duration: 1000
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 4
                        Text {
                            text: "Cupcake Theme Updates"
                            color: cTextFaint
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            font.capitalization: Font.AllUppercase
                        }
                        Text {
                            text: root.isCheckingCupcake ? "Checking for theme updates..." : 
                                 (root.cupcakeUpdatesAvailable ? "Theme Updates Available" : "Cupcake is up to date")
                            color: cText
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            font.letterSpacing: -0.5
                        }
                        Text {
                            text: root.isCheckingCupcake ? "Fetching the latest git commits" : 
                                 (root.cupcakeUpdatesAvailable ? "There are " + root.cupcakeUpdateCount + " new commits ready to pull." : "You have the latest dotfiles configuration.")
                            color: cTextDim
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 13
                        }
                        Item { Layout.preferredHeight: 2 }
                        Text {
                            text: "Last checked: " + root.lastCupcakeCheckTime
                            color: cTextFaint
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 10
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        spacing: 10
                        Layout.alignment: Qt.AlignVCenter

                        // Update Button
                        Rectangle {
                            visible: root.cupcakeUpdatesAvailable && !root.isCheckingCupcake
                            width: 140; height: 38; radius: 8
                            color: updateCcBtnMa.containsMouse ? Qt.rgba(cAccent.r*0.9, cAccent.g*0.9, cAccent.b*0.9, 1) : cAccent
                            Behavior on color { ColorAnimation { duration: 120 } }
                            RowLayout {
                                anchors.centerIn: parent; spacing: 8
                                Text { text: "\uea20"; font.family: "tabler-icons"; font.pixelSize: 16; color: "white" }
                                Text { text: "Update Theme"; color: "white"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.SemiBold }
                            }
                            MouseArea {
                                id: updateCcBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached(["kitty", "--class", "cupcake_updater", "-T", "Theme Update", "-e", "bash", "-c", "echo -e '\\033[1;34m[Cupcake Updater]\\033[0m Updating theme dotfiles...'; cd ~/Cupcake && git pull && cp -r .config/quickshell/* ~/.config/quickshell/ && echo -e '\\n\\033[1;32mUpdates complete! Restarting UI...\\033[0m'; sleep 1; pkill -x quickshell; quickshell > /dev/null 2>&1 &"]);
                                    checkCupcakeUpdatesProc.running = true;
                                    root.isCheckingCupcake = true;
                                }
                            }
                        }
                        
                        // Check Button
                        Rectangle {
                            visible: !root.isCheckingCupcake
                            width: 140; height: 38; radius: 8
                            color: checkCcBtnMa.containsMouse ? cSurfaceHover : "transparent"
                            border.color: cBorder; border.width: 1
                            Behavior on color { ColorAnimation { duration: 120 } }
                            RowLayout {
                                anchors.centerIn: parent; spacing: 8
                                Text { text: "\ueb13"; font.family: "tabler-icons"; font.pixelSize: 16; color: cText }
                                Text { text: "Check Again"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            }
                            MouseArea {
                                id: checkCcBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.isCheckingCupcake = true;
                                    checkCupcakeUpdatesProc.running = true;
                                }
                            }
                        }
                    }
                }
            }

            // ── Cupcake Commit Logs ──────────────────────────────────────
            UCard {
                visible: root.cupcakeUpdatesAvailable
                
                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 8
                    Text {
                        text: "NEW COMMITS"
                        color: cTextDim
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                    }
                }

                Repeater {
                    model: cupcakeLogsModel
                    delegate: Item {
                        Layout.fillWidth: true
                        implicitHeight: 48
                        
                        Rectangle {
                            anchors.fill: parent; anchors.leftMargin: -10; anchors.rightMargin: -10; radius: 6
                            color: logRowMa.containsMouse ? cSurfaceHover : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            spacing: 12

                            Rectangle {
                                width: 32; height: 32; radius: 8
                                color: cBgElevated
                                Text { anchors.centerIn: parent; text: "\uea4e"; font.family: "tabler-icons"; font.pixelSize: 16; color: cTextDim } // git-commit icon
                            }

                            Rectangle {
                                height: 24; radius: 6
                                width: hashText.implicitWidth + 16
                                color: cBgElevated; border.color: cBorder; border.width: 1
                                Text {
                                    id: hashText
                                    anchors.centerIn: parent
                                    text: model.hash
                                    color: cAccent
                                    font.family: Theme.monoFontFamily; font.pixelSize: 11
                                }
                            }

                            Text {
                                text: model.subject
                                color: cText
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            
                            Text {
                                text: model.timeago
                                color: cTextFaint
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 11
                            }
                        }

                        MouseArea { id: logRowMa; anchors.fill: parent; hoverEnabled: true }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left; anchors.right: parent.right
                            height: 1; color: cBorder; opacity: 0.5
                            visible: index < cupcakeLogsModel.count - 1
                        }
                    }
                }
            }


            // ── System Packages Update Hero ──────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 120
                radius: 14
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { 
                        position: 0.0; 
                        color: root.isCheckingSys ? Qt.rgba(cTextDim.r, cTextDim.g, cTextDim.b, 0.1) :
                              (root.sysUpdatesAvailable ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, Theme.isDark ? 0.18 : 0.12) : Qt.rgba(0.29, 0.87, 0.50, 0.15)) 
                    }
                    GradientStop { 
                        position: 1.0; 
                        color: root.isCheckingSys ? Qt.rgba(cTextDim.r, cTextDim.g, cTextDim.b, 0.03) :
                              (root.sysUpdatesAvailable ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.04) : Qt.rgba(0.29, 0.87, 0.50, 0.04)) 
                    }
                }
                border.color: root.isCheckingSys ? cBorder : (root.sysUpdatesAvailable ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.25) : Qt.rgba(0.29, 0.87, 0.50, 0.25))
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 300 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    spacing: 20

                    // Big Icon
                    Rectangle {
                        width: 56; height: 56; radius: 28
                        color: root.isCheckingSys ? cBgElevated : (root.sysUpdatesAvailable ? cAccent : "#4ade80")
                        Behavior on color { ColorAnimation { duration: 300 } }
                        
                        Text {
                            anchors.centerIn: parent
                            text: root.isCheckingSys ? "\ueb13" : (root.sysUpdatesAvailable ? "\uea20" : "\uea5e")
                            font.family: "tabler-icons"
                            font.pixelSize: 28
                            color: root.isCheckingSys ? cTextDim : "#ffffff"
                            
                            RotationAnimation on rotation {
                                running: root.isCheckingSys
                                loops: Animation.Infinite; from: 0; to: 360; duration: 1000
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 4
                        Text {
                            text: "System Packages"
                            color: cTextFaint
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            font.capitalization: Font.AllUppercase
                        }
                        Text {
                            text: root.isCheckingSys ? "Checking for system updates..." : 
                                 (root.sysUpdatesAvailable ? "System Updates Available" : "System is up to date")
                            color: cText
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            font.letterSpacing: -0.5
                        }
                        Text {
                            text: root.isCheckingSys ? "Fetching the latest repository data" : 
                                 (root.sysUpdatesAvailable ? root.sysUpdateCount + " packages can be upgraded" : "Your system has all the latest packages and security fixes.")
                            color: cTextDim
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 13
                        }
                        Item { Layout.preferredHeight: 2 }
                        Text {
                            text: "Last checked: " + root.lastSysCheckTime
                            color: cTextFaint
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 10
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        spacing: 10
                        Layout.alignment: Qt.AlignVCenter

                        // Update Button
                        Rectangle {
                            visible: root.sysUpdatesAvailable && !root.isCheckingSys
                            width: 140; height: 38; radius: 8
                            color: updateSysBtnMa.containsMouse ? Qt.rgba(cAccent.r*0.9, cAccent.g*0.9, cAccent.b*0.9, 1) : cAccent
                            Behavior on color { ColorAnimation { duration: 120 } }
                            RowLayout {
                                anchors.centerIn: parent; spacing: 8
                                Text { text: "\uea20"; font.family: "tabler-icons"; font.pixelSize: 16; color: "white" }
                                Text { text: "Install Packages"; color: "white"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.SemiBold }
                            }
                            MouseArea {
                                id: updateSysBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached(["kitty", "--class", "cupcake_updater", "-T", "System Update", "-e", "bash", "-c", "echo -e '\\033[1;34m[Cupcake Updater]\\033[0m Starting system update...'; sudo pacman -Syu; echo -e '\\n\\033[1;32mUpdates complete!\\033[0m Press enter to exit...'; read"]);
                                    checkSysUpdatesProc.running = true;
                                    root.isCheckingSys = true;
                                }
                            }
                        }
                        
                        // Check Button
                        Rectangle {
                            visible: !root.isCheckingSys
                            width: 140; height: 38; radius: 8
                            color: checkSysBtnMa.containsMouse ? cSurfaceHover : "transparent"
                            border.color: cBorder; border.width: 1
                            Behavior on color { ColorAnimation { duration: 120 } }
                            RowLayout {
                                anchors.centerIn: parent; spacing: 8
                                Text { text: "\ueb13"; font.family: "tabler-icons"; font.pixelSize: 16; color: cText }
                                Text { text: "Check Again"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            }
                            MouseArea {
                                id: checkSysBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.isCheckingSys = true;
                                    packagesModel.clear();
                                    checkSysUpdatesProc.running = true;
                                }
                            }
                        }
                    }
                }
            }

            // ── Package List ─────────────────────────────────────────────
            UCard {
                visible: root.sysUpdatesAvailable
                
                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 8
                    Text {
                        text: "AVAILABLE PACKAGE UPGRADES"
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
