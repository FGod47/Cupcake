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
    property color cBgElevated: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)
    property color cBorderSoft: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)

    // Updates
    property int updateCount: 0
    property int aurUpdateCount: 0
    property string mirrorSynced: "—"
    property var updatePackages: []
    property var ignoredPackages: []
    property bool isCheckingUpdates: true

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
                    }
                } catch(e) { console.log("Update parse error:", e); }
                root.isCheckingUpdates = false;
            }
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

            Text {
                text: "System Updates"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 24
                font.weight: Font.Bold
                color: cText
            }

            NCard {
                sectionTitle: "Available Updates"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb1d"}
                        RowLabel {
                            label: root.isCheckingUpdates ? "Checking for updates..." : (root.updateCount + " packages can be updated")
                            desc: root.isCheckingUpdates ? "Please wait" : (root.aurUpdateCount + " from the AUR")
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Pill {
                        label: "Refresh"
                        active: false
                        onClicked: {
                            root.isCheckingUpdates = true;
                            checkUpdatesProcess.running = true;
                        }
                    }
                    Pill {
                        label: "Update now"
                        active: true
                        big: true
                        onClicked: {
                            let cmd = "yay -Syu";
                            if (root.ignoredPackages.length > 0) {
                                cmd += " --ignore " + root.ignoredPackages.join(",");
                            }
                            Quickshell.execDetached(["bash", "-c", "kitty -e sh -c '" + cmd + "; read -p \"Press enter to close\"'"]);
                        }
                    }
                }

                // Package list rows
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 0
                    Layout.rightMargin: 0
                    spacing: 0
                    visible: !root.isCheckingUpdates && root.updateCount > 0

                    Repeater {
                        model: root.updatePackages
                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: modelData.name + (modelData.aur ? " (AUR)" : "")
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 12
                                color: cText
                                Layout.fillWidth: true
                                topPadding: 7
                                bottomPadding: 7
                            }
                            RowLayout {
                                spacing: 4
                                Layout.topMargin: 7
                                Layout.bottomMargin: 7
                                Text {
                                    text: modelData.old + " →"
                                    font.family: Theme.monoFontFamily
                                    font.pixelSize: 12
                                    color: cTextFaint
                                }
                                Text {
                                    text: modelData.ver
                                    font.family: Theme.monoFontFamily
                                    font.pixelSize: 12
                                    color: cAccent
                                }
                                Item { Layout.preferredWidth: 8 }
                                NToggle {
                                    scale: 0.7
                                    checked: !root.ignoredPackages.includes(modelData.name)
                                    onToggled: (val) => {
                                        let name = modelData.name;
                                        let arr = root.ignoredPackages.slice();
                                        if (val) {
                                            let idx = arr.indexOf(name);
                                            if (idx !== -1) arr.splice(idx, 1);
                                        } else {
                                            if (!arr.includes(name)) arr.push(name);
                                        }
                                        root.ignoredPackages = arr;
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: cBorderSoft
                                anchors.bottom: parent.bottom
                            }
                        }
                    }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb42" }
                        RowLabel { label: "Check automatically every day" }
                    }
                    Item { Layout.fillWidth: true }
                    NToggle {
                        checked: true
                        onToggled: (c) => {
                            Quickshell.execDetached(["bash", "-c", "echo '" + c + "' > ~/.config/cupcake/.autocheck_updates"]);
                        }
                    }
                }
            }
            Item { Layout.preferredHeight: 28 }
        }
    }
}
