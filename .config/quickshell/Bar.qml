import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
import QtQuick.Controls

PanelWindow {
    id: bar
    anchors {
        top: true
        left: true
        right: true
    }
    WlrLayershell.namespace: "waybar"
    exclusiveZone: 46
    // Strictly fixed to 46 to prevent Hyprland layer resize jitter when the dropdown closes
    implicitHeight: 46
    color: "transparent"
    
    property var modelData
    screen: modelData
    


    SystemClock {
        id: timeClock
        precision: SystemClock.Minutes 
    }

    // Shared style definitions based on user's style.css
    readonly property color bg: "#27293F"
    readonly property color fg: "#eeffff"
    readonly property string fontName: "JetBrainsMono Nerd Font Propo"
    readonly property int fontSize: 14

    // padding 0 16px translates to implicitWidth = contentItem.width + 32
    // margin: 8px 4px 0 4px is handled by Layout properties or anchors

    Item {
        // Fixed 46px top strip — never resizes when bar grows
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        // Make this item exactly 46px tall, but account for margins inside or don't set topMargin on the item itself
        height: 46

        // Inner wrapper to keep the original padding logic identical
        Item {
            anchors.fill: parent
            anchors.topMargin: 8
            anchors.leftMargin: 8
            anchors.rightMargin: 8

        // =======================
        // LEFT MODULES
        // =======================
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Workspaces Pill (#workspaces)
            Rectangle {
                color: bg
                radius: 18
                implicitHeight: 34
                implicitWidth: 168 // 5 * 32px + 8px padding
                Layout.alignment: Qt.AlignVCenter
                
                Row {
                    id: workspaceRow
                    anchors.centerIn: parent
                    spacing: 0
                    Repeater {
                        model: 5
                        delegate: Rectangle {
                            color: "transparent"
                            width: 32
                            height: 24
                            property int wsId: index + 1
                            property bool isFocused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
                            Text {
                                anchors.centerIn: parent
                                text: isFocused ? "⬤" : "◯"
                                color: isFocused ? "#F08CAE" : fg
                                font.family: fontName
                                font.pixelSize: fontSize
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: Hyprland.dispatch("workspace " + wsId)
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                }
            }

            // Active Window Pill (#window)
            Rectangle {
                id: windowPill
                radius: 18
                implicitHeight: 34
                color: "#B1DAAA"
                implicitWidth: windowText.implicitWidth > 0 ? Math.min(windowText.implicitWidth, 400) + 32 : 0
                Layout.alignment: Qt.AlignVCenter
                visible: Hyprland.activeToplevel && Hyprland.activeToplevel.title !== ""
                clip: true
                Behavior on implicitWidth { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                
                Text {
                    id: windowText
                    anchors.centerIn: parent
                    text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
                    color: "#1a1b26"
                    font.family: fontName
                    font.pixelSize: fontSize
                    font.weight: 500
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    width: Math.min(implicitWidth, 400)
                }
            }
        }

        // =======================
        // CENTER MODULES
        // =======================
        // Arch Pill (#custom-logo)
        Rectangle {
            id: archPill
            anchors.centerIn: parent
                radius: 18
                implicitHeight: 34
                implicitWidth: archText.implicitWidth + 32
                
                property color c1: "#f5e0dc"
                property color c2: "#f2cdcd"
                
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: archPill.c1 }
                    GradientStop { position: 1.0; color: archPill.c2 }
                }

                SequentialAnimation on c1 {
                    loops: Animation.Infinite
                    ColorAnimation { to: "#f2cdcd"; duration: 714 }
                    ColorAnimation { to: "#f5c2e7"; duration: 714 }
                    ColorAnimation { to: "#cba6f7"; duration: 714 }
                    ColorAnimation { to: "#f38ba8"; duration: 714 }
                    ColorAnimation { to: "#eba0ac"; duration: 714 }
                    ColorAnimation { to: "#fab387"; duration: 714 }
                    ColorAnimation { to: "#f9e2af"; duration: 714 }
                    ColorAnimation { to: "#a6e3a1"; duration: 714 }
                    ColorAnimation { to: "#94e2d5"; duration: 714 }
                    ColorAnimation { to: "#89dceb"; duration: 714 }
                    ColorAnimation { to: "#74c7ec"; duration: 714 }
                    ColorAnimation { to: "#89b4fa"; duration: 714 }
                    ColorAnimation { to: "#b4befe"; duration: 714 }
                    ColorAnimation { to: "#f5e0dc"; duration: 714 }
                }

                SequentialAnimation on c2 {
                    loops: Animation.Infinite
                    ColorAnimation { to: "#f5c2e7"; duration: 714 }
                    ColorAnimation { to: "#cba6f7"; duration: 714 }
                    ColorAnimation { to: "#f38ba8"; duration: 714 }
                    ColorAnimation { to: "#eba0ac"; duration: 714 }
                    ColorAnimation { to: "#fab387"; duration: 714 }
                    ColorAnimation { to: "#f9e2af"; duration: 714 }
                    ColorAnimation { to: "#a6e3a1"; duration: 714 }
                    ColorAnimation { to: "#94e2d5"; duration: 714 }
                    ColorAnimation { to: "#89dceb"; duration: 714 }
                    ColorAnimation { to: "#74c7ec"; duration: 714 }
                    ColorAnimation { to: "#89b4fa"; duration: 714 }
                    ColorAnimation { to: "#b4befe"; duration: 714 }
                    ColorAnimation { to: "#f5e0dc"; duration: 714 }
                    ColorAnimation { to: "#f2cdcd"; duration: 714 }
                }
                
                Text {
                    id: archText
                    anchors.centerIn: parent
                    text: " Arch"
                    color: "#1a1b26"
                    font.family: fontName
                    font.pixelSize: fontSize
                    font.weight: 500
                }
            }

        // =======================
        // RIGHT MODULES
        // =======================
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Network Pill
            Rectangle {
                color: "#27293F"
                radius: 18
                implicitHeight: 34
                implicitWidth: networkText.implicitWidth + 32
                Layout.alignment: Qt.AlignVCenter
                Text {
                    id: networkText
                    anchors.centerIn: parent
                    text: ""
                    color: fg
                    font.family: fontName
                    font.pixelSize: fontSize
                }
                
                Process {
                    id: networkProc
                    command: ["sh", "-c", "ip route get 1.1.1.1"]
                    stdout: StdioCollector {
                        onStreamFinished: (data) => {
                            networkText.text = (data || "").includes("uid") ? "  Connected" : "󰖪"
                        }
                    }
                }
                
                Timer {
                    interval: 2000; running: true; repeat: true
                    onTriggered: networkProc.running = true
                }
            }

            // Hardware Pill
            Rectangle {
                radius: 18
                implicitHeight: 34
                id: hwPill
                implicitWidth: hwText.implicitWidth + 32
                Layout.alignment: Qt.AlignVCenter
                color: "#24273a" // from custom-hw gradient
                Text {
                    id: hwText
                    anchors.centerIn: parent
                    text: "HW"
                    color: "#cad3f5"
                    font.family: fontName
                    font.pixelSize: fontSize
                }
                Process {
                    id: hwProc
                    command: ["sh", "-c", "~/.config/cupcake/scripts/hw_toggle_display.sh"]
                    stdout: StdioCollector {
                        onStreamFinished: (data) => {
                            try { hwText.text = JSON.parse(data).text || "" } catch(e) { hwText.text = data || "" }
                            hwPill.visible = hwText.text !== ""
                        }
                    }
                }
                Timer {
                    interval: 1000; running: true; repeat: true
                    onTriggered: hwProc.running = true
                }
                MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached("~/.config/cupcake/scripts/hw_toggle_state.sh") }
            }

            // Recording Pill
            Rectangle {
                color: "#27293F"
                radius: 18
                implicitHeight: 34
                id: recPill
                implicitWidth: recText.implicitWidth + 32
                Layout.alignment: Qt.AlignVCenter
                Text {
                    id: recText
                    anchors.centerIn: parent
                    text: ""
                    color: fg
                    font.family: fontName
                    font.pixelSize: fontSize
                }
                Process {
                    id: recProc
                    command: ["sh", "-c", "~/.config/cupcake/scripts/rec-status.sh"]
                    stdout: StdioCollector {
                        onStreamFinished: (data) => {
                            try { recText.text = JSON.parse(data).text || "" } catch(e) { recText.text = data || "" }
                            recPill.visible = recText.text !== ""
                        }
                    }
                }
                Timer {
                    interval: 1000; running: true; repeat: true
                    onTriggered: recProc.running = true
                }
            }

            // Tray Pill
            Rectangle {
                color: "#27293F"
                radius: 18
                implicitHeight: 34
                implicitWidth: trayRow.implicitWidth + 32
                Layout.alignment: Qt.AlignVCenter
                Row {
                    id: trayRow
                    anchors.centerIn: parent
                    spacing: 8
                    
                    Repeater {
                        model: SystemTray.items
                        delegate: Image {
                            source: modelData.icon || ""
                            sourceSize: Qt.size(18, 18)
                            width: 18
                            height: 18
                            fillMode: Image.PreserveAspectFit
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.LeftButton) {
                                        modelData.activate()
                                    } else if (mouse.button === Qt.RightButton) {
                                        if (modelData.hasMenu) {
                                            var pos = mapToItem(bar.contentItem, mouse.x, mouse.y)
                                            modelData.display(bar, pos.x, pos.y)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Controls Pill (#control)
            Rectangle {
                id: controlsPill
                color: "#27293F"
                radius: 18
                implicitHeight: 34
                implicitWidth: controlsRow.implicitWidth + 32
                clip: true
                
                property bool actionsExpanded: false
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: controlsPill.actionsExpanded = !controlsPill.actionsExpanded
                    cursorShape: Qt.PointingHandCursor
                }
                
                Row {
                    id: controlsRow
                    anchors.centerIn: parent
                    spacing: 12
                    
                    // Audio
                    Row {
                        spacing: 0
                        Text { text: audioSlider.value === 0 ? "" : (audioSlider.value < 50 ? "" : ""); color: fg; font.family: fontName; font.pixelSize: fontSize; anchors.verticalCenter: parent.verticalCenter }
                        Slider {
                            id: audioSlider
                            leftPadding: 8
                            width: controlsPill.actionsExpanded ? 108 : 0
                            clip: true
                            handle: Rectangle {
                                x: audioSlider.leftPadding + audioSlider.visualPosition * (audioSlider.availableWidth - width)
                                y: audioSlider.topPadding + audioSlider.availableHeight / 2 - height / 2
                                width: 14; height: 14
                                color: "transparent"
                            }
                            background: Rectangle {
                                x: audioSlider.leftPadding
                                y: audioSlider.topPadding + audioSlider.availableHeight / 2 - height / 2
                                implicitWidth: 100
                                implicitHeight: 14
                                width: audioSlider.availableWidth
                                height: implicitHeight
                                radius: 7
                                color: "#1a1b26" // track color
                                Rectangle {
                                    width: audioSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: "#b4befe" // fill color
                                    radius: 7
                                }
                            }
                            Behavior on width { NumberAnimation { duration: 500; easing.type: controlsPill.actionsExpanded ? Easing.OutBack : Easing.InOutCubic; easing.overshoot: 1.5 } }
                            from: 0; to: 100; value: 50
                            anchors.verticalCenter: parent.verticalCenter
                            onMoved: { Quickshell.execDetached(["pamixer", "--set-volume", Math.round(value).toString()]) }
                            
                            Process {
                                id: audioProc
                                command: ["pamixer", "--get-volume"]
                                running: true
                                stdout: StdioCollector { id: audioStdout }
                                onExited: {
                                    let val = parseInt((audioStdout.text || "").trim());
                                    if (!isNaN(val) && !audioSlider.pressed) audioSlider.value = val;
                                }
                            }
                            Timer {
                                interval: 3000; running: true; repeat: true
                                onTriggered: audioProc.running = true
                            }
                        }
                        Text {
                            leftPadding: 8
                            text: Math.round(audioSlider.value) + "%"
                            color: fg; font.family: fontName; font.pixelSize: fontSize; font.weight: 500
                            width: (controlsHover.hovered || controlsPill.actionsExpanded) ? implicitWidth : 0
                            clip: true
                            Behavior on width { NumberAnimation { duration: 500; easing.type: (controlsHover.hovered || controlsPill.actionsExpanded) ? Easing.OutBack : Easing.InOutCubic; easing.overshoot: 1.5 } }
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    // Backlight
                    Row {
                        spacing: 0
                        Text { text: lightSlider.value < 33 ? "󰃞" : (lightSlider.value < 66 ? "󰃝" : "󰃠"); color: fg; font.family: fontName; font.pixelSize: fontSize; anchors.verticalCenter: parent.verticalCenter }
                        Slider {
                            id: lightSlider
                            leftPadding: 8
                            width: controlsPill.actionsExpanded ? 108 : 0
                            clip: true
                            handle: Rectangle {
                                x: lightSlider.leftPadding + lightSlider.visualPosition * (lightSlider.availableWidth - width)
                                y: lightSlider.topPadding + lightSlider.availableHeight / 2 - height / 2
                                width: 14; height: 14
                                color: "transparent"
                            }
                            background: Rectangle {
                                x: lightSlider.leftPadding
                                y: lightSlider.topPadding + lightSlider.availableHeight / 2 - height / 2
                                implicitWidth: 100
                                implicitHeight: 14
                                width: lightSlider.availableWidth
                                height: implicitHeight
                                radius: 7
                                color: "#1a1b26" // track color
                                Rectangle {
                                    width: lightSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: "#f9e2af" // fill color
                                    radius: 7
                                }
                            }
                            Timer {
                                id: ddcTimer
                                interval: 150
                                repeat: false
                                property int targetValue: 100
                                onTriggered: Quickshell.execDetached(["ddcutil", "setvcp", "10", Math.round(targetValue).toString(), "--noverify"])
                            }
                            Behavior on width { NumberAnimation { duration: 500; easing.type: controlsPill.actionsExpanded ? Easing.OutBack : Easing.InOutCubic; easing.overshoot: 1.5 } }
                            from: 0; to: 100; value: 100
                            anchors.verticalCenter: parent.verticalCenter
                            onMoved: { 
                                ddcTimer.targetValue = value;
                                ddcTimer.restart();
                            }
                            onPressedChanged: {
                                if (!pressed) {
                                    ddcTimer.stop();
                                    Quickshell.execDetached(["ddcutil", "setvcp", "10", Math.round(value).toString()]);
                                }
                            }
                            
                            Process {
                                id: lightProc
                                command: ["ddcutil", "getvcp", "10", "--terse"]
                                running: true
                                stdout: StdioCollector { id: lightStdout }
                                onExited: {
                                    let parts = (lightStdout.text || "").trim().split(" ");
                                    if (parts.length >= 4) {
                                        let val = parseInt(parts[3]);
                                        if (!isNaN(val) && !lightSlider.pressed) lightSlider.value = val;
                                    }
                                }
                            }
                        }
                        Text {
                            leftPadding: 8
                            text: Math.round(lightSlider.value) + "%"
                            color: fg; font.family: fontName; font.pixelSize: fontSize; font.weight: 500
                            width: (controlsHover.hovered || controlsPill.actionsExpanded) ? implicitWidth : 0
                            clip: true
                            Behavior on width { NumberAnimation { duration: 500; easing.type: (controlsHover.hovered || controlsPill.actionsExpanded) ? Easing.OutBack : Easing.InOutCubic; easing.overshoot: 1.5 } }
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                HoverHandler { 
                    id: controlsHover 
                    onHoveredChanged: {
                        if (!hovered && controlsPill.actionsExpanded) {
                            controlsPill.actionsExpanded = false;
                        }
                    }
                }
            }

            // Clock/Notif Pill (#clock-notif-pill)
            Rectangle {
                id: clockPill
                radius: 18
                implicitHeight: 34
                color: "#27293F"
                implicitWidth: hasDropdown ? 380 : clockRow.implicitWidth + 32
                Behavior on implicitWidth { NumberAnimation { duration: 400; easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack; easing.overshoot: 0.5 } }
                Layout.alignment: Qt.AlignVCenter
                clip: true
                
                property var activeNotif: globalState.popups && globalState.popups.length > 0 ? globalState.popups[0] : null

                property bool hasDropdown: globalState.popups && globalState.popups.length > 0 && !globalState.hideIsland
                
                onWidthChanged: {
                    globalState.islandWidth = width;
                }
                Component.onCompleted: {
                    globalState.islandWidth = width;
                }

                Rectangle {
                    anchors.fill: parent
                    color: "#27293F"
                    radius: 18
                }
                
                Row {
                    id: clockRow
                    anchors.centerIn: parent
                    spacing: 5
                    
                    // --- Standard Clock State ---
                    Row {
                        id: mainClockRow
                        spacing: 5
                        opacity: 1.0
                        
                        NumberAnimation {
                            id: mainClockFadeIn
                            target: mainClockRow
                            property: "opacity"
                            to: 1.0
                            duration: 400
                            easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack
                        }
                        
                        NumberAnimation {
                            id: mainClockFadeOut
                            target: mainClockRow
                            property: "opacity"
                            to: 0.0
                            duration: 400
                            easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack
                        }
                        
                        Timer {
                            id: mainClockDelayTimer
                            interval: 400
                            onTriggered: mainClockFadeIn.start()
                        }
                        
                        Connections {
                            target: clockPill
                            function onHasDropdownChanged() {
                                if (clockPill.hasDropdown) {
                                    mainClockFadeIn.stop();
                                    mainClockDelayTimer.stop();
                                    mainClockFadeOut.start();
                                } else {
                                    mainClockFadeOut.stop();
                                    mainClockDelayTimer.start();
                                }
                            }
                        }

                        Text {
                            id: notifText
                            text: "󰂚"
                            color: fg; font.family: fontName; font.pixelSize: fontSize
                            MouseArea {
                                anchors.fill: parent;
                                cursorShape: Qt.PointingHandCursor
                                onClicked: globalState.notifPanelVisible = !globalState.notifPanelVisible
                            }
                        }

                        Text { text: " | "; color: fg; font.family: fontName; font.pixelSize: fontSize }

                        Text {
                            id: customClockText
                            text: Qt.formatDateTime(timeClock.date, "MMM dd  hh:mm AP")
                            color: fg
                            font.family: fontName
                            font.pixelSize: fontSize
                            font.weight: 500
                            onTextChanged: globalState.clockString = text
                            Component.onCompleted: globalState.clockString = text

                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached("~/.config/cupcake/scripts/toggle_clock.sh") }
                        }
                        
                        Process {
                            id: clockProc
                            command: ["sh", "-c", "~/.config/cupcake/scripts/display_clock.sh"]
                            stdout: StdioCollector {
                                onStreamFinished: (data) => {
                                    try { customClockText.text = JSON.parse(data).text || customClockText.text } catch(e) { if(data) customClockText.text = data }
                                }
                            }
                        }
                        Timer {
                            interval: 1000; running: true; repeat: true
                            onTriggered: clockProc.running = true
                        }
                    }
                    
                    }
            }

            // Power Pill (#custom-power)
            Rectangle {
                id: powerPill
                radius: 18
                implicitHeight: 34
                color: powerHover.hovered ? "#f33958" : "#eebac3"
                Behavior on color { ColorAnimation { duration: 500 } }
                implicitWidth: powerRow.implicitWidth + 32
                clip: true
                
                property bool actionsExpanded: false
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: powerPill.actionsExpanded = !powerPill.actionsExpanded
                    cursorShape: Qt.PointingHandCursor
                }

                Row {
                    id: powerRow
                    anchors.centerIn: parent
                    spacing: 0
                    
                    // Slide-left Revealer
                    Item {
                        id: powerRevealer
                        height: 34
                        width: (powerHover.hovered || powerPill.actionsExpanded) ? innerContent.implicitWidth : 0
                        clip: true
                        Behavior on width { NumberAnimation { duration: 500; easing.type: (powerHover.hovered || powerPill.actionsExpanded) ? Easing.OutBack : Easing.InOutCubic; easing.overshoot: 1.5 } }
                        
                        Row {
                            id: innerContent
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            
                            // State 1: Hover Text
                            Text {
                                text: "Power "
                                color: bg
                                font.family: fontName
                                font.pixelSize: fontSize
                                font.weight: 500
                                visible: !powerPill.actionsExpanded
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            // State 2: Clicked Actions
                            Row {
                                spacing: 12
                                visible: powerPill.actionsExpanded
                                anchors.verticalCenter: parent.verticalCenter
                                Text { text: "󰤄 Sleep "; color: bg; font.family: fontName; font.pixelSize: fontSize; font.weight: 600; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { mouse.accepted = true; Quickshell.execDetached(["systemctl", "suspend"]); } } }
                                Text { text: "󰗽 Logout "; color: bg; font.family: fontName; font.pixelSize: fontSize; font.weight: 600; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { mouse.accepted = true; Quickshell.execDetached(["hyprctl", "dispatch", "exit"]); } } }
                                Text { text: " Reboot "; color: bg; font.family: fontName; font.pixelSize: fontSize; font.weight: 600; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { mouse.accepted = true; Quickshell.execDetached(["systemctl", "reboot"]); } } }
                                Text { text: " Shutdown "; color: bg; font.family: fontName; font.pixelSize: fontSize; font.weight: 600; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { mouse.accepted = true; Quickshell.execDetached(["systemctl", "poweroff"]); } } }
                            }
                        }
                    }
                    
                    // Main Icon
                    Text {
                        text: ""
                        color: bg
                        font.family: fontName
                        font.pixelSize: fontSize
                        font.weight: 500
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !powerPill.actionsExpanded
                    }
                }

                HoverHandler { 
                    id: powerHover 
                    onHoveredChanged: {
                        if (!hovered && powerPill.actionsExpanded) {
                            powerPill.actionsExpanded = false;
                        }
                    }
                }
            }
        }
    }

    // ── Nested Notification Dropdown Window ──────
    // Implemented as a separate Wayland layer to prevent main Bar flicker, but embedded to avoid separate files.
    PanelWindow {
        id: dropdownWindow
        visible: globalState.popups && globalState.popups.length > 0 || globalState.closingIsland
        
        anchors.top: true
        anchors.right: true
        
        // Match the clock pill's position (10px from top, 62px from right including power pill + margins)
        margins.top: 10
        margins.right: 62

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "waybar-dropdown"
        WlrLayershell.layer: WlrLayer.Overlay

        implicitWidth: 380
        implicitHeight: 600
        
        property bool closingIsland: globalState.closingIsland
        property bool hasDropdown: globalState.popups && globalState.popups.length > 0 && !globalState.hideIsland

        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            
            width: globalState.islandWidth

            height: dropdownWindow.hasDropdown ? Math.min(600, Math.max(34, dropdownCol.height + 16)) : 34
            Behavior on height { NumberAnimation { duration: 400; easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack; easing.overshoot: 0.5 } }

            color: "#27293F"
            radius: 18
            clip: true
            
            opacity: 1.0
            
            Item {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 34
                
                Row {
                    id: overlayClock
                    anchors.centerIn: parent
                    spacing: 5
                    opacity: 1.0
                    
                    NumberAnimation {
                        id: explicitFadeOut
                        target: overlayClock
                        property: "opacity"
                        to: 0.0
                        duration: 400
                        easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack
                    }
                    
                    NumberAnimation {
                        id: explicitFadeIn
                        target: overlayClock
                        property: "opacity"
                        to: 1.0
                        duration: 400
                        easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack
                    }
                    
                    Timer {
                        id: overlayFadeInDelay
                        interval: 400
                        onTriggered: explicitFadeIn.start()
                    }
                    
                    Connections {
                        target: dropdownWindow
                        function onHasDropdownChanged() {
                            if (!dropdownWindow.hasDropdown) {
                                explicitFadeOut.stop();
                                overlayFadeInDelay.start();
                            }
                        }
                        function onVisibleChanged() {
                            if (dropdownWindow.visible && dropdownWindow.hasDropdown) {
                                // Force initial opacity before starting animation
                                overlayClock.opacity = 1.0;
                                explicitFadeIn.stop();
                                overlayFadeInDelay.stop();
                                explicitFadeOut.start();
                            }
                        }
                    }
                    
                    Text { text: "󰂚"; color: "#eeffff"; font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 14 }
                    Text { text: " | "; color: "#eeffff"; font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 14 }
                    Text { 
                        text: globalState.clockString || Qt.formatDateTime(new Date(), "MMM dd  hh:mm AP")
                        color: "#eeffff"; font.family: "JetBrainsMono Nerd Font Propo"; font.pixelSize: 14; font.weight: 500 
                    }
                }
            }
            
            Column {
                id: dropdownCol
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.topMargin: 8
                width: 364
                
                transformOrigin: Item.TopRight
                scale: dropdownWindow.hasDropdown ? 1.0 : 0.0
                opacity: dropdownWindow.hasDropdown ? 1.0 : 0.0
                
                Behavior on scale { NumberAnimation { duration: 400; easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack; easing.overshoot: 0.5 } }
                Behavior on opacity { NumberAnimation { duration: 400; easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack } }

                spacing: 6
                Repeater {
                    model: globalState.popups && globalState.popups.length > 0 ? globalState.popups.slice(0, 5) : []
                    delegate: NotificationCard {
                        width: dropdownCol.width
                        notificationData: modelData
                        inPanel: false
                    }
                }
            }
        }
    }
}
}
