import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell
import "../../theme"
import "../common"

Rectangle {
    id: clockWidget
    width: 320
    implicitHeight: 100
    color: Qt.rgba(Theme.colSurfaceContainer.r, Theme.colSurfaceContainer.g, Theme.colSurfaceContainer.b, 0.5)
    radius: 16
    border.color: Qt.rgba(1, 1, 1, 0.05)
    border.width: 1

    SystemClock { id: timeClock; precision: SystemClock.Minutes }

    RowLayout {
        anchors.centerIn: parent
        spacing: 12

        Text {
            text: Qt.formatDateTime(timeClock.date, "hh")
            font.family: Theme.defaultFontFamily
            font.pixelSize: 48
            font.weight: Font.Bold
            color: Theme.colPrimary
        }

        Text {
            text: ":"
            font.family: Theme.defaultFontFamily
            font.pixelSize: 48
            font.weight: Font.Bold
            color: Theme.colOnSurface
            opacity: 0.5
        }

        Text {
            text: Qt.formatDateTime(timeClock.date, "mm")
            font.family: Theme.defaultFontFamily
            font.pixelSize: 48
            font.weight: Font.Bold
            color: Theme.colOnSurface
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            
            Text {
                text: Qt.formatDateTime(timeClock.date, "AP")
                font.family: Theme.defaultFontFamily
                font.pixelSize: 14
                font.weight: Font.Bold
                color: Theme.colPrimary
            }
            Text {
                text: Qt.formatDateTime(timeClock.date, "ddd")
                font.family: Theme.defaultFontFamily
                font.pixelSize: 14
                color: Theme.colOnSurface
                opacity: 0.6
            }
        }
    }
}
