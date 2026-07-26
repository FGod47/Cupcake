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


    // =====================================================================
    // UI
    // =====================================================================

    ScrollView {
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        anchors.fill: parent
        anchors.bottomMargin: 28
        leftPadding: 32
        rightPadding: 32
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 20

            // ── Current wallpaper card ─────────────────────────────────────
            NCard {
                sectionTitle: "Current wallpaper"

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    Layout.bottomMargin: 16
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
            NCard {
                sectionTitle: "Wallpaper library"

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

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea7c" }
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
            NCard {
                sectionTitle: "Fit & display"


                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uead6" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Per-monitor wallpapers"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Use a different wallpaper on each display"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: root.perMonitor; onToggled: root.perMonitor = checked }
                }

                NRow {
                    visible: root.perMonitor
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea4e" }
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
            NCard {
                sectionTitle: "Slideshow"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb37" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Slideshow"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Automatically cycle through your wallpaper library"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: root.slideshow; onToggled: root.slideshow = checked }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea24" }
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

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb4c" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Shuffle order"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Play wallpapers in a random order"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: root.shuffleOrder; onToggled: root.shuffleOrder = checked }
                }
            }

            // ── Effects ────────────────────────────────────────────────────
            NCard {
                sectionTitle: "Effects"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb79" }
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
                    
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb04" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Blur on lock screen"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Apply a blur effect while the screen is locked"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
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
