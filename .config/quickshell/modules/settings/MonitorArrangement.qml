import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import Quickshell

Item {
    id: root
    property var monitorsData: []
    implicitHeight: 280
    
    // Virtual workspace size calculation
    property real maxW: 1
    property real maxH: 1
    property real minX: 0
    property real minY: 0
    
    // Visual scaling
    property real scaleFactor: Math.min(width / (maxW || 1), height / (maxH || 1)) * 0.8
    property real offsetX: (width - (maxW * scaleFactor)) / 2 - (minX * scaleFactor)
    property real offsetY: (height - (maxH * scaleFactor)) / 2 - (minY * scaleFactor)

    onMonitorsDataChanged: {
        if (!monitorsData || monitorsData.length === 0) return;
        
        let mnX = 999999, mnY = 999999;
        let mxW = 0, mxH = 0;
        
        for (let i = 0; i < monitorsData.length; i++) {
            let m = monitorsData[i];
            let mw = (m.transform % 2 !== 0) ? m.height : m.width;
            let mh = (m.transform % 2 !== 0) ? m.width : m.height;
            mw = mw / m.scale;
            mh = mh / m.scale;
            
            if (m.x < mnX) mnX = m.x;
            if (m.y < mnY) mnY = m.y;
            if (m.x + mw > mxW) mxW = m.x + mw;
            if (m.y + mh > mxH) mxH = m.y + mh;
        }
        
        minX = mnX;
        minY = mnY;
        maxW = mxW - mnX;
        maxH = mxH - mnY;
    }
    
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.2)
        radius: 12
        border.color: Qt.rgba(255,255,255, 0.1)
        border.width: 1
        clip: true
        
        Text {
            anchors.centerIn: parent
            text: "Drag and drop to arrange monitors"
            color: Qt.rgba(255,255,255, 0.4)
            font.pixelSize: 14
            visible: root.monitorsData.length > 0
            z: 0
        }
        
        Repeater {
            model: root.monitorsData
            delegate: Rectangle {
                id: monRect
                property var mon: modelData
                property real logicalWidth: (mon.transform % 2 !== 0 ? mon.height : mon.width) / mon.scale
                property real logicalHeight: (mon.transform % 2 !== 0 ? mon.width : mon.height) / mon.scale
                
                x: root.offsetX + (mon.x * root.scaleFactor)
                y: root.offsetY + (mon.y * root.scaleFactor)
                width: logicalWidth * root.scaleFactor
                height: logicalHeight * root.scaleFactor
                
                color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, dragArea.drag.active ? 0.9 : 0.6)
                radius: 6
                border.color: Theme.colPrimary
                border.width: 2
                
                Text {
                    anchors.centerIn: parent
                    text: mon.id !== undefined ? (mon.id + 1).toString() : "1"
                    font.pixelSize: 24
                    font.weight: Font.Bold
                    color: Theme.colOnPrimary
                }
                
                Text {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 8
                    text: mon.name
                    font.pixelSize: 11
                    color: Theme.colOnPrimary
                }
                
                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    cursorShape: Qt.OpenHandCursor
                    drag.target: monRect
                    
                    onPressed: {
                        cursorShape = Qt.ClosedHandCursor;
                        monRect.z = 100; // bring to front while dragging
                    }
                    onReleased: {
                        cursorShape = Qt.OpenHandCursor;
                        monRect.z = 1;
                        
                        // Snap to nearest grid or edges
                        let newX = (monRect.x - root.offsetX) / root.scaleFactor;
                        let newY = (monRect.y - root.offsetY) / root.scaleFactor;
                        
                        // Snap to 0 if close
                        if (Math.abs(newX) < 100) newX = 0;
                        if (Math.abs(newY) < 100) newY = 0;
                        
                        // For a full implementation, you'd calculate bounding boxes of other monitors and snap here
                        newX = Math.round(newX);
                        newY = Math.round(newY);
                        
                        // Apply hyprctl command immediately
                        let modeStr = mon.width + "x" + mon.height + "@" + mon.refreshRate;
                        Quickshell.execDetached(["hyprctl", "keyword", "monitor", 
                            mon.name + "," + modeStr + "," + newX + "x" + newY + "," + mon.scale]);
                            
                        // Also update the UI manually or let the Timer fetch new data
                        // For now we just let the 5-sec Timer refresh it, but let's trigger a refresh immediately
                        Quickshell.execDetached(["python3", Theme.homeDir + "/Cupcake/.local/bin/generate_monitor_lua.py"]);
                    }
                }
            }
        }
    }
}
