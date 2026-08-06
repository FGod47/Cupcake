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
    readonly property real expandedW: 340
    property real contentW: menuExpanded ? expandedW : headerW

    height: menuExpanded ? (expandedInner.implicitHeight + 28) : 30
    Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutQuart } }

    x: bar.barX
    width: contentW

    Behavior on x     { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
    Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }

    radius: menuExpanded ? 20 : 15
    Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
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
        let seconds = val;
        if (val > 10000000) seconds = Math.floor(val / 1000000);
        else if (val > 10000) seconds = Math.floor(val / 1000);
        else seconds = Math.floor(val);
        let m = Math.floor(seconds / 60);
        let s = Math.floor(seconds % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    function formatRemaining(val, total) {
        if (!val || !total || isNaN(val) || isNaN(total)) return "-0:00";
        let remaining = total - val;
        if (remaining < 0) remaining = 0;
        let seconds = remaining;
        if (total > 10000000) seconds = Math.floor(remaining / 1000000);
        else if (total > 10000) seconds = Math.floor(remaining / 1000);
        else seconds = Math.floor(remaining);
        let m = Math.floor(seconds / 60);
        let s = Math.floor(seconds % 60);
        return "-" + m + ":" + (s < 10 ? "0" : "") + s;
    }

    function cleanTrackTitle(title, artist) {
        if (!title) return "No Track";
        let t = title;
        t = t.replace(/\s*[([].*?(official|music video|lyric|audio).*?[)\]]/gi, "");
        if (artist && t.toLowerCase().startsWith(artist.toLowerCase() + " - ")) {
            t = t.substring(artist.length + 3);
        } else if (artist && t.toLowerCase().startsWith(artist.toLowerCase() + "-")) {
            t = t.substring(artist.length + 1);
        }
        return t.trim() || "No Track";
    }

    function shortenTrackTitle(title, artist, maxWords) {
        let t = cleanTrackTitle(title, artist);
        if (t === "No Track") return t;
        let words = t.split(/\s+/);
        if (words.length > maxWords) return words.slice(0, maxWords).join(" ");
        return t;
    }

    // ── COLLAPSED HEADER ROW ──
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
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Item {
            id: smallArtPlaceholder
            width: 22; height: 22
            anchors.verticalCenter: parent.verticalCenter
            Text {
                anchors.centerIn: parent
                text: "\ueafc"
                font.family: ddMusicFont.name
                font.pixelSize: 13
                color: Theme.colPrimary
                visible: floatingAlbumArt.status !== Image.Ready
            }
        }

        Text {
            id: compactTrackTitle
            text: hasPlayer ? shortenTrackTitle(player.trackTitle, player.trackArtist, 3) : "No Track"
            font.family: Theme.defaultFontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: bar.fg
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            maximumLineCount: 1
            width: Math.min(implicitWidth, 180)
            visible: !musicSplitPill.menuExpanded
            opacity: 0 // floatingTrackTitle takes its place
        }

        Item {
            id: smallPlayPausePlaceholder
            width: 22; height: 22
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ── FLOATING ANIMATED ALBUM ART ──
    Rectangle {
        id: floatingArtMask
        x: musicSplitPill.menuExpanded ? 14 : (12 + smallArtPlaceholder.x)
        y: musicSplitPill.menuExpanded ? 14 : 4
        width:  musicSplitPill.menuExpanded ? 100 : 22
        height: musicSplitPill.menuExpanded ? 100 : 22
        radius: musicSplitPill.menuExpanded ? 14 : 11
        visible: false
        Behavior on x      { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on y      { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on width  { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on height { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on radius { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
    }

    Image {
        id: floatingAlbumArt
        x: floatingArtMask.x
        y: floatingArtMask.y
        width:  floatingArtMask.width
        height: floatingArtMask.height
        z: 20
        source: (hasPlayer && player.trackArtUrl) ? player.trackArtUrl : ""
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
        layer.enabled: true
        layer.effect: OpacityMask { maskSource: floatingArtMask }
    }

    // ── FLOATING PLAY/PAUSE ──
    Rectangle {
        id: floatingPlayButton
        x: musicSplitPill.menuExpanded ? (14 + 100 + 12 + 28 + 8) : (12 + smallPlayPausePlaceholder.x)
        y: musicSplitPill.menuExpanded ? (14 + 52) : 4
        width:  musicSplitPill.menuExpanded ? 38 : 22
        height: musicSplitPill.menuExpanded ? 38 : 22
        radius: musicSplitPill.menuExpanded ? 19 : 11
        color:  musicSplitPill.menuExpanded ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
        z: 20
        Behavior on x      { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on y      { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on width  { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on height { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on radius { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on color  { ColorAnimation { duration: 250 } }

        Text {
            anchors.centerIn: parent
            text: isPlaying ? "\ued45" : "\ued46"
            font.family: ddMusicFont.name
            font.pixelSize: musicSplitPill.menuExpanded ? 18 : 14
            color: musicSplitPill.menuExpanded ? bar.fg : Theme.colPrimary
            Behavior on font.pixelSize { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
            Behavior on color { ColorAnimation { duration: 250 } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: if (hasPlayer) player.togglePlaying()
        }
    }

    // ── FLOATING TRACK TITLE ──
    Text {
        id: floatingTrackTitle
        text: hasPlayer ? shortenTrackTitle(player.trackTitle, player.trackArtist, 3) : "No Track"
        font.family: Theme.defaultFontFamily
        font.pixelSize: 11
        font.weight: musicSplitPill.menuExpanded ? Font.Bold : Font.DemiBold
        color: bar.fg
        scale: musicSplitPill.menuExpanded ? (16.0 / 11.0) : 1.0
        transformOrigin: Item.TopLeft
        Behavior on scale { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        x: musicSplitPill.menuExpanded ? (14 + 100 + 12) : (12 + compactTrackTitle.x)
        y: musicSplitPill.menuExpanded ? 14 : (musicHeaderRow.y + compactTrackTitle.y)
        Behavior on x { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on y { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        z: 20
    }

    // MouseArea for pill click
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
        id: expandedInner
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 14
        opacity: musicSplitPill.menuExpanded ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 250 } }

        // Top section: big art + track info + controls
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Album art placeholder (floating art sits here visually)
            Item {
                id: largeArtPlaceholder
                width: 100; height: 100

                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.15)
                    visible: floatingAlbumArt.status !== Image.Ready
                    Text {
                        anchors.centerIn: parent
                        text: "\ueafc"
                        font.family: ddMusicFont.name
                        font.pixelSize: 36
                        color: Theme.colPrimary
                    }
                }
            }

            // Right side: title + artist + controls
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                // Title placeholder (floating title sits here visually)
                Item {
                    Layout.fillWidth: true
                    height: 22
                }

                // Artist
                Text {
                    Layout.fillWidth: true
                    text: hasPlayer ? (player.trackArtist || "Unknown Artist") : "Unknown Artist"
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 13
                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Item { Layout.fillHeight: true; height: 4 }

                // Controls row: prev | play/pause placeholder | next
                RowLayout {
                    spacing: 8

                    // Prev
                    MouseArea {
                        width: 28; height: 28
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (hasPlayer) player.previous()
                        Text {
                            anchors.centerIn: parent
                            text: "\ued4c"
                            font.family: ddMusicFont.name
                            font.pixelSize: 18
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.85)
                        }
                    }

                    // Play/Pause placeholder (floating button sits here)
                    Item {
                        id: largePlayPausePlaceholder
                        width: 38; height: 38
                    }

                    // Next
                    MouseArea {
                        width: 28; height: 28
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (hasPlayer) player.next()
                        Text {
                            anchors.centerIn: parent
                            text: "\ued4b"
                            font.family: ddMusicFont.name
                            font.pixelSize: 18
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.85)
                        }
                    }
                }
            }
        }

        // Progress bar + timestamps
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            // Progress track
            Item {
                Layout.fillWidth: true
                height: 4

                property real currentPosition: hasPlayer ? player.position : 0
                property real progress: (hasPlayer && player.length > 0) ? (currentPosition / player.length) : 0

                id: progressWrapper

                Timer {
                    interval: 1000
                    running: hasPlayer && isPlaying
                    repeat: true
                    onTriggered: { if (hasPlayer) progressWrapper.currentPosition = player.position; }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: Qt.rgba(1, 1, 1, 0.12)

                    Rectangle {
                        height: parent.height
                        width: parent.width * progressWrapper.progress
                        radius: 2
                        color: Theme.colPrimary
                        Behavior on width { NumberAnimation { duration: 800 } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        if (hasPlayer && player.length > 0) {
                            let newPos = (mouse.x / width) * player.length;
                            try { player.position = newPos; } catch(e) {}
                            progressWrapper.currentPosition = Math.max(0, Math.min(newPos, player.length));
                        }
                    }
                    onPositionChanged: (mouse) => {
                        if (pressed && hasPlayer && player.length > 0) {
                            let clampedX = Math.max(0, Math.min(mouse.x, width));
                            let newPos = (clampedX / width) * player.length;
                            try { player.position = newPos; } catch(e) {}
                            progressWrapper.currentPosition = newPos;
                        }
                    }
                }
            }

            // Timestamps
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: hasPlayer ? formatTime(progressWrapper.currentPosition) : "0:00"
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 11
                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: hasPlayer ? formatRemaining(progressWrapper.currentPosition, player.length) : "-0:00"
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 11
                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                }
            }
        }
    }
}
