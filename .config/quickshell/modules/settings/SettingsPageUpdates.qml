import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import Quickshell.Io
import Quickshell
import "../common"

Item {
    id: root

    property color cText: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.88)
    property color cTextDim: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.6)
    property color cTextFaint: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.4)
    property color cAccent: Theme.colPrimary
    property color cAccentOn: Theme.colOnPrimary
    property color cBgElevated: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
    property color cBorderSoft: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
    property color cBgHover: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
    property color cSuccess: "#8fce9c"
    property color cDanger: "#e08a82"

    // Updates state
    property int updateCount: 0
    property int aurUpdateCount: 0
    property var updatePackages: []
    property var officialPackages: []
    property var aurPackages: []
    property var ignoredPackages: []
    property bool isCheckingUpdates: true
    property string searchQuery: ""

    Process {
        id: checkUpdatesProcess
        command: ["bash", Quickshell.env("HOME") + "/.config/cupcake/scripts/check-updates.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let txt = text.trim();
                    if (txt) {
                        let data = JSON.parse(txt);
                        root.updateCount = data.total;
                        root.aurUpdateCount = data.aur;
                        root.updatePackages = data.packages;
                        
                        let off = [];
                        let au = [];
                        for (let i = 0; i < data.packages.length; i++) {
                            if (data.packages[i].aur) au.push(data.packages[i]);
                            else off.push(data.packages[i]);
                        }
                        root.officialPackages = off;
                        root.aurPackages = au;
                    }
                } catch(e) { console.log("Update parse error:", e); }
                root.isCheckingUpdates = false;
            }
        }
    }

    // Components
    component Pill: Rectangle {
        id: pill
        property string label: ""
        property bool active: false
        property bool danger: false
        property bool big: false
        signal clicked()

        radius: 8
        height: big ? 34 : 26
        width: Math.max(pillText.implicitWidth + (big ? 32 : 24), 30)
        color: active ? cAccent : cBgElevated

        Text {
            id: pillText
            anchors.centerIn: parent
            text: pill.label
            font.family: Theme.defaultFontFamily
            font.pixelSize: 12
            font.weight: pill.big ? Font.SemiBold : Font.Medium
            color: active ? Theme.colOnPrimary : (pill.danger ? cDanger : cTextDim)
        }
        MouseArea {
            anchors.fill: parent
            onClicked: pill.clicked()
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onEntered: pill.color = pill.active ? Qt.tint(cAccent, Qt.rgba(1,1,1,0.1)) : cBgHover
            onExited: pill.color = pill.active ? cAccent : cBgElevated
        }
    }

    component RowLabel: ColumnLayout {
        property string label: ""
        property string desc: ""
        spacing: 1
        Layout.fillWidth: true
        Text {
            text: parent.label
            color: cText
            font.family: Theme.defaultFontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
        }
        Text {
            text: parent.desc
            color: cTextDim
            font.family: Theme.defaultFontFamily
            font.pixelSize: 11
            font.weight: Font.Normal
            opacity: 0.85
            visible: text !== ""
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }
    }

    component PkgCheck: Rectangle {
        property bool checked: false
        signal clicked()
        width: 16
        height: 16
        radius: 5
        color: checked ? cAccent : "transparent"
        border.color: checked ? cAccent : cTextFaint
        border.width: checked ? 0 : 1.5
        Text {
            anchors.centerIn: parent
            text: "\uea5e" // check icon
            font.family: "tabler-icons"
            font.pixelSize: 11
            color: cAccentOn
            visible: parent.checked
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
    
    component PkgRow: Rectangle {
        property var modelData
        property string tag
        
        visible: modelData.name.toLowerCase().includes(root.searchQuery.toLowerCase())
        Layout.fillWidth: true
        height: visible ? 38 : 0
        color: ma.containsMouse ? Qt.rgba(1,1,1,0.025) : "transparent"
        
        Rectangle { width: parent.width; height: 1; color: cBorderSoft; anchors.top: parent.top }
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12
            
            PkgCheck {
                checked: !root.ignoredPackages.includes(modelData.name)
                onClicked: {
                    let name = modelData.name;
                    let arr = root.ignoredPackages.slice();
                    let idx = arr.indexOf(name);
                    if (idx !== -1) arr.splice(idx, 1);
                    else arr.push(name);
                    root.ignoredPackages = arr;
                }
            }
            
            RowLayout {
                spacing: 8
                Layout.fillWidth: true
                Text {
                    text: modelData.name
                    font.family: Theme.monoFontFamily
                    font.pixelSize: 12
                    color: cText
                }
                Rectangle {
                    color: modelData.aur ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.15) : Qt.rgba(1,1,1,0.07)
                    radius: 5
                    width: tagText.implicitWidth + 12
                    height: 16
                    Text {
                        id: tagText
                        anchors.centerIn: parent
                        text: tag
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        font.letterSpacing: 0.5
                        color: modelData.aur ? cAccent : cTextFaint
                    }
                }
            }
            
            RowLayout {
                spacing: 4
                Text { text: modelData.old; font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cTextFaint }
                Text { text: "→"; font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cTextFaint }
                Text { text: modelData.ver; font.family: Theme.monoFontFamily; font.pixelSize: 11; color: cAccent; font.weight: Font.DemiBold }
            }
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: contentCol.implicitHeight + 60
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: contentCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 30
            spacing: 24

            // Page Head
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                Text {
                    text: "System Updates"
                    font.family: Theme.defaultFontFamily
                    font.pixelSize: 28
                    font.weight: Font.ExtraBold
                    font.letterSpacing: -0.6
                    color: cText
                }
                RowLayout {
                    spacing: 12
                    Text {
                        text: (root.updateCount + " updates available")
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 12
                        font.weight: Font.SemiBold
                        color: cText
                    }
                    Text { text: "·"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; color: cTextFaint }
                    Text {
                        text: "Checked recently"
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 12
                        font.weight: Font.SemiBold
                        color: cText
                    }
                }
            }

            // Toolbar
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                
                // Search box
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 11
                    color: cBgElevated
                    border.color: cBorderSoft
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8
                        Text {
                            text: "\ueb10" // search icon
                            font.family: "tabler-icons"
                            font.pixelSize: 15
                            color: cTextFaint
                        }
                        TextInput {
                            Layout.fillWidth: true
                            color: cText
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 12.5
                            verticalAlignment: TextInput.AlignVCenter
                            Text {
                                text: "Filter packages..."
                                color: cTextFaint
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 12.5
                                visible: parent.text === ""
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            onTextChanged: root.searchQuery = text
                        }
                    }
                }
                
                // Select all btn
                Rectangle {
                    Layout.preferredWidth: selAllText.implicitWidth + 28
                    Layout.preferredHeight: 36
                    radius: 11
                    color: selAllMa.containsMouse ? cBgHover : cBgElevated
                    border.color: cBorderSoft
                    Text {
                        id: selAllText
                        anchors.centerIn: parent
                        text: root.ignoredPackages.length > 0 ? "Select all" : "Deselect all"
                        font.family: Theme.defaultFontFamily
                        font.pixelSize: 12
                        font.weight: Font.SemiBold
                        color: selAllMa.containsMouse ? cText : cTextDim
                    }
                    MouseArea {
                        id: selAllMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.ignoredPackages.length > 0) {
                                root.ignoredPackages = []; // select all
                            } else {
                                let all = [];
                                for (let i = 0; i < root.updatePackages.length; i++) all.push(root.updatePackages[i].name);
                                root.ignoredPackages = all; // deselect all
                            }
                        }
                    }
                }
            }

            // Updates Card
            NCard {
                Layout.fillWidth: true
                sectionTitle: "" // Removed text title, using custom summary row instead
                
                // Custom Header/Summary Row
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: 16
                    spacing: 12
                    
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 11
                        color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.16)
                        Text {
                            anchors.centerIn: parent
                            text: "\ueb1d" // download icon
                            font.family: "tabler-icons"
                            font.pixelSize: 17
                            color: cAccent
                        }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: (root.updateCount - root.ignoredPackages.length) + " packages selected"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            color: cText
                        }
                        Text {
                            text: root.officialPackages.length + " official · " + root.aurPackages.length + " from the AUR"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11.5
                            color: cTextDim
                        }
                    }
                    
                    Pill {
                        label: "Refresh"
                        active: false
                        onClicked: {
                            root.isCheckingUpdates = true;
                            checkUpdatesProcess.running = true;
                        }
                    }
                    Pill {
                        label: root.isCheckingUpdates ? "Checking..." : "Update Now"
                        active: (root.updateCount - root.ignoredPackages.length) > 0 && !root.isCheckingUpdates
                        big: true
                        onClicked: {
                            if (active) {
                                let cmd = "yay -Syu";
                                if (root.ignoredPackages.length > 0) {
                                    cmd += " --ignore " + root.ignoredPackages.join(",");
                                }
                                Quickshell.execDetached(["bash", "-c", "kitty -e sh -c '" + cmd + "; read -p \"Press enter to close\"'"]);
                            }
                        }
                    }
                }
                
                // Packages list
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    visible: root.updateCount > 0
                    
                    // Official label
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                        Layout.topMargin: 12
                        Layout.bottomMargin: 4
                        visible: root.officialPackages.length > 0
                        spacing: 8
                        Text {
                            text: "OFFICIAL REPOSITORIES"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 10.5
                            font.weight: Font.Bold
                            font.letterSpacing: 0.8
                            color: cTextFaint
                        }
                        Rectangle {
                            width: offCountText.implicitWidth + 14
                            height: 18
                            radius: 9
                            color: Qt.rgba(1,1,1,0.06)
                            Text {
                                id: offCountText
                                anchors.centerIn: parent
                                text: root.officialPackages.length
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 10
                                color: cTextFaint
                            }
                        }
                    }
                    
                    Repeater {
                        model: root.officialPackages
                        delegate: PkgRow {
                            modelData: model
                            tag: "core"
                        }
                    }
                    
                    // AUR label
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                        Layout.topMargin: 12
                        Layout.bottomMargin: 4
                        visible: root.aurPackages.length > 0
                        spacing: 8
                        Text {
                            text: "AUR"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 10.5
                            font.weight: Font.Bold
                            font.letterSpacing: 0.8
                            color: cTextFaint
                        }
                        Rectangle {
                            width: aurCountText.implicitWidth + 14
                            height: 18
                            radius: 9
                            color: Qt.rgba(1,1,1,0.06)
                            Text {
                                id: aurCountText
                                anchors.centerIn: parent
                                text: root.aurPackages.length
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 10
                                color: cTextFaint
                            }
                        }
                    }
                    
                    Repeater {
                        model: root.aurPackages
                        delegate: PkgRow {
                            modelData: model
                            tag: "AUR"
                        }
                    }
                }
            }

            // Automation Card
            NCard {
                sectionTitle: "Automation"
                
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uebd1" } // clock icon
                        RowLabel { label: "Check for updates automatically"; desc: "" }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        Layout.preferredHeight: 30
                        Layout.preferredWidth: 200
                        radius: 8
                        color: Qt.rgba(1,1,1,0.06)
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 2
                            spacing: 2
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 6; color: "transparent"
                                Text { anchors.centerIn: parent; text: "Hourly"; font.family: Theme.defaultFontFamily; font.pixelSize: 11.5; font.weight: Font.SemiBold; color: cTextDim }
                            }
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 6; color: cAccent
                                Text { anchors.centerIn: parent; text: "Daily"; font.family: Theme.defaultFontFamily; font.pixelSize: 11.5; font.weight: Font.SemiBold; color: cAccentOn }
                            }
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 6; color: "transparent"
                                Text { anchors.centerIn: parent; text: "Weekly"; font.family: Theme.defaultFontFamily; font.pixelSize: 11.5; font.weight: Font.SemiBold; color: cTextDim }
                            }
                        }
                    }
                }
                
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea35" } // bell icon
                        RowLabel { label: "Notify when updates are available"; desc: "" }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: true }
                }
                
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb1d" } // download icon
                        RowLabel { label: "Download updates in the background"; desc: "" }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: false }
                }
            }

            // Mirrors Card
            NCard {
                sectionTitle: "Mirrors"
                
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uef76" } // server icon
                        RowLabel { label: "Mirrorlist"; desc: "Last optimized 2 hours ago · reflector" }
                    }
                    Item { Layout.fillWidth: true }
                    Pill { label: "Optimize Now"; active: false }
                }
                
                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb1d" } // refresh icon 
                        RowLabel { label: "Auto-refresh mirrors weekly"; desc: "" }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle { checked: true }
                }
            }
            
            // History Card
            NCard {
                sectionTitle: "History"
                
                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 7; height: 7; radius: 3.5; color: cSuccess }
                        Text { text: "Updated 9 packages"; font.family: Theme.defaultFontFamily; font.pixelSize: 12.5; font.weight: Font.SemiBold; color: cText }
                    }
                    Item { Layout.fillWidth: true }
                    Text { text: "2 days ago"; font.family: Theme.monoFontFamily; font.pixelSize: 10.5; color: cTextFaint }
                }
                
                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 7; height: 7; radius: 3.5; color: cSuccess }
                        Text { text: "Updated 1 package (linux-firmware)"; font.family: Theme.defaultFontFamily; font.pixelSize: 12.5; font.weight: Font.SemiBold; color: cText }
                    }
                    Item { Layout.fillWidth: true }
                    Text { text: "6 days ago"; font.family: Theme.monoFontFamily; font.pixelSize: 10.5; color: cTextFaint }
                }
                
                NRow {
                    RowLayout {
                        spacing: 12
                        Rectangle { width: 7; height: 7; radius: 3.5; color: cSuccess }
                        Text { text: "Updated 23 packages"; font.family: Theme.defaultFontFamily; font.pixelSize: 12.5; font.weight: Font.SemiBold; color: cText }
                    }
                    Item { Layout.fillWidth: true }
                    Text { text: "14 days ago"; font.family: Theme.monoFontFamily; font.pixelSize: 10.5; color: cTextFaint }
                }
            }

            Item { Layout.preferredHeight: 28 }
        }
    }
}
