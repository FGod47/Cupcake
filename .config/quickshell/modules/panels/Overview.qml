
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import "../../theme"

PanelWindow {
    id: overviewWin

    visible: true

    Region { id: emptyMask }
    mask: globalState.overviewOpen ? null : emptyMask

    WlrLayershell.namespace: "quickshell:overview"
    WlrLayershell.layer:     WlrLayer.Top
    WlrLayershell.keyboardFocus: globalState.overviewOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore


    anchors { top: true; bottom: true; left: true; right: true }

    // -------------------------------------------------------
    // Layout constants
    // -------------------------------------------------------
    readonly property int  wsColumns: Math.min(root.overviewTabs, 6)
    readonly property int  wsRows:    Math.ceil(root.overviewTabs / 6)
    readonly property int  wsTotal:   root.overviewTabs
    readonly property real wsScale:   0.14
    readonly property real wsSpacing: 6
    readonly property real wsPadding: 12
    readonly property real cellW:     screen.width  * wsScale
    readonly property real cellH:     screen.height * wsScale

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property int activeWsId: Math.max(1, Math.min(100, Hyprland.focusedWorkspace?.id ?? monitor?.activeWorkspace?.id ?? 1))
    readonly property int wsGroup:    Math.floor((activeWsId - 1) / wsTotal)

    readonly property real cardW: wsColumns * cellW + (wsColumns - 1) * wsSpacing + wsPadding * 2
    readonly property real cardH: wsRows    * cellH + (wsRows    - 1) * wsSpacing + wsPadding * 2
    readonly property real cardX: (width  - cardW) / 2
    readonly property real cardY: (height - cardH) / 2

    // -------------------------------------------------------
    // Drag state
    // -------------------------------------------------------
    property bool   isDragging:     false
    property string draggingAddr:   ""
    property int    draggingFromWs: -1
    property int    draggingToWs:   -1
    property real   dragX:          0
    property real   dragY:          0
    property real   dragW:          0
    property real   dragH:          0
    property real   dragOffX:       0
    property real   dragOffY:       0

    // -------------------------------------------------------
    // Hit-test helpers
    // -------------------------------------------------------
    function wsAtPoint(px, py) {
        var innerX = px - gridContent.x - overviewWin.wsPadding
        var innerY = py - gridContent.y - overviewWin.wsPadding
        var col = Math.floor(innerX / (cellW + wsSpacing))
        var row = Math.floor(innerY / (cellH + wsSpacing))
        if (col < 0 || col >= wsColumns || row < 0 || row >= wsRows) return -1
        var localX = innerX - col * (cellW + wsSpacing)
        var localY = innerY - row * (cellH + wsSpacing)
        if (localX > cellW || localY > cellH) return -1
        return wsGroup * wsTotal + row * wsColumns + col + 1
    }

    function windowAtPoint(px, py) {
        var localX = px - gridContent.x - overviewWin.wsPadding
        var localY = py - gridContent.y - overviewWin.wsPadding
        
        for (var i = windowList.length - 1; i >= 0; i--) {
            var win = windowList[i]
            if (!win || !win.workspace) continue
            var local = win.workspace.id - wsGroup * wsTotal - 1
            if (local < 0 || local >= wsTotal) continue
            var wCol = local % wsColumns
            var wRow = Math.floor(local / wsColumns)
            
            var bounds = overviewWin.wsBounds[win.workspace.id] || {xOff: 0, yOff: 0}
            var wx = wCol * (cellW + wsSpacing) + ((win.at[0] ?? 0) + bounds.xOff) * wsScale
            var wy = wRow * (cellH + wsSpacing) + ((win.at[1] ?? 0) + bounds.yOff) * wsScale
            var ww = (win.size[0] ?? 100) * wsScale
            var wh = (win.size[1] ?? 60)  * wsScale
            
            if (localX >= wx && localX <= wx + ww && localY >= wy && localY <= wy + wh) {
                return { addr: win.address, x: gridContent.x + overviewWin.wsPadding + wx, y: gridContent.y + overviewWin.wsPadding + wy, w: ww, h: wh, wsId: win.workspace.id }
            }
        }
        return null
    }

    // -------------------------------------------------------
    // Window data
    // -------------------------------------------------------
    property var windowList:   []
    property var windowByAddr: ({})
    property var wsBounds:     ({})

    Component.onCompleted: fetchClients.running = true

    Process {
        id: fetchClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var arr = JSON.parse(text)
                    overviewWin.windowList = arr
                    var map = {}
                    var bb = {}
                    arr.forEach(function(w) { 
                        map[w.address] = w 
                        if (w.workspace && w.workspace.id) {
                            var wid = w.workspace.id
                            if (!bb[wid]) bb[wid] = { minX: 99999, maxX: 0, minY: 99999, maxY: 0, count: 0 }
                            if (w.at) {
                                bb[wid].minX = Math.min(bb[wid].minX, w.at[0])
                                bb[wid].minY = Math.min(bb[wid].minY, w.at[1])
                            }
                            if (w.at && w.size) {
                                bb[wid].maxX = Math.max(bb[wid].maxX, w.at[0] + w.size[0])
                                bb[wid].maxY = Math.max(bb[wid].maxY, w.at[1] + w.size[1])
                            }
                            bb[wid].count++
                        }
                    })
                    
                    var offsets = {}
                    for (var wid in bb) {
                        var b = bb[wid]
                        if (b.count > 0) {
                            offsets[wid] = {
                                xOff: (((screen.width) - (b.maxX - b.minX)) / 2) - b.minX,
                                yOff: (((screen.height) - (b.maxY - b.minY)) / 2) - b.minY
                            }
                        }
                    }
                    overviewWin.wsBounds = offsets
                    overviewWin.windowByAddr = map
                } catch(e) {}
            }
        }
    }
    Timer {
        id: bgFetchTimer
        interval: 500
        repeat: false
    }

    Connections {
        target: Hyprland
        function onRawEvent() { 
            if (globalState.overviewOpen) {
                fetchClients.running = true 
            } else if (!bgFetchTimer.running) {
                fetchClients.running = true
                bgFetchTimer.start()
            }
        }
    }

    // -------------------------------------------------------
    // Single global MouseArea — owns all input
    // -------------------------------------------------------
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        z: 100

        onPressed: function(mouse) {
            overviewWin.isPressing = true
            overviewWin.pressX = mouse.x
            overviewWin.pressY = mouse.y
            overviewWin.isDragging = false
            overviewWin.draggingAddr = ""

            var win = overviewWin.windowAtPoint(mouse.x, mouse.y)
            if (win) {
                if (mouse.button === Qt.MiddleButton) {
                    Hyprland.dispatch("hl.dsp.window.close({window = \"address:" + win.addr + "\"})")
                    mouse.accepted = true
                    overviewWin.isPressing = false
                    return
                }
                overviewWin.draggingAddr   = win.addr
                overviewWin.draggingFromWs = win.wsId
                overviewWin.draggingToWs   = win.wsId
                overviewWin.dragX          = win.x
                overviewWin.dragY          = win.y
                overviewWin.dragW          = win.w
                overviewWin.dragH          = win.h
                overviewWin.dragOffX       = mouse.x - win.x
                overviewWin.dragOffY       = mouse.y - win.y
            }
            mouse.accepted = true
        }

        onPositionChanged: function(mouse) {
            if (!overviewWin.isPressing) return
            var dx = mouse.x - overviewWin.pressX
            var dy = mouse.y - overviewWin.pressY
            if (!overviewWin.isDragging && (dx * dx + dy * dy > 64) && overviewWin.draggingAddr !== "") {
                overviewWin.isDragging = true
            }
            if (overviewWin.isDragging) {
                overviewWin.dragX = mouse.x - overviewWin.dragOffX
                overviewWin.dragY = mouse.y - overviewWin.dragOffY
                overviewWin.draggingToWs = overviewWin.wsAtPoint(
                    overviewWin.dragX + overviewWin.dragW / 2,
                    overviewWin.dragY + overviewWin.dragH / 2
                )
            }
        }

        onReleased: function(mouse) {
            var wasDragging = overviewWin.isDragging
            var addr = overviewWin.draggingAddr
            var targetWs = overviewWin.draggingToWs
            var fromWs = overviewWin.draggingFromWs

            overviewWin.isPressing = false
            overviewWin.isDragging = false
            overviewWin.draggingAddr = ""
            overviewWin.draggingFromWs = -1
            overviewWin.draggingToWs = -1

            if (wasDragging) {
                if (targetWs !== -1 && targetWs !== fromWs && addr !== "") {
                    Hyprland.dispatch(
                        "hl.dsp.window.move({ workspace = " + targetWs +
                        ", follow = false, window = \"address:" + addr + "\" })"
                    )
                    fetchClients.running = true
                }
            } else {
                // It was a click, not a drag!
                var win = overviewWin.windowAtPoint(mouse.x, mouse.y)
                if (win) {
                    globalState.overviewOpen = false
                    Hyprland.dispatch("hl.dsp.focus({window = \"address:" + win.addr + "\"})")
                    return
                }
                var ws = overviewWin.wsAtPoint(mouse.x, mouse.y)
                if (ws !== -1) {
                    globalState.overviewOpen = false
                    Hyprland.dispatch("hl.dsp.focus({workspace = " + ws + "})")
                    return
                }
                // Clicked outside grid — close overview
                globalState.overviewOpen = false
            }
        }
    }

    // -------------------------------------------------------
    // Drag vs Click state
    // -------------------------------------------------------
    property real pressX: 0
    property real pressY: 0
    property bool isPressing: false

    // -------------------------------------------------------
    // Grid Content — explicit open/close animations, NO Behaviors
    // This guarantees everything fades as one unit with no ghost leftovers
    // -------------------------------------------------------
    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: gridContent; property: "opacity"; from: 0.0; to: 1.0; duration: 250; easing.type: Easing.OutExpo }
        NumberAnimation { target: gridContent; property: "scale";   from: 0.0; to: 1.0; duration: Theme.liquidify ? 650 : 350; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutExpo; easing.amplitude: 0.9; easing.period: 0.8 }
    }

    SequentialAnimation {
        id: closeAnim
        ParallelAnimation {
            NumberAnimation { target: gridContent; property: "opacity"; to: 0.0;  duration: 180; easing.type: Easing.InExpo }
            NumberAnimation { target: gridContent; property: "scale";   to: 0.0; duration: 250; easing.type: Easing.InBack }
        }
        ScriptAction { script: { gridContent.visible = false } }
    }

    Connections {
        target: globalState
        function onOverviewOpenChanged() {
            if (globalState.overviewOpen) {
                closeAnim.stop()
                gridContent.opacity = 0.0
                gridContent.scale   = 0.0
                gridContent.visible = true
                openAnim.restart()
            } else {
                openAnim.stop()
                closeAnim.restart()
            }
        }
    }

    Item {
        id: gridContent
        anchors.centerIn: parent
        width: overviewWin.cardW
        height: overviewWin.cardH
        z: 1
        visible: false
        opacity: 0.0
        scale: 0.0
        layer.enabled: true

        focus: globalState.overviewOpen
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                overviewWin.isDragging = false
                globalState.overviewOpen = false
                event.accepted = true
            }
        }

        // Background — ccOpacity baked into color alpha so opacity is never split
        Rectangle {
            anchors.fill: parent
            radius: 18
            color: Qt.rgba(
                Theme.colSurface.r,
                Theme.colSurface.g,
                Theme.colSurface.b,
                root.barTransparency ? root.overviewOpacity : 1.0
            )
        }

        
        Column {
            anchors.centerIn: parent
            width: overviewWin.cardW - overviewWin.wsPadding * 2
            height: overviewWin.cardH - overviewWin.wsPadding * 2
            spacing: overviewWin.wsSpacing

            Repeater {
                model: wsRows
                delegate: Row {
                    id: wsRow
                    required property int index
                    spacing: wsSpacing

                    Repeater {
                        model: wsColumns
                        delegate: Item {
                            id: wsCell
                            required property int index
                            property int wsId: overviewWin.wsGroup * overviewWin.wsTotal
                                              + wsRow.index * overviewWin.wsColumns
                                              + wsCell.index + 1
                            property bool isActive:   wsId === overviewWin.activeWsId
                            property bool isDragOver: overviewWin.draggingToWs === wsId && overviewWin.isDragging

                            width:  cellW
                            height: cellH
                            visible: (wsRow.index * overviewWin.wsColumns + wsCell.index) < overviewWin.wsTotal

                            // Cell background — elegant indented tray with theme tint
                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                color: wsCell.isDragOver ? Theme.colPrimary : Theme.colSurfaceContainerHigh
                                opacity: wsCell.isDragOver ? 0.35 : (wsCell.isActive ? 0.25 : 0.15)
                            }
                            
                            // Cell border — thicker and deeper
                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                color: "transparent"
                                border.color: wsCell.isActive ? Theme.colPrimary : (wsCell.isDragOver ? Theme.colPrimary : Theme.colOutline)
                                border.width: wsCell.isActive ? 5 : 3
                                opacity: wsCell.isActive ? 1.0 : 0.9
                            }

                            // Workspace number — matches CC's muted text style
                            Text {
                                anchors.centerIn: parent
                                text: wsCell.wsId
                                font.pixelSize: cellH * 0.28
                                font.weight: Font.DemiBold
                                font.family: Theme.defaultFontFamily
                                color: Qt.rgba(Theme.colOnSurfaceVariant.r, Theme.colOnSurfaceVariant.g, Theme.colOnSurfaceVariant.b, 0.25)
                            }

                            // Window thumbnails — visual only, no mouse areas
                            Repeater {
                                model: ToplevelManager.toplevels
                                delegate: Item {
                                    id: winTile
                                    required property var modelData
                                    property var    wData: overviewWin.windowByAddr["0x" + modelData.HyprlandToplevel?.address]
                                    property string wAddr: wData?.address ?? ""
                                    
                                    visible: !!(wData && wData.workspace && wData.workspace.id === wsCell.wsId)
                                    property bool   isBeingDragged: overviewWin.isDragging && overviewWin.draggingAddr === wAddr
                                    property var    bounds: overviewWin.wsBounds[wsCell.wsId] || {xOff: 0, yOff: 0}

                                    x:       Math.max(((wData?.at[0] ?? 0) + bounds.xOff) * overviewWin.wsScale, 0)
                                    y:       Math.max(((wData?.at[1] ?? 0) + bounds.yOff) * overviewWin.wsScale, 0)
                                    width:   (wData?.size[0] ?? 100) * overviewWin.wsScale
                                    height:  (wData?.size[1] ?? 60)  * overviewWin.wsScale
                                    opacity: isBeingDragged ? 0.20 : 1.0

                                    Rectangle {
                                        id: scContainer
                                        anchors.fill: parent
                                        radius: 10
                                        color: (winTile.modelData && winTile.modelData.title === "Cupcake Settings") ? (Theme.isDark ? Theme.colSurfaceContainer : Theme.colBackground) : "transparent"
                                        clip: true

                                        ScreencopyView {
                                            id: scView
                                            anchors.fill: parent
                                            captureSource: winTile.modelData
                                            live: true
                                            
                                            layer.enabled: true
                                            layer.effect: OpacityMask {
                                                maskSource: Rectangle {
                                                    width: scView.width
                                                    height: scView.height
                                                    radius: 10
                                                }
                                            }
                                        }
                                    }

                                    // App Icon Overlay
                                    Image {
                                        anchors.centerIn: parent
                                        width: Math.min(parent.width * 0.3, parent.height * 0.3, 40)
                                        height: width
                                        source: wData ? "image://icon/" + (wData.initialClass || wData.class || "") : ""
                                        fillMode: Image.PreserveAspectFit
                                        visible: status === Image.Ready
                                    }

                                    // Subtle border matching Theme.colOutline
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 10
                                        color: "transparent"
                                        border.color: Theme.colOutline
                                        border.width: 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // -------------------------------------------------------
    // Drag ghost — live screencopy with primary accent border
    // -------------------------------------------------------
    Item {
        id: dragGhost
        visible: overviewWin.isDragging
        x: overviewWin.dragX
        y: overviewWin.dragY
        width:  overviewWin.dragW
        height: overviewWin.dragH
        z: 200

        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0; verticalOffset: 4; radius: 14; samples: 17
            color: Qt.rgba(0, 0, 0, 0.35)
        }

        ScreencopyView {
            id: dragScView
            anchors.fill: parent
            captureSource: {
                if (!overviewWin.isDragging || overviewWin.draggingAddr === "") return null
                return ToplevelManager.toplevels.values.find(function(tl) {
                    return "0x" + tl.HyprlandToplevel?.address === overviewWin.draggingAddr
                }) ?? null
            }
            live: true
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle { width: dragScView.width; height: dragScView.height; radius: 10 }
            }
        }
        
        Image {
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.3, parent.height * 0.3, 40)
            height: width
            source: overviewWin.isDragging && overviewWin.draggingAddr !== "" && overviewWin.windowByAddr[overviewWin.draggingAddr] ? "image://icon/" + (overviewWin.windowByAddr[overviewWin.draggingAddr].initialClass || overviewWin.windowByAddr[overviewWin.draggingAddr].class || "") : ""
            fillMode: Image.PreserveAspectFit
            visible: status === Image.Ready
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 2
                radius: 8
                samples: 17
                color: Qt.rgba(0,0,0,0.7)
            }
        }

        // Primary color border — same as active workspace border
        Rectangle {
            anchors.fill: parent
            radius: 10
            color: "transparent"
            border.color: Theme.colPrimary
            border.width: 2
        }
    }
}
