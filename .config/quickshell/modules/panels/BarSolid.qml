import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../../theme"
import "../common"
import "../settings"
import Quickshell.Services.Mpris

PanelWindow {
    id: bar
    property string cpuTextVal: "33"
    property string ramTextVal: "3.0"
    property string tempTextVal: "53"
    property string volTextVal: "70"
    property string briTextVal: "50"
    property string batTextVal: "100"
    property bool isDestroying: false
    Component.onDestruction: isDestroying = true
    anchors {
        top: true
        left: true
        right: true
    }
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 46

    property var modelData
    screen: modelData
    
    color: "transparent"
    implicitHeight: 46

    HyprlandFocusGrab {
        windows: [bar]
        active: globalState.settingsOpen || globalState.powerMenuOpen
    }

    SystemClock { id: timeClock; precision: SystemClock.Minutes }
    
    // Ambient blur mask
    mask: normalMask
    Region {
        id: normalMask
        Region { item: auroraBar }
    }

    // ==========================================
    // AURORA BAR
    // ==========================================
    Rectangle {
        id: auroraBar
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        height: 34
        width: rowContainer.implicitWidth + 12
        radius: 17
        
        // Solid fallback
        color: Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, 0.4)

        // Linear gradient background
        LinearGradient {
            anchors.fill: parent
            source: parent
            start: Qt.point(0, 0)
            end: Qt.point(parent.width, parent.height)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(232/255, 163/255, 194/255, 0.55) }
                GradientStop { position: 0.3; color: Qt.rgba(182/255, 143/255, 216/255, 0.50) }
                GradientStop { position: 0.62; color: Qt.rgba(111/255, 143/208, 208/255, 0.48) }
                GradientStop { position: 1.0; color: Qt.rgba(86/255, 194/255, 201/255, 0.50) }
            }
        }
        
        // Inner borders
        Rectangle {
            anchors.fill: parent
            radius: 17
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.14)
            border.width: 1
        }
        
        RowLayout {
            id: rowContainer
            anchors.centerIn: parent
            spacing: 14
            
            // GROUP 1: Clock & Workspaces
            RowLayout {
                spacing: 6
                

                
                // Clock
                Text {
                    text: Qt.formatDateTime(timeClock.date, "h:mm ap")
                    font.family: "JetBrains Mono"
                    font.weight: Font.Medium
                    font.pixelSize: 12
                    color: Qt.rgba(1,1,1,0.94)
                    Layout.alignment: Qt.AlignVCenter
                }
                
                // Workspace Badges
                Row {
                    spacing: 3
                    Layout.leftMargin: 4
                    Repeater {
                        model: 5
                        delegate: Rectangle {
                            property int wsId: index + 1
                            property bool active: Hyprland.focusedWorkspace ? (Hyprland.focusedWorkspace.id === wsId) : (wsId === 1)
                            
                            width: 14
                            height: 14
                            radius: 5
                            color: active ? Qt.rgba(1,1,1,0.85) : Qt.rgba(1,1,1,0.14)
                            
                            Text {
                                anchors.centerIn: parent
                                text: wsId
                                font.family: "JetBrains Mono"
                                font.weight: Font.DemiBold
                                font.pixelSize: 9
                                color: active ? "#3a2a4a" : Qt.rgba(1,1,1,0.62)
                            }
                        }
                    }
                }
            }
            
            // DIVIDER
            Rectangle { width: 1; height: 16; color: Qt.rgba(1,1,1,0.16) }
            
            // GROUP 2: Hardware
            RowLayout {
                spacing: 14
                
                // Temp
                RowLayout {
                    spacing: 4
                    Text { text: ""; font.family: "JetBrains Mono Nerd Font"; color: Qt.rgba(1,1,1,0.92); font.pixelSize: 13 }
                    Text { id: tempVal; text: bar.tempTextVal; font.family: "Inter"; font.weight: Font.Medium; color: Qt.rgba(1,1,1,0.94); font.pixelSize: 12 }
                    Text { text: "°C"; font.family: "Inter"; color: Qt.rgba(1,1,1,0.62); font.pixelSize: 12 }
                }
                
                // RAM
                RowLayout {
                    spacing: 4
                    Text { text: ""; font.family: "JetBrains Mono Nerd Font"; color: Qt.rgba(1,1,1,0.92); font.pixelSize: 13 }
                    Text { id: ramVal; text: bar.ramTextVal; font.family: "Inter"; font.weight: Font.Medium; color: Qt.rgba(1,1,1,0.94); font.pixelSize: 12 }
                    Text { text: "GiB"; font.family: "Inter"; color: Qt.rgba(1,1,1,0.62); font.pixelSize: 12 }
                }
                
                // CPU
                RowLayout {
                    spacing: 4
                    Text { text: ""; font.family: "JetBrains Mono Nerd Font"; color: Qt.rgba(1,1,1,0.92); font.pixelSize: 13 }
                    Text { id: cpuVal; text: bar.cpuTextVal; font.family: "Inter"; font.weight: Font.Medium; color: Qt.rgba(1,1,1,0.94); font.pixelSize: 12 }
                    Text { text: "%"; font.family: "Inter"; color: Qt.rgba(1,1,1,0.62); font.pixelSize: 12 }
                }
            }
            
            // CENTER: Date
            Item { width: 24 } // Spacer
            Text {
                text: Qt.formatDateTime(timeClock.date, "ddd dd MM yyyy")
                font.family: "Inter"
                font.weight: Font.Medium
                font.pixelSize: 12
                color: Qt.rgba(1,1,1,0.94)
            }
            Item { width: 24 } // Spacer
            
            // DIVIDER
            Rectangle { width: 1; height: 16; color: Qt.rgba(1,1,1,0.16) }
            
            // GROUP 3: Controls
            RowLayout {
                spacing: 14
                
                // Volume
                RowLayout {
                    spacing: 4
                    Text { text: ""; font.family: "JetBrains Mono Nerd Font"; color: Qt.rgba(1,1,1,0.92); font.pixelSize: 13 }
                    Text { id: volVal; text: bar.volTextVal; font.family: "Inter"; font.weight: Font.Medium; color: Qt.rgba(1,1,1,0.94); font.pixelSize: 12 }
                    Text { text: "%"; font.family: "Inter"; color: Qt.rgba(1,1,1,0.62); font.pixelSize: 12 }
                }
                
                // Brightness
                RowLayout {
                    spacing: 4
                    Text { text: ""; font.family: "JetBrains Mono Nerd Font"; color: Qt.rgba(1,1,1,0.92); font.pixelSize: 13 }
                    Text { id: briVal; text: bar.briTextVal; font.family: "Inter"; font.weight: Font.Medium; color: Qt.rgba(1,1,1,0.94); font.pixelSize: 12 }
                    Text { text: "%"; font.family: "Inter"; color: Qt.rgba(1,1,1,0.62); font.pixelSize: 12 }
                }
                
                // Battery
                RowLayout {
                    spacing: 4
                    Text { text: ""; font.family: "JetBrains Mono Nerd Font"; color: Qt.rgba(1,1,1,0.92); font.pixelSize: 13 }
                    Rectangle {
                        width: 22
                        height: 5
                        radius: 3
                        color: Qt.rgba(1,1,1,0.18)
                        clip: true
                        Rectangle {
                            width: parent.width * (parseInt(batVal.text) / 100.0)
                            height: parent.height
                            radius: 3
                            LinearGradient {
                                anchors.fill: parent
                                source: parent
                                start: Qt.point(0,0)
                                end: Qt.point(parent.width, 0)
                                gradient: Gradient {
                                    GradientStop { position: 0; color: "#56c2c9" } // teal
                                    GradientStop { position: 1; color: "#e8a3c2" } // rose
                                }
                            }
                        }
                    }
                    Text { id: batVal; text: bar.batTextVal; font.family: "Inter"; font.weight: Font.Medium; color: Qt.rgba(1,1,1,0.94); font.pixelSize: 12 }
                    Text { text: "%"; font.family: "Inter"; color: Qt.rgba(1,1,1,0.62); font.pixelSize: 12 }
                }
            }
            
            // DIVIDER
            Rectangle { width: 1; height: 16; color: Qt.rgba(1,1,1,0.16) }
            
            // GROUP 4: Power Cap
            RowLayout {
                spacing: 10
                Layout.rightMargin: 4
                
                // Notification Bell
                Rectangle {
                    width: 22; height: 22; radius: 11
                    color: Qt.rgba(1,1,1,0.10)
                    Text { anchors.centerIn: parent; text: ""; font.family: "JetBrains Mono Nerd Font"; color: Qt.rgba(1,1,1,0.94); font.pixelSize: 12 }
                    // Dot
                    Rectangle {
                        width: 5; height: 5; radius: 2.5
                        color: "#e8a3c2"
                        x: 16; y: 1
                    }
                }
                
                // Settings
                Rectangle {
                    width: 22; height: 22; radius: 11
                    color: Qt.rgba(1,1,1,0.10)
                    Text { anchors.centerIn: parent; text: ""; font.family: "JetBrains Mono Nerd Font"; color: Qt.rgba(1,1,1,0.94); font.pixelSize: 12 }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: globalState.settingsOpen = !globalState.settingsOpen
                    }
                }
                
                // Power
                Rectangle {
                    width: 22; height: 22; radius: 11
                    color: Qt.rgba(1,1,1,0.16)
                    Text { anchors.centerIn: parent; text: ""; font.family: "JetBrains Mono Nerd Font"; color: Qt.rgba(1,1,1,0.94); font.pixelSize: 13 }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: globalState.powerMenuOpen = true
                    }
                }
            }
        }
    }
    
    // ==========================================
    // PROCESSES FOR DATA
    // ==========================================
    
    // CPU
    Process {
        id: cpuProc
        command: ["bash", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (bar.isDestroying) return;
                if (text && text.trim() !== "") {
                    let val = parseFloat(text.trim());
                    bar.cpuTextVal = isNaN(val) ? "0" : Math.round(val).toString();
                }
            }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: cpuProc.running = true }

    // RAM
    Process {
        id: ramProc
        command: ["bash", "-c", "free -m | awk '/Mem:/ {printf \"%.1f\", $3/1024}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { if (text) bar.ramTextVal = text.trim() }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: ramProc.running = true }

    // TEMP
    Process {
        id: tempProc
        command: ["bash", "-c", "sensors 2>/dev/null | grep -E 'Tctl|Package id 0' | awk '{print $3}' | sed 's/+//;s/°C//' | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (bar.isDestroying) return;
                if (text && text.trim() !== "") {
                    let val = parseFloat(text.trim());
                    bar.tempTextVal = isNaN(val) ? "0" : Math.round(val).toString();
                }
            }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: tempProc.running = true }

    // VOL
    Process {
        id: volProc
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { if (text) bar.volTextVal = text.trim() }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: volProc.running = true }

    // BRI
    Process {
        id: briProc
        command: ["bash", "-c", "ddcutil getvcp 10 --bus 5 2>/dev/null | awk -F'current value = ' '{print $2}' | awk '{print $1}' | tr -d ','"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { if (text) bar.briTextVal = text.trim() }
        }
    }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: briProc.running = true }

    // BAT
    Process {
        id: batProc
        command: ["bash", "-c", "upower -i $(upower -e | grep BAT) 2>/dev/null | grep percentage | awk '{print $2}' | tr -d '%'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { if (text && text.trim() !== "") bar.batTextVal = text.trim(); else bar.batTextVal = "100" }
        }
    }
    Timer { interval: 10000; running: true; repeat: true; onTriggered: batProc.running = true }
}
