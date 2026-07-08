import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../theme"
import "../common"

Item {
    id: root
    
    // =====================================================================
    // Reusable inline components based on the reference UI
    // =====================================================================

    component SectionLabel: Text {
        font.family: Theme.defaultFontFamily
        font.pixelSize: 11
        font.weight: Math.min(900, Theme.defaultFontWeight + 200)
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
            width: 18; height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: sw.checked ? parent.width - width - 2 : 2
            color: sw.checked ? Theme.colSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.8)
            Behavior on x { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: { sw.checked = !sw.checked; sw.toggled(sw.checked) }
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
                    color: active ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.92) : "transparent"

                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: modelData
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 12
                        font.weight: 500
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

        radius: 8
        height: 26
        width: pillText.implicitWidth + 24
        color: active ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.92) : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)

        Text {
            id: pillText
            anchors.centerIn: parent
            text: pill.label
            font.family: Theme.defaultFontFamily
            font.pixelSize: 12
            font.weight: 500
            color: active ? Theme.colSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.65)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: pill.clicked()
        }
    }

    component SettingsRow: RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        spacing: 12
    }

    // =====================================================================
    // Main Content
    // =====================================================================

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: Math.min(parent.width, 1000)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 24
            
            Item { Layout.preferredHeight: 8 }

            
            // --- Language section ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.topMargin: 16
                spacing: 8

                SectionLabel { text: "Language" }

                SettingsRow {
                    RowLayout {
                        spacing: 12
                        Text { text: "󰊿"; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 16 }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Application Language"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 500 }
                            Text { text: "Language used in the application's interface"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox {
                        Layout.preferredWidth: 200
                        model: ["Automatic (en)"]
                    }
                }
            }
            
            // SETUP WIZARD BUTTON
            Rectangle {
                Layout.topMargin: 16
                Layout.fillWidth: true
                Layout.minimumWidth: 200
                Layout.maximumWidth: 350
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 38
                color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.8)
                radius: 8
                Text {
                    anchors.centerIn: parent
                    text: "Launch the setup wizard"
                    color: Theme.colOnPrimary
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: Theme.defaultFontSize
                    font.weight: Math.min(900, Theme.defaultFontWeight + 200)
                }
            }

            Item { Layout.preferredHeight: 24 } // Bottom padding
        }
    }
}
