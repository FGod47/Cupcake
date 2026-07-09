import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import Quickshell
import Quickshell.Io
import "../common"

Item {
    id: root

    property bool btExpanded: true
    property bool btRadioEnabled: false

    // =====================================================================
    // Reusable inline components
    // =====================================================================

    component SettingsCard: Rectangle {
        default property alias content: innerCol.data
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        implicitHeight: innerCol.implicitHeight + 40
        Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
        radius: 12
        clip: true
        ColumnLayout {
            id: innerCol
            anchors.fill: parent
            anchors.margins: 20
            spacing: 8
        }
    }

    component SectionLabel: Text {
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 0.4
        color: Theme.colOnSurface
        opacity: 0.45
    }

    component ToggleSwitch: Rectangle {
        id: sw
        property bool checked: false
        signal toggled(bool checked)
        width: 38; height: 22
        radius: height / 2
        color: checked ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.15)
        border.width: checked ? 0 : 1
        border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.1)
        Behavior on color { ColorAnimation { duration: 120 } }
        Rectangle {
            width: 18; height: 18; radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: sw.checked ? parent.width - width - 2 : 2
            color: sw.checked ? Theme.colSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.8)
            Behavior on x { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: { sw.checked = !sw.checked; sw.toggled(sw.checked) }
        }
    }

    component SettingsRow: RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        spacing: 12
    }

    // =====================================================================
    // Background data
    // =====================================================================

    ListModel { id: btModel }

    Process {
        id: btProcess
        command: ["python3", "/home/code/.config/quickshell/modules/settings/bt_status.py"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.btRadioEnabled = data.powered;
                    
                    if (data.powered) {
                        let newDevices = data.devices || [];
                        btModel.clear();
                        for (let i = 0; i < newDevices.length; i++) {
                            btModel.append(newDevices[i]);
                        }
                    } else {
                        btModel.clear();
                    }
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 5000
        running: root.visible
        repeat: true
        onTriggered: {
            btProcess.running = true;
        }
    }

    // =====================================================================
    // UI
    // =====================================================================

    ScrollView {
        anchors.fill: parent
        anchors.topMargin: 0
        anchors.bottomMargin: 30
        anchors.leftMargin: 0
        anchors.rightMargin: 24
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 24

            SettingsCard {
                SectionLabel { text: "Bluetooth" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\uea37"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Bluetooth"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Manage paired and nearby devices"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    
                    // Rescan button
                    Rectangle {
                        visible: root.btRadioEnabled
                        width: 32; height: 32; radius: 8
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                        Text { anchors.centerIn: parent; text: "\ueb13"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 15 }
                        MouseArea { 
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; 
                            onClicked: { Quickshell.execDetached(["bluetoothctl", "--timeout", "10", "scan", "on"]); btProcess.running = true; } 
                        }
                    }

                    ToggleSwitch {
                        checked: root.btRadioEnabled
                        onToggled: Quickshell.execDetached(["bash", "-c", "bluetoothctl power " + (checked ? "on" : "off")])
                    }
                }

                Repeater {
                    visible: root.btExpanded
                    model: btModel
                    delegate: SettingsRow {
                        RowLayout {
                            spacing: 12
                            Rectangle {
                                width: 32; height: 32; radius: 16
                                color: model.connected ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                                Text { anchors.centerIn: parent; text: "\uea37"; color: model.connected ? Theme.colPrimary : Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                            }
                            ColumnLayout {
                                spacing: 1
                                Text { text: model.name; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                                Text { text: model.connected ? "Connected" : (model.paired ? "Paired" : "Available"); color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                            }
                        }
                        Item { Layout.fillWidth: true }
                        
                        // Status Badge / Action Button
                        Rectangle {
                            width: model.connected ? 74 : (model.paired ? 52 : 44)
                            height: 24; radius: 6
                            color: model.connected ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.07)
                            Text { 
                                anchors.centerIn: parent
                                text: model.connected ? "Connected" : (model.paired ? "Paired" : "Pair")
                                color: model.connected ? Theme.colPrimary : Theme.colOnSurfaceVariant
                                font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Medium 
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (model.connected) {
                                        Quickshell.execDetached(["bluetoothctl", "disconnect", model.mac]);
                                    } else {
                                        Quickshell.execDetached(["bluetoothctl", "connect", model.mac]);
                                    }
                                    btProcess.running = true;
                                }
                            }
                        }
                        
                        Text { 
                            text: "\ueb41"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 14; opacity: 0.35 
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached(["bluetoothctl", "remove", model.mac]);
                                    btProcess.running = true;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
