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

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        leftPadding: 32; rightPadding: 32; topPadding: 32; bottomPadding: 32
        
        ColumnLayout {
            width: parent.width
            spacing: 24

            Text {
                text: "Sound Settings"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 24
                font.weight: Font.Bold
                color: Theme.colOnSurface
            }
            
            SettingsCard {
                title: "Output (Speakers)"
                description: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.name : "Adjust the master volume for your system."
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    
                    Text { 
                        text: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted) ? "\ueb7f" : "\ueb7e" 
                        font.family: "tabler-icons"
                        font.pixelSize: 24
                        color: Theme.colPrimary 
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                                    Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted
                                }
                            }
                        }
                    }
                    
                    StyledSlider {
                        id: outSlider
                        Layout.fillWidth: true
                        from: 0; to: 1.0
                        value: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) ? Pipewire.defaultAudioSink.audio.volume : 0
                        onMoved: {
                            if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                                Pipewire.defaultAudioSink.audio.volume = value
                            }
                        }
                    }
                    
                    Text {
                        text: Math.round(outSlider.value * 100) + "%"
                        font.family: Theme.monoFontFamily
                        font.pixelSize: 14
                        color: Theme.colOnSurfaceVariant
                        Layout.preferredWidth: 40
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
            
            SettingsCard {
                title: "Input (Microphone)"
                description: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.name : "Adjust the microphone recording volume."
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    
                    Text { 
                        text: (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio && Pipewire.defaultAudioSource.audio.muted) ? "\ueaf0" : "\ueaef" 
                        font.family: "tabler-icons"
                        font.pixelSize: 24
                        color: Theme.colPrimary 
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) {
                                    Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted
                                }
                            }
                        }
                    }
                    
                    StyledSlider {
                        id: inSlider
                        Layout.fillWidth: true
                        from: 0; to: 1.0
                        value: (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) ? Pipewire.defaultAudioSource.audio.volume : 0
                        onMoved: {
                            if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) {
                                Pipewire.defaultAudioSource.audio.volume = value
                            }
                        }
                    }
                    
                    Text {
                        text: Math.round(inSlider.value * 100) + "%"
                        font.family: Theme.monoFontFamily
                        font.pixelSize: 14
                        color: Theme.colOnSurfaceVariant
                        Layout.preferredWidth: 40
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            SettingsCard {
                title: "App Mixer"
                description: "Adjust volume for individual applications."
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    
                    Repeater {
                        model: Pipewire.nodes
                        delegate: RowLayout {
                            visible: typeof modelData !== "undefined" && modelData.isStream && typeof modelData.audio !== "undefined" && modelData.audio !== null
                            Layout.fillWidth: true
                            spacing: 16
                            
                            function getIcon(name) {
                                if (!name) return "\ueb7e";
                                let n = name.toLowerCase();
                                if (n.includes("chrome") || n.includes("firefox") || n.includes("brave") || n.includes("edge")) return "\uebb7";
                                if (n.includes("spotify") || n.includes("music")) return "\ueafc";
                                if (n.includes("discord") || n.includes("teamspeak")) return "\uece3";
                                if (n.includes("steam")) return "\ued6f";
                                if (n.includes("mpv") || n.includes("vlc") || n.includes("player")) return "\ueafa";
                                if (n.includes("obs")) return "\ued22";
                                return "\ueb7e";
                            }
                            
                            Text { 
                                text: parent.visible ? getIcon(modelData.name) : ""
                                font.family: "tabler-icons"
                                font.pixelSize: 20
                                color: Theme.colPrimary 
                            }
                            
                            Text {
                                text: parent.visible ? modelData.name : ""
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 13
                                color: Theme.colOnSurface
                                Layout.preferredWidth: 120
                                elide: Text.ElideRight
                            }
                            
                            StyledSlider {
                                Layout.fillWidth: true
                                from: 0; to: 1.0
                                value: parent.visible ? modelData.audio.volume : 0
                                onMoved: {
                                    if (parent.visible) modelData.audio.volume = value
                                }
                            }
                            
                            Text {
                                text: parent.visible ? Math.round(modelData.audio.volume * 100) + "%" : ""
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 14
                                color: Theme.colOnSurfaceVariant
                                Layout.preferredWidth: 40
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }

            SettingsCard {
                title: "Output Devices"
                description: "Select and configure your speakers/headphones."
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    
                    Repeater {
                        model: Pipewire.nodes
                        delegate: RowLayout {
                            visible: typeof modelData !== "undefined" && modelData.isSink && typeof modelData.audio !== "undefined" && modelData.audio !== null
                            Layout.fillWidth: true
                            spacing: 16
                            
                            property bool isDefault: visible && Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.id === modelData.id
                            
                            Text { 
                                text: isDefault ? "\uea60" : "\uea5f" // circle-check or circle
                                font.family: "tabler-icons"
                                font.pixelSize: 20
                                color: isDefault ? Theme.colPrimary : Theme.colOnSurfaceVariant
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (parent.parent.visible) Quickshell.execDetached(["wpctl", "set-default", modelData.id])
                                    }
                                }
                            }
                            
                            Text {
                                text: parent.visible ? modelData.name : ""
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 13
                                color: isDefault ? Theme.colOnSurface : Theme.colOnSurfaceVariant
                                Layout.preferredWidth: 160
                                elide: Text.ElideRight
                            }
                            
                            StyledSlider {
                                Layout.fillWidth: true
                                from: 0; to: 1.0
                                value: parent.visible ? modelData.audio.volume : 0
                                onMoved: {
                                    if (parent.visible) modelData.audio.volume = value
                                }
                            }
                            
                            Text {
                                text: parent.visible ? Math.round(modelData.audio.volume * 100) + "%" : ""
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 14
                                color: Theme.colOnSurfaceVariant
                                Layout.preferredWidth: 40
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }

            SettingsCard {
                title: "Input Devices"
                description: "Select and configure your microphones."
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    
                    Repeater {
                        model: Pipewire.nodes
                        delegate: RowLayout {
                            visible: typeof modelData !== "undefined" && modelData.isSource && typeof modelData.audio !== "undefined" && modelData.audio !== null
                            Layout.fillWidth: true
                            spacing: 16
                            
                            property bool isDefault: visible && Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.id === modelData.id
                            
                            Text { 
                                text: isDefault ? "\uea60" : "\uea5f" 
                                font.family: "tabler-icons"
                                font.pixelSize: 20
                                color: isDefault ? Theme.colPrimary : Theme.colOnSurfaceVariant
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (parent.parent.visible) Quickshell.execDetached(["wpctl", "set-default", modelData.id])
                                    }
                                }
                            }
                            
                            Text {
                                text: parent.visible ? modelData.name : ""
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 13
                                color: isDefault ? Theme.colOnSurface : Theme.colOnSurfaceVariant
                                Layout.preferredWidth: 160
                                elide: Text.ElideRight
                            }
                            
                            StyledSlider {
                                Layout.fillWidth: true
                                from: 0; to: 1.0
                                value: parent.visible ? modelData.audio.volume : 0
                                onMoved: {
                                    if (parent.visible) modelData.audio.volume = value
                                }
                            }
                            
                            Text {
                                text: parent.visible ? Math.round(modelData.audio.volume * 100) + "%" : ""
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 14
                                color: Theme.colOnSurfaceVariant
                                Layout.preferredWidth: 40
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }
        }
    }
}
