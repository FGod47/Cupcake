import QtQuick
import QtQuick.Controls
import "../../theme"

TextField {
    id: customTextField
    
    color: Theme.colOnSurface
    font.family: Theme.defaultFontFamily
    font.pixelSize: 14
    
    background: Rectangle {
        implicitWidth: 150
        implicitHeight: 32
        color: Theme.colSurfaceContainer
        border.color: customTextField.activeFocus ? Theme.colPrimary : Theme.colOutline
        border.width: customTextField.activeFocus ? 2 : 1
        radius: 4
    }
}
