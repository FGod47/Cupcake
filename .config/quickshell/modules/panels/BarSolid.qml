import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
import QtQuick.Controls
import "../../theme"
import "../common"
import Quickshell.Services.Mpris

PanelWindow {
    id: bar
    property var modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: 46
    height: 46
    color: "transparent"

    // Data properties (same as Bar.qml)
    property color bg: Theme.colSurface
    property color fg: Theme.colOnSurface
    property string fontName: "tabler-icons"
    property real barOpacity: root.barOpacity

    // Hardware data states
    property string cpuStr: "0"
    property string ramStr: "0"
    property string tempStr: "0"
    property string volStr: "0"
    property string briStr: "50"
    property string batStr: "100"
    property string netStr: "0 KB/s"
    property bool isWifi: false
    property bool isWired: false
    property int signalPct: 0

    // Active player
    property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool hasPlayer: activePlayer !== null

    SystemClock { id: timeClock; precision: SystemClock.Minutes }

    // ──────────────────────────────────────────────
    //  SINGLE UNIFIED BAR
    // ──────────────────────────────────────────────
    Rectangle {
        id: solidBar
        anchors.centerIn: parent
        width: parent.width - 16   // small 8px margin each side
        height: 34
        radius: 17
        color: Qt.rgba(bg.r, bg.g, bg.b, root.barOpacity)

        // Thin glass top-edge highlight
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            height: 1
            radius: 1
            color: Qt.rgba(1, 1, 1, 0.12)
        }

        // ── ENTRY / EXIT ANIMATION ─────────────────
        opacity: 0
        scale: 0.92
        Component.onCompleted: {
            fadeIn.start()
        }

        NumberAnimation {
            id: fadeIn
            target: solidBar
            properties: "opacity,scale"
            to: 1.0
            duration: 400
            easing.type: Easing.OutBack
            easing.overshoot: 0.6
        }

        // ── THREE-COLUMN LAYOUT ────────────────────
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 0

            // ── LEFT: Workspaces + active window title ──
            Row {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                // Workspace dots
                Row {
                    spacing: 0
                    anchors.verticalCenter: parent.verticalCenter

                    // Active workspace highlight bubble
                    Item {
                        width: 5 * 26
                        height: 34
                        clip: true

                        Rectangle {
                            id: wsBubble
                            width: 20; height: 20; radius: 10
                            color: Theme.colPrimary
                            property int activeWs: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
                            property int validIndex: Math.max(0, Math.min(activeWs - 1, 4))
                            x: 3 + 26 * validIndex
                            y: 7
                            Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0
                            Repeater {
                                model: 5
                                delegate: Item {
                                    width: 26; height: 34
                                    property int wsId: index + 1
                                    property bool isFocused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
                                    property bool isOccupied: isFocused || Hyprland.workspaces.values.some(ws => ws.id === wsId)
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: isFocused ? 5 : (isOccupied ? 7 : 5)
                                        height: width; radius: width / 2
                                        color: isFocused ? Theme.colOnPrimary : (isOccupied ? fg : Qt.rgba(fg.r, fg.g, fg.b, 0.35))
                                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Hyprland.dispatch("workspace " + wsId)
                                    }
                                }
                            }
                        }
                    }
                }

                // Thin separator
                Rectangle { width: 1; height: 16; color: Qt.rgba(fg.r, fg.g, fg.b, 0.15); anchors.verticalCenter: parent.verticalCenter }

                // Active window title
                Text {
                    id: windowTitle
                    anchors.verticalCenter: parent.verticalCenter
                    text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
                    color: Qt.rgba(fg.r, fg.g, fg.b, 0.75)
                    font.family: Theme.defaultFontFamily
                    font.weight: Theme.defaultFontWeight
                    font.pixelSize: Theme.defaultFontSize
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    width: Math.min(implicitWidth, 200)
                    visible: text !== ""
                }
            }

            // ── CENTER: Clock ──────────────────────────
            Item {
                Layout.fillWidth: true
                height: 34
                Text {
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(timeClock.date, "MMM dd  •  h:mm ap")
                    color: fg
                    font.family: Theme.defaultFontFamily
                    font.weight: Font.Medium
                    font.pixelSize: Theme.defaultFontSize
                }
            }

            // ── RIGHT: System stats ────────────────────
            Row {
                spacing: 10
                Layout.alignment: Qt.AlignVCenter

                // Network speed
                Row {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter
                    visible: isWifi || isWired
                    Text { text: isWifi ? "" : ""; font.family: fontName; font.pixelSize: 13; color: fg; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: netStr; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight; color: Qt.rgba(fg.r, fg.g, fg.b, 0.8); anchors.verticalCenter: parent.verticalCenter }
                }

                // Separator
                Rectangle { width: 1; height: 14; color: Qt.rgba(fg.r, fg.g, fg.b, 0.15); anchors.verticalCenter: parent.verticalCenter }

                // Temp
                Row { spacing: 3; anchors.verticalCenter: parent.verticalCenter
                    Text { text: ""; font.family: fontName; font.pixelSize: 13; color: fg }
                    Text { text: tempStr + "°"; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight; color: Qt.rgba(fg.r, fg.g, fg.b, 0.8) }
                }
                // RAM
                Row { spacing: 3; anchors.verticalCenter: parent.verticalCenter
                    Text { text: ""; font.family: fontName; font.pixelSize: 13; color: fg }
                    Text { text: ramStr + "G"; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight; color: Qt.rgba(fg.r, fg.g, fg.b, 0.8) }
                }
                // CPU
                Row { spacing: 3; anchors.verticalCenter: parent.verticalCenter
                    Text { text: ""; font.family: fontName; font.pixelSize: 13; color: fg }
                    Text { text: cpuStr + "%"; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight; color: Qt.rgba(fg.r, fg.g, fg.b, 0.8) }
                }

                // Separator
                Rectangle { width: 1; height: 14; color: Qt.rgba(fg.r, fg.g, fg.b, 0.15); anchors.verticalCenter: parent.verticalCenter }

                // Volume
                Row { spacing: 3; anchors.verticalCenter: parent.verticalCenter
                    Text { text: parseInt(volStr) === 0 ? "" : (parseInt(volStr) < 50 ? "" : ""); font.family: fontName; font.pixelSize: 13; color: fg }
                    Text { text: volStr + "%"; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight; color: Qt.rgba(fg.r, fg.g, fg.b, 0.8) }
                }
                // Battery
                Row { spacing: 3; anchors.verticalCenter: parent.verticalCenter
                    Text { text: ""; font.family: fontName; font.pixelSize: 13; color: fg }
                    Text { text: batStr + "%"; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight; color: Qt.rgba(fg.r, fg.g, fg.b, 0.8) }
                }
            }
        }
    }

    // ──────────────────────────────────────────────
    //  BACKGROUND DATA POLLING (same scripts as Bar.qml)
    // ──────────────────────────────────────────────

    // CPU
    Process {
        id: cpuProc
        command: ["bash", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print int($2+$4)}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { let v = parseFloat(text); if (!isNaN(v)) bar.cpuStr = Math.round(v).toString() }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: cpuProc.running = true }

    // RAM
    Process {
        id: ramProc
        command: ["bash", "-c", "free -m | awk '/Mem:/ {printf \"%.1f\", $3/1024}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { if (text) bar.ramStr = text.trim() }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: ramProc.running = true }

    // Temp
    Process {
        id: tempProc
        command: ["bash", "-c", "sensors 2>/dev/null | awk '/^(Tctl|Package id 0|CPU Temperature)/{print int($2); exit}' | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { let v = parseFloat(text); if (!isNaN(v)) bar.tempStr = Math.round(v).toString() }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: tempProc.running = true }

    // Volume
    Process {
        id: volProc
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { if (text) bar.volStr = text.trim() }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: volProc.running = true }

    // Battery
    Process {
        id: batProc
        command: ["bash", "-c", "upower -i $(upower -e | grep BAT) 2>/dev/null | grep percentage | awk '{print $2}' | tr -d '%'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { if (text && text.trim() !== "") bar.batStr = text.trim(); else bar.batStr = "100" }
        }
    }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: batProc.running = true }

    // Network
    Process {
        id: netProc
        command: ["bash", "-c", "cat /proc/net/dev"]
        running: true
        property real lastRx: 0
        property real lastTx: 0
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return
                const lines = text.trim().split("\n")
                let totalRx = 0, totalTx = 0
                for (let i = 2; i < lines.length; i++) {
                    const parts = lines[i].trim().split(/\s+/)
                    if (parts.length >= 10 && (parts[0].startsWith("en") || parts[0].startsWith("wl") || parts[0].startsWith("eth"))) {
                        totalRx += parseInt(parts[1]) || 0
                        totalTx += parseInt(parts[9]) || 0
                    }
                }
                if (netProc.lastRx > 0) {
                    let diff = (totalRx - netProc.lastRx) + (totalTx - netProc.lastTx)
                    if (diff < 0) diff = 0
                    bar.netStr = diff >= 1048576 ? (diff/1048576).toFixed(1) + " MB/s" : Math.round(diff/1024) + " KB/s"
                }
                netProc.lastRx = totalRx
                netProc.lastTx = totalTx
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: netProc.running = true }

    // Wifi/Wired detection
    Process {
        id: netTypeProc
        command: ["bash", "-c", "nmcli -t -f TYPE,STATE d | grep 'connected'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                bar.isWifi = text.includes("wifi")
                bar.isWired = text.includes("ethernet")
            }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: netTypeProc.running = true }
}
