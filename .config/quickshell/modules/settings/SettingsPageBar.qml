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

    // Read saved configuration state
    Process {
        id: initBarSettings
        command: ["bash", "-c", "cat ~/.config/cupcake/.bar_monitors 2>/dev/null; echo '---'; cat ~/.config/cupcake/.bar_dropdown_style 2>/dev/null; echo '---'; cat ~/.config/cupcake/.bar_transparency 2>/dev/null; echo '---'; cat ~/.config/cupcake/.bar_opacity 2>/dev/null; echo '---'; cat ~/.config/cupcake/.hide_island 2>/dev/null; echo '---'; cat ~/.config/cupcake/.clock_24h 2>/dev/null; echo '---'; cat ~/.config/cupcake/.clock_show_seconds 2>/dev/null; echo '---'; cat ~/.cache/current_wallpaper 2>/dev/null"]
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
    property string selectedTextColor: Theme.colOnSurface
    property string selectedAccentColor: Theme.colPrimary

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

            // ── 1. HEADER ROW: Apply / Reset Actions ───
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
                            Quickshell.execDetached(["bash", "-c", "echo '" + root.dropdownStyle + "' > ~/.config/cupcake/.bar_dropdown_style && echo '" + root.barTransparency + "' > ~/.config/cupcake/.bar_transparency && echo '" + root.barOpacity.toFixed(2) + "' > ~/.config/cupcake/.bar_opacity && echo '" + root.hideIsland + "' > ~/.config/cupcake/.hide_island && echo '" + root.clock24h + "' > ~/.config/cupcake/.clock_24h && echo '" + root.showSeconds + "' > ~/.config/cupcake/.clock_show_seconds && ~/.local/bin/apply-transparency"]);
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

            // ── 2. CINEMATIC LARGE DESKTOP PREVIEW WINDOW ─────────────────
            Rectangle {
                id: previewFrame
                Layout.fillWidth: true
                height: 380
                radius: 18
                color: "#121316"
                border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                border.width: 1
                clip: true

                // Background wallpaper image / gradient
                Image {
                    id: wallImg
                    anchors.fill: parent
                    source: (root.wallpaperPath && !root.wallpaperPath.endsWith(".mp4")) ? ("file://" + root.wallpaperPath) : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: source !== ""
                    opacity: 0.85
                }

                // Fallback / artistic gradient backdrop matching reference screenshot
                Rectangle {
                    anchors.fill: parent
                    visible: !wallImg.visible
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#16384C" }
                        GradientStop { position: 0.45; color: "#544642" }
                        GradientStop { position: 0.80; color: "#8E2B24" }
                        GradientStop { position: 1.0; color: "#2B1115" }
                    }

                    // Diagonal linear grain texture
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

                // Top Vignette Overlay
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: Qt.rgba(0, 0, 0, 0.4)
                    border.width: 1
                    radius: 18
                }

                // ── MOCKUP BAR CAPSULE AT SCREEN TOP ───────────────────────
                Rectangle {
                    id: liveBar
                    anchors.top: root.barPosition === "Above" ? parent.top : undefined
                    anchors.bottom: root.barPosition === "Below" ? parent.bottom : undefined
                    anchors.left: root.barPosition === "Right" ? undefined : (root.barPosition === "Left" ? parent.left : undefined)
                    anchors.right: root.barPosition === "Left" ? undefined : (root.barPosition === "Right" ? parent.right : undefined)
                    anchors.horizontalCenter: (root.barPosition === "Above" || root.barPosition === "Below") ? parent.horizontalCenter : undefined
                    anchors.verticalCenter: (root.barPosition === "Left" || root.barPosition === "Right") ? parent.verticalCenter : undefined

                    anchors.topMargin: root.barPosition === "Above" ? 0 : 0
                    anchors.bottomMargin: root.barPosition === "Below" ? 0 : 0
                    anchors.leftMargin: root.barPosition === "Left" ? 0 : 0
                    anchors.rightMargin: root.barPosition === "Right" ? 0 : 0

                    width: (root.barPosition === "Left" || root.barPosition === "Right") ? 32 : 180
                    height: (root.barPosition === "Left" || root.barPosition === "Right") ? 180 : 28
                    
                    bottomLeftRadius: (root.barPosition === "Above") ? 14 : 0
                    bottomRightRadius: (root.barPosition === "Above") ? 14 : 0
                    topLeftRadius: (root.barPosition === "Below") ? 14 : 0
                    topRightRadius: (root.barPosition === "Below") ? 14 : 0

                    color: root.barTransparency
                           ? Qt.rgba(Theme.colSurfaceContainer.r, Theme.colSurfaceContainer.g, Theme.colSurfaceContainer.b, Math.max(0.7, root.barOpacity))
                           : Theme.colSurfaceContainer
                    border.color: Qt.rgba(255, 255, 255, 0.12)
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 250 } }

                    // Horizontal bar content (matching screenshot: Tue 23:24 4 RU 🔒 45%)
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        visible: root.barPosition === "Above" || root.barPosition === "Below"
                        spacing: 8

                        Text {
                            text: "Tue"
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 10
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.6)
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: root.clock24h ? "23:24" : "11:24"
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: root.selectedTextColor
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: "4"
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: root.selectedAccentColor
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: "RU"
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 9
                            font.weight: Font.SemiBold
                            color: root.selectedAccentColor
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: "\uf023"
                            font.family: "tabler-icons"
                            font.pixelSize: 9
                            color: root.selectedAccentColor
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: "45%"
                            font.family: Theme.monoFontFamily
                            font.pixelSize: 9
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.7)
                            Layout.alignment: Qt.AlignVCenter
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

            // ── 4. BOTTOM DUAL-CARD GRID (EXACT SCREENSHOT LAYOUT) ────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                // ── CARD A: SCREEN POSITION ───────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
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
                                Layout.preferredHeight: 74
                                radius: 10
                                color: root.barPosition === "Above" ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.04)
                                border.color: root.barPosition === "Above" ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.1)
                                border.width: root.barPosition === "Above" ? 2 : 1

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    // Diagram: Bar on top
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
                                    onClicked: root.barPosition = "Above"
                                }
                            }

                            // 2. Below
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 74
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
                                    onClicked: root.barPosition = "Below"
                                }
                            }

                            // 3. Left
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 74
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
                                Layout.preferredHeight: 74
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
            }
        }
    }
}
