import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
import QtQuick.Controls
import "theme"

PanelWindow {
    id: bar
    anchors {
        top: true
        left: true
        right: true
    }
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 46

    // and to allow the Settings menu to animate to the center of the screen
    implicitHeight: modelData.height
    color: "transparent"
    
    mask: normalMask
    
    Region {
        id: normalMask
        Region { item: leftModules }
        Region { item: archPill }
        Region { item: rightModules }
    }

    property var modelData
    screen: modelData
    


    SystemClock {
        id: timeClock
        precision: SystemClock.Minutes 
    }

    // Shared style definitions based on user's style.css
    property color bg: Theme.colSurface
    property color fg: Theme.colOnSurface
    property string fontName: "tabler-icons"
    property int fontSize: Theme.defaultFontSize

    // Full-screen click-away area when settings is open
    MouseArea {
        id: fullScreenClickAway
        anchors.fill: parent
        enabled: bar.settingsOpen
        onClicked: bar.settingsOpen = false
        z: -1
    }

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
            id: leftModules
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            
            visible: true
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            // Workspaces Pill (#workspaces)
            Rectangle {
                color: root.barTransparency ? Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity) : Theme.colSurface
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
                        delegate: Item {
                            width: 32
                            height: 34
                            property int wsId: index + 1
                            property bool isFocused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
                            property bool isOccupied: isFocused || Hyprland.workspaces.values.some(ws => ws.id === wsId)

                            // Active Workspace Background Bubble (Large Circle)
                            Rectangle {
                                anchors.centerIn: parent
                                width: isFocused ? 26 : 0
                                height: width
                                radius: width / 2
                                color: Theme.colPrimary
                                opacity: isFocused ? 1 : 0
                                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            // Inner Dot (For focused, occupied, or empty)
                            Rectangle {
                                anchors.centerIn: parent
                                width: isFocused ? 6 : (isOccupied ? 8 : 6)
                                height: width
                                radius: width / 2
                                color: isFocused ? Theme.colOnPrimary : (isOccupied ? fg : Qt.rgba(fg.r, fg.g, fg.b, 0.4))
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on width { NumberAnimation { duration: 150 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: Hyprland.dispatch("hl.dsp.focus({workspace = " + wsId + "})")
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
                color: Theme.colPrimary
                implicitWidth: windowText.implicitWidth > 0 ? Math.min(windowText.implicitWidth, 400) + 32 : 0
                Layout.alignment: Qt.AlignVCenter
                visible: Hyprland.activeToplevel && Hyprland.activeToplevel.title !== ""
                clip: true
                Behavior on implicitWidth { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                
                Text {
                    id: windowText
                    anchors.centerIn: parent
                    text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
                    color: Theme.colSurfaceContainerHigh
                    font.family: Theme.defaultFontFamily
                    font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    width: Math.min(implicitWidth, 400)
                }
            }
        }



        // =======================
        // RIGHT MODULES
        // =======================
        Row {
            id: rightModules
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            
            visible: true
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            // Network Pill
            Rectangle {
                color: root.barTransparency ? Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity) : Theme.colSurface
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
                    font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
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
                color: root.barTransparency ? Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity) : Theme.colSurface // from custom-hw gradient
                Text {
                    id: hwText
                    anchors.centerIn: parent
                    text: "HW"
                    color: Theme.colOnSurfaceVariant
                    font.family: fontName
                    font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
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
                color: root.barTransparency ? Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity) : Theme.colSurface
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
                    font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
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
                color: root.barTransparency ? Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity) : Theme.colSurface
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
                color: root.barTransparency ? Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity) : Theme.colSurface
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
                        Text { text: audioSlider.value === 0 ? "" : (audioSlider.value < 50 ? "" : ""); color: fg; font.family: fontName; font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize; anchors.verticalCenter: parent.verticalCenter }
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
                                color: Theme.colSurfaceContainerHigh // track color
                                Rectangle {
                                    width: audioSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: Theme.colPrimary // fill color
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
                            color: fg; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight
                            width: (controlsHover.hovered || controlsPill.actionsExpanded) ? implicitWidth : 0
                            clip: true
                            Behavior on width { NumberAnimation { duration: 500; easing.type: (controlsHover.hovered || controlsPill.actionsExpanded) ? Easing.OutBack : Easing.InOutCubic; easing.overshoot: 1.5 } }
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    // Backlight
                    Row {
                        spacing: 0
                        Text { text: lightSlider.value < 33 ? "" : (lightSlider.value < 66 ? "" : ""); color: fg; font.family: fontName; font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize; anchors.verticalCenter: parent.verticalCenter }
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
                                color: Theme.colSurfaceContainerHigh // track color
                                Rectangle {
                                    width: lightSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: Theme.colSecondary // fill color
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
                            color: fg; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight
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
            Item {
                implicitWidth: clockPill.width
                implicitHeight: 34
                
                Rectangle {
                    id: clockPill
                    y: 0
                    radius: 18
                    height: hasDropdown ? Math.min(600, Math.max(34, dropdownCol.height + 16)) : 34
                    Behavior on height { NumberAnimation { duration: 400; easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack; easing.overshoot: 0.5 } }
                    color: root.barTransparency ? Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity) : Theme.colSurface
                    width: hasDropdown ? 380 : clockRow.implicitWidth + 32
                    Behavior on width { NumberAnimation { duration: 400; easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack; easing.overshoot: 0.5 } }
                    clip: true
                    
                    property var activeNotif: globalState.popups && globalState.popups.length > 0 ? globalState.popups[0] : null
                    property bool hasDropdown: globalState.popups && globalState.popups.length > 0 && !globalState.hideIsland
                    
                    onWidthChanged: globalState.islandWidth = width
                    Component.onCompleted: globalState.islandWidth = width

                    Row {
                        id: clockRow
                        anchors.top: parent.top
                        anchors.topMargin: (34 - height) / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 5
                        
                        // --- Standard Clock State ---
                        Row {
                            id: mainClockRow
                            spacing: 5
                            opacity: 1.0
                            
                            NumberAnimation { id: mainClockFadeIn; target: mainClockRow; property: "opacity"; to: 1.0; duration: 400; easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack }
                            NumberAnimation { id: mainClockFadeOut; target: mainClockRow; property: "opacity"; to: 0.0; duration: 400; easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack }
                            Timer { id: mainClockDelayTimer; interval: 400; onTriggered: mainClockFadeIn.start() }
                            
                            Connections {
                                target: clockPill
                                function onHasDropdownChanged() {
                                    if (clockPill.hasDropdown) {
                                        mainClockFadeIn.stop(); mainClockDelayTimer.stop(); mainClockFadeOut.start();
                                    } else {
                                        mainClockFadeOut.stop(); mainClockDelayTimer.start();
                                    }
                                }
                            }




                            Text {
                                id: settingsLaunchText
                                text: "󰒓"
                                color: Theme.colPrimary; font.family: fontName; font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                                MouseArea { 
                                    anchors.fill: parent; 
                                    cursorShape: Qt.PointingHandCursor; 
                                    onClicked: Quickshell.execDetached(["quickshell", "-p", root.homeDir + "/.config/quickshell/Settings.qml"]) 
                                }
                            }

                            Text { text: " | "; color: fg; font.family: fontName; font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize }

                            Text {
                                id: notifText
                                text: "󰂚"
                                color: Theme.colPrimary; font.family: fontName; font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: globalState.notifPanelVisible = !globalState.notifPanelVisible }
                            }

                            Text { text: " | "; color: fg; font.family: fontName; font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize }

                            Text {
                                id: customClockText
                                text: Qt.formatDateTime(timeClock.date, "MMM dd  hh:mm AP")
                                color: fg; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight
                                onTextChanged: globalState.clockString = text
                                Component.onCompleted: globalState.clockString = text
                                MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached("~/.config/cupcake/scripts/toggle_clock.sh") }
                            }
                            
                            Process {
                                id: clockProc
                                command: ["sh", "-c", "~/.config/cupcake/scripts/display_clock.sh"]
                                stdout: StdioCollector { onStreamFinished: (data) => { try { customClockText.text = JSON.parse(data).text || customClockText.text } catch(e) { if(data) customClockText.text = data } } }
                            }
                            Timer { interval: 5000; running: true; repeat: true; onTriggered: clockProc.running = true }
                        }
                    }

                    // The overlay clock (when expanded)
                    Row {
                        id: overlayClock
                        visible: false
                        anchors.top: parent.top
                        anchors.topMargin: (34 - height) / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 5
                        opacity: 0.0
                        
                        NumberAnimation { id: explicitFadeOut; target: overlayClock; property: "opacity"; to: 0.0; duration: 400; easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack }
                        NumberAnimation { id: explicitFadeIn; target: overlayClock; property: "opacity"; to: 1.0; duration: 400; easing.type: globalState.closingIsland ? Easing.InOutCubic : Easing.OutBack }
                        Timer { id: overlayFadeInDelay; interval: 400; onTriggered: explicitFadeIn.start() }
                        
                        Connections {
                            target: clockPill
                            function onHasDropdownChanged() {
                                if (!clockPill.hasDropdown) { explicitFadeIn.stop(); explicitFadeOut.start(); }
                                else { explicitFadeOut.stop(); overlayClock.opacity = 1.0; explicitFadeIn.start(); }
                            }
                        }
                        Text { text: "󰂚"; color: Theme.colPrimary; font.family: "tabler-icons"; font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize }
                        Text { text: " | "; color: Theme.colOnSurface; font.family: "tabler-icons"; font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize }
                        Text { text: globalState.clockString || Qt.formatDateTime(new Date(), "MMM dd  hh:mm AP"); color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight }
                    }

                    // The dropdown column
                    Column {
                        id: dropdownCol
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 8
                        
                        transformOrigin: Item.TopRight
                        scale: clockPill.hasDropdown ? 1.0 : 0.0
                        opacity: clockPill.hasDropdown ? 1.0 : 0.0
                        
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
            // Power Pill (#custom-power)
            Rectangle {
                id: powerPill
                radius: 18
                implicitHeight: 34
                color: powerHover.hovered ? Theme.colError : Theme.colPrimary
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
                                font.family: Theme.defaultFontFamily
                                font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                                visible: !powerPill.actionsExpanded
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            // State 2: Clicked Actions
                            Row {
                                spacing: 12
                                visible: powerPill.actionsExpanded
                                anchors.verticalCenter: parent.verticalCenter
                                Item { implicitWidth: sleepRow.implicitWidth; implicitHeight: sleepRow.implicitHeight; Row { id: sleepRow; spacing: 4; Text { text: ""; color: bg; font.family: fontName; font.pixelSize: Theme.defaultFontSize; font.weight: 600 } Text { text: "Sleep "; color: bg; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: 600 } } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { mouse.accepted = true; Quickshell.execDetached(["bash", "-c", "systemctl suspend"]); } } }
                                Item { implicitWidth: logoutRow.implicitWidth; implicitHeight: logoutRow.implicitHeight; Row { id: logoutRow; spacing: 4; Text { text: ""; color: bg; font.family: fontName; font.pixelSize: Theme.defaultFontSize; font.weight: 600 } Text { text: "Logout "; color: bg; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: 600 } } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { mouse.accepted = true; Quickshell.execDetached(["bash", "-c", "loginctl kill-session $XDG_SESSION_ID"]); } } }
                                Item { implicitWidth: rebootRow.implicitWidth; implicitHeight: rebootRow.implicitHeight; Row { id: rebootRow; spacing: 4; Text { text: ""; color: bg; font.family: fontName; font.pixelSize: Theme.defaultFontSize; font.weight: 600 } Text { text: "Reboot "; color: bg; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: 600 } } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { mouse.accepted = true; Quickshell.execDetached(["bash", "-c", "systemctl reboot"]); } } }
                                Item { implicitWidth: shutdownRow.implicitWidth; implicitHeight: shutdownRow.implicitHeight; Row { id: shutdownRow; spacing: 4; Text { text: ""; color: bg; font.family: fontName; font.pixelSize: Theme.defaultFontSize; font.weight: 600 } Text { text: "Shutdown "; color: bg; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: 600 } } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { mouse.accepted = true; Quickshell.execDetached(["bash", "-c", "systemctl poweroff"]); } } }
                            }
                        }
                    }
                    
                    // Main Icon
                    Text {
                        text: ""
                        color: bg
                        font.family: fontName
                        font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
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
    // Moved archPill out of 46px restricted Item
        // =======================
        // CENTER MODULES
        // =======================
        
        
        Rectangle {
            id: archPill
            y: 10
            anchors.horizontalCenter: parent.horizontalCenter
            radius: 18
            width: archText.implicitWidth + 32
            height: 34
            
            property color c1: Theme.colPrimary
            property color c2: Theme.colSecondary
            
            color: root.barTransparency ? Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, root.barOpacity) : Theme.colSurface
            border.width: 1
            border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.3)
            
            Rectangle {
                anchors.fill: parent
                radius: 18
                
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: archPill.c1 }
                    GradientStop { position: 1.0; color: archPill.c2 }
                }
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
            
            Row {
                id: archText
                anchors.centerIn: parent
                spacing: 6
                Text {
                    text: ""
                    color: Theme.colSurfaceContainerHigh
                    font.family: Theme.monoFontFamily
                    font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                }
                Text {
                    text: "Arch"
                    color: Theme.colSurfaceContainerHigh
                    font.family: Theme.defaultFontFamily
                    font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                }
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // Placeholder for future use
                }
            }
        }
}
