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

    readonly property real headerW: musicHeaderRow.implicitWidth + 24
    readonly property real expandedW: 320
    readonly property real expandedH: 136
    property real contentW: menuExpanded ? expandedW : headerW

    height: menuExpanded ? expandedH : 30
    Behavior on height { NumberAnimation { duration: 450; easing.type: Easing.OutQuart } }

    x: bar.barX
    width: contentW
    Behavior on x     { NumberAnimation { duration: 450; easing.type: Easing.OutQuart } }
    Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.OutQuart } }

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

    // ── COLLAPSED COMPACT PILL CONTENT ──
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

        // Small Album Art
        Item {
            width: 22; height: 22
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                id: smallArtMask
                anchors.fill: parent
                radius: 11
                visible: false
            }

            Image {
                anchors.fill: parent
                source: (hasPlayer && player.trackArtUrl) ? player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
                layer.enabled: true
                layer.effect: OpacityMask { maskSource: smallArtMask }
            }

            Text {
                anchors.centerIn: parent
                text: "\ueafc"
                font.family: ddMusicFont.name
                font.pixelSize: 13
                color: Theme.colPrimary
                visible: !hasPlayer || !player.trackArtUrl
            }
        }

        // Track Title (3-word truncated)
        Text {
            text: hasPlayer ? shortenTrackTitle(player.trackTitle, player.trackArtist, 3) : "No Track"
            font.family: "Inter, sans-serif"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: bar.fg
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            maximumLineCount: 1
            width: Math.min(implicitWidth, 180)
        }

        // Small Play/Pause Icon
        Text {
            text: isPlaying ? "\ued45" : "\ued46"
            font.family: ddMusicFont.name
            font.pixelSize: 14
            color: Theme.colPrimary
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ── MOUSE AREA TO TOGGLE EXPAND ──
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

    // ── EXPANDED DROPDOWN CARD CONTENT ──
    Item {
        id: expandedContent
        anchors.fill: parent
        anchors.margins: 14
        opacity: musicSplitPill.menuExpanded ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        RowLayout {
            anchors.fill: parent
            spacing: 14

            // Left: Large Album Art (108x108)
            Item {
                Layout.preferredWidth: 108
                Layout.preferredHeight: 108
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                Rectangle {
                    id: largeArtMask
                    anchors.fill: parent
                    radius: 16
                    visible: false
                }

                Image {
                    anchors.fill: parent
                    source: (hasPlayer && player.trackArtUrl) ? player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                    layer.enabled: true
                    layer.effect: OpacityMask { maskSource: largeArtMask }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.15)
                    visible: !hasPlayer || !player.trackArtUrl
                    Text {
                        anchors.centerIn: parent
                        text: "\ueafc"
                        font.family: ddMusicFont.name
                        font.pixelSize: 36
                        color: Theme.colPrimary
                    }
                }
            }

            // Right: Song Details + Controls + Progress Bar
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // 1. Song Title (3-word truncated)
                Text {
                    Layout.fillWidth: true
                    text: hasPlayer ? shortenTrackTitle(player.trackTitle, player.trackArtist, 3) : "No Track"
                    font.family: "Inter, sans-serif"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: "#FFFFFF"
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                // 2. Artist Name
                Text {
                    Layout.fillWidth: true
                    text: hasPlayer ? (player.trackArtist || "Unknown Artist") : "Unknown Artist"
                    font.family: "Inter, sans-serif"
                    font.pixelSize: 13
                    color: Qt.rgba(1, 1, 1, 0.65)
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Item { Layout.fillHeight: true }

                // 3. Media Controls Row (Previous | Play/Pause | Next)
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20

                    // Previous Button
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

                    // Play / Pause Button
                    MouseArea {
                        width: 32; height: 32
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (hasPlayer) player.togglePlaying()
                        Text {
                            anchors.centerIn: parent
                            text: isPlaying ? "\ued45" : "\ued46"
                            font.family: ddMusicFont.name
                            font.pixelSize: 22
                            color: "#FFFFFF"
                        }
                    }

                    // Next Button
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

                // 4. Progress Bar
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

                Item { height: 4 }

                // 5. Timestamps
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
}
