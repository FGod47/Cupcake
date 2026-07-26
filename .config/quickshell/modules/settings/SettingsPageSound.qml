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
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        
        ColumnLayout {
            width: Math.min(parent.width, 1000)
            spacing: 20

            // OUTPUT
            NCard {
                sectionTitle: "Output"

                NRow {
                    id: outputDeviceRow
                    property var sinksModel: []
                    
                    Repeater {
                        model: Pipewire.nodes
                        delegate: Item {
                            visible: false
                            Component.onCompleted: {
                                if (typeof modelData !== "undefined" && modelData.isSink && !modelData.isStream) {
                                    let arr = outputDeviceRow.sinksModel.slice();
                                    arr.push({ label: modelData.description || modelData.name, node: modelData });
                                    outputDeviceRow.sinksModel = arr;
                                    
                                    if (Pipewire.defaultAudioSink && modelData.id === Pipewire.defaultAudioSink.id) {
                                        for(let i=0; i<arr.length; i++) {
                                            if(arr[i].node.id === modelData.id) outputDeviceCombo.currentIndex = i;
                                        }
                                    }
                                }
                            }
                            Component.onDestruction: {
                                if (typeof modelData !== "undefined" && modelData.isSink && !modelData.isStream) {
                                    let arr = outputDeviceRow.sinksModel.slice();
                                    arr = arr.filter(o => o.node.id !== modelData.id);
                                    outputDeviceRow.sinksModel = arr;
                                }
                            }
                        }
                    }

                    RowLayout {
                        spacing: 12
                        SoundRowIcon { icon: "\uebc5"; accent: true }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Output device"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                            Text { text: "Playback routed here by default"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox {
                        id: outputDeviceCombo
                        Layout.preferredWidth: 200
                        model: outputDeviceRow.sinksModel
                        textRole: "label"
                        
                        Connections {
                            target: Pipewire
                            function onDefaultAudioSinkChanged() {
                                if (Pipewire.defaultAudioSink) {
                                    for (let i = 0; i < outputDeviceCombo.model.length; i++) {
                                        if (outputDeviceCombo.model[i].node.id === Pipewire.defaultAudioSink.id) {
                                            outputDeviceCombo.currentIndex = i;
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                        
                        Component.onCompleted: {
                            if (Pipewire.defaultAudioSink) {
                                for (let i = 0; i < model.length; i++) {
                                    if (model[i].node.id === Pipewire.defaultAudioSink.id) {
                                        currentIndex = i;
                                        break;
                                    }
                                }
                            }
                        }
                        
                        onActivated: (index) => {
                            let n = model[index].node;
                            Pipewire.preferredDefaultAudioSink = n;
                        }
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        SoundRowIcon { icon: "\ueb7e" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Volume"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
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
                                onClicked: { 
                                    outMuteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"];
                                    outMuteProc.running = true;
                                }
                            }
                        }
                        
                        Process { id: outVolProc }
                        Process { id: outMuteProc }
                        
                        Process {
                            id: initOutVol
                            command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
                            stdout: StdioCollector { id: initOutVolOut }
                            onExited: {
                                let match = initOutVolOut.text.trim().match(/Volume:\s+([\d\.]+)/);
                                if (match && !volSlider.pressed) volSlider.value = parseFloat(match[1]);
                            }
                        }
                        Timer {
                            interval: 1000; running: true; repeat: true
                            onTriggered: initOutVol.running = true
                            Component.onCompleted: initOutVol.running = true
                        }
                        
                        StyledSlider {
                            id: volSlider
                            Layout.preferredWidth: 220
                            from: 0; to: 1.0
                            onMoved: { 
                                outVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", value.toString()];
                                outVolProc.running = true;
                            }
                        }
                        
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        SoundRowIcon { icon: "\ueaf4" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Balance"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                            Text { text: "Left / right channel bias"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 12
                        Text { text: "L"; font.family: Theme.monoFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                        StyledSlider {
                            id: balanceSlider
                            Layout.preferredWidth: 220
                            from: -50; to: 50
                            value: root.balanceVal
                            onMoved: root.balanceVal = value
                        }
                        Text { text: "R"; font.family: Theme.monoFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        SoundRowIcon { icon: "\ueb93" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Output profile"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
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
                    RowLayout {
                        spacing: 12
                        SoundRowIcon { icon: "\ueaef" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Input device"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                            Text { text: "Used for calls, recording, voice commands"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 8
                        Rectangle {
                            height: 22; width: inChipText.implicitWidth + 20; radius: 6; color: Qt.rgba(0,0,0,0.28)
                            Text {
                                id: inChipText
                                anchors.centerIn: parent
                                text: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.name : "Unknown Device"
                                font.family: Theme.monoFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant
                            }
                        }
                        Text { text: "\uea61"; font.family: "tabler-icons"; font.pixelSize: 16; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.3) }
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        SoundRowIcon { icon: "\ueaef" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Input volume"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
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
                                onClicked: { 
                                    inMuteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"];
                                    inMuteProc.running = true;
                                }
                            }
                        }
                        
                        Process { id: inVolProc }
                        Process { id: inMuteProc }
                        
                        Process {
                            id: initInVol
                            command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
                            stdout: StdioCollector { id: initInVolOut }
                            onExited: {
                                let match = initInVolOut.text.trim().match(/Volume:\s+([\d\.]+)/);
                                if (match && !inSlider.pressed) inSlider.value = parseFloat(match[1]);
                            }
                        }
                        Timer {
                            interval: 1000; running: true; repeat: true
                            onTriggered: initInVol.running = true
                            Component.onCompleted: initInVol.running = true
                        }
                        
                        StyledSlider {
                            id: inSlider
                            Layout.preferredWidth: 220
                            from: 0; to: 1.0
                            onMoved: { 
                                inVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", value.toString()];
                                inVolProc.running = true;
                            }
                        }
                        
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        SoundRowIcon { icon: "\ueaf1"; accent: true }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Noise suppression (RNNoise)"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: root.noiseSuppression; onToggled: (val) => root.noiseSuppression = val }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        SoundRowIcon { icon: "\uef57" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Echo cancellation"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
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
                                    color: Theme.colOnPrimary
                                }
                            }
                            
                            Text {
                                text: modelData.name
                                font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface
                                Layout.preferredWidth: 100; elide: Text.ElideRight
                            }
                            
                            Process { id: appVolProc }
                            
                            Process {
                                id: initAppVol
                                command: ["wpctl", "get-volume", modelData.id.toString()]
                                running: true
                                stdout: StdioCollector { id: initAppVolOut }
                                onExited: {
                                    let match = initAppVolOut.text.trim().match(/Volume:\s+([\d\.]+)/);
                                    if (match && !appVolSlider.pressed) appVolSlider.value = parseFloat(match[1]);
                                }
                            }
                            
                            StyledSlider {
                                id: appVolSlider
                                Layout.fillWidth: true
                                from: 0; to: 1.0
                                onMoved: {
                                    if (modelData.audio) {
                                        appVolProc.command = ["wpctl", "set-volume", modelData.id.toString(), value.toString()];
                                        appVolProc.running = true;
                                    }
                                }
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
                    RowLayout {
                        spacing: 12
                        SoundRowIcon { icon: "\uea37" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Preferred codec"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                            Text { text: "WH-1000XM5 · connected"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: ["SBC", "AAC", "aptX HD"]
                        current: root.btCodec
                        onSelected: (val) => root.btCodec = val
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        SoundRowIcon { icon: "\uea4e" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Prefer quality over battery life"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: root.btQuality; onToggled: (val) => root.btQuality = val }
                }
            }

            // SOUND EFFECTS
            NCard {
                sectionTitle: "Sound Effects"

                NRow {
                    RowLayout {
                        spacing: 12
                        SoundRowIcon { icon: "\uebc5" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Interface sound effects"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                            Text { text: "Volume changes, connect/disconnect chimes"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: root.sfxInterface; onToggled: (val) => root.sfxInterface = val }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        SoundRowIcon { icon: "\uea35" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Notification sound"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: root.sfxNotification; onToggled: (val) => root.sfxNotification = val }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        SoundRowIcon { icon: "\ueb7e" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Effects volume"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 12
                        StyledSlider {
                            id: sfxSlider
                            Layout.preferredWidth: 220
                            from: 0; to: 1.0
                            value: root.sfxVolume
                            onMoved: root.sfxVolume = value
                        }
                        
                    }
                }
            }

            // ADVANCED
            NCard {
                sectionTitle: "Advanced"

                NRow {
                    RowLayout {
                        spacing: 12
                        SoundRowIcon { icon: "\uea16" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Sample rate"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: ["44.1kHz", "48kHz", "96kHz"]
                        current: root.advSampleRate
                        onSelected: (val) => root.advSampleRate = val
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        SoundRowIcon { icon: "\ueb8b" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Buffer size (quantum)"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                            Text { text: "Lower reduces latency, higher reduces crackle"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: ["256", "512", "1024"]
                        current: root.advBuffer
                        onSelected: (val) => root.advBuffer = val
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        SoundRowIcon { icon: "\ueb6c" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Auto-switch to newly connected devices"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: root.advAutoSwitch; onToggled: (val) => root.advAutoSwitch = val }
                }
            }

        }
    }
}
