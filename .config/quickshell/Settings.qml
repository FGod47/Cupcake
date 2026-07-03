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
    
    Rectangle {
        anchors.fill: parent
        
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
