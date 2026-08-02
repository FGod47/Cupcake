import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Widgets
import Quickshell
import "../../../theme"

Row {
    id: networkRowContent
    height: 20
    spacing: 8
    anchors.verticalCenter: parent.verticalCenter
    
    property color fg: Theme.colOnSurface
    property string fontName: "JetBrainsMono Nerd Font"
    
    // Accept bar object for state properties
    property var barRef: null

    Text {
        visible: barRef ? barRef.isHotspot : false
        text: "\ued1b"
        font.family: fontName
        font.pixelSize: 15
        color: fg
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        visible: barRef ? barRef.isBluetooth : false
        text: (barRef && barRef.isBluetoothConnected) ? "\uecea" : "\uea37"
        font.family: fontName
        font.pixelSize: 15
        color: fg
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        visible: barRef ? barRef.isWired : false
        text: "\uebd9"
        font.family: fontName
        font.pixelSize: 15
        color: fg
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        visible: barRef ? barRef.isWifi : false
        text: "\uefcc"
        font.family: fontName
        font.pixelSize: 15
        color: fg
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        visible: barRef ? (barRef.isWifi || barRef.isWired || barRef.isBluetooth || barRef.isHotspot) : false
        text: "•"
        font.family: Theme.defaultFontFamily
        font.pixelSize: 15
        font.weight: Theme.defaultFontWeight
        color: Qt.rgba(fg.r, fg.g, fg.b, 0.4)
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        text: barRef ? barRef.netStr : "0 KB/s"
        font.family: Theme.defaultFontFamily
        font.pixelSize: 13
        font.weight: Theme.defaultFontWeight
        color: Qt.rgba(fg.r, fg.g, fg.b, 0.7)
        anchors.verticalCenter: parent.verticalCenter
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (barRef) {
                if (globalState.solidBoardOpen) globalState.solidBoardOpen = false;
                if (globalState.powerDropdownOpen) globalState.powerDropdownOpen = false;
                if (barRef.dropdownOpen) barRef.dropdownOpen = false;
                barRef.netDropdownOpen = !barRef.netDropdownOpen;
            }
        }
    }
}
