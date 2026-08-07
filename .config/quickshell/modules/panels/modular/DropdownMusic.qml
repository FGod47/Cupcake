import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import "../../../theme"

// ── MUSIC SPLIT PILL & MORPHING PLAYER ──
Rectangle {
    id: musicSplitPill
    y: 10
    property bool menuExpanded: bar.musicDropdownOpen
    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool hasPlayer: player !== null
    property bool isPlaying: hasPlayer ? (player.playbackState === 1 || player.isPlaying) : false

    readonly property real expandedW: 340
    readonly property real expandedH: 182
    readonly property real artMargin: 8
    readonly property real artSizeExpanded: 166

    readonly property real headerW: musicHeaderRow.implicitWidth + 24
    property real contentW: menuExpanded ? expandedW : headerW

    readonly property int dur: 450
    readonly property int easingType: Easing.OutQuart

    height: menuExpanded ? expandedH : 30
    Behavior on height { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }

    x: bar.barX
    width: contentW
    Behavior on x     { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }
    Behavior on width { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }

    radius: 20
    Behavior on radius { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }
    clip: true
    color: bar.pillColor

    HoverHandler { id: pillHover }
    property bool isHovered: pillHover.hovered || musicHeaderMa.containsMouse

    opacity: bar.keepMusicAlive ? 1.0 : 0.0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }

    FontLoader {
        id: ddMusicFont
        source: Qt.resolvedUrl("file://" + Quickshell.env("HOME") + "/.local/share/fonts/tabler-icons.ttf")
    }

    function formatTime(val) {
        if (!val || isNaN(val)) return "0:00";
        let s = val > 10000000 ? Math.floor(val/1000000) : val > 10000 ? Math.floor(val/1000) : Math.floor(val);
        return Math.floor(s/60) + ":" + (s%60 < 10 ? "0" : "") + Math.floor(s%60);
    }

    function formatRemaining(val, total) {
        if (!val || !total || isNaN(val) || isNaN(total)) return "-0:00";
        let r = Math.max(0, total - val);
        let s = total > 10000000 ? Math.floor(r/1000000) : total > 10000 ? Math.floor(r/1000) : Math.floor(r);
        return "-" + Math.floor(s/60) + ":" + (s%60 < 10 ? "0" : "") + Math.floor(s%60);
    }

    function cleanTrackTitle(title, artist) {
        if (!title) return "No Track";
        let t = title.replace(/\s*[([].*?(official|music video|lyric|audio).*?[)\]]/gi, "");
        if (artist && t.toLowerCase().startsWith(artist.toLowerCase() + " - "))
            t = t.substring(artist.length + 3);
        else if (artist && t.toLowerCase().startsWith(artist.toLowerCase() + "-"))
            t = t.substring(artist.length + 1);
        return t.trim() || "No Track";
    }

    function shortenTitle(title, artist, n) {
        let t = cleanTrackTitle(title, artist);
        if (t === "No Track") return t;
        let w = t.split(/\s+/);
        return w.length > n ? w.slice(0, n).join(" ") : t;
    }

    // ── COLLAPSED HEADER ROW ──
    Row {
        id: musicHeaderRow
        height: 24
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.top
        anchors.verticalCenterOffset: 15
        spacing: 8
        z: 10
        opacity: musicSplitPill.menuExpanded ? 0.0 : 1.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Item {
            width: 22; height: 22
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                id: compactArtMask
                anchors.fill: parent
                radius: 11
                visible: false
            }

            Image {
                id: compactArtImg
                anchors.fill: parent
                source: (hasPlayer && player.trackArtUrl) ? player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
                layer.enabled: true
                layer.effect: OpacityMask { maskSource: compactArtMask }
            }

            Text {
                anchors.centerIn: parent
                text: "\ueafc"
                font.family: ddMusicFont.name
                font.pixelSize: 13
                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                visible: compactArtImg.status !== Image.Ready
            }
        }

        Text {
            id: compactTrackTitle
            text: hasPlayer ? shortenTitle(player.trackTitle, player.trackArtist, 3) : "No Track"
            font.family: "Inter, sans-serif"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: bar.fg
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            maximumLineCount: 1
            width: Math.min(implicitWidth, 120)
        }

        Item {
            width: 22; height: 22
            anchors.verticalCenter: parent.verticalCenter
            Text {
                anchors.centerIn: parent
                text: isPlaying ? "\ued45" : "\ued46"
                font.family: ddMusicFont.name
                font.pixelSize: 13
                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (hasPlayer) player.togglePlaying()
            }
        }
    }

    // ── EXPANDED ALBUM ART (LEFT SIDE, 166x166) ──
    Rectangle {
        id: floatingArtMask
        x: artMargin
        y: artMargin
        width: artSizeExpanded
        height: artSizeExpanded
        radius: 16
        visible: false
    }

    Image {
        id: floatingAlbumArt
        x: floatingArtMask.x; y: floatingArtMask.y
        width: floatingArtMask.width; height: floatingArtMask.height
        z: 5
        source: (hasPlayer && player.trackArtUrl) ? player.trackArtUrl : ""
        fillMode: Image.PreserveAspectCrop
        visible: true
        opacity: (musicSplitPill.menuExpanded && status === Image.Ready) ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }
        layer.enabled: true
        layer.effect: OpacityMask { maskSource: floatingArtMask }
    }

    // Fallback Gradient + Note Icon + "now playing" doodle badge
    Rectangle {
        x: floatingArtMask.x; y: floatingArtMask.y
        width: floatingArtMask.width; height: floatingArtMask.height
        radius: floatingArtMask.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#ff9ad0" }
            GradientStop { position: 0.45; color: "#b28bff" }
            GradientStop { position: 1.0; color: "#4a2f9e" }
        }
        visible: true
        opacity: (musicSplitPill.menuExpanded && floatingAlbumArt.status !== Image.Ready) ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }
        z: 4

        // Top-right note icon
        Text {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 10
            anchors.rightMargin: 10
            text: "\ueafc"
            font.family: ddMusicFont.name
            font.pixelSize: 18
            color: "#FFFFFF"
            opacity: 0.7
        }

        // Bottom-left "now playing" doodle badge
        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 10
            anchors.bottomMargin: 10
            width: doodleText.implicitWidth + 14
            height: 20
            radius: 10
            color: "transparent"
            border.color: Qt.rgba(255, 255, 255, 0.85)
            border.width: 1

            Text {
                id: doodleText
                anchors.centerIn: parent
                text: "now playing"
                font.family: "Inter, sans-serif"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: "#FFFFFF"
            }
        }
    }

    // ── CLICK HANDLER ──
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

    // ── EXPANDED RIGHT COLUMN ──
    Item {
        id: expandedContent
        anchors.left: parent.left
        anchors.leftMargin: artMargin + artSizeExpanded + 14   // 188px
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.top: parent.top
        anchors.topMargin: 12
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12

        opacity: musicSplitPill.menuExpanded ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation { duration: musicSplitPill.menuExpanded ? 150 : 0 }
                NumberAnimation { duration: 250; easing.type: Easing.OutQuart }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // 1. Title & Artist Info
            Text {
                Layout.fillWidth: true
                text: hasPlayer ? (player.trackTitle || "No Track") : "No Track"
                font.family: "Inter, sans-serif"
                font.pixelSize: 13
                font.weight: Font.Bold
                color: "#FFFFFF"
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 2
                text: hasPlayer ? (player.trackArtist || "Unknown Artist") : "Unknown Artist"
                font.family: "Inter, sans-serif"
                font.pixelSize: 11
                color: Qt.rgba(1, 1, 1, 0.55)
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Item { Layout.fillHeight: true }

            // 2. Media Controls (Prev | Play/Pause | Next)
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                // Prev
                Rectangle {
                    width: 26; height: 26
                    radius: 13
                    color: prevMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "\ued4c"
                        font.family: ddMusicFont.name
                        font.pixelSize: 16
                        color: "#FFFFFF"
                    }
                    MouseArea {
                        id: prevMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (hasPlayer) player.previous()
                    }
                }

                // Play / Pause (32x32)
                Rectangle {
                    width: 32; height: 32
                    radius: 16
                    color: Qt.rgba(1, 1, 1, playMa.containsMouse ? 0.22 : 0.14)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: isPlaying ? "\ued45" : "\ued46"
                        font.family: ddMusicFont.name
                        font.pixelSize: 18
                        color: "#FFFFFF"
                    }
                    MouseArea {
                        id: playMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (hasPlayer) player.togglePlaying()
                    }
                }

                // Next
                Rectangle {
                    width: 26; height: 26
                    radius: 13
                    color: nextMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "\ued4b"
                        font.family: ddMusicFont.name
                        font.pixelSize: 16
                        color: "#FFFFFF"
                    }
                    MouseArea {
                        id: nextMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (hasPlayer) player.next()
                    }
                }
            }

            Item { height: 12 }

            // 3. Progress Bar & Slider
            Item {
                id: progressWrapper
                Layout.fillWidth: true
                height: 8

                property real currentPosition: hasPlayer ? player.position : 0
                property real progress: (hasPlayer && player.length > 0) ? (currentPosition / player.length) : 0

                Timer {
                    interval: 1000
                    running: hasPlayer && isPlaying
                    repeat: true
                    onTriggered: { if (hasPlayer) progressWrapper.currentPosition = player.position; }
                }

                // Track background
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 3
                    radius: 2
                    color: Qt.rgba(1, 1, 1, 0.16)

                    // Fill bar
                    Rectangle {
                        height: parent.height
                        width: parent.width * progressWrapper.progress
                        radius: 2
                        color: "#d3cadb"
                        Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.OutQuart } }

                        // Handle Dot
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: -4
                            width: 8; height: 8
                            radius: 4
                            color: "#FFFFFF"
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        if (hasPlayer && player.length > 0) {
                            let np = (mouse.x / width) * player.length;
                            try { player.position = np; } catch(e) {}
                            progressWrapper.currentPosition = Math.max(0, Math.min(np, player.length));
                        }
                    }
                    onPositionChanged: (mouse) => {
                        if (pressed && hasPlayer && player.length > 0) {
                            let cx = Math.max(0, Math.min(mouse.x, width));
                            let np = (cx / width) * player.length;
                            try { player.position = np; } catch(e) {}
                            progressWrapper.currentPosition = np;
                        }
                    }
                }
            }

            Item { height: 4 }

            // 4. Timestamps
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: hasPlayer ? formatTime(progressWrapper.currentPosition) : "0:00"
                    font.family: "Inter, sans-serif"
                    font.pixelSize: 10
                    color: Qt.rgba(1, 1, 1, 0.5)
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: hasPlayer ? formatRemaining(progressWrapper.currentPosition, player.length) : "-0:00"
                    font.family: "Inter, sans-serif"
                    font.pixelSize: 10
                    color: Qt.rgba(1, 1, 1, 0.5)
                }
            }
        }
    }
}
