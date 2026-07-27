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
    property bool   showProgress:     false
    property string updateLogLines:   ""
    property string progressMsg:      "Preparing transaction..."
    property string progressPct:      "0%"
    property real   progressVal:      0.0

    // ─── Backend processes ───────────────────────────────────────────────────
    Process {
        id: updateProc
        stdout: SplitParser {
            onRead: data => {
                let line = data.trim();
                if (!line) return;
                
                let lines = root.updateLogLines.split("\n").filter(l => l !== "");
                lines.push("$ " + line);
                if (lines.length > 15) lines.shift();
                root.updateLogLines = lines.join("\n");
                
                if (line.includes("Verifying package")) root.progressMsg = "Verifying packages...";
                else if (line.includes("Installing")) root.progressMsg = "Installing packages...";
                else if (line.includes("Updating system database") || line.includes("mkinitcpio")) root.progressMsg = "Finishing setup...";
                
                let match = line.match(/\((\d+)\/(\d+)\)/);
                if (match) {
                    root.progressVal = parseInt(match[1]) / parseInt(match[2]);
                    root.progressPct = Math.round(root.progressVal * 100) + "%";
                }
            }
        }
        onExited: {
            root.progressMsg = "Update complete";
            root.progressPct = "100%";
            root.progressVal = 1.0;
            root.updateLogLines += "\n✓ All packages updated successfully";
            // Refresh list
            root.isChecking = true;
            checkProc.running = true;
        }
    }

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
    ScrollView {
        id: scrollView
        anchors.fill: parent
        anchors.bottomMargin: 28
        leftPadding: 26
        rightPadding: 26
        contentWidth: availableWidth
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: mainCol
            width: parent.width
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
                            Layout.fillWidth: true; color: cText; clip: true
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
            NCard {
                sectionTitle: ""
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
                        spacing: 1
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

                    Item { Layout.fillWidth: true }

                    // Refresh ghost button
                    Rectangle {
                        width: _rfLbl.implicitWidth + 24; height: 32; radius: 8
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
                        width: _updLbl.implicitWidth + 24; height: 32; radius: 8
                        color: ((root.updateCount - root.ignoredPackages.length) > 0 && !root.isChecking)
                               ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.4)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            id: _updLbl; anchors.centerIn: parent
                            text: root.isChecking ? "Checking…" : (root.updateCount === 0 ? "Up to date" : (root.showProgress ? "Updating…" : "Update Now"))
                            font.family: Theme.defaultFontFamily; font.pixelSize: 13
                            font.weight: 700; color: cAccentOn
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if ((root.updateCount - root.ignoredPackages.length) > 0 && !root.isChecking && !root.showProgress) {
                                    root.showProgress = true;
                                    root.updateLogLines = "";
                                    root.progressMsg = "Preparing transaction...";
                                    root.progressPct = "0%";
                                    root.progressVal = 0.0;
                                    
                                    let cmd = "yay -Syu --noconfirm";
                                    if (root.ignoredPackages.length > 0)
                                        cmd += " --ignore " + root.ignoredPackages.join(",");
                                    
                                    let wrapperCmd = "if ! sudo -n true 2>/dev/null; then SUDO_ASKPASS=~/.config/quickshell/modules/settings/zenity_askpass.sh sudo -A -v || exit 1; fi; script -qec '" + cmd + "' /dev/null | tr '\\r' '\\n' | sed -u $'s/\x1b\\[[0-9;]*[a-zA-Z]//g'";
                                    
                                    updateProc.command = ["bash", "-c", wrapperCmd];
                                    updateProc.running = true;
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
                    visible: !root.isChecking && root.updateCount === 0 && !root.showProgress
                    Text {
                        anchors.centerIn: parent
                        text: "✓  System is up to date"
                        font.family: Theme.defaultFontFamily; font.pixelSize: 13; color: cTextDim
                    }
                }

                // Progress panel
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: _progCol.implicitHeight + 30
                    color: "transparent"
                    visible: root.showProgress
                    
                    ColumnLayout {
                        id: _progCol
                        anchors { fill: parent; leftMargin: 16; rightMargin: 16; topMargin: 10 }
                        spacing: 12
                        
                        // Top text
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: root.progressMsg; font.family: Theme.defaultFontFamily
                                font.pixelSize: 13; font.weight: 700; color: cText
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: root.progressPct; font.family: Theme.monoFontFamily
                                font.pixelSize: 12; color: cTextDim
                            }
                        }
                        
                        // Progress bar
                        Rectangle {
                            Layout.fillWidth: true; height: 4; radius: 2; color: cCard
                            Rectangle {
                                height: 4; radius: 2; color: cAccent
                                width: parent.width * root.progressVal
                                Behavior on width { NumberAnimation { duration: 300 } }
                            }
                        }
                        
                        // Log box
                        Rectangle {
                            Layout.fillWidth: true; implicitHeight: 140
                            color: Qt.rgba(0,0,0,0.2); radius: 8
                            border.color: cBorder; border.width: 1
                            clip: true
                            Text {
                                anchors { fill: parent; margins: 12 }
                                text: root.updateLogLines
                                font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cTextDim
                                lineHeight: 1.4
                                verticalAlignment: Text.AlignBottom
                            }
                        }
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
            // ── CARD 2: AUTOMATION ────────────────────────────────────────
            NCard {
                sectionTitle: "Automation"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uebd1" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Check for updates automatically"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: ["Hourly", "Daily", "Weekly"]
                        current: "Daily"
                        onSelected: (v) => {}
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea35" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Notify when updates are available"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: true
                        onToggled: (v) => {}
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb1d" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Download updates in the background"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: false
                        onToggled: (v) => {}
                    }
                }
            }
            // ── CARD 3: MIRRORS ───────────────────────────────────────────
            NCard {
                sectionTitle: "Mirrors"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uef76" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Mirrorlist"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Last optimized 2 hours ago · reflector"; color: cTextDim; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: _optLbl.implicitWidth + 24; height: 32; radius: 8
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

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uebd7" }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Auto-refresh mirrors weekly"; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: true
                        onToggled: (v) => {}
                    }
                }
            }
            // ── CARD 4: HISTORY ───────────────────────────────────────────
            NCard {
                sectionTitle: "History"

                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 8; height: 8; radius: 4; color: cSuccess }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Updated <b>9 packages</b>"; textFormat: Text.RichText; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text { text: "2 days ago"; font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cTextFaint }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 8; height: 8; radius: 4; color: cSuccess }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Updated <b>1 package</b> (linux-firmware)"; textFormat: Text.RichText; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text { text: "6 days ago"; font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cTextFaint }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 8; height: 8; radius: 4; color: cSuccess }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Updated <b>23 packages</b>"; textFormat: Text.RichText; color: cText; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text { text: "14 days ago"; font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cTextFaint }
                }
            }

            Item { Layout.preferredHeight: 24 }
        }
    }

    // ────────────────────────────────────────────────────────────────────────
    //  INLINE COMPONENTS
    // ────────────────────────────────────────────────────────────────────────

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
                Layout.preferredWidth: 300
                Item { Layout.fillWidth: true }
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
}
