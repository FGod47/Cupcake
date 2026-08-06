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

    readonly property real headerW: musicHeaderRow.implicitWidth + 20
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

    HoverHandler {
        id: pillHover
    }
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
        if (val > 10000000) seconds = Math.floor(val / 1000000); // microseconds
        else if (val > 10000) seconds = Math.floor(val / 1000); // milliseconds
        else seconds = Math.floor(val); // seconds
        
        let m = Math.floor(seconds / 60);
        let s = Math.floor(seconds % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    function cleanTrackTitle(title, artist) {
        if (!title) return "No Track";
        let t = title;
        // Remove common YouTube/Spotify clutter
        t = t.replace(/\s*[([].*?(official|music video|lyric|audio).*?[)\]]/gi, "");
        // Remove the prepended "Artist - " which happens on some MPRIS sources
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
        if (words.length > maxWords) {
            return words.slice(0, maxWords).join(" ");
        }
        return t;
    }

    // ── COLLAPSED HEADER ROW (Shown inside split pill) ──
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
            width: 22
            height: 22
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: "\ueafc" // fallback music note
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
            opacity: 0 // Hidden because floatingTrackTitle takes its place
        }

        // Play / Pause Button inside compact pill
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
        width: musicSplitPill.menuExpanded ? 54 : 22
        height: musicSplitPill.menuExpanded ? 54 : 22
        radius: musicSplitPill.menuExpanded ? 12 : 11
        visible: false
        
        Behavior on x { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on y { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on height { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on radius { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
    }

    Image {
        id: floatingAlbumArt
        x: floatingArtMask.x
        y: floatingArtMask.y
        width: floatingArtMask.width
        height: floatingArtMask.height
        z: 20 // Above both layouts
        source: (hasPlayer && player.trackArtUrl) ? player.trackArtUrl : ""
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: floatingArtMask
        }
    }

    // ── FLOATING ANIMATED PLAY/PAUSE BUTTON ──
    Rectangle {
        id: floatingPlayButton
        x: musicSplitPill.menuExpanded ? 268 : (12 + smallPlayPausePlaceholder.x)
        y: musicSplitPill.menuExpanded ? (14 + musicContentCol.implicitHeight - 38) : 4
        width: musicSplitPill.menuExpanded ? 38 : 22
        height: musicSplitPill.menuExpanded ? 38 : 22
        radius: musicSplitPill.menuExpanded ? 19 : 11
        color: musicSplitPill.menuExpanded ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
        z: 20
        
        Behavior on x { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on y { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on height { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on radius { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on color { ColorAnimation { duration: 250 } }

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
            onClicked: {
                if (hasPlayer) {
                    player.togglePlaying();
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

    // ── FLOATING ANIMATED TRACK TITLE ──
    Text {
        id: floatingTrackTitle
        text: hasPlayer ? shortenTrackTitle(player.trackTitle, player.trackArtist, 3) : "No Track"
        
        font.family: Theme.defaultFontFamily
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: bar.fg

        scale: musicSplitPill.menuExpanded ? (14.0 / 11.0) : 1.0
        transformOrigin: Item.TopLeft
        Behavior on scale { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }

        x: musicSplitPill.menuExpanded ? (14 + trackInfoWrapper.x) : (12 + compactTrackTitle.x)
        y: musicSplitPill.menuExpanded ? (14 + trackInfoWrapper.y) : (musicHeaderRow.y + compactTrackTitle.y)

        Behavior on x { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        Behavior on y { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        
        z: 20
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
                id: largeArtPlaceholder
                width: 54; height: 54

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.15)
                    visible: floatingAlbumArt.status !== Image.Ready

                    Text {
                        anchors.centerIn: parent
                        text: "\ueafc"
                        font.family: ddMusicFont.name
                        font.pixelSize: 24
                        color: Theme.colPrimary
                    }
                }
            }

            Item {
                id: trackInfoWrapper
                Layout.fillWidth: true
                height: trackInfoCol.implicitHeight
                clip: true

                ColumnLayout {
                    id: trackInfoCol
                    width: parent.width
                    spacing: 2

                    x: musicSplitPill.menuExpanded ? 0 : -40
                    Behavior on x { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }

                    Text {
                        id: realTitleText
                        Layout.fillWidth: true
                        text: hasPlayer ? shortenTrackTitle(player.trackTitle, player.trackArtist, 3) : "No Track"
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: bar.fg
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        opacity: 0 // Hidden because floatingTrackTitle takes its place
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
            }

            Rectangle {
                Layout.alignment: Qt.AlignTop | Qt.AlignRight
                visible: appNameText.text !== ""
                color: Qt.rgba(1, 1, 1, 0.08)
                radius: 12
                width: appNameText.implicitWidth + 16
                height: appNameText.implicitHeight + 8

                Text {
                    id: appNameText
                    anchors.centerIn: parent
                    text: hasPlayer ? (player.identity || "Unknown App") : ""
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
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
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            height: 4

            property real currentPosition: hasPlayer ? player.position : 0
            property real progress: (hasPlayer && player.length > 0) ? (currentPosition / player.length) : 0
            
            Timer {
                interval: 1000
                running: hasPlayer && isPlaying
                repeat: true
                onTriggered: {
                    if (hasPlayer) {
                        progressWrapper.currentPosition = player.position;
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 2
                color: Qt.rgba(1, 1, 1, 0.10)

                Rectangle {
                    height: parent.height
                    width: parent.width * progressWrapper.progress
                    radius: 2
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
                    text: "\ued4c"
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
                    text: "\ued4b"
                    font.family: ddMusicFont.name
                    font.pixelSize: 16
                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.8)
                }
            }

            Text {
                text: hasPlayer ? (formatTime(progressWrapper.currentPosition) + " - " + formatTime(player.length)) : "0:00 - 0:00"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 11
                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
            }

            Item { Layout.fillWidth: true }

            // Icon removed as per user request

            Item {
                id: largePlayPausePlaceholder
                width: 38; height: 38
            }
        }
    }
}
