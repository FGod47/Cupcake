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

    readonly property real barW: bar.width > 0 ? bar.width - 16 : 1164
    readonly property real barX: 8
    readonly property real startW: 160
    readonly property real startX: (bar.width > 0 ? bar.width : 1180) / 2 - 80
    readonly property real midY: 6

    // ─────────────────────────────────────────────────────
    //  SPRINGY MORPHING BAR (Expands seamlessly with continuous spring curve)
    // ─────────────────────────────────────────────────────
    Rectangle {
        id: solidBar
        y: bar.midY
        x: bar.startX
        width: bar.startW
        height: 34
        radius: 17
        color: Theme.colPrimary
        clip: true

        // Top glass highlight line
        Rectangle {
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: 4; anchors.rightMargin: 4
            height: 1; radius: 1
            color: Qt.rgba(1, 1, 1, 0.12)
        }

        // 1. Initial Arch Pill Label (Arch Logo + Name)
        Row {
            id: archHeader
            anchors.centerIn: parent
            spacing: 8
            opacity: 1.0
            visible: opacity > 0

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "\uf303"
                color: Theme.colOnPrimary
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: Theme.defaultFontSize + 1
                font.weight: Theme.defaultFontWeight
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Arch"
                color: Theme.colOnPrimary
                font.family: Theme.defaultFontFamily
                font.pixelSize: Theme.defaultFontSize
                font.weight: Theme.defaultFontWeight
            }
        }

        // 2. Solid Bar Modules (smoothly crossfades in parallel with spring expansion)
        RowLayout {
            id: contentLayout
            anchors.fill: parent
            anchors.leftMargin: 14; anchors.rightMargin: 14
            spacing: 0
            opacity: 0

            // ── LEFT: Workspaces + Window title ────────
            Row {
                spacing: 8
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

                Rectangle { width: 1; height: 14; color: Qt.rgba(fg.r, fg.g, fg.b, 0.15); anchors.verticalCenter: parent.verticalCenter; visible: windowTitle.visible }

                Text {
                    id: windowTitle
                    anchors.verticalCenter: parent.verticalCenter
                    text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
                    color: Qt.rgba(fg.r, fg.g, fg.b, 0.75)
                    font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                    elide: Text.ElideRight; maximumLineCount: 1; width: Math.min(implicitWidth, 220)
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
                spacing: 12; Layout.alignment: Qt.AlignVCenter

                Row { spacing: 5; anchors.verticalCenter: parent.verticalCenter; visible: isWifi || isWired
                    Text { text: isWifi ? "\ueb52" : "\uebd9"; font.family: fontName; font.pixelSize: 13; color: fg; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: netStr; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight; color: Qt.rgba(fg.r, fg.g, fg.b, 0.8); anchors.verticalCenter: parent.verticalCenter }
                }
                Rectangle { width: 1; height: 14; color: Qt.rgba(fg.r, fg.g, fg.b, 0.15); anchors.verticalCenter: parent.verticalCenter }
                Row { spacing: 5; anchors.verticalCenter: parent.verticalCenter
                    Text { text: "\ueaf8"; font.family: fontName; font.pixelSize: 13; color: fg }
                    Text { text: tempStr + "°"; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight; color: Qt.rgba(fg.r, fg.g, fg.b, 0.8) }
                }
                Row { spacing: 5; anchors.verticalCenter: parent.verticalCenter
                    Text { text: "\ueba8"; font.family: fontName; font.pixelSize: 13; color: fg }
                    Text { text: ramStr + "G"; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight; color: Qt.rgba(fg.r, fg.g, fg.b, 0.8) }
                }
                Row { spacing: 5; anchors.verticalCenter: parent.verticalCenter
                    Text { text: "\ueb0d"; font.family: fontName; font.pixelSize: 13; color: fg }
                    Text { text: cpuStr + "%"; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight; color: Qt.rgba(fg.r, fg.g, fg.b, 0.8) }
                }
                Rectangle { width: 1; height: 14; color: Qt.rgba(fg.r, fg.g, fg.b, 0.15); anchors.verticalCenter: parent.verticalCenter }
                Row { spacing: 5; anchors.verticalCenter: parent.verticalCenter
                    Text { text: parseInt(volStr) === 0 ? "\uea9c" : (parseInt(volStr) < 50 ? "\uea9d" : "\uea9e"); font.family: fontName; font.pixelSize: 13; color: fg }
                    Text { text: volStr + "%"; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight; color: Qt.rgba(fg.r, fg.g, fg.b, 0.8) }
                }
                Row { spacing: 5; anchors.verticalCenter: parent.verticalCenter
                    Text { text: "\uea38"; font.family: fontName; font.pixelSize: 13; color: fg }
                    Text { text: batStr + "%"; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Theme.defaultFontWeight; color: Qt.rgba(fg.r, fg.g, fg.b, 0.8) }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────
    //  CONTINUOUS PARALLEL SPRING MORPH ANIMATION
    // ─────────────────────────────────────────────────────
    ParallelAnimation {
        id: expandAnim
        running: false

        // 1. Springy horizontal geometry expansion
        NumberAnimation {
            target: solidBar
            property: "x"
            from: bar.startX
            to: bar.barX
            duration: 560
            easing.type: Easing.OutBack
            easing.overshoot: 0.5
        }
        NumberAnimation {
            target: solidBar
            property: "width"
            from: bar.startW
            to: bar.barW
            duration: 560
            easing.type: Easing.OutBack
            easing.overshoot: 0.5
        }

        // 2. Smooth color transition from accent primary to surface pill
        ColorAnimation {
            target: solidBar
            property: "color"
            from: Theme.colPrimary
            to: bar.pillColor
            duration: 460
            easing.type: Easing.OutCubic
        }

        // 3. Fade out Arch logo header as expansion begins
        NumberAnimation {
            target: archHeader
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: 220
            easing.type: Easing.OutQuad
        }

        // 4. Smoothly blend in new bar contents in parallel during the spring motion
        NumberAnimation {
            target: contentLayout
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 440
            easing.type: Easing.InOutCubic
        }
    }

    function resetToArchPill() {
        expandAnim.stop();
        solidBar.x = bar.startX;
        solidBar.width = bar.startW;
        solidBar.color = Theme.colPrimary;
        archHeader.opacity = 1.0;
        contentLayout.opacity = 0.0;
    }

    onVisibleChanged: {
        if (visible) {
            resetToArchPill();
            expandAnim.restart();
        }
    }

    Component.onCompleted: {
        if (visible) {
            resetToArchPill();
            expandAnim.start();
        }
    }

    // ─────────────────────────────────────────────────────
    //  BACKGROUND DATA POLLING
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
