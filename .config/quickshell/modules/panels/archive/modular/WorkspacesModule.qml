// ==============================================================================
// ⚠️ STRICT DIRECTIVE / AGENT LOCK: THIS COMPONENT IS TOTALLY DISABLED
// THIS COMPONENT IS PRESERVED FOR ARCHIVAL PURPOSES ONLY. IT IS DECOUPLED FROM
// THE CUPCAKE RUNTIME. NO AGENT MAY TOUCH, REFACTOR, MODIFY, OR RE-ENABLE THIS
// FILE IN ANY WAY UNLESS THE USER EXPLICITLY INSTRUCTS YOU TO DO SO.
// ==============================================================================
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Widgets
import Quickshell
import Qt5Compat.GraphicalEffects
import Quickshell.Hyprland
import "../../../theme"

Row {
    id: workspacesRow
    spacing: 8
    
    // Accept theme colors from parent (or fallback)
    property color fg: Theme.colOnSurface
    
    Repeater {
        model: 5
        delegate: Item {
            width: isFocused ? 22 : 12
            height: 30
            property int wsId: index + 1
            property bool isFocused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
            property bool isOccupied: isFocused || Hyprland.workspaces.values.some(ws => ws.id === wsId)
            
            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutSine } }

            Rectangle {
                id: wsRect
                anchors.centerIn: parent
                width: parent.width
                height: isFocused ? 6 : (wsMouse.containsMouse ? 6 : 4)
                radius: height / 2
                color: isFocused ? Theme.colPrimary : (isOccupied ? Qt.rgba(fg.r, fg.g, fg.b, 0.5) : Qt.rgba(fg.r, fg.g, fg.b, 0.2))
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutSine } }
            }

            MouseArea { 
                id: wsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("hl.dsp.focus({workspace = " + wsId + "})")
            }
        }
    }
}
