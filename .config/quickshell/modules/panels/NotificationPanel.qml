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
        top: 12
        right: 12
    }
    implicitWidth: 360
    implicitHeight: Math.min(mainLayout.implicitHeight + 28, (screen ? screen.height : 1080) - 24)
    color: "transparent"
    
    visible: globalState.notifPanelVisible || panelBg.width > 0
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notifpanel"
    
    // Exact colors matching the screenshot (Catppuccin Mocha themed)
    property color bgBase: "#11111b"       // crust
    property color bgMantle: Qt.rgba(0.094, 0.094, 0.145, 0.60)     // mantle (semi-transparent)
    property color bgSurface0: Qt.rgba(0.118, 0.118, 0.180, 0.45)   // base (semi-transparent)
    property color bgSurface1: "#313244"   // surface0
    property color textText: "#cdd6f4"     // text
    property color textSubtext0: "#a6adc8"   // subtext0
    property color textSubtext1: "#bac2de"   // subtext1
    property color colGreen: "#a6e3a1"     // green
    property color colGreenDim: "#2e3d30"  // dark green background for active status
    
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
        clip: true
        
        Rectangle {
            id: panelBg
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            
            states: [
                State {
                    name: "open"
                    when: globalState.notifPanelVisible
                    PropertyChanges { target: panelBg; width: 360; height: parent.height }
                },
                State {
                    name: "closed"
                    when: !globalState.notifPanelVisible
                    PropertyChanges { target: panelBg; width: 0; height: parent.height * 0.8 }
                }
            ]
            
            transitions: [
                Transition {
                    from: "closed"; to: "open"
                    NumberAnimation { properties: "width,height"; duration: 400; easing.type: Easing.OutExpo }
                },
                Transition {
                    from: "open"; to: "closed"
                    NumberAnimation { properties: "width,height"; duration: 300; easing.type: Easing.InExpo }
                }
            ]
            
            color: Qt.rgba(0.067, 0.067, 0.106, globalState.notifPanelOpacity)
            radius: 24
            border.color: "#313244"
            border.width: 1
            clip: true
            
            ColumnLayout {
                id: mainLayout
                width: 332
                height: parent.height - 28
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.top: parent.top
                anchors.topMargin: 14
                spacing: 14
                    
                    // 1. Controls Section (Top Card)
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: controlsLayout.implicitHeight + 28
                        color: bgMantle
                        radius: 20
                        
                        ColumnLayout {
                            id: controlsLayout
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 16
                            
                            // Header Row
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "\uea70  " + uptimeStr
                                    font.family: "tabler-icons, " + Theme.defaultFontFamily
                                    color: textSubtext0
                                    font.pixelSize: 13
                                    Layout.fillWidth: true
                                }
                                
                                Row {
                                    spacing: 16
                                    
                                    // Edit
                                    Text {
                                        text: "\uea8c"
                                        font.family: "tabler-icons"
                                        color: textSubtext0
                                        font.pixelSize: 16
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: Quickshell.execDetached("antigravity-ide")
                                        }
                                    }
                                    
                                    // Refresh
                                    Text {
                                        text: "\ueb13"
                                        font.family: "tabler-icons"
                                        color: textSubtext0
                                        font.pixelSize: 16
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: Quickshell.execDetached("quickshell -c cupcake --replace")
                                        }
                                    }
                                    
                                    // Settings
                                    Text {
                                        text: "\ueb20"
                                        font.family: "tabler-icons"
                                        color: textSubtext0
                                        font.pixelSize: 16
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: Quickshell.execDetached("quickshell -p ~/.config/quickshell/Settings.qml")
                                        }
                                    }
                                    
                                    // Power
                                    Text {
                                        text: "\ueb0d"
                                        font.family: "tabler-icons"
                                        color: textSubtext0
                                        font.pixelSize: 16
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: Quickshell.execDetached("quickshell -p ~/.config/quickshell/PowerMenu.qml")
                                        }
                                    }
                                }
                            }
                            
                            // Sliders Row
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                
                                // Brightness Slider
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Text { text: "\uec4e"; font.family: "tabler-icons"; color: textSubtext0; font.pixelSize: 16 }
                                    Slider {
                                        id: backlightSlider
                                        Layout.fillWidth: true
                                        from: 0; to: 100; value: 69
                                        
                                        background: Rectangle {
                                            x: backlightSlider.leftPadding
                                            y: backlightSlider.topPadding + backlightSlider.availableHeight / 2 - height / 2
                                            width: backlightSlider.availableWidth
                                            height: 5
                                            radius: 2.5
                                            color: bgSurface1
                                            Rectangle {
                                                width: backlightSlider.visualPosition * parent.width
                                                height: parent.height
                                                color: colGreen
                                                radius: 2.5
                                            }
                                        }
                                        handle: Rectangle {
                                            x: backlightSlider.leftPadding + backlightSlider.visualPosition * (backlightSlider.availableWidth - width)
                                            y: backlightSlider.topPadding + backlightSlider.availableHeight / 2 - height / 2
                                            width: 14; height: 14; radius: 7
                                            color: "#ffffff"
                                        }
                                        
                                        Timer {
                                            id: ddcTimer
                                            interval: 150; repeat: false
                                            property int targetValue: 100
                                            onTriggered: Quickshell.execDetached(["ddcutil", "setvcp", "10", Math.round(targetValue).toString(), "--noverify"])
                                        }
                                        onMoved: { ddcTimer.targetValue = value; ddcTimer.restart() }
                                        onPressedChanged: { if (!pressed) { ddcTimer.stop(); Quickshell.execDetached(["ddcutil", "setvcp", "10", Math.round(value).toString()]) } }
                                    }
                                    Text { text: Math.round(backlightSlider.value) + "%"; color: textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 12; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight }
                                    Text { text: "\ueb30"; font.family: "tabler-icons"; color: textSubtext0; font.pixelSize: 16 }
                                }
                                
                                // Volume Slider
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Text { text: "\uf1c3"; font.family: "tabler-icons"; color: textSubtext0; font.pixelSize: 16 }
                                    Slider {
                                        id: volumeSlider
                                        Layout.fillWidth: true
                                        from: 0; to: 100; value: 45
                                        
                                        background: Rectangle {
                                            x: volumeSlider.leftPadding
                                            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                            width: volumeSlider.availableWidth
                                            height: 5
                                            radius: 2.5
                                            color: bgSurface1
                                            Rectangle {
                                                width: volumeSlider.visualPosition * parent.width
                                                height: parent.height
                                                color: colGreen
                                                radius: 2.5
                                            }
                                        }
                                        handle: Rectangle {
                                            x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                                            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                            width: 14; height: 14; radius: 7
                                            color: "#ffffff"
                                        }
                                        
                                        onMoved: Quickshell.execDetached(`pamixer --set-volume ${Math.round(value)}`)
                                    }
                                    Text { text: Math.round(volumeSlider.value) + "%"; color: textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 12; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight }
                                    Text { text: "\ueb51"; font.family: "tabler-icons"; color: textSubtext0; font.pixelSize: 16 }
                                }
                            }
                            
                            // Toggles Grid
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 3
                                rowSpacing: 10
                                columnSpacing: 10
                                
                                // Wi-Fi Toggle
                                Rectangle {
                                    id: wifiToggle
                                    Layout.fillWidth: true; Layout.preferredHeight: 82
                                    color: bgSurface0
                                    radius: 16
                                    border.color: wifiActive ? colGreen : bgSurface1
                                    border.width: 1
                                    
                                    Column {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.right: parent.right
                                        anchors.rightMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4
                                        Text { text: "\ueb52"; color: wifiActive ? colGreen : textSubtext0; font.family: "tabler-icons"; font.pixelSize: 16 }
                                        Text { text: "Wi-Fi"; color: textText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 700 }
                                        Text { text: wifiSSID; color: wifiActive ? colGreen : textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width }
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: Quickshell.execDetached(wifiActive ? "nmcli radio wifi off" : "nmcli radio wifi on")
                                    }
                                }
                                
                                // Bluetooth Toggle
                                Rectangle {
                                    id: btToggle
                                    Layout.fillWidth: true; Layout.preferredHeight: 82
                                    color: bgSurface0
                                    radius: 16
                                    border.color: btActive ? colGreen : bgSurface1
                                    border.width: 1
                                    
                                    Column {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.right: parent.right
                                        anchors.rightMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4
                                        Text { text: "\uea37"; color: btActive ? colGreen : textSubtext0; font.family: "tabler-icons"; font.pixelSize: 16 }
                                        Text { text: "Bluetooth"; color: textText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 700 }
                                        Text { text: btDevice; color: btActive ? colGreen : textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width }
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: Quickshell.execDetached(btActive ? "bluetoothctl power off" : "bluetoothctl power on")
                                    }
                                }
                                
                                // EasyEffects Toggle
                                Rectangle {
                                    id: eeToggle
                                    Layout.fillWidth: true; Layout.preferredHeight: 82
                                    color: bgSurface0
                                    radius: 16
                                    border.color: eeActive ? colGreen : bgSurface1
                                    border.width: 1
                                    
                                    Column {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.right: parent.right
                                        anchors.rightMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4
                                        Text { text: "\uf6d7"; color: eeActive ? colGreen : textSubtext0; font.family: "tabler-icons"; font.pixelSize: 16 }
                                        Text { text: "EasyEffects"; color: textText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 700 }
                                        Text { text: eeStatus; color: eeActive ? colGreen : textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width }
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: Quickshell.execDetached(eeActive ? "pkill easyeffects" : "easyeffects --daemon")
                                    }
                                }
                                
                                // Firewall Toggle
                                Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: 82
                                    color: bgSurface0
                                    radius: 16
                                    border.color: bgSurface1
                                    border.width: 1
                                    
                                    Column {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.right: parent.right
                                        anchors.rightMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4
                                        Text { text: "\uec2c"; color: textSubtext0; font.family: "tabler-icons"; font.pixelSize: 16 }
                                        Text { text: "Firewall"; color: textText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 700 }
                                        Text { text: "Inactive"; color: textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                                    }
                                }
                                
                                // Cast Toggle
                                Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: 82
                                    color: bgSurface0
                                    radius: 16
                                    border.color: bgSurface1
                                    border.width: 1
                                    
                                    Column {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.right: parent.right
                                        anchors.rightMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4
                                        Text { text: "\uea56"; color: textSubtext0; font.family: "tabler-icons"; font.pixelSize: 16 }
                                        Text { text: "Cast"; color: textText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 700 }
                                        Text { text: "Inactive"; color: textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                                    }
                                }
                                
                                // Anti-flash Toggle
                                Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: 82
                                    color: bgSurface0
                                    radius: 16
                                    border.color: bgSurface1
                                    border.width: 1
                                    
                                    Column {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.right: parent.right
                                        anchors.rightMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4
                                        Text { text: "\uea2e"; color: textSubtext0; font.family: "tabler-icons"; font.pixelSize: 16 }
                                        Text { text: "Anti-flash"; color: textText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 700 }
                                        Text { text: "Inactive"; color: textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                                    }
                                }
                            }
                        }
                    }
                    
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
                                model: globalState.notifications ? globalState.notifications.values : null
                                
                                delegate: Rectangle {
                                    width: notifList.width
                                    height: notifCol.height + 24
                                    color: bgSurface0
                                    radius: 16
                                    
                                    // Function to format time relatively
                                    function getRelativeTime(timeVal) {
                                        if (!timeVal) return "";
                                        let diffMs = new Date().getTime() - (timeVal / 1000);
                                        let diffMins = Math.floor(diffMs / 60000);
                                        if (diffMins < 1) return "now";
                                        if (diffMins < 60) return diffMins + "m";
                                        let diffHours = Math.floor(diffMins / 60);
                                        if (diffHours < 24) return diffHours + "h";
                                        return "Yesterday";
                                    }
                                    
                                    RowLayout {
                                        id: notifCol
                                        anchors.left: parent.left; anchors.right: parent.right
                                        anchors.top: parent.top; anchors.margins: 12
                                        spacing: 12
                                        
                                        // Green Translucent Icon Box with Dynamic Icon
                                        Rectangle {
                                            width: 36; height: 36; radius: 10
                                            color: colGreenDim
                                            Layout.alignment: Qt.AlignTop
                                            
                                            Image {
                                                id: notifIconImg
                                                anchors.fill: parent
                                                anchors.margins: 4
                                                source: modelData && modelData.appIcon
                                                    ? (modelData.appIcon.startsWith("/")
                                                        ? "file://" + modelData.appIcon
                                                        : "image://icon/" + modelData.appIcon)
                                                    : ""
                                                sourceSize: Qt.size(36, 36)
                                                fillMode: Image.PreserveAspectFit
                                                asynchronous: true
                                                visible: status === Image.Ready
                                            }
                                            Text {
                                                text: "\uea35"
                                                color: colGreen
                                                font.family: "tabler-icons"; font.pixelSize: 18
                                                anchors.centerIn: parent
                                                visible: !notifIconImg.visible
                                            }
                                        }
                                        
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 3
                                            RowLayout {
                                                Layout.fillWidth: true
                                                Text { text: modelData.summary || "Notification"; color: textText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 700; Layout.fillWidth: true }
                                                Text { text: getRelativeTime(modelData.time); color: textSubtext0; font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                                            }
                                            Text { text: modelData.body || ""; color: textSubtext1; font.family: Theme.defaultFontFamily; font.pixelSize: 12; wrapMode: Text.Wrap; Layout.fillWidth: true; maximumLineCount: 2; elide: Text.ElideRight }
                                            
                                            // Dismiss/Copy Action Row
                                            RowLayout {
                                                Layout.fillWidth: true
                                                Layout.topMargin: 4
                                                spacing: 8
                                                
                                                Rectangle {
                                                    color: bgSurface1; radius: 8; implicitHeight: 26; implicitWidth: 80
                                                    Row {
                                                        anchors.centerIn: parent; spacing: 4
                                                        Text { text: "\ueb55"; font.family: "tabler-icons"; color: textText; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                                        Text { text: "Dismiss"; color: textText; font.family: Theme.defaultFontFamily; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                                                    }
                                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: modelData.dismiss() }
                                                }
                                                
                                                Rectangle {
                                                    color: colGreenDim; radius: 8; implicitHeight: 26; implicitWidth: 60
                                                    Text { text: "Copy"; color: colGreen; font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: 700; anchors.centerIn: parent }
                                                    MouseArea {
                                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor;
                                                        onClicked: {
                                                            Quickshell.execDetached(["wl-copy", modelData.body || ""]);
                                                            modelData.dismiss();
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
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
                                    text: "\uea5f"
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

    Component.onCompleted: {
        updateVolume.running = true
        updateBrightness.running = true
        updateUptime.running = true
        updateToggles.running = true
    }

    Timer {
        id: updateTimer
        interval: 1000
        running: globalState.notifPanelVisible
        repeat: true
        onTriggered: {
            updateVolume.running = true
            updateBrightness.running = true
        }
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
        id: updateVolume
        command: ["pamixer", "--get-volume"]
        stdout: StdioCollector { id: updateVolumeStdout }
        onExited: {
            if (!volumeSlider.pressed) {
                var vol = parseInt((updateVolumeStdout.text || "").trim())
                if (!isNaN(vol)) volumeSlider.value = vol
            }
        }
    }

    Process {
        id: updateBrightness
        command: ["ddcutil", "getvcp", "10", "--terse"]
        stdout: StdioCollector { id: updateBrightnessStdout }
        onExited: {
            if (!backlightSlider.pressed) {
                let match = (updateBrightnessStdout.text || "").match(/VCP\s+10\s+[A-Za-z]+\s+(\d+)/);
                if (match && match[1]) {
                    let bright = parseInt(match[1]);
                    if (!isNaN(bright)) backlightSlider.value = bright
                }
            }
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
