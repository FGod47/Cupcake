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
    color: Theme.colBackground
    
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
