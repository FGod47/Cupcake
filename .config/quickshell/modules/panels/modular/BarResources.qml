import QtQuick
import QtQuick.Layouts
import "../../../theme"

// ── System Resource Monitor ──
// Displays CPU and RAM usage with color-coded indicators.
// Reads bar.cpuStr and bar.ramStr from parent bar context.
Row {
    id: barResources
    spacing: 12
    opacity: (bar.netDropdownOpen || bar.dropdownOpen) ? 0 : 1
    visible: true
    Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }

    function resourceColor(val) {
        let v = parseFloat(val) || 0;
        if (v >= 80) return "#ff6b6b";
        if (v >= 50) return "#ffd580";
        return Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.6);
    }

    // CPU
    Row {
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text: "\uea4a" // tabler: cpu
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
            text: "\uf4bc" // tabler: memory
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

    // Trailing separator dot
    Text {
        text: "•"
        font.family: Theme.defaultFontFamily
        font.pixelSize: 13
        color: Qt.rgba(bar.fg.r, bar.fg.g, bar.fg.b, 0.3)
        anchors.verticalCenter: parent.verticalCenter
    }
}
