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
        command: ["bash", "-c", "cat ~/.config/cupcake/.bar_monitors 2>/dev/null; echo '---'; cat ~/.config/cupcake/.bar_dropdown_style 2>/dev/null; echo '---'; cat ~/.config/cupcake/.bar_transparency 2>/dev/null; echo '---'; cat ~/.config/cupcake/.bar_opacity 2>/dev/null; echo '---'; cat ~/.config/cupcake/.hide_island 2>/dev/null; echo '---'; cat ~/.config/cupcake/.clock_24h 2>/dev/null; echo '---'; cat ~/.config/cupcake/.clock_show_seconds 2>/dev/null"]
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
                }
            }
        }
    }

    // State properties
    property bool barEnabled: true
    property string barMonitors: "all"
    property string dropdownStyle: Theme.barDropdownStyle !== "" ? Theme.barDropdownStyle : "Detached"
    property bool barTransparency: true
    property real barOpacity: 0.50
    property bool hideIsland: false
    property bool clock24h: true
    property bool showSeconds: false

    Flickable {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.topMargin: 20
        anchors.bottomMargin: 20
        contentWidth: width
        contentHeight: mainCol.implicitHeight + 40
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainCol
            width: parent.width
            spacing: 20

            // ── PAGE TITLE ────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: "Top Bar"
                    color: Theme.colOnSurface
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 22
                    font.weight: Font.Bold
                }

                Item { Layout.fillWidth: true }

                // Quick test notification button
                Rectangle {
                    height: 32
                    width: testRow.implicitWidth + 24
                    radius: 16
                    color: testBtnMa.containsMouse ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.2) : Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12)
                    border.color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.3)
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        id: testRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "\ueaa2"
                            font.family: "tabler-icons"
                            font.pixelSize: 14
                            color: Theme.colPrimary
                        }
                        Text {
                            text: "Test Notification"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Theme.colPrimary
                        }
                    }

                    MouseArea {
                        id: testBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["notify-send", "Screenshot Saved", "/home/zero/Pictures/Screenshot/demo_preview.png"]);
                        }
                    }
                }
            }

            // ── LIVE VISUAL MOCKUP ─────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 140
                radius: 20
                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03)
                clip: true

                // Background desktop preview
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 12
                    radius: 14
                    color: Qt.rgba(0, 0, 0, 0.4)
                    border.color: Qt.rgba(255, 255, 255, 0.06)
                    border.width: 1

                    // Simulated top bar
                    Rectangle {
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 12
                        anchors.rightMargin: root.hideIsland ? 12 : 120
                        height: 28
                        radius: 14
                        color: root.barTransparency
                               ? Qt.rgba(Theme.colSurfaceContainer.r, Theme.colSurfaceContainer.g, Theme.colSurfaceContainer.b, root.barOpacity)
                               : Theme.colSurfaceContainer
                        border.color: Qt.rgba(255, 255, 255, 0.08)
                        border.width: 1

                        Behavior on anchors.rightMargin { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 250 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            // Cupcake logo
                            Text {
                                text: "🧁"
                                font.pixelSize: 12
                            }

                            // Workspaces dots
                            Row {
                                spacing: 4
                                Layout.alignment: Qt.AlignVCenter
                                Rectangle { width: 14; height: 5; radius: 2.5; color: Theme.colPrimary }
                                Rectangle { width: 5; height: 5; radius: 2.5; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.3) }
                                Rectangle { width: 5; height: 5; radius: 2.5; color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.3) }
                            }

                            Item { Layout.fillWidth: true }

                            // Center clock
                            Text {
                                text: root.clock24h ? "19:30" : "07:30 PM"
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: Theme.colOnSurface
                            }

                            Item { Layout.fillWidth: true }

                            // Status icons & micro-dots
                            RowLayout {
                                spacing: 6
                                Layout.alignment: Qt.AlignVCenter

                                Text { text: "\ueb52"; font.family: "tabler-icons"; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                                Rectangle { width: 3; height: 3; radius: 1.5; color: Theme.colOnSurface; opacity: 0.3 }
                                Text { text: "\ueb51"; font.family: "tabler-icons"; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                                Rectangle { width: 3; height: 3; radius: 1.5; color: Theme.colOnSurface; opacity: 0.3 }
                                Text { text: "\uef3b"; font.family: "tabler-icons"; font.pixelSize: 11; color: Theme.colOnSurfaceVariant }
                            }
                        }
                    }

                    // Simulated notification island pill (Right side)
                    Rectangle {
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        width: 100
                        height: 28
                        radius: 14
                        visible: !root.hideIsland
                        color: root.barTransparency
                               ? Qt.rgba(Theme.colSurfaceContainer.r, Theme.colSurfaceContainer.g, Theme.colSurfaceContainer.b, root.barOpacity)
                               : Theme.colSurfaceContainer
                        border.color: Qt.rgba(255, 255, 255, 0.08)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 4

                            Rectangle { width: 4; height: 4; radius: 2; color: "#E5C07B" }
                            Text {
                                text: "SCREENSHOT"
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 8
                                font.weight: Font.Bold
                                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.6)
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                    }

                    // Mockup caption
                    Text {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottomMargin: 8
                        text: "Solid Top Bar with " + root.dropdownStyle + " Pods • " + (root.barTransparency ? Math.round(root.barOpacity * 100) + "% Opacity" : "Opaque")
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 10
                        color: Qt.rgba(255, 255, 255, 0.4)
                    }
                }
            }

            // ── SECTION 1: LAYOUT & MONITORS ──────────────────────────────
            NCard {
                sectionTitle: "Layout & Displays"

                NRow {
                    Text {
                        text: "Dropdown Menus Style"
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Theme.colOnSurface
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: 6

                        // Attached Option
                        Rectangle {
                            height: 30
                            width: attachedText.implicitWidth + 20
                            radius: 8
                            color: root.dropdownStyle === "Attached" ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                id: attachedText
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

                        // Detached Option
                        Rectangle {
                            height: 30
                            width: detachedText.implicitWidth + 20
                            radius: 8
                            color: root.dropdownStyle === "Detached" ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                id: detachedText
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
                            text: "Monitor Placement"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Theme.colOnSurface
                        }
                        Text {
                            text: "Choose which displays show the top bar"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            color: Theme.colOnSurfaceVariant
                        }
                    }

                    RowLayout {
                        spacing: 6

                        Rectangle {
                            height: 30
                            width: allMonText.implicitWidth + 20
                            radius: 8
                            color: root.barMonitors === "all" ? Theme.colPrimary : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                id: allMonText
                                anchors.centerIn: parent
                                text: "All Displays"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: root.barMonitors === "all" ? Theme.colOnPrimary : Theme.colOnSurfaceVariant
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.barMonitors = "all";
                                    globalState.barMonitors = ["all"];
                                    Quickshell.execDetached(["bash", "-c", "echo 'all' > ~/.config/cupcake/.bar_monitors"]);
                                }
                            }
                        }
                    }
                }
            }

            // ── SECTION 2: APPEARANCE & TRANSPARENCY ──────────────────────
            NCard {
                sectionTitle: "Appearance & Opacity"

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
                            text: "Enable acrylic glass transparency on the top bar"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            color: Theme.colOnSurfaceVariant
                        }
                    }

                    NToggle {
                        checked: root.barTransparency
                        onToggled: (val) => {
                            root.barTransparency = val;
                            Quickshell.execDetached(["bash", "-c", "echo " + val + " > ~/.config/cupcake/.bar_transparency && ~/.local/bin/apply-transparency"]);
                        }
                    }
                }

                NRow {
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Bar Background Opacity"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: Theme.colOnSurface
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: Math.round(root.barOpacity * 100) + "%"
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: Theme.colPrimary
                            }
                        }

                        Slider {
                            id: opacitySlider
                            Layout.fillWidth: true
                            from: 0.10
                            to: 1.00
                            stepSize: 0.05
                            value: root.barOpacity
                            onMoved: {
                                root.barOpacity = opacitySlider.value;
                                Quickshell.execDetached(["bash", "-c", "echo '" + root.barOpacity.toFixed(2) + "' > ~/.config/cupcake/.bar_opacity"]);
                            }
                        }
                    }
                }
            }

            // ── SECTION 3: DYNAMIC ISLAND NOTIFICATIONS ───────────────────
            NCard {
                sectionTitle: "Dynamic Island & Notifications"

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

            // ── SECTION 4: CLOCK & WIDGETS ────────────────────────────────
            NCard {
                sectionTitle: "Clock & Status Indicators"

                NRow {
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "24-Hour Time Format"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Theme.colOnSurface
                        }
                        Text {
                            text: "Display time in 24-hour format (e.g. 19:30 vs 07:30 PM)"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            color: Theme.colOnSurfaceVariant
                        }
                    }

                    NToggle {
                        checked: root.clock24h
                        onToggled: (val) => {
                            root.clock24h = val;
                            Quickshell.execDetached(["bash", "-c", "echo " + val + " > ~/.config/cupcake/.clock_24h"]);
                        }
                    }
                }

                NRow {
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "Show Seconds on Clock"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Theme.colOnSurface
                        }
                        Text {
                            text: "Display real-time seconds in the top bar clock"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            color: Theme.colOnSurfaceVariant
                        }
                    }

                    NToggle {
                        checked: root.showSeconds
                        onToggled: (val) => {
                            root.showSeconds = val;
                            Quickshell.execDetached(["bash", "-c", "echo " + val + " > ~/.config/cupcake/.clock_show_seconds"]);
                        }
                    }
                }
            }
        }
    }
}
