import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../common"
import "../../../theme"

Item {
    id: clipSplitPill
    
    readonly property bool isAttached: Theme.barDropdownStyle === "Attached"

    // Multi-mode Y position
    y: bar.isBottom ? (solidBar.y - height - (isAttached ? 0 : 8)) : (isAttached ? (bar.midY + bar.barHeight) : (bar.midY + bar.barHeight + 8))
    Behavior on y { enabled: !bar.isBottom; NumberAnimation { duration: 350; easing.type: Easing.InOutExpo } }
    
    property bool menuExpanded: globalState.clipboardOpen
    readonly property real expandedW: 380
    readonly property real expandedH: 480
    property real contentW: expandedW
    
    // Balanced padding constants
    readonly property real padTop: isAttached ? 0 : 16
    readonly property real padSide: isAttached ? 30 : 18
    readonly property real padBottom: isAttached ? 24 : 18

    readonly property real targetH: expandedH

    // Aligned to the start boundary of the clock section
    x: clockItem.x + contentLayout.x + solidBar.x - contentW
    width: contentW
    height: menuExpanded ? targetH : 0

    // Signature smooth animations
    Behavior on height {
        NumberAnimation {
            duration: 450
            easing.type: Easing.InOutExpo
        }
    }
    Behavior on width {
        NumberAnimation {
            duration: 400
            easing.type: Easing.InOutExpo
        }
    }
    Behavior on x {
        NumberAnimation {
            duration: 400
            easing.type: Easing.InOutExpo
        }
    }

    property real openProgress: menuExpanded ? 1.0 : 0.0
    Behavior on openProgress {
        NumberAnimation {
            duration: 320
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
        }
    }

    opacity: openProgress
    visible: height > 0 || opacity > 0.01

    // ── Data State ──
    property var rawClipData: []
    property string activeFilter: "all"
    property string searchQuery: ""
    property string toastMessage: ""
    property bool showToast: false

    function refreshData() { fetchProc.running = true; }

    function copyClip(clipId) {
        execProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/clip_daemon.py", "copy", clipId];
        execProc.running = true;
        triggerToast("Copied to clipboard!");
    }

    function togglePin(clipId) {
        execProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/clip_daemon.py", "pin", clipId];
        execProc.running = true;
        refreshTimer.start();
    }

    function deleteClip(clipId) {
        execProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/clip_daemon.py", "delete", clipId];
        execProc.running = true;
        refreshTimer.start();
        triggerToast("Clip deleted");
    }

    function clearAll() {
        execProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/clip_daemon.py", "clear"];
        execProc.running = true;
        refreshTimer.start();
        triggerToast("Cleared unpinned clips");
    }

    function triggerToast(msg) {
        toastMessage = msg;
        showToast = true;
        toastTimer.restart();
    }

    function getFilteredData() {
        let list = rawClipData || [];
        let query = searchQuery.trim().toLowerCase();
        let filter = activeFilter;
        return list.filter((item) => {
            if (filter === "text" && item.type !== "text") return false;
            if (filter === "image" && item.type !== "image") return false;
            if (filter === "pinned" && !item.pinned) return false;
            if (query !== "") {
                let textMatch = item.content && item.content.toLowerCase().includes(query);
                let prevMatch = item.preview && item.preview.toLowerCase().includes(query);
                if (!textMatch && !prevMatch) return false;
            }
            return true;
        });
    }

    Process {
        id: fetchProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/clip_daemon.py", "get"]
        stdout: SplitParser {
            onRead: (data) => {
                try { clipSplitPill.rawClipData = JSON.parse(data); } catch (e) {}
            }
        }
    }

    Process { id: execProc }

    Timer { id: refreshTimer; interval: 150; onTriggered: refreshData() }
    Timer { id: toastTimer; interval: 1800; onTriggered: showToast = false }
    Timer { interval: 3000; running: menuExpanded; repeat: true; onTriggered: refreshData() }

    Connections {
        target: globalState
        function onClipboardOpenChanged() {
            if (globalState.clipboardOpen) {
                refreshData();
                searchInput.text = "";
                searchQuery = "";
                searchInput.forceActiveFocus();
            }
        }
    }

    // ── Dropdown Container ──────────────────────────────────────────
    Item {
        id: animContainer
        anchors.fill: parent
        clip: false
        layer.enabled: true
        layer.samples: 8
        layer.smooth: true

        // ── Attached Mode: Seamless Inverted Notch Cutout ──────────
        Shape {
            id: bgShape
            anchors.fill: parent
            visible: clipSplitPill.isAttached
            property color shapeColor: bar.pillColor
            readonly property real r: 16
            readonly property real w: width
            readonly property real h: Math.max(height, 1)

            layer.enabled: true
            layer.samples: 8
            layer.smooth: true

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: bgShape.shapeColor
                startX: 0
                startY: 0

                // Top-Left Inverted Concave Arc
                PathArc {
                    x: bgShape.r
                    y: bgShape.r
                    radiusX: bgShape.r
                    radiusY: bgShape.r
                    direction: PathArc.Clockwise
                }

                // Left Wall
                PathLine {
                    x: bgShape.r
                    y: Math.max(bgShape.r, bgShape.h - bgShape.r)
                }

                // Bottom-Left Smooth Curve
                PathArc {
                    x: 2 * bgShape.r
                    y: bgShape.h
                    radiusX: bgShape.r
                    radiusY: bgShape.r
                    direction: PathArc.Counterclockwise
                }

                // Bottom Line
                PathLine {
                    x: Math.max(2 * bgShape.r, bgShape.w - 2 * bgShape.r)
                    y: bgShape.h
                }

                // Bottom-Right Smooth Curve
                PathArc {
                    x: bgShape.w - bgShape.r
                    y: Math.max(bgShape.r, bgShape.h - bgShape.r)
                    radiusX: bgShape.r
                    radiusY: bgShape.r
                    direction: PathArc.Counterclockwise
                }

                // Right Wall
                PathLine {
                    x: bgShape.w - bgShape.r
                    y: bgShape.r
                }

                // Top-Right Inverted Concave Arc
                PathArc {
                    x: bgShape.w
                    y: 0
                    radiusX: bgShape.r
                    radiusY: bgShape.r
                    direction: PathArc.Clockwise
                }

                // Top Edge Connection
                PathLine {
                    x: 0
                    y: 0
                }
            }
        }

        // ── Floating Mode: Rounded Rectangle Background ──────────
        Rectangle {
            anchors.fill: parent
            visible: !clipSplitPill.isAttached
            radius: 16
            color: bar.pillColor
            antialiasing: true
            border.width: 1
            border.color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.12)
        }

        // ── CONTENT COLUMN ──
        ColumnLayout {
            id: clipContentCol
            anchors.fill: parent
            anchors.topMargin: padTop
            anchors.bottomMargin: padBottom
            anchors.leftMargin: padSide
            anchors.rightMargin: padSide
            spacing: 12

            // 1. Minimal Header Row
            RowLayout {
                Layout.fillWidth: true
                height: 20
                spacing: 8

                Text {
                    text: "CLIPBOARD"
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 0.5
                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                    Layout.fillWidth: true
                }

                // Clear unpinned button
                Rectangle {
                    width: 24; height: 24; radius: 12
                    color: clearMa.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.2) : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb41" // trash icon
                        font.family: bar.fontName
                        font.pixelSize: 13
                        color: clearMa.containsMouse ? Theme.colError : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.55)
                    }
                    MouseArea {
                        id: clearMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: clearAll()
                    }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Close button
                Rectangle {
                    width: 24; height: 24; radius: 12
                    color: closeMa.containsMouse ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.12) : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "\ueb55" // x close icon
                        font.family: bar.fontName
                        font.pixelSize: 12
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.55)
                    }
                    MouseArea {
                        id: closeMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: globalState.clipboardOpen = false
                    }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            // 2. Search Bar
            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 10
                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.07)
                border.color: searchInput.activeFocus ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.3) : "transparent"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12; anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: "\ueb1c" // search
                        font.family: bar.fontName
                        font.pixelSize: 14
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 12
                        color: bar.fg
                        selectByMouse: true
                        onTextChanged: searchQuery = text
                        Keys.onEscapePressed: globalState.clipboardOpen = false
                        Keys.onReturnPressed: {
                            let filtered = getFilteredData();
                            if (filtered.length > 0) {
                                copyClip(filtered[0].id);
                                globalState.clipboardOpen = false;
                            }
                        }

                        Text {
                            text: "Search clipboard history..."
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 12
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.35)
                            visible: !searchInput.text && !searchInput.inputMethodComposing
                        }
                    }

                    Text {
                        visible: searchInput.text !== ""
                        text: "\ueb55" // x close icon
                        font.family: bar.fontName
                        font.pixelSize: 13
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { searchInput.text = ""; searchQuery = ""; }
                        }
                    }
                }
            }

            // 3. Filter Pills Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [
                        { "id": "all", "label": "All" },
                        { "id": "text", "label": "Text" },
                        { "id": "image", "label": "Images" },
                        { "id": "pinned", "label": "Pinned" }
                    ]

                    Rectangle {
                        height: 26
                        width: filterText.implicitWidth + 18
                        radius: 13
                        color: activeFilter === modelData.id
                               ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.16)
                               : (filterMa.containsMouse ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.09) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.04))

                        Text {
                            id: filterText
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            font.weight: activeFilter === modelData.id ? Font.Bold : Font.Normal
                            color: activeFilter === modelData.id ? bar.fg : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6)
                        }

                        MouseArea {
                            id: filterMa
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: activeFilter = modelData.id
                        }

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }

            // 4. Clips List
            ListView {
                id: clipListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: getFilteredData()

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        radius: width / 2
                        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.2)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: clipListView.count === 0
                    text: "No clips found"
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 12
                    color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.4)
                }

                delegate: Rectangle {
                    id: itemCard
                    width: clipListView.width
                    height: 50
                    radius: 10
                    color: itemMa.containsMouse
                           ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.10)
                           : (modelData.pinned ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.07) : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.03))
                    border.color: modelData.pinned ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.22) : "transparent"
                    border.width: 1

                    // Background Click Area for Copying
                    MouseArea {
                        id: itemMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton
                        onClicked: {
                            copyClip(modelData.id);
                            globalState.clipboardOpen = false;
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10
                        z: 5

                        Rectangle {
                            width: 32; height: 32
                            radius: 8
                            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.08)

                            Text {
                                anchors.centerIn: parent
                                text: modelData.type === "image" ? "\ueb0a" : "\uea6f"
                                font.family: bar.fontName
                                font.pixelSize: 15
                                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.65)
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: modelData.type === "image" ? "Image Data" : (modelData.preview || "")
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 11
                                font.weight: modelData.pinned ? Font.Bold : Font.Normal
                                color: bar.fg
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.WrapAnywhere
                            }
                        }

                        RowLayout {
                            spacing: 4
                            z: 10

                            Rectangle {
                                width: 24; height: 24; radius: 12
                                color: modelData.pinned
                                       ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.18)
                                       : (pinMa.containsMouse ? Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.10) : "transparent")

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.pinned ? "\uf68d" : "\uec9c"
                                    font.family: bar.fontName
                                    font.pixelSize: 13
                                    color: modelData.pinned ? bar.fg : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                                }

                                MouseArea {
                                    id: pinMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton
                                    onClicked: (mouse) => {
                                        mouse.accepted = true;
                                        togglePin(modelData.id);
                                    }
                                }

                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            Rectangle {
                                width: 24; height: 24; radius: 12
                                color: delMa.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.25) : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "\ueb55"
                                    font.family: bar.fontName
                                    font.pixelSize: 12
                                    color: delMa.containsMouse ? Theme.colError : Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.45)
                                }

                                MouseArea {
                                    id: delMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton
                                    onClicked: (mouse) => {
                                        mouse.accepted = true;
                                        deleteClip(modelData.id);
                                    }
                                }

                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                    }

                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }

        // Toast Feedback
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            height: 26
            width: toastText.implicitWidth + 20
            radius: 13
            color: bar.pillColor
            border.color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.25)
            border.width: 1
            opacity: showToast ? 1 : 0
            visible: opacity > 0
            z: 100

            Text {
                id: toastText
                anchors.centerIn: parent
                text: toastMessage
                font.family: Theme.defaultFontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
                color: bar.fg
            }

            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }
}
