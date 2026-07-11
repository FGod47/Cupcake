import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import "../common"
import "../settings"

PanelWindow {
    id: notifPanel
    anchors {
        top: true
        right: true
    }
    
    margins {
        top: 58
        right: 0
    }
    implicitWidth: 380
    implicitHeight: (screen ? screen.height : 1080) - 70
    color: "transparent"
    
    visible: globalState.notifPanelVisible || panelBg.x < 380
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell:notifpanel"
    
    // Exact colors matching the screenshot (Catppuccin Mocha themed)
    property color bgBase: Theme.colBackground
    property color bgMantle: Qt.rgba(Theme.colSurfaceContainer.r, Theme.colSurfaceContainer.g, Theme.colSurfaceContainer.b, 0.60)
    property color bgSurface0: Qt.rgba(Theme.colSurfaceContainerHigh.r, Theme.colSurfaceContainerHigh.g, Theme.colSurfaceContainerHigh.b, 0.45)
    property color bgSurface1: Theme.colSurfaceVariant
    property color textText: Theme.colOnSurface
    property color textSubtext0: Theme.colOnSurfaceVariant
    property color textSubtext1: Theme.colOnSurfaceVariant
    property color colGreen: Theme.colPrimary
    property color colGreenDim: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.20)
    
    property string uptimeStr: "Up 0m"
    
    // Network toggle state
    property bool wifiActive: false
    property string wifiSSID: "Disconnected"
    
    // Bluetooth toggle state
    property bool btActive: false
    property string btDevice: "Not connected"
    
    // EasyEffects toggle state
    property bool eeActive: false
    property string eeStatus: "Inactive"

    Item {
        anchors.fill: parent
        clip: false
        
        Rectangle {
            id: panelBg
            width: 360
            height: parent.height
            
            color: Qt.rgba(Theme.colBackground.r, Theme.colBackground.g, Theme.colBackground.b, globalState.notifPanelOpacity)
            radius: 24
            clip: true

            states: [
                State {
                    name: "open"
                    when: globalState.notifPanelVisible
                    PropertyChanges { target: panelBg; x: 8 }
                },
                State {
                    name: "closed"
                    when: !globalState.notifPanelVisible
                    PropertyChanges { target: panelBg; x: 380 }
                }
            ]
            
            transitions: [
                Transition {
                    from: "closed"; to: "open"
                    NumberAnimation { properties: "x"; duration: 400; easing.type: Easing.OutExpo }
                },
                Transition {
                    from: "open"; to: "closed"
                    NumberAnimation { properties: "x"; duration: 400; easing.type: Easing.OutExpo }
                }
            ]
            
            ColumnLayout {
                id: mainLayout
                width: 332
                height: parent.height - 28
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.top: parent.top
                anchors.topMargin: 14
                spacing: 14
                    

                    // 2. Notifications Section (Middle Card)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: notifLayout.implicitHeight + 28
                        color: bgMantle
                        radius: 20
                        
                        ColumnLayout {
                            id: notifLayout
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 16
                            
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "\uea35  " + (globalState.notifications ? Object.keys(globalState.notifications.values).length : 0) + " notifications"
                                    font.family: "tabler-icons, " + Theme.defaultFontFamily
                                    color: textSubtext0
                                    font.pixelSize: 13
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: "\ueb6b"
                                    font.family: "tabler-icons"
                                    color: textSubtext0
                                    font.pixelSize: 16
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (globalState.notifications) {
                                                var arr = globalState.notifications.values;
                                                for (var i = arr.length - 1; i >= 0; i--) {
                                                    arr[i].dismiss();
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            ListView {
                                id: notifList
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                implicitHeight: count > 0 ? Math.min(contentHeight, 350) : 60
                                clip: true
                                spacing: 10
                                interactive: contentHeight > height
                                model: globalState.notifications || null
                                
                                add: Transition {
                                    NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: 250; easing.type: Easing.OutQuad }
                                    NumberAnimation { property: "scale"; from: 0.85; to: 1.0; duration: 250; easing.type: Easing.OutQuad }
                                }
                                
                                remove: Transition {
                                    ParallelAnimation {
                                        NumberAnimation { property: "opacity"; to: 0.0; duration: 200; easing.type: Easing.OutQuad }
                                        NumberAnimation { property: "scale"; to: 0.85; duration: 200; easing.type: Easing.OutQuad }
                                    }
                                }
                                
                                displaced: Transition {
                                    NumberAnimation { properties: "y"; duration: 250; easing.type: Easing.OutQuad }
                                }
                                
                                delegate: NotificationCard {
                                    width: notifList.width
                                    notificationData: modelData
                                    inPanel: true
                                }
                                
                                Item {
                                    width: parent.width; height: 60; visible: notifList.count === 0
                                    Text { anchors.centerIn: parent; text: "No new notifications"; color: textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 13 }
                                }
                            }
                        }
                    }
                    
                    // 3. Calendar Section (Bottom Card)
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: calLayout.implicitHeight + 28
                        color: bgMantle
                        radius: 20
                        
                        ColumnLayout {
                            id: calLayout
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 16
                            
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: Qt.formatDateTime(calGrid.currentDate, "MMMM yyyy")
                                    font.family: Theme.defaultFontFamily
                                    color: textText
                                    font.pixelSize: 14
                                    font.weight: 700
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: "\uea60"
                                    font.family: "tabler-icons"
                                    color: textSubtext0
                                    font.pixelSize: 16
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let prevMonth = calGrid.month - 1;
                                            let prevYear = calGrid.year;
                                            if (prevMonth < 0) { prevMonth = 11; prevYear--; }
                                            calGrid.currentDate = new Date(prevYear, prevMonth, 1);
                                        }
                                    }
                                }
                                Text {
                                    text: "\uea61"
                                    font.family: "tabler-icons"
                                    color: textSubtext0
                                    font.pixelSize: 16
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let nextMonth = calGrid.month + 1;
                                            let nextYear = calGrid.year;
                                            if (nextMonth > 11) { nextMonth = 0; nextYear++; }
                                            calGrid.currentDate = new Date(nextYear, nextMonth, 1);
                                        }
                                    }
                                }
                            }
                            
                            GridLayout {
                                id: calGrid
                                Layout.fillWidth: true
                                columns: 7
                                rowSpacing: 8
                                columnSpacing: 4
                                
                                property date currentDate: new Date()
                                property int year: currentDate.getFullYear()
                                property int month: currentDate.getMonth()
                                property int today: currentDate.getDate()
                                
                                function daysInMonth(y, m) { return new Date(y, m + 1, 0).getDate(); }
                                function startDayOfWeek(y, m) {
                                    let day = new Date(y, m, 1).getDay();
                                    return day === 0 ? 6 : day - 1;
                                }
                                
                                property int totalDays: daysInMonth(year, month)
                                property int startOffset: startDayOfWeek(year, month)
                                
                                Repeater {
                                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                                    Text {
                                        text: modelData
                                        color: textSubtext0
                                        font.family: Theme.defaultFontFamily
                                        font.pixelSize: 11
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                                
                                Repeater {
                                    model: calGrid.startOffset
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 28
                                    }
                                }
                                
                                Repeater {
                                    model: calGrid.totalDays
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 28
                                        
                                        Rectangle {
                                            width: 28; height: 28; radius: 14
                                            anchors.centerIn: parent
                                            property bool isToday: (index + 1) === calGrid.today && calGrid.year === new Date().getFullYear() && calGrid.month === new Date().getMonth()
                                            color: isToday ? colGreen : "transparent"
                                            
                                            Text {
                                                text: index + 1
                                                color: parent.isToday ? bgBase : textSubtext1
                                                font.family: Theme.defaultFontFamily; font.pixelSize: 12
                                                anchors.centerIn: parent
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

    Connections {
        target: globalState
        function onNotifPanelVisibleChanged() {
            if (globalState.notifPanelVisible) {
                postOpenUpdateTimer.restart()
            } else {
                postOpenUpdateTimer.stop()
            }
        }
    }



    Timer {
        id: postOpenUpdateTimer
        interval: 400 // trigger CPU-heavy updates only after 350ms slide animation finishes
        repeat: false
        onTriggered: {
            updateUptime.running = true
            updateToggles.running = true
        }
    }

    Component.onCompleted: {
        updateUptime.running = true
        updateToggles.running = true
    }

    // Refresh toggles and uptime every 10s
    Timer {
        id: slowTimer
        interval: 10000
        running: globalState.notifPanelVisible
        repeat: true
        onTriggered: {
            updateUptime.running = true
            updateToggles.running = true
        }
    }

    Process {
        id: updateUptime
        command: ["uptime", "-p"]
        stdout: StdioCollector { id: uptimeStdout }
        onExited: {
            let clean = (uptimeStdout.text || "").trim();
            clean = clean.replace("up ", "");
            clean = clean.replace(" hours", "h").replace(" hour", "h");
            clean = clean.replace(" minutes", "m").replace(" minute", "m");
            clean = clean.replace(",", "");
            uptimeStr = "Up " + clean;
        }
    }

    Process {
        id: updateToggles
        command: ["bash", "-c", "nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes'; bluetoothctl show | grep 'Powered:'; pgrep easyeffects"]
        stdout: StdioCollector { id: togglesStdout }
        onExited: {
            console.log("updateToggles stdout text: '" + togglesStdout.text + "'");
            let lines = (togglesStdout.text || "").split("\n");
            
            // Check wifi
            wifiActive = false;
            wifiSSID = "Disconnected";
            for (let i=0; i<lines.length; i++) {
                if (lines[i].startsWith("yes:")) {
                    wifiActive = true;
                    wifiSSID = lines[i].split(":")[1] || "Connected";
                    break;
                }
            }
            console.log("wifiActive:", wifiActive, "wifiSSID:", wifiSSID, "colGreen:", colGreen);
            
            // Check bluetooth
            btActive = false;
            btDevice = "Not connected";
            for (let i=0; i<lines.length; i++) {
                if (lines[i].includes("Powered: yes")) {
                    btActive = true;
                    btDevice = "Enabled";
                    break;
                }
            }
            
            // Check easyeffects
            eeActive = false;
            eeStatus = "Inactive";
            for (let i=0; i<lines.length; i++) {
                if (lines[i].trim() !== "" && !isNaN(parseInt(lines[i])) && !lines[i].includes("Powered") && !lines[i].includes("yes:")) {
                    eeActive = true;
                    eeStatus = "Active";
                    break;
                }
            }
        }
    }
}
