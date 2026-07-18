import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import Quickshell
import Quickshell.Io
import "../common"

Item {
    id: root
    anchors.fill: parent

    property var monitorsData: []
    property string pendingOutput: ""
    property int countdown: 0
    property var pendingRestoreCommand: []
    property int activeMonitorIndex: 0
    property var activeMonitor: monitorsData.length > 0 && activeMonitorIndex < monitorsData.length ? monitorsData[activeMonitorIndex] : null
    property var activeTransforms: ({})
    property int currentTransform: {
        if (!activeMonitor) return 0;
        return activeTransforms[activeMonitor.name] !== undefined ? activeTransforms[activeMonitor.name] : (activeMonitor.transform || 0);
    }
    property string homeDir: Quickshell.env("HOME")

    property color cBg: Theme.colSurface
    property color cBgElevated: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
    property color cSurfaceHover: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
    property color cBorderSoft: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.1)
    property color cText: Theme.colOnSurface
    property color cTextDim: Theme.colOnSurfaceVariant
    property color cAccent: Theme.colPrimary


    Timer {
        id: revertTimer
        interval: 1000
        repeat: true
        onTriggered: {
            root.countdown--
            if (root.countdown <= 0) {
                root.revertDisplay()
            }
        }
    }

    // Takes the exact hyprland monitor data object + a mode string like "1920x1080@165.00" + scale number + transform
    function applyDisplay(monData, modeStr, scaleVal, transformVal) {
        if (pendingOutput !== "") return;
        let posStr = monData.x + "x" + monData.y;
        pendingRestoreCommand = ["hyprctl", "eval",
            "hl.monitor({ output = \"" + monData.name + "\", mode = \"" +
            monData.width + "x" + monData.height + "@" + monData.refreshRate +
            "\", position = \"" + posStr + "\", scale = " + monData.scale + 
            ", transform = " + monData.transform + " }) return \"ok\""];
        pendingOutput = monData.name;
        countdown = 15;
        revertTimer.start();
        Quickshell.execDetached(["hyprctl", "eval",
            "hl.monitor({ output = \"" + monData.name + "\", mode = \"" +
            modeStr + "\", position = \"" + posStr + "\", scale = " + scaleVal + 
            ", transform = " + transformVal + " }) return \"ok\""]);
    }

    function keepDisplay() {
        if (pendingOutput === "") return;
        revertTimer.stop();
        Quickshell.execDetached(["python3", homeDir + "/Cupcake/.local/bin/generate_monitor_lua.py"]);
        pendingOutput = "";
    }

    function revertDisplay() {
        revertTimer.stop();
        Quickshell.execDetached(pendingRestoreCommand);
        pendingOutput = "";
    }

    Process {
        id: monitorsProcess
        command: ["hyprctl", "monitors", "-j"]
        running: root.visible
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.monitorsData = JSON.parse(text); } catch (e) {}
            }
        }
    }

    Timer {
        interval: 5000
        running: root.visible
        repeat: true
        onTriggered: monitorsProcess.running = true
    }

    // =========================================================
    // Shared inline components
    // =========================================================

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



    component SegmentedControl: Rectangle {
        id: seg
        property var options: []
        property string current: options.length > 0 ? options[0] : ""
        signal selected(string value)
        color: Qt.rgba(0, 0, 0, 0.28)
        radius: 8
        height: 30
        width: segRow.implicitWidth + 4
        Row {
            id: segRow
            anchors.centerIn: parent
            spacing: 1
            Repeater {
                model: seg.options
                delegate: Rectangle {
                    required property string modelData
                    property bool active: modelData === seg.current
                    height: 26
                    width: segLabel.implicitWidth + 24
                    radius: 6
                    color: active ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.92) : "transparent"
                    Text {
                        id: segLabel
                        anchors.centerIn: parent
                        text: modelData
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
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

    component SettingsRow: ColumnLayout {
        default property alias content: innerRow.data
        Layout.fillWidth: true
        Layout.topMargin: Theme.rowSpacing
        Layout.bottomMargin: Theme.rowSpacing
        spacing: 12
        RowLayout {
            id: innerRow
            Layout.fillWidth: true
            spacing: 12
        }
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
            visible: Theme.showDividers
        }
    }

    // Standard ComboBox styled to match the page
    component StyledComboBox: ComboBox {
        id: scb
        Layout.preferredWidth: 160
        Layout.preferredHeight: 32
        indicator: Text {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "\uea5f"
            font.family: "tabler-icons"
            font.pixelSize: 14
            color: Theme.colOnSurfaceVariant
        }
        background: Rectangle { color: Qt.rgba(0,0,0,0.28); radius: 8 }
        contentItem: Text {
            leftPadding: 12
            text: scb.displayText
            font.family: Theme.defaultFontFamily
            font.pixelSize: 13
            color: Theme.colOnSurface
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        popup: Popup {
            y: scb.height + 4
            width: scb.width
            implicitHeight: listView.contentHeight + 8
            padding: 4
            contentItem: ListView {
                id: listView
                clip: true
                implicitHeight: Math.min(contentHeight, 220)
                model: scb.delegateModel
                currentIndex: scb.highlightedIndex
                ScrollIndicator.vertical: ScrollIndicator {}
            }
            background: Rectangle {
                color: Theme.colSurfaceContainerHigh
                border.color: Theme.colOutline
                border.width: 1
                radius: 8
            }
        }
        delegate: ItemDelegate {
            width: scb.popup.width - 8
            height: 34
            highlighted: scb.highlightedIndex === index
            background: Rectangle {
                color: highlighted
                    ? Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.15)
                    : "transparent"
                radius: 6
            }
            contentItem: Text {
                text: modelData
                font.family: Theme.defaultFontFamily
                font.pixelSize: 13
                color: Theme.colOnSurface
                verticalAlignment: Text.AlignVCenter
                leftPadding: 8
            }
        }
    }

    // =========================================================
    // Main layout
    // =========================================================

    ScrollView {
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        id: scrollView
        anchors.fill: parent
        anchors.bottomMargin: 28
        anchors.rightMargin: 24
        leftPadding: 32
        rightPadding: 32
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 20

            // Pending change banner
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                height: 48
                radius: 12
                color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.12)
                border.color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.3)
                border.width: 1
                visible: root.pendingOutput !== ""

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    Text {
                        text: "\uea5b"
                        font.family: "tabler-icons"
                        font.pixelSize: 18
                        color: Theme.colPrimary
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Display changed — reverts in " + root.countdown + "s"
                        color: Theme.colOnSurface
                        font.pixelSize: 13
                        font.family: Theme.defaultFontFamily
                        font.weight: Font.Medium
                    }

                    Rectangle {
                        width: 72; height: 30; radius: 8
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
                        Text { anchors.centerIn: parent; text: "Revert"; color: cTextDim; font.pixelSize: 12; font.family: Theme.defaultFontFamily; font.weight: Font.Medium }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.revertDisplay() }
                    }
                    Rectangle {
                        width: 64; height: 30; radius: 8
                        color: Theme.colPrimary
                        Text { anchors.centerIn: parent; text: "Keep"; color: cText; font.pixelSize: 12; font.family: Theme.defaultFontFamily; font.weight: Font.Medium }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.keepDisplay() }
                    }
                }
            }

            // 1. Monitors selector
            NCard {
                sectionTitle: "Monitors"
                Flow {
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: root.monitorsData
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            property bool active: index === root.activeMonitorIndex
                            property string displayName: {
                                let d = modelData.description || "";
                                let parts = d.split(" ");
                                return parts.length > 3 ? parts.slice(0, 3).join(" ") : (d || modelData.name);
                            }
                            height: 34
                            implicitWidth: monPillText.implicitWidth + 28
                            radius: 8
                            color: active
                                ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.92)
                                : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.06)
                            border.width: active ? 0 : 1
                            border.color: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text {
                                id: monPillText
                                anchors.centerIn: parent
                                text: displayName
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: active ? Theme.colSurface : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.65)
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeMonitorIndex = index
                            }
                        }
                    }
                }
            }

            // 2. Resolution, Refresh rate, Scale — per-monitor card
            Repeater {
                model: root.monitorsData
                delegate: NCard {
                    id: monCard
                    required property var modelData
                    required property int index

                    visible: index === root.activeMonitorIndex

                    // ---- Parse available modes into [{w,h,rates:[]}] ----
                    property var modesParsed: {
                        let result = [];
                        let seen = {};
                        let modes = modelData.availableModes || [];
                        for (let i = 0; i < modes.length; i++) {
                            let m = modes[i].match(/^(\d+)x(\d+)@([\d.]+)Hz$/);
                            if (m) {
                                let w = parseInt(m[1], 10);
                                let h = parseInt(m[2], 10);
                                let hz = parseFloat(m[3]);
                                let key = w + "x" + h;
                                if (!seen[key]) {
                                    seen[key] = { w: w, h: h, rates: [], rawRates: [] };
                                    result.push(seen[key]);
                                }
                                // store rounded for display, raw for command
                                let rounded = Math.round(hz);
                                if (seen[key].rawRates.indexOf(hz) === -1) {
                                    seen[key].rates.push(rounded);
                                    seen[key].rawRates.push(hz);
                                }
                            }
                        }
                        result.sort(function(a,b){ return (b.w*b.h)-(a.w*a.h); });
                        for (let j = 0; j < result.length; j++) {
                            // sort by rawRate descending, keep rates/rawRates in sync
                            let indices = result[j].rawRates.map(function(_,i){ return i; });
                            indices.sort(function(a,b){ return result[j].rawRates[b]-result[j].rawRates[a]; });
                            result[j].rates    = indices.map(function(i){ return result[j].rates[i]; });
                            result[j].rawRates = indices.map(function(i){ return result[j].rawRates[i]; });
                        }
                        return result;
                    }

                    // Currently selected resolution index & rate index
                    property int selRes: 0
                    property int selRate: 0
                    readonly property var scaleOptions: [1.0, 1.25, 1.5, 2.0]
                    property int selScaleIdx: {
                        let s = modelData.scale;
                        for (let i = 0; i < scaleOptions.length; i++) {
                            if (Math.abs(scaleOptions[i] - s) < 0.01) return i;
                        }
                        return 0;
                    }

                    Component.onCompleted: {
                        // Set selRes to match current width/height
                        for (let i = 0; i < modesParsed.length; i++) {
                            if (modesParsed[i].w === modelData.width && modesParsed[i].h === modelData.height) {
                                selRes = i;
                                break;
                            }
                        }
                        // Set selRate to match current refreshRate
                        let bestDiff = 1e9;
                        let rates = modesParsed[selRes] ? modesParsed[selRes].rawRates : [];
                        for (let i = 0; i < rates.length; i++) {
                            let d = Math.abs(rates[i] - modelData.refreshRate);
                            if (d < bestDiff) { bestDiff = d; selRate = i; }
                        }
                    }

                    onSelResChanged: {
                        let rates = modesParsed[selRes] ? modesParsed[selRes].rawRates : [];
                        if (selRate >= rates.length) selRate = 0;
                    }

                    SectionLabel { text: "Resolution & Refresh Rate" }

                    NRow {
                        RowLayout {
                            spacing: 12
                            NIconBadge { icon: "\uea27"; iconColor: cTextDim; bgColor: cBgElevated }
                            ColumnLayout {
                                spacing: 1
                                Text { text: "Resolution"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                                Text { text: "Native resolution recommended for sharpest image"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                            }
                        }
                        Item { Layout.fillWidth: true }
                        StyledComboBox {
                            model: monCard.modesParsed.map(function(m){ return m.w + " × " + m.h; })
                            currentIndex: monCard.selRes
                            onActivated: function(idx) { monCard.selRes = idx; }
                        }
                    }

                    NRow {
                        RowLayout {
                            spacing: 12
                            NIconBadge { icon: "\ueb13"; iconColor: cTextDim; bgColor: cBgElevated }
                            ColumnLayout {
                                spacing: 1
                                Text { text: "Refresh rate"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                                Text { text: "Higher rates feel smoother but use more power"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                            }
                        }
                        Item { Layout.fillWidth: true }
                        StyledComboBox {
                            property var curRates: monCard.modesParsed[monCard.selRes] ? monCard.modesParsed[monCard.selRes].rates : []
                            model: curRates.map(function(hz){ return hz + "Hz"; })
                            currentIndex: monCard.selRate
                            onActivated: function(idx) { monCard.selRate = idx; }
                        }
                    }

                    NRow {
                        RowLayout {
                            spacing: 12
                            NIconBadge { icon: "\ueb56"; iconColor: cTextDim; bgColor: cBgElevated }
                            ColumnLayout {
                                spacing: 1
                                Text { text: "Scale"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                                Text { text: "Adjust the size of text, icons and apps"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                            }
                        }
                        Item { Layout.fillWidth: true }
                        StyledComboBox {
                            model: ["100%", "125%", "150%", "200%"]
                            currentIndex: monCard.selScaleIdx
                            onActivated: function(idx) { monCard.selScaleIdx = idx; }
                        }
                    }

                    // Apply button row
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 8
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 100; height: 34; radius: 8
                            color: root.pendingOutput !== ""
                                ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                                : Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.92)
                            Text {
                                anchors.centerIn: parent
                                text: root.pendingOutput !== "" ? "Pending…" : "Apply"
                                color: root.pendingOutput !== ""
                                    ? Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.35)
                                    : Theme.colSurface
                                font.weight: Font.Medium
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 13
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: root.pendingOutput === ""
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    let res = monCard.modesParsed[monCard.selRes];
                                    if (!res) return;
                                    let rawHz = res.rawRates[monCard.selRate];
                                    // Build exact mode string: "1920x1080@165.00"
                                    let modeStr = res.w + "x" + res.h + "@" + rawHz.toFixed(2);
                                    let scale = monCard.scaleOptions[monCard.selScaleIdx];
                                    root.applyDisplay(monCard.modelData, modeStr, scale, root.currentTransform);
                                }
                            }
                        }
                    }
                }
            }

            // 3. Orientation
            NCard {
                sectionTitle: "Orientation"
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb16"; iconColor: cTextDim; bgColor: cBgElevated }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Orientation"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Rotate the display to match your setup"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: ["Landscape", "Portrait"]
                        current: (root.currentTransform % 2 === 0) ? "Landscape" : "Portrait"
                        onSelected: function(value) {
                            if (!root.activeMonitor) return;
                            let t = (value === "Portrait" ? 1 : 0);
                            let newMap = Object.assign({}, root.activeTransforms);
                            newMap[root.activeMonitor.name] = t;
                            root.activeTransforms = newMap;
                            
                            // Apply immediately
                            let mon = root.activeMonitor;
                            let modeStr = mon.width + "x" + mon.height + "@" + mon.refreshRate;
                            root.applyDisplay(mon, modeStr, mon.scale, t);
                        }
                    }
                }
            }

            // 4. Arrangement
            NCard {
                sectionTitle: "Arrangement"
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb2e"; iconColor: cTextDim; bgColor: cBgElevated }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Primary display"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Use this monitor for the taskbar and default windows"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: true }
                }
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea7a"; iconColor: cTextDim; bgColor: cBgElevated }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Mirror displays"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Show the same content on every connected monitor"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: false }
                }
            }

            // 5. Night light
            NCard {
                id: nightLightCard
                SectionLabel { text: "Night light" }

                // Night light state
                property int nightTemp: 3400
                property string nlSchedule: "manual"
                property string customStart: "20:00"
                property string customEnd: "06:00"

                Process {
                    id: stateWriter
                    command: ["echo", "test"]
                    running: false
                }

                Timer {
                    id: nlDebounce
                    interval: 100
                    repeat: false
                    onTriggered: {
                        stateWriter.command = [
                            "python3", Quickshell.env("HOME") + "/.config/cupcake/scripts/night_light_scheduler.py",
                            "--enabled", nlToggle.checked ? "true" : "false",
                            "--temperature", nightLightCard.nightTemp.toString(),
                            "--schedule", nightLightCard.nlSchedule,
                            "--custom-start", nightLightCard.customStart,
                            "--custom-end", nightLightCard.customEnd
                        ];
                        stateWriter.running = false;
                        Qt.callLater(function() { stateWriter.running = true; });
                    }
                }

                function applyNightLight() {
                    nlDebounce.restart();
                }


                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueaf8"; iconColor: cTextDim; bgColor: cBgElevated }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Night light"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Shift colors warmer to reduce eye strain at night"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        id: nlToggle
                        checked: false
                        onToggled: function(v) {
                            nightLightCard.applyNightLight();
                        }
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea70"; iconColor: cTextDim; bgColor: cBgElevated }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Schedule"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "When night light activates"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: ["Always", "Sunset", "Custom"]
                        current: "Always"
                        onSelected: function(v) {
                            if (v === "Always") nightLightCard.nlSchedule = "manual";
                            else if (v === "Sunset") nightLightCard.nlSchedule = "auto";
                            else nightLightCard.nlSchedule = "custom";
                            nightLightCard.applyNightLight();
                        }
                    }
                }

                NRow {
                    visible: nightLightCard.nlSchedule === "custom"
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea60"; iconColor: cTextDim; bgColor: cBgElevated }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Custom schedule times"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Format: HH:MM (24-hour)"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 8
                        Text { text: "From"; color: cTextDim; font.pixelSize: 12; font.family: Theme.defaultFontFamily }
                        StyledTextField {
                            text: nightLightCard.customStart
                            Layout.preferredWidth: 60
                            onEditingFinished: { nightLightCard.customStart = text; nightLightCard.applyNightLight(); }
                        }
                        Text { text: "to"; color: cTextDim; font.pixelSize: 12; font.family: Theme.defaultFontFamily }
                        StyledTextField {
                            text: nightLightCard.customEnd
                            Layout.preferredWidth: 60
                            onEditingFinished: { nightLightCard.customEnd = text; nightLightCard.applyNightLight(); }
                        }
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uef67"; iconColor: cTextDim; bgColor: cBgElevated }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Color temperature"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Warmer = more orange, Cooler = more blue"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 10
                        Text {
                            text: nightLightCard.nightTemp + "K"
                            color: Theme.colOnSurfaceVariant
                            font.pixelSize: 12
                            font.family: Theme.defaultFontFamily
                            Layout.preferredWidth: 46
                            horizontalAlignment: Text.AlignRight
                        }
                        Slider {
                            id: tempSlider
                            from: 1000; to: 6500; stepSize: 100
                            value: nightLightCard.nightTemp
                            Layout.preferredWidth: 130
                            
                            background: Rectangle {
                                x: tempSlider.leftPadding; y: tempSlider.topPadding + tempSlider.availableHeight / 2 - height / 2
                                implicitWidth: 130; implicitHeight: 24 // Fix: Give the slider a height so the MouseArea works!
                                width: tempSlider.availableWidth; height: 6; radius: 3
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "#ff6000" }
                                    GradientStop { position: 1.0; color: "#c8e8ff" }
                                }
                            }
                            
                            handle: Rectangle {
                                x: tempSlider.leftPadding + tempSlider.visualPosition * (tempSlider.availableWidth - width)
                                y: tempSlider.topPadding + tempSlider.availableHeight / 2 - height / 2
                                implicitWidth: 16; implicitHeight: 16
                                width: 16; height: 16; radius: 8
                                color: Theme.colPrimary
                                border.color: Qt.rgba(0,0,0,0.15); border.width: 1
                            }
                            
                            onValueChanged: {
                                if (pressed) {
                                    nightLightCard.nightTemp = Math.round(value / 100) * 100;
                                    nightLightCard.applyNightLight();
                                }
                            }
                        }
                    }
                }
            }

            // 6. Advanced
            NCard {
                sectionTitle: "Advanced"
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ued23"; iconColor: cTextDim; bgColor: cBgElevated }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Variable refresh rate"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Reduce screen tearing by matching the GPU frame rate"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: true }
                }
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueff3"; iconColor: cTextDim; bgColor: cBgElevated }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "HDR"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Enable high dynamic range if your display supports it"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: false }
                }
            }

            Item { Layout.preferredHeight: 32 }
        }
    }
}

