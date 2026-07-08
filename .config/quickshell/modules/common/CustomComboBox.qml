import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"

ComboBox {
    id: control
    Layout.preferredWidth: 160
    Layout.preferredHeight: 32
    indicator: Text {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: "\uea5f"
        font.family: "tabler-icons"
        color: Theme.colOnSurfaceVariant
    }
    background: Rectangle { color: Qt.rgba(0, 0, 0, 0.28); radius: 8 }
    contentItem: Text {
        text: control.currentText
        font.family: Theme.defaultFontFamily
        font.pixelSize: 13
        color: Theme.colOnSurface
        verticalAlignment: Text.AlignVCenter
        anchors.left: parent.left
        anchors.leftMargin: 12
    }
    popup: Popup {
        y: control.height + 4
        width: control.width
        implicitHeight: contentItem.implicitHeight
        padding: 4
        contentItem: ListView {
            clip: true
            implicitHeight: Math.min(contentHeight, 200)
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator { }
        }
        background: Rectangle {
            color: Theme.colSurfaceContainerHigh
            border.color: Theme.colOutline
            border.width: 1
            radius: 8
        }
    }
    delegate: ItemDelegate {
        width: control.popup.width - 8
        height: 32
        highlighted: control.highlightedIndex === index
        required property string modelData
        required property int index
        onClicked: {
            control.currentIndex = index
            control.popup.close()
            control.activated(index)
        }
        background: Rectangle {
            color: highlighted ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.1) : "transparent"
            radius: 6
        }
        contentItem: Text {
            text: modelData
            font.family: Theme.defaultFontFamily
            font.pixelSize: 13
            color: Theme.colOnSurface
            verticalAlignment: Text.AlignVCenter
        }
    }
}
