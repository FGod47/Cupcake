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

    // Wallpaper & Session state
    property string currentWall: ""
    property string currentLockWall: ""
    property bool syncLockscreen: true
    property bool use24h: false
    property bool isPreviewUnlocked: false
    property bool lockOnSleep: true
    property string currentRealName: "Zero"

    // Live Adjustable Blur & Glass properties
    property int clockBlurRadius: 48
    property int bgBlurRadius: 42
    property int glassSheen: 48

    // Typography & Component Customization
    property string clockFontFile: "OpenSans-Bold.ttf"
    property int clockFontSize: 124
    property bool showDate: true
    property bool showSession: true
    property bool showPower: true
    property bool showAvatar: true
    property bool showNotifications: true

    FontLoader {
        id: previewClockFont
        source: {
            if (root.clockFontFile === "Inter Display" || root.clockFontFile === "Inter" || root.clockFontFile === "SF Pro Display") return "";
            return "file://" + Theme.homeDir + "/.local/share/fonts/" + root.clockFontFile;
        }
    }

    property string activeClockFontFamily: (previewClockFont.name && previewClockFont.name !== "") ? previewClockFont.name : (root.clockFontFile === "Inter Display" ? "Inter Display, Inter, sans-serif" : "Open Sans, sans-serif")

    Timer {
        id: saveDebounceTimer
        interval: 150
        repeat: false
        onTriggered: {
            Quickshell.execDetached(["bash", "-c", 
                "echo '" + root.clockBlurRadius + "' > ~/.config/cupcake/.lock_clock_blur; " +
                "echo '" + root.bgBlurRadius + "' > ~/.config/cupcake/.lock_bg_blur; " +
                "echo '" + root.glassSheen + "' > ~/.config/cupcake/.lock_glass_sheen; " +
                "echo '" + root.clockFontFile + "' > ~/.config/cupcake/.lock_clock_font; " +
                "echo '" + root.clockFontSize + "' > ~/.config/cupcake/.lock_clock_size; " +
                "echo '" + (root.showDate ? "true" : "false") + "' > ~/.config/cupcake/.lock_show_date; " +
                "echo '" + (root.showSession ? "true" : "false") + "' > ~/.config/cupcake/.lock_show_session; " +
                "echo '" + (root.showPower ? "true" : "false") + "' > ~/.config/cupcake/.lock_show_power; " +
                "echo '" + (root.showAvatar ? "true" : "false") + "' > ~/.config/cupcake/.lock_show_avatar; " +
                "echo '" + (root.showNotifications ? "true" : "false") + "' > ~/.config/cupcake/.lock_show_notifications; " +
                "echo '" + (root.use24h ? "true" : "false") + "' > ~/.config/cupcake/.clock_24h; " +
                "~/.config/cupcake/scripts/update-lock-settings.sh"
            ]);
        }
    }

    function saveLockSettings() {
        saveDebounceTimer.restart();
    }

    // Read real user name from system
    Process {
        command: ["bash", "-c", "getent passwd $USER | cut -d: -f5 | cut -d, -f1 || whoami"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0) root.currentRealName = text.trim();
            }
        }
    }

    // Read saved configuration state
    Process {
        id: initLockSettings
        command: ["bash", "-c", 
            "cat ~/.config/cupcake/.lock_clock_blur 2>/dev/null || echo '48'; echo '---'; " +
            "cat ~/.config/cupcake/.lock_bg_blur 2>/dev/null || echo '42'; echo '---'; " +
            "cat ~/.config/cupcake/.lock_glass_sheen 2>/dev/null || echo '48'; echo '---'; " +
            "cat ~/.config/cupcake/.lock_clock_font 2>/dev/null || echo 'OpenSans-Bold.ttf'; echo '---'; " +
            "cat ~/.config/cupcake/.lock_clock_size 2>/dev/null || echo '124'; echo '---'; " +
            "cat ~/.config/cupcake/.lock_show_date 2>/dev/null || echo 'true'; echo '---'; " +
            "cat ~/.config/cupcake/.lock_show_session 2>/dev/null || echo 'true'; echo '---'; " +
            "cat ~/.config/cupcake/.lock_show_power 2>/dev/null || echo 'true'; echo '---'; " +
            "cat ~/.config/cupcake/.lock_show_avatar 2>/dev/null || echo 'true'; echo '---'; " +
            "cat ~/.config/cupcake/.lock_show_notifications 2>/dev/null || echo 'true'; echo '---'; " +
            "cat ~/.config/cupcake/.clock_24h 2>/dev/null || echo 'false'"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    let parts = text.trim().split('---');
                    if (parts[0] && parts[0].trim() !== "") root.clockBlurRadius = parseInt(parts[0].trim()) || 48;
                    if (parts[1] && parts[1].trim() !== "") root.bgBlurRadius = parseInt(parts[1].trim()) || 42;
                    if (parts[2] && parts[2].trim() !== "") root.glassSheen = parseInt(parts[2].trim()) || 48;
                    if (parts[3] && parts[3].trim() !== "") root.clockFontFile = parts[3].trim();
                    if (parts[4] && parts[4].trim() !== "") root.clockFontSize = parseInt(parts[4].trim()) || 124;
                    if (parts[5] && parts[5].trim() !== "") root.showDate = (parts[5].trim() !== "false");
                    if (parts[6] && parts[6].trim() !== "") root.showSession = (parts[6].trim() !== "false");
                    if (parts[7] && parts[7].trim() !== "") root.showPower = (parts[7].trim() !== "false");
                    if (parts[8] && parts[8].trim() !== "") root.showAvatar = (parts[8].trim() !== "false");
                    if (parts[9] && parts[9].trim() !== "") root.showNotifications = (parts[9].trim() !== "false");
                    if (parts[10] && parts[10].trim() !== "") root.use24h = (parts[10].trim() === "true");
                }
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

    // Refresh wallpaper every 5s
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

            // ── 1. HERO SHOWCASE: LIVE LOCKSCREEN & SDDM PREVIEW ─────────
            NCard {
                sectionTitle: "Live interactive preview"

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    // Live Interactive Stage
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 330
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

                            // Dynamic Blur on Wallpaper (Uses root.bgBlurRadius)
                            FastBlur {
                                anchors.fill: heroLockWallImg
                                source: heroLockWallImg
                                radius: root.isPreviewUnlocked ? (root.bgBlurRadius * 0.7) : 0
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

                            // Frosted Glass Lockscreen Clock & Date
                            Column {
                                id: prevClockCol
                                anchors.top: parent.top
                                anchors.topMargin: root.isPreviewUnlocked ? 14 : 20
                                Behavior on anchors.topMargin { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 2

                                // Frosted Date
                                Item {
                                    id: prevGlassDate
                                    visible: root.showDate
                                    width: prevDateMaskText.implicitWidth
                                    height: prevDateMaskText.implicitHeight
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Item {
                                        anchors.fill: parent
                                        layer.enabled: true
                                        layer.effect: OpacityMask { maskSource: prevDateMaskText }

                                        Image {
                                            width: heroLockWallImg.width
                                            height: heroLockWallImg.height
                                            x: -prevGlassDate.x - (prevClockCol.x)
                                            y: -prevGlassDate.y - (prevClockCol.y)
                                            source: heroLockWallImg.source
                                            fillMode: Image.PreserveAspectCrop
                                            smooth: true

                                            layer.enabled: true
                                            layer.effect: FastBlur {
                                                radius: Math.max(8, Math.round(root.clockBlurRadius * 0.5))
                                                cached: true
                                            }
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            gradient: Gradient {
                                                orientation: Gradient.Vertical
                                                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, (root.glassSheen / 100.0) * 1.1) }
                                                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, (root.glassSheen / 100.0) * 0.45) }
                                                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, (root.glassSheen / 100.0) * 0.75) }
                                            }
                                        }
                                    }

                                    Text {
                                        id: prevDateMaskText
                                        anchors.centerIn: parent
                                        text: Qt.formatDate(new Date(), "ddd MMM d")
                                        font.family: root.activeClockFontFamily
                                        font.pixelSize: Math.max(10, Math.round(root.clockFontSize * 0.11))
                                        font.weight: Font.Bold
                                        font.bold: true
                                        font.letterSpacing: 0.5
                                        color: "#ffffff"
                                        visible: false
                                    }

                                    Text {
                                        id: prevDateLabel
                                        anchors.centerIn: parent
                                        text: Qt.formatDate(new Date(), "ddd MMM d")
                                        font.family: root.activeClockFontFamily
                                        font.pixelSize: Math.max(10, Math.round(root.clockFontSize * 0.11))
                                        font.weight: Font.Bold
                                        font.bold: true
                                        font.letterSpacing: 0.5
                                        color: Qt.rgba(1, 1, 1, 0.15)
                                    }
                                }

                                // Frosted Clock Digits
                                Item {
                                    id: prevGlassClock
                                    width: prevTimeMaskText.implicitWidth
                                    height: prevTimeMaskText.implicitHeight
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Item {
                                        anchors.fill: parent
                                        layer.enabled: true
                                        layer.effect: OpacityMask { maskSource: prevTimeMaskText }

                                        Image {
                                            width: heroLockWallImg.width
                                            height: heroLockWallImg.height
                                            x: -prevGlassClock.x - (prevClockCol.x)
                                            y: -prevGlassClock.y - (prevClockCol.y)
                                            source: heroLockWallImg.source
                                            fillMode: Image.PreserveAspectCrop
                                            smooth: true

                                            layer.enabled: true
                                            layer.effect: FastBlur {
                                                radius: Math.max(10, Math.round(root.clockBlurRadius * 0.65))
                                                cached: true
                                            }
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            gradient: Gradient {
                                                orientation: Gradient.Vertical
                                                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, (root.glassSheen / 100.0)) }
                                                GradientStop { position: 0.4; color: Qt.rgba(1, 1, 1, (root.glassSheen / 100.0) * 0.38) }
                                                GradientStop { position: 0.8; color: Qt.rgba(1, 1, 1, (root.glassSheen / 100.0) * 0.25) }
                                                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, (root.glassSheen / 100.0) * 0.65) }
                                            }
                                        }
                                    }

                                    Text {
                                        id: prevTimeMaskText
                                        anchors.centerIn: parent
                                        text: {
                                            if (root.use24h) return Qt.formatTime(new Date(), "hh:mm");
                                            let d = new Date();
                                            let h = d.getHours() % 12 || 12;
                                            let m = d.getMinutes();
                                            return h + ":" + (m < 10 ? "0" + m : m);
                                        }
                                        font.family: root.activeClockFontFamily
                                        font.pixelSize: Math.round(root.clockFontSize * 0.45)
                                        font.weight: Font.ExtraBold
                                        font.bold: true
                                        font.letterSpacing: -1.2
                                        color: "#ffffff"
                                        visible: false
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
                                        font.family: root.activeClockFontFamily
                                        font.pixelSize: Math.round(root.clockFontSize * 0.45)
                                        font.weight: Font.ExtraBold
                                        font.bold: true
                                        font.letterSpacing: -1.2
                                        color: Qt.rgba(1, 1, 1, 0.12)
                                    }
                                }
                            }

                            // Frosted Glass Avatar & Interactive Slide-Up Login Section
                            Column {
                                id: prevLoginCol
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: root.isPreviewUnlocked ? 28 : 12
                                Behavior on anchors.bottomMargin { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: root.isPreviewUnlocked ? 6 : 4
                                Behavior on spacing { NumberAnimation { duration: 250 } }

                                // ── Preview Frosted Glass Notification Pod (Above Avatar) ──
                                Item {
                                    id: prevNotifPod
                                    visible: root.showNotifications && !root.isPreviewUnlocked
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 190
                                    height: 38
                                    opacity: root.showNotifications && !root.isPreviewUnlocked ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 250 } }

                                    Item {
                                        anchors.fill: parent
                                        layer.enabled: true
                                        layer.effect: OpacityMask { maskSource: prevNotifMask }

                                        Image {
                                            width: heroLockWallImg.width
                                            height: heroLockWallImg.height
                                            x: -(heroLockWallImg.width - prevNotifPod.width) / 2
                                            y: -(prevLoginCol.y + prevNotifPod.y)
                                            source: heroLockWallImg.source
                                            fillMode: Image.PreserveAspectCrop
                                            smooth: true

                                            layer.enabled: true
                                            layer.effect: FastBlur {
                                                radius: Math.max(8, Math.round(root.clockBlurRadius * 0.5))
                                                cached: true
                                            }
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            gradient: Gradient {
                                                orientation: Gradient.Vertical
                                                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, (root.glassSheen / 100.0) * 0.35) }
                                                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, (root.glassSheen / 100.0) * 0.15) }
                                                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, (root.glassSheen / 100.0) * 0.25) }
                                            }
                                            border.width: 1.5
                                            border.color: Qt.rgba(255, 255, 255, 0.40)
                                            radius: 12
                                        }
                                    }

                                    Rectangle {
                                        id: prevNotifMask
                                        anchors.fill: parent
                                        radius: 12
                                        visible: false
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        spacing: 6

                                        Rectangle {
                                            width: 22; height: 22; radius: 11
                                            color: Qt.rgba(1, 1, 1, 0.20)
                                            Text { anchors.centerIn: parent; text: "💬"; font.pixelSize: 11 }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 0
                                            RowLayout {
                                                Layout.fillWidth: true
                                                Text { text: "Messages • Antigravity"; font.family: Theme.defaultFontFamily; font.pixelSize: 9; font.weight: Font.Bold; color: "#ffffff"; elide: Text.ElideRight; Layout.fillWidth: true }
                                                Text { text: "now"; font.family: Theme.defaultFontFamily; font.pixelSize: 8; color: Qt.rgba(1, 1, 1, 0.65) }
                                            }
                                            Text { text: "Ready to pair program with you!"; font.family: Theme.defaultFontFamily; font.pixelSize: 8; color: Qt.rgba(1, 1, 1, 0.85); elide: Text.ElideRight; Layout.fillWidth: true }
                                        }
                                    }
                                }

                                Rectangle {
                                    id: prevAvatarCircle
                                    visible: root.showAvatar
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: root.isPreviewUnlocked ? 30 : 34
                                    height: width
                                    radius: width / 2
                                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                    color: Qt.rgba(255, 255, 255, 0.25)
                                    border.width: 2.0; border.color: Qt.rgba(255, 255, 255, 0.65)

                                    Rectangle {
                                        id: prevAvatarMask
                                        anchors.fill: parent
                                        radius: prevAvatarCircle.radius
                                        visible: false
                                    }

                                    Item {
                                        anchors.fill: parent
                                        anchors.margins: 2.0
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
                                    text: root.currentRealName
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
                                        border.width: 1.5; border.color: Qt.rgba(255, 255, 255, 0.50)
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
                                    height: 20; radius: 10
                                    width: sddmBadgeRow.implicitWidth + 14
                                    color: Qt.rgba(0, 0, 0, 0.45)
                                    border.width: 1.5; border.color: Qt.rgba(255, 255, 255, 0.35)
                                    RowLayout {
                                        id: sddmBadgeRow; anchors.centerIn: parent; spacing: 4
                                        Text { text: "\ueae2"; font.family: "tabler-icons"; font.pixelSize: 10; color: Theme.colPrimary }
                                        Text { text: "SDDM & LOCK"; font.family: Theme.defaultFontFamily; font.pixelSize: 9; font.weight: Font.Bold; color: "#ffffff" }
                                    }
                                }
                            }

                            // Top Right: Frosted Glass Session Pill
                            Rectangle {
                                visible: root.showSession
                                anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 12
                                height: 20; radius: 10
                                width: prevSessionRow.implicitWidth + 14
                                color: Qt.rgba(255, 255, 255, 0.15)
                                border.width: 1.5; border.color: Qt.rgba(255, 255, 255, 0.45)
                                RowLayout {
                                    id: prevSessionRow; anchors.centerIn: parent; spacing: 4
                                    Text { text: "🖥"; font.pixelSize: 8 }
                                    Text { text: "Hyprland"; font.family: Theme.defaultFontFamily; font.pixelSize: 9; font.weight: Font.Medium; color: "#ffffff" }
                                }
                            }

                            // Bottom Right: Frosted Glass Power Buttons
                            Row {
                                visible: root.showPower
                                anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: 12
                                spacing: 6

                                Rectangle {
                                    width: 22; height: 22; radius: 11
                                    color: Qt.rgba(255, 255, 255, 0.15)
                                    border.width: 1.5; border.color: Qt.rgba(255, 255, 255, 0.45)
                                    Text { anchors.centerIn: parent; text: "🔄"; font.pixelSize: 8 }
                                }

                                Rectangle {
                                    width: 22; height: 22; radius: 11
                                    color: Qt.rgba(255, 255, 255, 0.15)
                                    border.width: 1.5; border.color: Qt.rgba(255, 255, 255, 0.45)
                                    Text { anchors.centerIn: parent; text: "⏻"; font.pixelSize: 9; color: "#ffffff" }
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

            // ── 2. FROSTED GLASS & BLUR CUSTOMIZATION ─────────────────────
            NCard {
                sectionTitle: "Frosted glass & blur effects"

                // Clock Frosted Blur Radius
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb04" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Clock & date backdrop blur"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Controls the optical blur radius behind the clock and date characters (" + root.clockBlurRadius + "px)"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledSlider {
                        implicitWidth: 160
                        from: 0
                        to: 64
                        stepSize: 2
                        value: root.clockBlurRadius
                        onMoved: {
                            root.clockBlurRadius = Math.round(value);
                            root.saveLockSettings();
                        }
                    }
                }

                // Wallpaper Blur on Unlock
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb29" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Wallpaper blur on unlock prompt"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Smooth depth-of-field blur applied to the wallpaper when sliding up (" + root.bgBlurRadius + "px)"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledSlider {
                        implicitWidth: 160
                        from: 0
                        to: 80
                        stepSize: 2
                        value: root.bgBlurRadius
                        onMoved: {
                            root.bgBlurRadius = Math.round(value);
                            root.saveLockSettings();
                        }
                    }
                }

                // Glass Sheen & Reflection
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea6d" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Glass reflection intensity"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Adjusts the specular gradient sheen and glassy opacity (" + root.glassSheen + "%)"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledSlider {
                        implicitWidth: 160
                        from: 10
                        to: 90
                        stepSize: 2
                        value: root.glassSheen
                        onMoved: {
                            root.glassSheen = Math.round(value);
                            root.saveLockSettings();
                        }
                    }
                }
            }

            // ── 3. TYPOGRAPHY & CLOCK STYLE ───────────────────────────────
            NCard {
                sectionTitle: "Typography & clock style"

                // Clock Font Family Selector
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    NRow {
                        RowLayout {
                            spacing: 12
                            NIconBadge { icon: "\ueaf4" }
                            ColumnLayout {
                                spacing: 1
                                Text { text: "Clock font preset"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                                Text { text: "Choose from authentic astronaut themes and modern clean sans typefaces"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                            }
                        }
                    }

                    // Font Preset Cards Grid
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // 1. Open Sans Bold (Astronaut Theme)
                        Rectangle {
                            Layout.fillWidth: true
                            height: 48; radius: 10
                            color: root.clockFontFile.indexOf("OpenSans") !== -1 ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.18) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            border.width: 1.5
                            border.color: root.clockFontFile.indexOf("OpenSans") !== -1 ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 2
                                Text { text: "Open Sans Bold"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.Bold; color: root.clockFontFile.indexOf("OpenSans") !== -1 ? Theme.colPrimary : Theme.colOnSurface }
                                Text { text: "Astronaut Signature"; font.family: Theme.defaultFontFamily; font.pixelSize: 9; color: Theme.colOnSurfaceVariant; opacity: 0.8 }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.clockFontFile = "OpenSans-Bold.ttf";
                                    root.saveLockSettings();
                                }
                            }
                        }

                        // 2. Orbitron (Astronaut Sci-Fi)
                        Rectangle {
                            Layout.fillWidth: true
                            height: 48; radius: 10
                            color: root.clockFontFile === "Orbitron-Black.ttf" ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.18) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            border.width: 1.5
                            border.color: root.clockFontFile === "Orbitron-Black.ttf" ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 2
                                Text { text: "Orbitron"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.Bold; color: root.clockFontFile === "Orbitron-Black.ttf" ? Theme.colPrimary : Theme.colOnSurface }
                                Text { text: "Sci-Fi Cyber"; font.family: Theme.defaultFontFamily; font.pixelSize: 9; color: Theme.colOnSurfaceVariant; opacity: 0.8 }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.clockFontFile = "Orbitron-Black.ttf";
                                    root.saveLockSettings();
                                }
                            }
                        }

                        // 3. Inter Display (Modern Swiss)
                        Rectangle {
                            Layout.fillWidth: true
                            height: 48; radius: 10
                            color: root.clockFontFile === "Inter Display" ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.18) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            border.width: 1.5
                            border.color: root.clockFontFile === "Inter Display" ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 2
                                Text { text: "Inter Display"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.Bold; color: root.clockFontFile === "Inter Display" ? Theme.colPrimary : Theme.colOnSurface }
                                Text { text: "Clean Swiss"; font.family: Theme.defaultFontFamily; font.pixelSize: 9; color: Theme.colOnSurfaceVariant; opacity: 0.8 }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.clockFontFile = "Inter Display";
                                    root.saveLockSettings();
                                }
                            }
                        }

                        // 4. Pixelon (Retro Arcade)
                        Rectangle {
                            Layout.fillWidth: true
                            height: 48; radius: 10
                            color: root.clockFontFile === "pixelon.regular.ttf" ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.18) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            border.width: 1.5
                            border.color: root.clockFontFile === "pixelon.regular.ttf" ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 2
                                Text { text: "Pixelon"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.Bold; color: root.clockFontFile === "pixelon.regular.ttf" ? Theme.colPrimary : Theme.colOnSurface }
                                Text { text: "8-Bit Retro"; font.family: Theme.defaultFontFamily; font.pixelSize: 9; color: Theme.colOnSurfaceVariant; opacity: 0.8 }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.clockFontFile = "pixelon.regular.ttf";
                                    root.saveLockSettings();
                                }
                            }
                        }
                    }
                }

                // Clock Font Size
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueaf4" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Clock font size"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Display scale for lockscreen clock numbers (" + root.clockFontSize + "px)"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledSlider {
                        implicitWidth: 160
                        from: 80
                        to: 160
                        stepSize: 4
                        value: root.clockFontSize
                        onMoved: {
                            root.clockFontSize = Math.round(value);
                            root.saveLockSettings();
                        }
                    }
                }

                // Time Format 12h / 24h
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
                                        root.saveLockSettings();
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
                                        root.saveLockSettings();
                                    }
                                }
                            }
                        }
                    }
                }

                // Show Date & Month
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea53" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Show date & day"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Display frosted date header above clock digits"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.showDate
                        onToggled: {
                            root.showDate = checked;
                            root.saveLockSettings();
                        }
                    }
                }
            }

            // ── 4. SDDM & LOCKSCREEN COMPONENT TOGGLES ────────────────────
            NCard {
                sectionTitle: "Component customization"

                // Show Notifications Pod (Above Avatar)
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea35" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Lock screen notifications"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Display frosted glass notification cards right before user profile avatar"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.showNotifications
                        onToggled: {
                            root.showNotifications = checked;
                            root.saveLockSettings();
                        }
                    }
                }

                // Show Session Switcher (SDDM only)
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb2b" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Session switcher pill"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Show top-right frosted glass capsule for session selection on SDDM startup"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.showSession
                        onToggled: {
                            root.showSession = checked;
                            root.saveLockSettings();
                        }
                    }
                }

                // Show Power Controls (SDDM only)
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb0d" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Power & reboot buttons"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Display bottom-right frosted glass restart and shutdown action discs on SDDM"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.showPower
                        onToggled: {
                            root.showPower = checked;
                            root.saveLockSettings();
                        }
                    }
                }

                // Show User Avatar
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb4d" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "User profile avatar"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Show user profile picture in frosted glass circular ring"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: root.showAvatar
                        onToggled: {
                            root.showAvatar = checked;
                            root.saveLockSettings();
                        }
                    }
                }
            }

            // ── 5. WALLPAPER & AUTO-LOCK ──────────────────────────────────
            NCard {
                sectionTitle: "Wallpaper synchronization & security"

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
