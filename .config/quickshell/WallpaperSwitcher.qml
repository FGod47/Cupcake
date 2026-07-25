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
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
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
    readonly property int    numVisible:  maxVisible || 1

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
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) root.currentWall = text.trim()
            }
        }
    }

    // ── Slide-up animation ────────────────────────────────────────────────
    property bool isOpen: false



    function dismiss() {
        if (userDismissed) return;
        userDismissed = true;
        isOpen = false;
        Quickshell.execDetached(["bash", "-c",
            "sleep 0.55 && pkill -f '[q]uickshell.*WallpaperSwitcher.qml'"]);
    }

    property bool userDismissed: false

    Component.onCompleted: {
        root.visible = true;
        Qt.callLater(() => {
            root.isOpen = true;
            pv.forceActiveFocus();
        });
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
                    const currentFileName = root.currentWall.split('/').pop()
                    for (let i = 0; i < wallModel.count; i++) {
                        if (wallModel.get(i, "fileName") === currentFileName) {
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

    // ── Invisible Scrim (Click outside to close) ───────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: root.dismiss()
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

        readonly property int fullWidth: Theme.wallpaperSwitcherStyle === "Grid" ? root.wallW * 2 + 100 : root.wallW + root.padH * 2
        readonly property int fullHeight: Theme.wallpaperSwitcherStyle === "Grid" ? gv.height + root.padV * 2 : pv.height + root.padV * 2 // approximation for label metrics height


        width: root.isOpen ? fullWidth : 0
        height: root.isOpen ? fullHeight : 160

        Behavior on width { NumberAnimation { duration: 550; easing.type: Easing.InOutExpo } }
        Behavior on height { NumberAnimation { duration: 550; easing.type: Easing.InOutExpo } }

        color: Qt.rgba(root.colBg.r, root.colBg.g, root.colBg.b, root.bgOpacity)
        topRightRadius: 36
        bottomRightRadius: 36
        topLeftRadius: 0
        bottomLeftRadius: 0

        // We place the inner content in a separate Item
        // and fade it out so it doesn't squish during the width animation
        Item {
            id: contentWrapper
            width: pill.width
            height: pill.height
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            
            Item {
                id: innerContent
                anchors.fill: parent
                opacity: root.isOpen && root.isInitialized ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                }

                WallpaperSwitcherCarousel {
                    id: pv
                    root: root
                    model: wallModel
                    visible: Theme.wallpaperSwitcherStyle !== "Grid"
                    focus: visible
                }
                
                // GridView layout
                WallpaperSwitcherGrid {
                    id: gv
                    root: root
                    model: wallModel
                    visible: Theme.wallpaperSwitcherStyle === "Grid"
                    focus: visible
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
