import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../../../theme"

// ── Bar Music Module ──
// Displays compact currently playing music track + artist in the bar.
// Clicking it toggles the separated music split pill dropdown.
Item {
    id: barMusic
    property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool isPlaying: activePlayer ? (activePlayer.playbackState === 1 || activePlayer.isPlaying) : false

    implicitWidth: musicRow.implicitWidth
    implicitHeight: 20
    visible: activePlayer !== null && (activePlayer.trackTitle !== "" || isPlaying)
    opacity: (bar.musicDropdownOpen || bar.netDropdownOpen || bar.dropdownOpen) ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }

    FontLoader {
        id: musicIconFont
        source: Qt.resolvedUrl("file://" + Quickshell.env("HOME") + "/.local/share/fonts/tabler-icons.ttf")
    }

    Row {
        id: musicRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        // Separator dot
        Text {
            text: "•"
            font.family: Theme.defaultFontFamily
            font.pixelSize: 13
            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.3)
            anchors.verticalCenter: parent.verticalCenter
        }

        // Music icon
        Text {
            text: "\ueabd" // tabler headphones icon
            font.family: musicIconFont.name
            font.pixelSize: 13
            color: Theme.colPrimary
            anchors.verticalCenter: parent.verticalCenter
        }

        // Track title & artist
        Text {
            width: Math.min(implicitWidth, 160)
            text: {
                if (!activePlayer) return "";
                let title = activePlayer.trackTitle || "Music";
                let artist = activePlayer.trackArtist || "";
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

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (bar.dropdownOpen) bar.dropdownOpen = false;
            if (bar.netDropdownOpen) bar.netDropdownOpen = false;
            bar.musicDropdownOpen = !bar.musicDropdownOpen;
        }
    }
}
