import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../../theme"
import Quickshell
import Quickshell.Io
import "../common"

Item {
    id: root

    Process { id: bashProcess }

    // Read saved configuration state
    Process {
        id: initBarSettings
        command: ["bash", "-c", "cat ~/.config/cupcake/.bar_monitors 2>/dev/null; echo '---'; cat ~/.config/cupcake/.bar_dropdown_style 2>/dev/null; echo '---'; cat ~/.config/cupcake/.bar_transparency 2>/dev/null; echo '---'; cat ~/.config/cupcake/.bar_opacity 2>/dev/null; echo '---'; cat ~/.config/cupcake/.hide_island 2>/dev/null; echo '---'; cat ~/.config/cupcake/.clock_24h 2>/dev/null; echo '---'; cat ~/.config/cupcake/.clock_show_seconds 2>/dev/null; echo '---'; cat ~/.cache/current_wallpaper 2>/dev/null; echo '---'; cat ~/.config/cupcake/.bar_position 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    let parts = text.trim().split('---');
                    if (parts[0]) root.barMonitors = parts[0].trim() !== "" ? parts[0].trim() : "all";
                    if (parts[1] && parts[1].trim() !== "") root.dropdownStyle = parts[1].trim();
                    if (parts[2]) root.barTransparency = (parts[2].trim() !== "false");
                    if (parts[3] && parts[3].trim() !== "") {
                        let v = parseFloat(parts[3].trim());
                        if (!isNaN(v)) root.barOpacity = v;
                    }
                    if (parts[4]) root.hideIsland = (parts[4].trim() === "true");
                    if (parts[5]) root.clock24h = (parts[5].trim() !== "false");
                    if (parts[6]) root.showSeconds = (parts[6].trim() === "true");
                    if (parts[7] && parts[7].trim() !== "") root.wallpaperPath = parts[7].trim();
                    if (parts[8] && parts[8].trim() !== "") root.barPosition = parts[8].trim();
                }
            }
        }
    }

    // State properties
    property bool barEnabled: true
    property string barPosition: "Above" // "Above", "Below", "Left", "Right"
    property string barMonitors: "all"
    property string dropdownStyle: Theme.barDropdownStyle !== "" ? Theme.barDropdownStyle : "Detached"
    property bool barTransparency: true
    property real barOpacity: 0.50
    property bool hideIsland: false
    property bool clock24h: true
    property bool showSeconds: false
    property string wallpaperPath: ""
    property string currentTimeStr: ""

    function getWallpaperPreviewSource(path) {
        if (!path) return "";
        let trimmed = path.trim();
        if (trimmed === "") return "";
        let isVideo = [".mp4", ".webm", ".mkv", ".mov", ".gif"].some(ext => trimmed.toLowerCase().endsWith(ext));
        if (isVideo) {
            let parts = trimmed.split('/');
            let fname = parts[parts.length - 1];
            return "file://" + Quickshell.env("HOME") + "/.cache/cupcake/wall_thumbs/" + fname + ".png";
        }
        return "file://" + trimmed;
    }

    // Live clock updater
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let d = new Date();
            let fmt = root.clock24h ? (root.showSeconds ? "hh:mm:ss" : "hh:mm") : (root.showSeconds ? "hh:mm:ss AP" : "hh:mm AP");
            root.currentTimeStr = Qt.formatDateTime(d, fmt);
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.topMargin: 16
        anchors.bottomMargin: 20
        contentWidth: width
        contentHeight: mainCol.implicitHeight + 40
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainCol
            width: parent.width
            spacing: 16

            // ── 1. HEADER ROW: Apply / Reset Actions ───────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Item { Layout.fillWidth: true }

                // Apply Button
                Rectangle {
                    height: 32
                    width: applyBtnText.implicitWidth + 28
                    radius: 8
                    color: applyMa.containsMouse ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.16) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
                    border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        id: applyBtnText
                        anchors.centerIn: parent
                        text: "Apply"
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Theme.colOnSurface
                    }

                    MouseArea {
                        id: applyMa
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["bash", "-c", "echo '" + root.barPosition + "' > ~/.config/cupcake/.bar_position && echo '" + root.dropdownStyle + "' > ~/.config/cupcake/.bar_dropdown_style && echo '" + root.barTransparency + "' > ~/.config/cupcake/.bar_transparency && echo '" + root.barOpacity.toFixed(2) + "' > ~/.config/cupcake/.bar_opacity && echo '" + root.hideIsland + "' > ~/.config/cupcake/.hide_island && echo '" + root.clock24h + "' > ~/.config/cupcake/.clock_24h && echo '" + root.showSeconds + "' > ~/.config/cupcake/.clock_show_seconds && ~/.local/bin/apply-transparency"]);
                            statusCaptionAnim.restart();
                        }
                    }
                }

                // Reset Button
                Rectangle {
                    height: 32
                    width: resetBtnText.implicitWidth + 28
                    radius: 8
                    color: resetMa.containsMouse ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                    border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.1)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        id: resetBtnText
                        anchors.centerIn: parent
                        text: "Reset"
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Theme.colOnSurfaceVariant
                    }

                    MouseArea {
                        id: resetMa
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.barPosition = "Above";
                            root.dropdownStyle = "Detached";
                            Theme.barDropdownStyle = "Detached";
                            root.barTransparency = true;
                            root.barOpacity = 0.50;
                            root.hideIsland = false;
                            globalState.hideIsland = false;
                            Quickshell.execDetached(["bash", "-c", "echo 'Detached' > ~/.config/cupcake/.bar_dropdown_style && echo 'true' > ~/.config/cupcake/.bar_transparency && echo '0.50' > ~/.config/cupcake/.bar_opacity && echo 'false' > ~/.config/cupcake/.hide_island && ~/.local/bin/apply-transparency"]);
                        }
                    }
                }
            }

            // ── 2. FULL LIVE CUPCAKE BAR PREVIEW CANVAS ───────────────────
            Rectangle {
                id: previewFrame
                Layout.fillWidth: true
                height: 380
                radius: 18
                color: "#121316"
                border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                border.width: 1

                // Rounded corner mask to ensure 100% smooth clipping on all backends
                Rectangle {
                    id: previewMask
                    anchors.fill: parent
                    radius: 18
                    visible: false
                    layer.enabled: true
                }

                Item {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: previewMask
                    }

                    // Background wallpaper image / poster
                    Image {
                        id: wallImg
                        anchors.fill: parent
                        source: root.getWallpaperPreviewSource(root.wallpaperPath)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: 0.88
                        onStatusChanged: {
                            if (status === Image.Error && root.wallpaperPath) {
                                let parts = root.wallpaperPath.split('/');
                                let fname = parts[parts.length - 1];
                                let altSource = "file://" + Quickshell.env("HOME") + "/.cache/cupcake/wall_thumbs/" + fname;
                                if (source.toString() !== altSource) {
                                    source = altSource;
                                }
                            }
                        }
                    }

                    // Fallback / artistic gradient backdrop matching reference screenshot
                    Rectangle {
                        anchors.fill: parent
                        visible: !wallImg.visible || wallImg.status !== Image.Ready
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#16384C" }
                            GradientStop { position: 0.45; color: "#544642" }
                            GradientStop { position: 0.80; color: "#8E2B24" }
                            GradientStop { position: 1.0; color: "#2B1115" }
                        }

                        Canvas {
                            anchors.fill: parent
                            opacity: 0.18
                            onPaint: {
                                let ctx = getContext("2d");
                                ctx.strokeStyle = "rgba(255,255,255,0.4)";
                                ctx.lineWidth = 1;
                                for (let x = -400; x < width + 400; x += 8) {
                                    ctx.beginPath();
                                    ctx.moveTo(x, 0);
                                    ctx.lineTo(x + 400, height);
                                    ctx.stroke();
                                }
                            }
                        }
                    }

                    // Inner dark vignette for realistic depth
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.color: Qt.rgba(0, 0, 0, 0.4)
                        border.width: 1
                    }
                }

                // ── LIVE FULL-WIDTH CUPCAKE SOLID BAR ──────────────────────
                Rectangle {
                    id: liveBar
                    x: root.barPosition === "Right" ? (parent.width - width - 14) : 14
                    y: root.barPosition === "Below" ? (parent.height - height - 14) : 14
                    width: (root.barPosition === "Left" || root.barPosition === "Right") ? 32 : (root.barPosition === "Below" ? (parent.width - 28) : (parent.width - 28 - (root.hideIsland ? 0 : 136)))
                    height: (root.barPosition === "Left" || root.barPosition === "Right") ? (parent.height - 28) : 32
                    radius: 16

                    color: root.barTransparency
                           ? Qt.rgba(Theme.colSurfaceContainer.r, Theme.colSurfaceContainer.g, Theme.colSurfaceContainer.b, root.barOpacity)
                           : Theme.colSurfaceContainer
                    border.color: Qt.rgba(255, 255, 255, 0.12)
                    border.width: 1

                    Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 250 } }

                    // Horizontal Solid Bar Content Layout
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        visible: root.barPosition === "Above" || root.barPosition === "Below"
                        spacing: 8

                        // Workspaces halo dots
                        Row {
                            spacing: 6
                            Layout.alignment: Qt.AlignVCenter

                            Rectangle {
                                width: 14; height: 6; radius: 3
                                color: Theme.colPrimary
                            }
                            Rectangle {
                                width: 5; height: 5; radius: 2.5
                                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.35)
                            }
                            Rectangle {
                                width: 5; height: 5; radius: 2.5
                                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.35)
                            }
                        }

                        // Active Window Title
                        Text {
                            text: "Cupcake Settings"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.55)
                            Layout.alignment: Qt.AlignVCenter
                            Layout.leftMargin: 4
                            elide: Text.ElideRight
                            Layout.maximumWidth: 160
                        }

                        // Center: Cupcake Logo (when Above) / Dock Icons (when Below)
                        Item {
                            Layout.alignment: Qt.AlignVCenter
                            width: root.barPosition === "Below" ? 110 : 50
                            height: 24
                            clip: true
                            Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

                            Text {
                                anchors.centerIn: parent
                                y: root.barPosition === "Below" ? -28 : ((parent.height - height) / 2)
                                text: "🧁 cupcake"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: Theme.colPrimary
                                opacity: root.barPosition === "Below" ? 0.0 : 0.85
                                Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                                Behavior on opacity { NumberAnimation { duration: 250 } }
                            }

                            Row {
                                anchors.centerIn: parent
                                y: root.barPosition === "Below" ? ((parent.height - height) / 2) : 28
                                opacity: root.barPosition === "Below" ? 1.0 : 0.0
                                spacing: 5
                                Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                                Behavior on opacity { NumberAnimation { duration: 250 } }

                                Rectangle { width: 18; height: 18; radius: 9; color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.2); Text { anchors.centerIn: parent; text: "\uebb6"; font.family: "tabler-icons"; font.pixelSize: 10; color: Theme.colPrimary } }
                                Rectangle { width: 18; height: 18; radius: 4; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12); Text { anchors.centerIn: parent; text: "🌐"; font.pixelSize: 10 } }
                                Rectangle { width: 18; height: 18; radius: 4; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12); Text { anchors.centerIn: parent; text: ">_"; font.pixelSize: 8; color: Theme.colPrimary } }
                                Rectangle { width: 18; height: 18; radius: 4; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12); Text { anchors.centerIn: parent; text: "📁"; font.pixelSize: 10 } }
                            }
                        }

                        // Spacer
                        Item { Layout.fillWidth: true }

                        // ── Right Side Status Controls ─────────────────────
                        RowLayout {
                            spacing: 7
                            Layout.alignment: Qt.AlignVCenter

                            // Wi-Fi
                            Text {
                                text: "\ueb52"
                                font.family: "tabler-icons"
                                font.pixelSize: 13
                                color: Theme.colOnSurface
                                opacity: 0.85
                            }

                            // Network Speed
                            Text {
                                text: "1.2 MB/s"
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 10
                                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.7)
                            }

                            // Dot Separator
                            Rectangle { width: 3; height: 3; radius: 1.5; color: Theme.colOnSurface; opacity: 0.25 }

                            // Volume
                            RowLayout {
                                spacing: 3
                                Text {
                                    text: "\ueb51"
                                    font.family: "tabler-icons"
                                    font.pixelSize: 13
                                    color: Theme.colOnSurface
                                    opacity: 0.85
                                }
                                Text {
                                    text: "65%"
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 10
                                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.7)
                                }
                            }

                            // Dot Separator
                            Rectangle { width: 3; height: 3; radius: 1.5; color: Theme.colOnSurface; opacity: 0.25 }

                            // Battery
                            RowLayout {
                                spacing: 3
                                Text {
                                    text: "\uef3b"
                                    font.family: "tabler-icons"
                                    font.pixelSize: 13
                                    color: Theme.colOnSurface
                                    opacity: 0.85
                                }
                                Text {
                                    text: "98%"
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 10
                                    color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.7)
                                }
                            }

                            // Clipboard
                            Text {
                                text: "\uea6d"
                                font.family: "tabler-icons"
                                font.pixelSize: 13
                                color: Theme.colOnSurface
                                opacity: 0.85
                            }

                            // Dot Separator
                            Rectangle { width: 3; height: 3; radius: 1.5; color: Theme.colOnSurface; opacity: 0.25 }

                            // Real-time Live Clock
                            Text {
                                text: root.currentTimeStr !== "" ? root.currentTimeStr : (root.clock24h ? "22:25" : "10:25 PM")
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: Theme.colOnSurface
                            }

                            // Dot Separator
                            Rectangle { width: 3; height: 3; radius: 1.5; color: Theme.colOnSurface; opacity: 0.25 }

                            // Power Button
                            Text {
                                text: "\ueb2c"
                                font.family: "tabler-icons"
                                font.pixelSize: 13
                                color: Theme.colOnSurface
                                opacity: 0.85
                            }
                        }
                    }

                    // Vertical Bar Content Layout (for Left / Right orientation)
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: 10
                        anchors.bottomMargin: 10
                        visible: root.barPosition === "Left" || root.barPosition === "Right"
                        spacing: 8

                        Text { text: "🧁"; font.pixelSize: 12; Layout.alignment: Qt.AlignHCenter }
                        Rectangle { width: 6; height: 14; radius: 3; color: Theme.colPrimary; Layout.alignment: Qt.AlignHCenter }
                        Item { Layout.fillHeight: true }
                        Text { text: "\ueb52"; font.family: "tabler-icons"; font.pixelSize: 12; color: Theme.colOnSurface; Layout.alignment: Qt.AlignHCenter }
                        Text { text: "\ueb51"; font.family: "tabler-icons"; font.pixelSize: 12; color: Theme.colOnSurface; Layout.alignment: Qt.AlignHCenter }
                        Text { text: "\ueb2c"; font.family: "tabler-icons"; font.pixelSize: 12; color: Theme.colOnSurface; Layout.alignment: Qt.AlignHCenter }
                    }
                }

                // ── LIVE NOTIFICATION ISLAND CAPSULE (Right Side) ─────────
                Rectangle {
                    x: parent.width - width - 14
                    y: 14
                    width: 120
                    height: 32
                    radius: 16
                    visible: !root.hideIsland
                    color: root.barTransparency
                           ? Qt.rgba(Theme.colSurfaceContainer.r, Theme.colSurfaceContainer.g, Theme.colSurfaceContainer.b, root.barOpacity)
                           : Theme.colSurfaceContainer
                    border.color: Qt.rgba(255, 255, 255, 0.12)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 6

                        Rectangle { width: 5; height: 5; radius: 2.5; color: "#E5C07B" }
                        Text {
                            text: "SCREENSHOT"
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.65)
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            // ── 3. STATUS CAPTION ─────────────────────────────────────────
            Text {
                id: statusCaption
                text: "All changes applied"
                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.4)
                font.family: Theme.monoFontFamily
                font.pixelSize: 11
                Layout.leftMargin: 4

                SequentialAnimation {
                    id: statusCaptionAnim
                    PropertyAction { target: statusCaption; property: "text"; value: "Applying changes..." }
                    PropertyAction { target: statusCaption; property: "color"; value: Theme.colPrimary }
                    PauseAnimation { duration: 600 }
                    PropertyAction { target: statusCaption; property: "text"; value: "All changes applied" }
                    PropertyAction { target: statusCaption; property: "color"; value: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.4) }
                }
            }

            // ── 4. SCREEN POSITION SELECTOR CARD ──────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 160
                radius: 16
                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.12)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    Text {
                        text: "SCREEN POSITION"
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.45)
                        font.family: Theme.monoFontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.0
                    }

                    // 4 Position Selectors (Above, Below, Left, Right)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // 1. Above
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 68
                            radius: 10
                            color: root.barPosition === "Above" ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04)
                            border.color: root.barPosition === "Above" ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.1)
                            border.width: root.barPosition === "Above" ? 2 : 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                Rectangle {
                                    width: 28; height: 18; radius: 3
                                    color: "transparent"
                                    border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.18)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignHCenter

                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 14; height: 3; radius: 1.5
                                        color: root.barPosition === "Above" ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.4)
                                    }
                                }
                                Text {
                                    text: "Above"
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 11
                                    font.weight: root.barPosition === "Above" ? Font.Bold : Font.Normal
                                    color: root.barPosition === "Above" ? Theme.colOnSurface : Theme.colOnSurfaceVariant
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.barPosition = "Above";
                                    Theme.barPosition = "Above";
                                    Quickshell.execDetached(["bash", "-c", "echo 'Above' > ~/.config/cupcake/.bar_position"]);
                                }
                            }
                        }

                        // 2. Below
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 68
                            radius: 10
                            color: root.barPosition === "Below" ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04)
                            border.color: root.barPosition === "Below" ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.1)
                            border.width: root.barPosition === "Below" ? 2 : 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                Rectangle {
                                    width: 28; height: 18; radius: 3
                                    color: "transparent"
                                    border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.18)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignHCenter

                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 14; height: 3; radius: 1.5
                                        color: root.barPosition === "Below" ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.4)
                                    }
                                }
                                Text {
                                    text: "Below"
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 11
                                    font.weight: root.barPosition === "Below" ? Font.Bold : Font.Normal
                                    color: root.barPosition === "Below" ? Theme.colOnSurface : Theme.colOnSurfaceVariant
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.barPosition = "Below";
                                    Theme.barPosition = "Below";
                                    Quickshell.execDetached(["bash", "-c", "echo 'Below' > ~/.config/cupcake/.bar_position"]);
                                }
                            }
                        }

                        // 3. Left
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 68
                            radius: 10
                            color: root.barPosition === "Left" ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04)
                            border.color: root.barPosition === "Left" ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.1)
                            border.width: root.barPosition === "Left" ? 2 : 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                Rectangle {
                                    width: 28; height: 18; radius: 3
                                    color: "transparent"
                                    border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.18)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignHCenter

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 3; height: 12; radius: 1.5
                                        color: root.barPosition === "Left" ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.4)
                                    }
                                }
                                Text {
                                    text: "Left"
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 11
                                    font.weight: root.barPosition === "Left" ? Font.Bold : Font.Normal
                                    color: root.barPosition === "Left" ? Theme.colOnSurface : Theme.colOnSurfaceVariant
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.barPosition = "Left"
                            }
                        }

                        // 4. Right
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 68
                            radius: 10
                            color: root.barPosition === "Right" ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04)
                            border.color: root.barPosition === "Right" ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.1)
                            border.width: root.barPosition === "Right" ? 2 : 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                Rectangle {
                                    width: 28; height: 18; radius: 3
                                    color: "transparent"
                                    border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.18)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignHCenter

                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 3; height: 12; radius: 1.5
                                        color: root.barPosition === "Right" ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.4)
                                    }
                                }
                                Text {
                                    text: "Right"
                                    font.family: Theme.defaultFontFamily
                                    font.pixelSize: 11
                                    font.weight: root.barPosition === "Right" ? Font.Bold : Font.Normal
                                    color: root.barPosition === "Right" ? Theme.colOnSurface : Theme.colOnSurfaceVariant
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.barPosition = "Right"
                            }
                        }
                    }

                    Text {
                        text: "It always opens towards the centre."
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.35)
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 11
                    }
                }
            }

            // ── 5. ADDITIONAL CONTROLS: STYLE & DYNAMIC ISLAND ────────────
            NCard {
                sectionTitle: "Dropdown Style & Dynamic Island"

                NRow {
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "Dropdown Menus Style"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Theme.colOnSurface
                        }
                        Text {
                            text: "Attached tab vs floating detached magnetic pods"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            color: Theme.colOnSurfaceVariant
                        }
                    }

                    RowLayout {
                        spacing: 6

                        Rectangle {
                            height: 30
                            width: attTxt.implicitWidth + 20
                            radius: 8
                            color: root.dropdownStyle === "Attached" ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                id: attTxt
                                anchors.centerIn: parent
                                text: "Attached"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: root.dropdownStyle === "Attached" ? Theme.colOnPrimary : Theme.colOnSurfaceVariant
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.dropdownStyle = "Attached";
                                    Theme.barDropdownStyle = "Attached";
                                    Quickshell.execDetached(["bash", "-c", "echo 'Attached' > ~/.config/cupcake/.bar_dropdown_style"]);
                                }
                            }
                        }

                        Rectangle {
                            height: 30
                            width: detTxt.implicitWidth + 20
                            radius: 8
                            color: root.dropdownStyle === "Detached" ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                id: detTxt
                                anchors.centerIn: parent
                                text: "Detached"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: root.dropdownStyle === "Detached" ? Theme.colOnPrimary : Theme.colOnSurfaceVariant
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.dropdownStyle = "Detached";
                                    Theme.barDropdownStyle = "Detached";
                                    Quickshell.execDetached(["bash", "-c", "echo 'Detached' > ~/.config/cupcake/.bar_dropdown_style"]);
                                }
                            }
                        }
                    }
                }

                NRow {
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "Dynamic Island Notification Pill"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Theme.colOnSurface
                        }
                        Text {
                            text: "Show morphing notification capsule on the right side of the bar"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            color: Theme.colOnSurfaceVariant
                        }
                    }

                    NToggle {
                        checked: !root.hideIsland
                        onToggled: (val) => {
                            root.hideIsland = !val;
                            globalState.hideIsland = !val;
                            Quickshell.execDetached(["bash", "-c", "echo " + (!val) + " > ~/.config/cupcake/.hide_island"]);
                        }
                    }
                }
            }

            // ── 6. TRANSPARENCY & OPACITY ─────────────────────────────
            NCard {
                sectionTitle: "Transparency & Opacity"

                NRow {
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "Bar Transparency"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Theme.colOnSurface
                        }
                        Text {
                            text: "Enable translucency for the status bar and island"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            color: Theme.colOnSurfaceVariant
                        }
                    }

                    NToggle {
                        checked: root.barTransparency
                        onToggled: (val) => {
                            root.barTransparency = val;
                            Theme.barTransparency = val;
                            Quickshell.execDetached(["bash", "-c", "echo " + val + " > ~/.config/cupcake/.bar_transparency && ~/.local/bin/apply-transparency"]);
                        }
                    }
                }

                NRow {
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "Bar Opacity"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Theme.colOnSurface
                        }
                        Text {
                            text: "Adjust background fill opacity (" + Math.round(root.barOpacity * 100) + "%)"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            color: Theme.colOnSurfaceVariant
                        }
                    }

                    StyledSlider {
                        Layout.preferredWidth: 220
                        from: 0.1; to: 1.0; stepSize: 0.05
                        value: root.barOpacity
                        onMoved: {
                            root.barOpacity = value;
                            Theme.barOpacity = value;
                            Quickshell.execDetached(["bash", "-c", "echo '" + value.toFixed(2) + "' > ~/.config/cupcake/.bar_opacity"]);
                        }
                        onValueChanged: {
                            root.barOpacity = value;
                            Theme.barOpacity = value;
                        }
                        onPressedChanged: {
                            if (!pressed) {
                                Quickshell.execDetached(["bash", "-c", "echo '" + root.barOpacity.toFixed(2) + "' > ~/.config/cupcake/.bar_opacity"]);
                            }
                        }
                    }
                }
            }
        }
    }
}
