//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "theme"
import "modules/common"

Window {
    id: shortcutsWindow
    visible: true
    width: 1040
    height: 820
    minimumWidth: 880
    minimumHeight: 650
    title: "Cupcake • Shortcuts"
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint

    readonly property color fg: Theme.colOnSurface
    property real bgOpacity: 0.85
    property int hyprRounding: 12
    property var categoriesData: []
    property var fixedData: []
    property string activeRecordingId: ""
    property string toastMessage: ""

    Process {
        id: initRounding
        command: ["bash", "-c", "hyprctl getoption decoration:rounding -j 2>/dev/null | grep -o '\"int\": [0-9]*' | grep -o '[0-9]*'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let v = parseInt(text.trim());
                if (!isNaN(v) && v >= 0) shortcutsWindow.hyprRounding = v;
            }
        }
    }

    Process {
        id: fetchShortcutsProc
        command: ["python3", Quickshell.env("HOME") + "/.config/cupcake/scripts/keybindings_manager.py", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                try {
                    let parsed = JSON.parse(text);
                    if (parsed.categories) shortcutsWindow.categoriesData = parsed.categories;
                    if (parsed.fixed) shortcutsWindow.fixedData = parsed.fixed;
                } catch(e) {
                    console.log("Error parsing shortcuts JSON:", e);
                }
            }
        }
    }

    Process {
        id: saveShortcutsProc
        property string payload: "{}"
        command: ["python3", Quickshell.env("HOME") + "/.config/cupcake/scripts/keybindings_manager.py", "save", saveShortcutsProc.payload]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                showToast("Shortcuts applied & Hyprland reloaded!");
                fetchShortcutsProc.running = true;
            }
        }
    }

    Process {
        id: resetShortcutsProc
        command: ["python3", Quickshell.env("HOME") + "/.config/cupcake/scripts/keybindings_manager.py", "reset"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                showToast("Shortcuts reset to defaults!");
                fetchShortcutsProc.running = true;
            }
        }
    }

    function showToast(msg) {
        toastMessage = msg;
        toastTimer.restart();
    }

    Timer {
        id: toastTimer
        interval: 2600
        onTriggered: shortcutsWindow.toastMessage = ""
    }

    function applyChanges() {
        activeRecordingId = "";
        saveShortcutsProc.payload = JSON.stringify({ categories: categoriesData });
        saveShortcutsProc.running = true;
    }

    function resetDefaults() {
        activeRecordingId = "";
        resetShortcutsProc.running = true;
    }

    function updateItemKey(itemId, newKey) {
        let cats = JSON.parse(JSON.stringify(categoriesData));
        for (let i = 0; i < cats.length; i++) {
            let cat = cats[i];
            for (let j = 0; j < cat.items.length; j++) {
                if (cat.items[j].id === itemId) {
                    cat.items[j].key = newKey;
                    break;
                }
            }
        }
        categoriesData = cats;
    }

    function removeItemKey(itemId) {
        updateItemKey(itemId, "NONE");
    }

    // Main Card Container
    Rectangle {
        id: windowBg
        anchors.fill: parent
        radius: shortcutsWindow.hyprRounding
        color: Qt.rgba(Theme.colSurfaceContainer.r, Theme.colSurfaceContainer.g, Theme.colSurfaceContainer.b, shortcutsWindow.bgOpacity)
        border.width: 1
        border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.25)
        clip: true

        // Window Draggable Header Area
        MouseArea {
            anchors.fill: parent
            z: -1
            property point clickPos: "0,0"
            onPressed: (mouse) => { clickPos = Qt.point(mouse.x, mouse.y); }
            onPositionChanged: (mouse) => {
                let delta = Qt.point(mouse.x - clickPos.x, mouse.y - clickPos.y);
                shortcutsWindow.x += delta.x;
                shortcutsWindow.y += delta.y;
            }
        }

        // Header Top Bar
        RowLayout {
            id: topHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 24
            anchors.leftMargin: 32
            anchors.rightMargin: 32
            height: 48
            spacing: 16

            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true

                RowLayout {
                    spacing: 8
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                    Image {
                        id: headerLogo
                        source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/cupcake-word-" + (Theme.isDark ? "light" : "dark") + ".svg"
                        sourceSize.height: 20
                        height: 20
                        width: Math.round(62 * (height / 20))
                        fillMode: Image.PreserveAspectFit
                        Layout.alignment: Qt.AlignVCenter
                        layer.enabled: true
                        layer.effect: ColorOverlay { color: shortcutsWindow.fg }
                    }

                    Text {
                        text: "•  Shortcuts"
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                        color: shortcutsWindow.fg
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                Text {
                    text: "Click a shortcut to change it. ✕ removes it."
                    font.family: Theme.appFontMono
                    font.pixelSize: 12
                    color: Qt.rgba(shortcutsWindow.fg.r, shortcutsWindow.fg.g, shortcutsWindow.fg.b, 0.5)
                }
            }

            // Action Buttons
            Row {
                spacing: 10
                Layout.alignment: Qt.AlignVCenter

                // Apply Button
                Rectangle {
                    width: 82
                    height: 32
                    radius: 8
                    color: applyMa.containsMouse ? "#27AE60" : "#2ECC71"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Apply"
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: "#0E1A13"
                    }

                    MouseArea {
                        id: applyMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: shortcutsWindow.applyChanges()
                    }
                }

                // Reset Button
                Rectangle {
                    width: 76
                    height: 32
                    radius: 8
                    color: resetMa.containsMouse ? Qt.rgba(shortcutsWindow.fg.r, shortcutsWindow.fg.g, shortcutsWindow.fg.b, 0.16) : Qt.rgba(shortcutsWindow.fg.r, shortcutsWindow.fg.g, shortcutsWindow.fg.b, 0.08)
                    border.width: 1
                    border.color: Qt.rgba(shortcutsWindow.fg.r, shortcutsWindow.fg.g, shortcutsWindow.fg.b, 0.12)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Reset"
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: shortcutsWindow.fg
                    }

                    MouseArea {
                        id: resetMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: shortcutsWindow.resetDefaults()
                    }
                }

                // Close Button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 8
                    color: closeMa.containsMouse ? Qt.rgba(Theme.colError.r, Theme.colError.g, Theme.colError.b, 0.25) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "\ueb55"
                        font.family: "tabler-icons"
                        font.pixelSize: 14
                        color: closeMa.containsMouse ? Theme.colError : Qt.rgba(shortcutsWindow.fg.r, shortcutsWindow.fg.g, shortcutsWindow.fg.b, 0.6)
                    }

                    MouseArea {
                        id: closeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: shortcutsWindow.close()
                    }
                }
            }
        }

        // Two Column Shortcuts Body
        Flickable {
            id: mainScroll
            anchors.top: topHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: 20
            anchors.leftMargin: 32
            anchors.rightMargin: 32
            anchors.bottomMargin: 24
            contentWidth: width
            contentHeight: contentRow.implicitHeight + 20
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            RowLayout {
                id: contentRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 36

                // LEFT COLUMN (PILL & APPLICATIONS)
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 24

                    Repeater {
                        model: shortcutsWindow.categoriesData.filter((c, idx) => idx === 0 || idx === 1)
                        delegate: ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: modelData.category
                                font.family: Theme.appFontMono
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                font.letterSpacing: 1.5
                                color: Qt.rgba(shortcutsWindow.fg.r, shortcutsWindow.fg.g, shortcutsWindow.fg.b, 0.45)
                                Layout.leftMargin: 2
                            }

                            Repeater {
                                model: modelData.items
                                delegate: Item {
                                    id: shortcutRowItem
                                    required property var modelData
                                    Layout.fillWidth: true
                                    height: 38

                                    readonly property bool isRecording: shortcutsWindow.activeRecordingId === modelData.id
                                    readonly property string keyDisplay: modelData.key && modelData.key.toUpperCase() !== "NONE" ? modelData.key.toUpperCase() : "NONE"

                                    // Key Shortcut Pill Button
                                    Rectangle {
                                        id: keyPill
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 148
                                        height: 32
                                        radius: 10
                                        color: shortcutRowItem.isRecording
                                               ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.25)
                                               : (pillMa.containsMouse ? Qt.rgba(shortcutsWindow.fg.r, shortcutsWindow.fg.g, shortcutsWindow.fg.b, 0.12) : Qt.rgba(shortcutsWindow.fg.r, shortcutsWindow.fg.g, shortcutsWindow.fg.b, 0.06))
                                        border.width: 1
                                        border.color: shortcutRowItem.isRecording
                                                      ? Theme.colPrimary
                                                      : (pillMa.containsMouse ? Qt.rgba(shortcutsWindow.fg.r, shortcutsWindow.fg.g, shortcutsWindow.fg.b, 0.25) : "transparent")
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Behavior on border.color { ColorAnimation { duration: 150 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: shortcutRowItem.isRecording ? "RECORDING..." : shortcutRowItem.keyDisplay
                                            font.family: Theme.appFontMono
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                            font.letterSpacing: 0.5
                                            color: shortcutRowItem.isRecording ? Theme.colPrimary : (shortcutRowItem.keyDisplay === "NONE" ? Qt.rgba(shortcutsWindow.fg.r, shortcutsWindow.fg.g, shortcutsWindow.fg.b, 0.35) : shortcutsWindow.fg)
                                            elide: Text.ElideRight
                                            width: parent.width - 12
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        MouseArea {
                                            id: pillMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (shortcutRowItem.isRecording) {
                                                    shortcutsWindow.activeRecordingId = "";
                                                } else {
                                                    shortcutsWindow.activeRecordingId = modelData.id;
                                                    keyInputGrabber.forceActiveFocus();
                                                }
                                            }
                                        }
                                    }

                                    // Action Label
                                    Text {
                                        anchors.left: keyPill.right
                                        anchors.leftMargin: 16
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.label
                                        font.family: Theme.defaultFontFamily
                                        font.pixelSize: 13
                                        font.weight: Font.Normal
                                        color: Qt.rgba(shortcutsWindow.fg.r, shortcutsWindow.fg.g, shortcutsWindow.fg.b, 0.8)
                                    }

                                    // Remove 'x' Button
                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 22
                                        height: 22
                                        radius: 6
                                        color: delMa.containsMouse ? Qt.rgba(Theme.colError.r, Theme.colError.g, Theme.colError.b, 0.20) : "transparent"
                                        visible: modelData.key && modelData.key.toUpperCase() !== "NONE"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "\ueb55"
                                            font.family: "tabler-icons"
                                            font.pixelSize: 11
                                            color: delMa.containsMouse ? Theme.colError : Qt.rgba(shortcutsWindow.fg.r, shortcutsWindow.fg.g, shortcutsWindow.fg.b, 0.35)
                                        }

                                        MouseArea {
                                            id: delMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: shortcutsWindow.removeItemKey(modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // RIGHT COLUMN (WINDOWS, WORKSPACES & FIXED)
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 24

                    Repeater {
                        model: shortcutsWindow.categoriesData.filter((c, idx) => idx >= 2)
                        delegate: ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: modelData.category
                                font.family: Theme.appFontMono
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                font.letterSpacing: 1.5
                                color: Qt.rgba(shortcutsWindow.fg.r, shortcutsWindow.fg.g, shortcutsWindow.fg.b, 0.45)
                                Layout.leftMargin: 2
                            }

                            Repeater {
                                model: modelData.items
                                delegate: Item {
                                    id: rightShortcutRowItem
                                    required property var modelData
                                    Layout.fillWidth: true
                                    height: 38

                                    readonly property bool isRecording: shortcutsWindow.activeRecordingId === modelData.id
                                    readonly property string keyDisplay: modelData.key && modelData.key.toUpperCase() !== "NONE" ? modelData.key.toUpperCase() : "NONE"

                                    // Key Shortcut Pill Button
                                    Rectangle {
                                        id: rightKeyPill
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 148
                                        height: 32
                                        radius: 10
                                        color: rightShortcutRowItem.isRecording
                                               ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.25)
                                               : (rightPillMa.containsMouse ? Qt.rgba(shortcutsWindow.fg.r, shortcutsWindow.fg.g, shortcutsWindow.fg.b, 0.12) : Qt.rgba(shortcutsWindow.fg.r, shortcutsWindow.fg.g, shortcutsWindow.fg.b, 0.06))
                                        border.width: 1
                                        border.color: rightShortcutRowItem.isRecording
                                                      ? Theme.colPrimary
                                                      : (rightPillMa.containsMouse ? Qt.rgba(shortcutsWindow.fg.r, shortcutsWindow.fg.g, shortcutsWindow.fg.b, 0.25) : "transparent")
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Behavior on border.color { ColorAnimation { duration: 150 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: rightShortcutRowItem.isRecording ? "RECORDING..." : rightShortcutRowItem.keyDisplay
                                            font.family: Theme.appFontMono
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                            font.letterSpacing: 0.5
                                            color: rightShortcutRowItem.isRecording ? Theme.colPrimary : (rightShortcutRowItem.keyDisplay === "NONE" ? Qt.rgba(shortcutsWindow.fg.r, shortcutsWindow.fg.g, shortcutsWindow.fg.b, 0.35) : shortcutsWindow.fg)
                                            elide: Text.ElideRight
                                            width: parent.width - 12
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        MouseArea {
                                            id: rightPillMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (rightShortcutRowItem.isRecording) {
                                                    shortcutsWindow.activeRecordingId = "";
                                                } else {
                                                    shortcutsWindow.activeRecordingId = modelData.id;
                                                    keyInputGrabber.forceActiveFocus();
                                                }
                                            }
                                        }
                                    }

                                    // Action Label
                                    Text {
                                        anchors.left: rightKeyPill.right
                                        anchors.leftMargin: 16
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.label
                                        font.family: Theme.defaultFontFamily
                                        font.pixelSize: 13
                                        font.weight: Font.Normal
                                        color: Qt.rgba(shortcutsWindow.fg.r, shortcutsWindow.fg.g, shortcutsWindow.fg.b, 0.8)
                                    }

                                    // Remove 'x' Button
                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 22
                                        height: 22
                                        radius: 6
                                        color: rightDelMa.containsMouse ? Qt.rgba(Theme.colError.r, Theme.colError.g, Theme.colError.b, 0.20) : "transparent"
                                        visible: modelData.key && modelData.key.toUpperCase() !== "NONE"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "\ueb55"
                                            font.family: "tabler-icons"
                                            font.pixelSize: 11
                                            color: rightDelMa.containsMouse ? Theme.colError : Qt.rgba(shortcutsWindow.fg.r, shortcutsWindow.fg.g, shortcutsWindow.fg.b, 0.35)
                                        }

                                        MouseArea {
                                            id: rightDelMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: shortcutsWindow.removeItemKey(modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // FIXED SYSTEM SHORTCUTS SECTION
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        visible: shortcutsWindow.fixedData.length > 0

                        Text {
                            text: "FIXED"
                            font.family: Theme.appFontMono
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            font.letterSpacing: 1.5
                            color: Qt.rgba(shortcutsWindow.fg.r, shortcutsWindow.fg.g, shortcutsWindow.fg.b, 0.45)
                            Layout.leftMargin: 2
                        }

                        Repeater {
                            model: shortcutsWindow.fixedData
                            delegate: Item {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 26

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 136
                                    text: modelData.key
                                    font.family: Theme.appFontMono
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: Qt.rgba(shortcutsWindow.fg.r, shortcutsWindow.fg.g, shortcutsWindow.fg.b, 0.5)
                                    horizontalAlignment: Text.AlignRight
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 164
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 12
                                    color: Qt.rgba(shortcutsWindow.fg.r, shortcutsWindow.fg.g, shortcutsWindow.fg.b, 0.55)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Global Key Press Grabber for Reprogramming
        Item {
            id: keyInputGrabber
            anchors.fill: parent
            focus: shortcutsWindow.activeRecordingId !== ""
            visible: shortcutsWindow.activeRecordingId !== ""

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    shortcutsWindow.activeRecordingId = "";
                    event.accepted = true;
                    return;
                }

                // Build modifier keys
                let parts = [];
                let isSuper = (event.modifiers & Qt.MetaModifier) || event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R;
                let isCtrl = (event.modifiers & Qt.ControlModifier) || event.key === Qt.Key_Control;
                let isAlt = (event.modifiers & Qt.AltModifier) || event.key === Qt.Key_Alt;
                let isShift = (event.modifiers & Qt.ShiftModifier) || event.key === Qt.Key_Shift;

                if (isSuper) parts.push("SUPER");
                if (isCtrl) parts.push("CTRL");
                if (isAlt) parts.push("ALT");
                if (isShift) parts.push("SHIFT");

                // Get key name
                let keyName = "";
                if (event.key >= Qt.Key_A && event.key <= Qt.Key_Z) {
                    keyName = String.fromCharCode(event.key);
                } else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                    keyName = String.fromCharCode(event.key);
                } else if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F12) {
                    keyName = "F" + (event.key - Qt.Key_F1 + 1);
                } else {
                    switch (event.key) {
                        case Qt.Key_Space: keyName = "space"; break;
                        case Qt.Key_Return: case Qt.Key_Enter: keyName = "Return"; break;
                        case Qt.Key_Tab: keyName = "tab"; break;
                        case Qt.Key_Slash: keyName = "slash"; break;
                        case Qt.Key_Print: keyName = "Print"; break;
                        case Qt.Key_Delete: keyName = "Delete"; break;
                        case Qt.Key_Backspace: keyName = "BackSpace"; break;
                        case Qt.Key_Left: keyName = "left"; break;
                        case Qt.Key_Right: keyName = "right"; break;
                        case Qt.Key_Up: keyName = "up"; break;
                        case Qt.Key_Down: keyName = "down"; break;
                        default: break;
                    }
                }

                // If only a modifier was pressed, wait for the main key
                if (!keyName) {
                    event.accepted = true;
                    return;
                }

                parts.push(keyName);
                let finalCombo = parts.join(" + ");

                shortcutsWindow.updateItemKey(shortcutsWindow.activeRecordingId, finalCombo);
                shortcutsWindow.activeRecordingId = "";
                event.accepted = true;
            }
        }

        // Floating Toast Notification
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 28
            width: toastText.implicitWidth + 36
            height: 38
            radius: 19
            color: Qt.rgba(0, 0, 0, 0.85)
            border.width: 1
            border.color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.4)
            visible: opacity > 0.01
            opacity: shortcutsWindow.toastMessage !== "" ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 250 } }

            Row {
                anchors.centerIn: parent
                spacing: 8
                Text {
                    text: "\ueab5"
                    font.family: "tabler-icons"
                    font.pixelSize: 14
                    color: Theme.colPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    id: toastText
                    text: shortcutsWindow.toastMessage
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: shortcutsWindow.fg
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
