pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../common"

Item {
    id: solidBoardRoot
    
    // We expect this to fill the parent container in BarSolid
    anchors.fill: parent

    GridLayout {
        id: contentGrid
        anchors.fill: parent
        anchors.margins: 24
        rowSpacing: 16
        columnSpacing: 16
        columns: 6

        // Left side placeholder (spans 4 columns)
        Rectangle {
            Layout.columnSpan: 4
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            radius: 16
            
            Text {
                anchors.centerIn: parent
                text: "Other Widgets"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 18
                color: Theme.fg
                opacity: 0.5
            }
        }

        // Right side column (Clock + Calendar, spans 2 columns)
        ColumnLayout {
            Layout.columnSpan: 2
            Layout.alignment: Qt.AlignRight | Qt.AlignTop
            spacing: 16

            ClockWidget {
                Layout.alignment: Qt.AlignRight
            }

            CalendarWidget {
                Layout.alignment: Qt.AlignRight
            }
        }
    }
}
