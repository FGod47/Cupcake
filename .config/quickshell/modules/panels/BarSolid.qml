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
    exclusiveZone: 40
    height: 40
    color: "transparent"
    mask: Region { item: solidBar }

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

    readonly property real screenW: bar.screen ? bar.screen.width : (bar.width > 0 ? bar.width : 1920)
    readonly property real barW: bar.screenW - 200
    readonly property real barX: 100
    readonly property real startW: 160
    readonly property real startX: (bar.screenW - bar.startW) / 2
    readonly property real midY: 10
    readonly property real startHeight: 34
    readonly property real barHeight: 30
    readonly property real startRadius: 18
    readonly property real barRadius: 15

    // ─────────────────────────────────────────────────────
    //  MORPHING BAR (Starts exactly as archPill, expands into solid bar)
    // ─────────────────────────────────────────────────────
    Rectangle {
        id: solidBar
        y: bar.midY
        x: bar.startX
        width: bar.startW
        height: bar.startHeight
        radius: bar.startRadius
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

        // 2. Solid Bar Modules (fades in as expansion completes)
        RowLayout {
            id: contentLayout
            anchors.fill: parent
            anchors.leftMargin: 16; anchors.rightMargin: 4
            spacing: 0
            opacity: 0

            // ── LEFT: Workspaces ────────
            Row {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: 5
                    delegate: Item {
                        width: isFocused ? 22 : 12
                        height: 30
                        property int wsId: index + 1
                        property bool isFocused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
                        property bool isOccupied: isFocused || Hyprland.workspaces.values.some(ws => ws.id === wsId)
                        
                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width
                            height: isFocused ? 6 : (wsMouse.containsMouse ? 6 : 4)
                            radius: height / 2
                            color: isFocused ? Theme.colPrimary : (isOccupied ? Qt.rgba(fg.r, fg.g, fg.b, 0.5) : Qt.rgba(fg.r, fg.g, fg.b, 0.2))
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        MouseArea { 
                            id: wsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Hyprland.dispatch("hl.dsp.focus({workspace = " + wsId + "})")
                        }
                    }
                }
            }
            
            // Spacer
            Item { Layout.fillWidth: true }
            
            // ── RIGHT: Power Icon ────────
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 26; height: 26; radius: 6
                color: Qt.rgba(fg.r, fg.g, fg.b, pMouse.containsMouse ? 0.15 : 0.0)
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "\ueb0d" // tabler icon for power
                    font.family: fontName
                    font.pixelSize: 15
                    color: fg
                }

                MouseArea {
                    id: pMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    // Just toggling the global state in case the user installs a separate listener later,
                    // or explicitly spawning wlogout if they install it.
                    onClicked: Quickshell.execDetached(["bash", "-c", "wlogout -b 5 || systemctl poweroff"])
                }
            }
        }
        
        Image {
            id: cupcakeLogo
            anchors.centerIn: parent
            source: Theme.isDark ? "../../assets/cupcake-word-light.svg" : "../../assets/cupcake-word-dark.svg"
            sourceSize.height: 24
            fillMode: Image.PreserveAspectFit
            opacity: contentLayout.opacity
        }
    }

    // ─────────────────────────────────────────────────────
    //  1. FORWARD EXPANSION ANIMATION (Pill -> Solid Bar)
    // ─────────────────────────────────────────────────────
    ParallelAnimation {
        id: expandAnim
        running: false

        NumberAnimation {
            target: solidBar
            property: "x"
            from: bar.startX
            to: bar.barX
            duration: 540
            easing.type: Easing.OutBack
            easing.overshoot: 0.5
        }
        NumberAnimation {
            target: solidBar
            property: "width"
            from: bar.startW
            to: bar.barW
            duration: 540
            easing.type: Easing.OutBack
            easing.overshoot: 0.5
        }
        NumberAnimation {
            target: solidBar
            property: "height"
            from: bar.startHeight
            to: bar.barHeight
            duration: 540
            easing.type: Easing.OutBack
            easing.overshoot: 0.5
        }
        NumberAnimation {
            target: solidBar
            property: "radius"
            from: bar.startRadius
            to: bar.barRadius
            duration: 540
            easing.type: Easing.OutBack
            easing.overshoot: 0.5
        }
        ColorAnimation {
            target: solidBar
            property: "color"
            from: Theme.colPrimary
            to: bar.pillColor
            duration: 440
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: archHeader
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: 220
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: contentLayout
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 420
            easing.type: Easing.InOutCubic
        }
        
        onFinished: {
            solidBar.color = Qt.binding(function() { return bar.pillColor; });
        }
    }

    // ─────────────────────────────────────────────────────
    //  2. REVERSE COLLAPSE ANIMATION (Solid Bar -> Pill)
    // ─────────────────────────────────────────────────────
    ParallelAnimation {
        id: collapseAnim
        running: false

        NumberAnimation {
            target: solidBar
            property: "x"
            to: bar.startX
            duration: 480
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: solidBar
            property: "width"
            to: bar.startW
            duration: 480
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: solidBar
            property: "height"
            to: bar.startHeight
            duration: 480
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: solidBar
            property: "radius"
            to: bar.startRadius
            duration: 480
            easing.type: Easing.InOutCubic
        }
        ColorAnimation {
            target: solidBar
            property: "color"
            to: Theme.colPrimary
            duration: 420
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: archHeader
            property: "opacity"
            to: 1.0
            duration: 250
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: contentLayout
            property: "opacity"
            to: 0.0
            duration: 200
            easing.type: Easing.InQuad
        }

        onFinished: {
            // Once collapse is complete, finalize mode change to "pill"
            globalState.barStyle = "pill";
            globalState.pendingBarStyle = "";
        }
    }

    function resetToArchPill() {
        collapseAnim.stop();
        expandAnim.stop();
        solidBar.x = bar.startX;
        solidBar.width = bar.startW;
        solidBar.height = bar.startHeight;
        solidBar.radius = bar.startRadius;
        solidBar.color = Theme.colPrimary;
        archHeader.opacity = 1.0;
        contentLayout.opacity = 0.0;
    }

    Connections {
        target: globalState
        function onBarStyleChanged() {
            if (globalState.barStyle === "solid") {
                resetToArchPill();
                expandAnim.restart();
            }
        }
        function onPendingBarStyleChanged() {
            if (globalState.pendingBarStyle === "pill") {
                expandAnim.stop();
                collapseAnim.restart();
            }
        }
    }

    Component.onCompleted: {
        if (globalState.barStyle === "solid") {
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
