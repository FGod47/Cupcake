import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
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
                Behavior on implicitWidth { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                
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
                    Text { text: ""; color: fg; font.family: fontName; font.pixelSize: fontSize }
                    Text { text: ""; color: fg; font.family: fontName; font.pixelSize: fontSize }
                }
            }

            // Controls Pill (#control)
            Rectangle {
                id: controlsPill
                color: "#27293F"
                radius: 18
                implicitHeight: 34
                implicitWidth: controlsRow.implicitWidth + 32
                Behavior on implicitWidth { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                
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
                        spacing: 8
                        Text { text: ""; color: fg; font.family: fontName; font.pixelSize: fontSize; anchors.verticalCenter: parent.verticalCenter }
                        Slider {
                            id: audioSlider
                            width: controlsPill.actionsExpanded ? 100 : 0
                            visible: width > 0
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
                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            from: 0; to: 100; value: 50
                            anchors.verticalCenter: parent.verticalCenter
                            onMoved: { Quickshell.execDetached(["pamixer", "--set-volume", Math.round(value).toString()]) }
                        }
                        Text {
                            text: Math.round(audioSlider.value) + "%"
                            color: fg; font.family: fontName; font.pixelSize: fontSize; font.weight: 500
                            width: (controlsHover.hovered || controlsPill.actionsExpanded) ? implicitWidth : 0
                            visible: width > 0
                            clip: true
                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    // Backlight
                    Row {
                        spacing: 8
                        Text { text: "☀"; color: fg; font.family: fontName; font.pixelSize: fontSize; anchors.verticalCenter: parent.verticalCenter }
                        Slider {
                            id: lightSlider
                            width: controlsPill.actionsExpanded ? 100 : 0
                            visible: width > 0
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
                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
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
                        }
                        Text {
                            text: Math.round(lightSlider.value) + "%"
                            color: fg; font.family: fontName; font.pixelSize: fontSize; font.weight: 500
                            width: (controlsHover.hovered || controlsPill.actionsExpanded) ? implicitWidth : 0
                            visible: width > 0
                            clip: true
                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
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
                radius: 18
                implicitHeight: 34
                color: "#27293F"
                implicitWidth: clockRow.implicitWidth + 32
                Layout.alignment: Qt.AlignVCenter
                Row {
                    id: clockRow
                    anchors.centerIn: parent
                    spacing: 5
                    
                    Text { 
                        id: notifText
                        text: "󰂚"
                        color: fg; font.family: fontName; font.pixelSize: fontSize 
                        MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached("~/.config/cupcake/scripts/toggle_bar.sh") }
                    }
                    
                    Text { text: " | "; color: fg; font.family: fontName; font.pixelSize: fontSize }
                    
                    Text { 
                        id: customClockText
                        text: Qt.formatDateTime(timeClock.date, "MMM dd  hh:mm AP")
                        color: fg 
                        font.family: fontName
                        font.pixelSize: fontSize
                        font.weight: 500
                        
                        MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached("~/.config/cupcake/scripts/toggle_clock.sh") }
                    }
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

            // Power Pill (#custom-power)
            Rectangle {
                id: powerPill
                radius: 18
                implicitHeight: 34
                color: powerHover.hovered ? "#f33958" : "#eebac3"
                Behavior on color { ColorAnimation { duration: 300 } }
                implicitWidth: powerRow.implicitWidth + 32
                Behavior on implicitWidth { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                
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
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        
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
}
