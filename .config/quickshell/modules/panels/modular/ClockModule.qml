import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Widgets
import Quickshell
import Qt5Compat.GraphicalEffects
import "../../../theme"

Row {
    id: clockRow
    spacing: 4
    
    property color fg: Theme.colOnSurface
    property string fontName: "JetBrainsMono Nerd Font"

    SystemClock {
        id: timeClock
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(timeClock.date, "hh:mm AP")
        font.family: Theme.defaultFontFamily
        font.pixelSize: Theme.defaultFontSize
        font.weight: Theme.defaultFontWeight
        color: fg
    }
}
