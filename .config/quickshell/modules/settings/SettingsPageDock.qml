import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import Quickshell
import Quickshell.Io
import "../common"

Item {
    id: root
    Process { id: bashProcess }

    Timer {
        id: shapeDebounce
        interval: 200
        repeat: false
        onTriggered: {
            bashProcess.command = ["bash", "-c", "echo '" + root.cornerRadius + "' > ~/.config/cupcake/.dock_shape && quickshell ipc -p ~/.config/quickshell/shell.qml call dock setDockShape " + root.cornerRadius];
            bashProcess.running = true;
        }
    }

    Process {
        id: initSettings
        command: ["bash", "-c", "cat ~/.config/cupcake/.dock_monitors 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_autohide 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_reserve_space 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_launcher_position 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_show_dots 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_magnification_enabled 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_magnification_scale 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_shape 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_pinned_apps_enabled 2>/dev/null; echo '---'; cat ~/.config/cupcake/.dock_pinned_apps 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    let parts = text.trim().split('---');
                    if (parts[0]) root.dockEnabled = (parts[0].trim() !== "none");
                    if (parts[1]) root.autoHide = (parts[1].trim() === "true");
                    if (parts[2]) root.reserveSpace = (parts[2].trim() === "true");
                    if (parts[3] && parts[3].trim() !== "") root.launcherPosition = parts[3].trim();
                    if (parts[4] && parts[4].trim() !== "") root.showDots = (parts[4].trim() === "true");
                    if (parts[5] && parts[5].trim() !== "") root.magnificationEnabled = (parts[5].trim() === "true");
                    if (parts[6] && parts[6].trim() !== "") root.magnificationScale = parseFloat(parts[6].trim());
                    if (parts[7] && parts[7].trim() !== "") {
                        root.cornerRadius = parseInt(parts[7].trim());
                    }
                    if (parts[8] && parts[8].trim() !== "") root.pinnedAppsEnabled = (parts[8].trim() === "true");
                    if (parts[9] && parts[9].trim() !== "") {
                        try {
                            root.pinnedApps = JSON.parse(parts[9].trim());
                        } catch(e) {}
                    }
                }
            }
        }
    }

    // =====================================================================
    // Interactive Properties (for live mockup state)
    // =====================================================================
    property bool dockEnabled: true
    property bool activeMonitorOnly: false
    property bool monitorsAll: true
    
    property bool autoHide: false
    property bool reserveSpace: false
    property bool showDots: true
    property bool showInstanceCount: false
    property string launcherPosition: "Start"
    property string launcherIcon: ""
    property bool magnificationEnabled: false
    
    property string dockPosition: "Bottom"
    property int iconSize: 48
    property int mainAxisPadding: 12
    property int crossAxisPadding: 8
    property int itemSpacing: 6
    property int endsMargin: 10
    property int edgeMargin: 8
    
    property int cornerRadius: 20
    
    property int bgOpacity: 60
    property bool shadowEnabled: true
    
    property real activeIconScale: 1.1
    property real inactiveIconScale: 1.0
    property real magnificationScale: 1.5
    property int activeIconOpacity: 100
    property int inactiveIconOpacity: 70
    
    property bool pinnedAppsEnabled: true
    property var pinnedApps: [
        { appId: "firefox", exec: "firefox", name: "Firefox" },
        { appId: "kitty", exec: "kitty", name: "Terminal" },
        { appId: "org.gnome.Nautilus", exec: "nautilus", name: "Files" },
        { appId: "code", exec: "code", name: "Code" }
    ]

    function savePinnedApps() {
        let jsonStr = JSON.stringify(root.pinnedApps);
        let encoded = encodeURIComponent(jsonStr);
        Quickshell.execDetached(["bash", "-c", "echo '" + jsonStr + "' > ~/.config/cupcake/.dock_pinned_apps && quickshell ipc -p ~/.config/quickshell/shell.qml call dock setPinnedAppsEncoded '\"" + encoded + "\"'"]);
    }

    Timer {
        id: applyRemoveTimer
        interval: 1
        repeat: false
        property int indexToRemove: -1
        onTriggered: {
            if (indexToRemove < 0) return;
            let arr = [];
            for (let i = 0; i < root.pinnedApps.length; i++) {
                if (i !== indexToRemove) {
                    arr.push(root.pinnedApps[i]);
                }
            }
            root.pinnedApps = arr;
            root.savePinnedApps();
            indexToRemove = -1;
        }
    }

    // =====================================================================

    // =====================================================================
    // Reusable inline components (Modern Design)
    // =====================================================================
    component SettingsCard: Rectangle {
        default property alias content: cardCol.data
        property string sectionTitle: ""
        Layout.fillWidth: true
        implicitHeight: cardCol.implicitHeight + (cardHeader.visible ? cardHeader.height + 28 : 32)
        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
        radius: 12
        border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.08)
        border.width: 1

        RowLayout {
            id: cardHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.topMargin: 16
            visible: sectionTitle !== ""
            spacing: 8

            Text {
                text: sectionTitle
                color: Theme.colOnSurfaceVariant
                font.family: Theme.defaultFontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
                font.capitalization: Font.AllUppercase
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15) }
        }

        ColumnLayout {
            id: cardCol
            anchors.top: cardHeader.visible ? cardHeader.bottom : parent.top
            anchors.topMargin: cardHeader.visible ? 12 : 16
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.bottomMargin: 16
            spacing: 0
        }
    }

    component SectionLabel: Text {
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 0.4
        color: Theme.colOnSurface
        opacity: 0.45
    }

    component SettingsRow: Rectangle {
        default property alias rowContent: innerLayout.data
        Layout.fillWidth: true
        implicitHeight: innerLayout.implicitHeight + 20
        color: "transparent"
        radius: 8

        property bool hoverable: false
        property bool hovered: hoverArea.containsMouse
        Behavior on color { ColorAnimation { duration: 120 } }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: parent.hoverable
        }

        RowLayout {
            id: innerLayout
            anchors.fill: parent
            anchors.leftMargin: 0
            anchors.rightMargin: 0
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            spacing: 12
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
            opacity: 0.6
        }
    }



    component SegmentedControl: Rectangle {
        id: seg
        property var options: []
        property string current: options.length > 0 ? options[0] : ""
        signal selected(string value)
        color: Qt.rgba(0, 0, 0, 0.28)
        radius: 8
        height: 30
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
                    height: 26
                    width: segLabel.implicitWidth + 24
                    radius: 6
                    color: active ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.92) : "transparent"
                    Text {
                        id: segLabel
                        anchors.centerIn: parent
                        text: modelData
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: active ? Theme.colSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.5)
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { seg.current = modelData; seg.selected(modelData) }
                    }
                }
            }
        }
    }

    component Pill: Rectangle {
        id: pill
        property string label: ""
        property bool active: false
        signal clicked()

        radius: 10
        height: 28
        width: pillText.implicitWidth + 24
        color: active ? cAccent : cBgElevated
        border.color: active ? cAccent : cBorder
        border.width: 1

        Text {
            id: pillText
            anchors.centerIn: parent
            text: pill.label
            font.family: Theme.defaultFontFamily
            font.pixelSize: 12
            font.weight: Font.Medium
            color: active ? "white" : cTextDim
        }

        MouseArea {
            anchors.fill: parent
            onClicked: pill.clicked()
            cursorShape: Qt.PointingHandCursor
        }
    }

    // =====================================================================
    // Main UI Layout
    // =====================================================================
    ScrollView {
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        anchors.fill: parent
        leftPadding: 32
        rightPadding: 32
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: Math.min(parent.width, 1000)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20

            // 1. GENERAL CARD
            SettingsCard {
                sectionTitle: "General"

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                            Text { anchors.centerIn: parent; text: "\uea9a"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Enabled"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Show the dock on your desktop"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.dockEnabled
                        onToggled: (c) => {
                            root.dockEnabled = c;
                            bashProcess.command = ["bash", "-c", "echo " + (c ? "'all'" : "'none'") + " > ~/.config/cupcake/.dock_monitors && quickshell ipc -p ~/.config/quickshell/shell.qml call dock setMonitors " + (c ? "'all'" : "'none'")];
                            bashProcess.running = true;
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                            Text { anchors.centerIn: parent; text: "\uebd3"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Active monitor only"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Only show the dock on the focused monitor"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.activeMonitorOnly
                        onToggled: (c) => root.activeMonitorOnly = c
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                            Text { anchors.centerIn: parent; text: "\ufa59"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Monitors"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Choose which monitors display the dock"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.monitorsAll
                        onToggled: (c) => root.monitorsAll = c
                    }
                }
            }

            // 2. BEHAVIOR CARD
            SettingsCard {
                sectionTitle: "Behavior"

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                            Text { anchors.centerIn: parent; text: "\uecf0"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Auto hide"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Hide the dock until the cursor reaches the edge"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.autoHide
                        onToggled: (c) => {
                            root.autoHide = c;
                            bashProcess.command = ["bash", "-c", "echo " + (c ? "'true'" : "'false'") + " > ~/.config/cupcake/.dock_autohide && quickshell ipc -p ~/.config/quickshell/shell.qml call dock setAutoHide " + (c ? "'true'" : "'false'")];
                            bashProcess.running = true;
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                            Text { anchors.centerIn: parent; text: "\ueb2c"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Reserve space"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Keep windows from overlapping the dock"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.reserveSpace
                        onToggled: (c) => {
                            root.reserveSpace = c;
                            bashProcess.command = ["bash", "-c", "echo " + (c ? "'true'" : "'false'") + " > ~/.config/cupcake/.dock_reserve_space && quickshell ipc -p ~/.config/quickshell/shell.qml call dock setReserveSpace " + (c ? "'true'" : "'false'")];
                            bashProcess.running = true;
                        }
                    }
                }



                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                            Text { anchors.centerIn: parent; text: "\uefb1"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Show dots"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Use dots for running app markers"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.showDots
                        onToggled: (c) => {
                            root.showDots = c;
                            bashProcess.command = ["bash", "-c", "echo '" + c + "' > ~/.config/cupcake/.dock_show_dots && quickshell ipc -p ~/.config/quickshell/shell.qml call dock setShowDots " + c];
                            bashProcess.running = true;
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                            Text { anchors.centerIn: parent; text: "\uf554"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Show instance count"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Badge with open window count per app"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.showInstanceCount
                        onToggled: (c) => root.showInstanceCount = c
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                            Text { anchors.centerIn: parent; text: "\uedba"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Launcher position"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Place the launcher at the start or end"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: ["Start", "End"]
                        current: root.launcherPosition
                        onSelected: (v) => {
                            root.launcherPosition = v;
                            bashProcess.command = ["bash", "-c", "echo '" + v + "' > ~/.config/cupcake/.dock_launcher_position && quickshell ipc -p ~/.config/quickshell/shell.qml call dock setLauncherPosition " + v];
                            bashProcess.running = true;
                        }
                    }
                }



                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                            Text { anchors.centerIn: parent; text: "\ueb56"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Pop up"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Enlarge icons on hover"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.magnificationEnabled
                        onToggled: (c) => {
                            root.magnificationEnabled = c;
                            bashProcess.command = ["bash", "-c", "echo '" + c + "' > ~/.config/cupcake/.dock_magnification_enabled && quickshell ipc -p ~/.config/quickshell/shell.qml call dock setMagnificationEnabled " + c];
                            bashProcess.running = true;
                        }
                    }
                }
            }

            // 3. LAYOUT CARD
            SettingsCard {
                sectionTitle: "Layout"



                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                            Text { anchors.centerIn: parent; text: "\ueecf"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Icon size"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Size of each dock icon"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 16; to: 128; stepSize: 1
                            value: root.iconSize
                            onValueChanged: root.iconSize = value
                        }
                        Text {
                            text: root.iconSize + "px"
                            color: Theme.colOnSurfaceVariant
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 12
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                            Text { anchors.centerIn: parent; text: "\ueb59"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Main axis padding"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Padding along the dock length"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 0; to: 64; stepSize: 1
                            value: root.mainAxisPadding
                            onValueChanged: root.mainAxisPadding = value
                        }
                        Text {
                            text: root.mainAxisPadding + "px"
                            color: Theme.colOnSurfaceVariant
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 12
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                            Text { anchors.centerIn: parent; text: "\ueb5b"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Cross axis padding"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Padding across the dock thickness"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 0; to: 64; stepSize: 1
                            value: root.crossAxisPadding
                            onValueChanged: root.crossAxisPadding = value
                        }
                        Text {
                            text: root.crossAxisPadding + "px"
                            color: Theme.colOnSurfaceVariant
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 12
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                            Text { anchors.centerIn: parent; text: "\uedb0"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Item spacing"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Space between dock icons"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 0; to: 64; stepSize: 1
                            value: root.itemSpacing
                            onValueChanged: root.itemSpacing = value
                        }
                        Text {
                            text: root.itemSpacing + "px"
                            color: Theme.colOnSurfaceVariant
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 12
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                            Text { anchors.centerIn: parent; text: "\uea0e"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Ends margin"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Margin at the start and end"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 0; to: 64; stepSize: 1
                            value: root.endsMargin
                            onValueChanged: root.endsMargin = value
                        }
                        Text {
                            text: root.endsMargin + "px"
                            color: Theme.colOnSurfaceVariant
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 12
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                            Text { anchors.centerIn: parent; text: "\uec89"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Edge margin"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Distance from the screen edge"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 0; to: 64; stepSize: 1
                            value: root.edgeMargin
                            onValueChanged: root.edgeMargin = value
                        }
                        Text {
                            text: root.edgeMargin + "px"
                            color: Theme.colOnSurfaceVariant
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 12
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }

            // 4. SHAPE CARD
            SettingsCard {
                sectionTitle: "Shape"

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                            Text { anchors.centerIn: parent; text: "\ueb7c"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Corner radius"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Overall corner rounding"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 0; to: 64; stepSize: 1
                            value: root.cornerRadius
                            onValueChanged: { root.cornerRadius = value; shapeDebounce.restart(); }
                        }
                        Text {
                            text: root.cornerRadius + "px"
                            color: Theme.colOnSurfaceVariant
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 12
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }

            // 5. EFFECTS CARD
            SettingsCard {
                sectionTitle: "Effects"

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                            Text { anchors.centerIn: parent; text: "\uea97"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Background opacity"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Transparency of the dock background"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 0; to: 100; stepSize: 1
                            value: root.bgOpacity
                            onValueChanged: root.bgOpacity = value
                        }
                        Text {
                            text: root.bgOpacity + "%"
                            color: Theme.colOnSurfaceVariant
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 12
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                            Text { anchors.centerIn: parent; text: "\ueed8"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Shadow"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Drop shadow beneath the dock"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.shadowEnabled
                        onToggled: (c) => root.shadowEnabled = c
                    }
                }
            }


            // 7. PINNED APPS CARD
            SettingsCard {
                sectionTitle: "Pinned apps"

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                            Text { anchors.centerIn: parent; text: "\uec9c"; color: cTextDim; font.family: "tabler-icons"; font.pixelSize: 18 }
                        }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Pinned apps"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Keep chosen apps permanently docked"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.pinnedAppsEnabled
                        onToggled: (c) => {
                            root.pinnedAppsEnabled = c;
                            bashProcess.command = ["bash", "-c", "echo '" + c + "' > ~/.config/cupcake/.dock_pinned_apps_enabled && quickshell ipc -p ~/.config/quickshell/shell.qml call dock setPinnedAppsEnabled '" + c + "'"];
                            bashProcess.running = true;
                        }
                    }
                }

                SettingsRow {
                    Flow {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 6

                        Repeater {
                            model: root.pinnedApps
                            delegate: Pill {
                                required property var modelData
                                required property int index
                                label: modelData.name + "  \u00d7"
                                active: false
                                onClicked: {
                                    applyRemoveTimer.indexToRemove = index;
                                    applyRemoveTimer.start();
                                }
                            }
                        }

                        Pill {
                            label: "+ Add app"
                            active: false
                            onClicked: {
                                appPickerModal.visible = true;
                                appPickerModal.searchField.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 24 }
        }
    }

    Rectangle {
        id: appPickerModal
        anchors.fill: parent
        color: Theme.colSurfaceContainerHigh
        visible: false
        z: 999
        radius: 12

        property var allApps: typeof DesktopEntries !== "undefined" ? DesktopEntries.applications.values : []
        property string query: ""
        property var filteredApps: {
            if (query === "") return allApps;
            let q = query.toLowerCase();
            return allApps.filter(a => a.name && a.name.toLowerCase().includes(q));
        }
        
        property alias searchField: searchField

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12
            
            RowLayout {
                spacing: 12
                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: "Search apps..."
                    color: Theme.colOnSurface
                    font.family: Theme.defaultFontFamily
                    onTextChanged: appPickerModal.query = text
                }
                Button {
                    text: "Cancel"
                    onClicked: appPickerModal.visible = false
                }
            }
            
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: appPickerModal.filteredApps
                clip: true
                spacing: 4
                delegate: Rectangle {
                    width: ListView.view.width
                    height: 48
                    color: hoverHandler.hovered ? Theme.colSurfaceVariant : "transparent"
                    radius: 8

                    HoverHandler { id: hoverHandler }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        text: modelData.name
                        color: Theme.colOnSurface
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 14
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            let arr = [...root.pinnedApps];
                            
                            // Prefer explicitly defined icon, fallback to desktopId without extension, fallback to name
                            let finalAppId = "";
                            if (modelData.icon) {
                                finalAppId = modelData.icon;
                            } else if (modelData.desktopId) {
                                finalAppId = modelData.desktopId.replace(".desktop", "");
                            } else if (modelData.id) {
                                finalAppId = modelData.id.replace(".desktop", "");
                            } else {
                                finalAppId = (modelData.name || "").toLowerCase();
                            }

                            let exec = modelData.execString || "";
                            if (!exec && modelData.command) {
                                exec = modelData.command.join(" ");
                            }
                            if (exec) {
                                exec = exec.replace(/%[a-zA-Z]/g, "").trim();
                            } else {
                                exec = finalAppId;
                            }

                            arr.push({ name: modelData.name, appId: finalAppId, exec: exec });
                            root.pinnedApps = arr;
                            root.savePinnedApps();
                            appPickerModal.visible = false;
                        }
                    }
                }
            }
        }
    }
}
