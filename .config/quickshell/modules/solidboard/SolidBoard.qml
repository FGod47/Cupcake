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

        // Placeholder for the widgets we'll build
        Text {
            Layout.columnSpan: 6
            Layout.alignment: Qt.AlignCenter
            text: "SolidBoard grid inside the Bar! (coming soon)"
            font.family: Theme.defaultFontFamily
            font.pixelSize: 18
            color: Theme.fg || "white"
        }
    }
}
