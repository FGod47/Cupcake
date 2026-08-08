import "../../../theme"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: clipDropdownPill

    property bool menuExpanded: globalState.clipboardOpen
    readonly property real openGap: 16
    readonly property real expandedW: 360
    readonly property real expandedH: 480
    readonly property int dur: 600
    readonly property int easingType: Easing.OutQuart

    property real clockHeaderW: 100 // Passed from BarSolid
    property real headerW: 36
    property real contentW: menuExpanded ? expandedW : headerW

    y: 10
    height: menuExpanded ? expandedH : 30
    x: menuExpanded ? (bar.barX + bar.barW - clockHeaderW - openGap - contentW) : (bar.barX + bar.barW - clockHeaderW - openGap - headerW)
    width: contentW
    radius: menuExpanded ? 16 : 15
    clip: true
    color: bar.pillColor
    z: 99
    opacity: menuExpanded ? 1 : 0
    visible: opacity > 0

    Behavior on x { NumberAnimation { duration: clipDropdownPill.dur; easing.type: clipDropdownPill.easingType } }
    Behavior on width { NumberAnimation { duration: clipDropdownPill.dur; easing.type: clipDropdownPill.easingType } }
    Behavior on height { NumberAnimation { duration: clipDropdownPill.dur; easing.type: clipDropdownPill.easingType } }
    Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }

    // ── Data State ──
    property var rawClipData: []
    property string activeFilter: "all"
    property string searchQuery: ""
    property string toastMessage: ""
    property bool showToast: false

    function refreshData() { fetchProc.running = true; }

    function copyClip(clipId) {
        execProc.command = ["python3", Quickshell.env("HOME") + "/Cupcake/.config/quickshell/scripts/clip_daemon.py", "copy", clipId];
        execProc.running = true;
        triggerToast("Copied to clipboard!");
    }

    function togglePin(clipId) {
        execProc.command = ["python3", Quickshell.env("HOME") + "/Cupcake/.config/quickshell/scripts/clip_daemon.py", "pin", clipId];
        execProc.running = true;
        refreshTimer.start();
    }

    function deleteClip(clipId) {
        execProc.command = ["python3", Quickshell.env("HOME") + "/Cupcake/.config/quickshell/scripts/clip_daemon.py", "delete", clipId];
        execProc.running = true;
        refreshTimer.start();
    }

    function clearAll() {
        execProc.command = ["python3", Quickshell.env("HOME") + "/Cupcake/.config/quickshell/scripts/clip_daemon.py", "clear"];
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

    FontLoader {
        id: clipTablerFont
        source: Qt.resolvedUrl("file://" + Quickshell.env("HOME") + "/.local/share/fonts/tabler-icons.ttf")
    }

    Process {
        id: fetchProc
        command: ["python3", Quickshell.env("HOME") + "/Cupcake/.config/quickshell/scripts/clip_daemon.py", "get"]
        stdout: SplitParser {
            onRead: (data) => {
                try { clipDropdownPill.rawClipData = JSON.parse(data); } catch (e) {}
            }
        }
    }

    Process { id: execProc }

    Timer { id: refreshTimer; interval: 150; onTriggered: refreshData() }
    Timer { id: toastTimer; interval: 1800; onTriggered: showToast = false }
    Timer { interval: 2000; running: menuExpanded; repeat: true; onTriggered: refreshData() }

    Connections {
        target: globalState
        function onClipboardOpenChanged() {
            if (globalState.clipboardOpen) {
                refreshData();
                searchInput.text = "";
                searchQuery = "";
            }
        }
    }

    // ── MAIN CONTENT LAYOUT ──
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // 1. Header Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "\uea6d"
                font.family: clipTablerFont.name
                font.pixelSize: 18
                color: "#ffc864"
            }

            Text {
                text: "Clipboard History"
                font.family: "Inter, sans-serif"
                font.pixelSize: 14
                font.weight: Font.Bold
                color: "#FFFFFF"
                Layout.fillWidth: true
            }

            // Clear unpinned button
            Rectangle {
                width: 28; height: 28; radius: 14
                color: clearMa.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.25) : Qt.rgba(1, 1, 1, 0.08)
                Text {
                    anchors.centerIn: parent
                    text: "\uea8c"
                    font.family: clipTablerFont.name
                    font.pixelSize: 15
                    color: clearMa.containsMouse ? "#ff6b6b" : Qt.rgba(1, 1, 1, 0.7)
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
                width: 28; height: 28; radius: 14
                color: closeMa.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(1, 1, 1, 0.08)
                Text {
                    anchors.centerIn: parent
                    text: "\ueb55"
                    font.family: clipTablerFont.name
                    font.pixelSize: 15
                    color: Qt.rgba(1, 1, 1, 0.7)
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
            radius: 18
            color: Qt.rgba(1, 1, 1, 0.08)
            border.color: searchInput.activeFocus ? Qt.rgba(1, 1, 1, 0.3) : "transparent"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12; anchors.rightMargin: 12
                spacing: 8

                Text {
                    text: "\ueb1c"
                    font.family: clipTablerFont.name
                    font.pixelSize: 15
                    color: Qt.rgba(1, 1, 1, 0.5)
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    font.family: "Inter, sans-serif"
                    font.pixelSize: 12
                    color: "#FFFFFF"
                    selectByMouse: true
                    onTextChanged: searchQuery = text

                    Text {
                        text: "Search clipboard..."
                        font.family: "Inter, sans-serif"
                        font.pixelSize: 12
                        color: Qt.rgba(1, 1, 1, 0.35)
                        visible: !searchInput.text && !searchInput.inputMethodComposing
                    }
                }

                Text {
                    visible: searchInput.text !== ""
                    text: "\ueb55"
                    font.family: clipTablerFont.name
                    font.pixelSize: 14
                    color: Qt.rgba(1, 1, 1, 0.5)
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
                    { "id": "pinned", "label": "Pinned 📌" }
                ]

                Rectangle {
                    height: 24
                    width: filterText.implicitWidth + 16
                    radius: 12
                    color: activeFilter === modelData.id ? Qt.rgba(1, 1, 1, 0.22) : (filterMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05))

                    Text {
                        id: filterText
                        anchors.centerIn: parent
                        text: modelData.label
                        font.family: "Inter, sans-serif"
                        font.pixelSize: 10
                        font.weight: activeFilter === modelData.id ? Font.Bold : Font.DemiBold
                        color: activeFilter === modelData.id ? "#FFFFFF" : Qt.rgba(1, 1, 1, 0.6)
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
                    color: Qt.rgba(1, 1, 1, 0.25)
                }
            }

            Text {
                anchors.centerIn: parent
                visible: clipListView.count === 0
                text: "No clips found"
                font.family: "Inter, sans-serif"
                font.pixelSize: 12
                color: Qt.rgba(1, 1, 1, 0.4)
            }

            delegate: Rectangle {
                width: clipListView.width
                height: modelData.type === "image" ? 80 : 54
                radius: 12
                color: itemMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)
                border.color: modelData.pinned ? Qt.rgba(255, 200, 100, 0.4) : "transparent"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 10

                    Rectangle {
                        width: modelData.type === "image" ? 64 : 38
                        height: modelData.type === "image" ? 64 : 38
                        radius: 8
                        color: Qt.rgba(0, 0, 0, 0.25)
                        clip: true

                        Image {
                            visible: modelData.type === "image"
                            anchors.fill: parent
                            source: modelData.imgPath ? ("file://" + modelData.imgPath) : ""
                            fillMode: Image.PreserveAspectCrop
                        }

                        Text {
                            visible: modelData.type !== "image"
                            anchors.centerIn: parent
                            text: "\uea6d"
                            font.family: clipTablerFont.name
                            font.pixelSize: 18
                            color: Qt.rgba(1, 1, 1, 0.6)
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            Layout.fillWidth: true
                            text: modelData.type === "image" ? "Image Clip" : (modelData.preview || "")
                            font.family: "Inter, sans-serif"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: "#FFFFFF"
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.WrapAnywhere
                        }

                        Text {
                            text: modelData.timestamp || ""
                            font.family: "Inter, sans-serif"
                            font.pixelSize: 9
                            color: Qt.rgba(1, 1, 1, 0.4)
                        }
                    }

                    RowLayout {
                        spacing: 4

                        Rectangle {
                            width: 26; height: 26; radius: 13
                            color: modelData.pinned ? Qt.rgba(255, 200, 100, 0.25) : (pinMa.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent")

                            Text {
                                anchors.centerIn: parent
                                text: "\ueae2"
                                font.family: clipTablerFont.name
                                font.pixelSize: 14
                                color: modelData.pinned ? "#ffc864" : Qt.rgba(1, 1, 1, 0.6)
                            }

                            MouseArea {
                                id: pinMa
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: togglePin(modelData.id)
                            }

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Rectangle {
                            width: 26; height: 26; radius: 13
                            color: delMa.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.25) : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "\ueb55"
                                font.family: clipTablerFont.name
                                font.pixelSize: 14
                                color: delMa.containsMouse ? "#ff6b6b" : Qt.rgba(1, 1, 1, 0.5)
                            }

                            MouseArea {
                                id: delMa
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: deleteClip(modelData.id)
                            }

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }

                MouseArea {
                    id: itemMa
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: copyClip(modelData.id)
                }

                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
    }

    // Toast
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        height: 28
        width: toastText.implicitWidth + 20
        radius: 14
        color: "#1e1e2e"
        border.color: Qt.rgba(1, 1, 1, 0.2)
        border.width: 1
        opacity: showToast ? 1 : 0
        visible: opacity > 0
        z: 100

        Text {
            id: toastText
            anchors.centerIn: parent
            text: toastMessage
            font.family: "Inter, sans-serif"
            font.pixelSize: 10
            font.weight: Font.DemiBold
            color: "#FFFFFF"
        }

        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}
