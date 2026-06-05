import Quickshell
import QtQuick

ShellRoot {
    id: root

    // Top Bar Components for all screens
    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    // Popups
    

}
