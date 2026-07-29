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

    anchors { top: true; left: true; right: true }
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: 46
    height: 46
    color: "transparent"

    // Shared styling
    property color bg: Theme.colSurface
    property color fg: Theme.colOnSurface
    property string fontName: "tabler-icons"
    property color pillColor: Qt.rgba(bg.r, bg.g, bg.b, root.barOpacity)

    // Hardware data
    property string cpuStr: "0"
    property string ramStr: "0"
    property string tempStr: "0"
    property string volStr: "0"
    property string batStr: "100"
    property string netStr: "0 KB/s"
    property bool isWifi: false
    property bool isWired: false

    property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    SystemClock { id: timeClock; precision: SystemClock.Minutes }

    // ─────────────────────────────────────────────────────
    //  THE ACTUAL UNIFIED BAR  (hidden until merge complete)
    // ─────────────────────────────────────────────────────
    Rectangle {
        id: solidBar
        anchors.centerIn: parent
        width: parent.width - 16
        height: 34
        radius: 17
        color: pillColor
        opacity: 0
        clip: true

        // Top glass highlight
        Rectangle {
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: 4; anchors.rightMargin: 4
            height: 1; radius: 1
            color: Qt.rgba(1, 1, 1, 0.10)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12; anchors.rightMargin: 12
            spacing: 0

            // ── LEFT: Workspaces + Window title ────────
            Row {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                Item {
                    width: 5 * 26; height: 34
                    Rectangle {
                        width: 20; height: 20; radius: 10
                        color: Theme.colPrimary
                        property int activeWs: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
                        property int validIndex: Math.max(0, Math.min(activeWs - 1, 4))
                        x: 3 + 26 * validIndex; y: 7
                        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        Repeater {
                            model: 5
                            delegate: Item {
                                width: 26; height: 34
                                property int wsId: index + 1
                                property bool isFocused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
                                property bool isOccupied: isFocused || Hyprland.workspaces.values.some(ws => ws.id === wsId)
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: isFocused ? 5 : (isOccupied ? 7 : 5); height: width; radius: width / 2
                                    color: isFocused ? Theme.colOnPrimary : (isOccupied ? fg : Qt.rgba(fg.r, fg.g, fg.b, 0.35))
                                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Hyprland.dispatch("workspace " + wsId) }
                            }
                        }
                    }
                }

                Rectangle { width: 1; height: 16; color: Qt.rgba(fg.r, fg.g, fg.b, 0.15); anchors.verticalCenter: parent.verticalCenter; visible: windowTitle.visible }

                Text {
                    id: windowTitle
                    anchors.verticalCenter: parent.verticalCenter
                    text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
                    color: Qt.rgba(fg.r, fg.g, fg.b, 0.75)
                    font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                    elide: Text.ElideRight; maximumLineCount: 1; width: Math.min(implicitWidth, 200)
                    visible: text !== ""
                }
            }

            // ── CENTER: Clock ───────────────────────────
            Item {
                Layout.fillWidth: true; height: 34
                Text {
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(timeClock.date, "MMM dd  •  h:mm ap")
                    color: fg; font.family: Theme.defaultFontFamily; font.weight: Font.Medium; font.pixelSize: Theme.defaultFontSize
                }
            }

            // ── RIGHT: System stats ─────────────────────
            Row {
                spacing: 10; Layout.alignment: Qt.AlignVCenter

                Row { spacing: 4; anchors.verticalCenter: parent.verticalCenter; visible: isWifi || isWired
                    Text { text: isWifi ? "" : ""; font.family: fontName; font.pixelSize: 13; color: fg; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: netStr; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight; color: Qt.rgba(fg.r, fg.g, fg.b, 0.8); anchors.verticalCenter: parent.verticalCenter }
                }
                Rectangle { width: 1; height: 14; color: Qt.rgba(fg.r, fg.g, fg.b, 0.15); anchors.verticalCenter: parent.verticalCenter }
                Row { spacing: 3; anchors.verticalCenter: parent.verticalCenter
                    Text { text: ""; font.family: fontName; font.pixelSize: 13; color: fg }
                    Text { text: tempStr + "°"; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight; color: Qt.rgba(fg.r, fg.g, fg.b, 0.8) }
                }
                Row { spacing: 3; anchors.verticalCenter: parent.verticalCenter
                    Text { text: ""; font.family: fontName; font.pixelSize: 13; color: fg }
                    Text { text: ramStr + "G"; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight; color: Qt.rgba(fg.r, fg.g, fg.b, 0.8) }
                }
                Row { spacing: 3; anchors.verticalCenter: parent.verticalCenter
                    Text { text: ""; font.family: fontName; font.pixelSize: 13; color: fg }
                    Text { text: cpuStr + "%"; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight; color: Qt.rgba(fg.r, fg.g, fg.b, 0.8) }
                }
                Rectangle { width: 1; height: 14; color: Qt.rgba(fg.r, fg.g, fg.b, 0.15); anchors.verticalCenter: parent.verticalCenter }
                Row { spacing: 3; anchors.verticalCenter: parent.verticalCenter
                    Text { text: parseInt(volStr) < 50 ? "" : ""; font.family: fontName; font.pixelSize: 13; color: fg }
                    Text { text: volStr + "%"; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight; color: Qt.rgba(fg.r, fg.g, fg.b, 0.8) }
                }
                Row { spacing: 3; anchors.verticalCenter: parent.verticalCenter
                    Text { text: ""; font.family: fontName; font.pixelSize: 13; color: fg }
                    Text { text: batStr + "%"; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight; color: Qt.rgba(fg.r, fg.g, fg.b, 0.8) }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────
    //  THREE PILL SHAPES  — appear then merge into the bar
    // ─────────────────────────────────────────────────────
    readonly property real barW: parent.width - 16   // == solidBar.width
    readonly property real barX: 8                   // == solidBar.x
    readonly property real midY: (bar.height - 34) / 2

    // LEFT pill  (workspaces area)
    Rectangle {
        id: segLeft
        y: bar.midY
        x: bar.barX
        width: Math.max(160, bar.barW * 0.17)
        height: 34; radius: 17
        color: bar.pillColor
        opacity: 0
    }

    // CENTER pill  (clock)
    Rectangle {
        id: segCenter
        y: bar.midY
        width: 178; height: 34; radius: 17
        color: bar.pillColor
        x: (bar.width - width) / 2
        opacity: 0
    }

    // RIGHT pill  (stats + controls)
    Rectangle {
        id: segRight
        y: bar.midY
        height: 34; radius: 17
        color: bar.pillColor
        property real rw: Math.max(300, bar.barW * 0.26)
        width: rw
        x: bar.barX + bar.barW - rw
        opacity: 0
    }

    // ─────────────────────────────────────────────────────
    //  MERGE ANIMATION SEQUENCE
    //  1. Pills pop in
    //  2. Brief pause so user sees them
    //  3. All three morph / slide together into one bar
    //  4. Content bar cross-fades in, pill overlays fade out
    // ─────────────────────────────────────────────────────
    SequentialAnimation {
        id: mergeAnim
        running: false

        // Step 1 — pills appear with a little scale-up pop
        ParallelAnimation {
            NumberAnimation { target: segLeft;   property: "opacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic }
            NumberAnimation { target: segCenter; property: "opacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic }
            NumberAnimation { target: segRight;  property: "opacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic }
        }

        // Step 2 — tiny hold so user perceives pills
        PauseAnimation { duration: 80 }

        // Step 3 — pills merge: stretch width, slide x to 8
        ParallelAnimation {
            // LEFT just stretches rightward (x stays at 8)
            NumberAnimation {
                target: segLeft; property: "width"
                to: bar.barW; duration: 480; easing.type: Easing.InOutCubic
            }
            // CENTER slides left AND stretches
            NumberAnimation {
                target: segCenter; property: "x"
                to: bar.barX; duration: 480; easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: segCenter; property: "width"
                to: bar.barW; duration: 480; easing.type: Easing.InOutCubic
            }
            // RIGHT slides left AND stretches
            NumberAnimation {
                target: segRight; property: "x"
                to: bar.barX; duration: 480; easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: segRight; property: "width"
                to: bar.barW; duration: 480; easing.type: Easing.InOutCubic
            }
        }

        // Step 4 — reveal content, dissolve pill overlays
        ParallelAnimation {
            NumberAnimation { target: solidBar;  property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: segLeft;   property: "opacity"; to: 0; duration: 220 }
            NumberAnimation { target: segCenter; property: "opacity"; to: 0; duration: 220 }
            NumberAnimation { target: segRight;  property: "opacity"; to: 0; duration: 220 }
        }
    }

    Component.onCompleted: mergeAnim.start()

    // ─────────────────────────────────────────────────────
    //  DATA POLLING
    // ─────────────────────────────────────────────────────
    Process {
        id: cpuProc; running: true
        command: ["bash", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print int($2+$4)}'"]
        stdout: StdioCollector { onStreamFinished: { let v = parseFloat(text); if (!isNaN(v)) bar.cpuStr = Math.round(v).toString() } }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: cpuProc.running = true }

    Process {
        id: ramProc; running: true
        command: ["bash", "-c", "free -m | awk '/Mem:/ {printf \"%.1f\", $3/1024}'"]
        stdout: StdioCollector { onStreamFinished: { if (text) bar.ramStr = text.trim() } }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: ramProc.running = true }

    Process {
        id: tempProc; running: true
        command: ["bash", "-c", "sensors 2>/dev/null | awk '/^(Tctl|Package id 0|CPU Temperature)/{print int($2); exit}'"]
        stdout: StdioCollector { onStreamFinished: { let v = parseFloat(text); if (!isNaN(v)) bar.tempStr = Math.round(v).toString() } }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: tempProc.running = true }

    Process {
        id: volProc; running: true
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}'"]
        stdout: StdioCollector { onStreamFinished: { if (text) bar.volStr = text.trim() } }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: volProc.running = true }

    Process {
        id: batProc; running: true
        command: ["bash", "-c", "upower -i $(upower -e | grep BAT) 2>/dev/null | grep percentage | awk '{print $2}' | tr -d '%'"]
        stdout: StdioCollector { onStreamFinished: { if (text && text.trim() !== "") bar.batStr = text.trim(); else bar.batStr = "100" } }
    }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: batProc.running = true }

    Process {
        id: netProc; running: true
        command: ["bash", "-c", "cat /proc/net/dev"]
        property real lastRx: 0; property real lastTx: 0
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return
                const lines = text.trim().split("\n")
                let rx = 0, tx = 0
                for (let i = 2; i < lines.length; i++) {
                    const p = lines[i].trim().split(/\s+/)
                    if (p.length >= 10 && (p[0].startsWith("en") || p[0].startsWith("wl") || p[0].startsWith("eth"))) {
                        rx += parseInt(p[1]) || 0; tx += parseInt(p[9]) || 0
                    }
                }
                if (netProc.lastRx > 0) {
                    let d = Math.max(0, (rx - netProc.lastRx) + (tx - netProc.lastTx))
                    bar.netStr = d >= 1048576 ? (d/1048576).toFixed(1) + " MB/s" : Math.round(d/1024) + " KB/s"
                }
                netProc.lastRx = rx; netProc.lastTx = tx
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: netProc.running = true }

    Process {
        id: netTypeProc; running: true
        command: ["bash", "-c", "nmcli -t -f TYPE,STATE d | grep 'connected'"]
        stdout: StdioCollector {
            onStreamFinished: { bar.isWifi = text.includes("wifi"); bar.isWired = text.includes("ethernet") }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: netTypeProc.running = true }
}
