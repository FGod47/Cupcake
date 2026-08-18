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
    property int windowRadius: 10
    width: 1200
    height: 900
    signal requestClose()
    
    property var font: {"family": Theme.monoFontFamily}
    property int currentIndex: 1
    property var barMonitors: ["all"]
    property var dockMonitors: ["all"]

    property string username: Quickshell.env("USER") || "zero"
    property string hostname: "infinity"
    property string realName: "Zero"
    property string userAvatar: ""

    Process {
        id: userInfoProcess
        command: ["bash", "-c", "hostname; whoami; getent passwd $USER 2>/dev/null | cut -d ':' -f 5 | cut -d ',' -f 1; ls ~/.face ~/.face.icon ~/.local/share/qylock-themes/cupcake-sddm/avatar.png 2>/dev/null | head -n 1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                let lines = text.trim().split("\n");
                if (lines[0] && lines[0].trim() !== "") root.hostname = lines[0].trim();
                if (lines[1] && lines[1].trim() !== "") root.username = lines[1].trim();
                if (lines[2] && lines[2].trim() !== "") root.realName = lines[2].trim();
                if (lines[3] && lines[3].trim() !== "") root.userAvatar = lines[3].trim();
            }
        }
    }

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


    property bool navExpanded: false

    // Extracted StyledSwitch to StyledSwitch.qml

    // Extracted StyledSlider to StyledSlider.qml





    // Theme Colors based on reference design
    property color cBg: Theme.isDark ? Theme.colBackground : Theme.colSurface
    property color cBgElevated: Theme.isDark ? Theme.colSurfaceContainer : Theme.colSurfaceContainer
    property color cSurface: Theme.isDark ? Theme.colSurface : Theme.colBackground
    property color cSurfaceHover: Theme.isDark ? Theme.colSurfaceContainerHigh : Theme.colSurfaceVariant
    property color cSurfaceActive: Theme.isDark ? Theme.colSurfaceVariant : Theme.colSurface
    property color cBorder: Theme.isDark ? Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.4) : Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.25)
    property color cBorderSoft: Theme.isDark ? Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.2) : Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
    property color cText: Theme.colOnBackground
    property color cTextDim: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.60)
    property color cTextFaint: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.38)
    property color cAccent: Theme.colPrimary
    property color cAccentDim: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.14)
    property color cAccentOn: {
        let lum = cAccent.r * 0.299 + cAccent.g * 0.587 + cAccent.b * 0.114;
        return lum > 0.5 ? "#14140c" : "#ffffff";
    }

    Rectangle {
        id: mainWrapper
        anchors.fill: parent
        color: "transparent"
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
            
            // RAIL
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 212
                color: cBg
                topLeftRadius: root.windowRadius
                bottomLeftRadius: root.windowRadius
                clip: true
                
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: cBorderSoft
                }
                
                Item {
                    anchors.fill: sidebarColumn
                    Rectangle {
                        id: sidebarHighlight
                        property Item activeItem: null
                        property bool isVisible: root.currentIndex !== 20 && activeItem !== null
                        
                        opacity: isVisible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                        
                        x: activeItem ? activeItem.x : 0
                        y: activeItem ? activeItem.y : 0
                        width: activeItem ? activeItem.width : 0
                        height: activeItem ? activeItem.height : 0
                        
                        color: cAccent
                        radius: 10
                        
                        Behavior on y { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
                        Behavior on height { NumberAnimation { duration: Theme.liquidify ? 800 : 250; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutCubic; easing.amplitude: 1.0; easing.period: 0.85 } }
                    }
                }
                
                ColumnLayout {
                    id: sidebarColumn
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 20
                    anchors.bottomMargin: 20
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 0
                    
                    // BRAND
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        Layout.bottomMargin: 16
                        Layout.topMargin: 6
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        spacing: 10
                        
                        Item {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredHeight: 50
                            Layout.preferredWidth: settingsLogo.implicitWidth > 0 ? settingsLogo.implicitWidth : 160
                            implicitHeight: 50
                            implicitWidth: settingsLogo.implicitWidth > 0 ? settingsLogo.implicitWidth : 160
                            
                            Image {
                                id: settingsLogo
                                source: "file://" + root.homeDir + "/.config/quickshell/assets/cupcake-shellsettings-" + (Theme.isDark ? "light" : "dark") + ".svg"
                                sourceSize.height: 50
                                fillMode: Image.PreserveAspectFit
                                height: 50
                                layer.enabled: true
                                layer.effect: ColorOverlay {
                                    color: root.colOnSurface
                                }
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }
                    
                    component GroupLabel: Text {
                        property string label: ""
                        text: label
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 0.8
                        font.capitalization: Font.AllUppercase
                        color: cTextFaint
                        Layout.topMargin: 14
                        Layout.bottomMargin: 6
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                    }
                    
                    component RailItem: Rectangle {
                        id: railItemRoot
                        property string label
                        property string icon
                        property int pageIndex
                        property bool isActive: root.currentIndex === pageIndex || (pageIndex === 1 && [1,3].includes(root.currentIndex))
                        
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 10
                        color: isActive ? "transparent" : (ma.containsMouse ? cSurfaceHover : "transparent")
                        Behavior on color { ColorAnimation { duration: 140 } }
                        
                        onIsActiveChanged: {
                            if (isActive) sidebarHighlight.activeItem = railItemRoot
                        }
                        Component.onCompleted: {
                            if (isActive) sidebarHighlight.activeItem = railItemRoot
                        }
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10
                            
                            Text {
                                text: railItemRoot.icon
                                font.family: "tabler-icons"
                                font.pixelSize: 17
                                color: (railItemRoot.isActive && root.currentIndex !== 20) ? root.cAccentOn : (ma.containsMouse ? cText : cTextDim)
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }
                            Text {
                                text: railItemRoot.label
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 13
                                font.weight: (railItemRoot.isActive && root.currentIndex !== 20) ? Font.DemiBold : Font.Medium
                                color: (railItemRoot.isActive && root.currentIndex !== 20) ? root.cAccentOn : (ma.containsMouse ? cText : cTextDim)
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }
                            Item { Layout.fillWidth: true }
                        }
                        
                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentIndex = parent.pageIndex
                        }
                    }
                    
                    GroupLabel { label: "Preferences" }
                    RailItem { icon: "\ueb01"; label: "Appearance"; pageIndex: 1 }    // palette
                    RailItem { icon: "\uead7"; label: "Bar"; pageIndex: 6 }           // layout-navbar
                    RailItem { icon: "\uf28e"; label: "Dock"; pageIndex: 4 }          // layout-navbar-expand
                    RailItem { icon: "\uebc5"; label: "Fonts"; pageIndex: 2 }         // typography
                    RailItem { icon: "\ueb20"; label: "General"; pageIndex: 0 }       // settings
                    RailItem { icon: "\ueae2"; label: "Lock screen"; pageIndex: 24 }  // lock
                    RailItem { icon: "\ueb0a"; label: "Wallpaper"; pageIndex: 5 }     // photo
                    
                    GroupLabel { label: "Machine" }
                    RailItem { icon: "\uea37"; label: "Bluetooth"; pageIndex: 22 }    // bluetooth
                    RailItem { icon: "\uea89"; label: "Displays"; pageIndex: 18 }     // device-desktop
                    RailItem { icon: "\ueb52"; label: "Network"; pageIndex: 17 }      // wifi
                    RailItem { icon: "\uef3b"; label: "Power"; pageIndex: 13 }        // battery-charging-2
                    RailItem { icon: "\ueb51"; label: "Sound"; pageIndex: 7 }         // volume
                    RailItem { icon: "\uef8e"; label: "System"; pageIndex: 10 }       // cpu
                    RailItem { icon: "\ueb1d"; label: "Updates"; pageIndex: 11 }      // download
                    RailItem { icon: "\ueac5"; label: "About"; pageIndex: 21 }        // info-circle
                    
                    Item { Layout.fillHeight: true } // spacer
                    
                    // FOOTER (USER PROFILE CARD)
                    Rectangle {
                        id: footerUserCard
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        Layout.topMargin: 8
                        color: (root.currentIndex === 20) 
                               ? (Theme.isDark ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.16) : Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12))
                               : (userFooterMa.containsMouse ? (Theme.isDark ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.06))
                                                             : (Theme.isDark ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04) : Qt.rgba(0, 0, 0, 0.03)))
                        radius: 10
                        border.width: 1
                        border.color: (root.currentIndex === 20) 
                                      ? Theme.colPrimary 
                                      : (userFooterMa.containsMouse ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.14) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.07))
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10
                            
                            // User Avatar
                            Rectangle {
                                width: 32; height: 32; radius: 16
                                color: cBgElevated
                                border.color: root.currentIndex === 20 ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                                border.width: 1
                                clip: true

                                Rectangle {
                                    id: footerAvatarMask
                                    anchors.fill: parent
                                    radius: 16
                                    visible: false
                                }

                                Item {
                                    anchors.fill: parent
                                    layer.enabled: true
                                    layer.effect: OpacityMask { maskSource: footerAvatarMask }

                                    Image {
                                        anchors.fill: parent
                                        source: root.userAvatar !== "" ? ("file://" + root.userAvatar) : ("file://" + root.homeDir + "/.local/share/qylock-themes/cupcake-sddm/avatar.png")
                                        fillMode: Image.PreserveAspectCrop
                                        visible: status === Image.Ready
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: root.userAvatar === ""
                                        text: root.username.length > 0 ? root.username.charAt(0).toUpperCase() : "U"
                                        font.family: Theme.defaultFontFamily
                                        font.pixelSize: 13
                                        font.weight: Font.Bold
                                        color: Theme.colPrimary
                                    }
                                }
                            }

                            ColumnLayout {
                                spacing: 1
                                Layout.fillWidth: true
                                Text {
                                    text: root.realName !== "" ? root.realName : root.username
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    color: (root.currentIndex === 20) ? Theme.colPrimary : cText
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: root.hostname
                                    font.family: Theme.monoFontFamily
                                    font.pixelSize: 10
                                    color: cTextFaint
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        MouseArea {
                            id: userFooterMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentIndex = 20;
                            }
                        }
                    }
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
                    Layout.preferredHeight: 70
                    Layout.bottomMargin: 16
                    color: "transparent"
                    
                    function getPageData(index) {
                        switch(index) {
                            case 0: return { title: "General", path: "settings › general" };
                            case 1: return { title: "Appearance", path: "settings › appearance › wallpaper" };
                            case 2: return { title: "Fonts", path: "settings › fonts" };
                            case 3: return { title: "Appearance", path: "settings › appearance › desktop" };
                            case 4: return { title: "Dock", path: "settings › dock" };
                            case 5: return { title: "Wallpaper", path: "settings › wallpaper" };
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
                            case 24: return { title: "Lock screen", path: "settings › lock screen" };
                            default: return { title: "Settings", path: "settings" };
                        }
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 32
                        anchors.rightMargin: 32
                        anchors.topMargin: 22
                        anchors.bottomMargin: 6
                        spacing: 16
                        
                        ColumnLayout {
                            spacing: 2
                            Text {
                                text: topBarRect.getPageData(root.currentIndex).title
                                color: cText
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 22
                                font.weight: Font.Black
                                font.letterSpacing: -0.4
                            }
                            Text {
                                text: topBarRect.getPageData(root.currentIndex).path
                                color: cTextFaint
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 11
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                        

                        
                        // Close button
                        Item {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 26
                            Layout.leftMargin: 4
                            Rectangle {
                                anchors.centerIn: parent
                                width: 26
                                height: 26
                                radius: 13
                                color: closeMa.containsMouse ? Qt.rgba(cText.r, cText.g, cText.b, 0.08) : Qt.rgba(cText.r, cText.g, cText.b, 0.04)
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: "" // X icon
                                    font.family: "tabler-icons"
                                    color: closeMa.containsMouse ? cText : cTextFaint
                                    font.pixelSize: 14
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                MouseArea {
                                    id: closeMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.requestClose()
                                }
                            }
                        }
                    }
                }
                
                // CONTENT GRID
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0
                    
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        
                        Loader {
                            id: contentLoader
                            anchors.fill: parent
                            
                            transform: Translate {
                                id: loaderTranslate
                                y: 0
                            }
                            
                            source: {
                                switch (root.currentIndex) {
                                    case 0: return "SettingsPageGeneral.qml";
                                    case 1: return "SettingsPageAppearance.qml";
                                    case 2: return "SettingsPageFonts.qml";
                                    case 4: return "SettingsPageDock.qml";
                                    case 5: return "SettingsPageWallpaper.qml";
                                    case 6: return "SettingsPageBar.qml";
                                    case 7: return "SettingsPageSound.qml";
                                    case 10: return "SettingsPageSystem.qml";
                                    case 11: return "SettingsPageUpdates.qml";

                                    case 13: return "SettingsPagePower.qml";
                                    case 17: return "SettingsPageNetwork.qml";
                                    case 18: return "SettingsPageDisplay.qml";
                                    case 20: return "SettingsPageUser.qml";
                                    case 21: return "SettingsPageSystem.qml";
                                    case 22: return "SettingsPageBluetooth.qml";
                                    case 23: return "SettingsPageHotspot.qml";
                                    case 24: return "SettingsPageLockscreen.qml";
                                    default: return "";
                                }
                            }
                            
                            onLoaded: {
                                if (contentLoader.item) {
                                    contentLoader.item.opacity = 0
                                    contentLoader.scale = 0.97
                                    loaderTranslate.y = 15
                                    enterAnim.restart()
                                }
                            }
                            
                            ParallelAnimation {
                                id: enterAnim
                                NumberAnimation { target: contentLoader.item; property: "opacity"; to: 1; duration: 250; easing.type: Easing.OutCubic }
                                NumberAnimation { target: contentLoader; property: "scale"; to: 1; duration: 350; easing.type: Easing.OutQuart }
                                NumberAnimation { target: loaderTranslate; property: "y"; to: 0; duration: 350; easing.type: Easing.OutQuart }
                            }

                            onStatusChanged: {
                                if (status === Loader.Error) {
                                    console.log("LOADER ERROR:", source, sourceComponent ? sourceComponent.errorString() : "unknown error");
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
