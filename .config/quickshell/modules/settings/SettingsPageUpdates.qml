import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import Quickshell.Io
import Quickshell
import "../common"

Item {
    id: root

    // ── Colours (mapped to theme tokens) ──────────────────────────────────
    property color cText:        Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.88)
    property color cTextDim:     Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.55)
    property color cTextFaint:   Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.35)
    property color cAccent:      Theme.colPrimary
    property color cAccentOn:    Theme.colOnPrimary
    property color cCard:        Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.045)
    property color cCardHover:   Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.07)
    property color cBorder:      Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.09)
    property color cAccentDim:   Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.16)
    property color cSuccess:     "#8fce9c"
    property color cDanger:      "#e08a82"
    property color cBgElevated:  Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.06)

    // ── Update state ──────────────────────────────────────────────────────
    property int    updateCount:      0
    property int    aurUpdateCount:   0
    property var    updatePackages:   []
    property var    officialPackages: []
    property var    aurPackages:      []
    property var    ignoredPackages:  []
    property bool   isChecking:       true
    property string searchQuery:      ""

    // ── Fetch updates ─────────────────────────────────────────────────────
    Process {
        id: checkProc
        command: ["bash", Quickshell.env("HOME") + "/.config/cupcake/scripts/check-updates.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let txt = text.trim();
                    if (txt) {
                        let data = JSON.parse(txt);
                        root.updateCount    = data.total;
                        root.aurUpdateCount = data.aur;
                        root.updatePackages = data.packages;
                        let off = [], au = [];
                        for (let i = 0; i < data.packages.length; i++) {
                            if (data.packages[i].aur) au.push(data.packages[i]);
                            else                      off.push(data.packages[i]);
                        }
                        root.officialPackages = off;
                        root.aurPackages      = au;
                    }
                } catch(e) { console.log("Update parse error:", e); }
                root.isChecking = false;
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    //  LOCAL COMPONENTS
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    // --- Card shell ---
    component Card: Rectangle {
        default property alias content: inner.data
        property string sectionTitle: ""
        Layout.fillWidth: true
        color: cCard
        border.color: cBorder
        border.width: 1
        radius: 16
        clip: true
        implicitHeight: inner.implicitHeight + (sectionTitle !== "" ? hdr.height + 10 : 0) + 24

        RowLayout {
            id: hdr
            visible: sectionTitle !== ""
            anchors { top: parent.top; left: parent.left; right: parent.right
                      topMargin: 14; leftMargin: 16; rightMargin: 16 }
            Text {
                text: sectionTitle.toUpperCase()
                font.family: Theme.defaultFontFamily
                font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8
                color: cTextFaint
            }
        }

        ColumnLayout {
            id: inner
            anchors {
                top: sectionTitle !== "" ? hdr.bottom : parent.top
                left: parent.left; right: parent.right
                topMargin: sectionTitle !== "" ? 4 : 0
            }
            spacing: 0
        }
    }

    // --- Row item (with top separator) ---
    component Row: Rectangle {
        default property alias content: rlay.data
        Layout.fillWidth: true
        implicitHeight: rlay.implicitHeight
        color: "transparent"
        Rectangle { width: parent.width; height: 1; color: cBorder; anchors.top: parent.top }
        RowLayout {
            id: rlay
            anchors { fill: parent; leftMargin: 16; rightMargin: 16; topMargin: 12; bottomMargin: 12 }
            spacing: 12
        }
    }

    // --- Row icon badge ---
    component RowIcon: Rectangle {
        property string icon: ""
        width: 30; height: 30; radius: 9
        color: cBgElevated
        Text {
            anchors.centerIn: parent
            text: parent.icon; font.family: "tabler-icons"; font.pixelSize: 15; color: cTextDim
        }
    }

    // --- Toggle ---
    component Tog: Rectangle {
        property bool on: false
        signal toggled()
        width: 38; height: 22; radius: 11
        color: on ? cAccent : Qt.rgba(1,1,1,0.10)
        Behavior on color { ColorAnimation { duration: 200 } }
        Rectangle {
            x: parent.on ? 16 : 2; y: 2; width: 18; height: 18; radius: 9
            color: parent.on ? cAccentOn : "white"
            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 200 } }
        }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: { parent.on = !parent.on; parent.toggled() }
        }
    }

    // --- Segmented control ---
    component Segmented: Rectangle {
        property var options: []
        property int selected: 1
        color: Qt.rgba(1,1,1,0.06); radius: 8
        implicitHeight: 30
        implicitWidth: 210
        RowLayout {
            anchors { fill: parent; margins: 2 }
            spacing: 2
            Repeater {
                model: parent.parent.options
                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true; radius: 6
                    color: index === parent.parent.parent.selected ? cAccent : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: 600
                        color: index === parent.parent.parent.selected ? cAccentOn : cTextDim
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: parent.parent.parent.parent.selected = index
                    }
                }
            }
        }
    }

    // --- Btn (ghost) ---
    component Btn: Rectangle {
        property string label: ""
        signal clicked()
        implicitHeight: 34
        implicitWidth: btnLbl.implicitWidth + 28
        color: btnMa.containsMouse ? cCardHover : cCard
        border.color: cBorder; border.width: 1; radius: 9
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
            id: btnLbl; anchors.centerIn: parent
            text: parent.label
            font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600; color: cText
        }
        MouseArea {
            id: btnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    // --- BtnPrimary ---
    component BtnPrimary: Rectangle {
        property string label: ""
        property bool enabled: true
        signal clicked()
        implicitHeight: 34
        implicitWidth: pLbl.implicitWidth + 28
        radius: 9
        color: enabled ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.45)
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
            id: pLbl; anchors.centerIn: parent
            text: parent.label
            font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 700; color: cAccentOn
        }
        MouseArea {
            anchors.fill: parent; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            hoverEnabled: true
            onClicked: if (parent.enabled) parent.clicked()
        }
    }

    // --- Package checkbox ---
    component PkgCheck: Rectangle {
        property bool checked: false
        signal toggled()
        width: 16; height: 16; radius: 5
        color: checked ? cAccent : "transparent"
        border.color: checked ? cAccent : cTextFaint; border.width: 1.5
        Behavior on color { ColorAnimation { duration: 150 } }
        Text {
            anchors.centerIn: parent; text: "\uea5e"; font.family: "tabler-icons"
            font.pixelSize: 11; font.weight: 700; color: cAccentOn; visible: parent.checked
        }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: parent.toggled()
        }
    }

    // --- Package row ---
    component PkgRow: Rectangle {
        property var pkg
        property string tag: "core"

        Layout.fillWidth: true
        implicitHeight: visible ? 40 : 0
        visible: pkg && pkg.name ? pkg.name.toLowerCase().includes(root.searchQuery.toLowerCase()) : false
        color: pkgMa.containsMouse ? Qt.rgba(1,1,1,0.025) : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        Rectangle { width: parent.width; height: 1; color: cBorder; anchors.top: parent.top }

        RowLayout {
            anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
            spacing: 12

            PkgCheck {
                checked: pkg && pkg.name ? !root.ignoredPackages.includes(pkg.name) : false
                onToggled: {
                    if (!pkg || !pkg.name) return;
                    let arr = root.ignoredPackages.slice();
                    let idx = arr.indexOf(pkg.name);
                    if (idx !== -1) arr.splice(idx, 1); else arr.push(pkg.name);
                    root.ignoredPackages = arr;
                }
            }

            // Name + tag
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                Text {
                    text: pkg && pkg.name ? pkg.name : ""
                    font.family: Theme.monoFontFamily; font.pixelSize: 12; color: cText
                }
                Rectangle {
                    color: (tag === "AUR") ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.15)
                                           : Qt.rgba(1,1,1,0.07)
                    radius: 5; width: tagTxt.implicitWidth + 12; height: 16
                    Text {
                        id: tagTxt; anchors.centerIn: parent
                        text: tag
                        font.family: Theme.defaultFontFamily; font.pixelSize: 9; font.weight: 700
                        font.letterSpacing: 0.5
                        color: (tag === "AUR") ? cAccent : cTextFaint
                    }
                }
            }

            // Version old → new
            RowLayout {
                spacing: 4
                Text { text: pkg && pkg.old ? pkg.old : ""; font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cTextFaint }
                Text { text: "→"; font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cTextFaint }
                Text { text: pkg && pkg.ver ? pkg.ver : ""; font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cAccent; font.weight: 600 }
            }

            // Size placeholder
            Text {
                text: pkg && pkg.size ? pkg.size : "—"
                font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cTextFaint
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 52
            }
        }

        MouseArea { id: pkgMa; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    //  MAIN LAYOUT
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    Flickable {
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 60
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainCol
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 26 }
            spacing: 16

            // ── Page Head ──────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6; Layout.topMargin: 4

                Text {
                    text: "System Updates"
                    font.family: Theme.defaultFontFamily; font.pixelSize: 28; font.weight: 800
                    font.letterSpacing: -0.6; color: cText
                }

                RowLayout {
                    spacing: 0
                    Text {
                        text: "<b>" + root.updateCount + "</b> updates available"
                        font.family: Theme.defaultFontFamily; font.pixelSize: 12; color: cTextDim
                        textFormat: Text.RichText
                    }
                    Text { text: "  ·  "; font.family: Theme.defaultFontFamily; font.pixelSize: 12; color: cTextFaint }
                    Text {
                        text: "Checked <b>recently</b>"
                        font.family: Theme.defaultFontFamily; font.pixelSize: 12; color: cTextDim
                        textFormat: Text.RichText
                    }
                }
            }

            // ── Toolbar: search + select all ───────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Search
                Rectangle {
                    Layout.fillWidth: true; height: 36; radius: 11
                    color: cCard; border.color: cBorder; border.width: 1
                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        spacing: 8
                        Text { text: "\ueb10"; font.family: "tabler-icons"; font.pixelSize: 15; color: cTextFaint }
                        TextInput {
                            Layout.fillWidth: true
                            color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13
                            verticalAlignment: TextInput.AlignVCenter
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Filter packages…"; color: cTextFaint
                                font.family: Theme.defaultFontFamily; font.pixelSize: 13
                                visible: parent.text === ""
                            }
                            onTextChanged: root.searchQuery = text
                        }
                    }
                }

                // Select all
                Rectangle {
                    implicitWidth: selTxt.implicitWidth + 28; height: 36; radius: 11
                    color: selMa.containsMouse ? cCardHover : cCard
                    border.color: cBorder; border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        id: selTxt; anchors.centerIn: parent
                        text: root.ignoredPackages.length > 0 ? "Select all" : "Deselect all"
                        font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: 600
                        color: selMa.containsMouse ? cText : cTextDim
                    }
                    MouseArea {
                        id: selMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.ignoredPackages.length > 0) {
                                root.ignoredPackages = [];
                            } else {
                                let all = [];
                                for (let i = 0; i < root.updatePackages.length; i++) all.push(root.updatePackages[i].name);
                                root.ignoredPackages = all;
                            }
                        }
                    }
                }
            }

            // ── Card 1: Updates ────────────────────────────────────────────
            Card {
                Layout.fillWidth: true

                // Summary row
                RowLayout {
                    Layout.fillWidth: true; Layout.margins: 14; Layout.bottomMargin: 10
                    spacing: 12

                    // Icon
                    Rectangle {
                        width: 36; height: 36; radius: 11; color: cAccentDim
                        Text {
                            anchors.centerIn: parent
                            text: "\uebd7"; font.family: "tabler-icons"; font.pixelSize: 17; color: cAccent
                        }
                    }

                    // Title + sub
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text {
                            text: (root.updateCount - root.ignoredPackages.length) + " packages selected"
                            font.family: Theme.defaultFontFamily; font.pixelSize: 14; font.weight: 700; color: cText
                        }
                        Text {
                            text: root.officialPackages.length + " official · " + root.aurPackages.length + " from the AUR"
                            font.family: Theme.defaultFontFamily; font.pixelSize: 12; color: cTextDim
                        }
                    }

                    // Refresh button
                    Btn {
                        label: root.isChecking ? "Checking…" : "Refresh"
                        onClicked: {
                            root.isChecking = true;
                            checkProc.running = true;
                        }
                    }

                    // Update Now button
                    BtnPrimary {
                        label: root.isChecking ? "Checking…" : "Update Now"
                        enabled: (root.updateCount - root.ignoredPackages.length) > 0 && !root.isChecking
                        onClicked: {
                            if (enabled) {
                                let cmd = "yay -Syu";
                                if (root.ignoredPackages.length > 0)
                                    cmd += " --ignore " + root.ignoredPackages.join(",");
                                Quickshell.execDetached(["bash", "-c",
                                    "kitty -e sh -c '" + cmd + "; read -p \"Press enter to close\"'"]);
                            }
                        }
                    }
                }

                // Official group
                RowLayout {
                    Layout.fillWidth: true; Layout.leftMargin: 16; Layout.rightMargin: 16
                    Layout.topMargin: 4; Layout.bottomMargin: 4
                    visible: root.officialPackages.length > 0
                    spacing: 8
                    Text {
                        text: "Official Repositories"; font.family: Theme.defaultFontFamily
                        font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8; color: cTextFaint
                    }
                    Rectangle {
                        color: Qt.rgba(1,1,1,0.06); radius: 20
                        width: offCnt.implicitWidth + 14; height: 18
                        Text {
                            id: offCnt; anchors.centerIn: parent
                            text: root.officialPackages.length
                            font.family: Theme.monoFontFamily; font.pixelSize: 10; color: cTextFaint
                        }
                    }
                }

                Repeater {
                    model: root.officialPackages
                    delegate: PkgRow { pkg: modelData; tag: "core"; Layout.fillWidth: true }
                }

                // AUR group
                RowLayout {
                    Layout.fillWidth: true; Layout.leftMargin: 16; Layout.rightMargin: 16
                    Layout.topMargin: 12; Layout.bottomMargin: 4
                    visible: root.aurPackages.length > 0
                    spacing: 8
                    Text {
                        text: "AUR"; font.family: Theme.defaultFontFamily
                        font.pixelSize: 11; font.weight: 700; font.letterSpacing: 0.8; color: cTextFaint
                    }
                    Rectangle {
                        color: Qt.rgba(1,1,1,0.06); radius: 20
                        width: aurCnt.implicitWidth + 14; height: 18
                        Text {
                            id: aurCnt; anchors.centerIn: parent
                            text: root.aurPackages.length
                            font.family: Theme.monoFontFamily; font.pixelSize: 10; color: cTextFaint
                        }
                    }
                }

                Repeater {
                    model: root.aurPackages
                    delegate: PkgRow { pkg: modelData; tag: "AUR"; Layout.fillWidth: true }
                }

                // Empty state
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 60
                    color: "transparent"
                    visible: root.updateCount === 0 && !root.isChecking
                    Text {
                        anchors.centerIn: parent
                        text: "✓  System is up to date"
                        font.family: Theme.defaultFontFamily; font.pixelSize: 13; color: cTextDim
                    }
                }

                // Loading state
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 60
                    color: "transparent"
                    visible: root.isChecking
                    Text {
                        anchors.centerIn: parent
                        text: "Checking for updates…"
                        font.family: Theme.defaultFontFamily; font.pixelSize: 13; color: cTextFaint
                    }
                }

                Item { Layout.preferredHeight: 6 }
            }

            // ── Card 2: Automation ─────────────────────────────────────────
            Card { sectionTitle: "Automation"

                Row {
                    RowIcon { icon: "\uebd1" }
                    ColumnLayout { Layout.fillWidth: true; spacing: 1
                        Text { text: "Check for updates automatically"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600; color: cText }
                    }
                    Segmented { options: ["Hourly", "Daily", "Weekly"]; selected: 1 }
                }

                Row {
                    RowIcon { icon: "\uea35" }
                    ColumnLayout { Layout.fillWidth: true; spacing: 1
                        Text { text: "Notify when updates are available"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600; color: cText }
                    }
                    Tog { on: true }
                }

                Row {
                    RowIcon { icon: "\ueb1d" }
                    ColumnLayout { Layout.fillWidth: true; spacing: 1
                        Text { text: "Download updates in the background"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600; color: cText }
                    }
                    Tog { on: false }
                }
            }

            // ── Card 3: Mirrors ────────────────────────────────────────────
            Card { sectionTitle: "Mirrors"

                Row {
                    RowIcon { icon: "\uef76" }
                    ColumnLayout { Layout.fillWidth: true; spacing: 2
                        Text { text: "Mirrorlist"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600; color: cText }
                        Text { text: "Last optimized 2 hours ago · reflector"; font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: cTextDim }
                    }
                    Btn { label: "Optimize Now" }
                }

                Row {
                    RowIcon { icon: "\uebd7" }
                    ColumnLayout { Layout.fillWidth: true; spacing: 1
                        Text { text: "Auto-refresh mirrors weekly"; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600; color: cText }
                    }
                    Tog { on: true }
                }
            }

            // ── Card 4: History ────────────────────────────────────────────
            Card { sectionTitle: "History"

                HistoryEntry { dotColor: cSuccess; label: "Updated <b>9 packages</b>"; time: "2 days ago" }
                HistoryEntry { dotColor: cSuccess; label: "Updated <b>1 package</b> (linux-firmware)"; time: "6 days ago" }
                HistoryEntry { dotColor: cSuccess; label: "Updated <b>23 packages</b>"; time: "14 days ago" }
            }

            Item { Layout.preferredHeight: 30 }
        }
    }

    // ── History entry sub-component ────────────────────────────────────────
    component HistoryEntry: Rectangle {
        property color dotColor: cSuccess
        property string label: ""
        property string time: ""
        Layout.fillWidth: true; implicitHeight: 44; color: "transparent"
        Rectangle { width: parent.width; height: 1; color: cBorder; anchors.top: parent.top }
        RowLayout {
            anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
            spacing: 12
            Rectangle { width: 7; height: 7; radius: 4; color: parent.parent.dotColor }
            Text {
                Layout.fillWidth: true
                text: parent.parent.label
                font.family: Theme.defaultFontFamily; font.pixelSize: 13; color: cText
                textFormat: Text.RichText
            }
            Text {
                text: parent.parent.time
                font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cTextFaint
            }
        }
    }
}
