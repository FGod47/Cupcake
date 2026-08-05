import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../theme"

// ── System Resource Monitor ──
// Displays CPU, RAM, Swap, and network speed with color-coded indicators.
// Reads bar.cpuStr, bar.ramStr, bar.swapStr, bar.netRxStr, bar.netTxStr
// from parent bar context.
Row {
    id: barResources
    spacing: 10
    opacity: (bar.netDropdownOpen || bar.dropdownOpen) ? 0 : 1
    visible: true
    Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }

    function resourceColor(val) {
        let v = parseFloat(val) || 0;
        if (v >= 80) return "#ff6b6b";
        if (v >= 50) return "#ffd580";
        return Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.55);
    }

    // ── Click anywhere → open btop ──
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["bash", "-c",
            "foot --title='System Monitor' btop 2>/dev/null || kitty --title='System Monitor' btop 2>/dev/null || alacritty -e btop 2>/dev/null || xterm -e btop &"])
    }

    // CPU
    Row {
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter
        Text {
            text: "\uea4a" // cpu
            font.family: bar.fontName
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
            text: "\uf4bc" // memory
            font.family: bar.fontName
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

    // Swap (only show if in use > 0%)
    Row {
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter
        visible: (parseFloat(bar.swapStr) || 0) > 0
        Text {
            text: "\uecd2" // swap/arrows icon
            font.family: bar.fontName
            font.pixelSize: 13
            color: barResources.resourceColor(bar.swapStr)
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: bar.swapStr + "%"
            font.family: Theme.defaultFontFamily
            font.pixelSize: 11
            font.weight: Theme.defaultFontWeight
            color: barResources.resourceColor(bar.swapStr)
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Network ↓↑
    Row {
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter
        visible: (bar.isWifi || bar.isWired || bar.isHotspot)
        Text {
            text: "\uea7a" // arrow-down-up / transfer
            font.family: bar.fontName
            font.pixelSize: 13
            color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.55)
            anchors.verticalCenter: parent.verticalCenter
        }
        Column {
            spacing: 0
            anchors.verticalCenter: parent.verticalCenter
            Text {
                text: "↓ " + bar.netRxStr
                font.family: Theme.defaultFontFamily
                font.pixelSize: 9
                font.weight: Theme.defaultFontWeight
                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.7)
            }
            Text {
                text: "↑ " + bar.netTxStr
                font.family: Theme.defaultFontFamily
                font.pixelSize: 9
                font.weight: Theme.defaultFontWeight
                color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.5)
            }
        }
    }

    // Trailing separator dot
    Text {
        text: "•"
        font.family: Theme.defaultFontFamily
        font.pixelSize: 13
        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.25)
        anchors.verticalCenter: parent.verticalCenter
    }
}
