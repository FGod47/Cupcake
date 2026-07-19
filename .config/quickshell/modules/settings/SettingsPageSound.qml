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

    component SoundRowIcon: Rectangle {
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
            NCard {
                sectionTitle: "Output"

                NRow {
                    hoverable: true
                    SoundRowIcon { icon: "\uebc5"; accent: true }
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

                NRow {
                    SoundRowIcon { icon: "\ueb7e" }
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

                NRow {
                    SoundRowIcon { icon: "\ueaf4" }
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

                NRow {
                    SoundRowIcon { icon: "\ueb93" }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Output profile"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                    }
                    SegmentedControl {
                        options: ["Stereo", "Surround 5.1"]
                        current: root.outProfile
                        onSelected: (val) => root.outProfile = val
                    }
                }
            }

            // INPUT
            NCard {
                sectionTitle: "Input"

                NRow {
                    hoverable: true
                    SoundRowIcon { icon: "\ueaef" }
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

                NRow {
                    SoundRowIcon { icon: "\ueaef" }
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

                NRow {
                    SoundRowIcon { icon: "\ueaf1"; accent: true }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Noise suppression (RNNoise)"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                    }
                    NToggle { checked: root.noiseSuppression; onToggled: (val) => root.noiseSuppression = val }
                }

                NRow {
                    SoundRowIcon { icon: "\uef57" }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Echo cancellation"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                    }
                    NToggle { checked: root.echoCancellation; onToggled: (val) => root.echoCancellation = val }
                }
            }

            // APP MIXER
            NCard {
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
            NCard {
                sectionTitle: "Bluetooth Audio"

                NRow {
                    SoundRowIcon { icon: "\uea37" }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Preferred codec"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        Text { text: "WH-1000XM5 · connected"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                    }
                    SegmentedControl {
                        options: ["SBC", "AAC", "aptX HD"]
                        current: root.btCodec
                        onSelected: (val) => root.btCodec = val
                    }
                }

                NRow {
                    SoundRowIcon { icon: "\uea4e" }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Prefer quality over battery life"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                    }
                    NToggle { checked: root.btQuality; onToggled: (val) => root.btQuality = val }
                }
            }

            // SOUND EFFECTS
            NCard {
                sectionTitle: "Sound Effects"

                NRow {
                    SoundRowIcon { icon: "\uebc5" }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Interface sound effects"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        Text { text: "Volume changes, connect/disconnect chimes"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                    }
                    NToggle { checked: root.sfxInterface; onToggled: (val) => root.sfxInterface = val }
                }

                NRow {
                    SoundRowIcon { icon: "\uea35" }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Notification sound"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                    }
                    NToggle { checked: root.sfxNotification; onToggled: (val) => root.sfxNotification = val }
                }

                NRow {
                    SoundRowIcon { icon: "\ueb7e" }
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
            NCard {
                sectionTitle: "Advanced"

                NRow {
                    SoundRowIcon { icon: "\uea16" }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Sample rate"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                    }
                    SegmentedControl {
                        options: ["44.1kHz", "48kHz", "96kHz"]
                        current: root.advSampleRate
                        onSelected: (val) => root.advSampleRate = val
                    }
                }

                NRow {
                    SoundRowIcon { icon: "\ueb8b" }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Buffer size (quantum)"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        Text { text: "Lower reduces latency, higher reduces crackle"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                    }
                    SegmentedControl {
                        options: ["256", "512", "1024"]
                        current: root.advBuffer
                        onSelected: (val) => root.advBuffer = val
                    }
                }

                NRow {
                    SoundRowIcon { icon: "\ueb6c" }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: "Auto-switch to newly connected devices"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                    }
                    NToggle { checked: root.advAutoSwitch; onToggled: (val) => root.advAutoSwitch = val }
                }
            }

        }
    }
}
