import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../theme"
import "../common"

Item {
    id: root

    property int gapsIn: 3
    property int gapsOut: 8
    property bool widgetsEnabled: false
    property bool screenCornersEnabled: false
    property int screenCornerSize: 12
    property bool bordersEnabled: true
    property int borderSize: 3
    property bool shadowsEnabled: false
    property int shadowSize: 4

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.gaps_in"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { let v = parseInt(text.trim()); if (!isNaN(v)) root.gapsIn = v; }
            }
        }
    }

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.gaps_out"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { let v = parseInt(text.trim()); if (!isNaN(v)) root.gapsOut = v; }
            }
        }
    }

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.borders"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { root.bordersEnabled = (text.trim() === "true"); }
            }
        }
    }

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.border_size"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { let v = parseInt(text.trim()); if (!isNaN(v)) root.borderSize = v; }
            }
        }
    }

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.shadows"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { root.shadowsEnabled = (text.trim() === "true"); }
            }
        }
    }

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.shadow_size"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { let v = parseInt(text.trim()); if (!isNaN(v)) root.shadowSize = v; }
            }
        }
    }

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.corners"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { root.screenCornersEnabled = (text.trim() === "true"); }
            }
        }
    }

    Process {
        command: ["cat", Theme.homeDir + "/.config/cupcake/.corner_size"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { let v = parseInt(text.trim()); if (!isNaN(v)) root.screenCornerSize = v; }
            }
        }
    }

    // =========================================================================
    // Inline components matching Appearance page style
    // =========================================================================

    component SettingsCard: Rectangle {
        default property alias content: innerCol.data
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        implicitHeight: innerCol.implicitHeight + 40
        Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        color: Theme.showCardBackground ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.03) : "transparent"
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

    component SettingsRow: RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        spacing: 12
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

    // =========================================================================
    // Main layout
    // =========================================================================

    ScrollView {
        id: scrollView
        anchors.fill: parent
        anchors.topMargin: 0
        anchors.bottomMargin: 30
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 24

            // --- Widgets section ---
            SettingsCard {
                SectionLabel { text: "Widgets" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb95"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        Text { text: "Widgets Enabled"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch {
                        checked: root.widgetsEnabled
                        onToggled: (v) => { root.widgetsEnabled = v; }
                    }
                }
            }

            // --- Screen Corners section ---
            SettingsCard {
                SectionLabel { text: "Screen Corners" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\uea17"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        Text { text: "Screen Corners Enabled"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch {
                        checked: root.screenCornersEnabled
                        onToggled: (v) => { 
                            root.screenCornersEnabled = v; 
                            Quickshell.execDetached(["bash", "-c", "echo '" + (v ? "true" : "false") + "' > ~/.config/cupcake/.corners && ~/.local/bin/apply-corners"]);
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb24"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        Text { text: "Screen Corners Size"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    }
                    Item { Layout.fillWidth: true }
                    StyledSlider {
                        id: screenCornersSlider
                        Layout.preferredWidth: 150
                        from: 0; to: 100; stepSize: 1
                        value: root.screenCornerSize
                        onValueChanged: root.screenCornerSize = value
                        onPressedChanged: {
                            if (!pressed)
                                Quickshell.execDetached(["bash", "-c", "echo '" + Math.round(root.screenCornerSize) + "' > ~/.config/cupcake/.corner_size && ~/.local/bin/apply-corners"]);
                        }
                    }
                    Text {
                        text: Math.round(root.screenCornerSize) + "px"
                        color: Theme.colOnSurfaceVariant
                        font.family: Theme.monoFontFamily
                        font.pixelSize: 12
                        Layout.preferredWidth: 32
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            // --- Window Gaps section ---
            SettingsCard {
                SectionLabel { text: "Window Gaps" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb24"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        Text { text: "Inner Gaps"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    }
                    Item { Layout.fillWidth: true }
                    StyledSlider {
                        Layout.preferredWidth: 150
                        from: 0; to: 30; stepSize: 1
                        value: root.gapsIn
                        onValueChanged: root.gapsIn = value
                        onPressedChanged: {
                            if (!pressed)
                                Quickshell.execDetached(["bash", "-c", "echo '" + Math.round(root.gapsIn) + "' > ~/.config/cupcake/.gaps_in && ~/.local/bin/apply-gaps"]);
                        }
                    }
                    Text {
                        text: Math.round(root.gapsIn) + "px"
                        color: Theme.colOnSurfaceVariant
                        font.family: Theme.monoFontFamily
                        font.pixelSize: 12
                        Layout.preferredWidth: 32
                        horizontalAlignment: Text.AlignRight
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueae5"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        Text { text: "Outer Gaps"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    }
                    Item { Layout.fillWidth: true }
                    StyledSlider {
                        Layout.preferredWidth: 150
                        from: 0; to: 60; stepSize: 1
                        value: root.gapsOut
                        onValueChanged: root.gapsOut = value
                        onPressedChanged: {
                            if (!pressed)
                                Quickshell.execDetached(["bash", "-c", "echo '" + Math.round(root.gapsOut) + "' > ~/.config/cupcake/.gaps_out && ~/.local/bin/apply-gaps"]);
                        }
                    }
                    Text {
                        text: Math.round(root.gapsOut) + "px"
                        color: Theme.colOnSurfaceVariant
                        font.family: Theme.monoFontFamily
                        font.pixelSize: 12
                        Layout.preferredWidth: 32
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
            // --- Window Borders section ---
            SettingsCard {
                SectionLabel { text: "Window Borders" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueac2" // tabler-icons 'border-all'
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        Text { text: "Borders Enabled"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch {
                        checked: root.bordersEnabled
                        onToggled: (v) => { 
                            root.bordersEnabled = v; 
                            Quickshell.execDetached(["bash", "-c", "echo '" + (v ? "true" : "false") + "' > ~/.config/cupcake/.borders && ~/.local/bin/apply-borders"]);
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb24"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        Text { text: "Border Size"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    }
                    Item { Layout.fillWidth: true }
                    StyledSlider {
                        Layout.preferredWidth: 150
                        from: 0; to: 10; stepSize: 1
                        value: root.borderSize
                        onValueChanged: root.borderSize = value
                        onPressedChanged: {
                            if (!pressed)
                                Quickshell.execDetached(["bash", "-c", "echo '" + Math.round(root.borderSize) + "' > ~/.config/cupcake/.border_size && ~/.local/bin/apply-borders"]);
                        }
                    }
                    Text {
                        text: Math.round(root.borderSize) + "px"
                        color: Theme.colOnSurfaceVariant
                        font.family: Theme.monoFontFamily
                        font.pixelSize: 12
                        Layout.preferredWidth: 32
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            // --- Window Shadows section ---
            SettingsCard {
                SectionLabel { text: "Window Shadows" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\uea60" // tabler-icons 'shadow'
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        Text { text: "Shadows Enabled"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    }
                    Item { Layout.fillWidth: true }
                    ToggleSwitch {
                        checked: root.shadowsEnabled
                        onToggled: (v) => { 
                            root.shadowsEnabled = v; 
                            Quickshell.execDetached(["bash", "-c", "echo '" + (v ? "true" : "false") + "' > ~/.config/cupcake/.shadows && ~/.local/bin/apply-shadows"]);
                        }
                    }
                }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "\ueb24"
                                color: Theme.colOnSurfaceVariant
                                font.family: "tabler-icons"
                                font.pixelSize: 16
                            }
                        }
                        Text { text: "Shadow Thickness"; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    }
                    Item { Layout.fillWidth: true }
                    StyledSlider {
                        Layout.preferredWidth: 150
                        from: 0; to: 30; stepSize: 1
                        value: root.shadowSize
                        onValueChanged: root.shadowSize = value
                        onPressedChanged: {
                            if (!pressed)
                                Quickshell.execDetached(["bash", "-c", "echo '" + Math.round(root.shadowSize) + "' > ~/.config/cupcake/.shadow_size && ~/.local/bin/apply-shadows"]);
                        }
                    }
                    Text {
                        text: Math.round(root.shadowSize) + "px"
                        color: Theme.colOnSurfaceVariant
                        font.family: Theme.monoFontFamily
                        font.pixelSize: 12
                        Layout.preferredWidth: 32
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
