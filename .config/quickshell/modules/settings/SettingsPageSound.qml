import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import Quickshell.Io
import Quickshell
import "../common"
import Quickshell.Services.Pipewire

Item {
    id: root

    // Dummy states for the UI elements that don't have direct Pipewire bindings yet
    property int balanceVal: 0
    property string outProfile: "Stereo"
    property bool noiseSuppression: true
    property bool echoCancellation: true
    property string btCodec: "AAC"
    property bool btQuality: false
    property bool sfxInterface: true
    property bool sfxNotification: true
    property real sfxVolume: 0.55
    property string advSampleRate: "48kHz"
    property string advBuffer: "512"
    property bool advAutoSwitch: true

    // Reusable inline components (Modern Design)
    component SettingsCard: Rectangle {
        default property alias content: cardCol.data
        property string sectionTitle: ""
        Layout.fillWidth: true
        implicitHeight: cardCol.implicitHeight + (cardHeader.visible ? cardHeader.height + 28 : 32)
        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
        radius: 12
        border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.08)
        border.width: 1

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
                color: Theme.colOnSurfaceVariant
                font.family: Theme.defaultFontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
                font.capitalization: Font.AllUppercase
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15) }
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

    component SettingsRow: Rectangle {
        default property alias rowContent: innerLayout.data
        Layout.fillWidth: true
        implicitHeight: innerLayout.implicitHeight + 20
        color: hoverable && hovered ? Qt.rgba(255,255,255,0.03) : "transparent"
        radius: 8
        property bool hoverable: false
        property bool showBorder: true
        property bool hovered: hoverArea.containsMouse
        signal clicked()

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: parent.hoverable
            onClicked: parent.clicked()
            cursorShape: parent.hoverable ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        RowLayout {
            id: innerLayout
            anchors.fill: parent
            anchors.leftMargin: 0
            anchors.rightMargin: 0
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            spacing: 12
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
            opacity: 0.6
            visible: parent.showBorder
        }
    }

    component SegmentedControl: Rectangle {
        id: seg
        property var options: []
        property string current: options.length > 0 ? options[0] : ""
        signal selected(string value)
        color: Qt.rgba(0, 0, 0, 0.28)
        radius: 8
        height: 30
        width: segRow.implicitWidth + 4
        Row {
            id: segRow
            anchors.centerIn: parent
            spacing: 1
            Repeater {
                model: seg.options
                delegate: Rectangle {
                    required property string modelData
                    property bool active: modelData === seg.current
                    height: 26
                    width: segLabel.implicitWidth + 24
                    radius: 6
                    color: active ? Theme.colPrimary : "transparent"
                    Text {
                        id: segLabel
                        anchors.centerIn: parent
                        text: modelData
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: active ? Theme.colSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.5)
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { seg.current = modelData; seg.selected(modelData) }
                    }
                }
            }
        }
    }

    component RowIcon: Rectangle {
        property string icon: ""
        property bool accent: false
        width: 32; height: 32; radius: 10
        color: Theme.colSurface
        Text {
            anchors.centerIn: parent
            text: parent.icon
            font.family: "tabler-icons"
            font.pixelSize: 16
            color: parent.accent ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.5)
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        leftPadding: 32; rightPadding: 32; topPadding: 32; bottomPadding: 32
        
        ColumnLayout {
            width: parent.width
            spacing: 20

            // Header
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                
                Column {
                    Text {
                        text: "Sound"
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 22
                        font.weight: Font.ExtraBold
                        font.letterSpacing: -0.4
                        color: Theme.colOnSurface
                    }
                    Text {
                        text: "~/.config/cupcake › sound"
                        font.family: Theme.monoFontFamily
                        font.pixelSize: 11.5
                        color: Theme.colOnSurfaceVariant
                    }
                }
                
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: badgeText.implicitWidth + 20; height: 22
                    radius: 11
                    color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12)
                    border.color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.25)
                    border.width: 1
                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: "PipeWire · WirePlumber"
                        font.family: Theme.monoFontFamily
                        font.pixelSize: 11
                        color: Theme.colPrimary
                    }
                }
            }

            // OUTPUT
            SettingsCard {
                sectionTitle: "Output"

                SettingsRow {
                    hoverable: true
                    RowIcon { icon: "\uebc5"; accent: true } // device-speaker
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Output device"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        Text { text: "Playback routed here by default"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                    }
                    RowLayout {
                        spacing: 8
                        Rectangle {
                            height: 22; width: chipText.implicitWidth + 20; radius: 6; color: Qt.rgba(0,0,0,0.28)
                            Text {
                                id: chipText
                                anchors.centerIn: parent
                                text: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.name : "Unknown Device"
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 11
                                color: Theme.colOnSurfaceVariant
                            }
                        }
                        Text { text: "\uea61"; font.family: "tabler-icons"; font.pixelSize: 16; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.3) }
                    }
                }

                SettingsRow {
                    RowIcon { icon: "\ueb7e" } // volume
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Volume"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                    }
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 30; height: 30; radius: 9
                            color: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted) ? Qt.rgba(242/255, 184/255, 181/255, 0.08) : Theme.colSurface
                            border.color: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted) ? Qt.rgba(242/255, 184/255, 181/255, 0.35) : Theme.colOutline
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted) ? "\ueb7f" : "\ueb7e"
                                font.family: "tabler-icons"; font.pixelSize: 15
                                color: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted) ? "#f2b8b5" : Theme.colOnSurfaceVariant
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted }
                            }
                        }
                        StyledSlider {
                            id: volSlider
                            Layout.preferredWidth: 150
                            from: 0; to: 1.0
                            value: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) ? Pipewire.defaultAudioSink.audio.volume : 0
                            onMoved: { if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) Pipewire.defaultAudioSink.audio.volume = value }
                        }
                        Text {
                            text: Math.round(volSlider.value * 100) + "%"
                            font.family: Theme.monoFontFamily; font.pixelSize: 11.5; color: Theme.colOnSurfaceVariant
                            Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                SettingsRow {
                    RowIcon { icon: "\ueaf4" } // adjustments-horizontal
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Balance"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        Text { text: "Left / right channel bias"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                    }
                    RowLayout {
                        spacing: 12
                        Text { text: "L"; font.family: Theme.monoFontFamily; font.pixelSize: 11.5; color: Theme.colOnSurfaceVariant }
                        StyledSlider {
                            Layout.preferredWidth: 120
                            from: -50; to: 50
                            value: root.balanceVal
                            onMoved: root.balanceVal = value
                        }
                        Text { text: "R"; font.family: Theme.monoFontFamily; font.pixelSize: 11.5; color: Theme.colOnSurfaceVariant }
                    }
                }

                SettingsRow {
                    showBorder: false
                    RowIcon { icon: "\ueb93" } // speaker
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Output profile"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                    }
                    SegmentedControl {
                        options: ["Stereo", "Surround 5.1"]
                        current: root.outProfile
                        onSelected: root.outProfile = value
                    }
                }
            }

            // INPUT
            SettingsCard {
                sectionTitle: "Input"

                SettingsRow {
                    hoverable: true
                    RowIcon { icon: "\ueaef" } // microphone
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Input device"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        Text { text: "Used for calls, recording, voice commands"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                    }
                    RowLayout {
                        spacing: 8
                        Rectangle {
                            height: 22; width: inChipText.implicitWidth + 20; radius: 6; color: Qt.rgba(0,0,0,0.28)
                            Text {
                                id: inChipText
                                anchors.centerIn: parent
                                text: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.name : "Unknown Device"
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 11
                                color: Theme.colOnSurfaceVariant
                            }
                        }
                        Text { text: "\uea61"; font.family: "tabler-icons"; font.pixelSize: 16; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.3) }
                    }
                }

                SettingsRow {
                    RowIcon { icon: "\ueaef" }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Input volume"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                    }
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 30; height: 30; radius: 9
                            color: (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio && Pipewire.defaultAudioSource.audio.muted) ? Qt.rgba(242/255, 184/255, 181/255, 0.08) : Theme.colSurface
                            border.color: (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio && Pipewire.defaultAudioSource.audio.muted) ? Qt.rgba(242/255, 184/255, 181/255, 0.35) : Theme.colOutline
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio && Pipewire.defaultAudioSource.audio.muted) ? "\ueaf0" : "\ueaef"
                                font.family: "tabler-icons"; font.pixelSize: 15
                                color: (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio && Pipewire.defaultAudioSource.audio.muted) ? "#f2b8b5" : Theme.colOnSurfaceVariant
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted }
                            }
                        }
                        StyledSlider {
                            id: inSlider
                            Layout.preferredWidth: 150
                            from: 0; to: 1.0
                            value: (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) ? Pipewire.defaultAudioSource.audio.volume : 0
                            onMoved: { if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) Pipewire.defaultAudioSource.audio.volume = value }
                        }
                        Text {
                            text: Math.round(inSlider.value * 100) + "%"
                            font.family: Theme.monoFontFamily; font.pixelSize: 11.5; color: Theme.colOnSurfaceVariant
                            Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                SettingsRow {
                    RowIcon { icon: "\ueaf1"; accent: true } // wave-sine
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Noise suppression (RNNoise)"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                    }
                    StyledSwitch { checked: root.noiseSuppression; onClicked: root.noiseSuppression = !root.noiseSuppression }
                }

                SettingsRow {
                    showBorder: false
                    RowIcon { icon: "\uef57" } // waves
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Echo cancellation"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                    }
                    StyledSwitch { checked: root.echoCancellation; onClicked: root.echoCancellation = !root.echoCancellation }
                }
            }

            // APP MIXER
            SettingsCard {
                sectionTitle: "App Volume Mixer"
                
                Repeater {
                    model: Pipewire.nodes
                    delegate: Item {
                        width: parent.width
                        height: visible ? 52 : 0
                        visible: typeof modelData !== "undefined" && modelData.isStream && typeof modelData.audio !== "undefined" && modelData.audio !== null

                        function getIcon(name) {
                            if (!name) return "Ap";
                            let n = name.toLowerCase();
                            if (n.includes("chrome") || n.includes("firefox") || n.includes("brave") || n.includes("edge")) return "Fx";
                            if (n.includes("spotify") || n.includes("music")) return "Sp";
                            if (n.includes("discord") || n.includes("teamspeak")) return "Dc";
                            if (n.includes("steam")) return "St";
                            return name.substring(0, 2).toUpperCase();
                        }

                        function getColor(name) {
                            let n = name ? name.toLowerCase() : "";
                            if (n.includes("firefox")) return Qt.rgba(1, 0.41, 0.23, 1);
                            if (n.includes("spotify")) return Qt.rgba(0.11, 0.72, 0.32, 1);
                            if (n.includes("discord")) return Qt.rgba(0.34, 0.39, 0.94, 1);
                            return Theme.colPrimary;
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.topMargin: 10
                            anchors.bottomMargin: 10
                            spacing: 12
                            
                            Rectangle {
                                width: 32; height: 32; radius: 10
                                color: getColor(modelData.name)
                                Text {
                                    anchors.centerIn: parent
                                    text: getIcon(modelData.name)
                                    font.family: Theme.defaultFontFamily; font.weight: Font.Bold; font.pixelSize: 13
                                    color: "white"
                                }
                            }
                            
                            Text {
                                text: modelData.name
                                font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface
                                Layout.preferredWidth: 100; elide: Text.ElideRight
                            }
                            
                            StyledSlider {
                                Layout.fillWidth: true
                                from: 0; to: 1.0
                                value: modelData.audio.volume
                                onMoved: modelData.audio.volume = value
                            }
                            
                            Text {
                                text: Math.round(modelData.audio.volume * 100) + "%"
                                font.family: Theme.monoFontFamily; font.pixelSize: 11.5; color: Theme.colOnSurfaceVariant
                                Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight
                            }
                        }
                        
                        Rectangle {
                            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                            height: 1; color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15); opacity: 0.6
                        }
                    }
                }
            }

            // BLUETOOTH AUDIO
            SettingsCard {
                sectionTitle: "Bluetooth Audio"

                SettingsRow {
                    RowIcon { icon: "\uea37" } // bluetooth
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Preferred codec"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        Text { text: "WH-1000XM5 · connected"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                    }
                    SegmentedControl {
                        options: ["SBC", "AAC", "aptX HD"]
                        current: root.btCodec
                        onSelected: root.btCodec = value
                    }
                }

                SettingsRow {
                    showBorder: false
                    RowIcon { icon: "\uea4e" } // battery-charging
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Prefer quality over battery life"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                    }
                    StyledSwitch { checked: root.btQuality; onClicked: root.btQuality = !root.btQuality }
                }
            }

            // SOUND EFFECTS
            SettingsCard {
                sectionTitle: "Sound Effects"

                SettingsRow {
                    RowIcon { icon: "\uebc5" } // device-speaker
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Interface sound effects"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        Text { text: "Volume changes, connect/disconnect chimes"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                    }
                    StyledSwitch { checked: root.sfxInterface; onClicked: root.sfxInterface = !root.sfxInterface }
                }

                SettingsRow {
                    RowIcon { icon: "\uea35" } // bell
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Notification sound"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                    }
                    StyledSwitch { checked: root.sfxNotification; onClicked: root.sfxNotification = !root.sfxNotification }
                }

                SettingsRow {
                    showBorder: false
                    RowIcon { icon: "\ueb7e" } // volume
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Effects volume"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                    }
                    RowLayout {
                        spacing: 12
                        StyledSlider {
                            Layout.preferredWidth: 150
                            from: 0; to: 1.0
                            value: root.sfxVolume
                            onMoved: root.sfxVolume = value
                        }
                        Text {
                            text: Math.round(root.sfxVolume * 100) + "%"
                            font.family: Theme.monoFontFamily; font.pixelSize: 11.5; color: Theme.colOnSurfaceVariant
                            Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }

            // ADVANCED
            SettingsCard {
                sectionTitle: "Advanced"

                SettingsRow {
                    RowIcon { icon: "\uea16" } // activity
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Sample rate"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                    }
                    SegmentedControl {
                        options: ["44.1kHz", "48kHz", "96kHz"]
                        current: root.advSampleRate
                        onSelected: root.advSampleRate = value
                    }
                }

                SettingsRow {
                    RowIcon { icon: "\ueb8b" } // cpu
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Buffer size (quantum)"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        Text { text: "Lower reduces latency, higher reduces crackle"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                    }
                    SegmentedControl {
                        options: ["256", "512", "1024"]
                        current: root.advBuffer
                        onSelected: root.advBuffer = value
                    }
                }

                SettingsRow {
                    showBorder: false
                    RowIcon { icon: "\ueb6c" } // refresh
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Auto-switch to newly connected devices"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                    }
                    StyledSwitch { checked: root.advAutoSwitch; onClicked: root.advAutoSwitch = !root.advAutoSwitch }
                }
            }

        }
    }
}
