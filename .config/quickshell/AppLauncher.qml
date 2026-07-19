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

    property string localAppLauncherStyle: "Hug"
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
        anchors.bottom: localAppLauncherStyle === "Hug" ? parent.bottom : undefined
        anchors.verticalCenter: localAppLauncherStyle === "Hover" ? parent.verticalCenter : undefined
        anchors.verticalCenterOffset: localAppLauncherStyle === "Hover" ? -(parent.height * 0.15) : 0
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.width
        height: card.height + 1 // Add 1px buffer to prevent clipping the card's top anti-aliasing
        clip: localAppLauncherStyle === "Hug" // Only clip when hugging the bottom edge

        // ── Launcher card ─────────────────────────────────────────────
        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0

            readonly property int cardWidth: 630
            readonly property int maxListItems: 8
            readonly property int itemH: 64
            readonly property int searchH: 68
            readonly property int cardPad: 24

            readonly property int fullHeight: (filteredApps.length === 0 ? 160 : Math.min(filteredApps.length, maxListItems) * itemH) + searchH + cardPad * 2

            width: localAppLauncherStyle === "Hover" ? cardWidth : (root.isOpen ? cardWidth : 160)
            height: localAppLauncherStyle === "Hover" ? fullHeight : (root.isOpen ? fullHeight : 0)

            scale: localAppLauncherStyle === "Hover" ? (root.isOpen ? 1.0 : 0.9) : 1.0
            opacity: localAppLauncherStyle === "Hover" ? (root.isOpen ? 1.0 : 0.0) : 1.0

            Behavior on scale { NumberAnimation { duration: Theme.liquidify ? 1000 : 450; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutExpo; easing.amplitude: 1.0; easing.period: 0.85 } }
            Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: Theme.liquidify ? 1200 : 550; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.InOutExpo; easing.amplitude: 0.4; easing.period: 0.85 } }
            Behavior on height { NumberAnimation { duration: Theme.liquidify ? 1200 : 550; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.InOutExpo; easing.amplitude: 0.4; easing.period: 0.85 } }

            color: Qt.rgba(root.colSurfaceContainer.r, root.colSurfaceContainer.g, root.colSurfaceContainer.b, root.bgOpacity)
            topLeftRadius: 28
            topRightRadius: 28
            bottomLeftRadius: localAppLauncherStyle === "Hover" ? 28 : 0
            bottomRightRadius: localAppLauncherStyle === "Hover" ? 28 : 0
            // Removed clip: true from card so it can render the fillets outside its bounds

            MouseArea { anchors.fill: parent; onClicked: {} }

            Item {
                id: contentWrapper
                width: card.width
                height: card.height
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                clip: true // Dynamically clips exactly to the card's current animating size
                
                Item {
                    id: innerContent
                    width: card.cardWidth
                    height: card.fullHeight
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    opacity: root.isOpen ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: root.isOpen ? 550 : 250; easing.type: Easing.InOutQuad } }


        // ── App List Area ─────────────────────────────────────────────
        Item {
            id: listArea
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: localAppLauncherStyle === "Hover" ? card.cardPad : card.searchH

            // Sliding highlight bar (exact Caelestia behavior)
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

            // Empty state
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

            // App list
            ListView {
                id: appList
                anchors.fill: parent
                anchors.margins: card.cardPad
                clip: true
                spacing: 0
                currentIndex: 0
                maximumFlickVelocity: 2500
                model: root.filteredApps

                // Animate items in/out on search
                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: 180; easing.type: Easing.OutCubic }
                }
                remove: Transition {
                    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 140 }
                    NumberAnimation { property: "scale"; from: 1; to: 0.96; duration: 140 }
                }
                displaced: Transition {
                    NumberAnimation { properties: "y"; duration: 220; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "opacity"; to: 1; duration: 220 }
                }

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

                    // Hover state layer
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

            parent: localAppLauncherStyle === "Hover" ? root : innerContent

            anchors.bottom: parent.bottom
            anchors.bottomMargin: localAppLauncherStyle === "Hover" ? 32 : 16
            
            anchors.horizontalCenter: localAppLauncherStyle === "Hover" ? parent.horizontalCenter : undefined
            anchors.left: localAppLauncherStyle === "Hover" ? undefined : parent.left
            anchors.right: localAppLauncherStyle === "Hover" ? undefined : parent.right
            anchors.leftMargin: localAppLauncherStyle === "Hover" ? 0 : card.cardPad
            anchors.rightMargin: localAppLauncherStyle === "Hover" ? 0 : card.cardPad
            
            width: localAppLauncherStyle === "Hover" ? card.cardWidth : undefined
            height: card.searchH - 16
            radius: 9999

            scale: localAppLauncherStyle === "Hover" ? (root.isOpen ? 1.0 : 0.9) : 1.0
            opacity: localAppLauncherStyle === "Hover" ? (root.isOpen ? 1.0 : 0.0) : 1.0
            Behavior on scale { NumberAnimation { duration: Theme.liquidify ? 1000 : 450; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutExpo; easing.amplitude: 1.0; easing.period: 0.85 } }
            Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

            color: Qt.lighter(root.colSurfaceContainerHigh, 1.12)
            border.color: searchField.activeFocus
                          ? Qt.rgba(root.colPrimary.r, root.colPrimary.g,
                                    root.colPrimary.b, 0.7)
                          : "transparent"
            border.width: 2

            Behavior on border.color { ColorAnimation { duration: 180 } }

            // Search icon
            Text {
                id: searchIconTxt
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                text: "\ueb1c" // ti-search
                font.family: "tabler-icons"
                font.weight: Theme.defaultFontWeight; font.pixelSize: 17
                color: root.colOnSurfaceVariant
            }

            // Placeholder
            Text {
                anchors.left: searchIconTxt.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                color: root.colOutline
                font.pixelSize: 15
                font.family: Theme.defaultFontFamily
                text: "Search applications…"
                visible: searchField.text.length === 0
            }

            TextInput {
                id: searchField
                anchors.left: searchIconTxt.right
                anchors.leftMargin: 10
                anchors.right: clearBtn.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                color: root.colOnSurface
                font.weight: Theme.defaultFontWeight; font.pixelSize: 15
                font.family: Theme.defaultFontFamily
                clip: true
                focus: true

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

            // Clear button
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
            } // Text clearBtn
        } // Rectangle searchBar
                } // Item innerContent
            } // Item contentWrapper

        // ── Left Fillet (Inverse bottom-left corner) ─────────────────────
        Shape {
            width: 28; height: 28
            anchors.bottom: parent.bottom
            anchors.right: parent.left
            anchors.rightMargin: 0 // 1px overlap to prevent subpixel tearing gaps

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

        // ── Right Fillet (Inverse bottom-right corner) ────────────────────
        Shape {
            width: 28; height: 28
            anchors.bottom: parent.bottom
            anchors.left: parent.right
            anchors.leftMargin: 0 // 1px overlap to prevent subpixel tearing gaps

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


} // PanelWindow
