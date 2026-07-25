import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import "modules/common"

Item {
    id: gv

    required property var root
    property var model

    anchors.centerIn: parent
    width: root.wallW + 100
    height: root.wallH * 2.6 + 120

    property int currentIndex: 0
    readonly property int count: rep.count

    Keys.onEscapePressed: root.dismiss()
    Keys.onReturnPressed: {
        if (count > 0 && currentIndex >= 0 && currentIndex < count) {
            const fileName = gv.model.get(currentIndex, "fileName")
            if (fileName) {
                const path = root.wallDir + "/" + fileName
                root.currentWall = path
                Quickshell.execDetached([
                    root.homeDir + "/.local/bin/set-theme", path
                ])
                root.dismiss()
            }
        }
    }
    
    Keys.onUpPressed: { gv.currentIndex = (gv.currentIndex > 0) ? gv.currentIndex - 1 : count - 1 }
    Keys.onDownPressed: { gv.currentIndex = (gv.currentIndex < count - 1) ? gv.currentIndex + 1 : 0 }
    Keys.onLeftPressed: { gv.currentIndex = (gv.currentIndex > 0) ? gv.currentIndex - 1 : count - 1 }
    Keys.onRightPressed: { gv.currentIndex = (gv.currentIndex < count - 1) ? gv.currentIndex + 1 : 0 }

    onVisibleChanged: {
        if (visible && root.currentWall !== "") {
            for (let i = 0; i < count; i++) {
                const entryFileName = gv.model.get(i, "fileName")
                if (entryFileName && root.wallDir + "/" + entryFileName === root.currentWall) {
                    currentIndex = i
                    return
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) {
                gv.currentIndex = (gv.currentIndex > 0) ? gv.currentIndex - 1 : gv.count - 1
            } else {
                gv.currentIndex = (gv.currentIndex < gv.count - 1) ? gv.currentIndex + 1 : 0
            }
        }
    }

    // ── Title ────────────────────────────────────────────────────────────
    Text {
        text: "WALLPAPER"
        color: root.colFgDim
        font.family: Theme.defaultFontFamily
        font.pixelSize: 11
        font.weight: Font.Bold
        font.letterSpacing: 1.4
        anchors.top: parent.top
        anchors.topMargin: 20
        anchors.left: parent.left
        anchors.leftMargin: 20
    }

    // ── Carousel Stage ───────────────────────────────────────────────────
    Item {
        id: stageContainer
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -15
        width: root.wallW + 40
        height: root.wallH * 2.6

        Row {
            anchors.centerIn: parent
            spacing: 20

            Item {
                id: stage
                width: root.wallW
                height: root.wallH

            Repeater {
                id: rep
                model: gv.model

                delegate: Item {
                    id: del
                    width: root.wallW
                    height: root.wallH
                    anchors.centerIn: parent

                    required property string fileName
                    required property url    fileUrl
                    required property int    index

                    readonly property int rawOffset: index - gv.currentIndex
                    readonly property int offset: {
                        let o = rawOffset
                        const half = Math.floor(gv.count / 2)
                        if (o > half) o -= gv.count
                        else if (o < -Math.floor((gv.count - 1) / 2)) o += gv.count
                        return o
                    }
                    readonly property int absOffset: Math.abs(offset)
                    readonly property bool isActive: offset === 0

                    readonly property real yShiftBase: root.wallH * (80.0 / 150.0)
                    readonly property real yShiftFar: root.wallH * (90.0 / 150.0)

                    z: 100 - absOffset
                    
                    property real targetY: absOffset > 1 ? offset * yShiftFar : offset * yShiftBase
                    property real targetScale: absOffset > 1 ? 0.7 : (1.0 - absOffset * 0.15)
                    property real targetOpacity: absOffset > 1 ? 0.0 : Math.max(1.0 - absOffset * 0.42, 0.18)
                    property real targetBrightness: isActive ? 1.0 : (1.0 - absOffset * 0.18)

                    transform: Translate { y: del.targetY }
                    scale: targetScale
                    opacity: targetOpacity

                    Behavior on targetY { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

                    // ── Thumbnail ──────────────────────────────────────────────
                    ClippingRectangle {
                        id: imgClip
                        anchors.fill: parent
                        radius: root.cornerR
                        color: root.colSub

                        // Emulate the filter: brightness(...) via an overlay rectangle
                        Rectangle {
                            anchors.fill: parent
                            color: "black"
                            opacity: 1.0 - del.targetBrightness
                            z: 10
                            Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
                        }

                        Image {
                            anchors.fill: parent
                            source: del.fileUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            sourceSize: Qt.size(root.wallW * 2, root.wallH * 2)
                            opacity: status === Image.Ready ? 1.0 : 0.0
                            Behavior on opacity {
                                NumberAnimation { duration: 400; easing.type: Easing.OutQuad }
                            }
                        }
                    }

                    // ── Inactive border ────────────────────────────────────────
                    Rectangle {
                        anchors.fill: imgClip
                        color: "transparent"
                        border.color: Qt.rgba(1, 1, 1, 0.10)
                        border.width: 1
                        radius: root.cornerR
                    }

                    // ── Applied Badge ──────────────────────────────────────────────────
                    Rectangle {
                        anchors.top: imgClip.top
                        anchors.right: imgClip.right
                        anchors.margins: 12
                        width: badgeRow.width + 16
                        height: 24
                        radius: 12
                        color: root.colPrimary
                        
                        readonly property bool isApplied: root.currentWall === (root.wallDir + "/" + del.fileName)
                        opacity: isApplied ? (del.isActive ? 1.0 : 0.4) : 0.0
                        Behavior on opacity { NumberAnimation { duration: 250 } }

                        Row {
                            id: badgeRow
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: "\uea5e"
                                color: Theme.colOnPrimary
                                font.family: "tabler-icons"
                                font.pixelSize: 13
                                font.weight: Font.Bold
                            }
                            Text {
                                text: "Active"
                                color: Theme.colOnPrimary
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 11
                                font.weight: Font.Bold
                            }
                        }
                    }

                    // ── Label ──────────────────────────────────────────────────
                    Rectangle {
                        id: labelBg
                        anchors.left: imgClip.left
                        anchors.bottom: imgClip.bottom
                        anchors.leftMargin: 12
                        anchors.bottomMargin: 11
                        width: labelText.width + 18
                        height: labelText.height + 8
                        radius: 20
                        color: Qt.rgba(0, 0, 0, 0.4)
                        opacity: del.isActive ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 250 } }

                        Text {
                            id: labelText
                            anchors.centerIn: parent
                            text: del.fileName.replace(/\.[^/.]+$/, "")
                            color: "#ffffff"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
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
                        opacity: del.isActive ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: del.absOffset <= 1
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!del.isActive) {
                                gv.currentIndex = index
                            } else {
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
            }
            } // Close stage

            // ── Dots Pagination ──────────────────────────────────────────────────
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Repeater {
                    model: gv.model
                    delegate: Rectangle {
                        width: 6
                        height: isCurrent ? 16 : 6
                        radius: isCurrent ? 4 : 3
                        color: isCurrent ? root.colPrimary : Qt.rgba(root.colFgDim.r, root.colFgDim.g, root.colFgDim.b, 0.3)
                        
                        readonly property bool isCurrent: index === gv.currentIndex

                        Behavior on height { NumberAnimation { duration: 200 } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: gv.currentIndex = index
                        }
                    }
                }
            }
        }
    }

    // ── Cupcake Logo ─────────────────────────────────────────────────────
    Image {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30
        anchors.horizontalCenter: parent.horizontalCenter
        width: 180
        height: 44
        fillMode: Image.PreserveAspectFit
        source: root.homeDir + "/Cupcake/Source/assets/cupcake-word-light.svg"
        opacity: 0.5
        smooth: true
        antialiasing: true
    }
}
