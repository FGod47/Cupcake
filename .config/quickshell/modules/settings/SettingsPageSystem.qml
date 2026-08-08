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

    property color cText: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.88)
    property color cTextDim: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.6)
    property color cTextFaint: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.4)
    property color cAccent: Theme.colPrimary
    property color cBgElevated: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
    property color cBorderSoft: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)

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
        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.05) }
    }




    component Pill: Rectangle {
        id: pill
        property string label: ""
        property bool active: false
        property bool danger: false
        property bool big: false
        signal clicked()

        radius: 8
        height: big ? 34 : 26
        width: pillText.implicitWidth + (big ? 32 : 24)
        color: active ? cAccent : cBgElevated

        Text {
            id: pillText
            anchors.centerIn: parent
            text: pill.label
            font.family: Theme.defaultFontFamily
            font.pixelSize: 12
            font.weight: pill.big ? Font.SemiBold : Font.Medium
            color: active ? Theme.colOnPrimary : (pill.danger ? cDanger : cTextDim)
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

    component PkgRow: RowLayout {
        property string pkgName: ""
        property string oldVer: ""
        property string newVer: ""
        Layout.fillWidth: true
        spacing: 0

        Text {
            text: pkgName
            font.family: Theme.monoFontFamily
            font.pixelSize: 11
            color: cText
            Layout.fillWidth: true
        }
        RowLayout {
            spacing: 4
            Text {
                text: oldVer + " →"
                font.family: Theme.monoFontFamily
                font.pixelSize: 11
                color: cTextFaint
            }
            Text {
                text: newVer
                font.family: Theme.monoFontFamily
                font.pixelSize: 11
                color: cAccent
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.columnSpan: 2
            height: 1
            color: cBorderSoft
            // This is placed as a bottom border via parent's bottom anchor in usage
        }
    }


    
    component RowLabel: ColumnLayout {
        property string label: ""
        property string desc: ""
        spacing: 1
        Layout.fillWidth: true
        Text {
            text: parent.label
            color: cText
            font.family: Theme.defaultFontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
        }
        Text {
            text: parent.desc
            color: cTextDim
            font.family: Theme.defaultFontFamily
            font.pixelSize: 11
            font.weight: Font.Normal
            opacity: 0.85
            visible: text !== ""
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }
    }

    component MonoChip: Rectangle {
        property string text: ""
        radius: 6
        color: Qt.rgba(0, 0, 0, 0.25)
        implicitWidth: Math.min(chipText.implicitWidth + 20, 220)
        implicitHeight: 26
        Text {
            id: chipText
            anchors.centerIn: parent
            width: parent.width - 20
            text: parent.text
            font.family: Theme.monoFontFamily
            font.pixelSize: 11
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
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        id: scrollView
        anchors.fill: parent
        anchors.bottomMargin: 28
        leftPadding: 32
        rightPadding: 32
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 20

            Item { Layout.preferredHeight: 14 }

            // --- Device section ---
            NCard {
                sectionTitle: "Device"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb00" }
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

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uecf5" }
                        RowLabel { label: "Operating system"; desc: root.osName }
                    }
                    Item { Layout.fillWidth: true }
                    MonoChip { text: "rolling" }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uebd4" }
                        RowLabel { label: "Kernel"; desc: root.kernel }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        radius: 20
                        color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.14)
                        implicitWidth: upToDateText.implicitWidth + 18
                        implicitHeight: 22
                        Text {
                            id: upToDateText
                            anchors.centerIn: parent
                            text: "up to date"
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: cAccent
                        }
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb42" }
                        RowLabel { label: "Uptime" }
                    }
                    Item { Layout.fillWidth: true }
                    MonoChip { text: root.uptime }
                }
            }

            // --- Performance section ---
            NCard {
                sectionTitle: "Performance"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb1b"}
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

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb1a"}
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

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uead7" }
                        RowLabel { label: "Swappiness"; desc: "Kernel preference for swapping over reclaim" }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 12
                        StyledSlider {
                            Layout.preferredWidth: 220
                            from: 0; to: 100; stepSize: 1
                            value: root.swappiness
                            onValueChanged: { root.swappiness = value; }
                            onPressedChanged: {
                                if (!pressed) {
                                    Quickshell.execDetached(["pkexec", "sysctl", "vm.swappiness=" + Math.round(root.swappiness)]);
                                }
                            }
                        }
                        
                    }
                }
            }

            // --- Startup applications section ---
            NCard {
                sectionTitle: "Startup Applications"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb1e" }
                        RowLabel { label: "Network Manager applet" }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.autostartNetworkManager
                        onToggled: (c) => { root.autostartNetworkManager = c; root.writeAutostartFlag("NETWORKMANAGER", c); }
                    }
                }
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueca6" }
                        RowLabel { label: "Bluetooth applet" }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.autostartBluetooth
                        onToggled: (c) => { root.autostartBluetooth = c; root.writeAutostartFlag("BLUETOOTH", c); }
                    }
                }
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uead4" }
                        RowLabel { label: "Polkit authentication agent" }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.autostartPolkit
                        onToggled: (c) => { root.autostartPolkit = c; root.writeAutostartFlag("POLKIT", c); }
                    }
                }
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb0f" }
                        RowLabel { label: "Clipboard history (cliphist)" }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.autostartCliphist
                        onToggled: (c) => { root.autostartCliphist = c; root.writeAutostartFlag("CLIPHIST", c); }
                    }
                }
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb4b" }
                        RowLabel { label: "Notification daemon (mako)" }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.autostartMako
                        onToggled: (c) => { root.autostartMako = c; root.writeAutostartFlag("MAKO", c); }
                    }
                }
            }

            // --- Session & power section ---
            NCard {
                sectionTitle: "Session & Power"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb37" }
                        RowLabel { label: "Lock after idle" }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 12
                        StyledSlider {
                            Layout.preferredWidth: 220
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
                        
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb37" }
                        RowLabel { label: "Lock on suspend" }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.lockOnSuspend
                        onToggled: (c) => {
                            root.lockOnSuspend = c;
                            Quickshell.execDetached(["bash", "-c", "echo '" + c + "' > ~/.config/cupcake/.lock_on_suspend"]);
                        }
                    }
                }

                NRow {
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
            NCard {
                sectionTitle: "Default Applications"

                NRow {
                    hoverable: true
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uebd4" }
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
                NRow {
                    hoverable: true
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb45" }
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
                NRow {
                    hoverable: true
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb35" }
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
                NRow {
                    hoverable: true
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb44" }
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


            // --- Quickshell section ---
            NCard {
                sectionTitle: "Quickshell"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uead9" }
                        RowLabel { label: "IPC socket"; desc: "Used by the quickshell CLI and this settings app" }
                    }
                    Item { Layout.fillWidth: true }
                    MonoChip { text: root.ipcSocketPath }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb1d" }
                        RowLabel { label: "Live-reload on config change" }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.liveReload
                        onToggled: (c) => {
                            root.liveReload = c;
                            Quickshell.execDetached(["bash", "-c", "echo '" + c + "' > ~/.config/cupcake/.quickshell_live_reload"]);
                        }
                    }
                }

                NRow {
                    RowLabel { label: "Shell process"; desc: "Restart the quickshell daemon" }
                    Item { Layout.fillWidth: true }
                    Pill {
                        label: "Restart shell"
                        onClicked: Quickshell.execDetached(["bash", "-c", "systemctl --user restart quickshell"])
                    }
                }
            }

            Item { Layout.preferredHeight: 28 }
        }
    }
}
