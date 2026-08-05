import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
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

    x: (bar.screenW / 2) - (contentW / 2)
    width: contentW

    Behavior on x     { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
    Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }

    radius: menuExpanded ? 24 : 15
    Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    clip: true

    color: bar.pillColor
    border.color: Qt.rgba(1, 1, 1, 0.12)
    border.width: 1

    // Top glass highlight line
    Rectangle {
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        anchors.leftMargin: 4; anchors.rightMargin: 4
        height: 1; radius: 1
        color: Qt.rgba(1, 1, 1, 0.12)
    }

    opacity: bar.isMusicPlaying ? 1.0 : 0.0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }

    FontLoader {
        id: ddMusicFont
        source: Qt.resolvedUrl("file://" + Quickshell.env("HOME") + "/.local/share/fonts/tabler-icons.ttf")
    }

    function formatTime(microseconds) {
        if (!microseconds || isNaN(microseconds)) return "0:00";
        let seconds = Math.floor(microseconds / 1000000);
        let m = Math.floor(seconds / 60);
        let s = seconds % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    // ── COLLAPSED HEADER ROW (Shown inside split pill) ──
    Row {
        id: musicHeaderRow
        anchors.horizontalCenter: parent.horizontalCenter
        y: (30 - height) / 2
        spacing: 6
        opacity: musicSplitPill.menuExpanded ? 0.0 : 1.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Text {
            text: "\ueabd" // tabler headphones/music icon
            font.family: "tabler-icons"
            font.pixelSize: 13
            color: Theme.colPrimary
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            width: Math.min(implicitWidth, 140)
            text: {
                if (!hasPlayer) return "";
                let title = player.trackTitle || "Music";
                let artist = player.trackArtist || "";
                return artist ? (title + " · " + artist) : title;
            }
            font.family: Theme.defaultFontFamily
            font.pixelSize: 11
            font.weight: Theme.defaultFontWeight
            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.85)
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            maximumLineCount: 1
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

            MouseArea {
                width: 32; height: 32
                cursorShape: Qt.PointingHandCursor
                property bool liked: false
                onClicked: liked = !liked

                Text {
                    anchors.centerIn: parent
                    text: parent.liked ? "\uea82" : "\uea83"
                    font.family: ddMusicFont.name
                    font.pixelSize: 18
                    color: parent.liked ? "#ff6b6b" : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                }
            }
        }

        // Middle Row: Progress Slider Line
        Item {
            Layout.fillWidth: true
            height: 6

            Rectangle {
                anchors.fill: parent
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.10)

                Rectangle {
                    height: parent.height
                    width: (hasPlayer && player.length > 0) ? (parent.width * (player.position / player.length)) : 0
                    radius: 3
                    color: Theme.colPrimary
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

            Text {
                text: "\uf85d"
                font.family: ddMusicFont.name
                font.pixelSize: 16
                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
            }

            Rectangle {
                width: 38; height: 38; radius: 19
                color: Qt.rgba(1, 1, 1, 0.10)

                Text {
                    anchors.centerIn: parent
                    text: isPlaying ? "\uea8c" : "\ueaed"
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
