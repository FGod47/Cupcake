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
import Quickshell.Wayland

Item {
    id: root
    readonly property string homeDir: Quickshell.env("HOME")
    width: 868
    height: 768
    signal requestClose()
    
    property var font: {"family": Theme.monoFontFamily}
    property int currentIndex: 0
    property var barMonitors: ["all"]
    property var dockMonitors: ["all"]

    Process {
        id: settingsMonitorPoll
        command: ["bash", "-c", "cat ~/.config/cupcake/.bar_monitors 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_monitors 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.length > 0) {
                    let parts = text.trim().split('---');
                    let barStr = parts[0] ? parts[0].trim() : "";
                    let dockStr = parts[1] ? parts[1].trim() : "";
                    if (barStr !== "") root.barMonitors = barStr.split(',');
                    if (dockStr !== "") root.dockMonitors = dockStr.split(',');
                }
            }
        }
    }
    
    Timer {
        interval: 2000
        running: root.visible
        repeat: true
        onTriggered: settingsMonitorPoll.running = true
    }

    property bool globalTransparency: true

    property real globalOpacity: 0.90
    property int globalBlurSize: 6
    property int globalBlurPasses: 3
    property real barOpacity: 0.50
    property bool barTransparency: true

    function applyGlobalSettings() {
        let isTrans = root.globalTransparency ? "true" : "false";
        Quickshell.execDetached(["bash", "-c", "echo " + isTrans + " > ~/.config/cupcake/.transparency && echo -e 'OPACITY=" + root.globalOpacity.toFixed(2) + "\\nBLUR_SIZE=" + root.globalBlurSize + "\\nBLUR_PASSES=" + root.globalBlurPasses + "' > ~/.config/cupcake/.transparency_values && ~/.local/bin/apply-transparency"]);
    }
    
    property bool windowBorders: true

    Process {
        id: initBorders
        command: ["cat", root.homeDir + "/.config/cupcake/.borders"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "false") {
                    root.windowBorders = false;
                }
            }
        }
    }

    property bool windowShadows: false

    Process {
        id: initShadows
        command: ["cat", root.homeDir + "/.config/cupcake/.shadows"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "true") {
                    root.windowShadows = true;
                } else if (text.trim() === "false") {
                    root.windowShadows = false;
                }
            }
        }
    }

    property int borderSize: 3

    Process {
        id: initBorderSize
        command: ["cat", root.homeDir + "/.config/cupcake/.border_size"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    let sz = parseInt(text.trim());
                    if (!isNaN(sz)) root.borderSize = sz;
                }
            }
        }
    }

    property int gapsIn: 3
    property int gapsOut: 8

    Process {
        id: initGapsIn
        command: ["cat", root.homeDir + "/.config/cupcake/.gaps_in"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    let sz = parseInt(text.trim());
                    if (!isNaN(sz)) root.gapsIn = sz;
                }
            }
        }
    }

    Process {
        id: initGapsOut
        command: ["cat", root.homeDir + "/.config/cupcake/.gaps_out"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    let sz = parseInt(text.trim());
                    if (!isNaN(sz)) root.gapsOut = sz;
                }
            }
        }
    }

    Process {
        id: initBarTransparencySettings
        command: ["cat", root.homeDir + "/.config/cupcake/.bar_transparency"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "false") { root.barTransparency = false; }
                else { root.barTransparency = true; }
            }
        }
    }

    Process {
        id: initBarOpacitySettings
        command: ["cat", root.homeDir + "/.config/cupcake/.bar_opacity"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    let v = parseFloat(text.trim());
                    if (!isNaN(v)) root.barOpacity = v;
                }
            }
        }
    }

    Process {
        id: initTransparency
        command: ["cat", root.homeDir + "/.config/cupcake/.transparency"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "false") {
                    root.globalTransparency = false;
                    if (appearancePage) appearancePage.transparency = false;
                }
            }
        }
    }

    Process {
        id: initTransparencyValues
        command: ["cat", root.homeDir + "/.config/cupcake/.transparency_values"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.length > 0) {
                    let lines = text.trim().split('\\n');
                    for (let i = 0; i < lines.length; i++) {
                        if (lines[i].startsWith('OPACITY=')) root.globalOpacity = parseFloat(lines[i].split('=')[1]);
                        if (lines[i].startsWith('BLUR_SIZE=')) root.globalBlurSize = parseInt(lines[i].split('=')[1]);
                        if (lines[i].startsWith('BLUR_PASSES=')) root.globalBlurPasses = parseInt(lines[i].split('=')[1]);
                    }
                }
            }
        }
    }

    Process {
        id: initColorMode
        command: ["cat", root.homeDir + "/.config/cupcake/.color_mode"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "light") {
                    if (appearancePage) appearancePage.darkTheme = false;
                }
            }
        }
    }


    property bool navExpanded: sidebarHover.hovered

    // Extracted StyledSwitch to StyledSwitch.qml

    // Extracted StyledSlider to StyledSlider.qml




    Item {
        id: mainWrapper
        anchors.fill: parent
        focus: true

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            onPressed: mouse.accepted = true
            onReleased: mouse.accepted = true
            onClicked: mouse.accepted = true
            onWheel: wheel.accepted = true
        }

        Item {
            id: contentOpacity
            anchors.fill: parent
            clip: true
            opacity: 1.0

            Item {
                anchors.fill: parent

                Keys.onPressed: (event) => {
                    if (event.modifiers === Qt.ControlModifier) {
                        if (event.key === Qt.Key_PageDown) {
                            root.currentIndex = Math.min(root.currentIndex + 1, 5)
                            event.accepted = true;
                        } 
                        else if (event.key === Qt.Key_PageUp) {
                            root.currentIndex = Math.max(root.currentIndex - 1, 0)
                            event.accepted = true;
                        }
                        else if (event.key === Qt.Key_Tab) {
                            root.currentIndex = (root.currentIndex + 1) % 6;
                            event.accepted = true;
                        }
                else if (event.key === Qt.Key_Backtab) {
                    root.currentIndex = (root.currentIndex - 1 + 6) % 6;
                    event.accepted = true;
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            // Custom Title Bar
            Item {
                Layout.fillWidth: true
                implicitHeight: 40
                

                
                Text {
                    anchors.centerIn: parent
                    text: "Settings"
                    color: Theme.colOnSurface
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 16
                    font.weight: Math.min(900, Theme.defaultFontWeight + 200)
                }
                
                MouseArea {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32; height: 32
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.requestClose()
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: parent.containsMouse ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.1) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: Theme.colOnSurfaceVariant
                        font.family: root.font.family
                        font.pixelSize: 16
                    }
                }
                
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 12
                spacing: 16

                // Navigation Rail
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: navExpanded ? 220 : 72
                    Behavior on Layout.preferredWidth { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                    
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                    radius: 16
                    border.width: 1
                    border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                    
                    HoverHandler {
                        id: sidebarHover
                    }

                    ScrollView {
                        id: navScrollView
                        anchors.fill: parent
                        anchors.margins: 4
                        contentWidth: availableWidth
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                        ColumnLayout {
                            width: navScrollView.availableWidth
                            spacing: 8
                            anchors.topMargin: 20

                            component NavHeader: Text {
                                visible: navExpanded
                                Layout.fillWidth: true
                                Layout.leftMargin: 24
                                Layout.topMargin: 16
                                Layout.bottomMargin: 8
                                color: Theme.colPrimary
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 12
                                font.weight: Math.min(900, Theme.defaultFontWeight + 200)
                                opacity: 0.8
                            }
                            
                            component NavButton: Item {
                                property string iconText
                                property string labelText
                                property int pageIndex

                                Layout.fillWidth: true
                                implicitHeight: 44
                                
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    anchors.topMargin: 2
                                    anchors.bottomMargin: 2
                                    radius: 12
                                    color: root.currentIndex === pageIndex 
                                        ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.15)
                                        : (navMouseArea.containsMouse ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05) : "transparent")
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: navExpanded ? 16 : 12
                                    spacing: 12
                                    
                                    Item {
                                        Layout.preferredWidth: 40
                                        Layout.fillHeight: true
                                        Text {
                                            anchors.centerIn: parent
                                            text: iconText
                                            color: Theme.colOnSurfaceVariant
                                            font.family: root.font.family
                                            font.weight: Theme.defaultFontWeight; font.pixelSize: 20
                                            opacity: root.currentIndex === pageIndex ? 1.0 : 0.6
                                        }
                                    }
                                    
                                    Text {
                                        visible: navExpanded
                                        text: labelText
                                        color: Theme.colOnSurface
                                        font.family: Theme.defaultFontFamily
                                        font.pixelSize: Theme.defaultFontSize
                                        font.weight: Math.min(900, Theme.defaultFontWeight + 200)
                                        Layout.fillWidth: true
                                        opacity: root.currentIndex === pageIndex ? 1.0 : 0.6
                                    }
                                }

                                MouseArea {
                                    id: navMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.currentIndex = pageIndex
                                }
                            }

                        NavHeader { text: "PERSONALIZATION" }
                        NavButton { iconText: "󰏘"; labelText: "Appearance"; pageIndex: 0 }
                        NavButton { iconText: ""; labelText: "Wallpaper"; pageIndex: 1 }
                        NavHeader { text: "SHELL" }
                        NavButton { iconText: "󰧨"; labelText: "Desktop"; pageIndex: 3 }
                        NavButton { iconText: "󰗚"; labelText: "Dock"; pageIndex: 4 }
                        NavButton { iconText: "󰋋"; labelText: "Panels"; pageIndex: 5 }
                        NavButton { iconText: "󰂚"; labelText: "Notifications"; pageIndex: 6 }
                        NavButton { iconText: "󰍡"; labelText: "OSD"; pageIndex: 7 }
                        NavButton { iconText: "󰖲"; labelText: "Shell"; pageIndex: 8 }
                        
                        NavHeader { text: "SYSTEM" }
                        NavButton { iconText: "󰕡"; labelText: "Security"; pageIndex: 9 }
                        NavButton { iconText: ""; labelText: "System"; pageIndex: 10 }
                        NavButton { iconText: "󰒓"; labelText: "Services"; pageIndex: 11 }
                        NavButton { iconText: "󰍎"; labelText: "Location"; pageIndex: 12 }
                        NavButton { iconText: "󰚥"; labelText: "Power"; pageIndex: 13 }
                        
                        NavHeader { text: "ADVANCED" }

                        NavHeader { text: "CUPCAKE EXTRA" }
                        NavButton { iconText: ""; labelText: "Network"; pageIndex: 17 }
                        NavButton { iconText: "󰍹"; labelText: "Display"; pageIndex: 18 }
                        NavButton { iconText: "✨"; labelText: "AI"; pageIndex: 19 }
                        NavButton { iconText: ""; labelText: "User"; pageIndex: 20 }
                        NavButton { iconText: ""; labelText: "About"; pageIndex: 21 }

                        Item { Layout.fillHeight: true } // Spacer
                    }
                }
            }

                // Content Area

                Rectangle {
                    id: contentAreaContainer
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: "transparent"
                    clip: true

                                        function getPageData(index) {
                        switch(index) {
                            case 0: return { icon: "󰏘", title: "Appearance" };
                            case 1: return { icon: "", title: "Wallpaper" };
                            case 3: return { icon: "󰧨", title: "Desktop" };
                            case 4: return { icon: "󰗚", title: "Dock" };
                            case 5: return { icon: "󰋋", title: "Panels" };
                            case 6: return { icon: "󰂚", title: "Notifications" };
                            case 7: return { icon: "󰍡", title: "OSD" };
                            case 8: return { icon: "󰖲", title: "Shell" };
                            case 9: return { icon: "󰕡", title: "Security" };
                            case 10: return { icon: "", title: "System" };
                            case 11: return { icon: "󰒓", title: "Services" };
                            case 12: return { icon: "󰍎", title: "Location" };
                            case 13: return { icon: "󰚥", title: "Power" };
                            case 17: return { icon: "", title: "Network" };
                            case 18: return { icon: "󰍹", title: "Display" };
                            case 19: return { icon: "✨", title: "AI" };
                            case 20: return { icon: "", title: "User" };
                            case 21: return { icon: "", title: "About" };
                            default: return { icon: "", title: "Settings" };
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        // Dynamic Content Header
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            color: "transparent"
                            

                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 24
                                anchors.rightMargin: 16
                                spacing: 16
                                
                                Text {
                                    text: contentAreaContainer.getPageData(root.currentIndex).icon
                                    color: Theme.colOnSurfaceVariant
                                    font.family: root.font.family
                                    font.weight: Theme.defaultFontWeight; font.pixelSize: 20
                                }
                                
                                Text {
                                    text: contentAreaContainer.getPageData(root.currentIndex).title
                                    color: Theme.colOnSurface
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 20
                                    font.weight: Math.min(900, Theme.defaultFontWeight + 200)
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        // Content Stack
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

            // We use Loader to get page transition animations, or just StackLayout.
            // StackLayout doesn't animate easily without custom item delegates.
            // I will implement a quick fade for the StackLayout children.

            Item {
                anchors.fill: parent


                                // PAGE 0: APPEARANCE
                Item {
                    id: appearancePage
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 0 ? 0 : 20
                    opacity: root.currentIndex === 0 ? 1 : 0
                    visible: root.currentIndex === 0 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    SettingsPageAppearance {
                        anchors.fill: parent
                    }
                }


                // PAGE 1: WALLPAPERS
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 1 ? 0 : 20
                    opacity: root.currentIndex === 1 ? 1 : 0
                    visible: root.currentIndex === 1 || opacity > 0
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
                            font.weight: Math.min(900, Theme.defaultFontWeight + 200)
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            text: "Clicking a wallpaper will instantly apply it and regenerate your dynamic material colors."
                            color: Theme.colOnSurfaceVariant
                            font.family: root.font.family
                            font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                            Layout.bottomMargin: 16
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }

                        GridView {
                            id: grid
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            cellWidth: 250
                            cellHeight: 180
                            clip: true

                            model: FolderListModel {
                                folder: "file://" + root.homeDir + "/.config/cupcake/themes/cupcake-dark/walls"
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
                                            Quickshell.execDetached([root.homeDir + "/.local/bin/set-theme", filePath])
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                
                // PAGE 3: DESKTOP
                Item {
                    id: page3
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 3 ? 0 : 20
                    opacity: root.currentIndex === 3 ? 1 : 0
                    visible: root.currentIndex === 3 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    SettingsPageDesktop { anchors.fill: parent }
                }

                // PAGE 4: DOCK
                Item {
                    id: page4
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 4 ? 0 : 20
                    opacity: root.currentIndex === 4 ? 1 : 0
                    visible: root.currentIndex === 4 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    SettingsPageDock { anchors.fill: parent }
                }

                // PAGE 5: PANELS
                Item {
                    id: page5
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 5 ? 0 : 20
                    opacity: root.currentIndex === 5 ? 1 : 0
                    visible: root.currentIndex === 5 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    SettingsPagePanels { anchors.fill: parent }
                }

                // PAGE 6: NOTIFICATIONS
                Item {
                    id: page6
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 6 ? 0 : 20
                    opacity: root.currentIndex === 6 ? 1 : 0
                    visible: root.currentIndex === 6 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    SettingsPageNotifications { anchors.fill: parent }
                }

                // PAGE 7: OSD
                Item {
                    id: page7
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 7 ? 0 : 20
                    opacity: root.currentIndex === 7 ? 1 : 0
                    visible: root.currentIndex === 7 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    SettingsPageOsd { anchors.fill: parent }
                }

                // PAGE 8: SHELL
                Item {
                    id: page8
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 8 ? 0 : 20
                    opacity: root.currentIndex === 8 ? 1 : 0
                    visible: root.currentIndex === 8 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    SettingsPageShell { anchors.fill: parent }
                }

                // PAGE 9: SECURITY
                Item {
                    id: page9
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 9 ? 0 : 20
                    opacity: root.currentIndex === 9 ? 1 : 0
                    visible: root.currentIndex === 9 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    SettingsPageSecurity { anchors.fill: parent }
                }

                // PAGE 11: SERVICES
                Item {
                    id: page11
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 11 ? 0 : 20
                    opacity: root.currentIndex === 11 ? 1 : 0
                    visible: root.currentIndex === 11 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    SettingsPageServices { anchors.fill: parent }
                }

                // PAGE 12: LOCATION
                Item {
                    id: page12
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 12 ? 0 : 20
                    opacity: root.currentIndex === 12 ? 1 : 0
                    visible: root.currentIndex === 12 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    SettingsPageLocation { anchors.fill: parent }
                }

                // PAGE 13: POWER
                Item {
                    id: page13
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 13 ? 0 : 20
                    opacity: root.currentIndex === 13 ? 1 : 0
                    visible: root.currentIndex === 13 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    SettingsPagePower { anchors.fill: parent }
                }

                // PAGE 10: SYSTEM
                Item {
                    id: page10
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 10 ? 0 : 20
                    opacity: root.currentIndex === 10 ? 1 : 0
                    visible: root.currentIndex === 10 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    SettingsPageSystem { anchors.fill: parent }
                }

                // PAGE 17: NETWORK
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 17 ? 0 : 20
                    opacity: root.currentIndex === 17 ? 1 : 0
                    visible: root.currentIndex === 17 || opacity > 0
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
                                font.weight: Math.min(900, Theme.defaultFontWeight + 200)
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
                                    font.weight: Theme.defaultFontWeight; font.pixelSize: 20
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: refreshProcess.running = true
                                }
                            }
                            
                            // Toggle Switch
                            Item { Layout.fillWidth: true }
                            StyledSwitch {
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
                                            font.weight: Theme.defaultFontWeight; font.pixelSize: 20
                                        }
                                        
                                        // Name
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2
                                            Text {
                                                text: model.ssid
                                                color: Theme.colOnSurface
                                                font.family: root.font.family
                                                font.weight: Theme.defaultFontWeight; font.pixelSize: 16
                                                font.bold: model.inUse
                                            }
                                            Text {
                                                text: model.inUse ? "Connected" : (model.isSecure ? "Secured" : "Not secured")
                                                color: Theme.colOnSurfaceVariant
                                                font.family: root.font.family
                                                font.weight: Theme.defaultFontWeight; font.pixelSize: 12
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
                                                font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
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
                                                font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
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
                                    font.weight: Theme.defaultFontWeight; font.pixelSize: 16
                                }
                                Text {
                                    text: "Advanced Network Configuration"
                                    color: Theme.colOnSurface
                                    font.family: root.font.family
                                    font.pixelSize: Theme.defaultFontSize
                                    font.weight: Math.min(900, Theme.defaultFontWeight + 200)
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

                // PAGE 19: AI PANEL
                Item {
                    id: aiSettingsPage
                    property bool keyExists: false

                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 159 ? 0 : 20
                    opacity: root.currentIndex === 159 ? 1 : 0
                    visible: root.currentIndex === 159 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                    Flickable {
                        anchors.fill: parent
                        contentHeight: aiContentCol.implicitHeight + 48
                        clip: true
                        
                        ColumnLayout {
                            id: aiContentCol
                            width: parent.width - 48
                            x: 24
                            y: 24
                            spacing: 16

                        Text {
                            text: "AI Panel Settings"
                            color: Theme.colOnSurface
                            font.family: root.font.family
                            font.pixelSize: 24
                            font.weight: Math.min(900, Theme.defaultFontWeight + 200)
                        }

                        // Save Key Process
                        Process {
                            id: saveKeyProcess
                            running: false
                        }

                        // Process to check if key exists
                        // Process to check if key exists and load accounts
                        Process {
                            id: settingsCheckKey
                            command: ["bash", "-c", "cat ~/.config/quickshell/gemini_accounts.txt 2>/dev/null | cut -d':' -f1"]
                            running: true
                            stdout: SplitParser {
                                onRead: data => {
                                    if (data.trim() !== "") {
                                        aiSettingsPage.keyExists = true;
                                        let lines = data.trim().split("\n");
                                        let cleanLines = [];
                                        for (let i = 0; i < lines.length; i++) {
                                            if (lines[i].trim() !== "") cleanLines.push(lines[i].trim());
                                        }
                                        if (cleanLines.length > 0) {
                                            // Accounts loaded successfully
                                        }
                                    }
                                }
                            }
                        }

                        // --- SECTION: CONFIGURATION ---
                        Text {
                            text: "API Configuration"
                            color: Theme.colOnSurface
                            font.family: root.font.family
                            font.pixelSize: 18
                            font.weight: Math.min(900, Theme.defaultFontWeight + 200)
                            Layout.topMargin: 8
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: configCol.implicitHeight + 32
                            radius: 12
                            color: Theme.colSurfaceContainer
                            
                            ColumnLayout {
                                id: configCol
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 20
                                
                                // API Key Box
                                // Add Account Box
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: "Add New Google Gemini Account"
                                            color: Theme.colOnSurfaceVariant
                                            font.family: root.font.family
                                            font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: aiSettingsPage.keyExists ? "✅ Accounts Loaded" : "❌ No Accounts"
                                            color: aiSettingsPage.keyExists ? Theme.colPrimary : Theme.colError
                                            font.family: root.font.family
                                            font.pixelSize: Theme.defaultFontSize
                                            font.weight: Math.min(900, Theme.defaultFontWeight + 200)
                                        }
                                    }
                                    
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 12

                                        TextField {
                                            id: emailInput
                                            Layout.preferredWidth: 200
                                            Layout.preferredHeight: 40
                                            placeholderText: "Email address..."
                                            color: Theme.colOnSurface
                                            background: Rectangle { color: Theme.colSurfaceContainerHigh; radius: 6 }
                                            leftPadding: 10
                                        }

                                        TextField {
                                            id: apiKeyInput
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 40
                                            placeholderText: "Paste your API key here..."
                                            color: Theme.colOnSurface
                                            background: Rectangle { color: Theme.colSurfaceContainerHigh; radius: 6 }
                                            leftPadding: 10
                                            
                                            onAccepted: {
                                                if (emailInput.text.trim() === "" || apiKeyInput.text.trim() === "") return;
                                                saveKeyProcess.command = ["bash", "-c", "echo '" + emailInput.text + ":" + apiKeyInput.text + "' >> ~/.config/quickshell/gemini_accounts.txt"];
                                                saveKeyProcess.running = true;
                                                aiSettingsPage.keyExists = true;
                                                placeholderText = "Account added!";
                                                text = "";
                                                emailInput.text = "";
                                                settingsCheckKey.running = true;
                                            }
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: 80
                                            Layout.preferredHeight: 40
                                            radius: 6
                                            color: Theme.colPrimary
                                            
                                            Text {
                                                anchors.centerIn: parent
                                                text: "Save"
                                                color: Theme.colOnPrimary
                                                font.family: root.font.family
                                                
                                                font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                                            }
                                            
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: apiKeyInput.accepted()
                                            }
                                        }
                                    }
                                }

                            }
                        }


                        Item { Layout.fillHeight: true }
                        }
                    }
                }

                // PAGE 20: USER
                Item {
                    id: userPage
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 160 ? 0 : 20
                    opacity: root.currentIndex === 160 ? 1 : 0
                    visible: root.currentIndex === 160 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                    property string userName: "Loading..."
                    property string hostName: "Loading..."
                    property string homeDir: "Loading..."
                    property string userShell: "Loading..."
                    property string userId: "Loading..."
                    property string groupId: "Loading..."

                    Process {
                        command: ["bash", "-c", "echo \"$(whoami)|$(cat /etc/hostname 2>/dev/null)|$HOME|$SHELL|$(id -u)|$(id -g)\""]
                        running: root.currentIndex === 160
                        stdout: StdioCollector {
                            onStreamFinished: {
                                let lines = text.trim().split("|");
                                if (lines.length >= 6) {
                                    userPage.userName = lines[0] || "Unknown";
                                    userPage.hostName = lines[1] || "Unknown";
                                    userPage.homeDir = lines[2] || "Unknown";
                                    userPage.userShell = lines[3] || "Unknown";
                                    userPage.userId = lines[4] || "Unknown";
                                    userPage.groupId = lines[5] || "Unknown";
                                }
                            }
                        }
                    }

                    Flickable {
                        anchors.fill: parent
                        contentHeight: userContentCol.implicitHeight + 48
                        clip: true

                        ColumnLayout {
                            id: userContentCol
                            width: parent.width - 48
                            x: 24
                            y: 24
                            spacing: 24

                            component UserInfoItem: Item {
                                property string titleText
                                property string valueText
                                property bool isFirst: false
                                property bool isLast: false

                                Layout.fillWidth: true
                                Layout.preferredHeight: 72

                                Item {
                                    anchors.fill: parent
                                    clip: true

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        
                                        anchors.bottomMargin: (isFirst && !isLast) ? -24 : 0
                                        anchors.topMargin: (isLast && !isFirst) ? -24 : 0

                                        radius: (isFirst || isLast) ? 24 : 0
                                        color: Theme.colSurfaceContainerHigh
                                    }
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 24
                                    anchors.rightMargin: 24
                                    spacing: 2

                                    Item { Layout.fillHeight: true }
                                    Text {
                                        text: titleText
                                        color: Theme.colOnSurface
                                        font.family: root.font.family
                                        font.weight: Theme.defaultFontWeight; font.pixelSize: 16
                                    }
                                    Text {
                                        text: valueText
                                        color: Theme.colOnSurfaceVariant
                                        font.family: root.font.family
                                        font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                                    }
                                    Item { Layout.fillHeight: true }
                                }
                            }

                            Text {
                                text: "User"
                                color: Theme.colOnSurface
                                font.family: root.font.family
                                font.pixelSize: 32
                                font.weight: Math.min(900, Theme.defaultFontWeight + 200)
                                Layout.bottomMargin: 8
                            }

                            // Profile details
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Profile Information"
                                    color: Theme.colPrimary
                                    font.family: root.font.family
                                    font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                                    Layout.leftMargin: 16
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    
                                    UserInfoItem { titleText: "Username"; valueText: userPage.userName; isFirst: true }
                                    UserInfoItem { titleText: "Device Hostname"; valueText: userPage.hostName }
                                    UserInfoItem { titleText: "Home Directory"; valueText: userPage.homeDir; isLast: true }
                                }
                            }

                            // Account details
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Account Details"
                                    color: Theme.colPrimary
                                    font.family: root.font.family
                                    font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                                    Layout.leftMargin: 16
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    
                                    UserInfoItem { titleText: "Default Shell"; valueText: userPage.userShell; isFirst: true }
                                    UserInfoItem { titleText: "User ID (UID)"; valueText: userPage.userId }
                                    UserInfoItem { titleText: "Group ID (GID)"; valueText: userPage.groupId; isLast: true }
                                }
                            }
                        }
                    }
                }

                // PAGE 21: ABOUT
                Item {
                    id: aboutPage
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 161 ? 0 : 20
                    opacity: root.currentIndex === 161 ? 1 : 0
                    visible: root.currentIndex === 161 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                    property string sysOs: "Loading..."
                    property string sysKernel: "Loading..."
                    property string sysUptime: "Loading..."
                    property string hyprVersion: "Loading..."
                    property string qsVersion: "Loading..."

                    property string hwCpu: "Loading..."
                    property string hwCpuCores: "Loading..."
                    property string hwGpu: "Loading..."
                    property string hwVram: "Loading..."
                    property string hwRam: "Loading..."
                    property string hwMobo: "Loading..."
                    property string hwDisplay: "Loading..."
                    property string hwSwap: "Loading..."

                    Process {
                        id: aboutInfoProcess
                        command: ["bash", root.homeDir + "/.local/bin/get-hw-info"]
                        running: true
                        stdout: StdioCollector {
                            onStreamFinished: {
                                let lines = text.trim().split("\n");
                                if (lines.length >= 12) {
                                    aboutPage.sysOs = lines[0];
                                    aboutPage.sysKernel = lines[1];
                                    aboutPage.sysUptime = lines[2];
                                    aboutPage.hyprVersion = lines[3];
                                    aboutPage.qsVersion = lines[4];
                                    aboutPage.hwCpu = lines[5];
                                    aboutPage.hwGpu = lines[6];
                                    aboutPage.hwRam = lines[7];
                                    aboutPage.hwMobo = lines[8] || "Unknown";
                                    aboutPage.hwVram = lines[9] || "Shared";
                                    aboutPage.hwDisplay = lines[10] || "Unknown";
                                    aboutPage.hwCpuCores = lines[11] || "?";
                                    aboutPage.hwSwap = lines[12] || "Unknown";
                                }
                            }
                        }
                    }

                    Flickable {
                        anchors.fill: parent
                        contentHeight: aboutContentCol.implicitHeight + 48
                        clip: true

                        ColumnLayout {
                            id: aboutContentCol
                            width: parent.width - 48
                            x: 24
                            y: 24
                            spacing: 24

                        component InfoItem: Item {
                            property string titleText
                            property string valueText
                            property bool isFirst: false
                            property bool isLast: false

                            Layout.fillWidth: true
                            Layout.preferredHeight: 72

                            Item {
                                anchors.fill: parent
                                clip: true

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    
                                    anchors.bottomMargin: (isFirst && !isLast) ? -24 : 0
                                    anchors.topMargin: (isLast && !isFirst) ? -24 : 0

                                    radius: (isFirst || isLast) ? 24 : 0
                                    color: Theme.colSurfaceContainerHigh
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 24
                                anchors.rightMargin: 24
                                spacing: 2

                                Item { Layout.fillHeight: true }
                                Text {
                                    text: titleText
                                    color: Theme.colOnSurface
                                    font.family: root.font.family
                                    font.weight: Theme.defaultFontWeight; font.pixelSize: 16
                                }
                                Text {
                                    text: valueText
                                    color: Theme.colOnSurfaceVariant
                                    font.family: root.font.family
                                    font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                                }
                                Item { Layout.fillHeight: true }
                            }
                        }

                        Text {
                            text: "About"
                            color: Theme.colOnSurface
                            font.family: root.font.family
                            font.pixelSize: 32
                            font.weight: Math.min(900, Theme.defaultFontWeight + 200)
                            Layout.bottomMargin: 8
                        }

                        // System details
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "System details"
                                color: Theme.colPrimary
                                font.family: root.font.family
                                font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                                Layout.leftMargin: 16
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                
                                InfoItem { titleText: "Operating System"; valueText: aboutPage.sysOs; isFirst: true }
                                InfoItem { titleText: "Kernel Version"; valueText: aboutPage.sysKernel }
                                InfoItem { titleText: "System Uptime"; valueText: aboutPage.sysUptime; isLast: true }
                            }
                        }

                        // Hardware details
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Hardware details"
                                color: Theme.colPrimary
                                font.family: root.font.family
                                font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                                Layout.leftMargin: 16
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                
                                InfoItem { titleText: "Processor (CPU)"; valueText: aboutPage.hwCpu + " (" + aboutPage.hwCpuCores + " Cores)"; isFirst: true }
                                InfoItem { titleText: "Graphics (GPU)"; valueText: aboutPage.hwGpu + " (" + aboutPage.hwVram + ")" }
                                InfoItem { titleText: "Motherboard"; valueText: aboutPage.hwMobo }
                                InfoItem { titleText: "Memory (RAM)"; valueText: aboutPage.hwRam }
                                InfoItem { titleText: "Swap Memory"; valueText: aboutPage.hwSwap }
                                InfoItem { titleText: "Display Resolution"; valueText: aboutPage.hwDisplay; isLast: true }
                            }
                        }

                        // Software details
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Software details"
                                color: Theme.colPrimary
                                font.family: root.font.family
                                font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                                Layout.leftMargin: 16
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                
                                InfoItem { titleText: "Window Manager"; valueText: "Hyprland " + aboutPage.hyprVersion; isFirst: true }
                                InfoItem { titleText: "Desktop Shell"; valueText: "Quickshell " + aboutPage.qsVersion }
                                InfoItem { titleText: "Theme Engine"; valueText: "Cupcake OS"; isLast: true }
                            }
                        }
                        }
                    }
                } // Closes PAGE 7 Item

                // PAGE 18: DISPLAY
                Item {
                    id: displayPage
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 18 ? 0 : 20
                    opacity: root.currentIndex === 18 ? 1 : 0
                    visible: root.currentIndex === 18 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                    property var monitorsData: []
                    property string pendingOutput: ""
                    property int countdown: 0
                    property var pendingRestoreCommand: []

                    Timer {
                        id: revertTimer
                        interval: 1000
                        repeat: true
                        onTriggered: {
                            displayPage.countdown--
                            if (displayPage.countdown <= 0) {
                                displayPage.revertDisplay()
                            }
                        }
                    }

                    function applyDisplay(modelData, modeStr, scaleStr) {
                        if (displayPage.pendingOutput !== "") return;
                        let posStr = modelData.x + "x" + modelData.y;
                        displayPage.pendingRestoreCommand = ["hyprctl", "eval", "hl.monitor({ output = \"" + modelData.name + "\", mode = \"" + modelData.width + "x" + modelData.height + "@" + modelData.refreshRate + "\", position = \"" + posStr + "\", scale = " + modelData.scale + " }) return \"ok\""];
                        displayPage.pendingOutput = modelData.name;
                        displayPage.countdown = 15;
                        revertTimer.start();
                        Quickshell.execDetached(["hyprctl", "eval", "hl.monitor({ output = \"" + modelData.name + "\", mode = \"" + modeStr + "\", position = \"" + posStr + "\", scale = " + scaleStr + " }) return \"ok\""]);
                    }

                    function keepDisplay() {
                        if (displayPage.pendingOutput === "") return;
                        revertTimer.stop();
                        Quickshell.execDetached(["python3", root.homeDir + "/Cupcake/.local/bin/generate_monitor_lua.py"]);
                        displayPage.pendingOutput = "";
                    }

                    function revertDisplay() {
                        revertTimer.stop();
                        Quickshell.execDetached(displayPage.pendingRestoreCommand);
                        displayPage.pendingOutput = "";
                    }
                    
                    Process {
                        id: monitorsProcess
                        command: ["hyprctl", "monitors", "-j"]
                        running: displayPage.visible
                        stdout: StdioCollector {
                            onStreamFinished: {
                                try {
                                    displayPage.monitorsData = JSON.parse(text);
                                } catch (e) {
                                    console.log("Failed to parse monitors");
                                }
                            }
                        }
                    }
                    
                    Timer {
                        interval: 5000
                        running: displayPage.visible
                        repeat: true
                        onTriggered: monitorsProcess.running = true
                    }

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 24
                        contentHeight: displayContentCol.implicitHeight + 40
                        clip: true

                        ColumnLayout {
                            id: displayContentCol
                            width: Math.min(displayPage.width - 48, 1000)
                            anchors.horizontalCenter: parent.horizontalCenter
                            Layout.alignment: Qt.AlignTop
                            spacing: 24
                            
                            Text {
                                text: "Display Settings"
                                color: Theme.colOnSurface
                                font.family: root.font.family
                                font.pixelSize: 32
                                font.weight: Math.min(900, Theme.defaultFontWeight + 200)
                            }
                            
                            Text {
                                text: "Manage your monitors, resolution, refresh rates, and scaling."
                                color: Theme.colOnSurfaceVariant
                                font.family: root.font.family
                                font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                            }
                            
                            // Monitor List
                            Repeater {
                                model: displayPage.monitorsData
                                delegate: Rectangle {
                                    id: monitorCard
                                    Layout.fillWidth: true
                                    implicitHeight: cardContent.implicitHeight + 32
                                    radius: 12
                                    color: Theme.colSurfaceContainer
                                    border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.2)
                                    border.width: 1

                                    property bool pending: displayPage.pendingOutput === modelData.name

                                    property var modesParsed: {
                                        let result = [];
                                        let seen = {};
                                        for (let i = 0; i < modelData.availableModes.length; i++) {
                                            let m = modelData.availableModes[i].match(/^(\d+)x(\d+)@([\d.]+)Hz$/);
                                            if (m) {
                                                let w = parseInt(m[1], 10);
                                                let h = parseInt(m[2], 10);
                                                let hz = Math.round(parseFloat(m[3]));
                                                let key = w + "x" + h;
                                                if (!seen[key]) {
                                                    seen[key] = { w: w, h: h, rates: [] };
                                                    result.push(seen[key]);
                                                }
                                                if (seen[key].rates.indexOf(hz) === -1) seen[key].rates.push(hz);
                                            }
                                        }
                                        result.sort(function(a,b) { return (b.w*b.h) - (a.w*a.h); });
                                        for (let j = 0; j < result.length; j++) {
                                            result[j].rates.sort(function(a,b) { return b - a; });
                                        }
                                        return result;
                                    }

                                    property int selRes: 0
                                    property int selRate: 0
                                    property real selScale: modelData.scale
                                    readonly property var scaleOptions: [1.0, 1.25, 1.5, 2.0]

                                    Component.onCompleted: {
                                        for (let i = 0; i < modesParsed.length; i++) {
                                            if (modesParsed[i].w === modelData.width && modesParsed[i].h === modelData.height) {
                                                selRes = i;
                                                break;
                                            }
                                        }
                                        let bestDiff = 1e9;
                                        let rates = modesParsed[selRes] ? modesParsed[selRes].rates : [];
                                        for (let i = 0; i < rates.length; i++) {
                                            let d = Math.abs(rates[i] - modelData.refreshRate);
                                            if (d < bestDiff) { bestDiff = d; selRate = i; }
                                        }
                                    }

                                    onSelResChanged: {
                                        let rates = modesParsed[selRes] ? modesParsed[selRes].rates : [];
                                        if (selRate >= rates.length) selRate = Math.max(0, rates.length - 1);
                                    }

                                    ColumnLayout {
                                        id: cardContent
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 16
                                        spacing: 16
                                        
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 16
                                            Text { text: "󰍹"; color: Theme.colPrimary; font.weight: Theme.defaultFontWeight; font.pixelSize: 32 }
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 4
                                                Text { text: modelData.name + (modelData.focused ? " (Active)" : ""); color: Theme.colOnSurface; font.family: root.font.family; font.pixelSize: 16; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                                Text { text: modelData.description; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.weight: Theme.defaultFontWeight; font.pixelSize: 12 }
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 1
                                            color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.2)
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 24

                                            ColumnLayout {
                                                spacing: 8
                                                Text { text: "Resolution"; color: Theme.colOnSurfaceVariant; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; font.family: root.font.family }
                                                ComboBox {
                                                    id: resCombo
                                                    Layout.preferredWidth: 140
                                                    Layout.preferredHeight: 36
                                                    model: monitorCard.modesParsed.map(function(r) { return r.w + "x" + r.h; })
                                                    currentIndex: monitorCard.selRes
                                                    onActivated: monitorCard.selRes = index
                                                    
                                                    indicator: Item {}
                                                    background: Rectangle { color: Theme.colSurfaceContainerHigh; radius: 8 }
                                                    contentItem: Text {
                                                        text: resCombo.currentText + " "
                                                        font.family: root.font.family
                                                        font.pixelSize: 13
                                                        font.weight: 600
                                                        color: Theme.colOnSurface
                                                        verticalAlignment: Text.AlignVCenter
                                                        horizontalAlignment: Text.AlignHCenter
                                                    }
                                                    popup: Popup {
                                                        y: resCombo.height - 1
                                                        width: resCombo.width
                                                        implicitHeight: contentItem.implicitHeight
                                                        padding: 4
                                                        contentItem: ListView {
                                                            clip: true
                                                            implicitHeight: Math.min(contentHeight, 200)
                                                            model: resCombo.popup.visible ? resCombo.delegateModel : null
                                                            currentIndex: resCombo.highlightedIndex
                                                            ScrollIndicator.vertical: ScrollIndicator { }
                                                        }
                                                        background: Rectangle {
                                                            color: Theme.colSurfaceContainerHigh
                                                            border.color: Theme.colOutline
                                                            border.width: 1
                                                            radius: 8
                                                        }
                                                    }
                                                    delegate: ItemDelegate {
                                                        width: resCombo.popup.width - 8
                                                        height: 36
                                                        highlighted: resCombo.highlightedIndex === index
                                                        background: Rectangle {
                                                            color: highlighted ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.2) : "transparent"
                                                            radius: 6
                                                        }
                                                        contentItem: Text {
                                                            text: modelData
                                                            font.family: root.font.family
                                                            font.weight: Theme.defaultFontWeight; font.pixelSize: 13
                                                            color: Theme.colOnSurface
                                                            verticalAlignment: Text.AlignVCenter
                                                            horizontalAlignment: Text.AlignHCenter
                                                        }
                                                    }
                                                }
                                            }

                                            ColumnLayout {
                                                spacing: 8
                                                Text { text: "Refresh Rate"; color: Theme.colOnSurfaceVariant; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; font.family: root.font.family }
                                                ComboBox {
                                                    id: rateCombo
                                                    property var curRates: monitorCard.modesParsed[monitorCard.selRes] ? monitorCard.modesParsed[monitorCard.selRes].rates : []
                                                    Layout.preferredWidth: 110
                                                    Layout.preferredHeight: 36
                                                    model: rateCombo.curRates.map(function(hz) { return hz + "Hz"; })
                                                    currentIndex: monitorCard.selRate
                                                    onActivated: monitorCard.selRate = index
                                                    
                                                    indicator: Item {}
                                                    background: Rectangle { color: Theme.colSurfaceContainerHigh; radius: 8 }
                                                    contentItem: Text {
                                                        text: rateCombo.currentText + " "
                                                        font.family: root.font.family
                                                        font.pixelSize: 13
                                                        font.weight: 600
                                                        color: Theme.colOnSurface
                                                        verticalAlignment: Text.AlignVCenter
                                                        horizontalAlignment: Text.AlignHCenter
                                                    }
                                                    popup: Popup {
                                                        y: rateCombo.height - 1
                                                        width: rateCombo.width
                                                        implicitHeight: contentItem.implicitHeight
                                                        padding: 4
                                                        contentItem: ListView {
                                                            clip: true
                                                            implicitHeight: Math.min(contentHeight, 200)
                                                            model: rateCombo.popup.visible ? rateCombo.delegateModel : null
                                                            currentIndex: rateCombo.highlightedIndex
                                                            ScrollIndicator.vertical: ScrollIndicator { }
                                                        }
                                                        background: Rectangle {
                                                            color: Theme.colSurfaceContainerHigh
                                                            border.color: Theme.colOutline
                                                            border.width: 1
                                                            radius: 8
                                                        }
                                                    }
                                                    delegate: ItemDelegate {
                                                        width: rateCombo.popup.width - 8
                                                        height: 36
                                                        highlighted: rateCombo.highlightedIndex === index
                                                        background: Rectangle {
                                                            color: highlighted ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.2) : "transparent"
                                                            radius: 6
                                                        }
                                                        contentItem: Text {
                                                            text: modelData
                                                            font.family: root.font.family
                                                            font.weight: Theme.defaultFontWeight; font.pixelSize: 13
                                                            color: Theme.colOnSurface
                                                            verticalAlignment: Text.AlignVCenter
                                                            horizontalAlignment: Text.AlignHCenter
                                                        }
                                                    }
                                                }
                                            }

                                            ColumnLayout {
                                                spacing: 8
                                                Text { text: "Scale"; color: Theme.colOnSurfaceVariant; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; font.family: root.font.family }
                                                ComboBox {
                                                    id: scaleCombo
                                                    Layout.preferredWidth: 100
                                                    Layout.preferredHeight: 36
                                                    model: monitorCard.scaleOptions.map(function(s) { return (s * 100) + "%"; })
                                                    currentIndex: monitorCard.scaleOptions.indexOf(monitorCard.selScale)
                                                    onActivated: monitorCard.selScale = monitorCard.scaleOptions[index]
                                                    
                                                    indicator: Item {}
                                                    background: Rectangle { color: Theme.colSurfaceContainerHigh; radius: 8 }
                                                    contentItem: Text {
                                                        text: scaleCombo.currentText + " "
                                                        font.family: root.font.family
                                                        font.pixelSize: 13
                                                        font.weight: 600
                                                        color: Theme.colOnSurface
                                                        verticalAlignment: Text.AlignVCenter
                                                        horizontalAlignment: Text.AlignHCenter
                                                    }
                                                    popup: Popup {
                                                        y: scaleCombo.height - 1
                                                        width: scaleCombo.width
                                                        implicitHeight: contentItem.implicitHeight
                                                        padding: 4
                                                        contentItem: ListView {
                                                            clip: true
                                                            implicitHeight: Math.min(contentHeight, 200)
                                                            model: scaleCombo.popup.visible ? scaleCombo.delegateModel : null
                                                            currentIndex: scaleCombo.highlightedIndex
                                                            ScrollIndicator.vertical: ScrollIndicator { }
                                                        }
                                                        background: Rectangle {
                                                            color: Theme.colSurfaceContainerHigh
                                                            border.color: Theme.colOutline
                                                            border.width: 1
                                                            radius: 8
                                                        }
                                                    }
                                                    delegate: ItemDelegate {
                                                        width: scaleCombo.popup.width - 8
                                                        height: 36
                                                        highlighted: scaleCombo.highlightedIndex === index
                                                        background: Rectangle {
                                                            color: highlighted ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.2) : "transparent"
                                                            radius: 6
                                                        }
                                                        contentItem: Text {
                                                            text: modelData
                                                            font.family: root.font.family
                                                            font.weight: Theme.defaultFontWeight; font.pixelSize: 13
                                                            color: Theme.colOnSurface
                                                            verticalAlignment: Text.AlignVCenter
                                                            horizontalAlignment: Text.AlignHCenter
                                                        }
                                                    }
                                                }
                                            }
                                            Item { Layout.fillWidth: true }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 16
                                            visible: !monitorCard.pending

                                            Rectangle {
                                                width: 120; height: 40; radius: 20
                                                color: applyArea.containsMouse ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.8) : Theme.colPrimary
                                                Text { anchors.centerIn: parent; text: "Apply"; color: Theme.colOnPrimary; font.weight: Math.min(900, Theme.defaultFontWeight + 200); font.family: root.font.family; font.pixelSize: Theme.defaultFontSize }
                                                MouseArea {
                                                    id: applyArea
                                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        let res = monitorCard.modesParsed[monitorCard.selRes];
                                                        let hz = res.rates[monitorCard.selRate];
                                                        let modeStr = res.w + "x" + res.h + "@" + hz;
                                                        displayPage.applyDisplay(modelData, modeStr, monitorCard.selScale);
                                                    }
                                                }
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 16
                                            visible: monitorCard.pending

                                            Rectangle {
                                                width: 160; height: 40; radius: 20
                                                color: Theme.colError
                                                Text { anchors.centerIn: parent; text: "Keep Changes (" + displayPage.countdown + "s)"; color: Theme.colOnError; font.weight: Math.min(900, Theme.defaultFontWeight + 200); font.family: root.font.family; font.pixelSize: Theme.defaultFontSize }
                                                MouseArea {
                                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: displayPage.keepDisplay()
                                                }
                                            }
                                            Text {
                                                text: "Reverts automatically if not confirmed"
                                                color: Theme.colOnSurfaceVariant
                                                font.weight: Theme.defaultFontWeight; font.pixelSize: 12
                                                font.family: root.font.family
                                            }
                                        }
                                    }
                                }
                            }

                        }
                    }
                }
            }
            }
        }
        }
        }
    }
}
}}
