import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../theme"

// ── System Resource Monitor ──
// Displays CPU and RAM usage with color-coded indicators.
Item {
    id: barResources
    implicitWidth: resRow.implicitWidth
    implicitHeight: 20
    opacity: (bar.netDropdownOpen || bar.dropdownOpen) ? 0 : 1
    visible: true
    Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }

    FontLoader {
        id: resIconFont
        source: Qt.resolvedUrl("file://" + Quickshell.env("HOME") + "/.local/share/fonts/tabler-icons.ttf")
    }

    function resourceColor(val) {
        let v = parseFloat(val) || 0;
        if (v >= 80) return "#ff6b6b";
        if (v >= 50) return "#ffd580";
        return Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6);
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["bash", "-c", "foot --title='System Monitor' btop 2>/dev/null || kitty --title='System Monitor' btop 2>/dev/null || alacritty -e btop 2>/dev/null || xterm -e btop &"])
    }

    Row {
        id: resRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        // CPU
        Row {
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter
            Text {
                text: "\uea4a" // cpu icon
                font.family: resIconFont.name
                font.pixelSize: 13
                color: barResources.resourceColor(bar.cpuStr)
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: bar.cpuStr + "%"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 11
                font.weight: Theme.defaultFontWeight
                color: barResources.resourceColor(bar.cpuStr)
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // RAM
        Row {
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter
            Text {
                text: "\uf4bc" // memory icon
                font.family: resIconFont.name
                font.pixelSize: 13
                color: barResources.resourceColor(bar.ramStr)
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: bar.ramStr + "%"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 11
                font.weight: Theme.defaultFontWeight
                color: barResources.resourceColor(bar.ramStr)
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Trailing separator dot
        Text {
            text: "•"
            font.family: Theme.defaultFontFamily
            font.pixelSize: 13
            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.3)
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
