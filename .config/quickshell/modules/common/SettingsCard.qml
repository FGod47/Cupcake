import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"

Rectangle {
    id: cardRoot
    property string title: ""
    property string description: ""
    property string icon: ""
    
    // Colors
    property color cSurface: Theme.isDark ? "#171c24" : "#ffffff"
    property color cBorder: Theme.isDark ? "#242b36" : "#dde1e7"
    property color cTextFaint: Theme.isDark ? "#4d5566" : "#9aa2af"
    
    default property alias content: innerLayout.data

    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight
    color: cSurface
    radius: 10
    border.color: cBorder
    border.width: 1
    clip: true

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.topMargin: 0
        anchors.bottomMargin: 0
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        spacing: 0

        // Card Title Header
        Item {
            Layout.fillWidth: true
            implicitHeight: titleLayout.implicitHeight + 13
            visible: cardRoot.title !== ""
            
            RowLayout {
                id: titleLayout
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 13
                anchors.bottomMargin: 0
                spacing: 8
                
                Text { 
                    visible: cardRoot.icon !== ""
                    text: cardRoot.icon
                    color: cTextFaint
                    font.pixelSize: 13
                    font.family: Theme.monoFontFamily 
                }
                Text { 
                    text: cardRoot.title
                    color: cTextFaint
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 11
                    font.weight: 600
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 0.6
                    Layout.fillWidth: true 
                }
            }
        }
        
        // Rows inside innerLayout will handle their own borders/padding
        ColumnLayout {
            id: innerLayout
            Layout.fillWidth: true
            spacing: 0
        }
    }
}
