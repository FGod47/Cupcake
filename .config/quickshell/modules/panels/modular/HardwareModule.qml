import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Widgets
import Quickshell
import "../../../theme"

Row {
    id: hardwareRow
    spacing: 12
    
    property color fg: Theme.colOnSurface
    property string fontName: "JetBrainsMono Nerd Font"
    
    // Accept bar object for state properties
    property var barRef: null

    // Brightness
    MouseArea {
        id: bMouse
        width: childrenRect.width
        height: 20
        anchors.verticalCenter: parent.verticalCenter
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onEntered: { if (barRef && barRef.brightStr === "0") barRef.lightProc.running = true; }
        onClicked: {
            if (barRef) {
                if (globalState.solidBoardOpen) globalState.solidBoardOpen = false;
                if (barRef.netDropdownOpen) barRef.netDropdownOpen = false;
                barRef.dropdownOpen = !barRef.dropdownOpen;
            }
        }
        
        Row {
            height: 20
            spacing: bMouse.containsMouse ? 8 : 0
            Behavior on spacing { NumberAnimation { duration: 200 } }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: barRef ? barRef.getBrightnessIcon(barRef.brightStr) : "\uf185"
                font.family: fontName
                font.pixelSize: 15
                color: fg
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: (barRef ? barRef.brightStr : "0") + "%"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 13
                font.weight: Theme.defaultFontWeight
                color: Qt.rgba(fg.r, fg.g, fg.b, 0.7)
                width: bMouse.containsMouse ? implicitWidth : 0
                clip: true
                Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutSine } }
            }
        }
    }

    // Volume
    MouseArea {
        id: vMouse
        width: childrenRect.width
        height: 20
        anchors.verticalCenter: parent.verticalCenter
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            if (barRef) {
                if (globalState.solidBoardOpen) globalState.solidBoardOpen = false;
                if (barRef.netDropdownOpen) barRef.netDropdownOpen = false;
                barRef.dropdownOpen = !barRef.dropdownOpen;
            }
        }
        
        Row {
            height: 20
            spacing: vMouse.containsMouse ? 8 : 0
            Behavior on spacing { NumberAnimation { duration: 200 } }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: barRef ? barRef.getVolumeIcon(barRef.volStr, barRef.isVolMuted) : "\uf028"
                font.family: fontName
                font.pixelSize: 15
                color: (barRef && barRef.isVolMuted) ? Theme.colError : fg
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: (barRef ? barRef.volStr : "0") + "%"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 13
                font.weight: Theme.defaultFontWeight
                color: Qt.rgba(fg.r, fg.g, fg.b, 0.7)
                width: vMouse.containsMouse ? implicitWidth : 0
                clip: true
                Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutSine } }
            }
        }
    }
}
