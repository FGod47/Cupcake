//@ pragma UseQApplication
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "../../theme"
import Quickshell.Wayland
import "../common"

Item {
    id: root
    readonly property string homeDir: Quickshell.env("HOME")
    width: 868
    height: 768
    signal requestClose()
    
    property var font: {"family": Theme.monoFontFamily}
    property int currentIndex: 10
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
    property real dockOpacity: 0.50
    property real osdOpacity: 0.95
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





    // Theme Colors based on reference design
    property color cBg: Theme.isDark ? "#0a0d11" : "#eef0f3"
    property color cBgElevated: Theme.isDark ? "#12161c" : "#f7f8fa"
    property color cSurface: Theme.isDark ? "#171c24" : "#ffffff"
    property color cSurfaceHover: Theme.isDark ? "#1e242e" : "#eef1f5"
    property color cSurfaceActive: Theme.isDark ? "#232a35" : "#e6eaf0"
    property color cBorder: Theme.isDark ? "#242b36" : "#dde1e7"
    property color cBorderSoft: Theme.isDark ? "#1a2029" : "#e5e8ed"
    property color cText: Theme.isDark ? "#e8ecf1" : "#171b21"
    property color cTextDim: Theme.isDark ? "#8891a0" : "#5b6472"
    property color cTextFaint: Theme.isDark ? "#4d5566" : "#9aa2af"
    property color cAccent: Theme.colPrimary
    property color cAccentDim: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.14)

    Rectangle {
        id: mainWrapper
        anchors.fill: parent
        color: cBgElevated
        border.color: cBorder
        border.width: 1
        radius: 16
        clip: true
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            onPressed: mouse.accepted = true
            onReleased: mouse.accepted = true
            onClicked: mouse.accepted = true
            onWheel: wheel.accepted = true
            
            Keys.onPressed: (event) => {
                if (event.modifiers === Qt.ControlModifier) {
                    if (event.key === Qt.Key_Tab) {
                        root.currentIndex = (root.currentIndex + 1) % 6;
                        event.accepted = true;
                    }
                }
            }
        }
        
        RowLayout {
            anchors.fill: parent
            spacing: 0
            
            // ICON RAIL
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 64
                color: cBg
                
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: cBorderSoft
                }
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: 16
                    anchors.bottomMargin: 16
                    spacing: 4
                    
                    // Logo
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 0
                        Layout.bottomMargin: 18
                        width: 34; height: 34
                        radius: 9
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: cAccent }
                            GradientStop { position: 1.0; color: Theme.colPrimary } // accent-2
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "A"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 15
                            font.weight: 700
                            color: "#0a0d11"
                        }
                    }
                    
                    component RailBtn: Item {
                        property string icon
                        property string tip
                        property int pageIndex
                        property bool isActive: root.currentIndex === pageIndex || (pageIndex === 1 && [0,1,3,4].includes(root.currentIndex))
                        
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        Layout.alignment: Qt.AlignHCenter
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: isActive ? cAccentDim : (ma.containsMouse ? cSurfaceHover : "transparent")
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        
                        Rectangle {
                            visible: isActive
                            anchors.left: parent.left
                            anchors.leftMargin: -10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3; height: 16
                            radius: 2
                            color: cAccent
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: icon
                            font.family: "tabler-icons"
                            font.pixelSize: 19
                            color: isActive ? cAccent : (ma.containsMouse ? cTextDim : cTextFaint)
                        }
                        
                        // Tooltip
                        Rectangle {
                            id: tooltip
                            anchors.left: parent.right
                            anchors.leftMargin: ma.containsMouse ? 12 : 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: tipText.implicitWidth + 18
                            height: tipText.implicitHeight + 10
                            radius: 6
                            color: Theme.isDark ? "#000000" : "#171b21"
                            opacity: ma.containsMouse ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                            Behavior on anchors.leftMargin { NumberAnimation { duration: 120 } }
                            Text {
                                id: tipText
                                anchors.centerIn: parent
                                text: tip
                                color: "#ffffff"
                                font.pixelSize: 11.5
                                font.weight: 500
                                font.family: Theme.defaultFontFamily
                            }
                        }
                        
                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentIndex = pageIndex
                        }
                    }
                    
                    RailBtn { icon: ""; tip: "System"; pageIndex: 10 }
                    RailBtn { icon: ""; tip: "Appearance"; pageIndex: 1 }
                    RailBtn { icon: ""; tip: "Displays"; pageIndex: 18 }
                    RailBtn { icon: ""; tip: "Network"; pageIndex: 17 }
                    RailBtn { icon: ""; tip: "Sound"; pageIndex: 7 }
                    RailBtn { icon: ""; tip: "Power"; pageIndex: 13 }
                    RailBtn { icon: ""; tip: "Updates"; pageIndex: 11 }
                    
                    Item { Layout.fillHeight: true } // spacer
                    
                    RailBtn { icon: ""; tip: "About"; pageIndex: 21 }
                }
            }
            
            // MAIN
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0
                
                // TOPBAR
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    color: "transparent"
                    
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: cBorderSoft
                    }
                    
                    function getPageData(index) {
                        switch(index) {
                            case 0: return { title: "Appearance", path: "settings › appearance › general" };
                            case 1: return { title: "Appearance", path: "settings › appearance › wallpaper" };
                            case 3: return { title: "Appearance", path: "settings › appearance › desktop" };
                            case 4: return { title: "Appearance", path: "settings › appearance › dock" };
                            case 6: return { title: "Notifications", path: "settings › notifications" };
                            case 7: return { title: "Sound", path: "settings › sound" };
                            case 8: return { title: "Shell", path: "settings › shell" };
                            case 10: return { title: "System", path: "settings › system" };
                            case 11: return { title: "Updates", path: "settings › updates" };
                            case 12: return { title: "Location", path: "settings › location" };
                            case 13: return { title: "Power", path: "settings › power" };
                            case 17: return { title: "Network", path: "settings › network" };
                            case 23: return { title: "Hotspot", path: "settings › network › hotspot" };
                            case 22: return { title: "Bluetooth", path: "settings › bluetooth" };
                            case 18: return { title: "Displays", path: "settings › displays" };
                            case 19: return { title: "AI", path: "settings › ai" };
                            case 20: return { title: "User", path: "settings › user" };
                            case 21: return { title: "About", path: "settings › about" };
                            default: return { title: "Settings", path: "settings" };
                        }
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 24
                        anchors.rightMargin: 24
                        spacing: 16
                        
                        ColumnLayout {
                            spacing: 1
                            Text {
                                text: parent.parent.getPageData(root.currentIndex).title
                                color: cText
                                font.family: Theme.defaultFontFamily // Should be Space Grotesk in HTML but we use system
                                font.pixelSize: 18
                                font.weight: 600
                                font.letterSpacing: -0.3
                            }
                            Text {
                                text: parent.parent.getPageData(root.currentIndex).path
                                color: cTextFaint
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 12
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        // Search
                        Rectangle {
                            Layout.preferredWidth: 230
                            Layout.preferredHeight: 34
                            radius: 8
                            color: cSurface
                            border.color: cBorder
                            border.width: 1
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 5
                                Text {
                                    text: "" // search icon
                                    font.family: "tabler-icons"
                                    color: cTextFaint
                                }
                                TextInput {
                                    Layout.fillWidth: true
                                    color: cText
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 12.5
                                }
                                Rectangle {
                                    Layout.preferredWidth: 26
                                    Layout.preferredHeight: 18
                                    radius: 4
                                    color: "transparent"
                                    border.color: cBorder
                                    border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: "⌘K"
                                        font.family: Theme.monoFontFamily
                                        font.pixelSize: 10.5
                                        color: cTextFaint
                                    }
                                }
                            }
                        }
                        
                        // Close button
                        Rectangle {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            radius: 8
                            color: "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: "" // X icon
                                font.family: "tabler-icons"
                                color: cTextFaint
                                font.pixelSize: 18
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.requestClose()
                            }
                        }
                    }
                }
                
                // CONTENT GRID
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 24
                    spacing: 20
                    
                    // PANELS
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        
                        // Appearance Top Nav Bar
                        Rectangle {
                            id: appNav
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: isAppearanceCategory ? 40 : 0
                            visible: isAppearanceCategory
                            opacity: isAppearanceCategory ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                            color: cSurfaceActive
                            border.color: cBorder
                            border.width: 1
                            radius: 10
                            clip: true
                            
                            property bool isAppearanceCategory: [0, 1, 4, 3].includes(root.currentIndex)
                            
                            RowLayout {
                                anchors.fill: parent
                                spacing: 0
                                
                                component TopNavBtn: Item {
                                    property string text
                                    property string icon
                                    property int pageIndex
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        radius: 8
                                        color: root.currentIndex === pageIndex ? cAccentDim : (ma.containsMouse ? cSurfaceHover : "transparent")
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                    
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 7
                                        Text {
                                            text: parent.parent.icon
                                            font.family: "tabler-icons"
                                            font.pixelSize: 14
                                            color: root.currentIndex === pageIndex ? cAccent : cTextDim
                                        }
                                        Text {
                                            text: parent.parent.text
                                            font.family: Theme.defaultFontFamily
                                            font.pixelSize: 13
                                            font.weight: Font.Medium
                                            color: root.currentIndex === pageIndex ? cText : cTextDim
                                        }
                                    }
                                    MouseArea {
                                        id: ma
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.currentIndex = pageIndex
                                    }
                                }
                                
                                TopNavBtn { text: "Wallpaper"; icon: ""; pageIndex: 1 }
                                TopNavBtn { text: "General"; icon: ""; pageIndex: 0 }
                                TopNavBtn { text: "Dock"; icon: ""; pageIndex: 4 }
                                TopNavBtn { text: "Desktop"; icon: ""; pageIndex: 3 }
                            }
                        }
                        
                        Item {
                            anchors.top: appNav.bottom
                            anchors.topMargin: appNav.isAppearanceCategory ? 14 : 0
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            
                            // LOADERS INJECTED HERE
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
                        source: "SettingsPageGeneral.qml"
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

                // PAGE 22: BLUETOOTH
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 22 ? 0 : 20
                    opacity: root.currentIndex === 22 ? 1 : 0
                    visible: root.currentIndex === 22 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    Loader { anchors.fill: parent; active: root.currentIndex === 22; source: "SettingsPageBluetooth.qml" }
                }

                // PAGE 23: HOTSPOT
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 23 ? 0 : 20
                    opacity: root.currentIndex === 23 ? 1 : 0
                    visible: root.currentIndex === 23 || opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    Loader { anchors.fill: parent; active: root.currentIndex === 23; source: "SettingsPageHotspot.qml" }
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
                    
                    // SESSION CARD
                    Rectangle {
                        Layout.preferredWidth: 250
                        Layout.alignment: Qt.AlignTop
                        implicitHeight: fetchCol.implicitHeight + 36
                        radius: 10
                        color: cSurface
                        border.color: cBorder
                        border.width: 1
                        
                        ColumnLayout {
                            id: fetchCol
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 4
                            
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "      /\ 
     /  \ 
    /    \ 
   /      \ 
  /   ,,   \ 
 /   |  |   \ 
/_-''    ''-_\"
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 9.5
                                font.weight: 600
                                color: cAccent
                                horizontalAlignment: Text.AlignHCenter
                                Layout.bottomMargin: 12
                            }
                            
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: Quickshell.env("USER") + "@" + Quickshell.env("HOSTNAME")
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 12.5
                                font.weight: 600
                                color: cText
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "------------------"
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 10.5
                                color: cTextFaint
                                Layout.bottomMargin: 10
                            }
                            
                            component FetchLine: RowLayout {
                                property string key
                                property string val
                                Layout.fillWidth: true
                                Text { text: key; color: cTextFaint; font.family: Theme.monoFontFamily; font.pixelSize: 11.5 }
                                Item { Layout.fillWidth: true }
                                Text { text: val; color: cTextDim; font.family: Theme.monoFontFamily; font.pixelSize: 11.5 }
                            }
                            
                            FetchLine { key: "OS"; val: "Arch Linux x86_64" }
                            FetchLine { key: "Kernel"; val: "6.10.3-arch1-1" }
                            FetchLine { key: "WM"; val: "Hyprland" }
                            FetchLine { key: "Shell"; val: "zsh 5.9" }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.topMargin: 10
                                Layout.bottomMargin: 10
                                height: 1
                                color: cBorderSoft
                            }
                            
                            // CPU / RAM bars
                            component FetchBar: ColumnLayout {
                                property string label
                                property string val
                                property real percent
                                Layout.fillWidth: true
                                spacing: 4
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: label; color: cTextFaint; font.family: Theme.monoFontFamily; font.pixelSize: 10.5 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: val; color: cTextFaint; font.family: Theme.monoFontFamily; font.pixelSize: 10.5 }
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 5
                                    radius: 3
                                    color: cSurfaceActive
                                    Rectangle {
                                        width: parent.width * parent.parent.percent
                                        height: parent.height
                                        radius: 3
                                        color: cAccent
                                    }
                                }
                            }
                            
                            FetchBar { label: "CPU"; val: "23%"; percent: 0.23 }
                            Item { Layout.preferredHeight: 6 }
                            FetchBar { label: "RAM"; val: "41%"; percent: 0.41 }
                            
                            Item { Layout.preferredHeight: 12 }
                            
                            // Swatches
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                component SSwatch: Rectangle { Layout.fillWidth: true; height: 8; radius: 2; property color c; color: c }
                                SSwatch { c: "#2b2f38" }
                                SSwatch { c: "#f2777a" }
                                SSwatch { c: "#7ee787" }
                                SSwatch { c: "#e6b450" }
                                SSwatch { c: "#4fb8e8" }
                                SSwatch { c: "#9d8cf2" }
                                SSwatch { c: "#66c2cd" }
                                SSwatch { c: "#e8ecf1" }
                            }
                        }
                    }
                }
            }
        }
    }
}
