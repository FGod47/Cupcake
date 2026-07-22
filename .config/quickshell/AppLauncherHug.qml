pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQml
import QtQuick.Shapes
import "fuzzysort.js" as FuzzySort
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

    // ── M3 Dark Palette (Modified to match Bar.qml) ────────────────────
    property color colSurface:               Theme.colSurface
    property color colSurfaceContainer:      Theme.colSurfaceContainer // pure black
    property color colSurfaceContainerHigh:  Theme.colSurfaceContainerHigh // very dark grey for search
    property color colOnSurface:             Theme.colOnSurface // match bar fg
    property color colOnSurfaceVariant:      Theme.colOnSurfaceVariant
    property color colOutline:               Theme.colOutline
    property color colPrimary:               Theme.colPrimary // match bar accent

    property real bgOpacity: 0.80
    Process {
        id: initLauncherOpacity
        running: true
        command: ["cat", Theme.homeDir + "/.config/cupcake/.launcher_opacity"]
        stdout: StdioCollector { onStreamFinished: {
                if (text) { let v = parseFloat(text.trim()); if (!isNaN(v)) root.bgOpacity = v; }
        } }
    }
    Timer { interval: 500; running: true; repeat: true; onTriggered: initLauncherOpacity.running = true }

    // ── State ─────────────────────────────────────────────────────────
    // DesktopEntries loads asynchronously — bind reactively
    property var allApps: DesktopEntries.applications.values
    property var filteredApps: []   // starts populated once entries load
    property bool userDismissed: false
    property string currentQuery: ""

    // Whenever DesktopEntries finishes scanning, re-apply the current filter
    onAllAppsChanged: {
        filterApps(currentQuery);
    }

    // 1.0 = hidden below screen, 0.0 = fully visible
    property bool isOpen: false

    Timer {
        id: openTimer
        interval: 50
        running: false
        repeat: false
        onTriggered: {
            isOpen = true;
            searchField.forceActiveFocus();
            filterApps("");
        }
    }

    Component {
        id: customResultComp
        QtObject {
            property string name: ""
            property string comment: ""
            property string icon: ""
            property string execString: ""
            property string genericName: ""
            property var command: []
        }
    }

    function tryPath(path) {
        if (path.startsWith("/") || path.startsWith("~")) {
            let expanded = path.replace(/^~/, Quickshell.env("HOME"));
            return customResultComp.createObject(null, {
                name: "Open Path: " + path,
                comment: "Run in terminal",
                icon: "utilities-terminal",
                command: ["xdg-open", expanded]
            });
        }
        return null;
    }

    function safeEvalMath(query) {
        if (/^[0-9\+\-\*\/\%\(\)\.\s]+$/.test(query) && /[0-9]/.test(query) && /[\+\-\*\/\%]/.test(query)) {
            try {
                let obj = Qt.createQmlObject('import QtQml; QtObject { property real res: (' + query + ') }', root, "mathEval");
                if (obj && obj.res !== undefined && !isNaN(obj.res)) {
                    let res = obj.res;
                    obj.destroy();
                    return customResultComp.createObject(null, {
                        name: "Result: " + res,
                        comment: "Math calculation",
                        icon: "accessories-calculator",
                        command: ["wl-copy", res.toString()]
                    });
                }
            } catch (e) {}
        }
        return null;
    }

    function safeEvalConv(query) {
        let match = query.match(/^([0-9.]+)\s*([a-zA-Z]+)\s+(?:in|to)\s+([a-zA-Z]+)$/);
        if (match) {
            let val = parseFloat(match[1]);
            let from = match[2].toLowerCase();
            let to = match[3].toLowerCase();
            
            let rates = { "kg": 1, "lbs": 2.20462, "lb": 2.20462, "c": 1, "f": 1, "m": 1, "cm": 100, "km": 0.001, "inch": 39.3701, "ft": 3.28084 };
            if (from === "c" && to === "f") {
                let res = (val * 9/5) + 32;
                return customResultComp.createObject(null, { name: res.toFixed(2) + " °F", comment: "Temperature conversion", icon: "accessories-calculator", command: ["wl-copy", res.toFixed(2)] });
            } else if (from === "f" && to === "c") {
                let res = (val - 32) * 5/9;
                return customResultComp.createObject(null, { name: res.toFixed(2) + " °C", comment: "Temperature conversion", icon: "accessories-calculator", command: ["wl-copy", res.toFixed(2)] });
            } else if (rates[from] && rates[to]) {
                let res = (val / rates[from]) * rates[to];
                return customResultComp.createObject(null, {
                    name: res.toFixed(2) + " " + to,
                    comment: "Unit conversion",
                    icon: "accessories-calculator",
                    command: ["wl-copy", res.toFixed(2)]
                });
            }
        }
        return null;
    }

    function filterApps(query) {
        currentQuery = query;
        let q = query.toLowerCase().trim();
        if (q.length === 0) {
            let arr = [];
            for (let i = 0; i < allApps.length; i++) arr.push(allApps[i]);
            filteredApps = arr;
        } else {
            let results = FuzzySort.go(q, allApps, {
                keys: ['name', 'genericName', 'comment'],
                all: true
            });
            let apps = results.map(function(r) { return r.obj; });
            
            let mathRes = safeEvalMath(q);
            if (mathRes) apps.unshift(mathRes);
            
            let convRes = safeEvalConv(q);
            if (convRes) apps.unshift(convRes);
            
            let pathRes = tryPath(query);
            if (pathRes) apps.unshift(pathRes);
            
            // Web search fallback if no strict matches
            try {
                if (apps.length === 0 || (results.length > 0 && results[0].score < -1000)) {
                    let searchObj = customResultComp.createObject(null, {
                        name: "Search Google for '" + query + "'",
                        comment: "Web search",
                        icon: "web-browser",
                        command: ["xdg-open", "https://google.com/search?q=" + encodeURIComponent(query)]
                    });
                    if (searchObj) {
                        apps.push(searchObj);
                    }
                }
            } catch (e) {}

            filteredApps = apps;
        }
        appList.currentIndex = 0;
    }

    function dismiss() {
        if (userDismissed) return;
        userDismissed = true;
        isOpen = false;
        Quickshell.execDetached(["bash", "-c",
            "sleep 0.45 && pkill -f '[q]uickshell.*AppLauncher.*\\.qml'"]);
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
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.width
        height: card.height + 1 // Add 1px buffer to prevent clipping the card's top anti-aliasing
        clip: true

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

            readonly property int fullHeight: (appList.count === 0 ? 160 : Math.min(appList.count, maxListItems) * itemH) + searchH + cardPad * 2

            width: root.isOpen ? cardWidth : 160
            height: root.isOpen ? fullHeight : 0

            Behavior on width { NumberAnimation { duration: 550; easing.type: Easing.InOutExpo } }
            Behavior on height { NumberAnimation { duration: 550; easing.type: Easing.InOutExpo } }

            color: Qt.rgba(root.colSurfaceContainer.r, root.colSurfaceContainer.g, root.colSurfaceContainer.b, root.bgOpacity)
            topLeftRadius: 28
            topRightRadius: 28
            bottomLeftRadius: 0
            bottomRightRadius: 0
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
            anchors.bottom: searchBar.top
            anchors.bottomMargin: 0

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
                opacity: appList.count > 0 ? 0.09 : 0
                visible: appList.count > 0

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
                visible: appList.count === 0
                opacity: appList.count === 0 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "" // \uf002
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 42
                    color: root.colOnSurfaceVariant
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No results"
                    color: root.colOnSurfaceVariant
                    font.pixelSize: 17
                    font.weight: Font.Medium
                    font.family: "JetBrainsMono Nerd Font Propo"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Try searching for something else"
                    color: root.colOutline
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font Propo"
                }
            }

            // App list
            ListView {
                id: appList
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Math.min(contentHeight, parent.height)
                anchors.leftMargin: card.cardPad
                anchors.rightMargin: card.cardPad
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
                            let cmd = delegateItem.modelData.execString
                                      || delegateItem.modelData.command.join(" ");
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
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                font.family: "JetBrainsMono Nerd Font Propo"
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: delegateItem.modelData?.comment
                                      || delegateItem.modelData?.genericName
                                      || ""
                                color: root.colOutline
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font Propo"
                                elide: Text.ElideRight
                                width: parent.width
                                visible: text.length > 0
                            }
                        }
                    }
                }
            }
        }

        // ── Search bar — pinned to bottom of card (Caelestia layout) ──
        Rectangle {
            id: searchBar

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: card.cardPad
            anchors.bottomMargin: 16

            height: card.searchH - 16
            radius: 9999

            color: Qt.rgba(root.colSurfaceContainerHigh.r, root.colSurfaceContainerHigh.g, root.colSurfaceContainerHigh.b, 0.4)
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
                text: "" // \uf002
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 17
                color: root.colOnSurfaceVariant
            }

            // Placeholder
            Text {
                anchors.left: searchIconTxt.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                color: root.colOutline
                font.pixelSize: 15
                font.family: "JetBrainsMono Nerd Font Propo"
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
                font.pixelSize: 15
                font.family: "JetBrainsMono Nerd Font Propo"
                clip: true
                focus: true

                onTextChanged: root.filterApps(text)

                Keys.onEscapePressed: root.dismiss()

                Keys.onReturnPressed: {
                    let apps = root.filteredApps;
                    if (apps.length > 0) {
                        let idx = (appList.currentIndex >= 0 && appList.currentIndex < apps.length)
                                  ? appList.currentIndex : 0;
                        let cmd = apps[idx].execString || apps[idx].command.join(" ");
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
                text: "✕"
                font.pixelSize: 15
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
