pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
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

    Timer {
        id: webFetchDebounce
        interval: 500
        repeat: false
        property string targetQuery: ""
        onTriggered: {
            logDebug("TIMER FIRED FOR: " + targetQuery);
            if (webFetchProcess.running) {
                pendingQuery = targetQuery;
                webFetchProcess.running = false;
            } else {
                currentFetchQuery = targetQuery;
                webFetchProcess.command = ["python3", Quickshell.env("HOME") + "/.config/cupcake/scripts/fetch_search.py", targetQuery];
                webFetchProcess.running = true;
            }
        }
    }

    Process {
        id: webFetchProcess
        property string currentFetchQuery: ""
        property string pendingQuery: ""
        stdout: StdioCollector {
            id: webFetchStdout
            onStreamFinished: {
                let txt = webFetchStdout.text;
                logDebug("Stream finished. Text length: " + txt.length);
                try {
                    if (currentQuery !== currentFetchQuery) {
                        logDebug("Query mismatch: " + currentQuery + " vs " + currentFetchQuery);
                        return;
                    }
                    
                    let lines = txt.trim().split("\n");
                    let lastLine = lines[lines.length - 1];
                    if (!lastLine) {
                        logDebug("Empty last line");
                        return;
                    }
                    
                    logDebug("Parsing JSON...");
                    let json = JSON.parse(lastLine);
                    if (json.length === 0) {
                        logDebug("Empty JSON array");
                        return;
                    }
                    
                    let newArr = [];
                    for(let k=0; k<filteredApps.length; k++) newArr.push(filteredApps[k]);
                    
                    for (let i = 0; i < json.length; i++) {
                        let searchObj = customResultComp.createObject(root, {
                            name: json[i].name,
                            comment: json[i].comment,
                            icon: json[i].icon || "web-browser",
                            command: ["xdg-open", json[i].url]
                        });
                        if (searchObj) {
                            newArr.push(searchObj);
                        }
                    }
                    filteredApps = newArr;
                    logDebug("Successfully appended " + json.length + " items");
                } catch (e) { logDebug("Live search error: " + e); }
            }
        }
        onExited: {
            if (pendingQuery !== "") {
                currentFetchQuery = pendingQuery;
                webFetchProcess.command = ["python3", Quickshell.env("HOME") + "/.config/cupcake/scripts/fetch_search.py", pendingQuery];
                webFetchProcess.running = true;
                pendingQuery = "";
            }
        }
    }

    Timer {
        id: fileFetchDebounce
        interval: 100
        repeat: false
        property string targetQuery: ""
        onTriggered: {
            if (fileFetchProcess.running) {
                pendingQuery = targetQuery;
                fileFetchProcess.running = false;
            } else {
                currentFetchQuery = targetQuery;
                fileFetchProcess.command = ["python3", Quickshell.env("HOME") + "/.config/cupcake/scripts/fetch_files.py", targetQuery];
                fileFetchProcess.running = true;
            }
        }
    }

    Process {
        id: fileFetchProcess
        command: []
        running: false
        property string pendingQuery: ""
        property string currentFetchQuery: ""
        
        stdout: StdioCollector {
            id: fileFetchStdout
            onStreamFinished: {
                let txt = fileFetchStdout.text;
                try {
                    if (currentQuery.replace(/^f\s+|^file\s+/, "").trim().toLowerCase() !== currentFetchQuery.toLowerCase()) {
                        return;
                    }
                    
                    let lines = txt.trim().split("\n");
                    let lastLine = lines[lines.length - 1];
                    if (!lastLine) return;
                    
                    let json = JSON.parse(lastLine);
                    
                    let newArr = [];
                    for (let i = 0; i < json.length; i++) {
                        let fileObj = customResultComp.createObject(root, {
                            name: json[i].name,
                            comment: json[i].comment,
                            icon: json[i].icon,
                            command: ["xdg-open", json[i].url]
                        });
                        if (fileObj) {
                            newArr.push(fileObj);
                        }
                    }
                    filteredApps = newArr;
                } catch (e) {
                    console.log("File search error: " + e);
                }
            }
        }
        onExited: {
            if (pendingQuery !== "") {
                currentFetchQuery = pendingQuery;
                fileFetchProcess.command = ["python3", Quickshell.env("HOME") + "/.config/cupcake/scripts/fetch_files.py", pendingQuery];
                fileFetchProcess.running = true;
                pendingQuery = "";
            }
        }
    }

    // ── Math & Commands ──────────────────────────────────────────────────────────
    // DesktopEntries loads asynchronously — bind reactively
    property var allApps: DesktopEntries.applications.values
    property var filteredApps: []   // strictly a JS array so ListView uses JS adapter
    property bool userDismissed: false
    property string currentQuery: ""

    // Whenever DesktopEntries finishes scanning, re-apply the current filter
    onAllAppsChanged: {
        filterApps(currentQuery);
    }

    // 1.0 = hidden below screen, 0.0 = fully visible
    property bool isOpen: false

    Component.onCompleted: {
        Qt.callLater(function() {
            isOpen = true;
            searchField.forceActiveFocus();
            filterApps("");
        });
    }

    function safeEvalMath(expr) {
        try {
            let clean = expr.trim();
            if (/^[0-9+\-*/().\s]+$/.test(clean) && /[+\-*/]/.test(clean)) {
                let result = Function('"use strict";return (' + clean + ')')();
                if (result !== undefined && !isNaN(result) && result !== Infinity && result !== clean) {
                    return customResultComp.createObject(null, {
                        name: String(result),
                        comment: "= " + clean,
                        icon: "accessories-calculator",
                        execString: "wl-copy '" + result + "'",
                        genericName: "Copy result"
                    });
                }
            }
        } catch (e) {}
        return null;
    }

    function tryConversion(expr) {
        let match = expr.toLowerCase().match(/^([\d.]+)\s*(kg|lbs|c|f|km|mi|m|ft)$/);
        if (match) {
            let val = parseFloat(match[1]);
            let unit = match[2];
            let toBase = 0;
            if (unit === "kg") toBase = 2.20462;
            else if (unit === "lbs") toBase = 1/2.20462;
            else if (unit === "c") return customResultComp.createObject(root, {
                    name: String(Number((val * 9/5) + 32).toFixed(2)) + " °F",
                    comment: "Conversion",
                    icon: "accessories-calculator",
                    execString: "wl-copy '" + String(Number((val * 9/5) + 32).toFixed(2)) + "'",
                    genericName: "Copy result"
                });
            else if (unit === "f") return customResultComp.createObject(root, {
                    name: String(Number((val - 32) * 5/9).toFixed(2)) + " °C",
                    comment: "Conversion",
                    icon: "accessories-calculator",
                    execString: "wl-copy '" + String(Number((val - 32) * 5/9).toFixed(2)) + "'",
                    genericName: "Copy result"
                });
            else if (unit === "km") toBase = 0.621371;
            else if (unit === "mi") toBase = 1/0.621371;
            else if (unit === "m") toBase = 3.28084;
            else if (unit === "ft") toBase = 1/3.28084;
            
            return customResultComp.createObject(null, {
                    name: String(Number(val * toBase).toFixed(2)) + " " + (match[2] === "km" ? "mi" : match[2] === "mi" ? "km" : match[2] === "c" ? "f" : match[2] === "f" ? "c" : match[2] === "kg" ? "lbs" : match[2] === "lbs" ? "kg" : match[2] === "m" ? "ft" : "m"),
                    comment: "Conversion",
                    icon: "accessories-calculator",
                    execString: "wl-copy '" + String(Number(val * toBase).toFixed(2)) + "'",
                    genericName: "Copy result"
                });
        }
        return null;
    }

    function tryPath(expr) {
        let clean = expr.trim();
        if (clean.startsWith("/") || clean.startsWith("~/")) {
            return customResultComp.createObject(null, {
                name: "Open " + clean,
                comment: "File Path",
                icon: "system-file-manager",
                execString: "xdg-open '" + clean + "'",
                genericName: "Open Directory"
            });
        }
        return null;
    }

    function logDebug(msg) {
        Quickshell.execDetached(["bash", "-c", "echo '" + msg + "' >> /tmp/qs_debug.log"]);
    }

    function filterApps(query) {
        currentQuery = query;
        let q = query.toLowerCase().trim();
        
        // File Search Mode Interceptor
        if (q.startsWith("f ") || q.startsWith("file ")) {
            let fileQ = q.replace(/^f\s+|^file\s+/, "").trim();
            if (fileQ.length > 0) {
                // Trigger file search debounce
                fileFetchDebounce.targetQuery = fileQ;
                fileFetchDebounce.restart();
            } else {
                filteredApps = [];
            }
            appList.currentIndex = 0;
            return; // Skip local app search completely
        }
        
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
            logDebug("Fuzzysort found: " + apps.length);
            
            let mathRes = safeEvalMath(q);
            if (mathRes) apps.unshift(mathRes);
            
            let convRes = tryConversion(q);
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
                    
                    // Trigger live search in background (debounced)
                    webFetchDebounce.targetQuery = query;
                    webFetchDebounce.restart();
                }
            } catch (e) { logDebug("Error in fallback: " + e); }
            
            try {
                filteredApps = apps;
                logDebug("Assigned to filteredApps. Length is now: " + filteredApps.length);
            } catch(e) { logDebug("Error assigning: " + e); }
        }
        try {
            appList.currentIndex = 0;
        } catch(e) {}
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
        anchors.bottom: Theme.appLauncherStyle === "Hug" ? parent.bottom : undefined
        anchors.verticalCenter: Theme.appLauncherStyle === "Hover" ? parent.verticalCenter : undefined
        anchors.verticalCenterOffset: Theme.appLauncherStyle === "Hover" ? -(parent.height * 0.15) : 0
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.width
        height: card.height + 1 // Add 1px buffer to prevent clipping the card's top anti-aliasing
        clip: Theme.appLauncherStyle === "Hug" // Only clip when hugging the bottom edge

        // ── Launcher card ─────────────────────────────────────────────
        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0

            readonly property int cardWidth: 800
            readonly property int maxListItems: 8
            readonly property int itemH: 64
            readonly property int searchH: 68
            readonly property int cardPad: 24

            readonly property int fullHeight: (appList.count === 0 ? 160 : Math.min(appList.count, maxListItems) * itemH) + searchH + cardPad * 2

            width: Theme.appLauncherStyle === "Hover" ? cardWidth : (root.isOpen ? cardWidth : 160)
            height: Theme.appLauncherStyle === "Hover" ? fullHeight : (root.isOpen ? fullHeight : 0)

            scale: Theme.appLauncherStyle === "Hover" ? (root.isOpen ? 1.0 : 0.9) : 1.0
            opacity: Theme.appLauncherStyle === "Hover" ? (root.isOpen ? 1.0 : 0.0) : 1.0

            Behavior on scale { NumberAnimation { duration: Theme.liquidify ? 1000 : 450; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutExpo; easing.amplitude: 1.0; easing.period: 0.85 } }
            Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: Theme.liquidify ? 1200 : 700; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.InOutExpo; easing.amplitude: 1.0; easing.period: 0.85 } }
            Behavior on height { NumberAnimation { duration: Theme.liquidify ? 1200 : 700; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.InOutExpo; easing.amplitude: 1.0; easing.period: 0.85 } }

            color: Qt.rgba(root.colSurfaceContainer.r, root.colSurfaceContainer.g, root.colSurfaceContainer.b, root.bgOpacity)
            border.color: Theme.appLauncherStyle === "Hover" ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
            border.width: Theme.appLauncherStyle === "Hover" ? 1 : 0
            radius: Theme.appLauncherStyle === "Hover" ? 26 : 0
            topLeftRadius: Theme.appLauncherStyle === "Hug" ? 28 : 26
            topRightRadius: Theme.appLauncherStyle === "Hug" ? 28 : 26
            bottomLeftRadius: Theme.appLauncherStyle === "Hover" ? 26 : 0
            bottomRightRadius: Theme.appLauncherStyle === "Hover" ? 26 : 0

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
            clip: true
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.appLauncherStyle === "Hover" ? card.searchH : card.searchH + card.cardPad

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
                    text: "\ueb1c" // ti-search
                    font.family: "tabler-icons"
                    font.weight: Theme.defaultFontWeight; font.pixelSize: 42
                    color: root.colOnSurfaceVariant
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No results. Apps: " + (filteredApps ? filteredApps.length : "null") + " Count: " + appList.count + " Comp: " + (customResultComp ? "OK" : "NULL")
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
                            source: {
                                let icn = delegateItem.modelData?.icon ?? "";
                                if (icn.startsWith("http://") || icn.startsWith("https://")) {
                                    return icn;
                                }
                                return Quickshell.iconPath(icn, "application-x-executable");
                            }
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

        // ── Search bar — pinned to bottom of card (Caelestia layout) ──
        Rectangle {
            id: searchBar

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            height: card.searchH
            radius: 9999

            color: Theme.appLauncherStyle === "Hover" ? Qt.rgba(root.colSurfaceContainerHigh.r, root.colSurfaceContainerHigh.g, root.colSurfaceContainerHigh.b, 0.4) : "transparent"
            border.width: 0

            // Search icon background
            Rectangle {
                id: searchIconWrapper
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.appLauncherStyle === "Hover" ? 38 : 36
                height: Theme.appLauncherStyle === "Hover" ? 38 : 36
                radius: Theme.appLauncherStyle === "Hover" ? 19 : 18
                color: Qt.rgba(root.colPrimary.r, root.colPrimary.g, root.colPrimary.b, 0.15)

                Text {
                    id: searchIconTxt
                    anchors.centerIn: parent
                    text: "\ueb1c" // ti-search
                    font.family: "tabler-icons"
                    font.weight: Theme.defaultFontWeight
                    font.pixelSize: Theme.appLauncherStyle === "Hover" ? 20 : 18
                    color: root.colOnSurface
                }
            }

            // Inner Pill for Text Input
            Rectangle {
                id: searchInputPill
                anchors.left: searchIconWrapper.right
                anchors.leftMargin: Theme.appLauncherStyle === "Hover" ? 12 : 10
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                height: 38
                radius: 19
                color: Theme.appLauncherStyle === "Hover" ? Qt.rgba(root.colOnSurface.r, root.colOnSurface.g, root.colOnSurface.b, 0.08) : "transparent"
                opacity: card.width > 120 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                
                // Placeholder
                Text {
                    id: placeholderTxt
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.appLauncherStyle === "Hover" ? 16 : 0
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.colOutline
                    font.pixelSize: 15
                    font.family: Theme.defaultFontFamily
                    text: Theme.appLauncherStyle === "Hover" ? "Search, calculate or run" : "Search applications…"
                    visible: searchField.text.length === 0
                    opacity: card.width > 100 ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }

                TextInput {
                    id: searchField
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.appLauncherStyle === "Hover" ? 16 : 0
                    anchors.right: clearBtn.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.colOnSurface
                    font.weight: Theme.defaultFontWeight; font.pixelSize: 15
                    font.family: Theme.defaultFontFamily
                    clip: true
                    focus: true
                    opacity: card.width > 100 ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

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
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\ueb55" // ti-x
                    font.family: "tabler-icons"
                    font.weight: Theme.defaultFontWeight; font.pixelSize: 15
                    color: root.colOnSurfaceVariant
                    opacity: searchField.text.length > 0 && card.width > 100 ? 1 : 0
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
            } // searchInputPill

        } // searchBar
        } // innerContent
    } // contentWrapper

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
