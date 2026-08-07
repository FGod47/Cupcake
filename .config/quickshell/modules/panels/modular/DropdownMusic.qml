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
Rectangle {
    id: musicSplitPill
    y: 10
    property bool menuExpanded: bar.musicDropdownOpen
    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool hasPlayer: player !== null
    property bool isPlaying: hasPlayer ? (player.playbackState === 1 || player.isPlaying) : false

    readonly property real headerW: musicHeaderRow.implicitWidth + 20
    readonly property real expandedW: 320
    readonly property real expandedH: 136
    property real contentW: menuExpanded ? expandedW : headerW

    // Art: 108×108, left margin 14. Right column starts at 136.
    readonly property real artSize: 108
    readonly property real artMargin: 14
    readonly property real rightColX: artMargin + artSize + 14   // 136

    // All shared animation duration/easing
    readonly property int dur: 500
    readonly property int easingType: Easing.OutQuart

    height: menuExpanded ? expandedH : 30
    Behavior on height { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }

    x: bar.barX
    width: contentW
    Behavior on x     { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }
    Behavior on width { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }

    radius: menuExpanded ? 20 : 15
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

    // ── COLLAPSED HEADER ROW (fades out while pill expands) ──
    Row {
        id: musicHeaderRow
        height: 24
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.top
        anchors.verticalCenterOffset: 15
        spacing: 8
        z: 10
        opacity: musicSplitPill.menuExpanded ? 0.0 : 1.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuart } }

        // Art placeholder (real art is floating)
        Item {
            id: smallArtPlaceholder
            width: 22; height: 22
            anchors.verticalCenter: parent.verticalCenter
            Text {
                anchors.centerIn: parent
                text: "\ueafc"
                font.family: ddMusicFont.name
                font.pixelSize: 13
                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                visible: floatingAlbumArt.status !== Image.Ready
            }
        }

        // Track title text
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
            width: Math.min(implicitWidth, 100)
            opacity: 1.0
        }

        // Compact play/pause icon (collapsed pill only)
        Item {
            id: smallPlayPausePlaceholder
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

    // ── FLOATING ALBUM ART (only visible when expanded) ──
    Rectangle {
        id: floatingArtMask
        x: artMargin
        y: artMargin
        width: artSize
        height: artSize
        radius: 14
        visible: false
    }

    Image {
        id: floatingAlbumArt
        x: floatingArtMask.x; y: floatingArtMask.y
        width: floatingArtMask.width; height: floatingArtMask.height
        z: 5
        source: (hasPlayer && player.trackArtUrl) ? player.trackArtUrl : ""
        fillMode: Image.PreserveAspectCrop
        visible: musicSplitPill.menuExpanded && status === Image.Ready
        opacity: musicSplitPill.menuExpanded ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }
        layer.enabled: true
        layer.effect: OpacityMask { maskSource: floatingArtMask }
    }

    // Art fallback (no album art) — only shown when expanded
    Rectangle {
        x: floatingArtMask.x; y: floatingArtMask.y
        width: floatingArtMask.width; height: floatingArtMask.height
        radius: floatingArtMask.radius
        color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.18)
        visible: musicSplitPill.menuExpanded && floatingAlbumArt.status !== Image.Ready
        opacity: musicSplitPill.menuExpanded ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }
        z: 4
        Text {
            anchors.centerIn: parent
            text: "\ueafc"
            font.family: ddMusicFont.name
            font.pixelSize: 36
            color: Theme.colPrimary
        }
    }

    // ── FLOATING TRACK TITLE — only shown when expanded ──
    Text {
        id: floatingTrackTitle
        text: hasPlayer ? shortenTitle(player.trackTitle, player.trackArtist, 3) : "No Track"
        font.family: "Inter, sans-serif"
        font.pixelSize: 15
        font.weight: Font.Bold
        color: "#FFFFFF"
        elide: Text.ElideRight
        width: musicSplitPill.expandedW - musicSplitPill.rightColX - musicSplitPill.artMargin
        x: musicSplitPill.rightColX
        y: artMargin
        z: 10
        opacity: musicSplitPill.menuExpanded ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }
    }

    // ── FLOATING PLAY/PAUSE BUTTON (glides from pill → centre of controls row) ──
    // Expanded centre of controls row:
    //   rightColX + (rightColW / 2) - 16  where rightColW = expandedW - rightColX - artMargin
    readonly property real _rightColW: expandedW - rightColX - artMargin  // ~170
    readonly property real _playExpandedX: rightColX + (_rightColW - 32) / 2
    readonly property real _playExpandedY: 57   // empirically centred in controls row

    // Play button — only shown in expanded state (compact pill shows icon in header row)
    Item {
        x: musicSplitPill._playExpandedX
        y: musicSplitPill._playExpandedY
        width: 32; height: 32
        z: 10
        visible: musicSplitPill.menuExpanded
        opacity: musicSplitPill.menuExpanded ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }

        Text {
            anchors.centerIn: parent
            text: isPlaying ? "\ued45" : "\ued46"
            font.family: ddMusicFont.name
            font.pixelSize: 22
            color: "#FFFFFF"
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: if (hasPlayer) player.togglePlaying()
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

    // ── EXPANDED CONTENT (right column: artist, controls, progress) ──
    Item {
        id: expandedContent
        anchors.left: parent.left
        anchors.leftMargin: musicSplitPill.rightColX
        anchors.right: parent.right
        anchors.rightMargin: artMargin
        anchors.top: parent.top
        anchors.topMargin: artMargin
        anchors.bottom: parent.bottom
        anchors.bottomMargin: artMargin
        // Delay fade-in slightly so card has expanded before content appears
        opacity: musicSplitPill.menuExpanded ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation { duration: musicSplitPill.menuExpanded ? 180 : 0 }
                NumberAnimation { duration: 220; easing.type: Easing.OutQuart }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Space reserved for floatingTrackTitle (scaled 15px ≈ 22px rendered)
            Item { Layout.fillWidth: true; height: 22 }

            // Artist name
            Text {
                Layout.fillWidth: true
                text: hasPlayer ? (player.trackArtist || "Unknown Artist") : "Unknown Artist"
                font.family: "Inter, sans-serif"
                font.pixelSize: 13
                color: Qt.rgba(1, 1, 1, 0.6)
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Item { Layout.fillHeight: true }

            // Controls: ⏮  |  [play placeholder]  |  ⏭
            RowLayout {
                id: controlsRow
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                MouseArea {
                    width: 32; height: 32
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (hasPlayer) player.previous()
                    Text {
                        anchors.centerIn: parent
                        text: "\ued4c"
                        font.family: ddMusicFont.name
                        font.pixelSize: 22
                        color: "#FFFFFF"
                    }
                }

                // Invisible placeholder — floatingPlayButton floats here
                Item { id: largePlayPausePlaceholder; width: 32; height: 32 }

                MouseArea {
                    width: 32; height: 32
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (hasPlayer) player.next()
                    Text {
                        anchors.centerIn: parent
                        text: "\ued4b"
                        font.family: ddMusicFont.name
                        font.pixelSize: 22
                        color: "#FFFFFF"
                    }
                }
            }

            Item { height: 10 }

            // Progress bar
            Item {
                id: progressWrapper
                Layout.fillWidth: true
                height: 5

                property real currentPosition: hasPlayer ? player.position : 0
                property real progress: (hasPlayer && player.length > 0) ? (currentPosition / player.length) : 0

                Timer {
                    interval: 1000
                    running: hasPlayer && isPlaying
                    repeat: true
                    onTriggered: { if (hasPlayer) progressWrapper.currentPosition = player.position; }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: Qt.rgba(1, 1, 1, 0.15)

                    Rectangle {
                        height: parent.height
                        width: parent.width * progressWrapper.progress
                        radius: 3
                        color: Qt.rgba(1, 1, 1, 0.85)
                        Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.OutQuart } }
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

            // Timestamps
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: hasPlayer ? formatTime(progressWrapper.currentPosition) : "0:00"
                    font.family: "Inter, sans-serif"
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.5)
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: hasPlayer ? formatRemaining(progressWrapper.currentPosition, player.length) : "-0:00"
                    font.family: "Inter, sans-serif"
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.5)
                }
            }
        }
    }
}
