import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../../theme"
import Qt5Compat.GraphicalEffects

Rectangle {
    id: musicWidget
    Layout.fillWidth: true
    Layout.preferredHeight: 170
    radius: 20
    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)


    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool hasPlayer: player !== null

    // For position slider
    property real uiPosition: player ? player.position : 0
    property bool dragging: false

    Timer {
        interval: 1000
        running: hasPlayer && player.isPlaying && !musicWidget.dragging
        repeat: true
        onTriggered: musicWidget.uiPosition = player.position
    }

    Connections {
        target: player
        function onPositionChanged() {
            if (!musicWidget.dragging) musicWidget.uiPosition = player.position;
        }
    }

    function formatTime(microseconds) {
        if (!microseconds) return "0:00";
        let seconds = Math.floor(microseconds / 1000000);
        let m = Math.floor(seconds / 60);
        let s = seconds % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Top Row: Art + Info + Actions
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Art/Icon
            Item {
                width: 52
                height: 52

                Rectangle {
                    id: widgetArtMask
                    anchors.fill: parent
                    radius: 14
                    visible: false
                }

                // Fallback music icon if no track art is loaded
                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.1)
                    visible: widgetArtImage.status !== Image.Ready

                    Text {
                        anchors.centerIn: parent
                        text: "\ueafc" // music icon
                        font.family: "tabler-icons"
                        font.pixelSize: 26
                        color: Theme.colPrimary
                    }
                }

                Image {
                    id: widgetArtImage
                    anchors.fill: parent
                    source: (hasPlayer && player.trackArtUrl) ? player.trackArtUrl : ""
                    visible: status === Image.Ready
                    fillMode: Image.PreserveAspectCrop
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: widgetArtMask
                    }
                }
            }

            // Title & Artist
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: hasPlayer ? (player.trackTitle || "Unknown Track") : "No Media Playing"
                    color: Theme.colOnSurface
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: hasPlayer ? (player.trackArtist || "Unknown Artist") : "Waiting for player..."
                    color: Theme.colOnSurfaceVariant
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Right Buttons
            RowLayout {
                spacing: 8
                
                Rectangle {
                    width: 34; height: 34; radius: 10
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text { anchors.centerIn: parent; text: "\ueabe"; font.family: "tabler-icons"; font.pixelSize: 18; color: Theme.colOnSurfaceVariant } // heart
                }
                Rectangle {
                    width: 34; height: 34; radius: 10
                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    Text { anchors.centerIn: parent; text: "\uea95"; font.family: "tabler-icons"; font.pixelSize: 18; color: Theme.colOnSurfaceVariant } // dots
                }
            }
        }

        // Progress Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 4
            height: 4
            radius: 2
            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.1)

            Rectangle {
                height: parent.height
                width: hasPlayer && player.length > 0 ? (musicWidget.uiPosition / player.length) * parent.width : 0
                color: Theme.colPrimary
                radius: 2
            }
            
            Rectangle {
                width: 12
                height: 12
                radius: 6
                color: "#ffffff"
                y: -4
                x: hasPlayer && player.length > 0 ? (musicWidget.uiPosition / player.length) * parent.width - width / 2 : 0
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -10
                onPressed: mouse => {
                    musicWidget.dragging = true
                    let percent = Math.max(0, Math.min(1, mouse.x / width))
                    if (hasPlayer && player.length > 0) musicWidget.uiPosition = percent * player.length
                }
                onPositionChanged: mouse => {
                    if (musicWidget.dragging) {
                        let percent = Math.max(0, Math.min(1, mouse.x / width))
                        if (hasPlayer && player.length > 0) musicWidget.uiPosition = percent * player.length
                    }
                }
                onReleased: mouse => {
                    if (musicWidget.dragging && hasPlayer && player.length > 0) {
                        let percent = Math.max(0, Math.min(1, mouse.x / width))
                        player.position = percent * player.length
                    }
                    musicWidget.dragging = false
                }
            }
        }

        // Timeline text
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: -8 // move it up a bit since progress bar spacing
            
            Text {
                text: formatTime(musicWidget.uiPosition)
                color: Theme.colOnSurfaceVariant
                font.family: Theme.defaultFontFamily
                font.pixelSize: 11
            }

            Item { Layout.fillWidth: true } // spacer

            Text {
                text: hasPlayer && player.length > 0 ? formatTime(player.length) : "0:00"
                color: Theme.colOnSurfaceVariant
                font.family: Theme.defaultFontFamily
                font.pixelSize: 11
            }
        }

        // Controls
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            Text {
                text: "\uf000" // shuffle
                font.family: "tabler-icons"
                font.pixelSize: 18
                color: Theme.colOnSurfaceVariant
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true } // spacer

            Rectangle {
                width: 40; height: 40; radius: 20
                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
                Text { anchors.centerIn: parent; text: "\ued48"; font.family: "tabler-icons"; font.pixelSize: 20; color: Theme.colOnSurface } // prev (skip-back)
                MouseArea { anchors.fill: parent; onClicked: if (hasPlayer) player.previous() }
            }

            Item { // Wrapper for glow effect (simulated with a background rectangle)
                width: 48; height: 48
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 4; height: parent.height - 4
                    radius: 22
                    color: Theme.colPrimary
                    opacity: 0.4
                    scale: 1.15
                    visible: hasPlayer && player.isPlaying // subtle glow when playing
                }
                Rectangle {
                    anchors.fill: parent
                    radius: 24
                    color: Theme.colPrimary
                    Text {
                        anchors.centerIn: parent
                        text: hasPlayer && player.isPlaying ? "\ued45" : "\ued46" // pause / play
                        font.family: "tabler-icons"
                        font.pixelSize: 24
                        color: Theme.colSurface
                    }
                    MouseArea { anchors.fill: parent; onClicked: if (hasPlayer) player.togglePlaying() }
                }
            }

            Rectangle {
                width: 40; height: 40; radius: 20
                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
                Text { anchors.centerIn: parent; text: "\ued49"; font.family: "tabler-icons"; font.pixelSize: 20; color: Theme.colOnSurface } // next (skip-forward)
                MouseArea { anchors.fill: parent; onClicked: if (hasPlayer) player.next() }
            }

            Item { Layout.fillWidth: true } // spacer

            Text {
                text: "\ueb72" // repeat
                font.family: "tabler-icons"
                font.pixelSize: 18
                color: Theme.colOnSurfaceVariant
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
