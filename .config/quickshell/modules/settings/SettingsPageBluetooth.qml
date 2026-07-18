import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import Quickshell
import Quickshell.Bluetooth
import "../common"

Item {
    id: root

    property bool btExpanded: true
    property bool btRadioEnabled: Bluetooth.defaultAdapter?.enabled ?? false

    function getDeviceIcon(device) {
        let iconName = device.icon || "";
        if (iconName.includes("headset") || iconName.includes("headphones") || iconName.includes("audio"))
            return "\ueabd"; // headphones
        if (iconName.includes("phone"))
            return "\uea8a"; // mobile
        if (iconName.includes("mouse"))
            return "\ueaf9"; // mouse
        if (iconName.includes("keyboard"))
            return "\uebd6"; // keyboard
        if (iconName.includes("printer"))
            return "\ueb0e"; // printer
        return "\uea37"; // default bluetooth
    }

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
        color: Theme.showCardBackground ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03) : "transparent"
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
        id: tog
        property bool checked: false
        signal toggled(bool checked)
        width: 38; height: 22
        radius: height / 2
        color: checked ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.15)
        border.width: checked ? 0 : 1
        border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.1)
        Behavior on color { ColorAnimation { duration: 120 } }
        Rectangle {
            width: 18; height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: tog.checked ? parent.width - width - 2 : 2
            color: tog.checked ? Theme.colSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.8)
            Behavior on x { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: { tog.checked = !tog.checked; tog.toggled(tog.checked) }
        }
    }

    component SettingsRow: ColumnLayout {
        default property alias content: innerRow.data
        Layout.fillWidth: true
        Layout.topMargin: Theme.rowSpacing
        Layout.bottomMargin: Theme.rowSpacing
        spacing: 12
        RowLayout {
            id: innerRow
            Layout.fillWidth: true
            spacing: 12
        }
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
            visible: Theme.showDividers
        }
    }

    Component {
        id: deviceDelegate
        SettingsRow {
            required property BluetoothDevice modelData
            
            RowLayout {
                spacing: 12
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: modelData.connected ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text { anchors.centerIn: parent; text: root.getDeviceIcon(modelData); color: modelData.connected ? Theme.colPrimary : Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                }
                ColumnLayout {
                    spacing: 1
                    Text { text: modelData.name || "Unknown device"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    Text { 
                        text: {
                            if (!modelData.paired) return "Available";
                            let status = modelData.connected ? "Connected" : "Paired";
                            if (modelData.connected && modelData.batteryAvailable) {
                                status += " • " + Math.round(modelData.battery * 100) + "%";
                            }
                            return status;
                        }
                        color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 
                    }
                }
            }
            Item { Layout.fillWidth: true }
            
            // Status Badge / Action Button
            Rectangle {
                width: modelData.connected ? 74 : (modelData.paired ? 52 : 44)
                height: 24; radius: 6
                color: modelData.connected ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.07)
                Text { 
                    anchors.centerIn: parent
                    text: modelData.connected ? "Connected" : (modelData.paired ? "Paired" : "Pair")
                    color: modelData.connected ? Theme.colPrimary : Theme.colOnSurfaceVariant
                    font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Medium 
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.connected) {
                            modelData.disconnect();
                        } else {
                            modelData.connect();
                        }
                    }
                }
            }
            
            // Forget Button
            Rectangle {
                visible: modelData.paired
                width: 52; height: 24; radius: 6
                color: Qt.rgba(Theme.colError.r, Theme.colError.g, Theme.colError.b, 0.12)
                Text { 
                    anchors.centerIn: parent
                    text: "Forget"
                    color: Theme.colError
                    font.family: Theme.defaultFontFamily; font.pixelSize: 11; font.weight: Font.Medium 
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["bluetoothctl", "remove", modelData.address]);
                    }
                }
            }
        }
    }

    // =====================================================================
    // Background data
    // =====================================================================

    property list<var> pairedDevices: {
        let arr = Bluetooth.devices.values.filter(d => d.paired);
        arr.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            return (a.name || "").localeCompare(b.name || "");
        });
        return arr;
    }
    
    property list<var> availableDevices: {
        let arr = Bluetooth.devices.values.filter(d => !d.paired && d.name);
        arr.sort((a, b) => {
            const macRegex = /^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$/;
            const aIsMac = macRegex.test(a.name || "");
            const bIsMac = macRegex.test(b.name || "");
            if (aIsMac !== bIsMac) return aIsMac ? 1 : -1;
            return (a.name || "").localeCompare(b.name || "");
        });
        return arr;
    }

    // =====================================================================
    // UI
    // =====================================================================

    ScrollView {
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        anchors.fill: parent
        anchors.bottomMargin: 28
        anchors.rightMargin: 24
        leftPadding: 32
        rightPadding: 32
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 20

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
                            Text { text: "Bluetooth"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Manage paired and nearby devices"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    
                    // Rescan button
                    Rectangle {
                        visible: root.btRadioEnabled
                        width: 32; height: 32; radius: 8
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                        Text { 
                            id: scanIcon
                            anchors.centerIn: parent
                            text: "\ueb13"
                            color: Bluetooth.defaultAdapter?.discovering ? Theme.colPrimary : Theme.colOnSurfaceVariant
                            font.family: "tabler-icons"; font.pixelSize: 15
                            
                            RotationAnimation on rotation {
                                loops: Animation.Infinite
                                from: 0; to: 360
                                duration: 1000
                                running: Bluetooth.defaultAdapter?.discovering ?? false
                            }
                        }
                        MouseArea { 
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; 
                            onClicked: { 
                                if (Bluetooth.defaultAdapter) {
                                    Bluetooth.defaultAdapter.discovering = !Bluetooth.defaultAdapter.discovering;
                                }
                            } 
                        }
                    }

                    ToggleSwitch {
                        checked: root.btRadioEnabled
                        onToggled: {
                            if (Bluetooth.defaultAdapter) {
                                Bluetooth.defaultAdapter.enabled = checked;
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true; height: 8; visible: root.btExpanded && pairedDevices.length > 0 }
                SectionLabel { text: "Paired Devices"; visible: root.btExpanded && pairedDevices.length > 0 }

                Repeater {
                    visible: root.btExpanded
                    model: pairedDevices
                    delegate: deviceDelegate
                }

                Item { Layout.fillWidth: true; height: 8; visible: root.btExpanded && availableDevices.length > 0 }
                SectionLabel { text: "Available Devices"; visible: root.btExpanded && availableDevices.length > 0 }

                Repeater {
                    visible: root.btExpanded
                    model: availableDevices
                    delegate: deviceDelegate
                }
            }
        }
    }
}
