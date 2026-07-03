//@ pragma UseQApplication
import QtQuick
import Quickshell
import "theme"

Window {
    id: settingsWindow
    visible: true
    width: 900
    height: 800
    title: "Cupcake Settings"
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint
    
    Rectangle {
        anchors.fill: parent
        radius: 16
        border.width: 1
        border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.3)
        clip: true
        
        // Glassy semi-transparent gradient
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(Theme.colBackground.r, Theme.colBackground.g, Theme.colBackground.b, 0.7) }
            GradientStop { position: 1.0; color: Qt.rgba(Theme.colSurfaceContainerHigh.r, Theme.colSurfaceContainerHigh.g, Theme.colSurfaceContainerHigh.b, 0.8) }
        }
        
        SettingsUI {
            id: settingsUI
            anchors.fill: parent
            
            Connections {
                target: settingsUI
                function onRequestClose() {
                    settingsWindow.close();
                }
            }
        }
    }
}
