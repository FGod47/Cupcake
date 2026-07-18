import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import Quickshell.Io
import Quickshell
import "../common"

Item {
    id: root
    Process { id: bashProcess }

    // =====================================================================
    // Backend state for this page
    // =====================================================================

    property string hostname: "ryzen-arch"
    property string kernel: "—"
    property string uptime: "—"
    property string osName: "Arch Linux x86_64"

    Process {
        command: ["hostnamectl", "--static"]
        running: true
        stdout: StdioCollector { onStreamFinished: { let s = text.trim(); if (s !== "") root.hostname = s; } }
    }
    Process {
        command: ["uname", "-r"]
        running: true
        stdout: StdioCollector { onStreamFinished: { root.kernel = text.trim(); } }
    }
    Process {
        command: ["uptime", "-p"]
        running: true
        stdout: StdioCollector { onStreamFinished: { root.uptime = text.trim().replace("up ", ""); } }
    }

    property string cpuGovernor: "schedutil"
    Process {
        command: ["cat", "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"]
        running: true
        stdout: StdioCollector { onStreamFinished: { let s = text.trim(); if (s !== "") root.cpuGovernor = s; } }
    }

    property string powerProfile: "Balanced"
    Process {
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let s = text.trim();
                if (s === "power-saver") root.powerProfile = "Saver";
                else if (s === "performance") root.powerProfile = "Performance";
                else if (s !== "") root.powerProfile = "Balanced";
            }
        }
    }

    property int swappiness: 10
    Process {
        command: ["cat", "/proc/sys/vm/swappiness"]
        running: true
        stdout: StdioCollector { onStreamFinished: { let v = parseInt(text.trim()); if (!isNaN(v)) root.swappiness = v; } }
    }

    property int lockTimeout: 10 // minutes
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.lock_timeout"]
        running: true
        stdout: StdioCollector { onStreamFinished: { let v = parseInt(text.trim()); if (!isNaN(v)) root.lockTimeout = v; } }
    }

    property bool lockOnSuspend: true
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.lock_on_suspend"]
        running: true
        stdout: StdioCollector { onStreamFinished: { root.lockOnSuspend = (text.trim() !== "false"); } }
    }

    // Startup toggles
    property bool autostartNetworkManager: true
    property bool autostartBluetooth: true
    property bool autostartPolkit: true
    property bool autostartCliphist: true
    property bool autostartMako: false

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.autostart_flags"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.length === 0) return;
                let lines = text.trim().split('\n');
                for (let i = 0; i < lines.length; i++) {
                    let l = lines[i];
                    if (l.startsWith('NETWORKMANAGER=')) root.autostartNetworkManager = l.split('=')[1] === 'true';
                    if (l.startsWith('BLUETOOTH=')) root.autostartBluetooth = l.split('=')[1] === 'true';
                    if (l.startsWith('POLKIT=')) root.autostartPolkit = l.split('=')[1] === 'true';
                    if (l.startsWith('CLIPHIST=')) root.autostartCliphist = l.split('=')[1] === 'true';
                    if (l.startsWith('MAKO=')) root.autostartMako = l.split('=')[1] === 'true';
                }
            }
        }
    }

    function writeAutostartFlag(key, value) {
        Quickshell.execDetached(["bash", "-c",
            "sed -i '/^" + key + "=/d' ~/.config/cupcake/.autostart_flags; " +
            "echo '" + key + "=" + value + "' >> ~/.config/cupcake/.autostart_flags"]);
    }

    // Default apps
    property string defaultTerminal: "kitty"
    property string defaultFileManager: "nautilus"
    property string defaultBrowser: "firefox"
    property string defaultEditor: "neovim"

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.default_apps"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.length === 0) return;
                let lines = text.trim().split('\n');
                for (let i = 0; i < lines.length; i++) {
                    let l = lines[i];
                    if (l.startsWith('TERMINAL=')) root.defaultTerminal = l.split('=')[1];
                    if (l.startsWith('FILEMANAGER=')) root.defaultFileManager = l.split('=')[1];
                    if (l.startsWith('BROWSER=')) root.defaultBrowser = l.split('=')[1];
                    if (l.startsWith('EDITOR=')) root.defaultEditor = l.split('=')[1];
                }
            }
        }
    }

    // Updates
    property int updateCount: 0
    property int aurUpdateCount: 0
    property string mirrorSynced: "—"

    Process {
        id: checkUpdatesProcess
        command: ["bash", "-c", "checkupdates 2>/dev/null | wc -l"]
        running: true
        stdout: StdioCollector { onStreamFinished: { let v = parseInt(text.trim()); if (!isNaN(v)) root.updateCount = v; } }
    }
    Process {
        command: ["bash", "-c", "command -v yay >/dev/null && yay -Qua 2>/dev/null | wc -l || echo 0"]
        running: true
        stdout: StdioCollector { onStreamFinished: { let v = parseInt(text.trim()); if (!isNaN(v)) root.aurUpdateCount = v; } }
    }

    // Quickshell
    property string ipcSocketPath: "/run/user/1000/quickshell/cupcake.sock"
    property bool liveReload: true
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.quickshell_live_reload"]
        running: true
        stdout: StdioCollector { onStreamFinished: { root.liveReload = (text.trim() !== "false"); } }
    }

    // =====================================================================
    // Reusable inline components (mirrors SettingsPageAppearance.qml)
    // =====================================================================

    component SettingsCard: Rectangle {
        default property alias content: cardCol.data
        property string sectionTitle: ""
        Layout.fillWidth: true
        radius: 12
        color: cSurface
        border.color: cBorder
        border.width: 1
        implicitHeight: cardCol.implicitHeight + (sectionTitle !== "" ? 56 : 32)
        Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        clip: true

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
                color: cTextDim
                font.family: Theme.defaultFontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
                font.capitalization: Font.AllUppercase
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: cBorder }
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

    component SectionLabel: RowLayout {
        property string text: ""
        Layout.fillWidth: true
        Layout.bottomMargin: 8
        spacing: 8
        Text {
            text: parent.text
            color: cTextDim
            font.family: Theme.defaultFontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 0.8
            font.capitalization: Font.AllUppercase
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: cBorder }
    }

    component ToggleSwitch: Rectangle {
        id: tog
        property bool checked: false
        signal toggled(bool checked)
        width: 44; height: 24; radius: 12
        color: checked ? cAccent : cBorderSoft
        Behavior on color { ColorAnimation { duration: 150 } }
        Rectangle {
            width: 18; height: 18; radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: tog.checked ? parent.width - width - 3 : 3
            color: "white"
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: { tog.checked = !tog.checked; tog.toggled(tog.checked) }
        }
    }

    component SegmentedControl: Rectangle {
        id: seg
        property var options: []
        property string current: options.length > 0 ? options[0] : ""
        signal selected(string value)

        color: cBgElevated
        radius: 8
        height: 30
        width: row.implicitWidth + 4

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 1

            Repeater {
                model: seg.options
                delegate: Rectangle {
                    required property string modelData
                    property bool active: modelData === seg.current
                    height: 26
                    width: label.implicitWidth + 24
                    radius: 6
                    color: active ? cAccent : "transparent"

                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: modelData
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: active ? "white" : cTextDim
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
        property bool danger: false
        signal clicked()

        radius: 8
        height: 26
        width: pillText.implicitWidth + 24
        color: active ? cAccent : cBgElevated

        Text {
            id: pillText
            anchors.centerIn: parent
            text: pill.label
            font.family: Theme.defaultFontFamily
            font.pixelSize: 12
            font.weight: Font.Medium
            color: active ? "white" : (pill.danger ? cDanger : cTextDim)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: pill.clicked()
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onEntered: pill.color = pill.active ? cAccent : cBgHover
            onExited: pill.color = pill.active ? cAccent : cBgElevated
        }
    }

    component SettingsRow: Rectangle {
        default property alias content: innerRow.data
        Layout.fillWidth: true
        implicitHeight: innerRow.implicitHeight + 20
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
            id: innerRow
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
            color: cBorder
            opacity: 0.6
        }
    }

    component IconChip: Rectangle {
        property string glyph: ""
        property bool accented: false
        width: 32; height: 32; radius: 10
        color: cBgElevated
        Text {
            anchors.centerIn: parent
            text: parent.glyph
            color: parent.accented ? cAccent : cTextDim
            font.family: "tabler-icons"
            font.pixelSize: 16
        }
    }

    component RowLabel: ColumnLayout {
        property string label: ""
        property string desc: ""
        spacing: 1
        Text { text: parent.label; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
        Text {
            text: parent.desc
            color: cTextDim
            font.family: Theme.defaultFontFamily
            font.pixelSize: 11
            opacity: 0.8
            visible: text !== ""
        }
    }

    component MonoChip: Rectangle {
        property string text: ""
        radius: 6
        color: Qt.rgba(0, 0, 0, 0.25)
        implicitWidth: Math.min(chipText.implicitWidth + 16, 220)
        implicitHeight: 22
        Text {
            id: chipText
            anchors.centerIn: parent
            width: parent.width - 16
            text: parent.parent.text
            font.family: Theme.monoFontFamily
            font.pixelSize: 10
            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.55)
            elide: Text.ElideMiddle
            horizontalAlignment: Text.AlignHCenter
        }
    }

    component NavChevron: Text {
        text: "\uea61" // chevron-right
        color: cTextDim
        font.family: "tabler-icons"
        font.pixelSize: 18
        opacity: 0.6
        anchors.verticalCenter: parent.verticalCenter
    }

    // =====================================================================
    // Main layout
    // =====================================================================

    ScrollView {
        id: scrollView
        anchors.fill: parent
        anchors.bottomMargin: 30
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 24

            Item { Layout.preferredHeight: 8 }

            // --- Device section ---
            SettingsCard {
                SectionLabel { text: "Device" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        IconChip { glyph: "\ueb00" }
                        RowLabel { label: "Hostname"; desc: "Shown on the network and in shell prompts" }
                    }
                    Item { Layout.fillWidth: true }
                    TextField {
                        text: root.hostname
                        font.family: Theme.monoFontFamily
                        font.pixelSize: 12
                        color: cText
                        implicitWidth: 170
                        background: Rectangle { radius: 6; color: Qt.rgba(0, 0, 0, 0.25); border.color: cBorder; border.width: 1 }
                        onEditingFinished: {
                            root.hostname = text;
                            Quickshell.execDetached(["pkexec", "hostnamectl", "set-hostname", text]);
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        IconChip { glyph: "\uecf5" }
                        RowLabel { label: "Operating system"; desc: root.osName }
                    }
                    Item { Layout.fillWidth: true }
                    MonoChip { text: "rolling" }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        IconChip { glyph: "\uebd4" }
                        RowLabel { label: "Kernel"; desc: root.kernel }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        radius: 20
                        color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.14)
                        implicitWidth: upToDateText.implicitWidth + 18
                        implicitHeight: 20
                        Text {
                            id: upToDateText
                            anchors.centerIn: parent
                            text: "up to date"
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: cAccent
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        IconChip { glyph: "\ueb42" }
                        RowLabel { label: "Uptime" }
                    }
                    Item { Layout.fillWidth: true }
                    MonoChip { text: root.uptime }
                }
            }

            // --- Performance section ---
            SettingsCard {
                SectionLabel { text: "Performance" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        IconChip { glyph: "\ueb1b"; accented: true }
                        RowLabel { label: "CPU governor"; desc: "Scheduling policy applied on boot" }
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: ["powersave", "schedutil", "performance"]
                        current: root.cpuGovernor
                        onSelected: (v) => {
                            root.cpuGovernor = v;
                            Quickshell.execDetached(["bash", "-c",
                                "echo '" + v + "' > ~/.config/cupcake/.cpu_governor && ~/.local/bin/set-governor"]);
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        IconChip { glyph: "\ueb1a"; accented: true }
                        RowLabel { label: "Power profile" }
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: ["Saver", "Balanced", "Performance"]
                        current: root.powerProfile
                        onSelected: (v) => {
                            root.powerProfile = v;
                            let val = v === "Saver" ? "power-saver" : (v === "Performance" ? "performance" : "balanced");
                            Quickshell.execDetached(["powerprofilesctl", "set", val]);
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        IconChip { glyph: "\uead7" }
                        RowLabel { label: "Swappiness"; desc: "Kernel preference for swapping over reclaim" }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 0; to: 100; stepSize: 1
                            value: root.swappiness
                            onValueChanged: { root.swappiness = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["pkexec", "sysctl", "vm.swappiness=" + Math.round(root.swappiness)]);
                                }
                            }
                        }
                        Text {
                            text: Math.round(root.swappiness)
                            color: cTextDim
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 12
                            Layout.preferredWidth: 32
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }

            // --- Startup applications section ---
            SettingsCard {
                SectionLabel { text: "Startup Applications" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        IconChip { glyph: "\ueb1e" }
                        RowLabel { label: "Network Manager applet" }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch {
                        checked: root.autostartNetworkManager
                        onToggled: (c) => { root.autostartNetworkManager = c; root.writeAutostartFlag("NETWORKMANAGER", c); }
                    }
                }
                SettingsRow {
                    RowLayout {
                        spacing: 12
                        IconChip { glyph: "\ueca6" }
                        RowLabel { label: "Bluetooth applet" }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch {
                        checked: root.autostartBluetooth
                        onToggled: (c) => { root.autostartBluetooth = c; root.writeAutostartFlag("BLUETOOTH", c); }
                    }
                }
                SettingsRow {
                    RowLayout {
                        spacing: 12
                        IconChip { glyph: "\uead4" }
                        RowLabel { label: "Polkit authentication agent" }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch {
                        checked: root.autostartPolkit
                        onToggled: (c) => { root.autostartPolkit = c; root.writeAutostartFlag("POLKIT", c); }
                    }
                }
                SettingsRow {
                    RowLayout {
                        spacing: 12
                        IconChip { glyph: "\ueb0f" }
                        RowLabel { label: "Clipboard history (cliphist)" }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch {
                        checked: root.autostartCliphist
                        onToggled: (c) => { root.autostartCliphist = c; root.writeAutostartFlag("CLIPHIST", c); }
                    }
                }
                SettingsRow {
                    RowLayout {
                        spacing: 12
                        IconChip { glyph: "\ueb4b" }
                        RowLabel { label: "Notification daemon (mako)" }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch {
                        checked: root.autostartMako
                        onToggled: (c) => { root.autostartMako = c; root.writeAutostartFlag("MAKO", c); }
                    }
                }
            }

            // --- Session & power section ---
            SettingsCard {
                SectionLabel { text: "Session & Power" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        IconChip { glyph: "\ueb37" }
                        RowLabel { label: "Lock after idle" }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 16
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 1; to: 30; stepSize: 1
                            value: root.lockTimeout
                            onValueChanged: { root.lockTimeout = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["bash", "-c",
                                        "echo '" + Math.round(root.lockTimeout) + "' > ~/.config/cupcake/.lock_timeout"]);
                                }
                            }
                        }
                        Text {
                            text: Math.round(root.lockTimeout) + "m"
                            color: cTextDim
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 12
                            Layout.preferredWidth: 32
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        IconChip { glyph: "\ueb37" }
                        RowLabel { label: "Lock on suspend" }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch {
                        checked: root.lockOnSuspend
                        onToggled: (c) => {
                            root.lockOnSuspend = c;
                            Quickshell.execDetached(["bash", "-c", "echo '" + c + "' > ~/.config/cupcake/.lock_on_suspend"]);
                        }
                    }
                }

                SettingsRow {
                    RowLabel { label: "Session actions" }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 8
                        Pill { label: "Lock"; onClicked: Quickshell.execDetached(["loginctl", "lock-session"]) }
                        Pill { label: "Log Out"; onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "exit"]) }
                        Pill { label: "Restart"; onClicked: Quickshell.execDetached(["systemctl", "reboot"]) }
                        Pill { label: "Shut Down"; danger: true; onClicked: Quickshell.execDetached(["systemctl", "poweroff"]) }
                    }
                }
            }

            // --- Default applications section ---
            SettingsCard {
                SectionLabel { text: "Default Applications" }

                SettingsRow {
                    hoverable: true
                    RowLayout {
                        spacing: 12
                        IconChip { glyph: "\uebd4" }
                        RowLabel { label: "Terminal" }
                    }
                    Item { Layout.fillWidth: true }
                    MonoChip { text: root.defaultTerminal }
                    NavChevron {}
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let p = root;
                            while (p && !p.hasOwnProperty("currentIndex")) p = p.parent;
                            if (p && p.currentIndex !== undefined) p.currentIndex = 6; // default apps sub-page
                        }
                    }
                }
                SettingsRow {
                    hoverable: true
                    RowLayout {
                        spacing: 12
                        IconChip { glyph: "\ueb45" }
                        RowLabel { label: "File manager" }
                    }
                    Item { Layout.fillWidth: true }
                    MonoChip { text: root.defaultFileManager }
                    NavChevron {}
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let p = root;
                            while (p && !p.hasOwnProperty("currentIndex")) p = p.parent;
                            if (p && p.currentIndex !== undefined) p.currentIndex = 6;
                        }
                    }
                }
                SettingsRow {
                    hoverable: true
                    RowLayout {
                        spacing: 12
                        IconChip { glyph: "\ueb35" }
                        RowLabel { label: "Web browser" }
                    }
                    Item { Layout.fillWidth: true }
                    MonoChip { text: root.defaultBrowser }
                    NavChevron {}
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let p = root;
                            while (p && !p.hasOwnProperty("currentIndex")) p = p.parent;
                            if (p && p.currentIndex !== undefined) p.currentIndex = 6;
                        }
                    }
                }
                SettingsRow {
                    hoverable: true
                    RowLayout {
                        spacing: 12
                        IconChip { glyph: "\ueb44" }
                        RowLabel { label: "Text editor" }
                    }
                    Item { Layout.fillWidth: true }
                    MonoChip { text: root.defaultEditor }
                    NavChevron {}
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let p = root;
                            while (p && !p.hasOwnProperty("currentIndex")) p = p.parent;
                            if (p && p.currentIndex !== undefined) p.currentIndex = 6;
                        }
                    }
                }
            }

            // --- System updates section ---
            SettingsCard {
                SectionLabel { text: "System Updates" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        IconChip { glyph: "\ueb1d"; accented: true }
                        RowLabel {
                            label: root.updateCount + " packages can be updated"
                            desc: root.aurUpdateCount + " from the AUR"
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Pill {
                        label: "Update now"
                        active: true
                        onClicked: Quickshell.execDetached(["bash", "-c", "kitty -e sh -c 'sudo pacman -Syu; read -p \"Press enter to close\"'"])
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        IconChip { glyph: "\ueb42" }
                        RowLabel { label: "Check automatically every day" }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch {
                        checked: true
                        onToggled: (c) => {
                            Quickshell.execDetached(["bash", "-c", "echo '" + c + "' > ~/.config/cupcake/.autocheck_updates"]);
                        }
                    }
                }
            }

            // --- Quickshell section ---
            SettingsCard {
                SectionLabel { text: "Quickshell" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        IconChip { glyph: "\uead9" }
                        RowLabel { label: "IPC socket"; desc: "Used by the quickshell CLI and this settings app" }
                    }
                    Item { Layout.fillWidth: true }
                    MonoChip { text: root.ipcSocketPath }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        IconChip { glyph: "\ueb1d" }
                        RowLabel { label: "Live-reload on config change" }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch {
                        checked: root.liveReload
                        onToggled: (c) => {
                            root.liveReload = c;
                            Quickshell.execDetached(["bash", "-c", "echo '" + c + "' > ~/.config/cupcake/.quickshell_live_reload"]);
                        }
                    }
                }

                SettingsRow {
                    RowLabel { label: "Shell process"; desc: "Restart the quickshell daemon" }
                    Item { Layout.fillWidth: true }
                    Pill {
                        label: "Restart shell"
                        onClicked: Quickshell.execDetached(["bash", "-c", "systemctl --user restart quickshell"])
                    }
                }
            }

            Item { Layout.preferredHeight: 8 }
        }
    }
}
