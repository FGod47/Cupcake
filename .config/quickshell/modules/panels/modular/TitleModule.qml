import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Widgets
import Quickshell
import Qt5Compat.GraphicalEffects
import Quickshell.Hyprland
import "../../../theme"

Row {
    id: titleRow
    spacing: 12
    
    // Accept theme colors from parent (or fallback)
    property color fg: Theme.colOnSurface
    property string fontName: "JetBrainsMono Nerd Font"

    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: Hyprland.activeToplevel && Hyprland.activeToplevel.title !== ""
        text: "•"
        font.family: Theme.defaultFontFamily
        font.pixelSize: 15
        font.weight: Theme.defaultFontWeight
        color: Qt.rgba(fg.r, fg.g, fg.b, 0.4)
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, 300) // Replaces Layout.maximumWidth
        elide: Text.ElideRight
        visible: Hyprland.activeToplevel && Hyprland.activeToplevel.title !== ""
        text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
        font.family: Theme.defaultFontFamily
        font.pixelSize: 13
        font.weight: Theme.defaultFontWeight
        color: Qt.rgba(fg.r, fg.g, fg.b, 0.6)
    }
}
