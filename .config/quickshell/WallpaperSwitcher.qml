import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Qt.labs.folderlistmodel
import "theme"

PanelWindow {
    id: root

    anchors { bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "cupcake-wallpaper"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"
    implicitHeight: 9000

    // ── Caelestia exact token values ─────────────────────────────────────
    readonly property int    wallW:       280          // wallpaperWidth
    readonly property int    wallH:       Math.round(wallW / 16 * 9)  // 157
    readonly property int    itemW:       180          // Spacing distance for stacking effect
    readonly property int    cornerR:     17           // rounding.normal
    readonly property int    padH:        50           // padding
    readonly property int    padV:        15
    readonly property int    labelGap:    7            // spacing.small
    readonly property int    maxVisible:  Math.min(5, wallModel.count)
    readonly property int    numVisible:  maxVisible > 1 && maxVisible % 2 === 0 ? maxVisible - 1 : (maxVisible || 1)

    // ── Palette ──────────────────────────────────────────────────────────
    readonly property color colBg:      Theme.colSurfaceContainerHigh
    readonly property color colSub:     Theme.colSurface
    readonly property color colFgDim:   Theme.colOnSurfaceVariant
    readonly property color colPrimary: Theme.colPrimary

    readonly property string wallDir: "/home/one/.config/cupcake/walls"

    // ── Current wallpaper ────────────────────────────────────────────────
    property string currentWall: ""
    property bool   isInitialized: false
    property int    moveDuration: 0

    Process {
        command: ["swww", "query"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const m = data.match(/currently displaying: image: (.+)/)
                if (m) root.currentWall = m[1].trim()
            }
        }
    }

    // ── Slide-up animation ────────────────────────────────────────────────
    property bool isOpen: false

    Component.onCompleted: Qt.callLater(() => { isOpen = true })

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
        function toggle(): void {
            if (root.visible && root.isOpen) {
                root.dismiss()
            } else {
                root.moveDuration = 0
                root.isOpen = false
                root.visible = true
                
                Qt.callLater(() => {
                    root.isOpen = true
                    // Fetch latest desktop wallpaper on reappear
                    queryProc.running = true
                })
            }
        }
    }

    // ── Find Current Wallpaper ───────────────────────────────────────────
    Process {
        id: queryProc
        command: ["/home/one/.local/bin/swww", "query"]
        running: true
        stdout: StdioCollector {
            id: queryStdout
        }
        onExited: {
            const out = queryStdout.text
            const match = out.match(/image:\s*(.*)/)
            if (match && match[1]) {
                const fullPath = match[1].trim()
                root.currentWall = fullPath
                const fileName = fullPath.split('/').pop()
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
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.width
        height: pill.height + 1
        clip: true

    // ── Pill ─────────────────────────────────────────────────────────────
    Rectangle {
        id: pill

        anchors.bottom:           parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin:     0

        readonly property int fullWidth: pv.width + root.padH * 2
        readonly property int fullHeight: root.wallH + 12 + 15 + root.padV * 2 // approximation for label metrics height

        width: root.isOpen ? fullWidth : 160
        height: root.isOpen ? fullHeight : 0

        Behavior on width { NumberAnimation { duration: 550; easing.type: Easing.InOutExpo } }
        Behavior on height { NumberAnimation { duration: 550; easing.type: Easing.InOutExpo } }

        color: root.colBg
        topLeftRadius: 36
        topRightRadius: 36
        bottomLeftRadius: 0
        bottomRightRadius: 0

        Item {
            id: contentWrapper
            width: pill.width
            height: pill.height
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            clip: true
            
            Item {
                id: innerContent
                width: pill.fullWidth
                height: pill.fullHeight
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                
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
            width:  Math.min(root.numVisible * root.itemW, root.width - 40 - root.padH * 2)
            height: parent.height
            
            highlightMoveDuration: root.moveDuration

            focus: true
            
            Keys.onLeftPressed: decrementCurrentIndex()
            Keys.onRightPressed: incrementCurrentIndex()
            Keys.onEscapePressed: root.dismiss()
            Keys.onReturnPressed: {
                if (pv.currentItem) {
                    const path = root.wallDir + "/" + pv.currentItem.fileName
                    root.currentWall = path
                    wallProc.command = [
                        "/home/one/.local/bin/set-theme", path
                    ]
                    wallProc.running = true
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
                    const entry = model.get(i)
                    if (entry && root.wallDir + "/" + entry.fileName === root.currentWall) {
                        currentIndex = i
                        return
                    }
                }
            }

            path: Path {
                startX: 0
                startY: pv.height / 2
                PathAttribute { name: "z"; value: 0 }
                PathLine { x: pv.width / 2; relativeY: 0 }
                PathAttribute { name: "z"; value: 10 }
                PathLine { x: pv.width; relativeY: 0 }
                PathAttribute { name: "z"; value: 0 }
            }

            delegate: Item {
                id: del

                required property string fileName
                required property url    fileUrl
                required property int    index

                readonly property bool  isCurrent: PathView.isCurrentItem
                readonly property bool  onPath:    PathView.onPath ?? true

                width:   root.itemW
                height:  pv.height
                z:       PathView.z ?? 0

                scale:   isCurrent ? 1.0 : (onPath ? 0.8 : 0.0)
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
                Rectangle {
                    anchors.centerIn: imgClip
                    anchors.verticalCenterOffset: 2
                    width:  imgClip.width + 6
                    height: imgClip.height + 6
                    radius: root.cornerR + 3
                    color:  Qt.rgba(0, 0, 0, 0.35)
                    z:      -2
                }
                Rectangle {
                    anchors.centerIn: imgClip
                    anchors.verticalCenterOffset: 4
                    width:  imgClip.width + 12
                    height: imgClip.height + 12
                    radius: root.cornerR + 6
                    color:  Qt.rgba(0, 0, 0, 0.15)
                    z:      -3
                }

                // ── Thumbnail ──────────────────────────────────────────────
                ClippingRectangle {
                    id: imgClip

                    anchors.top:              parent.top
                    anchors.topMargin:        root.padV
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

                // ── Active border removed ──────────────────────────────────

                // ── Filename label ─────────────────────────────────────────
                Text {
                    anchors.top:              imgClip.bottom
                    anchors.topMargin:        root.labelGap
                    anchors.horizontalCenter: parent.horizontalCenter
                    width:                    root.wallW - 16

                    text:                del.fileName.replace(/\.[^.]+$/, "")
                    color:               del.isCurrent ? root.colPrimary : root.colFgDim
                    opacity:             del.isCurrent ? 1.0 : 0.0
                    font.pixelSize:      12
                    font.family:         "Inter, Roboto, sans-serif"
                    font.weight:         del.isCurrent ? 600 : 400
                    elide:               Text.ElideMiddle
                    horizontalAlignment: Text.AlignHCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                // ── Click handler ──────────────────────────────────────────
                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: {
                        const path = root.wallDir + "/" + del.fileName
                        root.currentWall = path
                        wallProc.command = [
                            "/home/one/.local/bin/set-theme", path
                        ]
                        wallProc.running = true
                        root.dismiss()
                    }
                }
            }
        }
            } // Item innerContent
        } // Item contentWrapper

        // ── Left Fillet (Inverse bottom-left corner) ─────────────────────
        Shape {
            width: 36; height: 36
            anchors.bottom: parent.bottom
            anchors.right: parent.left
            anchors.rightMargin: -1
            ShapePath {
                fillColor: root.colBg
                strokeColor: "transparent"
                startX: 36; startY: 0
                PathLine { x: 36; y: 36 }
                PathLine { x: 0; y: 36 }
                PathArc {
                    x: 36; y: 0
                    radiusX: 36; radiusY: 36
                    useLargeArc: false
                    direction: PathArc.Counterclockwise
                }
            }
        }

        // ── Right Fillet (Inverse bottom-right corner) ────────────────────
        Shape {
            width: 36; height: 36
            anchors.bottom: parent.bottom
            anchors.left: parent.right
            anchors.leftMargin: -1
            ShapePath {
                fillColor: root.colBg
                strokeColor: "transparent"
                startX: 0; startY: 0
                PathLine { x: 0; y: 36 }
                PathLine { x: 36; y: 36 }
                PathArc {
                    x: 0; y: 0
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
