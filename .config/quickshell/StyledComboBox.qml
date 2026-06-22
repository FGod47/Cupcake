import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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
    
    property string searchText: ""
    
    popup: Popup {
        y: customComboBox.height - 1
        width: customComboBox.width
        implicitHeight: contentLayout.implicitHeight + 8
        height: Math.min(250, implicitHeight)
        padding: 4
        
        onOpened: {
            customComboBox.searchText = "";
            searchInput.text = "";
            searchInput.forceActiveFocus();
        }

        contentItem: ColumnLayout {
            id: contentLayout
            spacing: 4
            
            TextField {
                id: searchInput
                Layout.fillWidth: true
                placeholderText: "Search..."
                color: Theme.colOnSurface
                font.family: Theme.defaultFontFamily
                font.pixelSize: 14
                background: Rectangle {
                    color: Theme.colSurfaceContainer
                    border.color: Theme.colOutline
                    border.width: 1
                    radius: 4
                }
                onTextEdited: customComboBox.searchText = text.toLowerCase()
            }
            
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                implicitHeight: contentHeight
                
                // Filter the model
                model: {
                    if (!customComboBox.model) return [];
                    // if it's an integer (like model: 10), it's not array-like in the same way, but we assume string arrays for fonts
                    if (!Array.isArray(customComboBox.model) && typeof customComboBox.model !== 'object') {
                        return customComboBox.model;
                    }
                    let arr = [];
                    for (let i = 0; i < customComboBox.model.length; i++) {
                        let txt = customComboBox.model[i];
                        if (typeof txt === 'string' && txt.toLowerCase().includes(customComboBox.searchText)) {
                            arr.push(txt);
                        } else if (typeof txt === 'object' && txt.label && txt.label.toLowerCase().includes(customComboBox.searchText)) {
                            arr.push(txt);
                        } else if (customComboBox.searchText === "") {
                            arr.push(txt);
                        }
                    }
                    return arr;
                }
                
                delegate: ItemDelegate {
                    width: customComboBox.width - 8
                    padding: 8
                    
                    property string itemText: typeof modelData === 'object' ? modelData.label : modelData
                    
                    contentItem: Text {
                        text: itemText
                        color: customComboBox.currentText === itemText ? Theme.colOnPrimary : Theme.colOnSurface
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 14
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: customComboBox.currentText === itemText ? Theme.colPrimary : (hovered ? Theme.colSurfaceContainerHigh : "transparent")
                        radius: 4
                    }
                    onClicked: {
                        // find original index
                        let originalIdx = -1;
                        for (let i = 0; i < customComboBox.model.length; i++) {
                            let txt = typeof customComboBox.model[i] === 'object' ? customComboBox.model[i].label : customComboBox.model[i];
                            if (txt === itemText) {
                                originalIdx = i;
                                break;
                            }
                        }
                        if (originalIdx !== -1) {
                            customComboBox.currentIndex = originalIdx;
                            customComboBox.activated(originalIdx);
                        }
                        customComboBox.popup.close();
                    }
                }
                ScrollIndicator.vertical: ScrollIndicator { }
            }
        }

        background: Rectangle {
            border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.5)
            border.width: 1
            color: Theme.colSurfaceContainerHigh
            radius: 6
        }
    }
}
