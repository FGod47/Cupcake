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
    
    editable: true
    
    contentItem: TextField {
        text: customComboBox.editText
        color: Theme.colOnSurface
        font.family: Theme.defaultFontFamily
        font.pixelSize: 14
        verticalAlignment: Text.AlignVCenter
        leftPadding: 12
        background: Item {} // Transparent background
        
        onTextEdited: {
            customComboBox.editText = text
            let match = customComboBox.find(text, Qt.MatchContains)
            if (match !== -1) {
                customComboBox.currentIndex = match
            }
        }
    }
    
    delegate: ItemDelegate {
        width: customComboBox.width
        padding: 8
        contentItem: Text {
            text: modelData
            color: highlighted ? Theme.colOnPrimary : Theme.colOnSurface
            font.family: Theme.defaultFontFamily
            font.pixelSize: 14
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: highlighted ? Theme.colPrimary : "transparent"
            radius: 4
        }
    }

    popup: Popup {
        y: customComboBox.height - 1
        width: customComboBox.width
        implicitHeight: contentItem.implicitHeight
        height: Math.min(250, implicitHeight)
        padding: 4

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: customComboBox.popup.visible ? customComboBox.delegateModel : null
            currentIndex: customComboBox.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator { }
        }

        background: Rectangle {
            border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.5)
            border.width: 1
            color: Theme.colSurfaceContainerHigh
            radius: 6
        }
    }
}
