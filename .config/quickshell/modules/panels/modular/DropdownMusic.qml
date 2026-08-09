import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import "../../../theme"

// ── MUSIC SPLIT PILL & MORPHING PLAYER ──
Rectangle {
    id: musicSplitPill
    y: bar.midY + bar.barHeight + 8
    property bool menuExpanded: bar.musicDropdownOpen
    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool hasPlayer: player !== null
    property bool isPlaying: hasPlayer ? (player.playbackState === 1 || player.isPlaying) : false

    readonly property real expandedW: 340
    readonly property real expandedH: 156
    readonly property real artMargin: 8
    readonly property real artSizeExpanded: 140

    property real contentW: expandedW

    readonly property int dur: 350
    readonly property int easingType: Easing.OutQuart

    height: menuExpanded ? expandedH : 0
    Behavior on height { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }

    x: bar.barX + 4
    width: contentW
    Behavior on x     { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }
    Behavior on width { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }

    radius: 16
    Behavior on radius { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }
    clip: true
    color: bar.pillColor

    HoverHandler { id: pillHover; enabled: true }
    property bool isHovered: (isPlaying || menuExpanded) && (pillHover.hovered || musicHeaderMa.containsMouse)

    opacity: bar.musicDropdownOpen ? 1.0 : 0.0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }

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
        let t = title;
        // Step 1: If title contains " - ", extract song title (part after hyphen)
        if (t.indexOf(" - ") !== -1) {
            let parts = t.split(" - ");
            t = parts[1];
        }
        // Step 2: Strip pipe metadata "| ..."
        if (t.indexOf("|") !== -1) t = t.split("|")[0];
        // Step 3: Strip parenthetical/bracketed tags like (Official Video), [HD]
        t = t.replace(/\s*[([].*?[)\]]/gi, "");
        return t.trim() || title.trim() || "No Track";
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

        // Small art layout placeholder (floatingAlbumArt renders over this in collapsed state)
        Item {
            width: 22; height: 22
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id: compactTitleSpacer
            text: hasPlayer ? shortenTitle(player.trackTitle, player.trackArtist, 3) : "No Track"
            font.family: "Inter, sans-serif"
            font.pixelSize: 15
            font.weight: Font.Bold
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            maximumLineCount: 1
            width: Math.min(implicitWidth, 220) * (11.0 / 15.0)
            opacity: 0
        }

        Item {
            width: 22; height: 22
            anchors.verticalCenter: parent.verticalCenter
            Shape {
                width: 24; height: 24
                anchors.centerIn: parent
                vendorExtensionsEnabled: false
                scale: 15 / 24
                ShapePath {
                    fillColor: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
                    strokeColor: "transparent"
                    PathSvg {
                        path: isPlaying
                            ? "M9 4h-2a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h2a2 2 0 0 0 2 -2v-12a2 2 0 0 0 -2 -2z M17 4h-2a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h2a2 2 0 0 0 2 -2v-12a2 2 0 0 0 -2 -2z"
                            : "M6 4v16a1 1 0 0 0 1.524 .852l13 -8a1 1 0 0 0 0 -1.704l-13 -8a1 1 0 0 0 -1.524 .852z"
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (hasPlayer) player.togglePlaying()
            }
        }
    }

    // ── HARDWARE-ACCELERATED MORPHING ALBUM ART ──
    Rectangle {
        id: floatingArtMask
        width: artSizeExpanded
        height: artSizeExpanded
        radius: musicSplitPill.menuExpanded ? 16 : 70
        Behavior on radius { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }
        visible: false
    }

    Item {
        id: floatingArtContainer
        width: artSizeExpanded
        height: artSizeExpanded
        z: 15

        x: musicSplitPill.menuExpanded ? artMargin : 10
        y: musicSplitPill.menuExpanded ? artMargin : 4

        readonly property real compactScale: 22.0 / artSizeExpanded
        scale: musicSplitPill.menuExpanded ? 1.0 : compactScale
        transformOrigin: Item.TopLeft

        Behavior on x     { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }
        Behavior on y     { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }
        Behavior on scale { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }

        Image {
            id: floatingAlbumArt
            anchors.fill: parent
            source: (hasPlayer && player.trackArtUrl) ? player.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            opacity: (hasPlayer && player.trackArtUrl && status === Image.Ready) ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 250 } }
            layer.enabled: true
            layer.effect: OpacityMask { maskSource: floatingArtMask }
        }

        // Fallback Gradient + Note Icon + "now playing" doodle badge
        Rectangle {
            anchors.fill: parent
            radius: 16
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#ff9ad0" }
                GradientStop { position: 0.45; color: "#b28bff" }
                GradientStop { position: 1.0; color: "#4a2f9e" }
            }
            opacity: floatingAlbumArt.status !== Image.Ready ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 250 } }

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
    }

    // ── MORPHING TRACK TITLE ──
    Text {
        id: morphingTrackTitle
        text: hasPlayer ? shortenTitle(player.trackTitle, player.trackArtist, 3) : "No Track"
        font.family: "Inter, sans-serif"
        font.pixelSize: 15
        font.weight: Font.Bold
        color: "#FFFFFF"
        elide: Text.ElideRight
        maximumLineCount: 1
        z: 20

        x: musicSplitPill.menuExpanded ? (artMargin + artSizeExpanded + 14) : 40
        y: musicSplitPill.menuExpanded ? 18 : (musicHeaderRow.y + compactTitleSpacer.y)
        width: musicSplitPill.menuExpanded
            ? (expandedW - (artMargin + artSizeExpanded + 14) - 14)
            : Math.min(compactTitleSpacer.implicitWidth + 10, 220)

        scale: musicSplitPill.menuExpanded ? 1.0 : (11.0 / 15.0)
        transformOrigin: Item.Left

        Behavior on x     { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }
        Behavior on y     { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }
        Behavior on width { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }
        Behavior on scale { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }
    }

    // ── CLICK HANDLER ──
    MouseArea {
        id: musicHeaderMa
        anchors.fill: parent
        enabled: bar.keepMusicAlive
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
        anchors.leftMargin: artMargin + artSizeExpanded + 14   // 162px
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.top: parent.top
        anchors.topMargin: 18
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12

        opacity: musicSplitPill.menuExpanded ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 350; easing.type: musicSplitPill.easingType } }

        transform: Translate {
            y: musicSplitPill.menuExpanded ? 0 : 25
            Behavior on y { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }
        }

        Column {
            anchors.fill: parent
            spacing: 0

            // 1. Reserved space for morphingTrackTitle
            Item { width: parent.width; height: 18 }

            Text {
                width: parent.width
                text: hasPlayer ? (player.trackArtist || "Unknown Artist") : "Unknown Artist"
                font.family: "Inter, sans-serif"
                font.pixelSize: 11
                color: Qt.rgba(1, 1, 1, 0.55)
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Item { width: parent.width; height: 12 }

            // 2. Media Controls (Prev | Play/Pause | Next)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                height: 32
                spacing: 12

                // Prev
                Rectangle {
                    width: 26; height: 26
                    radius: 13
                    anchors.verticalCenter: parent.verticalCenter
                    color: prevMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Shape {
                        width: 24; height: 24
                        anchors.centerIn: parent
                        vendorExtensionsEnabled: false
                        scale: 14 / 24
                        ShapePath {
                            fillColor: "#FFFFFF"
                            strokeColor: "transparent"
                            PathSvg {
                                path: "M4.576 4.148a1 1 0 0 0 -1.576 .852v14a1 1 0 0 0 1.524 .852l.096 -.007a1 1 0 0 0 .804 -.845v-5.172l9.524 5.872a1 1 0 0 0 1.476 -.852v-14a1 1 0 0 0 -1.476 -.852l-9.524 5.872v-5.172a1 1 0 0 0 -1 -1z"
                            }
                        }
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
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(1, 1, 1, playMa.containsMouse ? 0.22 : 0.14)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Shape {
                        width: 24; height: 24
                        anchors.centerIn: parent
                        vendorExtensionsEnabled: false
                        scale: 16 / 24
                        ShapePath {
                            fillColor: "#FFFFFF"
                            strokeColor: "transparent"
                            PathSvg {
                                path: isPlaying
                                    ? "M9 4h-2a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h2a2 2 0 0 0 2 -2v-12a2 2 0 0 0 -2 -2z M17 4h-2a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h2a2 2 0 0 0 2 -2v-12a2 2 0 0 0 -2 -2z"
                                    : "M6 4v16a1 1 0 0 0 1.524 .852l13 -8a1 1 0 0 0 0 -1.704l-13 -8a1 1 0 0 0 -1.524 .852z"
                            }
                        }
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
                    anchors.verticalCenter: parent.verticalCenter
                    color: nextMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Shape {
                        width: 24; height: 24
                        anchors.centerIn: parent
                        vendorExtensionsEnabled: false
                        scale: 14 / 24
                        ShapePath {
                            fillColor: "#FFFFFF"
                            strokeColor: "transparent"
                            PathSvg {
                                path: "M19.424 4.148a1 1 0 0 0 -1.424 .852v5.172l-9.524 -5.872a1 1 0 0 0 -1.476 .852v14a1 1 0 0 0 1.476 .852l9.524 -5.872v5.172a1 1 0 0 0 1.524 .852l.096 -.007a1 1 0 0 0 .804 -.845v-14a1 1 0 0 0 -1 -1z"
                            }
                        }
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

            Item { width: parent.width; height: 18 }

            // 3. Progress Bar & Slider
            Item {
                id: progressWrapper
                width: parent.width
                height: 14

                property real currentPosition: hasPlayer ? player.position : 0
                property real progress: (hasPlayer && player.length > 0) ? Math.max(0, Math.min(1, currentPosition / player.length)) : 0
                property bool isHovered: seekMa.containsMouse || seekMa.pressed

                Timer {
                    interval: 1000
                    running: hasPlayer && isPlaying && !seekMa.pressed
                    repeat: true
                    onTriggered: { if (hasPlayer) progressWrapper.currentPosition = player.position; }
                }

                // Track background container
                Rectangle {
                    id: progressTrack
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: progressWrapper.isHovered ? 6 : 4
                    radius: height / 2
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.15)
                    clip: true

                    Behavior on height { NumberAnimation { duration: 150 } }
                    Behavior on radius { NumberAnimation { duration: 150 } }

                    // Fill bar
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * progressWrapper.progress
                        radius: parent.radius
                        color: Theme.colPrimary
                        Behavior on width { enabled: !seekMa.pressed; NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
                    }
                }

                // Smooth Draggable Knob / Handle
                Rectangle {
                    width: 12; height: 12
                    radius: 6
                    x: Math.max(0, Math.min(progressWrapper.width - width, (progressWrapper.width * progressWrapper.progress) - (width / 2)))
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.colPrimary
                    opacity: progressWrapper.isHovered ? 1.0 : 0.0
                    scale: progressWrapper.isHovered ? (seekMa.pressed ? 1.25 : 1.0) : 0.4
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on scale   { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                    Behavior on x       { enabled: !seekMa.pressed; NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
                }

                MouseArea {
                    id: seekMa
                    anchors.fill: parent
                    hoverEnabled: true
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

            Item { width: parent.width; height: 4 }

            // 4. Timestamps (staggered slide-up from below progress bar after expansion)
            Item {
                id: timestampWrapper
                width: parent.width
                height: 14

                opacity: musicSplitPill.menuExpanded ? 1.0 : 0.0
                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation { duration: musicSplitPill.menuExpanded ? 120 : 0 }
                        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                }

                transform: Translate {
                    y: musicSplitPill.menuExpanded ? 0 : 16
                    Behavior on y {
                        SequentialAnimation {
                            PauseAnimation { duration: musicSplitPill.menuExpanded ? 120 : 0 }
                            NumberAnimation { duration: 550; easing.type: Easing.OutCubic }
                        }
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: hasPlayer ? formatTime(progressWrapper.currentPosition) : "0:00"
                    font.family: "Inter, sans-serif"
                    font.pixelSize: 10
                    color: Qt.rgba(1, 1, 1, 0.5)
                }
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: hasPlayer ? formatRemaining(progressWrapper.currentPosition, player.length) : "-0:00"
                    font.family: "Inter, sans-serif"
                    font.pixelSize: 10
                    color: Qt.rgba(1, 1, 1, 0.5)
                }
            }
        }
    }
}
