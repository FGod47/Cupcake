import QtQuick
import QtQuick.Controls
import "theme"

ComboBox {
    id: customComboBox
    
    background: Rectangle {
        implicitWidth: 120
        implicitHeight: 32
        color: customComboBox.hovered ? Theme.colSurfaceContainerHigh : Theme.colSurfaceContainer
        border.color: Theme.colOutline
        border.width: 1
        radius: 4
    }
    
    contentItem: Text {
        text: customComboBox.displayText
        color: Theme.colOnSurface
        font.family: Theme.defaultFontFamily
        font.pixelSize: 14
        verticalAlignment: Text.AlignVCenter
        leftPadding: 12
    }
}
