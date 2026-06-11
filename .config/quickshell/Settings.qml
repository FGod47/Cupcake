//@ pragma UseQApplication
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "theme"

ApplicationWindow {
    id: root
    visible: true
    title: "Cupcake Settings"
    minimumWidth: 800
    minimumHeight: 600
    width: 900
    height: 700
    color: Theme.colSurface
    font.family: "JetBrainsMono Nerd Font Propo"

    property int currentIndex: 0

    property bool navExpanded: root.width >= 900

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8 // end-4 uses tighter outer margins
        spacing: 8 // end-4 uses tight spacing between rail and content

        // Navigation Rail (No background, floats on window)
        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: navExpanded ? 200 : 72
            Behavior on Layout.preferredWidth { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                // Header / Icon
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    Text {
                        anchors.centerIn: parent
                        text: "🧁"
                        font.pixelSize: 32
                    }
                }

                Item { Layout.preferredHeight: 16 }

                // Nav Buttons
                component NavButton: Rectangle {
                    property string iconText
                    property string labelText
                    property int pageIndex

                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: 24 // Fully rounded pill shape like end-4
                    color: root.currentIndex === pageIndex ? Theme.colPrimary : "transparent"
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: navExpanded ? 16 : 0
                        spacing: 12
                        
                        Item {
                            Layout.preferredWidth: navExpanded ? implicitWidth : parent.width
                            Layout.fillHeight: true
                            Text {
                                anchors.centerIn: parent
                                text: iconText
                                color: root.currentIndex === pageIndex ? Theme.colOnPrimary : Theme.colOnSurfaceVariant
                                font.family: root.font.family
                                font.pixelSize: 20
                            }
                        }
                        
                        Text {
                            visible: navExpanded
                            text: labelText
                            color: root.currentIndex === pageIndex ? Theme.colOnPrimary : Theme.colOnSurfaceVariant
                            font.family: root.font.family
                            font.pixelSize: 15
                            font.bold: root.currentIndex === pageIndex
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentIndex = pageIndex
                        onEntered: if (root.currentIndex !== pageIndex) parent.color = Theme.colSurfaceContainerHigh
                        onExited: if (root.currentIndex !== pageIndex) parent.color = "transparent"
                    }
                }

                NavButton { iconText: ""; labelText: "Wallpapers"; pageIndex: 0 }
                NavButton { iconText: ""; labelText: "Top Bar"; pageIndex: 1 }
                NavButton { iconText: ""; labelText: "System"; pageIndex: 2 }
                NavButton { iconText: ""; labelText: "Network"; pageIndex: 3 }

                Item { Layout.fillHeight: true } // Spacer
            }
        }

        // Content Area (end-4 uses a rounded rectangle container for the active page)
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: Theme.colSurfaceContainerHigh
            radius: 24 // Large rounded corners like end-4
            clip: true

            // We use Loader to get page transition animations, or just StackLayout.
            // StackLayout doesn't animate easily without custom item delegates.
            // I will implement a quick fade for the StackLayout children.

            Item {
                anchors.fill: parent

                // PAGE 0: WALLPAPERS
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 0 ? 0 : 20
                    opacity: root.currentIndex === 0 ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 16

                        Text {
                            text: "Select Wallpaper"
                            color: Theme.colOnSurface
                            font.family: root.font.family
                            font.pixelSize: 32
                            font.bold: true
                        }

                        Text {
                            text: "Clicking a wallpaper will instantly apply it and regenerate your dynamic material colors."
                            color: Theme.colOnSurfaceVariant
                            font.family: root.font.family
                            font.pixelSize: 14
                            Layout.bottomMargin: 16
                        }

                        GridView {
                            id: grid
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            cellWidth: 250
                            cellHeight: 180
                            clip: true

                            model: FolderListModel {
                                folder: "file:///home/one/.config/cupcake/themes/cupcake-dark/walls"
                                nameFilters: ["*.png", "*.jpg", "*.jpeg"]
                            }

                            delegate: Item {
                                width: grid.cellWidth
                                height: grid.cellHeight

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    radius: 12
                                    color: "transparent"
                                    border.color: mouseArea.containsMouse ? Theme.colPrimary : "transparent"
                                    border.width: 3

                                    Image {
                                        id: img
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        source: fileUrl
                                        fillMode: Image.PreserveAspectCrop
                                        Behavior on scale { NumberAnimation { duration: 150 } }
                                        scale: mouseArea.containsMouse ? 1.05 : 1.0

                                        layer.enabled: true
                                        layer.effect: OpacityMask {
                                            maskSource: Rectangle {
                                                width: img.width
                                                height: img.height
                                                radius: 9
                                            }
                                        }
                                    }
                                    
                                    MouseArea {
                                        id: mouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Quickshell.execDetached(["/home/one/.local/bin/set-theme", filePath])
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // PAGE 1: TOP BAR
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 1 ? 0 : 20
                    opacity: root.currentIndex === 1 ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 16

                        Text {
                            text: "Top Bar Settings"
                            color: Theme.colOnSurface
                            font.family: root.font.family
                            font.pixelSize: 32
                            font.bold: true
                        }
                        
                        Text {
                            text: "Manage your Quickshell status bar"
                            color: Theme.colOnSurfaceVariant
                            font.family: root.font.family
                            font.pixelSize: 14
                            Layout.bottomMargin: 16
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            color: Theme.colSurfaceContainer
                            radius: 12
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                Text {
                                    text: "Restart Top Bar"
                                    color: Theme.colOnSurface
                                    font.family: root.font.family
                                    font.pixelSize: 16
                                    Layout.fillWidth: true
                                }
                                Button {
                                    text: "Restart"
                                    font.family: root.font.family
                                    onClicked: {
                                        Quickshell.execDetached(["/home/one/.config/cupcake/scripts/toggle_bar.sh"])
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // PAGE 2: SYSTEM
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 2 ? 0 : 20
                    opacity: root.currentIndex === 2 ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 16

                        Text {
                            text: "System Controls"
                            color: Theme.colOnSurface
                            font.family: root.font.family
                            font.pixelSize: 32
                            font.bold: true
                        }
                        
                        Text {
                            text: "Power and Session management"
                            color: Theme.colOnSurfaceVariant
                            font.family: root.font.family
                            font.pixelSize: 14
                            Layout.bottomMargin: 16
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            color: Theme.colSurfaceContainer
                            radius: 12
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                Text {
                                    text: "Color Mode (Light / Dark)"
                                    color: Theme.colOnSurface
                                    font.family: root.font.family
                                    font.pixelSize: 16
                                    Layout.fillWidth: true
                                }
                                
                                Switch {
                                    id: colorModeSwitch
                                    
                                    property bool initialized: false
                                    
                                    Process {
                                        command: ["cat", "/home/one/.config/cupcake/.color_mode"]
                                        running: true
                                        stdout: StdioCollector {
                                            onStreamFinished: {
                                                if (text.trim() === "light") {
                                                    colorModeSwitch.checked = true;
                                                } else {
                                                    colorModeSwitch.checked = false;
                                                }
                                                colorModeSwitch.initialized = true;
                                            }
                                        }
                                    }
                                    
                                    onCheckedChanged: {
                                        if (!initialized) return;
                                        let newMode = checked ? "light" : "dark";
                                        Quickshell.execDetached(["bash", "-c", "echo '" + newMode + "' > ~/.config/cupcake/.color_mode && ~/.local/bin/set-theme"]);
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            color: Theme.colSurfaceContainer
                            radius: 12
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                Text {
                                    text: "Reload Hyprland Config"
                                    color: Theme.colOnSurface
                                    font.family: root.font.family
                                    font.pixelSize: 16
                                    Layout.fillWidth: true
                                }
                                Button {
                                    text: "Reload"
                                    font.family: root.font.family
                                    onClicked: Quickshell.execDetached(["hyprctl", "reload"])
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            color: Theme.colSurfaceContainer
                            radius: 12
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                Text {
                                    text: "Reboot System"
                                    color: Theme.colOnSurface
                                    font.family: root.font.family
                                    font.pixelSize: 16
                                    Layout.fillWidth: true
                                }
                                Button {
                                    text: "Reboot"
                                    font.family: root.font.family
                                    onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // PAGE 3: NETWORK
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 3 ? 0 : 20
                    opacity: root.currentIndex === 3 ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 16

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Wi-Fi Networks"
                                color: Theme.colOnSurface
                                font.family: root.font.family
                                font.pixelSize: 32
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            // Rescan Button
                            Rectangle {
                                width: 48; height: 48
                                radius: 12
                                color: Theme.colSurfaceContainerHigh
                                Text {
                                    anchors.centerIn: parent
                                    text: ""
                                    color: Theme.colOnSurface
                                    font.family: root.font.family
                                    font.pixelSize: 20
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: refreshProcess.running = true
                                }
                            }
                            
                            // Toggle Switch
                            Switch {
                                id: wifiSwitch
                                checked: true
                                onCheckedChanged: Quickshell.execDetached(["nmcli", "radio", "wifi", checked ? "on" : "off"])
                            }
                        }

                        // Background Process to list networks
                        Process {
                            id: refreshProcess
                            command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
                            running: true
                            environment: ({ LANG: "C", LC_ALL: "C" })
                            stdout: StdioCollector {
                                onStreamFinished: {
                                    wifiModel.clear();
                                    const textStr = text.trim();
                                    if (textStr === "") return;
                                    
                                    const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                                    const rep = new RegExp("\\\\:", "g");
                                    const rep2 = new RegExp(PLACEHOLDER, "g");
                                    const lines = textStr.split("\n");
                                    let seen = {};
                                    
                                    for (let i = 0; i < lines.length; i++) {
                                        const line = lines[i];
                                        if (line === "") continue;
                                        
                                        const net = line.replace(rep, PLACEHOLDER).split(":");
                                        const inUse = net[0] === "yes";
                                        const signal = parseInt(net[1]) || 0;
                                        const ssid = net[3] ? net[3].replace(rep2, ":") : "";
                                        const security = net[5] ? net[5].replace(rep2, ":") : "";
                                        const isSecure = security.length > 0 && security !== "--";
                                        
                                        if (ssid === "" || ssid === "--") continue;
                                        if (seen[ssid]) continue;
                                        seen[ssid] = true;
                                        
                                        wifiModel.append({
                                            "ssid": ssid,
                                            "inUse": inUse,
                                            "isSecure": isSecure,
                                            "security": security,
                                            "signal": signal,
                                            "expanded": false,
                                            "password": ""
                                        });
                                    }
                                }
                            }
                        }

                        // List of Networks
                        ListView {
                            id: wifiList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 8

                            model: ListModel { id: wifiModel }

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: model.expanded ? 120 : 64
                                color: Theme.colSurfaceContainer
                                radius: 12
                                Behavior on height { NumberAnimation { duration: 150 } }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 12

                                    RowLayout {
                                        Layout.fillWidth: true
                                        // Icon
                                        Text {
                                            text: model.inUse ? "" : (model.signal > 60 ? "" : "")
                                            color: model.inUse ? Theme.colPrimary : Theme.colOnSurface
                                            font.family: root.font.family
                                            font.pixelSize: 20
                                        }
                                        
                                        // Name
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2
                                            Text {
                                                text: model.ssid
                                                color: Theme.colOnSurface
                                                font.family: root.font.family
                                                font.pixelSize: 16
                                                font.bold: model.inUse
                                            }
                                            Text {
                                                text: model.inUse ? "Connected" : (model.isSecure ? "Secured" : "Not secured")
                                                color: Theme.colOnSurfaceVariant
                                                font.family: root.font.family
                                                font.pixelSize: 12
                                            }
                                        }

                                        // Lock Icon
                                        Text {
                                            visible: model.isSecure && !model.inUse
                                            text: ""
                                            color: Theme.colOnSurfaceVariant
                                            font.family: root.font.family
                                            font.pixelSize: 16
                                        }
                                    }

                                    // Expanded content
                                    RowLayout {
                                        Layout.fillWidth: true
                                        visible: model.expanded
                                        
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 40
                                            color: Theme.colSurfaceContainerHigh
                                            radius: 8
                                            border.color: Theme.colOutline
                                            border.width: 1
                                            
                                            TextInput {
                                                id: passInput
                                                anchors.fill: parent
                                                anchors.margins: 10
                                                verticalAlignment: TextInput.AlignVCenter
                                                color: Theme.colOnSurface
                                                font.family: root.font.family
                                                font.pixelSize: 14
                                                echoMode: TextInput.Password
                                                clip: true
                                                onTextChanged: model.password = text
                                            }
                                            
                                            Text {
                                                anchors.left: parent.left
                                                anchors.leftMargin: 10
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Password..."
                                                color: Theme.colOnSurfaceVariant
                                                font.family: root.font.family
                                                font.pixelSize: 14
                                                visible: passInput.text === ""
                                            }
                                        }

                                        Button {
                                            text: "Connect"
                                            font.family: root.font.family
                                            onClicked: {
                                                if (model.isSecure) {
                                                    Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", model.ssid, "password", model.password]);
                                                } else {
                                                    Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", model.ssid]);
                                                }
                                                model.expanded = false;
                                                refreshProcess.running = true;
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !model.expanded
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (model.inUse) return;
                                        
                                        for (let i = 0; i < wifiModel.count; i++) {
                                            if (i !== index) wifiModel.setProperty(i, "expanded", false);
                                        }
                                        
                                        if (!model.isSecure) {
                                            Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", model.ssid]);
                                            refreshProcess.running = true;
                                        } else {
                                            model.expanded = true;
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Bottom Open Advanced GUI Button
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            color: Theme.colSurfaceContainerHigh
                            radius: 12
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Text {
                                    text: ""
                                    color: Theme.colOnSurface
                                    font.family: root.font.family
                                    font.pixelSize: 16
                                }
                                Text {
                                    text: "Advanced Network Configuration"
                                    color: Theme.colOnSurface
                                    font.family: root.font.family
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["nm-connection-editor"])
                            }
                        }
                    }
                }
            }
        }
    }
}
