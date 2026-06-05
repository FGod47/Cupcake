import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

PanelWindow {
    id: controlCenter
    visible: false

    anchors {
        top: true
        right: true
    }
    margins {
        top: 50
        right: 10
    }
    
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    width: 320
    height: 130

    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"
        radius: 10
        border.color: "#313244"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            // Volume Control
            RowLayout {
                spacing: 12
                
                Text {
                    text: " "
                    color: "white"
                    font.pixelSize: 16
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Quickshell.execDetached("pamixer -t")
                            updateVolume.running = true
                        }
                    }
                }

                Slider {
                    id: volumeSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: 0
                    onMoved: {
                        Quickshell.execDetached(`pamixer --set-volume ${Math.round(value)}`)
                        volumeLabel.text = Math.round(value) + "%"
                    }
                }

                Text {
                    id: volumeLabel
                    text: Math.round(volumeSlider.value) + "%"
                    color: "white"
                    Layout.minimumWidth: 40
                    horizontalAlignment: Text.AlignRight
                }
            }

            // Backlight Control
            RowLayout {
                spacing: 12
                
                Text {
                    text: "☀ "
                    color: "white"
                    font.pixelSize: 16
                }

                Slider {
                    id: backlightSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: 0
                    onMoved: {
                        Quickshell.execDetached(`brightnessctl s ${Math.round(value)}%`)
                        backlightLabel.text = Math.round(value) + "%"
                    }
                }

                Text {
                    id: backlightLabel
                    text: Math.round(backlightSlider.value) + "%"
                    color: "white"
                    Layout.minimumWidth: 40
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: controlCenter.visible
        repeat: true
        onTriggered: {
            updateVolume.running = true
            updateBrightness.running = true
        }
    }

    Process {
        id: updateVolume
        command: ["pamixer", "--get-volume"]
        stdout: StdioCollector {
            onStreamFinished: (data) => {
                if (!volumeSlider.pressed) {
                    var vol = parseInt(data)
                    if (!isNaN(vol)) {
                        volumeSlider.value = vol
                        volumeLabel.text = vol + "%"
                    }
                }
            }
        }
    }

    Process {
        id: updateBrightness
        command: ["sh", "-c", "brightnessctl -m | awk -F, '{print substr($4, 1, length($4)-1)}'"]
        stdout: StdioCollector {
            onStreamFinished: (data) => {
                if (!backlightSlider.pressed) {
                    var bright = parseInt(data)
                    if (!isNaN(bright)) {
                        backlightSlider.value = bright
                        backlightLabel.text = bright + "%"
                    }
                }
            }
        }
    }
}
