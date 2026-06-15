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
    flags: Qt.Window | Qt.FramelessWindowHint
    minimumWidth: 750
    minimumHeight: 500
    width: 1100
    height: 750
    color: root.globalTransparency ? Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.globalOpacity) : Theme.colSurface
    font.family: "JetBrainsMono Nerd Font Propo"

    property int currentIndex: 0
    property bool globalTransparency: true

    property real globalOpacity: 0.90
    property int globalBlurSize: 6
    property int globalBlurPasses: 3

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
            width: (customSwitch.pressed || customSwitch.down) ? (28 * customSwitch.scale) : customSwitch.checked ? (24 * customSwitch.scale) : (16 * customSwitch.scale)
            height: (customSwitch.pressed || customSwitch.down) ? (28 * customSwitch.scale) : customSwitch.checked ? (24 * customSwitch.scale) : (16 * customSwitch.scale)
            radius: 9999
            color: customSwitch.checked ? Theme.colOnPrimary : Theme.colOutline
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: customSwitch.checked ? ((customSwitch.pressed || customSwitch.down) ? (22 * customSwitch.scale) : 24 * customSwitch.scale) : ((customSwitch.pressed || customSwitch.down) ? (2 * customSwitch.scale) : 8 * customSwitch.scale)

            Behavior on anchors.leftMargin {
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




    Item {
        anchors.fill: parent
        focus: true

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
                        onClicked: root.close()
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
                        NavButton { iconText: ""; labelText: "Appearance"; pageIndex: 0 }
                        NavButton { iconText: ""; labelText: "Wallpapers"; pageIndex: 1 }
                        NavButton { iconText: ""; labelText: "Top Bar"; pageIndex: 2 }
                        NavButton { iconText: ""; labelText: "System"; pageIndex: 3 }
                        NavButton { iconText: ""; labelText: "Network"; pageIndex: 4 }
                        
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
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

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

                        RowLayout {
                            id: contentCol
                            width: Math.min(appearancePage.width - 48, 1000)
                            anchors.horizontalCenter: parent.horizontalCenter
                            Layout.alignment: Qt.AlignTop
                            spacing: 36
                            
                            ColumnLayout {
                                Layout.preferredWidth: 1
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignTop
                                spacing: 36
                                
SettingsCard {
                                    surfaceColor: Theme.colSurfaceContainer
                                    outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.2)
                                    primaryColor: Theme.colPrimary
                                    onSurfaceColor: Theme.colOnSurface
                                    title: "Theme & Palette"
                                    icon: ""
                                    // === Wallpaper & Colors Section ===
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 16

                                

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 20

                                    // Wallpaper Preview
                                    Rectangle {
                                        id: previewRect
                                        Layout.preferredWidth: 340
                                        Layout.preferredHeight: 200
                                        radius: 16
                                        color: Theme.colSurfaceContainerHigh
                                        clip: true
                                        
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
                                                    radius: 16
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
                                    }

                                    // Right column (Choose file + Light/Dark)
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        spacing: 16



                                        // Light/Dark toggles
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            spacing: 0
                                            
                                            // Light Mode
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 16
                                                color: !appearancePage.darkTheme ? Theme.colPrimary : Theme.colSurfaceContainer
                                                ColumnLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 8
                                                    Text { text: "☀"; Layout.alignment: Qt.AlignHCenter; color: !appearancePage.darkTheme ? Theme.colOnPrimary : Theme.colOnSurface; font.pixelSize: 28 }
                                                    Text { text: "Light"; Layout.alignment: Qt.AlignHCenter; color: !appearancePage.darkTheme ? Theme.colOnPrimary : Theme.colOnSurface; font.family: root.font.family; font.pixelSize: 14 }
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
                                                radius: 16
                                                color: appearancePage.darkTheme ? Theme.colPrimary : Theme.colSurfaceContainer
                                                ColumnLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 8
                                                    Text { text: "☾"; Layout.alignment: Qt.AlignHCenter; color: appearancePage.darkTheme ? Theme.colOnPrimary : Theme.colOnSurface; font.pixelSize: 28 }
                                                    Text { text: "Dark"; Layout.alignment: Qt.AlignHCenter; color: appearancePage.darkTheme ? Theme.colOnPrimary : Theme.colOnSurface; font.family: root.font.family; font.pixelSize: 14 }
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

                                // Chips (Color Schemes)
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
SettingsCard {
                                    surfaceColor: Theme.colSurfaceContainer
                                    outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.2)
                                    primaryColor: Theme.colPrimary
                                    onSurfaceColor: Theme.colOnSurface
                                    title: "Window Layout"
                                    icon: ""
                                    // Window Gaps Adjustments
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 8
                                    spacing: 12
                                    Text { text: ""; color: Theme.colOnSurfaceVariant; font.pixelSize: 20; font.family: "JetBrainsMono Nerd Font Propo" }
                                    Text { text: "Window Gaps"; color: Theme.colOnSurface; font.family: root.font.family; font.pixelSize: 16; Layout.fillWidth: true }
                                }
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 32
                                    spacing: 12

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
                            
                            ColumnLayout {
                                Layout.preferredWidth: 1
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignTop
                                spacing: 36
                                
SettingsCard {
                                    surfaceColor: Theme.colSurfaceContainer
                                    outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.2)
                                    primaryColor: Theme.colPrimary
                                    onSurfaceColor: Theme.colOnSurface
                                    title: "Window Effects"
                                    icon: "󰽉"
                                    // Transparency Switch
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 8
                                    spacing: 12
                                    Text { text: "⚆"; color: Theme.colOnSurfaceVariant; font.pixelSize: 20 }
                                    Text { text: "Transparency"; color: Theme.colOnSurface; font.family: root.font.family; font.pixelSize: 16; Layout.fillWidth: true }
                                    
                                    StyledSwitch {
                                        checked: root.globalTransparency
                                        onClicked: {
                                            root.globalTransparency = !root.globalTransparency;
                                            root.applyGlobalSettings();
                                        }
                                    }
                                }

                                
                                    // Advanced Transparency Controls (Visible when transparency is on)
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 32
                                    Layout.topMargin: 8
                                    visible: root.globalTransparency
                                    spacing: 12
                                    
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

                            // === Bar & screen Section ===
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 16

                                RowLayout {
                                    spacing: 12
                                    Text { text: "💻"; color: Theme.colOnSurface; font.pixelSize: 22 }
                                    Text { text: "Bar & screen"; color: Theme.colOnSurface; font.family: root.font.family; font.pixelSize: 20; font.bold: true }
                                }

                                
                                    // Window Borders Switch
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 8
                                    spacing: 12
                                    Text { text: ""; color: Theme.colOnSurfaceVariant; font.pixelSize: 20; font.family: "JetBrainsMono Nerd Font Propo" }
                                    Text { text: "Window Borders"; color: Theme.colOnSurface; font.family: root.font.family; font.pixelSize: 16; Layout.fillWidth: true }
                                    
                                    StyledSwitch {
                                        checked: root.windowBorders
                                        onClicked: {
                                            root.windowBorders = !root.windowBorders;
                                            let isBorders = root.windowBorders ? "true" : "false";
                                            Quickshell.execDetached(["bash", "-c", "echo " + isBorders + " > ~/.config/cupcake/.borders && ~/.local/bin/apply-borders"]);
                                        }
                                    }
                                }

                                
                                    // Advanced Border Controls (Visible when borders are on)
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 32
                                    Layout.topMargin: 8
                                    visible: root.windowBorders
                                    spacing: 12
                                    
                                    RowLayout {
                                        Layout.fillWidth: true
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
                                }

                                
                                    // Window Shadows Switch
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 8
                                    spacing: 12
                                    Text { text: "󰽉"; color: Theme.colOnSurfaceVariant; font.pixelSize: 20; font.family: "JetBrainsMono Nerd Font Propo" }
                                    Text { text: "Window Shadows"; color: Theme.colOnSurface; font.family: root.font.family; font.pixelSize: 16; Layout.fillWidth: true }
                                    
                                    StyledSwitch {
                                        checked: root.windowShadows
                                        onClicked: {
                                            root.windowShadows = !root.windowShadows;
                                            let isShadows = root.windowShadows ? "true" : "false";
                                            Quickshell.execDetached(["bash", "-c", "echo " + isShadows + " > ~/.config/cupcake/.shadows && ~/.local/bin/apply-shadows"]);
                                        }
                                    }
                                }

                                
                                }

                                SettingsCard {
                                    surfaceColor: Theme.colSurfaceContainer
                                    outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.2)
                                    primaryColor: Theme.colPrimary
                                    onSurfaceColor: Theme.colOnSurface
                                    title: "Quickshell Panels"
                                    icon: ""
                                    // Row 1: Bar position and Bar style
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 24

                                    // Bar position
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Text { text: "Bar position"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14 }
                                        RowLayout {
                                            spacing: 4
                                            Repeater {
                                                model: [ {t: "↑ Top", v: 0}, {t: "← Left", v: 1}, {t: "↓ Bottom", v: 2}, {t: "→ Right", v: 3} ]
                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 40
                                                    radius: 20
                                                    color: appearancePage.barPosition === modelData.v ? Theme.colPrimary : Theme.colSurfaceContainerHigh
                                                    Text { anchors.centerIn: parent; text: modelData.t; color: appearancePage.barPosition === modelData.v ? Theme.colOnPrimary : Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14 }
                                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: appearancePage.barPosition = modelData.v }
                                                }
                                            }
                                        }
                                    }

                                    // Bar style
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Text { text: "Bar style"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14 }
                                        RowLayout {
                                            spacing: 4
                                            Repeater {
                                                model: [ {t: "◝ Hug", v: 0}, {t: "□ Float", v: 1}, {t: "▤ Rect", v: 2} ]
                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 40
                                                    radius: 20
                                                    color: appearancePage.barStyle === modelData.v ? Theme.colPrimary : Theme.colSurfaceContainerHigh
                                                    Text { anchors.centerIn: parent; text: modelData.t; color: appearancePage.barStyle === modelData.v ? Theme.colOnPrimary : Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14 }
                                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: appearancePage.barStyle = modelData.v }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Row 2: Screen round corner
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Text { text: "Screen round corner"; color: Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14 }
                                    RowLayout {
                                        spacing: 4
                                        Repeater {
                                            model: [ {t: "× No", v: 0}, {t: "✓ Yes", v: 1}, {t: "⛶ When not fullscreen", v: 2} ]
                                            Rectangle {
                                                width: labelText3.implicitWidth + 32
                                                height: 40
                                                radius: 20
                                                color: appearancePage.screenCorner === modelData.v ? Theme.colPrimary : Theme.colSurfaceContainerHigh
                                                Text { id: labelText3; anchors.centerIn: parent; text: modelData.t; color: appearancePage.screenCorner === modelData.v ? Theme.colOnPrimary : Theme.colOnSurfaceVariant; font.family: root.font.family; font.pixelSize: 14 }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: appearancePage.screenCorner = modelData.v }
                                            }
                                        }
                                        Item { Layout.fillWidth: true } // spacer
                                    }
                                }
                            }

                            
                                                                // Notice Box
                                Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 100
                                Layout.topMargin: 16
                                radius: 16
                                color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.2)
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 16
                                    Text { Layout.alignment: Qt.AlignTop; text: "ⓘ"; color: Theme.colPrimary; font.pixelSize: 20 }
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
                                
                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 16
                                    width: copyText.implicitWidth + 32
                                    height: 32
                                    radius: 16
                                    color: "transparent"
                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 8
                                        Text { text: "📄"; color: Theme.colOnSurface; font.pixelSize: 16 }
                                        Text { id: copyText; text: "Copy path"; color: Theme.colOnSurface; font.family: root.font.family; font.pixelSize: 14 }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
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

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
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
                        Process {
                            id: settingsCheckKey
                            command: ["bash", "-c", "cat ~/.config/quickshell/gemini_key.txt 2>/dev/null"]
                            running: true
                            stdout: SplitParser {
                                onRead: data => {
                                    if (data.length > 10) {
                                        aiSettingsPage.keyExists = true;
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 120
                            radius: 12
                            color: Theme.colSurfaceContainer
                            
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 8
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Google Gemini API Key"
                                        color: Theme.colOnSurfaceVariant
                                        font.family: root.font.family
                                        font.pixelSize: 14
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: aiSettingsPage.keyExists ? "✅ Key is Set" : "❌ No Key Found"
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
                                        id: apiKeyInput
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 40
                                        placeholderText: aiSettingsPage.keyExists ? "Paste a new key to overwrite..." : "Paste your API key here..."
                                        color: Theme.colOnSurface
                                        background: Rectangle {
                                            color: Theme.colSurfaceContainerHigh
                                            radius: 6
                                        }
                                        leftPadding: 10
                                        
                                        onAccepted: {
                                            saveKeyProcess.command = ["bash", "-c", "echo '" + text + "' > ~/.config/quickshell/gemini_key.txt"];
                                            saveKeyProcess.running = true;
                                            aiSettingsPage.keyExists = true;
                                            placeholderText = "Key saved successfully!";
                                            text = "";
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

                        // Model Selection
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 100
                            radius: 12
                            color: Theme.colSurfaceContainer
                            
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 8
                                
                                Text {
                                    text: "Default Model"
                                    color: Theme.colOnSurfaceVariant
                                    font.family: root.font.family
                                    font.pixelSize: 14
                                }
                                
                                ComboBox {
                                    id: modelCombo
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    model: [
                                        "gemini-3.5-flash",
                                        "gemini-flash-latest",
                                        "gemini-2.5-pro",
                                        "gemini-2.5-flash",
                                        "gemini-2.0-flash",
                                        "gemini-pro-latest"
                                    ]
                                    
                                    background: Rectangle {
                                        color: Theme.colSurfaceContainerHigh
                                        radius: 6
                                    }
                                    
                                    Process {
                                        command: ["bash", "-c", "cat ~/.config/quickshell/gemini_model.txt 2>/dev/null"]
                                        running: true
                                        stdout: SplitParser {
                                            onRead: data => {
                                                if (data.trim() !== "") {
                                                    for (var i = 0; i < modelCombo.model.length; i++) {
                                                        if (modelCombo.model[i] === data.trim()) {
                                                            modelCombo.currentIndex = i;
                                                            break;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                    Process {
                                        id: saveModelProcess
                                        running: false
                                    }
                                    
                                    onActivated: {
                                        saveModelProcess.command = ["bash", "-c", "echo '" + currentText + "' > ~/.config/quickshell/gemini_model.txt"];
                                        saveModelProcess.running = true;
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
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
                }
            }
        }
    }
}
}
