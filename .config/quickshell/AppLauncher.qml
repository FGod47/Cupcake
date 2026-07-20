pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Wayland
import "theme"
import "modules/common"
import "modules/settings"

// Use the same pattern as WallpaperSwitcher.qml (which works as standalone)
// Center it on screen via a centered Item inside the window
PanelWindow {
    id: root

    // Anchor left+right+bottom only (4-sided anchor breaks layer shell)
    anchors {
        left: true
        right: true
        bottom: true
    }

    // Make this tall enough to cover the screen for the scrim effect
    // We'll set it to a very large value — Wayland clips to the screen
    implicitHeight: 9000

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "cupcake-launcher"
    color: "transparent"

    property color colSurface:               Theme.colSurface
    property color colSurfaceContainer:      Theme.colSurfaceContainer // pure black
    property color colSurfaceContainerHigh:  Theme.colSurfaceContainerHigh // very dark grey for search
    property color colOnSurface:             Theme.colOnSurface // match bar fg
    property color colOnSurfaceVariant:      Theme.colOnSurfaceVariant
    property color colOutline:               Theme.colOutline
    property color colPrimary:               Theme.colPrimary // match bar accent
    
    // Derived colors for UI
    property color inputBg:                  root.colSurfaceContainerHigh
    property color inputBorder:              Qt.rgba(root.colOutline.r, root.colOutline.g, root.colOutline.b, 0.5)
    property color hoverBg:                  Qt.rgba(root.colOnSurface.r, root.colOnSurface.g, root.colOnSurface.b, 0.08)

    property real bgOpacity: 0.80

    Process {
        id: initLauncherOpacity
        command: ["cat", Theme.homeDir + "/.config/cupcake/.launcher_opacity"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) { let v = parseFloat(text.trim()); if (!isNaN(v)) root.bgOpacity = v; }
            }
        }
    }
    Timer { interval: 500; running: true; repeat: true; onTriggered: initLauncherOpacity.running = true }

    // ── State ─────────────────────────────────────────────────────────
    // DesktopEntries loads asynchronously — bind reactively
    property var allApps: DesktopEntries.applications.values
    property var filteredApps: allApps   // starts populated once entries load
    property bool userDismissed: false
    property string currentQuery: ""

    // Whenever DesktopEntries finishes scanning, re-apply the current filter
    onAllAppsChanged: {
        filterApps(currentQuery);
    }

    // 1.0 = hidden below screen, 0.0 = fully visible
    property bool isOpen: false

    property string localAppLauncherStyle: "Hover"
    Process {
        command: ["cat", Quickshell.env("HOME") + "/.config/cupcake/.applauncher_style"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let s = text.trim();
                if (s !== "") root.localAppLauncherStyle = s;
                openTimer.start();
            }
        }
    }

    Timer {
        id: openTimer
        interval: 50
        running: false
        repeat: false
        onTriggered: {
            isOpen = true;
            searchField.forceActiveFocus();
        }
    }


    function filterApps(query) {
        currentQuery = query;
        let q = query.toLowerCase().trim();
        if (q.length === 0) {
            filteredApps = allApps;
        } else {
            filteredApps = allApps.filter(function(app) {
                let n = app.name        && app.name.toLowerCase().indexOf(q) !== -1;
                let d = app.comment     && app.comment.toLowerCase().indexOf(q) !== -1;
                let g = app.genericName && app.genericName.toLowerCase().indexOf(q) !== -1;
                return n || d || g;
            });
        }
        appList.currentIndex = 0;
    }

    function dismiss() {
        if (userDismissed) return;
        userDismissed = true;
        isOpen = false;
        Quickshell.execDetached(["bash", "-c",
            "sleep 0.45 && pkill -f '[q]uickshell.*AppLauncher.qml'"]);
    }

    // ── Invisible Scrim (Click outside to close) ───────────────────────
    Rectangle {
        anchors.fill: parent
        color: "transparent" // User requested to remove the dark background

        MouseArea {
            anchors.fill: parent
            onClicked: root.dismiss()
        }
    }

    // ── Master Vertical Clipping Wrapper ──────────────────────────
    Item {
        id: masterWrapper
        anchors.bottom: parent.bottom
        anchors.bottomMargin: localAppLauncherStyle === "Hover" ? 200 : 0
        anchors.horizontalCenter: parent.horizontalCenter
        width: card.width
        height: card.height + 1
        clip: localAppLauncherStyle === "Hug"

        // ── Launcher card ─────────────────────────────────────────────
        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0

            readonly property int cardWidth: localAppLauncherStyle === "Hover" ? 540 : 630
            readonly property int maxListItems: 8
            readonly property int itemH: 64
            readonly property int searchH: localAppLauncherStyle === "Hover" ? 52 : 68
            readonly property int cardPad: 24

            readonly property int fullHeight: (filteredApps.length === 0 ? 160 : Math.min(filteredApps.length, maxListItems) * itemH) + searchH + cardPad * 2

            width: localAppLauncherStyle === "Hover" ? (root.isOpen ? cardWidth : 52) : (root.isOpen ? cardWidth : 160)
            height: localAppLauncherStyle === "Hover" ? (searchField.text.length > 0 ? fullHeight : searchH) : (root.isOpen ? fullHeight : 0)

            onHeightChanged: console.log("Card height:", height)
            onWidthChanged: console.log("Card width:", width)

            scale: localAppLauncherStyle === "Hover" ? (root.isOpen ? 1.0 : 0.9) : 1.0
            opacity: localAppLauncherStyle === "Hover" ? (root.isOpen ? 1.0 : 0.0) : 1.0

            Behavior on scale { NumberAnimation { duration: Theme.liquidify ? 1000 : 450; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutExpo; easing.amplitude: 1.0; easing.period: 0.85 } }
            Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            Behavior on width {
                SequentialAnimation {
                    PauseAnimation { duration: (root.isOpen && searchField.text.length === 0) ? 250 : 0 }
                    NumberAnimation {
                        duration: Theme.liquidify ? 900 : 450
                        easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutExpo
                        easing.amplitude: 0.4
                        easing.period: 0.8
                    }
                }
            }
            Behavior on height { NumberAnimation { duration: Theme.liquidify ? 1200 : 550; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.InOutExpo; easing.amplitude: 0.4; easing.period: 0.85 } }

            color: localAppLauncherStyle === "Hover" ? Qt.rgba(30/255, 30/255, 34/255, 0.72) : Qt.rgba(root.colSurfaceContainer.r, root.colSurfaceContainer.g, root.colSurfaceContainer.b, root.bgOpacity)
            border.color: localAppLauncherStyle === "Hover" ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
            border.width: localAppLauncherStyle === "Hover" ? 1 : 0
            radius: localAppLauncherStyle === "Hover" ? 26 : 0
            topLeftRadius: localAppLauncherStyle === "Hug" ? 28 : 26
            topRightRadius: localAppLauncherStyle === "Hug" ? 28 : 26
            bottomLeftRadius: localAppLauncherStyle === "Hover" ? 26 : 0
            bottomRightRadius: localAppLauncherStyle === "Hover" ? 26 : 0

            MouseArea { anchors.fill: parent; onClicked: {} }

            Item {
                id: contentWrapper
                width: card.width
                height: card.height
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                clip: true
                
                Item {
                    id: innerContent
                    width: card.width
                    height: card.height
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter

        // ── App List Area ─────────────────────────────────────────────
        Item {
            id: listArea
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: searchBar.top
            clip: true

            Rectangle {
                id: rowHighlight
                x: card.cardPad
                width: appList.width
                height: card.itemH
                y: appList.currentItem
                   ? (appList.currentItem.y - appList.contentY + card.cardPad)
                   : card.cardPad
                radius: 14
                color: root.colOnSurface
                opacity: filteredApps.length > 0 ? 0.09 : 0
                visible: filteredApps.length > 0

                Behavior on y {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 10
                visible: filteredApps.length === 0
                opacity: filteredApps.length === 0 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "\ueb1c" // ti-search
                    font.family: "tabler-icons"
                    font.weight: Theme.defaultFontWeight; font.pixelSize: 42
                    color: root.colOnSurfaceVariant
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No results"
                    color: root.colOnSurfaceVariant
                    font.weight: Theme.defaultFontWeight; font.pixelSize: 17
                    font.family: Theme.defaultFontFamily
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Try searching for something else"
                    color: root.colOutline
                    font.weight: Theme.defaultFontWeight; font.pixelSize: 13
                    font.family: Theme.defaultFontFamily
                }
            }

            ListView {
                id: appList
                anchors.fill: parent
                anchors.margins: card.cardPad
                clip: true
                spacing: 0
                currentIndex: 0
                maximumFlickVelocity: 2500
                model: root.filteredApps

                ScrollBar.vertical: ScrollBar {
                    id: vScroll
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: root.colOutline
                        opacity: vScroll.active ? 0.6 : 0
                        Behavior on opacity { NumberAnimation { duration: 160 } }
                    }
                    background: null
                }

                delegate: Item {
                    id: delegateItem
                    required property var modelData
                    required property int index

                    width: appList.width
                    height: card.itemH

                    Rectangle {
                        anchors.fill: parent
                        radius: 14
                        color: root.colOnSurface
                        opacity: hoverH.hovered && appList.currentIndex !== delegateItem.index ? 0.05 : 0
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }

                    HoverHandler {
                        id: hoverH
                        onHoveredChanged: {
                            if (hovered) appList.currentIndex = delegateItem.index;
                        }
                    }

                    TapHandler {
                        onTapped: {
                            appList.currentIndex = delegateItem.index;
                            let cmd = (delegateItem.modelData.execString
                                      || delegateItem.modelData.command.join(" ")).replace(/%[a-zA-Z]/g, "").trim();
                            Quickshell.execDetached(["bash", "-c", cmd]);
                            root.dismiss();
                        }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 14

                        IconImage {
                            asynchronous: true
                            source: Quickshell.iconPath(
                                delegateItem.modelData?.icon ?? "",
                                "application-x-executable")
                            width: 40
                            height: 40
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            width: parent.width - 54 - 14

                            Text {
                                text: delegateItem.modelData?.name ?? ""
                                color: root.colOnSurface
                                font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize
                                font.family: Theme.defaultFontFamily
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: delegateItem.modelData?.comment
                                      || delegateItem.modelData?.genericName
                                      || ""
                                color: root.colOnSurfaceVariant
                                font.weight: Theme.defaultFontWeight; font.pixelSize: 12
                                font.family: Theme.defaultFontFamily
                                elide: Text.ElideRight
                                width: parent.width
                                visible: text.length > 0
                            }
                        }
                    }
                }
            }
        }

        // ── Search bar ────────────────────────────────────────────────
        Rectangle {
            id: searchBar
            parent: innerContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: card.searchH

            color: "transparent"
            border.width: 0

            Rectangle {
                id: searchIconWrapper
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                height: 36
                radius: 18
                color: Qt.rgba(root.colPrimary.r, root.colPrimary.g, root.colPrimary.b, 0.15)

                Text {
                    id: searchIconTxt
                    anchors.centerIn: parent
                    text: "\ueb1c" // ti-search
                    font.family: "tabler-icons"
                    font.weight: Theme.defaultFontWeight; font.pixelSize: 18
                    color: root.colPrimary
                }
            }

            Text {
                anchors.left: searchIconWrapper.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                color: root.colOutline
                font.pixelSize: 15
                font.family: Theme.defaultFontFamily
                text: "Search applications…"
                visible: searchField.text.length === 0
                opacity: card.width > 100 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            TextInput {
                id: searchField
                anchors.left: searchIconWrapper.right
                anchors.leftMargin: 10
                anchors.right: clearBtn.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                color: root.colOnSurface
                font.weight: Theme.defaultFontWeight; font.pixelSize: 15
                font.family: Theme.defaultFontFamily
                clip: true
                focus: true
                opacity: card.width > 100 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }

                onTextChanged: root.filterApps(text)

                Keys.onEscapePressed: root.dismiss()

                Keys.onReturnPressed: {
                    let apps = root.filteredApps;
                    if (apps.length > 0) {
                        let idx = (appList.currentIndex >= 0 && appList.currentIndex < apps.length)
                                  ? appList.currentIndex : 0;
                        let cmd = (apps[idx].execString || apps[idx].command.join(" ")).replace(/%[a-zA-Z]/g, "").trim();
                        Quickshell.execDetached(["bash", "-c", cmd]);
                        root.dismiss();
                    }
                }

                Keys.onDownPressed: {
                    if (appList.currentIndex < root.filteredApps.length - 1)
                        appList.currentIndex++;
                }
                Keys.onUpPressed: {
                    if (appList.currentIndex > 0)
                        appList.currentIndex--;
                }
            }

            Text {
                id: clearBtn
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                text: "\ueb55" // ti-x
                font.family: "tabler-icons"
                font.weight: Theme.defaultFontWeight; font.pixelSize: 15
                color: root.colOnSurfaceVariant
                opacity: searchField.text.length > 0 ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 150 } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        searchField.text = "";
                        searchField.forceActiveFocus();
                    }
                }
            }
        }
                } // innerContent
            } // contentWrapper

        Shape {
            visible: localAppLauncherStyle === "Hug"
            width: 28; height: 28
            anchors.bottom: parent.bottom
            anchors.right: parent.left
            anchors.rightMargin: 0

            ShapePath {
                fillColor: Qt.rgba(root.colSurfaceContainer.r, root.colSurfaceContainer.g, root.colSurfaceContainer.b, root.bgOpacity)
                strokeColor: "transparent"
                startX: 28; startY: 0
                PathLine { x: 28; y: 28 }
                PathLine { x: 0; y: 28 }
                PathArc {
                    x: 28; y: 0
                    radiusX: 28; radiusY: 28
                    useLargeArc: false
                    direction: PathArc.Counterclockwise
                }
            }
        }

        Shape {
            visible: localAppLauncherStyle === "Hug"
            width: 28; height: 28
            anchors.bottom: parent.bottom
            anchors.left: parent.right
            anchors.leftMargin: 0

            ShapePath {
                fillColor: Qt.rgba(root.colSurfaceContainer.r, root.colSurfaceContainer.g, root.colSurfaceContainer.b, root.bgOpacity)
                strokeColor: "transparent"
                startX: 0; startY: 0
                PathLine { x: 0; y: 28 }
                PathLine { x: 28; y: 28 }
                PathArc {
                    x: 0; y: 0
                    radiusX: 28; radiusY: 28
                    useLargeArc: false
                    direction: PathArc.Clockwise
                }
            }
        }
        } // Rectangle card
    } // Item masterWrapper

    // Bottom decorative bar
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: 134
        height: 5
        radius: 2.5
        color: Qt.rgba(root.colOnSurface.r, root.colOnSurface.g, root.colOnSurface.b, 0.4)
        anchors.bottomMargin: 8
    }
} // PanelWindow
