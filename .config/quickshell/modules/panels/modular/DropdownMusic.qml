import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import "../../../theme"

// ── MUSIC SPLIT PILL & DROPDOWN ──
// Standalone split pill that appears in the center of the bar when music plays.
// Displays track title & artist compact pill, and expands into music card dropdown when clicked.
Rectangle {
    id: musicSplitPill
    y: 10
    property bool menuExpanded: bar.musicDropdownOpen
    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool hasPlayer: player !== null
    property bool isPlaying: hasPlayer ? (player.playbackState === 1 || player.isPlaying) : false

    readonly property real headerW: musicHeaderRow.implicitWidth + 24
    readonly property real expandedW: 320
    property real contentW: menuExpanded ? expandedW : headerW

    height: menuExpanded ? (musicContentCol.implicitHeight + 28) : 30
    Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutQuart } }

    x: bar.barX
    width: contentW

    Behavior on x     { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
    Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }

    radius: menuExpanded ? 24 : 15
    Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    clip: true

    color: bar.pillColor
    border.color: Qt.rgba(1, 1, 1, 0.12)
    border.width: 1

    HoverHandler {
        id: pillHover
    }
    property bool isHovered: pillHover.hovered || musicHeaderMa.containsMouse

    // Top glass highlight line
    Rectangle {
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        anchors.leftMargin: 4; anchors.rightMargin: 4
        height: 1; radius: 1
        color: Qt.rgba(1, 1, 1, 0.12)
    }

    opacity: bar.keepMusicAlive ? 1.0 : 0.0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }

    FontLoader {
        id: ddMusicFont
        source: Qt.resolvedUrl("file://" + Quickshell.env("HOME") + "/.local/share/fonts/tabler-icons.ttf")
    }

    function formatTime(val) {
        if (!val || isNaN(val)) return "0:00";
        let seconds = val;
        if (val > 10000000) seconds = Math.floor(val / 1000000); // microseconds
        else if (val > 10000) seconds = Math.floor(val / 1000); // milliseconds
        else seconds = Math.floor(val); // seconds
        
        let m = Math.floor(seconds / 60);
        let s = Math.floor(seconds % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    // ── COLLAPSED HEADER ROW (Shown inside split pill) ──
    Row {
        id: musicHeaderRow
        anchors.horizontalCenter: parent.horizontalCenter
        y: (30 - height) / 2
        spacing: 6
        z: 10
        opacity: musicSplitPill.menuExpanded ? 0.0 : 1.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Text {
            text: "\ueafc" // tabler music note icon
            font.family: ddMusicFont.name
            font.pixelSize: 13
            color: Theme.colPrimary
            anchors.verticalCenter: parent.verticalCenter
        }

        Canvas {
            id: waveCanvas
            width: 80
            height: 24
            anchors.verticalCenter: parent.verticalCenter
            
            property real time: 0
            
            PwNodePeakMonitor {
                id: peakMonitor
                node: Pipewire.defaultAudioSink
            }
            
            // Get live audio peak from Pipewire monitor
            property real currentPeak: peakMonitor.peak || 0.0
            
            // Smooth the peak to avoid jitter
            property real smoothedPeak: 0
            Behavior on smoothedPeak { NumberAnimation { duration: 50; easing.type: Easing.OutQuad } }
            onCurrentPeakChanged: smoothedPeak = currentPeak
            
            Timer {
                running: musicSplitPill.isPlaying && !musicSplitPill.menuExpanded
                repeat: true
                interval: 32 // ~30 fps
                onTriggered: {
                    waveCanvas.time += 0.15;
                    waveCanvas.requestPaint();
                }
            }
            
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                
                var centerY = height / 2;
                
                // Max allowed amplitude to stay well within the 24px high Canvas
                // Leaving 6px margin on top and bottom so it doesn't touch the edges
                var maxAmp = (height / 2) - 6; 
                
                // Base minimal amplitude + scaled audio peak (clamped to maxAmp)
                var dynamicAmp = 1.5 + (smoothedPeak * maxAmp);
                if (dynamicAmp > maxAmp) dynamicAmp = maxAmp;
                
                function drawWave(amplitude, opacity, lineWidth) {
                    ctx.beginPath();
                    ctx.strokeStyle = Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, opacity);
                    ctx.lineWidth = lineWidth;
                    for (var x = 0; x <= width; x += 1) {
                        // Taper off at the edges
                        var envelope = Math.sin((x / width) * Math.PI);
                        
                        // Combine multiple high-frequency sine waves to create an erratic, "voice-note" style waveform
                        var wave1 = Math.sin(x * 0.35 + time * 2.0) * 0.5;
                        var wave2 = Math.sin(x * 0.62 - time * 3.1) * 0.3;
                        var wave3 = Math.sin(x * 1.15 + time * 4.5) * 0.2;
                        
                        var combinedWave = wave1 + wave2 + wave3;
                        var y = centerY + (combinedWave * amplitude * envelope);
                        
                        if (x === 0) ctx.moveTo(x, y);
                        else ctx.lineTo(x, y);
                    }
                    ctx.stroke();
                }
                
                // Single clean erratic string matching the screenshot
                drawWave(dynamicAmp, 1.0, 1.5);
            }
        }

        // Play / Pause Button inside compact pill
        Item {
            width: 22; height: 22
            anchors.verticalCenter: parent.verticalCenter
            z: 20

            Text {
                anchors.centerIn: parent
                text: musicSplitPill.isPlaying ? "\ued45" : "\ued46" // pause vs play icon
                font.family: ddMusicFont.name
                font.pixelSize: 14
                color: Theme.colPrimary
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (hasPlayer) player.togglePlaying();
                }
            }
        }
    }

    // MouseArea for Header Pill click -> Toggle Music Dropdown
    MouseArea {
        id: musicHeaderMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: (mouseY <= 30) ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (mouseY <= 30) {
                if (bar.dropdownOpen) bar.dropdownOpen = false;
                if (bar.netDropdownOpen) bar.netDropdownOpen = false;
                bar.musicDropdownOpen = !bar.musicDropdownOpen;
            }
        }
    }

    // ── EXPANDED DROPDOWN CONTENT ──
    ColumnLayout {
        id: musicContentCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 12
        opacity: musicSplitPill.menuExpanded ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 250 } }

        // Top Row: Album Art + Track Info + Heart Icon
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Item {
                width: 54; height: 54

                Rectangle {
                    id: musicArtMask
                    anchors.fill: parent
                    radius: 12
                    visible: false
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.15)

                    Text {
                        anchors.centerIn: parent
                        text: "\ueafc"
                        font.family: ddMusicFont.name
                        font.pixelSize: 24
                        color: Theme.colPrimary
                    }
                }

                Image {
                    id: albumArtImg
                    anchors.fill: parent
                    source: (hasPlayer && player.artUrl) ? player.artUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready && source !== ""
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: musicArtMask
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: hasPlayer ? (player.trackTitle || "No Track") : "No Track"
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: bar.fg
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    Layout.fillWidth: true
                    text: hasPlayer ? (player.trackArtist || "Unknown Artist") : "Unknown Artist"
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 12
                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            // Liked icon removed as per user request
        }

        // Middle Row: Progress Slider Line
        Item {
            id: progressWrapper
            Layout.fillWidth: true
            height: 6

            property real progress: (hasPlayer && player.length > 0) ? (player.position / player.length) : 0
            
            Timer {
                interval: 1000
                running: hasPlayer && isPlaying
                repeat: true
                onTriggered: {
                    if (hasPlayer && player.length > 0) {
                        progressWrapper.progress = player.position / player.length;
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.10)

                Rectangle {
                    height: parent.height
                    width: parent.width * progressWrapper.progress
                    radius: 3
                    color: Theme.colPrimary
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (hasPlayer && player.length > 0) {
                        let newPos = (mouse.x / width) * player.length;
                        try { player.position = newPos; } catch(e) {}
                        progressWrapper.progress = Math.max(0, Math.min(mouse.x / width, 1));
                    }
                }
                onPositionChanged: (mouse) => {
                    if (pressed && hasPlayer && player.length > 0) {
                        let clampedX = Math.max(0, Math.min(mouse.x, width));
                        let newPos = (clampedX / width) * player.length;
                        try { player.position = newPos; } catch(e) {}
                        progressWrapper.progress = clampedX / width;
                    }
                }
            }
        }

        // Bottom Row: Controls + Time + Play/Pause Circle
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MouseArea {
                width: 28; height: 28
                cursorShape: Qt.PointingHandCursor
                onClicked: if (hasPlayer) player.previous()

                Text {
                    anchors.centerIn: parent
                    text: "\ueaa7"
                    font.family: ddMusicFont.name
                    font.pixelSize: 16
                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.8)
                }
            }

            MouseArea {
                width: 28; height: 28
                cursorShape: Qt.PointingHandCursor
                onClicked: if (hasPlayer) player.next()

                Text {
                    anchors.centerIn: parent
                    text: "\ueaa6"
                    font.family: ddMusicFont.name
                    font.pixelSize: 16
                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.8)
                }
            }

            Text {
                text: hasPlayer ? (formatTime(player.position) + " - " + formatTime(player.length)) : "0:00 - 0:00"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 11
                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
            }

            Item { Layout.fillWidth: true }

            // Icon removed as per user request

            Rectangle {
                width: 38; height: 38; radius: 19
                color: Qt.rgba(1, 1, 1, 0.10)

                Text {
                    anchors.centerIn: parent
                    text: isPlaying ? "\ued45" : "\ued46"
                    font.family: ddMusicFont.name
                    font.pixelSize: 18
                    color: bar.fg
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (hasPlayer) player.togglePlaying()
                }
            }
        }
    }
}
