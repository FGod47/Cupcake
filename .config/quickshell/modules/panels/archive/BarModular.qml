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
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import Quickshell.Hyprland

import "../../../theme"

Scope {
    property bool visible: true
    id: bar
    
    // Core Bar Properties
    property real barW: 1920 - 24
    property real barH: 42
    property real barX: 12
    property real barY: 8
    
    // Theme Colors
    property color bg: Qt.rgba(Theme.colSurface.r, Theme.colSurface.g, Theme.colSurface.b, 0.4)
    property color fg: Theme.colOnSurface
    property string fontName: "JetBrainsMono Nerd Font"
    
    // UI State
    property bool dropdownOpen: false // Hardware expanded
    property bool netDropdownOpen: false // Network expanded
    property string volStr: "50"
    property string brightStr: "50"
    property string netStr: "0 KB/s"
    property bool isWifi: true
    property bool isWired: false
    property bool isBluetooth: true
    property bool isBluetoothConnected: false
    property bool isHotspot: false
    property bool isVolMuted: false

    function getVolumeIcon(volVal, isMuted) {
        if (isMuted) return "";
        var v = parseFloat(volVal) || 0;
        if (v <= 0) return "";
        if (v < 50) return "";
        return "";
    }

    function getBrightnessIcon(brightVal) {
        var b = parseFloat(brightVal) || 0;
        if (b < 33) return "";
        if (b < 66) return "";
        return "";
    }
    
    PanelWindow {
        id: barWindow
        visible: bar.visible
        anchors { top: true; left: true; right: true }
        height: 60
        color: "transparent"
        margins { top: bar.barY; left: bar.barX; right: bar.barX }
        
        onWidthChanged: { bar.barW = width; }

        mask: Region {
            Region { item: leftBg }
            Region { item: centerBg }
            Region { item: rightBg }
            Region { item: netSplitPill }
            Region { item: volBrightSplitPill }
            Region { item: clockSplitPill }
            Region { item: powerSplitPill }
        }

        DropdownNetwork { id: netSplitPill }
        DropdownHardware { id: volBrightSplitPill }
        DropdownClock { id: clockSplitPill }
        DropdownPower { id: powerSplitPill }

        // --- THE LIQUID BACKGROUND MASKING SYSTEM ---
        
        // 1. Left Background (Always visible, shrinks when right pills pop out)
        Rectangle {
            id: leftBg
            x: 0
            y: 0
            height: bar.barH
            radius: 20
            color: Theme.colPrimary
            
            // The magic: width is dynamic based on what is expanded!
            width: {
                if (bar.netDropdownOpen) {
                    return leftGroup.width + 24; // Shrink to fit Workspaces + Title
                } else if (bar.dropdownOpen) {
                    return leftGroup.width + spacer.width + netGroup.width + 24; // Shrink to fit up to Network
                } else {
                    return parent.width; // Solid Mode: span entire screen
                }
            }
            Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        }

        // 2. Center Background (Only visible when Network expands)
        Rectangle {
            id: centerBg
            y: 0
            height: bar.barH
            radius: 20
            color: Theme.colPrimary
            
            // Follow the network group
            x: netGroup.x - 12
            width: netGroup.width + 24
            
            opacity: bar.netDropdownOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
            Behavior on x { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
            Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        }

        // 3. Right Background (Visible when Network or Hardware expands)
        Rectangle {
            id: rightBg
            y: 0
            height: bar.barH
            radius: 20
            color: Theme.colPrimary
            
            // Follow the hardware/clock groups
            x: rightGroup.x - 12
            width: rightGroup.width + 24
            
            opacity: (bar.netDropdownOpen || bar.dropdownOpen) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
            Behavior on x { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
            Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
        }

        // --- THE ACTUAL MODULES ---
        
        RowLayout {
            id: contentLayout
            anchors.fill: parent
            anchors.bottomMargin: parent.height - bar.barH
            spacing: 0
            
            // Group 1: Left Items
            Row {
                id: leftGroup
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 12
                spacing: 8
                
                WorkspacesModule { fg: bar.fg }
                TitleModule { fg: bar.fg }
            }
            
            Item { id: spacer; Layout.fillWidth: true } // Pushes right items to the right edge
            
            // Group 2: Center Items (Network)
            Row {
                id: netGroup
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: bar.netDropdownOpen ? 16 : 8 // Gap changes when expanded
                Behavior on Layout.rightMargin { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
                
                NetworkModule { fg: bar.fg; barRef: bar }
            }

            // Group 3: Right Items (Hardware, SysTray, Clock, Power)
            Row {
                id: rightGroup
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: 12
                spacing: 12
                
                HardwareModule { fg: bar.fg; barRef: bar }
                SysTrayModule { fg: bar.fg; barRef: bar }
                ClockModule { fg: bar.fg }
                PowerModule { fg: bar.fg }
            }
        }
    }
}
