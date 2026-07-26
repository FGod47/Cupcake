import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import Quickshell
import Quickshell.Io

Item {
    id: root
    anchors.fill: parent

    component NCard: Rectangle {
        default property alias content: cardCol.data
        property string sectionTitle: ""
        Layout.fillWidth: true
        implicitHeight: cardCol.implicitHeight + (cardHeader.visible ? cardHeader.height + 28 : 32)
        color: cBgElevated
        radius: 20
        border.width: 0
        clip: true

        RowLayout {
            id: cardHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.topMargin: 16
            visible: sectionTitle !== ""
            spacing: 8

            Text {
                text: sectionTitle
                color: cTextDim
                font.family: Theme.defaultFontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
                font.capitalization: Font.AllUppercase
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: cBorder }
        }

        ColumnLayout {
            id: cardCol
            anchors.top: cardHeader.visible ? cardHeader.bottom : parent.top
            anchors.topMargin: cardHeader.visible ? 12 : 16
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.bottomMargin: 16
            spacing: 0
        }
    }

    component NRow: Rectangle {
        default property alias rowContent: innerLayout.data
        Layout.fillWidth: true
        implicitHeight: innerLayout.implicitHeight + 20
        color: "transparent"
        radius: 8

        property bool hoverable: false
        property bool hovered: hoverArea.containsMouse
        Behavior on color { ColorAnimation { duration: 120 } }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: parent.hoverable
        }

        RowLayout {
            id: innerLayout
            anchors.fill: parent
                    anchors.topMargin: 10
            anchors.bottomMargin: 10
            spacing: 12
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: cBorder
            opacity: 0.6
        }
    }

    component NIconBadge: Rectangle {
        property string icon: ""
        property color iconColor: cTextDim
        property color bgColor: cBgElevated
        width: 36; height: 36; radius: 10
        color: bgColor
        Text {
            anchors.centerIn: parent
            text: parent.icon
            font.family: "tabler-icons"
            font.pixelSize: 18
            color: parent.iconColor
        }
    }

    component NToggle: Rectangle {
        id: tog
        property bool checked: false
        signal toggled(bool val)
        width: 44; height: 24; radius: 12
        color: checked ? cAccent : cBorderSoft
        Behavior on color { ColorAnimation { duration: 150 } }
        Rectangle {
            width: 18; height: 18; radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: tog.checked ? parent.width - width - 3 : 3
            color: Theme.colBackground
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            layer.enabled: true
            layer.effect: null
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: { tog.checked = !tog.checked; tog.toggled(tog.checked) }
        }
    }

    // Theme references
    property color cBg: Theme.colSurface
    property color cBgElevated: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
    property color cSurfaceHover: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
    property color cBorder: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
    property color cBorderSoft: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.08)
    property color cText: Theme.colOnSurface
    property color cTextDim: Theme.colOnSurfaceVariant
    property color cTextFaint: Qt.rgba(Theme.colOnSurfaceVariant.r, Theme.colOnSurfaceVariant.g, Theme.colOnSurfaceVariant.b, 0.5)
    property color cAccent: Theme.colPrimary

    // State
    component NEditableRow: NRow {
        property string labelText: ""
        property string iconStr: ""
        property string currentValue: ""
        signal saveRequested(string newValue)
        
        property bool editing: false
        
        NIconBadge { icon: iconStr }
        Text { text: labelText; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
        Item { Layout.fillWidth: true }
        
        TextField {
            id: field
            text: currentValue
            enabled: editing
            color: editing ? cText : cTextDim
            font.family: Theme.defaultFontFamily
            font.pixelSize: 13
            horizontalAlignment: Text.AlignRight
            selectByMouse: true
            background: Rectangle {
                color: editing && field.activeFocus ? cSurfaceHover : "transparent"
                radius: 6
                border.color: editing && field.activeFocus ? cAccent : (editing ? cBorderSoft : "transparent")
                border.width: 1
            }
            padding: 6
            rightPadding: 8
            leftPadding: 8
            onAccepted: btnMa.saveAction()
        }
        
        RowLayout {
            spacing: 8
            
            Rectangle {
                width: cancelTxt.width + 16; height: 26; radius: 13
                visible: editing
                color: cancelMa.containsMouse ? cSurfaceHover : "transparent"
                border.color: cBorderSoft
                border.width: 1
                Text {
                    id: cancelTxt
                    anchors.centerIn: parent
                    text: "Cancel"
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: cTextDim
                }
                MouseArea {
                    id: cancelMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        field.text = currentValue;
                        editing = false;
                    }
                }
            }
            
            Rectangle {
                width: btnTxt.width + 16; height: 26; radius: 13
                color: btnMa.containsMouse ? (editing ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.12) : cSurfaceHover) : (editing ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.1) : "transparent")
                border.color: editing ? cAccent : cBorderSoft
                border.width: 1
                Text {
                    id: btnTxt
                    anchors.centerIn: parent
                    text: editing ? "Save" : "Edit"
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: editing ? cAccent : cTextDim
                }
                MouseArea {
                    id: btnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    function saveAction() {
                        if (editing) {
                            if (field.text.trim() !== "" && field.text.trim() !== currentValue) {
                                saveRequested(field.text.trim());
                            } else {
                                field.text = currentValue;
                            }
                            editing = false;
                        }
                    }
                    onClicked: {
                        if (editing) {
                            saveAction();
                        } else {
                            editing = true;
                            field.forceActiveFocus();
                        }
                    }
                }
            }
        }
    }

    property bool hotspotEnabled: false
    property string hotspotSsid: ""
    property string hotspotPassword: ""
    property int connectedClients: 0

    ListModel {
        id: clientsModel
    }

    Process {
        id: hotspotStatusProcess
        command: ["bash", "-c", "nmcli -t -f TYPE,STATE,CONNECTION d | grep -i 'wifi:connected' | grep -qi -E 'hotspot' && echo 'on' || echo 'off'"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.hotspotEnabled = text.trim() === "on" }
    }

    Process {
        id: hotspotDetailsProcess
        command: ["bash", "-c", "nmcli -g 802-11-wireless.ssid connection show Hotspot 2>/dev/null || echo 'cupcake-hotspot'"]
        running: true
        stdout: StdioCollector { onStreamFinished: { if (text.trim() !== "") root.hotspotSsid = text.trim() } }
    }

    Process {
        id: hotspotPassProcess
        command: ["bash", "-c", "nmcli -s -g 802-11-wireless-security.psk connection show Hotspot 2>/dev/null || echo 'cupcake-password'"]
        running: true
        stdout: StdioCollector { onStreamFinished: { if (text.trim() !== "") root.hotspotPassword = text.trim() } }
    }

    Process {
        id: hotspotClientsProcess
        command: ["python3", "/home/code/.local/bin/quickshell-hotspot-clients.py"]
        running: root.hotspotEnabled
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let devices = JSON.parse(text.trim());
                    root.connectedClients = devices.length;
                    clientsModel.clear();
                    for (let i = 0; i < devices.length; i++) {
                        clientsModel.append(devices[i]);
                    }
                } catch (e) {
                    root.connectedClients = 0;
                    clientsModel.clear();
                }
            }
        }
    }

    Timer {
        interval: 3000
        running: root.visible && root.hotspotEnabled
        repeat: true
        onTriggered: hotspotClientsProcess.running = true
    }

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

            // Back button & Title header
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: backMa.containsMouse ? cSurfaceHover : "transparent"
                    Text { anchors.centerIn: parent; text: "\uea5c"; font.family: "tabler-icons"; font.pixelSize: 20; color: cText }
                    MouseArea {
                        id: backMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let p = root;
                            while (p && !p.hasOwnProperty("currentIndex")) p = p.parent;
                            if (p.currentIndex !== undefined) p.currentIndex = 17; // back to network
                        }
                    }
                }

                Text {
                    text: "Mobile Hotspot"
                    color: cText
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 20
                    font.weight: Font.Medium
                }
            }

            NCard {
                sectionTitle: "Hotspot Configuration"

                NRow {
                    NIconBadge {
                        icon: "\ued1b"
                    }
                    ColumnLayout {
                        spacing: 2
                        Text { text: "Wi-Fi Hotspot"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                        Text { text: root.hotspotEnabled ? "Broadcasting..." : "Off"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.hotspotEnabled
                        onToggled: {
                            root.hotspotEnabled = val;
                            if (val) {
                                Quickshell.execDetached(["bash", "-c", "bluetoothctl scan off 2>/dev/null; sleep 0.5; nmcli connection up Hotspot 2>/dev/null || nmcli device wifi hotspot"]);
                                hotspotClientsProcess.running = true;
                            } else {
                                Quickshell.execDetached(["bash", "-c", "nmcli connection down Hotspot || nmcli connection down hotspot"]);
                            }
                        }
                    }
                }

                NEditableRow {
                    iconStr: "\ueabc"
                    labelText: "Network Name"
                    currentValue: root.hotspotSsid
                    onSaveRequested: function(newValue) {
                        Quickshell.execDetached(["nmcli", "connection", "modify", "Hotspot", "802-11-wireless.ssid", newValue]);
                        root.hotspotSsid = newValue;
                    }
                }

                NEditableRow {
                    iconStr: "\ueb07"
                    labelText: "Password"
                    currentValue: root.hotspotPassword !== "" ? root.hotspotPassword : "cupcake-password"
                    onSaveRequested: function(newValue) {
                        Quickshell.execDetached(["nmcli", "connection", "modify", "Hotspot", "802-11-wireless-security.key-mgmt", "wpa-psk", "802-11-wireless-security.psk", newValue]);
                        root.hotspotPassword = newValue;
                    }
                }
            }

            NCard {
                sectionTitle: "Connected Devices"
                visible: root.hotspotEnabled

                NRow {
                    NIconBadge { icon: "\uebd9" }
                    ColumnLayout {
                        spacing: 2
                        Text { text: "Clients"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                        Text { text: root.connectedClients + " device(s) connected"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                    }
                    Item { Layout.fillWidth: true }
                }

                Repeater {
                    model: clientsModel
                    delegate: NRow {
                        NIconBadge {
                            icon: "\uea8a"
                        }
                        ColumnLayout {
                            spacing: 2
                            Text { text: model.name; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: model.ip + " • " + model.mac; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11 }
                        }
                        Item { Layout.fillWidth: true }
                        
                        Rectangle {
                            width: blockTxt.width + 16; height: 26; radius: 13
                            color: blockMa.containsMouse ? Qt.rgba(255, 0, 0, 0.1) : "transparent"
                            border.color: blockMa.containsMouse ? "#ff4444" : cBorderSoft
                            border.width: 1
                            Text {
                                id: blockTxt
                                anchors.centerIn: parent
                                text: "Block"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: blockMa.containsMouse ? "#ff4444" : cTextDim
                            }
                            MouseArea {
                                id: blockMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached(["bash", "-c", "nmcli connection modify Hotspot +802-11-wireless.mac-address-blacklist " + model.mac + " && nmcli connection up Hotspot"]);
                                    clientsModel.remove(index);
                                    root.connectedClients -= 1;
                                }
                            }
                        }
                    }
                }
            }

        }
    }
}
