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
    readonly property real expandedW: 300
    property real contentW: menuExpanded ? expandedW : headerW

    // Art is 110px + 14px margin = 124. Right column fills the rest.
    readonly property real artSize: 110
    readonly property real artMargin: 14

    height: menuExpanded ? (artSize + artMargin * 2) : 30
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
        let r = total - val;
        if (r < 0) r = 0;
        let seconds = r;
        if (total > 10000000) seconds = Math.floor(r / 1000000);
        else if (total > 10000) seconds = Math.floor(r / 1000);
        else seconds = Math.floor(r);
        let m = Math.floor(seconds / 60);
        let s = Math.floor(seconds % 60);
        return "-" + m + ":" + (s < 10 ? "0" : "") + s;
    }

    function cleanTrackTitle(title, artist) {
        if (!title) return "No Track";
        let t = title;
        t = t.replace(/\s*[([].*?(official|music video|lyric|audio).*?[)\]]/gi, "");
        if (artist && t.toLowerCase().startsWith(artist.toLowerCase() + " - "))
            t = t.substring(artist.length + 3);
        else if (artist && t.toLowerCase().startsWith(artist.toLowerCase() + "-"))
            t = t.substring(artist.length + 1);
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
            opacity: 0
        }

        Item {
            id: smallPlayPausePlaceholder
            width: 22; height: 22
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ── FLOATING ALBUM ART MASK ──
    Rectangle {
        id: floatingArtMask
        x: musicSplitPill.menuExpanded ? artMargin : (12 + smallArtPlaceholder.x)
        y: musicSplitPill.menuExpanded ? artMargin : 4
        width:  musicSplitPill.menuExpanded ? artSize : 22
        height: musicSplitPill.menuExpanded ? artSize : 22
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
        x: floatingArtMask.x; y: floatingArtMask.y
        width: floatingArtMask.width; height: floatingArtMask.height
        z: 20
        source: (hasPlayer && player.trackArtUrl) ? player.trackArtUrl : ""
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
        layer.enabled: true
        layer.effect: OpacityMask { maskSource: floatingArtMask }
    }

    // Fallback icon when no art
    Rectangle {
        x: floatingArtMask.x; y: floatingArtMask.y
        width: floatingArtMask.width; height: floatingArtMask.height
        radius: floatingArtMask.radius
        color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.15)
        visible: musicSplitPill.menuExpanded && floatingAlbumArt.status !== Image.Ready
        z: 19
        Behavior on x      { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on y      { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on width  { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on height { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Text {
            anchors.centerIn: parent
            text: "\ueafc"
            font.family: ddMusicFont.name
            font.pixelSize: 36
            color: Theme.colPrimary
        }
    }

    // ── FLOATING PLAY/PAUSE ──
    // In expanded: sits in the controls row (centre of 3 buttons on right column)
    // right column starts at: artMargin + artSize + 12
    readonly property real rightColX: artMargin + artSize + 12
    // Controls row is vertically centred in the right column, roughly 2/3 down
    readonly property real controlsRowY: artMargin + 52

    Rectangle {
        id: floatingPlayButton
        x: musicSplitPill.menuExpanded ? (musicSplitPill.rightColX + 32) : (12 + smallPlayPausePlaceholder.x)
        y: musicSplitPill.menuExpanded ? musicSplitPill.controlsRowY : 4
        width:  musicSplitPill.menuExpanded ? 36 : 22
        height: musicSplitPill.menuExpanded ? 36 : 22
        radius: musicSplitPill.menuExpanded ? 18 : 11
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
            font.pixelSize: musicSplitPill.menuExpanded ? 17 : 14
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
        text: hasPlayer ? cleanTrackTitle(player.trackTitle, player.trackArtist) : "No Track"
        font.family: Theme.defaultFontFamily
        font.pixelSize: 11
        font.weight: Font.Bold
        color: bar.fg
        elide: Text.ElideRight
        width: musicSplitPill.menuExpanded
               ? (musicSplitPill.expandedW - musicSplitPill.rightColX - musicSplitPill.artMargin)
               : compactTrackTitle.width
        scale: musicSplitPill.menuExpanded ? (16.0 / 11.0) : 1.0
        transformOrigin: Item.TopLeft
        Behavior on scale  { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        x: musicSplitPill.menuExpanded ? musicSplitPill.rightColX : (12 + compactTrackTitle.x)
        y: musicSplitPill.menuExpanded ? artMargin : (musicHeaderRow.y + compactTrackTitle.y)
        Behavior on x { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on y { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        z: 20
    }

    // ── MOUSE AREA ──
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

    // ── EXPANDED CONTENT (right column only, art is handled by floating elements) ──
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
        opacity: musicSplitPill.menuExpanded ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Title placeholder (floating title sits here, needs height reserve)
            Item {
                Layout.fillWidth: true
                // Reserve space for the scaled-up title (11px * 16/11 scale ≈ 16px + a bit)
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

            Item { Layout.fillHeight: true }

            // Controls: prev | [play/pause placeholder] | next
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MouseArea {
                    width: 28; height: 36
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

                // Play/pause placeholder — floating button goes here
                Item { width: 36; height: 36 }

                MouseArea {
                    width: 28; height: 36
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

                Item { Layout.fillWidth: true }
            }

            Item { height: 6 }

            // Progress bar
            Item {
                id: progressWrapper
                Layout.fillWidth: true
                height: 3
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
                    radius: 2
                    color: Qt.rgba(1, 1, 1, 0.15)
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

            Item { height: 2 }

            // Timestamps
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: hasPlayer ? formatTime(progressWrapper.currentPosition) : "0:00"
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 10
                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: hasPlayer ? formatRemaining(progressWrapper.currentPosition, player.length) : "-0:00"
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 10
                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                }
            }
        }
    }
}
