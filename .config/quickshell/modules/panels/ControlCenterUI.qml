import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../theme"
import "../common"

Item {
    id: ccUi
    width: 362
    height: 330

    signal requestClose()

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
    property bool wifiActive: false
    property string wifiSSID: "Disconnected"
    property bool btActive: false
    property string btDevice: "Not connected"
    property bool eeActive: false
    property string eeStatus: "Inactive"

    Rectangle {
        id: controlsCard
        anchors.fill: parent
        color: bgMantle
        radius: 20
        border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.2)
        border.width: 1

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

                    // Settings Launcher
                    Text {
                        text: "\ueb20"
                        font.family: "tabler-icons"
                        color: textSubtext0
                        font.pixelSize: 16
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached("quickshell -p ~/.config/quickshell/Settings.qml")
                                ccUi.requestClose()
                            }
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
                    color: wifiActive ? colGreenDim : bgSurface0
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
                    color: btActive ? colGreenDim : bgSurface0
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
                    color: eeActive ? colGreenDim : bgSurface0
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

    Timer {
        id: slowTimer
        interval: 10000
        running: ccUi.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            updateUptime.running = true
            updateToggles.running = true
        }
    }

    Timer {
        id: fastTimer
        interval: 3000
        running: ccUi.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            updateVolume.running = true
            updateBrightness.running = true
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

            wifiActive = false;
            wifiSSID = "Disconnected";
            for (let i=0; i<lines.length; i++) {
                if (lines[i].startsWith("yes:")) {
                    wifiActive = true;
                    wifiSSID = lines[i].split(":")[1] || "Connected";
                    break;
                }
            }

            btActive = false;
            btDevice = "Not connected";
            for (let i=0; i<lines.length; i++) {
                if (lines[i].includes("Powered: yes")) {
                    btActive = true;
                    btDevice = "Enabled";
                    break;
                }
            }

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
