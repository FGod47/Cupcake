import QtQuick
import Quickshell
import "theme"

Window {
    width: 400
    height: 400
    color: Theme.colSurfaceContainer

    Component.onCompleted: {
        console.log("INITIAL: Theme.isDark=", Theme.isDark, "colOnSurface=", Theme.colOnSurface);
    }
    
    Connections {
        target: Theme
        function onIsDarkChanged() {
            console.log("CHANGED: Theme.isDark=", Theme.isDark, "colOnSurface=", Theme.colOnSurface);
            Qt.callLater(function() { Qt.quit() });
        }
    }
}
