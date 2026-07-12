import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import "../../theme"
import Quickshell
import Quickshell.Io
import "../common"

Item {
    id: root

    property string wallDir: Theme.homeDir + "/.config/cupcake/walls"
    property string currentWall: ""
    property string fitMode: "Fill"
    property bool perMonitor: false
    property string selectedMonitor: "Global"
    property bool slideshow: true
    property bool shuffleOrder: true
    property real dimOverlay: 0.2
    property bool blurLockScreen: true
    property string changeInterval: "30 minutes"

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.dim_overlay"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { let v = parseFloat(text.trim()); if (!isNaN(v)) root.dimOverlay = v; }
            }
        }
    }

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.blur_lockscreen"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { root.blurLockScreen = (text.trim() === "true"); }
            }
        }
    }

    // Read current wallpaper from the cache file (set-theme writes here)
    Process {
        id: wallProcess
        command: ["bash", "-c", "cat ~/.cache/current_wallpaper 2>/dev/null || echo ''"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let p = text.trim();
                if (p !== "") root.currentWall = p;
            }
        }
    }

    // Refresh wallpaper path every 10s (only if process isn't already running)
    Timer {
        interval: 10000
        repeat: true
        running: true
        onTriggered: {
            if (!wallProcess.running) wallProcess.running = true;
        }
    }

    // =====================================================================
    // Inline components
    // =====================================================================

    component SettingsCard: Rectangle {
        default property alias content: innerCol.data
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        implicitHeight: innerCol.implicitHeight + 40
        Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        color: Theme.showCardBackground ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03) : "transparent"
        radius: 12
        clip: true
        ColumnLayout {
            id: innerCol
            anchors.fill: parent
            anchors.margins: 20
            spacing: 8
        }
    }

    component SectionLabel: Text {
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 0.4
        color: Theme.colOnSurface
        opacity: 0.45
    }

    component ToggleSwitch: Rectangle {
        id: sw
        property bool checked: false
        signal toggled(bool checked)
        width: 38; height: 22
        radius: height / 2
        color: checked ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.15)
        border.width: checked ? 0 : 1
        border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.1)
        Behavior on color { ColorAnimation { duration: 120 } }
        Rectangle {
            width: 18; height: 18; radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: sw.checked ? parent.width - width - 2 : 2
            color: sw.checked ? Theme.colSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.8)
            Behavior on x { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: { sw.checked = !sw.checked; sw.toggled(sw.checked) }
        }
    }

    component SettingsRow: ColumnLayout {
        default property alias content: innerRow.data
        Layout.fillWidth: true
        Layout.topMargin: Theme.rowSpacing
        Layout.bottomMargin: Theme.rowSpacing
        spacing: 12
        RowLayout {
            id: innerRow
            Layout.fillWidth: true
            spacing: 12
        }
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
            visible: Theme.showDividers
        }
    }

    component SegmentedControl: Rectangle {
        id: seg
        property var options: []
        property string current: options.length > 0 ? options[0] : ""
        signal selected(string value)
        color: Qt.rgba(0, 0, 0, 0.28)
        radius: 8; height: 30
        width: segRow.implicitWidth + 4
        Row {
            id: segRow
            anchors.centerIn: parent
            spacing: 1
            Repeater {
                model: seg.options
                delegate: Rectangle {
                    required property string modelData
                    property bool active: modelData === seg.current
                    height: 26; width: segLabel.implicitWidth + 24; radius: 6
                    color: active ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.92) : "transparent"
                    Text {
                        id: segLabel
                        anchors.centerIn: parent; text: modelData
                        font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.Medium
                        color: active ? Theme.colSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.5)
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { seg.current = modelData; seg.selected(modelData) } }
                }
            }
        }
    }

    // =====================================================================
    // UI
    // =====================================================================

    ScrollView {
        anchors.fill: parent
        anchors.topMargin: 0
        anchors.bottomMargin: 30
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 24

            // ── Current wallpaper card ─────────────────────────────────────
            SettingsCard {
                SectionLabel { text: "Current wallpaper" }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 20

                    Rectangle {
                        width: 180; height: 120; radius: 10
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.06)
                        clip: true
                        Rectangle {
                            id: previewMask
                            anchors.fill: parent
                            radius: 10
                            visible: false
                        }
                        Image {
                            id: previewImg
                            anchors.fill: parent
                            source: {
                                if (root.currentWall === "") return "";
                                var parts = root.currentWall.split("/");
                                var filename = parts[parts.length - 1];
                                return "file://" + Theme.homeDir + "/.cache/cupcake/wall_thumbs/" + filename;
                            }
                            sourceSize: Qt.size(360, 240)
                            fillMode: Image.PreserveAspectCrop
                            visible: root.currentWall !== ""
                            asynchronous: true
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: previewMask
                            }
                            onStatusChanged: {
                                if (status === Image.Error && root.currentWall !== "" && source.toString() !== ("file://" + root.currentWall)) {
                                    source = "file://" + root.currentWall
                                }
                            }
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: root.currentWall === ""
                            text: "\ueb0a"; font.family: "tabler-icons"; font.pixelSize: 32
                            color: Theme.colOnSurfaceVariant; opacity: 0.3
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: root.currentWall !== "" ? root.currentWall.split("/").pop().replace(/\.[^.]+$/, "") : "No wallpaper"
                            color: Theme.colOnSurface; font.family: Theme.monoFontFamily
                            font.pixelSize: 16; font.weight: Font.Bold
                            elide: Text.ElideRight; Layout.fillWidth: true
                        }
                        Text {
                            text: "Applied to Built-in Display"
                            color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily
                            font.pixelSize: 12; opacity: 0.8
                        }

                        RowLayout {
                            spacing: 20
                            Layout.topMargin: 4

                            Rectangle {
                                color: "transparent"
                                implicitWidth: browseRow.implicitWidth
                                implicitHeight: browseRow.implicitHeight
                                RowLayout { id: browseRow; spacing: 6
                                    Text { text: "\uea7b"; color: Theme.colPrimary; font.family: "tabler-icons"; font.pixelSize: 15 }
                                    Text { text: "Browse files"; color: Theme.colPrimary; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached(["bash", "-c", "XDG_CURRENT_DESKTOP=gnome zenity --file-selection --file-filter='Images | *.png *.jpg *.jpeg *.webp' 2>/dev/null | xargs -I{} " + Theme.homeDir + "/.local/bin/set-theme {}"])
                                }
                            }

                            Rectangle {
                                color: "transparent"
                                implicitWidth: shuffleRow.implicitWidth
                                implicitHeight: shuffleRow.implicitHeight
                                RowLayout { id: shuffleRow; spacing: 6
                                    Text { text: "\ueb4c"; color: Theme.colPrimary; font.family: "tabler-icons"; font.pixelSize: 15 }
                                    Text { text: "Shuffle now"; color: Theme.colPrimary; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached(["bash", "-c", "ls " + root.wallDir + "/*.{png,jpg,jpeg} 2>/dev/null | shuf -n1 | xargs " + Theme.homeDir + "/.local/bin/set-theme"])
                                }
                            }
                        }
                    }
                }
            }

            // ── Wallpaper library ──────────────────────────────────────────
            SettingsCard {
                SectionLabel { text: "Wallpaper library" }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    columnSpacing: 10
                    rowSpacing: 10

                    Repeater {
                        model: FolderListModel {
                            folder: "file://" + root.wallDir
                            nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
                            showDirs: false
                        }

                        delegate: Loader {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 110
                            asynchronous: true
                            
                            sourceComponent: Component {
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 10; clip: true
                                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.06)
                                    border.color: (root.currentWall === filePath) ? Theme.colPrimary : "transparent"
                                    border.width: 2
                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                    Rectangle {
                                        id: tileMask
                                        anchors.fill: parent
                                        radius: 9
                                        visible: false
                                        layer.enabled: true
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "\ueb0a" // tabler-icons 'photo'
                                        font.family: "tabler-icons"
                                        font.pixelSize: 24
                                        color: Theme.colOnSurfaceVariant
                                        opacity: 0.2
                                    }



                                    Item {
                                        anchors.fill: parent
                                        layer.enabled: true
                                        layer.effect: OpacityMask {
                                            maskSource: tileMask
                                        }

                                        Image {
                                            id: img
                                            anchors.fill: parent
                                            source: "file://" + Theme.homeDir + "/.cache/cupcake/wall_thumbs/" + fileName
                                            sourceSize: Qt.size(250, 150)
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                            opacity: status === Image.Ready ? 1 : 0
                                            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                            onStatusChanged: {
                                                if (status === Image.Error && source.toString() !== fileUrl.toString()) {
                                                    source = fileUrl
                                                }
                                            }
                                        }

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.left: parent.left; anchors.right: parent.right
                                            height: 36
                                            gradient: Gradient {
                                                orientation: Gradient.Vertical
                                                GradientStop { position: 0.0; color: "transparent" }
                                                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
                                            }
                                            Text {
                                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 8 }
                                                text: fileName.replace(/\.[^.]+$/, "")
                                                color: "white"; font.family: Theme.defaultFontFamily
                                                font.pixelSize: 11; font.weight: Font.Medium; elide: Text.ElideRight
                                            }
                                        }
                                    }

                                    Rectangle {
                                        visible: root.currentWall === filePath
                                        width: 22; height: 22; radius: 11
                                        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 7
                                        color: Theme.colPrimary
                                        Text { anchors.centerIn: parent; text: "\uea5e"; color: Theme.colSurface; font.family: "tabler-icons"; font.pixelSize: 13 }
                                    }

                                    Rectangle {
                                        z: 1
                                        width: 28; height: 28; radius: 14
                                        anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 7
                                        color: Qt.rgba(0, 0, 0, 0.65)
                                        opacity: parent.hovered ? 1 : 0
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                        Text { anchors.centerIn: parent; text: "\ueb41"; color: "white"; font.family: "tabler-icons"; font.pixelSize: 14 }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Quickshell.execDetached(["bash", "-c", "rm '" + filePath + "' && rm -f '" + Theme.homeDir + "/.cache/cupcake/wall_thumbs/" + fileName + "'"])
                                            }
                                        }
                                    }

                                    property bool hovered: false
                                    scale: hovered ? 1.03 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                    MouseArea {
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onEntered: parent.hovered = true
                                        onExited: parent.hovered = false
                                        onClicked: {
                                            root.currentWall = filePath
                                            if (root.perMonitor && root.selectedMonitor !== "Global") {
                                                Quickshell.execDetached(["awww", "img", "-o", root.selectedMonitor, filePath])
                                            } else {
                                                Quickshell.execDetached([Theme.homeDir + "/.local/bin/set-theme", filePath])
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Add button
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 110
                        radius: 10; color: "transparent"
                        border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.15)
                        border.width: 2; opacity: 0.6
                        Text {
                            anchors.centerIn: parent
                            text: "\uea13"; color: Theme.colOnSurfaceVariant
                            font.family: "tabler-icons"; font.pixelSize: 24
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(["bash", "-c", "XDG_CURRENT_DESKTOP=gnome zenity --file-selection --file-filter='Images | *.png *.jpg *.jpeg' 2>/dev/null | xargs -I{} bash -c 'cp \"{}\" " + root.wallDir + "/ && ~/.local/bin/cupcake-generate-thumbnails'"])
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\uea7c"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Wallpaper directory"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Location where your wallpaper images are stored"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        radius: 6
                        color: Qt.rgba(0,0,0,0.25)
                        implicitWidth: pathText.implicitWidth + 16
                        implicitHeight: 22
                        Text {
                            id: pathText
                            anchors.centerIn: parent
                            text: root.wallDir
                            font.family: "monospace"
                            font.pixelSize: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.55)
                            elide: Text.ElideMiddle
                        }
                    }
                }
            }

            // ── Fit & display ──────────────────────────────────────────────
            SettingsCard {
                SectionLabel { text: "Fit & display" }


                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\uead6"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Per-monitor wallpapers"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Use a different wallpaper on each display"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch { checked: root.perMonitor; onToggled: root.perMonitor = checked }
                }

                SettingsRow {
                    visible: root.perMonitor
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\uea4e"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Select Display"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Choose which monitor to set the wallpaper for"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    
                    Rectangle {
                        color: Qt.rgba(0, 0, 0, 0.28)
                        radius: 8
                        implicitHeight: 30
                        implicitWidth: rowContainer.implicitWidth + 4

                        Row {
                            id: rowContainer
                            anchors.centerIn: parent
                            spacing: 1
                            
                            Rectangle {
                                width: labelGlobal.implicitWidth + 24; height: 26; radius: 6
                                color: root.selectedMonitor === "Global" ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.92) : "transparent"
                                Text {
                                    id: labelGlobal; anchors.centerIn: parent; text: "Global"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.Medium
                                    color: root.selectedMonitor === "Global" ? Theme.colSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.7)
                                }
                                MouseArea { anchors.fill: parent; onClicked: root.selectedMonitor = "Global" }
                            }
                            
                            Repeater {
                                model: Quickshell.screens
                                delegate: Rectangle {
                                    width: labelScreen.implicitWidth + 24; height: 26; radius: 6
                                    color: root.selectedMonitor === modelData.name ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.92) : "transparent"
                                    Text {
                                        id: labelScreen; anchors.centerIn: parent; text: modelData.name; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.Medium
                                        color: root.selectedMonitor === modelData.name ? Theme.colSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.7)
                                    }
                                    MouseArea { anchors.fill: parent; onClicked: root.selectedMonitor = modelData.name }
                                }
                            }
                        }
                    }
                }
            }

            // ── Slideshow ──────────────────────────────────────────────────
            SettingsCard {
                SectionLabel { text: "Slideshow" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\ueb37"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Slideshow"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Automatically cycle through your wallpaper library"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch { checked: root.slideshow; onToggled: root.slideshow = checked }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\uea24"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Change every"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "How often the wallpaper changes"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    ComboBox {
                        id: intervalCombo
                        model: ["5 minutes", "15 minutes", "30 minutes", "1 hour", "3 hours", "Daily"]
                        currentIndex: 2
                        implicitWidth: 140; implicitHeight: 32
                        indicator: Text { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: "\uea5f"; font.family: "tabler-icons"; font.pixelSize: 13; color: Theme.colOnSurfaceVariant }
                        background: Rectangle { color: Qt.rgba(0,0,0,0.28); radius: 8 }
                        contentItem: Text { leftPadding: 12; text: intervalCombo.displayText; font.family: Theme.defaultFontFamily; font.pixelSize: 12; color: Theme.colOnSurface; verticalAlignment: Text.AlignVCenter }
                        popup: Popup {
                            y: intervalCombo.height + 4; width: intervalCombo.width; padding: 4
                            implicitHeight: lvInterval.contentHeight + 8
                            contentItem: ListView { id: lvInterval; clip: true; implicitHeight: Math.min(contentHeight, 200); model: intervalCombo.delegateModel; currentIndex: intervalCombo.highlightedIndex }
                            background: Rectangle { color: Theme.colSurfaceContainerHigh; border.color: Theme.colOutline; border.width: 1; radius: 8 }
                        }
                        delegate: ItemDelegate {
                            width: intervalCombo.width - 8; height: 34
                            highlighted: intervalCombo.highlightedIndex === index
                            background: Rectangle { color: highlighted ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.15) : "transparent"; radius: 6 }
                            contentItem: Text { text: modelData; font.family: Theme.defaultFontFamily; font.pixelSize: 12; color: Theme.colOnSurface; verticalAlignment: Text.AlignVCenter; leftPadding: 8 }
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\ueb4c"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Shuffle order"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Play wallpapers in a random order"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch { checked: root.shuffleOrder; onToggled: root.shuffleOrder = checked }
                }
            }

            // ── Effects ────────────────────────────────────────────────────
            SettingsCard {
                SectionLabel { text: "Effects" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\ueb79"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Dim overlay"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Darken the wallpaper for better icon contrast"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledSlider {
                        id: dimSlider
                        from: 0; to: 1; value: root.dimOverlay
                        implicitWidth: 110
                        
                        Timer {
                            id: dimDebounce
                            interval: 50
                            property real pendingValue: 0
                            onTriggered: {
                                Quickshell.execDetached(["quickshell", "ipc", "call", "wallpaper", "setDimOverlay", pendingValue.toString()]);
                            }
                        }

                        onValueChanged: {
                            root.dimOverlay = value;
                            dimDebounce.pendingValue = value;
                            dimDebounce.restart();
                        }
                        onPressedChanged: {
                            if (!pressed) {
                                dimDebounce.stop();
                                Quickshell.execDetached(["bash", "-c", "echo '" + value.toFixed(2) + "' > ~/.config/cupcake/.dim_overlay"]);
                                Quickshell.execDetached(["quickshell", "ipc", "call", "wallpaper", "setDimOverlay", value.toString()]);
                            }
                        }
                    }
                    Text {
                        text: Math.round(root.dimOverlay * 100) + "%"
                        color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 12
                        Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text { anchors.centerIn: parent; text: "\ueb04"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Blur on lock screen"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Apply a blur effect while the screen is locked"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch {
                        checked: root.blurLockScreen
                        onToggled: {
                            root.blurLockScreen = checked
                            Quickshell.execDetached(["bash", "-c", "echo " + (checked ? "true" : "false") + " > ~/.config/cupcake/.blur_lockscreen"])
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 32 }
        }
    }
}
