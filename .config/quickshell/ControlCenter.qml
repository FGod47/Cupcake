import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "theme"

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
        color: Theme.colSurface
        radius: 10
        border.color: Theme.colOutline
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            // Volume Control
            RowLayout {
                spacing: 12
                
                Text {
                    text: volumeSlider.value === 0 ? " " : (volumeSlider.value < 50 ? " " : " ")
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
                    text: backlightSlider.value < 33 ? "󰃞 " : (backlightSlider.value < 66 ? "󰃟 " : "󰃠 ")
                    color: "white"
                    font.pixelSize: 16
                }

                Slider {
                    id: backlightSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: 0
                    
                    Timer {
                        id: controlCenterDdcTimer
                        interval: 150
                        repeat: false
                        property int targetValue: 100
                        onTriggered: Quickshell.execDetached(["brightnessctl", "set", Math.round(targetValue).toString() + "%"])
                    }
                    
                    onMoved: {
                        controlCenterDdcTimer.targetValue = value;
                        controlCenterDdcTimer.restart();
                        backlightLabel.text = Math.round(value) + "%"
                    }
                    onPressedChanged: {
                        if (!pressed) {
                            controlCenterDdcTimer.stop();
                            Quickshell.execDetached(["brightnessctl", "set", Math.round(value).toString() + "%"]);
                        }
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

    Component.onCompleted: {
        updateVolume.running = true
        updateBrightness.running = true
    }

    Timer {
        id: updateTimer
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
        stdout: StdioCollector { id: updateVolumeStdout }
        onExited: {
            if (!volumeSlider.pressed) {
                var vol = parseInt((updateVolumeStdout.text || "").trim())
                if (!isNaN(vol)) {
                    volumeSlider.value = vol
                    volumeLabel.text = vol + "%"
                }
            }
        }
    }

    Process {
        id: updateBrightness
        command: ["bash", "-c", "brightnessctl -m | head -n1 | cut -d, -f4 | tr -d %"]
        stdout: StdioCollector { id: updateBrightnessStdout }
        onExited: {
            if (!backlightSlider.pressed) {
                let bright = parseInt((updateBrightnessStdout.text || "").trim());
                if (!isNaN(bright)) {
                    backlightSlider.value = bright
                    backlightLabel.text = bright + "%"
                }
            }
        }
    }
}
