import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "theme"
import "modules/panels"
import "modules/settings"
import "modules/common"

PanelWindow {
    id: settingsWindow
    anchors { left: true; top: true; bottom: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "cupcake-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"

    mask: Region {
        item: bgRect
    }
    
    // ── Click outside to close ──────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: settingsWindow.dismiss()
    }

    readonly property int fullWidth: 900
    readonly property int fullHeight: 800


    property bool isOpen: false
    property bool userDismissed: false
    
    Component.onCompleted: {
        Qt.callLater(() => {
            settingsWindow.isOpen = true;
        });
    }
    
    function dismiss() {
        if (userDismissed) return;
        userDismissed = true;
        settingsWindow.isOpen = false;
        closeTimer.start();
    }
    
    Timer {
        id: closeTimer
        interval: 550
        onTriggered: Qt.quit()
    }

    property real bgOpacity: 0.75
    Process {
        id: initSettingsOpacity
        command: ["cat", Quickshell.env("HOME") + "/.config/cupcake/.settings_opacity"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { let v = parseFloat(text.trim()); if (!isNaN(v)) settingsWindow.bgOpacity = v; }
            }
        }
    }
    Timer { interval: 500; running: true; repeat: true; onTriggered: initSettingsOpacity.running = true }

    // Dynamically read Hyprland's rounding value so window corners always match
    property int hyprRounding: 10
    Process {
        id: initRounding
        command: ["bash", "-c", "hyprctl getoption decoration:rounding -j | grep -o '\"int\": [0-9]*' | grep -o '[0-9]*'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let v = parseInt(text.trim());
                if (!isNaN(v) && v >= 0) settingsWindow.hyprRounding = v;
            }
        }
    }

    Rectangle {
        id: bgRect
        anchors.centerIn: parent
        width: settingsWindow.isOpen ? settingsWindow.fullWidth : 0
        height: settingsWindow.isOpen ? settingsWindow.fullHeight : 160
        
        Behavior on width { NumberAnimation { duration: 550; easing.type: Easing.InOutExpo } }
        Behavior on height { NumberAnimation { duration: 550; easing.type: Easing.InOutExpo } }

        radius: settingsWindow.hyprRounding
        border.width: 1
        border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.3)
        clip: true
        
        // Solid glassy background to prevent color banding (line blocks)
        color: Qt.rgba(Theme.colSurfaceContainer.r, Theme.colSurfaceContainer.g, Theme.colSurfaceContainer.b, settingsWindow.bgOpacity)
        
        Item {
            id: contentWrapper
            anchors.fill: parent
            clip: true
            
            Item {
                id: innerContent
                width: settingsWindow.fullWidth
                height: settingsWindow.fullHeight
                anchors.centerIn: parent
                opacity: settingsWindow.isOpen ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }

                SettingsUI {
                    id: settingsUI
                    anchors.fill: parent
                    windowRadius: settingsWindow.hyprRounding
                    
                    Connections {
                        target: settingsUI
                        function onRequestClose() {
                            settingsWindow.dismiss();
                        }
                    }
                }
            }
        }
    }
}
