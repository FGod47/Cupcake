import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import Quickshell.Io
import Quickshell
import "../common"

Item {
    id: root

    // ─── Colours ────────────────────────────────────────────────────────────
    property color cText:       Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.88)
    property color cTextDim:    Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.55)
    property color cTextFaint:  Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.35)
    property color cAccent:     Theme.colPrimary
    property color cAccentOn:   Theme.colOnPrimary
    property color cCard:       Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.045)
    property color cCardHover:  Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.07)
    property color cBorder:     Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.09)
    property color cAccentDim:  Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.16)
    property color cIconBg:     Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.06)
    property color cSuccess:    "#8fce9c"

    // ─── State ──────────────────────────────────────────────────────────────
    property int    updateCount:      0
    property var    updatePackages:   []
    property var    officialPackages: []
    property var    aurPackages:      []
    property var    ignoredPackages:  []
    property bool   isChecking:       true
    property string searchQuery:      ""

    // ─── Backend process ─────────────────────────────────────────────────────
    Process {
        id: checkProc
        command: ["bash", Quickshell.env("HOME") + "/.config/cupcake/scripts/check-updates.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(text.trim());
                    root.updateCount    = d.total;
                    root.updatePackages = d.packages;
                    let off = [], au = [];
                    for (let i = 0; i < d.packages.length; i++) {
                        if (d.packages[i].aur) au.push(d.packages[i]);
                        else off.push(d.packages[i]);
                    }
                    root.officialPackages = off;
                    root.aurPackages      = au;
                } catch(e) {}
                root.isChecking = false;
            }
        }
    }

    // ────────────────────────────────────────────────────────────────────────
    //  MAIN SCROLL AREA
    // ────────────────────────────────────────────────────────────────────────
    Flickable {
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 40
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainCol
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 26 }
            spacing: 14

            // ── PAGE HEAD ─────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true; spacing: 5; Layout.topMargin: 2

                Text {
                    text: "System Updates"
                    font.family: Theme.defaultFontFamily; font.pixelSize: 28; font.weight: 800
                    font.letterSpacing: -0.6; color: cText
                }
                RowLayout {
                    spacing: 6
                    Text {
                        text: root.updateCount + " updates available"
                        font.family: Theme.defaultFontFamily; font.pixelSize: 12; color: cTextDim
                        font.weight: 600
                    }
                    Text { text: "·"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; color: cTextFaint }
                    Text {
                        text: "Checked <b>recently</b>"; textFormat: Text.RichText
                        font.family: Theme.defaultFontFamily; font.pixelSize: 12; color: cTextDim
                    }
                }
            }

            // ── TOOLBAR ───────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true; spacing: 10

                // Search box
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 36; radius: 11
                    color: cCard; border.color: cBorder; border.width: 1
                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        spacing: 8
                        Text { text: "\ueb10"; font.family: "tabler-icons"; font.pixelSize: 15; color: cTextFaint }
                        TextInput {
                            Layout.fillWidth: true; color: cText
                            font.family: Theme.defaultFontFamily; font.pixelSize: 13
                            verticalAlignment: TextInput.AlignVCenter
                            onTextChanged: root.searchQuery = text
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Filter packages…"; color: cTextFaint
                                font.family: Theme.defaultFontFamily; font.pixelSize: 13
                                visible: parent.text === ""
                            }
                        }
                    }
                }

                // Select all / Deselect all
                Rectangle {
                    implicitWidth: _selTxt.implicitWidth + 28; implicitHeight: 36; radius: 11
                    color: _selMa.containsMouse ? cCardHover : cCard
                    border.color: cBorder; border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        id: _selTxt; anchors.centerIn: parent
                        text: root.ignoredPackages.length > 0 ? "Select all" : "Deselect all"
                        font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: 600
                        color: _selMa.containsMouse ? cText : cTextDim
                    }
                    MouseArea {
                        id: _selMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
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

            // ── CARD 1: UPDATES ──────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true; radius: 16
                color: cCard; border.color: cBorder; border.width: 1
                clip: true
                implicitHeight: _updCardCol.implicitHeight

                ColumnLayout {
                    id: _updCardCol
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    spacing: 0

                    // Summary row
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: 14; spacing: 12

                        // Icon
                        Rectangle {
                            width: 36; height: 36; radius: 11; color: cAccentDim
                            Text {
                                anchors.centerIn: parent
                                text: "\uebd7"; font.family: "tabler-icons"
                                font.pixelSize: 17; color: cAccent
                            }
                        }

                        // Counts
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 1
                            Text {
                                text: (root.updateCount - root.ignoredPackages.length) + " packages selected"
                                font.family: Theme.defaultFontFamily; font.pixelSize: 14
                                font.weight: 700; color: cText
                            }
                            Text {
                                text: root.officialPackages.length + " official · " + root.aurPackages.length + " from the AUR"
                                font.family: Theme.defaultFontFamily; font.pixelSize: 12; color: cTextDim
                            }
                        }

                        // Refresh ghost button
                        Rectangle {
                            implicitWidth: _rfLbl.implicitWidth + 24; implicitHeight: 32; radius: 8
                            color: _rfMa.containsMouse ? cCardHover : "transparent"
                            border.color: cBorder; border.width: 1
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text {
                                id: _rfLbl; anchors.centerIn: parent
                                text: root.isChecking ? "Checking…" : "Refresh"
                                font.family: Theme.defaultFontFamily; font.pixelSize: 13
                                font.weight: 600; color: cText
                            }
                            MouseArea {
                                id: _rfMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { root.isChecking = true; checkProc.running = true; }
                            }
                        }

                        // Update Now primary button
                        Rectangle {
                            implicitWidth: _updLbl.implicitWidth + 24; implicitHeight: 32; radius: 8
                            color: ((root.updateCount - root.ignoredPackages.length) > 0 && !root.isChecking)
                                   ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.4)
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text {
                                id: _updLbl; anchors.centerIn: parent
                                text: root.isChecking ? "Checking…" : "Update Now"
                                font.family: Theme.defaultFontFamily; font.pixelSize: 13
                                font.weight: 700; color: cAccentOn
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if ((root.updateCount - root.ignoredPackages.length) > 0 && !root.isChecking) {
                                        let cmd = "yay -Syu";
                                        if (root.ignoredPackages.length > 0)
                                            cmd += " --ignore " + root.ignoredPackages.join(",");
                                        Quickshell.execDetached(["bash", "-c",
                                            "kitty -e sh -c '" + cmd + "; read -p \"Press enter to close\"'"]);
                                    }
                                }
                            }
                        }
                    }

                    // Loading state
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 56; color: "transparent"
                        visible: root.isChecking
                        Text {
                            anchors.centerIn: parent
                            text: "Checking for updates…"
                            font.family: Theme.defaultFontFamily; font.pixelSize: 13; color: cTextFaint
                        }
                    }

                    // Empty / up-to-date state
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 56; color: "transparent"
                        visible: !root.isChecking && root.updateCount === 0
                        Text {
                            anchors.centerIn: parent
                            text: "✓  System is up to date"
                            font.family: Theme.defaultFontFamily; font.pixelSize: 13; color: cTextDim
                        }
                    }

                    // ── Official group ─────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16; Layout.rightMargin: 16
                        Layout.topMargin: 10; Layout.bottomMargin: 4
                        visible: root.officialPackages.length > 0
                        spacing: 8
                        Text {
                            text: "Official Repositories"
                            font.family: Theme.defaultFontFamily; font.pixelSize: 11
                            font.weight: 700; font.letterSpacing: 0.8; color: cTextFaint
                        }
                        Rectangle {
                            color: Qt.rgba(1,1,1,0.06); radius: 20
                            width: _offCnt.implicitWidth + 14; height: 18
                            Text {
                                id: _offCnt; anchors.centerIn: parent
                                text: root.officialPackages.length
                                font.family: Theme.monoFontFamily; font.pixelSize: 10; color: cTextFaint
                            }
                        }
                    }

                    Repeater {
                        model: root.officialPackages
                        delegate: PkgRowItem {
                            required property var modelData
                            pkg: modelData; pkgTag: "core"; Layout.fillWidth: true
                        }
                    }

                    // ── AUR group ──────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16; Layout.rightMargin: 16
                        Layout.topMargin: 12; Layout.bottomMargin: 4
                        visible: root.aurPackages.length > 0
                        spacing: 8
                        Text {
                            text: "AUR"
                            font.family: Theme.defaultFontFamily; font.pixelSize: 11
                            font.weight: 700; font.letterSpacing: 0.8; color: cTextFaint
                        }
                        Rectangle {
                            color: Qt.rgba(1,1,1,0.06); radius: 20
                            width: _aurCnt.implicitWidth + 14; height: 18
                            Text {
                                id: _aurCnt; anchors.centerIn: parent
                                text: root.aurPackages.length
                                font.family: Theme.monoFontFamily; font.pixelSize: 10; color: cTextFaint
                            }
                        }
                    }

                    Repeater {
                        model: root.aurPackages
                        delegate: PkgRowItem {
                            required property var modelData
                            pkg: modelData; pkgTag: "AUR"; Layout.fillWidth: true
                        }
                    }

                    Item { Layout.preferredHeight: 8 }
                }
            }

            // ── CARD 2: AUTOMATION ────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true; radius: 16
                color: cCard; border.color: cBorder; border.width: 1; clip: true
                implicitHeight: _autoCol.implicitHeight

                ColumnLayout {
                    id: _autoCol
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    spacing: 0

                    // Section title
                    Text {
                        Layout.leftMargin: 16; Layout.topMargin: 14; Layout.bottomMargin: 4
                        text: "AUTOMATION"
                        font.family: Theme.defaultFontFamily; font.pixelSize: 11
                        font.weight: 700; font.letterSpacing: 0.8; color: cTextFaint
                    }

                    // Row: Check frequency
                    SettingsRow {
                        icon: "\uebd1"
                        label: "Check for updates automatically"
                        SegControl { options: ["Hourly", "Daily", "Weekly"]; activeIdx: 1 }
                    }

                    // Row: Notify
                    SettingsRow {
                        icon: "\uea35"
                        label: "Notify when updates are available"
                        TogSwitch { isOn: true }
                    }

                    // Row: Background download
                    SettingsRow {
                        icon: "\ueb1d"
                        label: "Download updates in the background"
                        TogSwitch { isOn: false }
                    }

                    Item { Layout.preferredHeight: 4 }
                }
            }

            // ── CARD 3: MIRRORS ───────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true; radius: 16
                color: cCard; border.color: cBorder; border.width: 1; clip: true
                implicitHeight: _mirrorCol.implicitHeight

                ColumnLayout {
                    id: _mirrorCol
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    spacing: 0

                    Text {
                        Layout.leftMargin: 16; Layout.topMargin: 14; Layout.bottomMargin: 4
                        text: "MIRRORS"
                        font.family: Theme.defaultFontFamily; font.pixelSize: 11
                        font.weight: 700; font.letterSpacing: 0.8; color: cTextFaint
                    }

                    SettingsRow {
                        icon: "\uef76"
                        label: "Mirrorlist"
                        desc: "Last optimized 2 hours ago · reflector"
                        Rectangle {
                            implicitWidth: _optLbl.implicitWidth + 24; implicitHeight: 32; radius: 8
                            color: _optMa.containsMouse ? cCardHover : "transparent"
                            border.color: cBorder; border.width: 1
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text {
                                id: _optLbl; anchors.centerIn: parent
                                text: "Optimize Now"
                                font.family: Theme.defaultFontFamily; font.pixelSize: 13
                                font.weight: 600; color: cText
                            }
                            MouseArea { id: _optMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                        }
                    }

                    SettingsRow {
                        icon: "\uebd7"
                        label: "Auto-refresh mirrors weekly"
                        TogSwitch { isOn: true }
                    }

                    Item { Layout.preferredHeight: 4 }
                }
            }

            // ── CARD 4: HISTORY ───────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true; radius: 16
                color: cCard; border.color: cBorder; border.width: 1; clip: true
                implicitHeight: _histCol.implicitHeight

                ColumnLayout {
                    id: _histCol
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    spacing: 0

                    Text {
                        Layout.leftMargin: 16; Layout.topMargin: 14; Layout.bottomMargin: 4
                        text: "HISTORY"
                        font.family: Theme.defaultFontFamily; font.pixelSize: 11
                        font.weight: 700; font.letterSpacing: 0.8; color: cTextFaint
                    }

                    HistRow { histLabel: "Updated <b>9 packages</b>";               histTime: "2 days ago" }
                    HistRow { histLabel: "Updated <b>1 package</b> (linux-firmware)"; histTime: "6 days ago" }
                    HistRow { histLabel: "Updated <b>23 packages</b>";               histTime: "14 days ago" }

                    Item { Layout.preferredHeight: 4 }
                }
            }

            Item { Layout.preferredHeight: 24 }
        }
    }

    // ────────────────────────────────────────────────────────────────────────
    //  INLINE COMPONENTS  (defined at Item level — access root props directly)
    // ────────────────────────────────────────────────────────────────────────

    // Package row
    component PkgRowItem: Rectangle {
        property var    pkg
        property string pkgTag: "core"

        Layout.fillWidth: true
        implicitHeight: visible ? 40 : 0
        visible: pkg && pkg.name ? pkg.name.toLowerCase().includes(root.searchQuery.toLowerCase()) : false
        color: _pkgMa.containsMouse ? Qt.rgba(1,1,1,0.025) : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        // Top separator
        Rectangle { width: parent.width; height: 1; color: cBorder; anchors.top: parent.top }

        RowLayout {
            anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
            spacing: 12

            // Checkbox
            Rectangle {
                id: _chk
                property bool ticked: pkg && pkg.name ? !root.ignoredPackages.includes(pkg.name) : false
                width: 16; height: 16; radius: 5
                color: ticked ? cAccent : "transparent"
                border.color: ticked ? cAccent : cTextFaint; border.width: 1.5
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent; text: "\uea5e"; font.family: "tabler-icons"
                    font.pixelSize: 11; font.weight: 700; color: cAccentOn
                    visible: _chk.ticked
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!pkg || !pkg.name) return;
                        let arr = root.ignoredPackages.slice();
                        let idx = arr.indexOf(pkg.name);
                        if (idx !== -1) arr.splice(idx, 1); else arr.push(pkg.name);
                        root.ignoredPackages = arr;
                    }
                }
            }

            // Name + tag pill
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                Text {
                    text: pkg && pkg.name ? pkg.name : ""
                    font.family: Theme.monoFontFamily; font.pixelSize: 12; color: cText
                }
                Rectangle {
                    color: pkgTag === "AUR" ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.15) : Qt.rgba(1,1,1,0.07)
                    radius: 5; width: _tgLbl.implicitWidth + 12; height: 16
                    Text {
                        id: _tgLbl; anchors.centerIn: parent; text: pkgTag
                        font.family: Theme.defaultFontFamily; font.pixelSize: 9; font.weight: 700
                        font.letterSpacing: 0.5
                        color: pkgTag === "AUR" ? cAccent : cTextFaint
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

            // Size
            Text {
                text: pkg && pkg.size ? pkg.size : "—"
                font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cTextFaint
                horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 52
            }
        }

        MouseArea { id: _pkgMa; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
    }

    // Settings row (icon + label + right control)
    component SettingsRow: Rectangle {
        default property alias rowControl: _ctrlSlot.data
        property string icon:  ""
        property string label: ""
        property string desc:  ""

        Layout.fillWidth: true
        implicitHeight: _srl.implicitHeight + 24
        color: "transparent"

        // top separator
        Rectangle { width: parent.width; height: 1; color: cBorder; anchors.top: parent.top }

        RowLayout {
            id: _srl
            anchors { fill: parent; leftMargin: 16; rightMargin: 16; topMargin: 12; bottomMargin: 12 }
            spacing: 12

            // Icon badge
            Rectangle {
                width: 30; height: 30; radius: 9; color: cIconBg
                Text {
                    anchors.centerIn: parent; text: parent.parent.parent.icon
                    font.family: "tabler-icons"; font.pixelSize: 15; color: cTextDim
                }
            }

            // Label column
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text {
                    text: parent.parent.parent.label
                    font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: 600; color: cText
                }
                Text {
                    text: parent.parent.parent.desc
                    font.family: Theme.defaultFontFamily; font.pixelSize: 11; color: cTextDim
                    visible: parent.parent.parent.desc !== ""
                }
            }

            // Right-side control slot
            Item {
                id: _ctrlSlot
                implicitWidth: childrenRect.width
                implicitHeight: childrenRect.height
            }
        }
    }

    // Toggle switch
    component TogSwitch: Rectangle {
        property bool isOn: false
        width: 38; height: 22; radius: 11
        color: isOn ? cAccent : Qt.rgba(1,1,1,0.10)
        Behavior on color { ColorAnimation { duration: 200 } }
        Rectangle {
            x: parent.isOn ? 16 : 2; y: 2; width: 18; height: 18; radius: 9
            color: parent.isOn ? cAccentOn : "white"
            Behavior on x     { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation  { duration: 200 } }
        }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: parent.isOn = !parent.isOn
        }
    }

    // Segmented control
    component SegControl: Rectangle {
        property var options:   []
        property int activeIdx: 1
        color: Qt.rgba(1,1,1,0.06); radius: 8
        implicitHeight: 30; implicitWidth: 210

        RowLayout {
            anchors { fill: parent; margins: 2 }
            spacing: 2
            Repeater {
                model: parent.parent.options
                delegate: Rectangle {
                    required property int   index
                    required property string modelData
                    Layout.fillWidth: true; Layout.fillHeight: true; radius: 6
                    property bool active: index === parent.parent.parent.activeIdx
                    color: active ? cAccent : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text {
                        anchors.centerIn: parent; text: modelData
                        font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: 600
                        color: parent.active ? cAccentOn : cTextDim
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: parent.parent.parent.parent.activeIdx = parent.index
                    }
                }
            }
        }
    }

    // History row
    component HistRow: Rectangle {
        property string histLabel: ""
        property string histTime:  ""
        Layout.fillWidth: true; implicitHeight: 44; color: "transparent"
        Rectangle { width: parent.width; height: 1; color: cBorder; anchors.top: parent.top }
        RowLayout {
            anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
            spacing: 12
            Rectangle { width: 7; height: 7; radius: 4; color: cSuccess }
            Text {
                Layout.fillWidth: true; text: histLabel
                font.family: Theme.defaultFontFamily; font.pixelSize: 13; color: cText
                textFormat: Text.RichText
            }
            Text {
                text: histTime
                font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cTextFaint
            }
        }
    }
}
