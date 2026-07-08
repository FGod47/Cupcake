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
    property int currentIndex: 1
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
                        text: "\ueb55"
                        color: Theme.colOnSurfaceVariant
                        font.family: "tabler-icons"
                        font.pixelSize: 18
                    }
                }
                
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 12
                spacing: 4

                // Navigation Rail
                Item {
                    Layout.fillHeight: true
                    Layout.preferredWidth: navExpanded ? 220 : 72
                    Behavior on Layout.preferredWidth { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                    
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
                                property bool isActive: root.currentIndex === pageIndex

                                Layout.fillWidth: true
                                implicitHeight: 44
                                
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    anchors.topMargin: 2
                                    anchors.bottomMargin: 2
                                    radius: 12
                                    color: isActive 
                                        ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.15)
                                        : (navMouseArea.containsMouse ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05) : "transparent")
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 24
                                    spacing: 12
                                    
                                    Text {
                                        text: iconText
                                        color: isActive ? Theme.colPrimary : Theme.colOnSurfaceVariant
                                        font.family: "tabler-icons"
                                        font.weight: Theme.defaultFontWeight; font.pixelSize: 18
                                        opacity: isActive ? 1.0 : 0.6
                                    }
                                    
                                    Text {
                                        visible: navExpanded
                                        text: labelText
                                        color: Theme.colOnSurface
                                        font.family: Theme.defaultFontFamily
                                        font.pixelSize: Theme.defaultFontSize
                                        font.weight: Math.min(900, Theme.defaultFontWeight + 200)
                                        Layout.fillWidth: true
                                        opacity: isActive ? 1.0 : 0.6
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
                        
                        NavButton { iconText: "\ueb01"; labelText: "Appearance"; pageIndex: 1; isActive: [0, 103, 1, 4, 3].includes(root.currentIndex) }
                        NavButton { iconText: "\uead7"; labelText: "Panels"; pageIndex: 5 }
                        NavButton { iconText: "\uea35"; labelText: "Notifications"; pageIndex: 6 }
                        NavButton { iconText: "\ueaed"; labelText: "OSD"; pageIndex: 7 }
                        NavButton { iconText: "\uebdc"; labelText: "Shell"; pageIndex: 8 }
                        
                        NavHeader { text: "SYSTEM" }
                        NavButton { iconText: "\ueb20"; labelText: "System"; pageIndex: 10 }
                        NavButton { iconText: "\ueb1f"; labelText: "Services"; pageIndex: 11 }
                        NavButton { iconText: "\ueae8"; labelText: "Location"; pageIndex: 12 }
                        NavButton { iconText: "\ueb0d"; labelText: "Power"; pageIndex: 13 }
                        

                        NavHeader { text: "CUPCAKE EXTRA" }
                        NavButton { iconText: "\ueb52"; labelText: "Network"; pageIndex: 17 }
                        NavButton { iconText: "\uea89"; labelText: "Display"; pageIndex: 18 }
                        NavButton { iconText: "\uf6d7"; labelText: "AI"; pageIndex: 19 }
                        NavButton { iconText: "\ueb4d"; labelText: "User"; pageIndex: 20 }
                        NavButton { iconText: "\ueac5"; labelText: "About"; pageIndex: 21 }

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
                            case 0: return { icon: "\ueb01", title: "Appearance" };
                            case 1: return { icon: "\ueb0a", title: "Wallpaper" };
                            case 3: return { icon: "\uea89", title: "Desktop" };
                            case 4: return { icon: "\uead3", title: "Dock" };
                            case 5: return { icon: "\uead7", title: "Panels" };
                            case 6: return { icon: "\uea35", title: "Notifications" };
                            case 7: return { icon: "\ueaed", title: "OSD" };
                            case 8: return { icon: "\uebdc", title: "Shell" };
                            case 10: return { icon: "\ueb20", title: "System" };
                            case 11: return { icon: "\ueb1f", title: "Services" };
                            case 12: return { icon: "\ueae8", title: "Location" };
                            case 13: return { icon: "\ueb0d", title: "Power" };
                            case 17: return { icon: "\ueb52", title: "Network" };
                            case 18: return { icon: "\uea89", title: "Display" };
                            case 19: return { icon: "\uf6d7", title: "AI" };
                            case 20: return { icon: "\ueb4d", title: "User" };
                            case 21: return { icon: "\ueac5", title: "About" };
                            default: return { icon: "\ueb20", title: "Settings" };
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
                                    font.family: "tabler-icons"
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

                        // Appearance Top Nav Bar
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: isAppearanceCategory ? 48 : 0
                            Layout.leftMargin: 24
                            Layout.rightMargin: 24
                            Layout.topMargin: 0
                            Layout.bottomMargin: 8
                            visible: isAppearanceCategory
                            opacity: isAppearanceCategory ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            radius: 12
                            clip: true
                            
                            property bool isAppearanceCategory: [0, 103, 1, 4, 3].includes(root.currentIndex)
                            
                            Flickable {
                                anchors.fill: parent
                                anchors.margins: 4
                                contentWidth: topBarRow.implicitWidth
                                boundsBehavior: Flickable.StopAtBounds
                                clip: true
                                
                                RowLayout {
                                    id: topBarRow
                                    height: parent.height
                                    spacing: 4
                                    
                                    component TopNavBtn: Rectangle {
                                        property string text
                                        property int pageIndex
                                        implicitWidth: txt.implicitWidth + 32
                                        Layout.fillHeight: true
                                        radius: 8
                                        color: root.currentIndex === pageIndex ? Theme.colOnSurface : (ma.containsMouse ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05) : "transparent")
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        
                                        Text {
                                            id: txt
                                            anchors.centerIn: parent
                                            text: parent.text
                                            font.family: Theme.defaultFontFamily
                                            font.pixelSize: 13
                                            font.weight: root.currentIndex === pageIndex ? Font.Bold : Font.Medium
                                            color: root.currentIndex === pageIndex ? Theme.colBackground : Theme.colOnSurfaceVariant
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                        MouseArea {
                                            id: ma
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: root.currentIndex = pageIndex
                                        }
                                    }
                                    
                                    TopNavBtn { text: "Wallpaper"; pageIndex: 1 }
                                    TopNavBtn { text: "General"; pageIndex: 0 }
                                    TopNavBtn { text: "Window Gaps"; pageIndex: 103 }
                                    TopNavBtn { text: "Dock"; pageIndex: 4 }
                                    TopNavBtn { text: "Desktop"; pageIndex: 3 }
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
                    Loader {
                        anchors.fill: parent
                        active: root.currentIndex === 0
                        source: "SettingsPageAppearance.qml"
                    }
                }

                // PAGE 101: WIDGETS
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 101 ? 0 : 20
                    opacity: root.currentIndex === 101 ? 1 : 0
                    visible: root.currentIndex === 101 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    Loader { anchors.fill: parent; active: root.currentIndex === 101; source: "SettingsPageWidgets.qml" }
                }

                // PAGE 102: SCREEN CORNERS
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 102 ? 0 : 20
                    opacity: root.currentIndex === 102 ? 1 : 0
                    visible: root.currentIndex === 102 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    Loader { anchors.fill: parent; active: root.currentIndex === 102; source: "SettingsPageScreenCorners.qml" }
                }

                // PAGE 103: WINDOW GAPS
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 103 ? 0 : 20
                    opacity: root.currentIndex === 103 ? 1 : 0
                    visible: root.currentIndex === 103 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    Loader { anchors.fill: parent; active: root.currentIndex === 103; source: "SettingsPageWindowGaps.qml" }
                }

                // PAGE 1: WALLPAPERS
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 1 ? 0 : 20
                    opacity: root.currentIndex === 1 ? 1 : 0
                    visible: root.currentIndex === 1 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Loader {
                        anchors.fill: parent
                        active: root.currentIndex === 1
                        asynchronous: true
                        source: "SettingsPageWallpaper.qml"
                    }
                }

                // PAGE 3: DESKTOP
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 3 ? 0 : 20
                    opacity: root.currentIndex === 3 ? 1 : 0
                    visible: root.currentIndex === 3 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    Loader { anchors.fill: parent; active: root.currentIndex === 3; source: "SettingsPageDesktop.qml" }
                }

                // PAGE 4: DOCK
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 4 ? 0 : 20
                    opacity: root.currentIndex === 4 ? 1 : 0
                    visible: root.currentIndex === 4 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    Loader { anchors.fill: parent; active: root.currentIndex === 4; source: "SettingsPageDock.qml" }
                }

                // PAGE 5: PANELS
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 5 ? 0 : 20
                    opacity: root.currentIndex === 5 ? 1 : 0
                    visible: root.currentIndex === 5 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    Loader { anchors.fill: parent; active: root.currentIndex === 5; source: "SettingsPagePanels.qml" }
                }

                // PAGE 6: NOTIFICATIONS
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 6 ? 0 : 20
                    opacity: root.currentIndex === 6 ? 1 : 0
                    visible: root.currentIndex === 6 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    Loader { anchors.fill: parent; active: root.currentIndex === 6; source: "SettingsPageNotifications.qml" }
                }

                // PAGE 7: OSD
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 7 ? 0 : 20
                    opacity: root.currentIndex === 7 ? 1 : 0
                    visible: root.currentIndex === 7 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    Loader { anchors.fill: parent; active: root.currentIndex === 7; source: "SettingsPageOsd.qml" }
                }

                // PAGE 8: SHELL
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 8 ? 0 : 20
                    opacity: root.currentIndex === 8 ? 1 : 0
                    visible: root.currentIndex === 8 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    Loader { anchors.fill: parent; active: root.currentIndex === 8; source: "SettingsPageShell.qml" }
                }

                // PAGE 10: SYSTEM
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 10 ? 0 : 20
                    opacity: root.currentIndex === 10 ? 1 : 0
                    visible: root.currentIndex === 10 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    Loader { anchors.fill: parent; active: root.currentIndex === 10; source: "SettingsPageSystem.qml" }
                }

                // PAGE 11: SERVICES
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 11 ? 0 : 20
                    opacity: root.currentIndex === 11 ? 1 : 0
                    visible: root.currentIndex === 11 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    Loader { anchors.fill: parent; active: root.currentIndex === 11; source: "SettingsPageServices.qml" }
                }

                // PAGE 12: LOCATION
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 12 ? 0 : 20
                    opacity: root.currentIndex === 12 ? 1 : 0
                    visible: root.currentIndex === 12 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    Loader { anchors.fill: parent; active: root.currentIndex === 12; source: "SettingsPageLocation.qml" }
                }

                // PAGE 13: POWER
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 13 ? 0 : 20
                    opacity: root.currentIndex === 13 ? 1 : 0
                    visible: root.currentIndex === 13 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    Loader { anchors.fill: parent; active: root.currentIndex === 13; source: "SettingsPagePower.qml" }
                }

                // PAGE 17: NETWORK
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 17 ? 0 : 20
                    opacity: root.currentIndex === 17 ? 1 : 0
                    visible: root.currentIndex === 17 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    Loader { anchors.fill: parent; active: root.currentIndex === 17; source: "SettingsPageNetwork.qml" }
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
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Loader { anchors.fill: parent; active: root.currentIndex === 18; source: "SettingsPageDisplay.qml" }
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
