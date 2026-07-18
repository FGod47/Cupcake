import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../theme"
import "../common"

Item {
    id: root

    // =====================================================================
    // Components
    // =====================================================================

    component SettingsCard: Rectangle {
        default property alias content: cardCol.data
        Layout.fillWidth: true
        radius: 12
        color: cSurface
        border.color: cBorder
        border.width: 1
        implicitHeight: cardCol.implicitHeight + 22
        Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        clip: true

        ColumnLayout {
            id: cardCol
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.bottomMargin: 6
            spacing: 0
        }
    }

    component SectionLabel: RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 8
        property string text: ""
        spacing: 8
        Text {
            text: parent.text
            color: cTextDim
            font.family: Theme.defaultFontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 0.8
            font.capitalization: Font.AllUppercase
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: cBorder }
    }

    component SettingsRow: Rectangle {
        default property alias rowContent: innerLayout.data
        property bool clickable: false
        property string iconName: ""
        property bool iconAccent: false
        property string title: ""
        property string subtitle: ""
        property alias control: controlLayout.data

        Layout.fillWidth: true
        implicitHeight: innerLayout.implicitHeight + 20
        color: clickable && hoverArea.containsMouse ? cSurfaceHover : "transparent"
        radius: 8

        Behavior on color { ColorAnimation { duration: 120 } }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: parent.clickable
            cursorShape: parent.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        RowLayout {
            id: innerLayout
            anchors.fill: parent
            anchors.leftMargin: 0
            anchors.rightMargin: 0
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            spacing: 12

            Rectangle {
                visible: parent.parent.iconName !== ""
                width: 32; height: 32; radius: 10
                color: cBgElevated
                Text {
                    anchors.centerIn: parent
                    text: parent.parent.parent.iconName
                    color: parent.parent.parent.iconAccent ? cAccent : cTextDim
                    font.family: "tabler-icons"
                    font.pixelSize: 16
                }
            }

            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true
                Text {
                    text: parent.parent.parent.title
                    color: cText
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }
                Text {
                    visible: text !== ""
                    text: parent.parent.parent.subtitle
                    color: cTextDim
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 11
                    opacity: 0.85
                }
            }

            RowLayout {
                id: controlLayout
                spacing: 10
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: cBorderSoft
        }
    }

    component MonoChip: Rectangle {
        property string text: ""
        color: Qt.rgba(0,0,0,0.28)
        radius: 6
        height: 24
        width: Math.min(220, label.implicitWidth + 20)
        Text {
            id: label
            anchors.centerIn: parent
            text: parent.text
            color: cTextDim
            font.family: Theme.monoFontFamily
            font.pixelSize: 11
        }
    }

    component MonoInput: TextField {
        font.family: Theme.monoFontFamily
        font.pixelSize: 12
        color: cText
        background: Rectangle {
            color: Qt.rgba(0,0,0,0.28)
            border.color: parent.activeFocus ? cAccent : cBorder
            border.width: 1
            radius: 6
            implicitWidth: 170
            implicitHeight: 28
        }
        leftPadding: 10
        rightPadding: 10
    }

    component StatusBadge: Rectangle {
        property string text: ""
        property string status: "good" // good, warn
        color: status === "good" ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.14) : Qt.rgba(0.96, 0.83, 0.53, 0.14)
        radius: 20
        height: 20
        width: badgeLabel.implicitWidth + 18
        Text {
            id: badgeLabel
            anchors.centerIn: parent
            text: parent.text
            color: parent.status === "good" ? cAccent : "#f6d488"
            font.family: Theme.monoFontFamily
            font.pixelSize: 10
            font.weight: Font.DemiBold
        }
    }

    component ToggleSwitch: Rectangle {
        id: tog
        property bool checked: false
        signal toggled(bool checked)
        width: 44; height: 24; radius: 12
        color: checked ? cAccent : cBorder
        Behavior on color { ColorAnimation { duration: 150 } }
        Rectangle {
            width: 18; height: 18; radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: tog.checked ? parent.width - width - 3 : 3
            color: "white"
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: { tog.checked = !tog.checked; tog.toggled(tog.checked) }
        }
    }

    component SegmentedControl: Rectangle {
        id: seg
        property var options: []
        property string current: options.length > 0 ? options[0] : ""
        signal selected(string value)

        color: cBgElevated
        radius: 8
        height: 30
        width: row.implicitWidth + 4

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 1

            Repeater {
                model: seg.options
                delegate: Rectangle {
                    required property string modelData
                    property bool active: modelData === seg.current
                    height: 26
                    width: label.implicitWidth + 24
                    radius: 6
                    color: active ? cAccent : "transparent"

                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: modelData
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: active ? "white" : cTextDim
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: { seg.current = modelData; seg.selected(modelData) }
                    }
                }
            }
        }
    }

    component StyledSlider: Slider {
        id: control
        background: Rectangle {
            x: control.leftPadding
            y: control.topPadding + control.availableHeight / 2 - height / 2
            implicitWidth: 150
            implicitHeight: 4
            width: control.availableWidth
            height: implicitHeight
            radius: 3
            color: cBorder

            Rectangle {
                width: control.visualPosition * parent.width
                height: parent.height
                color: cAccent
                radius: 3
            }
        }
        handle: Rectangle {
            x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
            y: control.topPadding + control.availableHeight / 2 - height / 2
            implicitWidth: 15
            implicitHeight: 15
            radius: 8
            color: cAccent
            border.color: cBgElevated
            border.width: 2
        }
    }

    component Pill: Rectangle {
        id: pill
        property string label: ""
        property bool active: false
        property bool danger: false
        property bool big: false
        signal clicked()

        radius: 8
        height: big ? 34 : 26
        width: pillText.implicitWidth + (big ? 32 : 24)
        color: active ? cAccent : cBgElevated
        
        Text {
            id: pillText
            anchors.centerIn: parent
            text: pill.label
            font.family: Theme.defaultFontFamily
            font.pixelSize: 12
            font.weight: big ? Font.DemiBold : Font.Medium
            color: active ? "white" : cTextDim
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: pill.clicked()
        }

        states: [
            State {
                name: "dangerHover"
                when: ma.containsMouse && pill.danger
                PropertyChanges { target: pill; color: "#f2b8b5" }
                PropertyChanges { target: pillText; color: "#601410" }
            }
        ]
        transitions: Transition { ColorAnimation { duration: 150 } }
    }

    // =====================================================================
    // Logic
    // =====================================================================
    property string uptimeText: "Checking..."
    Timer {
        interval: 60000; running: true; repeat: true
        onTriggered: {
            Quickshell.execDetached(["bash", "-c", "uptime -p | sed 's/up //;s/ hours\?/h/;s/ minutes\?/m/' > /tmp/uptime.txt"]);
        }
    }
    Process {
        command: ["bash", "-c", "uptime -p | sed 's/up //;s/ hours\?/h/;s/ minutes\?/m/'"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.uptimeText = text.trim() }
    }
    
    // =====================================================================
    // Main UI Layout
    // =====================================================================
    ScrollView {
        id: scrollView
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: Math.min(parent.width, 760)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20

            Item { Layout.preferredHeight: 8 }

            // DEVICE
            SettingsCard {
                SectionLabel { text: "Device" }

                SettingsRow {
                    iconName: "" // map to icon from SVG
                    title: "Hostname"
                    subtitle: "Shown on the network and in shell prompts"
                    control: MonoInput { text: "ryzen-arch" }
                }
                SettingsRow {
                    iconName: ""
                    title: "Operating system"
                    subtitle: "Arch Linux x86_64"
                    control: MonoChip { text: "rolling" }
                }
                SettingsRow {
                    iconName: ""
                    title: "Kernel"
                    subtitle: "6.10.3-arch1-1"
                    control: StatusBadge { text: "up to date"; status: "good" }
                }
                SettingsRow {
                    iconName: ""
                    title: "Uptime"
                    control: MonoChip { text: root.uptimeText }
                }
            }

            // PERFORMANCE
            SettingsCard {
                SectionLabel { text: "Performance" }

                SettingsRow {
                    iconName: ""
                    iconAccent: true
                    title: "CPU governor"
                    subtitle: "Scheduling policy applied on boot"
                    control: SegmentedControl {
                        options: ["powersave", "schedutil", "performance"]
                        current: "schedutil"
                    }
                }
                SettingsRow {
                    iconName: ""
                    iconAccent: true
                    title: "Power profile"
                    control: SegmentedControl {
                        options: ["Saver", "Balanced", "Performance"]
                        current: "Balanced"
                    }
                }
                SettingsRow {
                    iconName: ""
                    title: "Swappiness"
                    subtitle: "Kernel preference for swapping over reclaim"
                    control: RowLayout {
                        spacing: 12
                        StyledSlider { from: 0; to: 100; value: 10 }
                        Text {
                            text: "10"
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 11
                            color: cTextDim
                        }
                    }
                }
            }

            // STARTUP
            SettingsCard {
                SectionLabel { text: "Startup Applications" }

                SettingsRow { iconName: ""; title: "Network Manager applet"; control: ToggleSwitch { checked: true } }
                SettingsRow { iconName: ""; title: "Bluetooth applet"; control: ToggleSwitch { checked: true } }
                SettingsRow { iconName: ""; title: "Polkit authentication agent"; control: ToggleSwitch { checked: true } }
                SettingsRow { iconName: ""; title: "Clipboard history (cliphist)"; control: ToggleSwitch { checked: true } }
                SettingsRow { iconName: ""; title: "Notification daemon (mako)"; control: ToggleSwitch { checked: false } }
            }

            // SESSION & POWER
            SettingsCard {
                SectionLabel { text: "Session & Power" }

                SettingsRow {
                    iconName: ""
                    title: "Lock after idle"
                    control: RowLayout {
                        spacing: 12
                        StyledSlider { from: 1; to: 30; value: 10 }
                        Text { text: "10m"; font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cTextDim }
                    }
                }
                SettingsRow { iconName: ""; title: "Lock on suspend"; control: ToggleSwitch { checked: true } }
                SettingsRow {
                    title: "Session actions"
                    control: RowLayout {
                        spacing: 8
                        Pill { label: "Lock" }
                        Pill { label: "Log Out" }
                        Pill { label: "Restart" }
                        Pill { label: "Shut Down"; danger: true }
                    }
                }
            }

            // DEFAULT APPS
            SettingsCard {
                SectionLabel { text: "Default Applications" }

                SettingsRow { clickable: true; iconName: "\ueca4"; title: "Terminal"; control: RowLayout { spacing: 10; MonoChip { text: "kitty" } Text { text: "\uea61"; color: cTextFaint; font.family: "tabler-icons"; font.pixelSize: 16 } } }
                SettingsRow { clickable: true; iconName: "\ueb01"; title: "File manager"; control: RowLayout { spacing: 10; MonoChip { text: "nautilus" } Text { text: "\uea61"; color: cTextFaint; font.family: "tabler-icons"; font.pixelSize: 16 } } }
                SettingsRow { clickable: true; iconName: "\uec50"; title: "Web browser"; control: RowLayout { spacing: 10; MonoChip { text: "firefox" } Text { text: "\uea61"; color: cTextFaint; font.family: "tabler-icons"; font.pixelSize: 16 } } }
                SettingsRow { clickable: true; iconName: "\ueabf"; title: "Text editor"; control: RowLayout { spacing: 10; MonoChip { text: "neovim" } Text { text: "\uea61"; color: cTextFaint; font.family: "tabler-icons"; font.pixelSize: 16 } } }
            }

            // UPDATES
            SettingsCard {
                SectionLabel { text: "System Updates" }

                SettingsRow {
                    iconName: ""
                    iconAccent: true
                    title: "14 packages can be updated"
                    subtitle: "3 from the AUR · mirrorlist synced 2h ago"
                    control: Pill { label: "Update now"; active: true; big: true }
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: cBorderSoft
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4; Layout.bottomMargin: 4
                    Text { text: "linux"; font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cText }
                    Item { Layout.fillWidth: true }
                    Text { text: "6.10.2 → "; font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cTextFaint }
                    Text { text: "6.10.3"; font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cAccent }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: cBorderSoft }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4; Layout.bottomMargin: 4
                    Text { text: "mesa"; font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cText }
                    Item { Layout.fillWidth: true }
                    Text { text: "24.1.4 → "; font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cTextFaint }
                    Text { text: "24.1.5"; font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cAccent }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: cBorderSoft }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4; Layout.bottomMargin: 4
                    Text { text: "quickshell-git"; font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cText }
                    Item { Layout.fillWidth: true }
                    Text { text: "r412 → "; font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cTextFaint }
                    Text { text: "r418"; font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cAccent }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: cBorderSoft }
                SettingsRow { iconName: ""; title: "Check automatically every day"; control: ToggleSwitch { checked: true } }
            }

            // QUICKSHELL
            SettingsCard {
                SectionLabel { text: "Quickshell" }

                SettingsRow { iconName: ""; title: "IPC socket"; subtitle: "Used by quickshell CLI and this settings app"; control: MonoChip { text: "/run/user/1000/quickshell/cupcake.sock" } }
                SettingsRow { iconName: ""; title: "Live-reload on config change"; control: ToggleSwitch { checked: true } }
                SettingsRow { title: "Shell process"; subtitle: "Restart the quickshell daemon"; control: Pill { label: "Restart shell" } }
            }

            Item { Layout.preferredHeight: 32 }
        }
    }
}
