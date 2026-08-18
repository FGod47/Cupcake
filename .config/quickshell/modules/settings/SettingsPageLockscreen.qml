import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../../theme"
import Quickshell.Io
import Quickshell
import "../common"

Item {
    id: root

    property color cText: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.88)
    property color cTextDim: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.6)
    property color cAccent: Theme.colPrimary
    property color cBgElevated: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)

    property string currentWall: ""
    property string currentLockWall: ""
    property bool syncLockscreen: true
    property bool use24h: false
    property bool showSeconds: false
    property bool isPreviewUnlocked: false
    property bool lockOnSleep: true
    property bool blurLockScreen: true
    property string idleTimeout: "10 minutes"
    property string lockTheme: "cupcake-sddm"

    FontLoader {
        id: previewClockFont
        source: "file://" + Theme.homeDir + "/.local/share/fonts/Nunito.ttf"
    }

    // Read blur lockscreen preference
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.blur_lockscreen"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) root.blurLockScreen = (text.trim() === "true");
            }
        }
    }

    // Read current lock wallpaper
    Process {
        id: lockWallReader
        command: ["bash", "-c", "cat ~/.config/cupcake/.lock_wallpaper_path 2>/dev/null || echo ''"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let p = text.trim();
                if (p !== "") root.currentLockWall = p;
            }
        }
    }

    // Read current desktop wallpaper
    Process {
        id: deskWallReader
        command: ["bash", "-c", "cat ~/.cache/current_wallpaper 2>/dev/null || echo ''"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let p = text.trim();
                if (p !== "") root.currentWall = p;
            }
        }
    }

    // Read sync preference
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.sync_lock_wall"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) root.syncLockscreen = (text.trim() === "true");
            }
        }
    }

    // Read clock 24h preference
    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.clock_24h"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) root.use24h = (text.trim() === "true");
            }
        }
    }

    // Refresh every 5s
    Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: {
            if (!lockWallReader.running) lockWallReader.running = true;
            if (!deskWallReader.running) deskWallReader.running = true;
        }
    }

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

            // ── 1. HERO SHOWCASE: LIVE LOCKSCREEN PREVIEW ──────────────────
            NCard {
                sectionTitle: "Lock screen & SDDM Greeter"

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    // Live Interactive Stage
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 300
                        radius: 14
                        color: "#0a0a0c"
                        border.width: 1
                        border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                        clip: true

                        Rectangle {
                            id: heroStageMask
                            anchors.fill: parent
                            radius: 14
                            visible: false
                        }

                        Item {
                            anchors.fill: parent
                            layer.enabled: true
                            layer.effect: OpacityMask { maskSource: heroStageMask }

                            // Lockscreen Wallpaper Preview
                            Image {
                                id: heroLockWallImg
                                anchors.fill: parent
                                source: {
                                    var wall = root.syncLockscreen ? root.currentWall : (root.currentLockWall || root.currentWall);
                                    if (wall === "") return "file://" + Theme.homeDir + "/.local/share/qylock-themes/cupcake-sddm/background.png";
                                    var parts = wall.split("/");
                                    var filename = parts[parts.length - 1];
                                    return "file://" + Theme.homeDir + "/.cache/cupcake/wall_thumbs/" + filename + ".png";
                                }
                                sourceSize: Qt.size(720, 480)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                onStatusChanged: {
                                    if (status === Image.Error) {
                                        var wall = root.syncLockscreen ? root.currentWall : (root.currentLockWall || root.currentWall);
                                        if (wall !== "") source = "file://" + wall;
                                        else source = "file://" + Theme.homeDir + "/.local/share/qylock-themes/cupcake-sddm/background.png";
                                    }
                                }
                            }

                            // Dynamic Blur on Wallpaper
                            FastBlur {
                                anchors.fill: heroLockWallImg
                                source: heroLockWallImg
                                radius: root.isPreviewUnlocked ? 28 : 0
                                cached: true
                                Behavior on radius { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                            }

                            // Dim Overlay on Blur
                            Rectangle {
                                anchors.fill: parent
                                color: "#000000"
                                opacity: root.isPreviewUnlocked ? 0.35 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 350 } }
                            }

                            // Subtle Vignette
                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    orientation: Gradient.Vertical
                                    GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.45) }
                                    GradientStop { position: 0.4; color: "transparent" }
                                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.65) }
                                }
                            }

                            // iOS Style Frosted Glassy Lockscreen Clock & Date
                            Column {
                                id: prevClockCol
                                anchors.top: parent.top
                                anchors.topMargin: root.isPreviewUnlocked ? 18 : 24
                                Behavior on anchors.topMargin { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 2

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: Qt.formatDate(new Date(), "ddd MMM d")
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    color: "#ffffff"
                                    opacity: 0.95
                                }

                                Item {
                                    id: prevGlassClock
                                    width: prevTimeLabel.implicitWidth
                                    height: prevTimeLabel.implicitHeight
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    // Cropped wallpaper behind clock digits
                                    ShaderEffectSource {
                                        id: prevClockBgSource
                                        anchors.fill: parent
                                        sourceItem: heroLockWallImg
                                        sourceRect: {
                                            var pt = prevGlassClock.mapToItem(heroLockWallImg, 0, 0);
                                            return Qt.rect(pt.x, pt.y, prevGlassClock.width, prevGlassClock.height);
                                        }
                                        live: true
                                        visible: false
                                    }

                                    // Masked blurred wallpaper layer
                                    Item {
                                        anchors.fill: parent
                                        layer.enabled: true
                                        layer.effect: OpacityMask { maskSource: prevTimeMaskItem }

                                        FastBlur {
                                            anchors.fill: parent
                                            source: prevClockBgSource
                                            radius: 24
                                            cached: true
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            color: Qt.rgba(1, 1, 1, 0.42)
                                        }
                                    }

                                    Item {
                                        id: prevTimeMaskItem
                                        anchors.fill: parent
                                        visible: false

                                        Text {
                                            anchors.centerIn: parent
                                            text: {
                                                if (root.use24h) return Qt.formatTime(new Date(), "hh:mm");
                                                let d = new Date();
                                                let h = d.getHours() % 12 || 12;
                                                let m = d.getMinutes();
                                                return h + ":" + (m < 10 ? "0" + m : m);
                                            }
                                            font.family: previewClockFont.name || "Nunito"
                                            font.pixelSize: 56
                                            font.weight: Font.Bold
                                            font.letterSpacing: -1.5
                                            color: "#ffffff"
                                        }
                                    }

                                    Text {
                                        id: prevTimeLabel
                                        anchors.centerIn: parent
                                        text: {
                                            if (root.use24h) return Qt.formatTime(new Date(), "hh:mm");
                                            let d = new Date();
                                            let h = d.getHours() % 12 || 12;
                                            let m = d.getMinutes();
                                            return h + ":" + (m < 10 ? "0" + m : m);
                                        }
                                        font.family: previewClockFont.name || "Nunito"
                                        font.pixelSize: 56
                                        font.weight: Font.Bold
                                        font.letterSpacing: -1.5
                                        color: Qt.rgba(1, 1, 1, 0.18)
                                        style: Text.Raised
                                        styleColor: Qt.rgba(0, 0, 0, 0.22)
                                    }
                                }
                            }

                            // Frosted Glass Avatar & Interactive Slide-Up Login Section
                            Column {
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: root.isPreviewUnlocked ? 34 : 16
                                Behavior on anchors.bottomMargin { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: root.isPreviewUnlocked ? 6 : 3
                                Behavior on spacing { NumberAnimation { duration: 250 } }

                                Rectangle {
                                    id: prevAvatarCircle
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: root.isPreviewUnlocked ? 34 : 38
                                    height: width
                                    radius: width / 2
                                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                    color: Qt.rgba(255, 255, 255, 0.25)
                                    border.width: 1.5; border.color: Qt.rgba(255, 255, 255, 0.5)

                                    Rectangle {
                                        id: prevAvatarMask
                                        anchors.fill: parent
                                        radius: prevAvatarCircle.radius
                                        visible: false
                                    }

                                    Item {
                                        anchors.fill: parent
                                        anchors.margins: 1.5
                                        layer.enabled: true
                                        layer.effect: OpacityMask { maskSource: prevAvatarMask }

                                        Image {
                                            anchors.fill: parent
                                            source: "file://" + Theme.homeDir + "/.local/share/qylock-themes/cupcake-sddm/avatar.png"
                                            fillMode: Image.PreserveAspectCrop
                                        }
                                    }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Debojyoti Chakraborty"
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: "#ffffff"
                                }

                                // Fixed-Height Action Slot (Smooth Cross-Fade)
                                Item {
                                    id: prevActionSlot
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 140
                                    height: 26

                                    // Resting State: Click to unlock Hint
                                    Item {
                                        id: prevUnlockHint
                                        anchors.fill: parent
                                        opacity: root.isPreviewUnlocked ? 0.0 : 0.85
                                        y: root.isPreviewUnlocked ? -6 : 0
                                        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                        Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "▲  Click to unlock"
                                            font.family: Theme.defaultFontFamily
                                            font.pixelSize: 9
                                            font.weight: Font.Medium
                                            color: "#ffffff"
                                        }
                                    }

                                    // Active State: Password Input Pill with Animated Dots
                                    Rectangle {
                                        id: prevPasswordContainer
                                        anchors.fill: parent
                                        radius: 13
                                        clip: true
                                        opacity: root.isPreviewUnlocked ? 1.0 : 0.0
                                        y: root.isPreviewUnlocked ? 0 : 6
                                        scale: root.isPreviewUnlocked ? 1.0 : 0.92
                                        color: Qt.rgba(255, 255, 255, 0.15)
                                        border.width: 1; border.color: Qt.rgba(255, 255, 255, 0.35)
                                        Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                                        Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                                        Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 5
                                            Repeater {
                                                model: 6
                                                delegate: Rectangle {
                                                    id: prevDot
                                                    width: 6; height: 6; radius: 3
                                                    color: "#ffffff"
                                                    scale: root.isPreviewUnlocked ? 1.0 : 0.0
                                                    Behavior on scale {
                                                        NumberAnimation {
                                                            duration: 200 + (index * 40)
                                                            easing.type: Easing.OutBack
                                                            easing.overshoot: 1.4
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Interactive click to toggle preview unlock
                            MouseArea {
                                anchors.fill: parent
                                z: -1
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.isPreviewUnlocked = !root.isPreviewUnlocked
                            }

                            // Top Left Tags: System Badges
                            Row {
                                anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 12
                                spacing: 6
                                Rectangle {
                                    height: 22; radius: 11
                                    width: sddmBadgeRow.implicitWidth + 16
                                    color: Qt.rgba(0, 0, 0, 0.72)
                                    border.width: 1; border.color: Theme.colPrimary
                                    RowLayout {
                                        id: sddmBadgeRow; anchors.centerIn: parent; spacing: 5
                                        Text { text: "\ueae2"; font.family: "tabler-icons"; font.pixelSize: 11; color: Theme.colPrimary }
                                        Text { text: "SDDM & HYPRLOCK"; font.family: Theme.defaultFontFamily; font.pixelSize: 9; font.weight: Font.Bold; color: "#ffffff" }
                                    }
                                }
                            }
                        }
                    }

                    // Action Controls Bar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        // Test / Preview Lockscreen Button
                        Rectangle {
                            height: 36; radius: 8
                            implicitWidth: testLockRow.implicitWidth + 24
                            color: Theme.colPrimary
                            scale: testLockMa.containsMouse ? 1.02 : 1.0
                            Behavior on scale { NumberAnimation { duration: 120 } }
                            RowLayout {
                                id: testLockRow; anchors.centerIn: parent; spacing: 8
                                Text { text: "\ueae2"; font.family: "tabler-icons"; font.pixelSize: 15; color: Theme.colSurface }
                                Text { text: "Test Lock Screen (Super + L)"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Bold; color: Theme.colSurface }
                            }
                            MouseArea {
                                id: testLockMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached([Theme.homeDir + "/.local/share/quickshell-lockscreen/lock.sh"])
                            }
                        }

                        // Browse Lockscreen Wallpaper
                        Rectangle {
                            height: 36; radius: 8
                            implicitWidth: browseLockRow.implicitWidth + 20
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
                            border.width: 1; border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.15)
                            RowLayout {
                                id: browseLockRow; anchors.centerIn: parent; spacing: 6
                                Text { text: "\uea7b"; font.family: "tabler-icons"; font.pixelSize: 15; color: Theme.colPrimary }
                                Text { text: "Change Lock Wallpaper"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                            }
                            MouseArea {
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["bash", "-c", "XDG_CURRENT_DESKTOP=gnome zenity --file-selection --file-filter='Supported Media | *.png *.jpg *.jpeg *.webp *.gif *.mp4 *.webm *.mkv *.mov' --file-filter='All Files | *' 2>/dev/null | xargs -I{} bash -c 'echo false > ~/.config/cupcake/.sync_lock_wall; ~/.local/bin/set-lock-wallpaper \"{}\"'"])
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Mirror Desktop Button
                        Rectangle {
                            visible: !root.syncLockscreen
                            height: 36; radius: 8
                            implicitWidth: syncDesktopRow.implicitWidth + 20
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
                            border.width: 1; border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.15)
                            RowLayout {
                                id: syncDesktopRow; anchors.centerIn: parent; spacing: 6
                                Text { text: "\uea08"; font.family: "tabler-icons"; font.pixelSize: 15; color: Theme.colPrimary }
                                Text { text: "Match Desktop"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.colOnSurface }
                            }
                            MouseArea {
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.currentWall !== "") {
                                        Quickshell.execDetached([Theme.homeDir + "/.local/bin/set-lock-wallpaper", root.currentWall]);
                                        root.currentLockWall = root.currentWall;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── 2. WALLPAPER & SYNC OPTIONS ────────────────────────────────
            NCard {
                sectionTitle: "Wallpaper synchronization"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea08" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Mirror desktop wallpaper"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Automatically update SDDM and lockscreen whenever desktop wallpaper changes"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.syncLockscreen
                        onToggled: {
                            root.syncLockscreen = checked;
                            Quickshell.execDetached(["bash", "-c", "echo " + (checked ? "true" : "false") + " > ~/.config/cupcake/.sync_lock_wall"]);
                            if (checked && root.currentWall !== "") {
                                Quickshell.execDetached([Theme.homeDir + "/.local/bin/set-lock-wallpaper", root.currentWall]);
                            }
                        }
                    }
                }
            }

            // ── 3. CLOCK & DISPLAY OPTIONS ─────────────────────────────────
            NCard {
                sectionTitle: "Clock & typography"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea60" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Time format"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Choose 12-hour (9:26 PM) or 24-hour (21:26) clock format"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }

                    // Segmented 12h / 24h Pill
                    Rectangle {
                        width: 140; height: 32; radius: 16
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
                        border.width: 1; border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)

                        RowLayout {
                            anchors.fill: parent; spacing: 0
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 16
                                color: !root.use24h ? Theme.colPrimary : "transparent"
                                Text { anchors.centerIn: parent; text: "12-hour"; color: !root.use24h ? Theme.colSurface : Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.Bold }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.use24h = false;
                                        Quickshell.execDetached(["bash", "-c", "echo false > ~/.config/cupcake/.clock_24h"]);
                                    }
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 16
                                color: root.use24h ? Theme.colPrimary : "transparent"
                                Text { anchors.centerIn: parent; text: "24-hour"; color: root.use24h ? Theme.colSurface : Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.Bold }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.use24h = true;
                                        Quickshell.execDetached(["bash", "-c", "echo true > ~/.config/cupcake/.clock_24h"]);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── 4. SECURITY & SESSION LOCK ─────────────────────────────────
            NCard {
                sectionTitle: "Security & auto-lock"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueaf8" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Lock before sleep or suspend"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Automatically lock the screen when the computer enters sleep or suspend mode"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.lockOnSleep
                        onToggled: root.lockOnSleep = checked
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb04" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Blur on lock screen"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Apply a frosted blur effect behind the lockscreen interface"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.blurLockScreen
                        onToggled: {
                            root.blurLockScreen = checked;
                            Quickshell.execDetached(["bash", "-c", "echo " + (checked ? "true" : "false") + " > ~/.config/cupcake/.blur_lockscreen"]);
                        }
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueab0" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Keyboard shortcut"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Press Super + L to lock your session anytime"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        height: 26; radius: 6
                        width: kbdRow.implicitWidth + 16
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
                        border.width: 1; border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.15)
                        RowLayout {
                            id: kbdRow; anchors.centerIn: parent; spacing: 4
                            Text { text: "SUPER + L"; font.family: Theme.monoFontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: Theme.colPrimary }
                        }
                    }
                }
            }
        }
    }
}
