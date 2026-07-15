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
                                font.pixelSize: 11
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
                    id: topBarRect
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
                                text: topBarRect.getPageData(root.currentIndex).title
                                color: cText
                                font.family: Theme.defaultFontFamily // Should be Space Grotesk in HTML but we use system
                                font.pixelSize: 18
                                font.weight: 600
                                font.letterSpacing: -0.3
                            }
                            Text {
                                text: topBarRect.getPageData(root.currentIndex).path
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
                                    font.pixelSize: 12
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
                                        font.pixelSize: 10
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
            
                        }
                    }
                    

                }
            }
        }
    }
}
