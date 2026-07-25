import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import "modules/common"

GridView {
    id: gv

    required property var root

    anchors.centerIn: parent
    width: root.wallW * 2 + 40
    height: Math.min(Math.ceil(count / 2) * (root.wallH + 20), root.height * 0.8)
    cellWidth: root.wallW + 20
    cellHeight: root.wallH + 20

    Keys.onEscapePressed: root.dismiss()
    Keys.onReturnPressed: {
        if (gv.currentItem) {
            const path = root.wallDir + "/" + gv.currentItem.fileName
            root.currentWall = path
            Quickshell.execDetached([
                root.homeDir + "/.local/bin/set-theme", path
            ])
            root.dismiss()
        }
    }
    
    onVisibleChanged: {
        if (visible && root.currentWall !== "") {
            for (let i = 0; i < count; i++) {
                const entryFileName = model.get(i, "fileName")
                if (entryFileName && root.wallDir + "/" + entryFileName === root.currentWall) {
                    currentIndex = i
                    return
                }
            }
        }
    }

    delegate: Item {
        id: delGv
        width: gv.cellWidth
        height: gv.cellHeight

        required property string fileName
        required property url    fileUrl
        required property int    index
        
        readonly property bool isCurrent: GridView.isCurrentItem

        // ── Thumbnail ──────────────────────────────────────────────
        ClippingRectangle {
            id: imgClipGv
            anchors.centerIn: parent
            width:  root.wallW
            height: root.wallH
            radius: root.cornerR
            color:  root.colSub

            Image {
                anchors.fill:  parent
                source:        delGv.fileUrl
                fillMode:      Image.PreserveAspectCrop
                asynchronous:  true
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
            anchors.fill: imgClipGv
            anchors.margins: -4
            color: "transparent"
            border.color: root.colPrimary
            border.width: 3
            radius: root.cornerR + 4
            opacity: delGv.isCurrent ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape:  Qt.PointingHandCursor
            onClicked: {
                gv.currentIndex = index
                const path = root.wallDir + "/" + delGv.fileName
                root.currentWall = path
                Quickshell.execDetached([
                    root.homeDir + "/.local/bin/set-theme", path
                ])
                root.dismiss()
            }
        }
    }
}
