import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
import "theme"
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string wallDir: Theme.homeDir + "/.config/cupcake/walls"
    property string currentWall: ""
    property string fitMode: "Fill"
    property bool perMonitor: false
    property bool slideshow: true
    property bool shuffleOrder: true
    property real dimOverlay: 0.2
    property bool blurLockScreen: true
    property string changeInterval: "30 minutes"

    // Read current wallpaper
    Process {
        command: ["bash", "-c", "cat ~/.config/cupcake/.wallpaper 2>/dev/null || echo ''"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.currentWall = text.trim() }
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
        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
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

    component SettingsRow: RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        spacing: 12
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
        anchors.rightMargin: 24
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
                        Image {
                            anchors.fill: parent
                            source: root.currentWall !== "" ? ("file://" + root.currentWall) : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: root.currentWall !== ""
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

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 110
                            radius: 10; clip: true
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.06)
                            border.color: (root.currentWall === filePath) ? Theme.colPrimary : "transparent"
                            border.width: 2
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Image {
                                anchors.fill: parent
                                source: fileUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            Rectangle {
                                visible: root.currentWall === filePath
                                width: 22; height: 22; radius: 11
                                anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 7
                                color: Theme.colPrimary
                                Text { anchors.centerIn: parent; text: "\uea5e"; color: Theme.colSurface; font.family: "tabler-icons"; font.pixelSize: 13 }
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

                            property bool hovered: false
                            scale: hovered ? 1.03 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            MouseArea {
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onEntered: parent.hovered = true
                                onExited: parent.hovered = false
                                onClicked: {
                                    root.currentWall = filePath
                                    Quickshell.execDetached([Theme.homeDir + "/.local/bin/set-theme", filePath])
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
                            onClicked: Quickshell.execDetached(["bash", "-c", "XDG_CURRENT_DESKTOP=gnome zenity --file-selection --file-filter='Images | *.png *.jpg *.jpeg' 2>/dev/null | xargs -I{} cp {} " + root.wallDir + "/"])
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
                            Text { anchors.centerIn: parent; text: "\uea42"; color: Theme.colOnSurfaceVariant; font.family: "tabler-icons"; font.pixelSize: 16 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Fit mode"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "How the image scales to fill your screen"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: ["Fill", "Fit", "Stretch", "Center", "Tile"]
                        current: root.fitMode
                        onSelected: root.fitMode = value
                    }
                }

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
                            Text { text: "Per-monitor wallpapers"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Use a different wallpaper on each display"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch { checked: root.perMonitor; onToggled: root.perMonitor = checked }
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
                            Text { text: "Slideshow"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
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
                            Text { text: "Change every"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
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
                            Text { text: "Shuffle order"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
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
                            Text { text: "Dim overlay"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Darken the wallpaper for better icon contrast"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Slider {
                        id: dimSlider
                        from: 0; to: 1; value: root.dimOverlay
                        implicitWidth: 110; implicitHeight: 22
                        onValueChanged: root.dimOverlay = value
                        background: Rectangle {
                            x: dimSlider.leftPadding; y: dimSlider.topPadding + dimSlider.availableHeight / 2 - height / 2
                            width: dimSlider.availableWidth; height: 4; radius: 2
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                            Rectangle { width: dimSlider.visualPosition * parent.width; height: parent.height; radius: 2; color: Theme.colPrimary }
                        }
                        handle: Rectangle {
                            x: dimSlider.leftPadding + dimSlider.visualPosition * (dimSlider.availableWidth - width)
                            y: dimSlider.topPadding + dimSlider.availableHeight / 2 - height / 2
                            width: 16; height: 16; radius: 8; color: Theme.colPrimary
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
                            Text { text: "Blur on lock screen"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
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
