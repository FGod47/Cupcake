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

PanelWindow {
    id: root
    visible: true
    color: "transparent"
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    margins {
        top: 0
    }
    
    property var font: {"family": "JetBrainsMono Nerd Font Propo"}
    property int currentIndex: 0
    property var barMonitors: ["all"]
    property var dockMonitors: ["all"]
    
    Process {
        id: markOpenProc
        command: ["bash", "-c", "echo 1 > /tmp/cupcake_settings"]
        running: true
    }

    Process {
        id: markCloseProc
        command: ["bash", "-c", "echo 0 > /tmp/cupcake_settings"]
        running: false
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
    property bool barTransparency: true

    function applyGlobalSettings() {
        let isTrans = root.globalTransparency ? "true" : "false";
        Quickshell.execDetached(["bash", "-c", "echo " + isTrans + " > /home/zero/.config/cupcake/.transparency && echo -e 'OPACITY=" + root.globalOpacity.toFixed(2) + "\\nBLUR_SIZE=" + root.globalBlurSize + "\\nBLUR_PASSES=" + root.globalBlurPasses + "' > /home/zero/.config/cupcake/.transparency_values && ~/.local/bin/apply-transparency"]);
    }
    
    property bool windowBorders: true

    Process {
        id: initBorders
        command: ["cat", "/home/zero/.config/cupcake/.borders"]
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
        command: ["cat", "/home/zero/.config/cupcake/.shadows"]
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
        command: ["cat", "/home/zero/.config/cupcake/.border_size"]
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
        command: ["cat", "/home/zero/.config/cupcake/.gaps_in"]
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
        command: ["cat", "/home/zero/.config/cupcake/.gaps_out"]
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
        command: ["cat", "/home/zero/.config/cupcake/.bar_transparency"]
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
        command: ["cat", "/home/zero/.config/cupcake/.bar_opacity"]
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
        command: ["cat", "/home/zero/.config/cupcake/.transparency"]
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
        command: ["cat", "/home/zero/.config/cupcake/.transparency_values"]
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
        command: ["cat", "/home/zero/.config/cupcake/.color_mode"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "light") {
                    if (appearancePage) appearancePage.darkTheme = false;
                }
            }
        }
    }


    property bool navExpanded: root.width > 900

    component StyledSwitch: Switch {
        id: customSwitch
        property real scale: 0.8
        implicitHeight: 32 * scale
        implicitWidth: 52 * scale
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

        // Custom track styling
        background: Rectangle {
            width: parent.width
            height: parent.height
            radius: 9999
            color: customSwitch.checked ? Theme.colPrimary : Theme.colSurfaceContainerHigh
            border.width: 2 * customSwitch.scale
            border.color: customSwitch.checked ? Theme.colPrimary : Theme.colOutline

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
        }

        // Custom thumb styling
        indicator: Rectangle {
            width: (customSwitch.pressed || customSwitch.down) ? (28 * customSwitch.scale) : (24 * customSwitch.scale)
            height: (customSwitch.pressed || customSwitch.down) ? (28 * customSwitch.scale) : (24 * customSwitch.scale)
            radius: 9999
            color: customSwitch.checked ? Theme.colOnPrimary : Theme.colOutline
            
            // Vertically center it
            y: (customSwitch.implicitHeight - height) / 2
            
            // Calculate X based on state
            // Gap of 4 * scale from the edge
            x: customSwitch.checked 
                ? (customSwitch.implicitWidth - width - (4 * customSwitch.scale))
                : (4 * customSwitch.scale)

            Behavior on x {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
            Behavior on width {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
            Behavior on height {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    component StyledSlider: Slider {
        id: control
        background: Item {
            x: control.leftPadding
            y: control.topPadding + control.availableHeight / 2 - height / 2
            implicitWidth: 200
            implicitHeight: 16
            width: control.availableWidth
            height: implicitHeight
            
            // Full Inactive Track (Continuous Pill)
            Rectangle {
                anchors.fill: parent
                color: Theme.colOnSurface
                opacity: 0.15
                radius: height / 2
            }
            
            // Active Track (clipped straight at the thumb boundary)
            Item {
                width: control.visualPosition * parent.width
                height: parent.height
                clip: true
                
                Rectangle {
                    width: control.availableWidth
                    height: parent.height
                    color: Theme.colPrimary
                    radius: parent.height / 2
                }
            }
        }
        handle: Item {
            // Perfectly center the thumb on the boundary
            x: control.leftPadding + control.visualPosition * control.availableWidth - width / 2
            y: control.topPadding + control.availableHeight / 2 - height / 2
            implicitWidth: 16
            implicitHeight: 16



            // Solid Blue Circle (creates the rounded edge around the thumb)
            Rectangle {
                anchors.centerIn: parent
                width: 16
                height: 16
                radius: 8
                color: Theme.colPrimary
            }

            // Inner Thumb Dot
            Rectangle {
                anchors.centerIn: parent
                width: (control.pressed || control.hovered) ? 10 : 6
                height: (control.pressed || control.hovered) ? 10 : 6
                radius: width / 2
                color: "#ffffff"
                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            }
        }
    }




    MouseArea {
        anchors.fill: parent
        onClicked: {
            markCloseProc.running = true;
            closeAnim.start();
        }
        z: -1
    }

    Item {
        id: mainWrapper
        width: fakeArchText.implicitWidth + 32
        height: 34
        x: (parent.width - width) / 2
        y: 6
        focus: true

        Timer {
            id: startupDelay
            interval: 120
            running: true
            onTriggered: morphAnim.start()
        }

        ParallelAnimation {
            id: morphAnim
            NumberAnimation { target: mainWrapper; property: "width"; to: 1100; duration: 500; easing.type: Easing.OutCubic }
            NumberAnimation { target: mainWrapper; property: "height"; to: 750; duration: 500; easing.type: Easing.OutCubic }
            NumberAnimation { target: mainWrapper; property: "y"; to: 46; duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
            NumberAnimation { target: contentOpacity; property: "opacity"; from: 0.0; to: 1.0; duration: 500; easing.type: Easing.OutCubic }
            NumberAnimation { target: fakeArchPill; property: "opacity"; from: 1.0; to: 0.0; duration: 250; easing.type: Easing.OutCubic }
        }

        ParallelAnimation {
            id: closeAnim
            NumberAnimation { target: mainWrapper; property: "width"; to: fakeArchText.implicitWidth + 32; duration: 400; easing.type: Easing.InCubic }
            NumberAnimation { target: mainWrapper; property: "height"; to: 34; duration: 400; easing.type: Easing.InCubic }
            NumberAnimation { target: mainWrapper; property: "y"; to: 6; duration: 400; easing.type: Easing.InBack; easing.overshoot: 1.0 }
            NumberAnimation { target: contentOpacity; property: "opacity"; to: 0.0; duration: 200; easing.type: Easing.InCubic }
            NumberAnimation { target: fakeArchPill; property: "opacity"; to: 1.0; duration: 400; easing.type: Easing.InCubic }
            onFinished: Qt.quit()
        }

        // Settings Background
        Rectangle {
            anchors.fill: parent
            radius: 18
            color: root.globalTransparency ? Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.globalOpacity) : Theme.colSurface
            border.width: 1
            border.color: Theme.colSurfaceContainerHigh
            opacity: contentOpacity.opacity
        }

        // Fake Arch Pill (Matches Bar.qml exactly)
        Rectangle {
            id: fakeArchPill
            anchors.fill: parent
            radius: 18
            
            property color c1: Theme.colPrimary
            property color c2: Theme.colSecondary
            
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: fakeArchPill.c1 }
                GradientStop { position: 1.0; color: fakeArchPill.c2 }
            }

            SequentialAnimation on c1 {
                loops: Animation.Infinite
                ColorAnimation { to: Theme.colSecondary; duration: 2000 }
                ColorAnimation { to: Theme.colPrimary; duration: 2000 }
            }

            SequentialAnimation on c2 {
                loops: Animation.Infinite
                ColorAnimation { to: Theme.colPrimary; duration: 2000 }
                ColorAnimation { to: Theme.colSecondary; duration: 2000 }
            }
            
            Text {
                id: fakeArchText
                anchors.centerIn: parent
                text: " Arch"
                color: Theme.colSurfaceContainerHigh
                font.family: root.font.family
                font.pixelSize: 14
                font.weight: 500
            }
        }

        Item {
            id: contentOpacity
            anchors.fill: parent
            clip: true
            opacity: 0

            Item {
                width: 1100
                height: 750
                anchors.centerIn: parent

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

            // Custom Titlebar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.topMargin: 12
                color: root.globalTransparency ? Qt.rgba(Theme.colSurfaceContainer.r, Theme.colSurfaceContainer.g, Theme.colSurfaceContainer.b, 0.5) : Theme.colSurfaceContainer
                radius: 10
                
                Text {
                    anchors.centerIn: parent
                    text: "Settings"
                    color: Theme.colOnSurface
                    font.family: root.font.family
                    font.pixelSize: 16
                    font.bold: true
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32; height: 32
                    radius: 16
                    color: closeMouseArea.containsMouse ? Theme.colSurfaceContainerHigh : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text {
                        anchors.centerIn: parent
                        text: "✖"
                        color: Theme.colOnSurfaceVariant
                        font.family: root.font.family
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: closeMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
            markCloseProc.running = true;
            closeAnim.start();
        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.topMargin: 8
                Layout.bottomMargin: 12
                spacing: 16

                // Navigation Rail
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: navExpanded ? 180 : 56
                    
                    color: root.globalTransparency ? Qt.rgba(Theme.colSurfaceContainer.r, Theme.colSurfaceContainer.g, Theme.colSurfaceContainer.b, 0.5) : Theme.colSurfaceContainer
                    radius: 10
                    Behavior on Layout.preferredWidth { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 5

                        Item { Layout.preferredHeight: 8 } // Spacer

                        // Nav Buttons
                        component NavHeader: Text {
                            visible: navExpanded
                            Layout.fillWidth: true
                            Layout.leftMargin: 20
                            Layout.topMargin: 12
                            Layout.bottomMargin: 4
                            color: Theme.colOnSurfaceVariant
                            font.family: "Inter"
                            font.pixelSize: 11
                            font.bold: true
                            opacity: 0.7
                        }





                        component NavButton: Item {
                            property string iconText
                            property string labelText
                            property int pageIndex

                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            
                            // Background Pill
                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                radius: 8
                                color: root.currentIndex === pageIndex 
                                    ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.15) 
                                    : (navMouseArea.containsMouse ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05) : "transparent")
                                
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: navExpanded ? 26 : 20
                                spacing: 14
                                
                                Text {
                                    text: iconText
                                    color: root.currentIndex === pageIndex ? Theme.colPrimary : Theme.colOnSurfaceVariant
                                    font.family: root.font.family
                                    font.pixelSize: 18
                                    opacity: root.currentIndex === pageIndex ? 1.0 : 0.6
                                    Layout.preferredWidth: 20
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                
                                Text {
                                    visible: navExpanded
                                    text: labelText
                                    color: root.currentIndex === pageIndex ? Theme.colPrimary : Theme.colOnSurfaceVariant
                                    font.family: "Inter"
                                    font.pixelSize: 14
                                    font.bold: root.currentIndex === pageIndex
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

                        NavHeader { text: "MENU" }
                        NavButton { iconText: "󰏘"; labelText: "Appearance"; pageIndex: 0 }
                        NavButton { iconText: ""; labelText: "Wallpapers"; pageIndex: 1 }
                        NavButton { iconText: ""; labelText: "Top Bar"; pageIndex: 2 }
                        NavButton { iconText: ""; labelText: "System"; pageIndex: 3 }
                        NavButton { iconText: ""; labelText: "Network"; pageIndex: 4 }
                        NavButton { iconText: "󰍹"; labelText: "Display"; pageIndex: 8 }
                        
                        NavHeader { text: "GENERAL" }
                        NavButton { iconText: "✨"; labelText: "AI"; pageIndex: 5 }
                        NavButton { iconText: ""; labelText: "User"; pageIndex: 6 }
                        NavButton { iconText: ""; labelText: "About"; pageIndex: 7 }

                        Item { Layout.fillHeight: true } // Spacer
                    }
                }

                // Content Area (uses a rounded rectangle container for the active page)
                Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: root.globalTransparency ? Qt.rgba(Theme.colSurfaceContainer.r, Theme.colSurfaceContainer.g, Theme.colSurfaceContainer.b, 0.5) : Theme.colSurfaceContainer
            radius: 10 // Appearance.rounding.windowRounding (18) - contentPadding (8)
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

                    property string selectedScheme: "Content"

                    Process {
                        id: initSchemeProcess
                        command: ["cat", "/home/zero/.config/cupcake/.color_scheme"]
                        running: true
                        stdout: StdioCollector {
                            onStreamFinished: {
                                if (text.trim() !== "") {
                                    appearancePage.selectedScheme = text.trim();
                                } else {
                                    appearancePage.selectedScheme = "Auto";
                                }
                            }
                        }
                    }

                    Process {
                        id: applySchemeProcess
                    }
                    property int barPosition: 0 // 0=Top, 1=Left, 2=Bottom, 3=Right
                    property int barStyle: 0 // 0=Hug, 1=Float, 2=Rect
                    property int screenCorner: 2 // 0=No, 1=Yes, 2=When not fullscreen
                    property bool darkTheme: true
                    property bool transparency: true

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 24
                        contentHeight: contentCol.implicitHeight + 40
                        clip: true
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; active: true }

                        ColumnLayout {
                            id: contentCol
                            width: Math.min(appearancePage.width - 48, 1000)
                            anchors.horizontalCenter: parent.horizontalCenter
                            Layout.alignment: Qt.AlignTop
                            spacing: 36
                            
                            // ==========================================
                            // LEFT COLUMN
                            // ==========================================
                            ColumnLayout {
                                
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignTop
                                spacing: 24
                                
                                SettingsCard {
                                    surfaceColor: Theme.colSurfaceContainer
                                    outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                                    primaryColor: Theme.colPrimary
                                    onSurfaceColor: Theme.colOnSurface
                                    title: "Theme & Palette"
                                    icon: ""
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 24

                                        // Hero Wallpaper Banner
                                        Rectangle {
                                            id: previewRect
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 220
                                            radius: 16
                                            color: Theme.colSurfaceContainerHigh
                                            border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.3)
                                            border.width: 1
                                            
                                            property string currentWpPath: ""
                                            
                                            Image {
                                                id: wpPreviewImg
                                                anchors.fill: parent
                                                source: previewRect.currentWpPath !== "" ? "file://" + previewRect.currentWpPath : ""
                                                fillMode: Image.PreserveAspectCrop
                                                asynchronous: true
                                                visible: source.toString() !== "" && status === Image.Ready
                                                layer.enabled: true
                                                layer.effect: OpacityMask {
                                                    maskSource: Rectangle {
                                                        width: wpPreviewImg.width
                                                        height: wpPreviewImg.height
                                                        radius: 15
                                                    }
                                                }
                                            }
                                            
                                            Text {
                                                anchors.centerIn: parent
                                                text: ""
                                                color: Theme.colPrimary
                                                font.pixelSize: 80
                                                visible: !wpPreviewImg.visible
                                            }
                                            
                                            Process {
                                                id: wpPollProcess
                                                command: ["cat", "/home/zero/.cache/current_wallpaper"]
                                                running: true
                                                stdout: StdioCollector {
                                                    onStreamFinished: {
                                                        let p = text.trim();
                                                        if (p !== "" && p !== previewRect.currentWpPath) {
                                                            previewRect.currentWpPath = p;
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            Timer {
                                                interval: 2000
                                                running: appearancePage.visible
                                                repeat: true
                                                onTriggered: wpPollProcess.running = true
                                            }

                                            // Glassmorphic Light/Dark Switch Floating inside banner
                                            Rectangle {
                                                anchors.bottom: parent.bottom
                                                anchors.right: parent.right
                                                anchors.margins: 16
                                                width: 240
                                                height: 48
                                                radius: 24
                                                color: Qt.rgba(Theme.colSurfaceContainer.r, Theme.colSurfaceContainer.g, Theme.colSurfaceContainer.b, 0.75)
                                                border.color: Qt.rgba(1, 1, 1, 0.1)
                                                
                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.margins: 4
                                                    spacing: 4
                                                    
                                                    // Light Mode
                                                    Rectangle {
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        radius: 20
                                                        color: !appearancePage.darkTheme ? Theme.colPrimary : "transparent"
                                                        Behavior on color { ColorAnimation { duration: 200 } }
                                                        RowLayout {
                                                            anchors.centerIn: parent
                                                            spacing: 6
                                                            Text { text: "☀"; color: !appearancePage.darkTheme ? Theme.colOnPrimary : Theme.colOnSurface; font.pixelSize: 16 }
                                                            Text { text: "Light"; color: !appearancePage.darkTheme ? Theme.colOnPrimary : Theme.colOnSurface; font.family: root.font.family; font.pixelSize: 14; font.bold: !appearancePage.darkTheme }
                                                        }
                                                        MouseArea {
                                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor;
                                                            onClicked: {
                                                                appearancePage.darkTheme = false;
                                                                Quickshell.execDetached(["bash", "-c", "echo 'light' > ~/.config/cupcake/.color_mode && ~/.local/bin/set-theme"]);
                                                            }
                                                        }
                                                    }
                                                    // Dark Mode
                                                    Rectangle {
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        radius: 20
                                                        color: appearancePage.darkTheme ? Theme.colPrimary : "transparent"
                                                        Behavior on color { ColorAnimation { duration: 200 } }
                                                        RowLayout {
                                                            anchors.centerIn: parent
                                                            spacing: 6
                                                            Text { text: "☾"; color: appearancePage.darkTheme ? Theme.colOnPrimary : Theme.colOnSurface; font.pixelSize: 16 }
                                                            Text { text: "Dark"; color: appearancePage.darkTheme ? Theme.colOnPrimary : Theme.colOnSurface; font.family: root.font.family; font.pixelSize: 14; font.bold: appearancePage.darkTheme }
                                                        }
                                                        MouseArea {
                                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor;
                                                            onClicked: {
                                                                appearancePage.darkTheme = true;
                                                                Quickshell.execDetached(["bash", "-c", "echo 'dark' > ~/.config/cupcake/.color_mode && ~/.local/bin/set-theme"]);
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        // Color Scheme Chips
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 12
                                            Text { text: "Color Extraction Scheme"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14; font.bold: true }
                                            
                                            Flow {
                                                Layout.fillWidth: true
                                                spacing: 8
                                                
                                                Repeater {
                                                    model: ["Auto", "Content", "Expressive", "Fidelity", "Fruit Salad", "Monochrome", "Neutral", "Rainbow", "Tonal Spot"]
                                                    Rectangle {
                                                        width: labelText.implicitWidth + 32
                                                        height: 36
                                                        radius: 18
                                                        color: appearancePage.selectedScheme === modelData ? Theme.colPrimary : Theme.colSurfaceContainerHigh
                                                        Behavior on color { ColorAnimation { duration: 150 } }
                                                        Text {
                                                            id: labelText
                                                            anchors.centerIn: parent
                                                            text: modelData
                                                            color: appearancePage.selectedScheme === modelData ? Theme.colOnPrimary : Theme.colOnSurfaceVariant
                                                            font.family: root.font.family
                                                            font.pixelSize: 14
                                                        }
                                                        MouseArea { 
                                                            anchors.fill: parent; 
                                                            cursorShape: Qt.PointingHandCursor; 
                                                            onClicked: {
                                                                appearancePage.selectedScheme = modelData
                                                                applySchemeProcess.command = ["bash", "-c", "echo '" + modelData + "' > ~/.config/cupcake/.color_scheme && ~/.local/bin/set-theme"]
                                                                applySchemeProcess.running = true
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                SettingsCard {
                                    surfaceColor: Theme.colSurfaceContainer
                                    outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                                    primaryColor: Theme.colPrimary
                                    onSurfaceColor: Theme.colOnSurface
                                    title: "Window Effects"
                                    icon: "󰽉"
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 24

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 12
                                            Text { text: "⚆"; color: Theme.colOnSurfaceVariant; font.pixelSize: 22 }
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Text { text: "Glassmorphism"; color: Theme.colOnSurface; font.family: root.font.family; font.pixelSize: 16; font.bold: true }
                                                Text { text: "Enable transparency and blur for windows"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 13 }
                                            }
                                            Item { Layout.fillWidth: true }
                                            StyledSwitch {
                                                checked: root.globalTransparency
                                                onClicked: {
                                                    root.globalTransparency = !root.globalTransparency;
                                                    root.applyGlobalSettings();
                                                }
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.leftMargin: 34
                                            visible: root.globalTransparency
                                            spacing: 16
                                            
                                            RowLayout {
                                                Layout.fillWidth: true
                                                Text { text: "Opacity (" + Math.round(root.globalOpacity * 100) + "%)"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14; Layout.preferredWidth: 120 }
                                                StyledSlider {
                                                    Layout.fillWidth: true
                                                    from: 0.4; to: 1.0; stepSize: 0.05
                                                    value: root.globalOpacity
                                                    onPressedChanged: {
                                                        if (!pressed) {
                                                            root.globalOpacity = value;
                                                            root.applyGlobalSettings();
                                                        }
                                                    }
                                                }
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Text { text: "Blur Size (" + root.globalBlurSize + ")"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14; Layout.preferredWidth: 120 }
                                                StyledSlider {
                                                    Layout.fillWidth: true
                                                    from: 1; to: 12; stepSize: 1
                                                    value: root.globalBlurSize
                                                    onPressedChanged: {
                                                        if (!pressed) {
                                                            root.globalBlurSize = value;
                                                            root.applyGlobalSettings();
                                                        }
                                                    }
                                                }
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Text { text: "Blur Passes (" + root.globalBlurPasses + ")"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14; Layout.preferredWidth: 120 }
                                                StyledSlider {
                                                    Layout.fillWidth: true
                                                    from: 1; to: 4; stepSize: 1
                                                    value: root.globalBlurPasses
                                                    onPressedChanged: {
                                                        if (!pressed) {
                                                            root.globalBlurPasses = value;
                                                            root.applyGlobalSettings();
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // ==========================================
                            // RIGHT COLUMN
                            // ==========================================
                            ColumnLayout {
                                
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignTop
                                spacing: 24
                                
                                SettingsCard {
                                    surfaceColor: Theme.colSurfaceContainer
                                    outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                                    primaryColor: Theme.colPrimary
                                    onSurfaceColor: Theme.colOnSurface
                                    title: "Window Layout"
                                    icon: ""

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 24

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 12
                                            Text { text: ""; color: Theme.colOnSurfaceVariant; font.pixelSize: 22; font.family: "JetBrainsMono Nerd Font Propo" }
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Text { text: "Window Borders"; color: Theme.colOnSurface; font.family: root.font.family; font.pixelSize: 16; font.bold: true }
                                                Text { text: "Draw colored borders around windows"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 13 }
                                            }
                                            Item { Layout.fillWidth: true }
                                            StyledSwitch {
                                                checked: root.windowBorders
                                                onClicked: {
                                                    root.windowBorders = !root.windowBorders;
                                                    let isBorders = root.windowBorders ? "true" : "false";
                                                    Quickshell.execDetached(["bash", "-c", "echo " + isBorders + " > ~/.config/cupcake/.borders && ~/.local/bin/apply-borders"]);
                                                }
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.leftMargin: 34
                                            visible: root.windowBorders
                                            Text { text: "Thickness (" + Math.round(root.borderSize) + "px)"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14; Layout.preferredWidth: 120 }
                                            StyledSlider {
                                                Layout.fillWidth: true
                                                from: 1; to: 10; stepSize: 1
                                                value: root.borderSize
                                                onValueChanged: {
                                                    if (root.borderSize !== value) {
                                                        root.borderSize = value;
                                                        Quickshell.execDetached(["bash", "-c", "echo " + Math.round(value) + " > ~/.config/cupcake/.border_size && ~/.local/bin/apply-borders"]);
                                                    }
                                                }
                                            }
                                        }
                                        
                                        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.1) }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 12
                                            Text { text: "󰽉"; color: Theme.colOnSurfaceVariant; font.pixelSize: 22; font.family: "JetBrainsMono Nerd Font Propo" }
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Text { text: "Drop Shadows"; color: Theme.colOnSurface; font.family: root.font.family; font.pixelSize: 16; font.bold: true }
                                                Text { text: "Draw drop shadows behind windows"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 13 }
                                            }
                                            Item { Layout.fillWidth: true }
                                            StyledSwitch {
                                                checked: root.windowShadows
                                                onClicked: {
                                                    root.windowShadows = !root.windowShadows;
                                                    let isShadows = root.windowShadows ? "true" : "false";
                                                    Quickshell.execDetached(["bash", "-c", "echo " + isShadows + " > ~/.config/cupcake/.shadows && ~/.local/bin/apply-shadows"]);
                                                }
                                            }
                                        }
                                        
                                        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.1) }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 16
                                            RowLayout {
                                                spacing: 12
                                                Text { text: "◫"; color: Theme.colOnSurfaceVariant; font.pixelSize: 22 }
                                                Text { text: "Window Gaps"; color: Theme.colOnSurface; font.family: root.font.family; font.pixelSize: 16; font.bold: true }
                                            }
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                Layout.leftMargin: 34
                                                spacing: 16
                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    Text { text: "Inner (" + Math.round(root.gapsIn) + "px)"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14; Layout.preferredWidth: 120 }
                                                    StyledSlider {
                                                        Layout.fillWidth: true
                                                        from: 0; to: 30; stepSize: 1
                                                        value: root.gapsIn
                                                        onValueChanged: {
                                                            if (root.gapsIn !== value) {
                                                                root.gapsIn = value;
                                                                Quickshell.execDetached(["bash", "-c", "echo " + Math.round(value) + " > ~/.config/cupcake/.gaps_in && ~/.local/bin/apply-gaps"]);
                                                            }
                                                        }
                                                    }
                                                }
                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    Text { text: "Outer (" + Math.round(root.gapsOut) + "px)"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14; Layout.preferredWidth: 120 }
                                                    StyledSlider {
                                                        Layout.fillWidth: true
                                                        from: 0; to: 60; stepSize: 1
                                                        value: root.gapsOut
                                                        onValueChanged: {
                                                            if (root.gapsOut !== value) {
                                                                root.gapsOut = value;
                                                                Quickshell.execDetached(["bash", "-c", "echo " + Math.round(value) + " > ~/.config/cupcake/.gaps_out && ~/.local/bin/apply-gaps"]);
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                SettingsCard {
                                    surfaceColor: Theme.colSurfaceContainer
                                    outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                                    primaryColor: Theme.colPrimary
                                    onSurfaceColor: Theme.colOnSurface
                                    title: "Bar Layout & Styling"
                                    icon: ""
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 24

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 12
                                            Text { text: "Position on screen"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14; font.bold: true }
                                            RowLayout {
                                                spacing: 4
                                                Repeater {
                                                    model: [ {t: "↑ Top", v: 0}, {t: "← Left", v: 1}, {t: "↓ Bottom", v: 2}, {t: "→ Right", v: 3} ]
                                                    Rectangle {
                                                        Layout.fillWidth: true
                                                        Layout.preferredHeight: 36
                                                        radius: 18
                                                        color: appearancePage.barPosition === modelData.v ? Theme.colPrimary : Theme.colSurfaceContainerHigh
                                                        Behavior on color { ColorAnimation { duration: 150 } }
                                                        Text { anchors.centerIn: parent; text: modelData.t; color: appearancePage.barPosition === modelData.v ? Theme.colOnPrimary : Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14 }
                                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: appearancePage.barPosition = modelData.v }
                                                    }
                                                }
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 12
                                            Text { text: "Bar geometry"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14; font.bold: true }
                                            RowLayout {
                                                spacing: 4
                                                Repeater {
                                                    model: [ {t: "◝ Hug", v: 0}, {t: "□ Float", v: 1}, {t: "▤ Rect", v: 2} ]
                                                    Rectangle {
                                                        Layout.fillWidth: true
                                                        Layout.preferredHeight: 36
                                                        radius: 18
                                                        color: appearancePage.barStyle === modelData.v ? Theme.colPrimary : Theme.colSurfaceContainerHigh
                                                        Behavior on color { ColorAnimation { duration: 150 } }
                                                        Text { anchors.centerIn: parent; text: modelData.t; color: appearancePage.barStyle === modelData.v ? Theme.colOnPrimary : Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14 }
                                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: appearancePage.barStyle = modelData.v }
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.1) }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 12
                                            Text { text: "⚆"; color: Theme.colOnSurfaceVariant; font.pixelSize: 22 }
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Text { text: "Bar Glassmorphism"; color: Theme.colOnSurface; font.family: root.font.family; font.pixelSize: 16; font.bold: true }
                                                Text { text: "Enable independent transparency for the bar"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 13 }
                                            }
                                            Item { Layout.fillWidth: true }
                                            StyledSwitch {
                                                checked: root.barTransparency
                                                onClicked: {
                                                    root.barTransparency = !root.barTransparency;
                                                    Quickshell.execDetached(["bash", "-c", "echo " + (root.barTransparency ? "true" : "false") + " > ~/.config/cupcake/.bar_transparency && ~/.local/bin/apply-transparency"]);
                                                }
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.leftMargin: 34
                                            visible: root.barTransparency
                                            Text { text: "Opacity (" + Math.round(root.barOpacity * 100) + "%)"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14; Layout.preferredWidth: 120 }
                                            StyledSlider {
                                                Layout.fillWidth: true
                                                from: 0.1; to: 1.0; stepSize: 0.05
                                                value: root.barOpacity
                                                onPressedChanged: {
                                                    if (!pressed) {
                                                        root.barOpacity = value;
                                                        Quickshell.execDetached(["bash", "-c", "echo " + value.toFixed(2) + " > ~/.config/cupcake/.bar_opacity"]);
                                                    }
                                                }
                                            }
                                        }
                                        
                                        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.1) }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 12
                                            Text { text: "Screen rounded corners"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14; font.bold: true }
                                            RowLayout {
                                                spacing: 4
                                                Repeater {
                                                    model: [ {t: "× No", v: 0}, {t: "✓ Yes", v: 1}, {t: "⛶ When not fullscreen", v: 2} ]
                                                    Rectangle {
                                                        width: labelText3.implicitWidth + 32
                                                        height: 36
                                                        radius: 18
                                                        color: appearancePage.screenCorner === modelData.v ? Theme.colPrimary : Theme.colSurfaceContainerHigh
                                                        Behavior on color { ColorAnimation { duration: 150 } }
                                                        Text { id: labelText3; anchors.centerIn: parent; text: modelData.t; color: appearancePage.screenCorner === modelData.v ? Theme.colOnPrimary : Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14 }
                                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: appearancePage.screenCorner = modelData.v }
                                                    }
                                                }
                                                Item { Layout.fillWidth: true }
                                            }
                                        }
                                    }
                                }

                                // Notice Box
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 100
                                    radius: 16
                                    color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.1)
                                    border.color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.3)
                                    border.width: 1
                                    
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 20
                                        spacing: 16
                                        Text { Layout.alignment: Qt.AlignTop; text: "ⓘ"; color: Theme.colPrimary; font.pixelSize: 24 }
                                        Text {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignTop
                                            wrapMode: Text.WordWrap
                                            text: "Not all options are available in this app. You should also check the config file by hitting the \"Open Configuration\" button in the System tab or navigating to ~/.config/cupcake manually."
                                            color: Theme.colOnSurface
                                            font.family: root.font.family
                                            font.pixelSize: 14
                                        }
                                    }
                                }
                            }
                        }
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
                                folder: "file:///home/zero/.config/cupcake/themes/cupcake-dark/walls"
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
                                            Quickshell.execDetached(["/home/zero/.local/bin/set-theme", filePath])
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // PAGE 2: TOP BAR
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 2 ? 0 : 20
                    opacity: root.currentIndex === 2 ? 1 : 0
                    visible: root.currentIndex === 2 || opacity > 0
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

                        SettingsCard {
                            surfaceColor: Theme.colSurfaceContainer
                            outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.2)
                            primaryColor: Theme.colPrimary
                            onSurfaceColor: Theme.colOnSurface
                            title: "Target Monitors"
                            icon: "󰍹"
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                Text { text: "Choose which monitors the Top Bar and Dock appear on. By default, they appear on all monitors."; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                                
                                // Top Bar Monitors
                                Text { text: "Top Bar Displays:"; color: Theme.colOnSurface; font.family: root.font.family; font.pixelSize: 14; font.bold: true; Layout.topMargin: 8 }
                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    
                                    Rectangle {
                                        width: allText.implicitWidth + 32
                                        height: 36
                                        radius: 18
                                        color: root.barMonitors.includes("all") ? Theme.colPrimary : Theme.colSurfaceContainerHigh
                                        Text { id: allText; anchors.centerIn: parent; text: "All Monitors"; color: root.barMonitors.includes("all") ? Theme.colOnPrimary : Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14 }
                                        MouseArea { 
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; 
                                            onClicked: { Quickshell.execDetached(["bash", "-c", "echo 'all' > ~/.config/cupcake/.bar_monitors"]); }
                                        }
                                    }
                                    
                                    Repeater {
                                        model: Quickshell.screens
                                        Rectangle {
                                            width: monitorText.implicitWidth + 32
                                            height: 36
                                            radius: 18
                                            color: (!root.barMonitors.includes("all") && root.barMonitors.includes(modelData.name)) ? Theme.colPrimary : Theme.colSurfaceContainerHigh
                                            Text { id: monitorText; anchors.centerIn: parent; text: modelData.name; color: (!root.barMonitors.includes("all") && root.barMonitors.includes(modelData.name)) ? Theme.colOnPrimary : Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14 }
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor;
                                                onClicked: {
                                                    let arr = root.barMonitors.slice();
                                                    if (arr.includes("all")) arr = [];
                                                    if (arr.includes(modelData.name)) { arr = arr.filter(n => n !== modelData.name); } else { arr.push(modelData.name); }
                                                    if (arr.length === 0) arr = ["all"];
                                                    Quickshell.execDetached(["bash", "-c", "echo '" + arr.join(",") + "' > ~/.config/cupcake/.bar_monitors"]);
                                                }
                                            }
                                        }
                                    }
                                }

                                // Dock Monitors
                                Text { text: "Dock Displays:"; color: Theme.colOnSurface; font.family: root.font.family; font.pixelSize: 14; font.bold: true; Layout.topMargin: 8 }
                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    
                                    Rectangle {
                                        width: allDockText.implicitWidth + 32
                                        height: 36
                                        radius: 18
                                        color: root.dockMonitors.includes("all") ? Theme.colPrimary : Theme.colSurfaceContainerHigh
                                        Text { id: allDockText; anchors.centerIn: parent; text: "All Monitors"; color: root.dockMonitors.includes("all") ? Theme.colOnPrimary : Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14 }
                                        MouseArea { 
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; 
                                            onClicked: { Quickshell.execDetached(["bash", "-c", "echo 'all' > ~/.config/cupcake/.dock_monitors"]); }
                                        }
                                    }
                                    
                                    Repeater {
                                        model: Quickshell.screens
                                        Rectangle {
                                            width: dockText.implicitWidth + 32
                                            height: 36
                                            radius: 18
                                            color: (!root.dockMonitors.includes("all") && root.dockMonitors.includes(modelData.name)) ? Theme.colPrimary : Theme.colSurfaceContainerHigh
                                            Text { id: dockText; anchors.centerIn: parent; text: modelData.name; color: (!root.dockMonitors.includes("all") && root.dockMonitors.includes(modelData.name)) ? Theme.colOnPrimary : Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14 }
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor;
                                                onClicked: {
                                                    let arr = root.dockMonitors.slice();
                                                    if (arr.includes("all")) arr = [];
                                                    if (arr.includes(modelData.name)) { arr = arr.filter(n => n !== modelData.name); } else { arr.push(modelData.name); }
                                                    if (arr.length === 0) arr = ["all"];
                                                    Quickshell.execDetached(["bash", "-c", "echo '" + arr.join(",") + "' > ~/.config/cupcake/.dock_monitors"]);
                                                }
                                            }
                                        }
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
                                        Quickshell.execDetached(["/home/zero/.config/cupcake/scripts/toggle_bar.sh"])
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // PAGE 3: SYSTEM
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 3 ? 0 : 20
                    opacity: root.currentIndex === 3 ? 1 : 0
                    visible: root.currentIndex === 3 || opacity > 0
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

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            color: Theme.colSurfaceContainer
                            radius: 12
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                Text {
                                    text: "Open Configuration Folder"
                                    color: Theme.colOnSurface
                                    font.family: root.font.family
                                    font.pixelSize: 16
                                    Layout.fillWidth: true
                                }
                                Button {
                                    text: "Open"
                                    font.family: root.font.family
                                    onClicked: Quickshell.execDetached(["xdg-open", "/home/zero/.config/cupcake"])
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // PAGE 4: NETWORK
                Item {
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 4 ? 0 : 20
                    opacity: root.currentIndex === 4 ? 1 : 0
                    visible: root.currentIndex === 4 || opacity > 0
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

                // PAGE 5: AI PANEL
                Item {
                    id: aiSettingsPage
                    property bool keyExists: false

                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 5 ? 0 : 20
                    opacity: root.currentIndex === 5 ? 1 : 0
                    visible: root.currentIndex === 5 || opacity > 0
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
                            font.bold: true
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
                            font.bold: true
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
                                            font.pixelSize: 14
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: aiSettingsPage.keyExists ? "✅ Accounts Loaded" : "❌ No Accounts"
                                            color: aiSettingsPage.keyExists ? Theme.colPrimary : Theme.colError
                                            font.family: root.font.family
                                            font.pixelSize: 14
                                            font.bold: true
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
                                                font.bold: true
                                                font.pixelSize: 14
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

                // PAGE 6: USER
                Item {
                    id: userPage
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 6 ? 0 : 20
                    opacity: root.currentIndex === 6 ? 1 : 0
                    visible: root.currentIndex === 6 || opacity > 0
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
                        running: root.currentIndex === 6
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
                                        font.pixelSize: 16
                                        font.weight: Font.Medium
                                    }
                                    Text {
                                        text: valueText
                                        color: Theme.colOnSurfaceVariant
                                        font.family: root.font.family
                                        font.pixelSize: 14
                                    }
                                    Item { Layout.fillHeight: true }
                                }
                            }

                            Text {
                                text: "User"
                                color: Theme.colOnSurface
                                font.family: root.font.family
                                font.pixelSize: 32
                                font.bold: true
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
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
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
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
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

                // PAGE 7: ABOUT
                Item {
                    id: aboutPage
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 7 ? 0 : 20
                    opacity: root.currentIndex === 7 ? 1 : 0
                    visible: root.currentIndex === 7 || opacity > 0
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
                        command: ["bash", "/home/zero/.local/bin/get-hw-info"]
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
                                    font.pixelSize: 16
                                    font.weight: Font.Medium
                                }
                                Text {
                                    text: valueText
                                    color: Theme.colOnSurfaceVariant
                                    font.family: root.font.family
                                    font.pixelSize: 14
                                }
                                Item { Layout.fillHeight: true }
                            }
                        }

                        Text {
                            text: "About"
                            color: Theme.colOnSurface
                            font.family: root.font.family
                            font.pixelSize: 32
                            font.bold: true
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
                                font.pixelSize: 14
                                font.weight: Font.Medium
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
                                font.pixelSize: 14
                                font.weight: Font.Medium
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
                                font.pixelSize: 14
                                font.weight: Font.Medium
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

                // PAGE 8: DISPLAY
                Item {
                    id: displayPage
                    anchors.fill: parent
                    anchors.topMargin: root.currentIndex === 8 ? 0 : 20
                    opacity: root.currentIndex === 8 ? 1 : 0
                    visible: root.currentIndex === 8 || opacity > 0
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
                        Quickshell.execDetached(["python3", "/home/zero/Cupcake/.local/bin/generate_monitor_lua.py"]);
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
                                font.bold: true
                            }
                            
                            Text {
                                text: "Manage your monitors, resolution, refresh rates, and scaling."
                                color: Theme.colOnSurfaceVariant
                                font.family: root.font.family
                                font.pixelSize: 14
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
                                            Text { text: "󰍹"; color: Theme.colPrimary; font.pixelSize: 32 }
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 4
                                                Text { text: modelData.name + (modelData.focused ? " (Active)" : ""); color: Theme.colOnSurface; font.family: root.font.family; font.pixelSize: 16; font.bold: true }
                                                Text { text: modelData.description; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 12 }
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
                                                Text { text: "Resolution"; color: Theme.colOnSurfaceVariant; font.pixelSize: 12; font.family: root.font.family }
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
                                                            font.pixelSize: 13
                                                            font.weight: 500
                                                            color: Theme.colOnSurface
                                                            verticalAlignment: Text.AlignVCenter
                                                            horizontalAlignment: Text.AlignHCenter
                                                        }
                                                    }
                                                }
                                            }

                                            ColumnLayout {
                                                spacing: 8
                                                Text { text: "Refresh Rate"; color: Theme.colOnSurfaceVariant; font.pixelSize: 12; font.family: root.font.family }
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
                                                            font.pixelSize: 13
                                                            font.weight: 500
                                                            color: Theme.colOnSurface
                                                            verticalAlignment: Text.AlignVCenter
                                                            horizontalAlignment: Text.AlignHCenter
                                                        }
                                                    }
                                                }
                                            }

                                            ColumnLayout {
                                                spacing: 8
                                                Text { text: "Scale"; color: Theme.colOnSurfaceVariant; font.pixelSize: 12; font.family: root.font.family }
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
                                                            font.pixelSize: 13
                                                            font.weight: 500
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
                                                Text { anchors.centerIn: parent; text: "Apply"; color: Theme.colOnPrimary; font.bold: true; font.family: root.font.family; font.pixelSize: 14 }
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
                                                Text { anchors.centerIn: parent; text: "Keep Changes (" + displayPage.countdown + "s)"; color: Theme.colOnError; font.bold: true; font.family: root.font.family; font.pixelSize: 14 }
                                                MouseArea {
                                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: displayPage.keepDisplay()
                                                }
                                            }
                                            Text {
                                                text: "Reverts automatically if not confirmed"
                                                color: Theme.colOnSurfaceVariant
                                                font.pixelSize: 12
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

