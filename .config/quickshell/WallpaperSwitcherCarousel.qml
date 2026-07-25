import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import "modules/common"

PathView {
    id: pv

    required property var root

    anchors.centerIn: parent
    width:  root.wallW + 40
    height: Math.min(root.numVisible * root.itemH, root.height - 40 - root.padV * 2)
    
    highlightMoveDuration: root.moveDuration
    
    property real lastKeyTime: 0
    
    function handleKey(event, isNext) {
        let now = Date.now();
        // Throttle exactly to the animation duration to prevent movement queueing
        if (now - pv.lastKeyTime < root.moveDuration) {
            event.accepted = true;
            return;
        }
        pv.lastKeyTime = now;
        
        if (isNext) incrementCurrentIndex();
        else decrementCurrentIndex();
        event.accepted = true;
    }

    Keys.onUpPressed: function(event) { handleKey(event, false); }
    Keys.onDownPressed: function(event) { handleKey(event, true); }
    Keys.onLeftPressed: function(event) { handleKey(event, false); }
    Keys.onRightPressed: function(event) { handleKey(event, true); }
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
        startY: (root.numVisible % 2 === 0) ? root.itemH / 2 : 0
        PathAttribute { name: "z"; value: 0 }
        PathLine { x: pv.width / 2; y: ((root.numVisible % 2 === 0) ? root.itemH / 2 : 0) + pv.height / 2 }
        PathAttribute { name: "z"; value: 10 }
        PathLine { x: pv.width / 2; y: ((root.numVisible % 2 === 0) ? root.itemH / 2 : 0) + pv.height }
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
    } // Item del
}
