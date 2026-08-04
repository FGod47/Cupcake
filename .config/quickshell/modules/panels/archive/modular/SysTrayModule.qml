// ==============================================================================
// ⚠️ STRICT DIRECTIVE / AGENT LOCK: THIS COMPONENT IS TOTALLY DISABLED
// THIS COMPONENT IS PRESERVED FOR ARCHIVAL PURPOSES ONLY. IT IS DECOUPLED FROM
// THE CUPCAKE RUNTIME. NO AGENT MAY TOUCH, REFACTOR, MODIFY, OR RE-ENABLE THIS
// FILE IN ANY WAY UNLESS THE USER EXPLICITLY INSTRUCTS YOU TO DO SO.
// ==============================================================================
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell.Widgets
import Quickshell
import Qt5Compat.GraphicalEffects
import "../../../theme"

Row {
    id: sysTrayRow
    spacing: 8
    height: 20
    
    property color fg: Theme.colOnSurface
    property var barRef: null

    Repeater {
        id: sysTrayRepeater
        model: SystemTray.items
        delegate: Item {
            width: 13
            height: 20
            anchors.verticalCenter: parent.verticalCenter

            IconImage {
                anchors.centerIn: parent
                source: modelData.icon || ""
                width: 13
                height: 13
                layer.enabled: true
                layer.effect: ColorOverlay {
                    color: fg
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        modelData.activate();
                    } else if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                        if (barRef && barRef.contentItem) {
                            var pos = mapToItem(barRef.contentItem, mouse.x, mouse.y);
                            modelData.display(barRef, pos.x, pos.y);
                        } else {
                            modelData.display(null, mouse.x, mouse.y);
                        }
                    }
                }
            }
        }
    }
}
