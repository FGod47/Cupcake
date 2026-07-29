import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"

Rectangle {
    id: powerPill
    radius: 18
    
    property color bg: Theme.colSurface
    property string fontName: "tabler-icons"
    
    property bool actionsExpanded: globalState.powerMenuOpen
    property bool confirmingDefault: false
    property string pendingAction: ""
    
    property int selectedIndex: 0
    property int confirmIndex: 1
    property bool keyboardNavigating: false
    
    onActionsExpandedChanged: {
        if (actionsExpanded) {
            selectedIndex = 0;
            confirmIndex = 1;
            keyboardNavigating = true;
            powerPill.forceActiveFocus();
        } else {
            keyboardNavigating = false;
        }
    }
    
    focus: globalState.powerMenuOpen
    Keys.onUpPressed: function(event) {
        if (powerPill.confirmingDefault) return;
        powerPill.keyboardNavigating = true;
        powerPill.selectedIndex = (powerPill.selectedIndex - 1 + 4) % 4;
        event.accepted = true;
    }
    Keys.onDownPressed: function(event) {
        if (powerPill.confirmingDefault) return;
        powerPill.keyboardNavigating = true;
        powerPill.selectedIndex = (powerPill.selectedIndex + 1) % 4;
        event.accepted = true;
    }
    Keys.onLeftPressed: function(event) {
        if (!powerPill.confirmingDefault) return;
        powerPill.keyboardNavigating = true;
        powerPill.confirmIndex = (powerPill.confirmIndex - 1 + 2) % 2;
        event.accepted = true;
    }
    Keys.onRightPressed: function(event) {
        if (!powerPill.confirmingDefault) return;
        powerPill.keyboardNavigating = true;
        powerPill.confirmIndex = (powerPill.confirmIndex + 1) % 2;
        event.accepted = true;
    }
    Keys.onEscapePressed: function(event) {
        powerPill.keyboardNavigating = true;
        if (powerPill.confirmingDefault) {
            powerPill.confirmingDefault = false;
        } else {
            globalState.powerMenuOpen = false;
        }
        event.accepted = true;
    }
    Keys.onReturnPressed: function(event) {
        powerPill.keyboardNavigating = true;
        if (!powerPill.confirmingDefault) {
            if (powerPill.selectedIndex === 0) { powerPill.pendingAction = "sleep"; powerPill.launchHeroFrom(sleepIconRect); }
            else if (powerPill.selectedIndex === 1) { powerPill.pendingAction = "logout"; powerPill.launchHeroFrom(logoutIconRect); }
            else if (powerPill.selectedIndex === 2) { powerPill.pendingAction = "reboot"; powerPill.launchHeroFrom(rebootIconRect); }
            else if (powerPill.selectedIndex === 3) { powerPill.pendingAction = "shutdown"; powerPill.launchHeroFrom(shutdownIconRect); }
            powerPill.confirmIndex = 1;
            powerPill.confirmingDefault = true;
        } else {
            if (powerPill.confirmIndex === 1) {
                powerPill.executeAction(powerPill.pendingAction);
            } else {
                powerPill.confirmingDefault = false;
            }
        }
        event.accepted = true;
    }
    
    property real targetHeight: actionsExpanded ? (state2Column.implicitHeight + 24) : 34
    property real targetWidth: actionsExpanded ? (state2Column.implicitWidth + 24) : (powerHover.containsMouse ? (34 + powerHoverText.implicitWidth + 8) : 34)
    
    height: targetHeight
    width: targetWidth
    
    color: powerHover.containsMouse || actionsExpanded ? Theme.colError : Theme.colPrimary
    Behavior on radius { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
    Behavior on height { NumberAnimation { duration: Theme.liquidify ? 800 : 500; easing.type: Theme.liquidify ? Easing.OutElastic : (powerPill.actionsExpanded ? Easing.OutBack : Easing.InOutCubic); easing.amplitude: 1.0; easing.period: 0.85; easing.overshoot: 1.5 } }
    Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 500; easing.type: Theme.liquidify ? Easing.OutElastic : (powerPill.actionsExpanded ? Easing.OutBack : Easing.InOutCubic); easing.amplitude: 1.0; easing.period: 0.85; easing.overshoot: 1.5 } }
    Behavior on color { ColorAnimation { duration: 300 } }
    clip: true
    
    function executeAction(action) {
        powerPill.confirmingDefault = false;
        globalState.powerMenuOpen = false;
        if (action === "shutdown") Quickshell.execDetached(["bash", "-c", "systemctl poweroff"]);
        else if (action === "reboot") Quickshell.execDetached(["bash", "-c", "systemctl reboot"]);
        else if (action === "logout") Quickshell.execDetached(["bash", "-c", "loginctl kill-session $XDG_SESSION_ID"]);
        else if (action === "sleep") Quickshell.execDetached(["bash", "-c", "systemctl suspend"]);
    }
    
    function triggerAction(action) {
        powerPill.pendingAction = action;
        powerPill.confirmingDefault = true;
    }
    
    // Stored click-time coordinates for the flying icon animation
    property real heroStartX: 0
    property real heroStartY: 0
    
    function launchHeroFrom(iconRect) {
        var startPos = iconRect.mapToItem(statesContainer, 0, 0);
        var centerPos = confirmIconPlaceholder.mapToItem(statesContainer,
            confirmIconPlaceholder.width / 2,
            confirmIconPlaceholder.height / 2);
        heroIcon.x = startPos.x;
        heroIcon.y = startPos.y;
        heroIcon.width = 32;
        heroIcon.height = 32;
        heroIcon.radius = 16;
        heroIcon.opacity = 1;
        heroXAnim.from = startPos.x;
        heroXAnim.to = centerPos.x - 12 - 24;
        heroYAnim.from = startPos.y;
        heroYAnim.to = centerPos.y - 24;
        heroWAnim.from = 32;
        heroWAnim.to = 48;
        heroHAnim.from = 32;
        heroHAnim.to = 48;
        heroRAnim.from = 16;
        heroRAnim.to = 24;
        heroXAnim.restart();
        heroYAnim.restart();
        heroWAnim.restart();
        heroHAnim.restart();
        heroRAnim.restart();
    }
    
    function getActionLabel(action) {
        if (action === "sleep") return "Sleep now?";
        if (action === "logout") return "Logout now?";
        if (action === "reboot") return "Reboot now?";
        if (action === "shutdown") return "Shutdown now?";
        return "";
    }
    
    function getActionIcon(action) {
        if (action === "sleep") return "\ueaf8";
        if (action === "logout") return "\ueba8";
        if (action === "reboot") return "\ueb13";
        if (action === "shutdown") return "\ueb0d";
        return "";
    }
    
    function getActionSub(action) {
        if (action === "sleep") return "The screen will lock and go dark.";
        if (action === "logout") return "You will be signed out of this session.";
        if (action === "reboot") return "The system will restart shortly.";
        if (action === "shutdown") return "Unsaved work will be lost.";
        return "";
    }
    
    MouseArea {
        id: powerHover
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: {
            if (!powerPill.confirmingDefault) {
                globalState.powerMenuOpen = !globalState.powerMenuOpen;
            }
        }
    }
    
    Item {
        id: innerContent
        anchors.fill: parent
        opacity: (powerPill.actionsExpanded) ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        
        Row {
            id: powerRow
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            layoutDirection: Qt.RightToLeft
            spacing: 14
            
            Rectangle {
                visible: powerPill.actionsExpanded
                width: powerPill.actionsExpanded ? state2Column.implicitWidth : 0
                height: powerPill.actionsExpanded ? state2Column.implicitHeight : 0
                color: "transparent"
                anchors.verticalCenter: parent.verticalCenter
                clip: true
                
                Item {
                    id: statesContainer
                    width: powerPill.actionsExpanded ? state2Column.implicitWidth : 0
                    height: powerPill.actionsExpanded ? state2Column.implicitHeight : 0
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: powerPill.actionsExpanded
                    clip: true
                    Behavior on height { NumberAnimation { duration: Theme.liquidify ? 800 : 500; easing.type: Theme.liquidify ? Easing.OutElastic : (powerPill.actionsExpanded ? Easing.OutBack : Easing.InOutCubic); easing.amplitude: 1.0; easing.period: 0.85; easing.overshoot: 1.5 } }
                    Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 500; easing.type: Theme.liquidify ? Easing.OutElastic : (powerPill.actionsExpanded ? Easing.OutBack : Easing.InOutCubic); easing.amplitude: 1.0; easing.period: 0.85; easing.overshoot: 1.5 } }
                    
                    Rectangle {
                        id: heroIcon
                        width: 32; height: 32; radius: width / 2
                        color: "#ffffff"
                        z: 10
                        opacity: 0
                        visible: opacity > 0
                        
                        NumberAnimation on x { id: heroXAnim; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.1; running: false }
                        NumberAnimation on y { id: heroYAnim; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.1; running: false }
                        NumberAnimation on width  { id: heroWAnim; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.1; running: false }
                        NumberAnimation on height { id: heroHAnim; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.1; running: false }
                        NumberAnimation on radius { id: heroRAnim; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.1; running: false }
                        
                        Connections {
                            target: powerPill
                            function onConfirmingDefaultChanged() {
                                if (!powerPill.confirmingDefault) {
                                    heroIcon.opacity = 0;
                                }
                            }
                        }
                        
                        Text { 
                            text: powerPill.getActionIcon(powerPill.pendingAction)
                            color: "#5a2432"
                            font.family: fontName
                            font.pixelSize: parent.width * 0.5
                            anchors.centerIn: parent
                        }
                    }
                    
                    Column {
                        id: state2Column
                        spacing: 6
                        width: 196
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: !powerPill.confirmingDefault ? 0 : -12
                        opacity: !powerPill.confirmingDefault ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                        Behavior on anchors.leftMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                        Rectangle {
                            width: parent.width; height: 42; radius: 21
                            color: Qt.rgba(255, 255, 255, sleepArea.containsMouse || (powerPill.focus && powerPill.selectedIndex === 0) ? 0.62 : 0.38)
                            border.width: (powerPill.focus && powerPill.keyboardNavigating && powerPill.selectedIndex === 0) ? 2 : 0
                            border.color: Theme.isDark ? "#5a2432" : "#ffffff"
                            Row {
                                anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
                                spacing: 10
                                Rectangle {
                                    id: sleepIconRect
                                    width: 32; height: 32; radius: 16
                                    color: "#ffffff"
                                    opacity: (powerPill.confirmingDefault && powerPill.pendingAction === "sleep") ? 0 : 1
                                    Text { text: "\ueaf8"; color: "#5a2432"; font.family: fontName; font.pixelSize: 15; anchors.fill: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                }
                                Text { text: "Sleep"; color: Theme.isDark ? "#5a2432" : "#ffffff"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600; anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea { 
                                id: sleepArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onPositionChanged: { powerPill.keyboardNavigating = false; }
                                onClicked: { 
                                    mouse.accepted = true
                                    powerPill.pendingAction = "sleep"
                                    powerPill.launchHeroFrom(sleepIconRect)
                                    powerPill.confirmingDefault = true
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width; height: 42; radius: 21
                            color: Qt.rgba(255, 255, 255, logoutArea.containsMouse || (powerPill.focus && powerPill.selectedIndex === 1) ? 0.62 : 0.38)
                            border.width: (powerPill.focus && powerPill.keyboardNavigating && powerPill.selectedIndex === 1) ? 2 : 0
                            border.color: Theme.isDark ? "#5a2432" : "#ffffff"
                            Row {
                                anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
                                spacing: 10
                                Rectangle {
                                    id: logoutIconRect
                                    width: 32; height: 32; radius: 16
                                    color: "#ffffff"
                                    opacity: (powerPill.confirmingDefault && powerPill.pendingAction === "logout") ? 0 : 1
                                    Text { text: "\ueba8"; color: "#5a2432"; font.family: fontName; font.pixelSize: 15; anchors.fill: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                }
                                Text { text: "Logout"; color: Theme.isDark ? "#5a2432" : "#ffffff"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600; anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea { 
                                id: logoutArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onPositionChanged: { powerPill.keyboardNavigating = false; }
                                onClicked: { 
                                    mouse.accepted = true
                                    powerPill.pendingAction = "logout"
                                    powerPill.launchHeroFrom(logoutIconRect)
                                    powerPill.confirmingDefault = true
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width; height: 42; radius: 21
                            color: Qt.rgba(255, 255, 255, rebootArea.containsMouse || (powerPill.focus && powerPill.selectedIndex === 2) ? 0.62 : 0.38)
                            border.width: (powerPill.focus && powerPill.keyboardNavigating && powerPill.selectedIndex === 2) ? 2 : 0
                            border.color: Theme.isDark ? "#5a2432" : "#ffffff"
                            Row {
                                anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
                                spacing: 10
                                Rectangle {
                                    id: rebootIconRect
                                    width: 32; height: 32; radius: 16
                                    color: "#ffffff"
                                    opacity: (powerPill.confirmingDefault && powerPill.pendingAction === "reboot") ? 0 : 1
                                    Text { text: "\ueb13"; color: "#5a2432"; font.family: fontName; font.pixelSize: 15; anchors.fill: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                }
                                Text { text: "Reboot"; color: Theme.isDark ? "#5a2432" : "#ffffff"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600; anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea { 
                                id: rebootArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onPositionChanged: { powerPill.keyboardNavigating = false; }
                                onClicked: { 
                                    mouse.accepted = true
                                    powerPill.pendingAction = "reboot"
                                    powerPill.launchHeroFrom(rebootIconRect)
                                    powerPill.confirmingDefault = true
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width; height: 42; radius: 21
                            color: Qt.rgba(255, 255, 255, shutdownArea.containsMouse || (powerPill.focus && powerPill.selectedIndex === 3) ? 0.62 : 0.38)
                            border.width: (powerPill.focus && powerPill.keyboardNavigating && powerPill.selectedIndex === 3) ? 2 : 0
                            border.color: Theme.isDark ? "#5a2432" : "#ffffff"
                            Row {
                                anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
                                spacing: 10
                                Rectangle {
                                    id: shutdownIconRect
                                    width: 32; height: 32; radius: 16
                                    color: "#ffffff"
                                    opacity: (powerPill.confirmingDefault && powerPill.pendingAction === "shutdown") ? 0 : 1
                                    Text { text: "\ueb0d"; color: "#5a2432"; font.family: fontName; font.pixelSize: 15; anchors.fill: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                }
                                Text { text: "Shutdown"; color: Theme.isDark ? "#5a2432" : "#ffffff"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600; anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea { 
                                id: shutdownArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onPositionChanged: { powerPill.keyboardNavigating = false; }
                                onClicked: { 
                                    mouse.accepted = true
                                    powerPill.pendingAction = "shutdown"
                                    powerPill.launchHeroFrom(shutdownIconRect)
                                    powerPill.confirmingDefault = true
                                }
                            }
                        }
                    }
                    
                    Item {
                        id: state3Column
                        width: 196
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.leftMargin: powerPill.confirmingDefault ? 0 : 12
                        opacity: powerPill.confirmingDefault ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                        Behavior on anchors.leftMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        
                        Item {
                            anchors.top: parent.top
                            anchors.bottom: buttonsRow.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            
                            Column {
                                anchors.centerIn: parent
                                width: parent.width
                                spacing: 8
                                
                                Item {
                                    id: confirmIconPlaceholder
                                    width: 48; height: 48
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                
                                Column {
                                    width: parent.width
                                    spacing: 2
                                    Text { width: parent.width; text: powerPill.getActionLabel(powerPill.pendingAction); color: Theme.isDark ? "#5a2432" : "#ffffff"; font.family: Theme.defaultFontFamily; font.pixelSize: 14; font.weight: 700; horizontalAlignment: Text.AlignHCenter }
                                    Text { width: parent.width; text: powerPill.getActionSub(powerPill.pendingAction); color: Theme.isDark ? "#5a2432" : "#ffffff"; opacity: 0.6; font.family: Theme.defaultFontFamily; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter }
                                }
                            }
                        }
                        
                        Row {
                            id: buttonsRow
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 8
                            width: parent.width
                            spacing: 6
                            
                            Rectangle {
                                width: (parent.width - 6) / 2; height: 32; radius: 16
                                color: Qt.rgba(255, 255, 255, nopeArea.containsMouse || (powerPill.focus && powerPill.confirmIndex === 0) ? 0.62 : 0.4)
                                border.width: (powerPill.focus && powerPill.keyboardNavigating && powerPill.confirmIndex === 0) ? 2 : 0
                                border.color: Theme.isDark ? "#5a2432" : "#ffffff"
                                Text { text: "Cancel"; color: Theme.isDark ? "#5a2432" : "#ffffff"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: 700; anchors.centerIn: parent }
                                MouseArea { id: nopeArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onPositionChanged: { powerPill.keyboardNavigating = false; } onClicked: { mouse.accepted = true; powerPill.confirmingDefault = false; } }
                            }
                            
                            Rectangle {
                                width: (parent.width - 6) / 2; height: 32; radius: 16
                                color: sureArea.containsMouse || (powerPill.focus && powerPill.confirmIndex === 1) ? "#6c2b3c" : "#5a2432"
                                border.width: (powerPill.focus && powerPill.keyboardNavigating && powerPill.confirmIndex === 1) ? 2 : 0
                                border.color: "#fbdfe4"
                                Text { text: "Confirm"; color: "#fbdfe4"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: 700; anchors.centerIn: parent }
                                MouseArea { id: sureArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onPositionChanged: { powerPill.keyboardNavigating = false; } onClicked: { mouse.accepted = true; powerPill.executeAction(powerPill.pendingAction); } }
                            }
                        }
                    }
                }
            }
        }
    }
    
    Row {
        anchors.right: parent.right
        anchors.rightMargin: (34 - powerIconText.implicitWidth) / 2
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        opacity: (!powerPill.actionsExpanded && !powerPill.confirmingDefault) ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        
        Text {
            id: powerHoverText
            text: "Power"
            color: Theme.colOnPrimary
            font.family: Theme.defaultFontFamily
            font.weight: 600
            font.pixelSize: Theme.defaultFontSize
            clip: true
            width: powerHover.containsMouse ? implicitWidth : 0
            Behavior on width { NumberAnimation { duration: Theme.liquidify ? 800 : 500; easing.type: Theme.liquidify ? Easing.OutElastic : ((powerHover.containsMouse || powerPill.actionsExpanded) ? Easing.OutBack : Easing.InOutCubic); easing.amplitude: 1.0; easing.period: 0.85; easing.overshoot: 1.5 } }
            anchors.verticalCenter: parent.verticalCenter
        }
        
        Text {
            id: powerIconText
            text: "\ueb0d"
            color: bg
            font.family: fontName
            font.weight: Theme.defaultFontWeight
            font.pixelSize: Theme.defaultFontSize
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
