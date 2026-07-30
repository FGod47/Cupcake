pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../common"

Item {
    id: solidBoardRoot
    
    // We expect this to fill the parent container in BarSolid
    anchors.fill: parent

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        ClockWidget {
            Layout.alignment: Qt.AlignHCenter
        }

        CalendarWidget {
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
