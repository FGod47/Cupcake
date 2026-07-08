import QtQuick
import QtQuick.Effects
import Quickshell

Window {
    width: 200; height: 200; visible: true
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: 50
        visible: false
    }
    Image {
        id: img
        anchors.fill: parent
        source: "file://" + "/home/code/.config/cupcake/walls/21kz5g.png"
        visible: false
    }
    MultiEffect {
        source: img
        anchors.fill: img
        maskEnabled: true
        maskSource: mask
    }
}
