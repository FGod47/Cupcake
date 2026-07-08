import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Widgets
import Qt.labs.folderlistmodel
import "theme"
import "modules/common"
import "modules/settings"

PanelWindow {
    id: root

    readonly property string homeDir: Quickshell.env("HOME")

    anchors { left: true; top: true; bottom: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "cupcake-wallpaper"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"
    
    mask: Region {
        item: pill
    }

    // ── Caelestia exact token values ─────────────────────────────────────
    readonly property int    wallW:       280          // wallpaperWidth
    readonly property int    wallH:       Math.round(wallW / 16 * 9)  // 157
    readonly property int    itemW:       180          // Spacing distance for stacking effect
    readonly property int    itemH:       170          // Vertical spacing distance
    readonly property int    cornerR:     17           // rounding.normal
    readonly property int    padH:        20           // padding
    readonly property int    padV:        15
    readonly property int    labelGap:    7            // spacing.small
    readonly property int    maxVisible:  Math.min(5, wallModel.count)
    readonly property int    numVisible:  maxVisible > 1 && maxVisible % 2 === 0 ? maxVisible - 1 : (maxVisible || 1)

    // ── Palette ──────────────────────────────────────────────────────────
    readonly property color colBg:      Theme.colSurfaceContainerHigh
    readonly property color colSub:     Theme.colSurface
    readonly property color colFgDim:   Theme.colOnSurfaceVariant
    readonly property color colPrimary: Theme.colPrimary

    property real bgOpacity: 0.80

    Process {
        id: initWallpaperOpacity
        command: ["cat", root.homeDir + "/.config/cupcake/.wallpaper_opacity"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { let v = parseFloat(text.trim()); if (!isNaN(v)) root.bgOpacity = v; }
            }
        }
    }
    Timer { interval: 500; running: true; repeat: true; onTriggered: initWallpaperOpacity.running = true }

    readonly property string wallDir: root.homeDir + "/.config/cupcake/walls"

    // ── Current wallpaper ────────────────────────────────────────────────
    property string currentWall: ""
    property bool   isInitialized: false
    property int    moveDuration: 0

    Process {
        command: ["cat", root.homeDir + "/.cache/current_wallpaper"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() !== "") root.currentWall = data.trim()
            }
        }
    }

    // ── Slide-up animation ────────────────────────────────────────────────
    property bool isOpen: false



    function dismiss() {
        isOpen = false
        killTimer.restart()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: console.log("Debug info:", root.width, root.isOpen, pill.width, pill.height, root.isInitialized, innerContent.opacity)
    }

    Timer {
        id: killTimer
        interval: 520
        onTriggered: root.visible = false
    }

    IpcHandler {
        target: "wallpaperswitcher"
        property real lastToggleTime: 0
        function toggle(): void {
            if (Date.now() - lastToggleTime < 300) return;
            lastToggleTime = Date.now();
            
            if (root.visible && root.isOpen) {
                root.dismiss()
            } else {
                root.moveDuration = 0
                root.isOpen = false
                root.visible = true
                
                Qt.callLater(() => {
                    root.isOpen = true
                    root.requestActivate()
                    pv.forceActiveFocus()
                    // Fetch latest desktop wallpaper on reappear
                    queryProc.running = true
                })
            }
        }
    }

    GlobalShortcut {
        name: "wallpaperswitcher_toggle"
        property real lastToggleTime: 0
        onPressed: {
            if (Date.now() - lastToggleTime < 300) return;
            lastToggleTime = Date.now();
            
            if (root.visible && root.isOpen) {
                root.dismiss()
            } else {
                root.moveDuration = 0
                root.isOpen = false
                root.visible = true
                
                Qt.callLater(() => {
                    root.isOpen = true
                    root.requestActivate()
                    pv.forceActiveFocus()
                    // Fetch latest desktop wallpaper on reappear
                    queryProc.running = true
                })
            }
        }
    }

    // ── Find Current Wallpaper ───────────────────────────────────────────
    Process {
        id: queryProc
        command: ["cat", root.homeDir + "/.cache/current_wallpaper"]
        running: true
        stdout: StdioCollector {
            id: queryStdout
        }
        onExited: {
            const out = queryStdout.text
            if (out.trim() !== "") {
                root.currentWall = out.trim()
                const fileName = root.currentWall.split('/').pop()
                console.log("queryProc found current wallpaper:", fileName)
                
                // If model is already ready, find index
                if (wallModel.status === FolderListModel.Ready) {
                    for (let i = 0; i < wallModel.count; i++) {
                        if (wallModel.get(i, "fileName") === fileName) {
                            pv.currentIndex = i
                            break
                        }
                    }
                    initTimer.start()
                }
            }
        }
    }

    // ── Wallpaper model ───────────────────────────────────────────────────
    FolderListModel {
        id:           wallModel
        folder:       "file://" + root.wallDir
        nameFilters:  ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        showDirs:     false
        sortField:    FolderListModel.Name

        onStatusChanged: {
            if (status === FolderListModel.Ready) {
                if (root.currentWall !== "") {
                    const fileName = root.currentWall.split('/').pop()
                    for (let i = 0; i < count; i++) {
                        if (get(i, "fileName") === fileName) {
                            pv.currentIndex = i
                            break
                        }
                    }
                }
                initTimer.start()
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: console.log("Debug info:", root.width, root.isOpen, pill.width, pill.height, root.isInitialized, innerContent.opacity)
    }

    Timer {
        id: initTimer
        interval: 50
        onTriggered: {
            root.isInitialized = true
            root.moveDuration = 300
        }
    }

    // ── Master Vertical Clipping Wrapper ──────────────────────────
    Item {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: pill.width + 1
        height: root.height
        clip: true

    // ── Pill ─────────────────────────────────────────────────────────────
    Rectangle {
        id: pill

        anchors.left:             parent.left
        anchors.verticalCenter:   parent.verticalCenter
        anchors.leftMargin:       0

        readonly property int fullWidth: root.wallW + root.padH * 2
        readonly property int fullHeight: pv.height + root.padV * 2 // approximation for label metrics height

        width: root.isOpen ? fullWidth : 0
        height: root.isOpen ? fullHeight : 160

        Behavior on width { NumberAnimation { duration: 550; easing.type: Easing.InOutExpo } }
        Behavior on height { NumberAnimation { duration: 550; easing.type: Easing.InOutExpo } }

        color: Qt.rgba(root.colBg.r, root.colBg.g, root.colBg.b, root.bgOpacity)
        topRightRadius: 36
        bottomRightRadius: 36
        topLeftRadius: 0
        bottomLeftRadius: 0

        Item {
            id: contentWrapper
            width: pill.width
            height: pill.height
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            
            Item {
                id: innerContent
                width: pill.fullWidth
                height: pill.fullHeight
                anchors.centerIn: parent
                
                opacity: root.isOpen && root.isInitialized ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: root.isOpen ? 550 : 250; easing.type: Easing.InOutQuad } }

        FontMetrics {
            id: labelMetrics
            font.pixelSize: 12
            font.family: "Inter, Roboto, sans-serif"
        }

        // PathView carousel
        PathView {
            id: pv

            anchors.centerIn: parent
            width:  root.wallW + 40
            height: Math.min(root.numVisible * root.itemH, root.height - 40 - root.padV * 2)
            
            highlightMoveDuration: root.moveDuration

            focus: true
            
            Keys.onUpPressed: decrementCurrentIndex()
            Keys.onDownPressed: incrementCurrentIndex()
            Keys.onLeftPressed: decrementCurrentIndex()
            Keys.onRightPressed: incrementCurrentIndex()
            Keys.onEscapePressed: root.dismiss()
            Keys.onReturnPressed: {
                if (pv.currentItem) {
                    const path = root.wallDir + "/" + pv.currentItem.fileName
                    root.currentWall = path
                    Quickshell.execDetached([
                        root.homeDir + "/.local/bin/set-theme", path
                    ])
                    root.dismiss()
                }
            }

            model:          wallModel
            pathItemCount:  root.numVisible
            cacheItemCount: 4

            snapMode:                PathView.SnapOneItem
            preferredHighlightBegin: 0.5
            preferredHighlightEnd:   0.5
            highlightRangeMode:      PathView.StrictlyEnforceRange

            onCountChanged: {
                if (count === 0) return
                for (let i = 0; i < count; i++) {
                    const entryFileName = model.get(i, "fileName")
                    if (entryFileName && root.wallDir + "/" + entryFileName === root.currentWall) {
                        currentIndex = i
                        return
                    }
                }
            }

            path: Path {
                startX: pv.width / 2
                startY: 0
                PathAttribute { name: "z"; value: 0 }
                PathLine { x: pv.width / 2; y: pv.height / 2 }
                PathAttribute { name: "z"; value: 10 }
                PathLine { x: pv.width / 2; y: pv.height }
                PathAttribute { name: "z"; value: 0 }
            }

            delegate: Item {
                id: del

                required property string fileName
                required property url    fileUrl
                required property int    index

                readonly property bool  isCurrent: PathView.isCurrentItem
                readonly property bool  onPath:    PathView.onPath ?? true

                width:   pv.width
                height:  root.itemH
                z:       PathView.z ?? 0

                scale:   onPath ? 1.0 : 0.0
                opacity: onPath ? 1.0 : 0.0

                Behavior on scale {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                    }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                // ── Drop shadow ──────────────────────────

                // ── Thumbnail ──────────────────────────────────────────────
                ClippingRectangle {
                    id: imgClip

                    anchors.verticalCenter:   parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    width:  root.wallW
                    height: root.wallH
                    radius: root.cornerR
                    color:  root.colSub

                    Image {
                        anchors.fill:  parent
                        source:        del.fileUrl
                        fillMode:      Image.PreserveAspectCrop
                        asynchronous:  true
                        smooth:        !pv.moving
                        cache:         true
                        sourceSize:    Qt.size(root.wallW * 2, root.wallH * 2)
                        opacity:       status === Image.Ready ? 1.0 : 0.0
                        Behavior on opacity {
                            NumberAnimation { duration: 400; easing.type: Easing.OutQuad }
                        }
                    }
                }

                // ── Active border ──────────────────────────────────────────
                Rectangle {
                    anchors.fill: imgClip
                    anchors.margins: -4
                    color: "transparent"
                    border.color: root.colPrimary
                    border.width: 3
                    radius: root.cornerR + 4
                    opacity: del.isCurrent ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                // ── Filename label removed ─────────────────────────────────────────

                // ── Click handler ──────────────────────────────────────────
                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: {
                        const path = root.wallDir + "/" + del.fileName
                        root.currentWall = path
                        Quickshell.execDetached([
                            root.homeDir + "/.local/bin/set-theme", path
                        ])
                        root.dismiss()
                    }
                }
            }
        }
            } // Item innerContent
        } // Item contentWrapper

        // ── Top Fillet (Inverse top-left corner) ─────────────────────
        Shape {
            width: 36; height: 36
            anchors.bottom: parent.top
            anchors.bottomMargin: 0
            anchors.left: parent.left
            ShapePath {
                fillColor: Qt.rgba(root.colBg.r, root.colBg.g, root.colBg.b, root.bgOpacity)
                strokeColor: "transparent"
                startX: 36; startY: 36
                PathLine { x: 0; y: 36 }
                PathLine { x: 0; y: 0 }
                PathArc {
                    x: 36; y: 36
                    radiusX: 36; radiusY: 36
                    useLargeArc: false
                    direction: PathArc.Counterclockwise
                }
            }
        }

        // ── Bottom Fillet (Inverse bottom-left corner) ─────────────────────
        Shape {
            width: 36; height: 36
            anchors.top: parent.bottom
            anchors.topMargin: 0
            anchors.left: parent.left
            ShapePath {
                fillColor: Qt.rgba(root.colBg.r, root.colBg.g, root.colBg.b, root.bgOpacity)
                strokeColor: "transparent"
                startX: 36; startY: 0
                PathLine { x: 0; y: 0 }
                PathLine { x: 0; y: 36 }
                PathArc {
                    x: 36; y: 0
                    radiusX: 36; radiusY: 36
                    useLargeArc: false
                    direction: PathArc.Clockwise
                }
            }
        }

    } // Rectangle pill
    } // Item masterWrapper

    // ── Wallpaper Process ────────────────────────────────────────────────
    Process {
        id: wallProc
    }

    // ── Click outside → dismiss ───────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        z: -99
        onClicked: root.dismiss()
    }


}
