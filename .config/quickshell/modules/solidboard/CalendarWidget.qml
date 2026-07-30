import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import "../common"

Rectangle {
    id: calWidget
    width: 320
    implicitHeight: mainLayout.implicitHeight + 32
    color: Qt.rgba(Theme.colSurfaceContainer.r, Theme.colSurfaceContainer.g, Theme.colSurfaceContainer.b, 0.5)
    radius: 16
    border.color: Qt.rgba(1, 1, 1, 0.05)
    border.width: 1
    clip: true

    property date currentDate: new Date()

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                Layout.fillWidth: true
                text: Qt.formatDateTime(calWidget.currentDate, "MMMM yyyy")
                font.family: Theme.defaultFontFamily
                font.pixelSize: Theme.defaultFontSize + 2
                font.weight: Font.Bold
                color: Theme.colOnSurface
            }

            // Month navigation
            RowLayout {
                spacing: 8
                
                MouseArea {
                    width: 24; height: 24
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let d = new Date(calWidget.currentDate);
                        d.setMonth(d.getMonth() - 1);
                        calWidget.currentDate = d;
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "\uea60" // chevron-left
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                        color: Theme.colOnSurface
                    }
                }
                MouseArea {
                    width: 24; height: 24
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let d = new Date(calWidget.currentDate);
                        d.setMonth(d.getMonth() + 1);
                        calWidget.currentDate = d;
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "\uea61" // chevron-right
                        font.family: "tabler-icons"
                        font.pixelSize: 16
                        color: Theme.colOnSurface
                    }
                }
            }
        }

        // Calendar Grid
        DayOfWeekRow {
            Layout.fillWidth: true
            locale: monthGrid.locale
            font.family: Theme.defaultFontFamily
            font.pixelSize: Theme.defaultFontSize - 2
            delegate: Text {
                text: model.shortName
                font.family: Theme.defaultFontFamily
                font.pixelSize: Theme.defaultFontSize - 2
                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.6)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        MonthGrid {
            id: monthGrid
            Layout.fillWidth: true
            month: calWidget.currentDate.getMonth()
            year: calWidget.currentDate.getFullYear()
            locale: Qt.locale("en_US")
            font.family: Theme.defaultFontFamily
            font.pixelSize: Theme.defaultFontSize
            spacing: 4

            delegate: Rectangle {
                implicitWidth: 32
                implicitHeight: 32
                radius: 16
                color: model.today ? Theme.colPrimary : (cellMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent")
                
                Text {
                    anchors.centerIn: parent
                    text: model.day
                    font: monthGrid.font
                    color: model.today ? Theme.colOnPrimary : (model.month === monthGrid.month ? Theme.colOnSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.3))
                }
                
                MouseArea {
                    id: cellMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }
}
