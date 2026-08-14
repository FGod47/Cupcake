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
Item {
    id: musicSplitPill

    readonly property bool isAttached: Theme.barDropdownStyle === "Attached"
    y: isAttached ? (bar.midY + bar.barHeight) : (bar.midY + bar.barHeight + 8)
    Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

    property bool menuExpanded: bar.musicDropdownOpen
    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool hasPlayer: player !== null
    property bool isPlaying: hasPlayer ? (player.playbackState === 1 || player.isPlaying) : false

    readonly property real expandedW: 360
    readonly property real expandedH: 140
    readonly property real padTop: isAttached ? 22 : 14
    readonly property real padSide: isAttached ? 26 : 14
    readonly property real padBottom: isAttached ? 22 : 14
    readonly property real artSizeExpanded: 120

    property real contentW: expandedW

    readonly property int dur: 280
    readonly property int easingType: Easing.OutExpo

    height: menuExpanded ? (expandedH + padTop + padBottom) : 0
    Behavior on height { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }

    x: bar.barX + 16
    width: contentW
    Behavior on x     { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }
    Behavior on width { NumberAnimation { duration: musicSplitPill.dur; easing.type: musicSplitPill.easingType } }

    property real openProgress: menuExpanded ? 1.0 : 0.0
    property real scaleProgress: menuExpanded ? 1.0 : 0.0
    Behavior on openProgress  { NumberAnimation { duration: 260; easing.type: Easing.OutExpo } }
    Behavior on scaleProgress { NumberAnimation { duration: 260; easing.type: Easing.OutExpo } }

    opacity: openProgress
    visible: opacity > 0.01

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
        if (t.indexOf(" - ") !== -1) {
            let parts = t.split(" - ");
            t = parts[1];
        }
        if (t.indexOf("|") !== -1) t = t.split("|")[0];
        t = t.replace(/\s*[([].*?[)\]]/gi, "");
        return t.trim() || title.trim() || "No Track";
    }

    function shortenTitle(title, artist, n) {
        let t = cleanTrackTitle(title, artist);
        if (t === "No Track") return t;
        let w = t.split(/\s+/);
        return w.length > n ? w.slice(0, n).join(" ") : t;
    }

    Item {
        id: animContainer
        anchors.fill: parent
        transformOrigin: musicSplitPill.isAttached ? Item.Top : Item.Center
        scale: musicSplitPill.isAttached ? musicSplitPill.scaleProgress : 1.0
        opacity: musicSplitPill.openProgress

        // ── Attached Mode Shape ──────────────────────────────────
        Shape {
            id: bgShape
            anchors.fill: parent
            visible: musicSplitPill.isAttached
            property color shapeColor: bar.pillColor
            readonly property real r: 16
            readonly property real w: width
            readonly property real h: Math.max(height, 1)

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: bgShape.shapeColor
                startX: 0
                startY: 0

                PathArc {
                    x: bgShape.r
                    y: bgShape.r
                    radiusX: bgShape.r
                    radiusY: bgShape.r
                    direction: PathArc.Clockwise
                }
                PathLine {
                    x: bgShape.r
                    y: Math.max(bgShape.r, bgShape.h - bgShape.r)
                }
                PathQuad {
                    x: 2 * bgShape.r
                    y: bgShape.h
                    controlX: bgShape.r
                    controlY: bgShape.h
                }
                PathLine {
                    x: Math.max(2 * bgShape.r, bgShape.w - 2 * bgShape.r)
                    y: bgShape.h
                }
                PathQuad {
                    x: bgShape.w - bgShape.r
                    y: Math.max(bgShape.r, bgShape.h - bgShape.r)
                    controlX: bgShape.w - bgShape.r
                    controlY: bgShape.h
                }
                PathLine {
                    x: bgShape.w - bgShape.r
                    y: bgShape.r
                }
                PathArc {
                    x: bgShape.w
                    y: 0
                    radiusX: bgShape.r
                    radiusY: bgShape.r
                    direction: PathArc.Clockwise
                }
                PathLine {
                    x: 0
                    y: 0
                }
            }
        }

        // ── Floating Mode Shape ──────────────────────────────────
        Rectangle {
            id: bgRect
            anchors.fill: parent
            visible: !musicSplitPill.isAttached
            radius: 16
            color: bar.pillColor
        }

        // ── HARDWARE-ACCELERATED MORPHING ALBUM ART ──
        Rectangle {
            id: floatingArtMask
            width: artSizeExpanded
            height: artSizeExpanded
            radius: 16
            visible: false
        }

        Item {
            id: floatingArtContainer
            width: artSizeExpanded
            height: artSizeExpanded
            z: 15
            x: musicSplitPill.padSide
            y: musicSplitPill.padTop

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

        // ── TRACK TITLE ──
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
            x: musicSplitPill.padSide + artSizeExpanded + 14
            y: musicSplitPill.padTop + 4
            width: expandedW - (musicSplitPill.padSide + artSizeExpanded + 14) - musicSplitPill.padSide
        }

        // ── CLICK HANDLER ──
        MouseArea {
            id: musicHeaderMa
            anchors.fill: parent
            enabled: bar.keepMusicAlive
            hoverEnabled: true
            onClicked: {
                // Keep open
            }
        }

        // ── EXPANDED RIGHT COLUMN ──
        Item {
            id: expandedContent
            anchors.left: parent.left
            anchors.leftMargin: musicSplitPill.padSide + artSizeExpanded + 14
            anchors.right: parent.right
            anchors.rightMargin: musicSplitPill.padSide
            anchors.top: parent.top
            anchors.topMargin: musicSplitPill.padTop + 4
            anchors.bottom: parent.bottom
            anchors.bottomMargin: musicSplitPill.padBottom

            opacity: musicSplitPill.menuExpanded ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            Column {
                anchors.fill: parent
                spacing: 0

                // 1. Reserved space for title
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

                Item { width: parent.width; height: 10 }

                // 2. Media Controls
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

                    // Play / Pause
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

                Item { width: parent.width; height: 14 }

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

                // 4. Timestamps
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
}
