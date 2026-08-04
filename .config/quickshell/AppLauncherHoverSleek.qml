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
import Qt5Compat.GraphicalEffects

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
    property var filteredApps: []   // starts populated once entries load
    property bool userDismissed: false
    property string currentQuery: ""

    // Whenever DesktopEntries finishes scanning, re-apply the current filter
    onAllAppsChanged: {
        filterApps(currentQuery);
    }

    // 1.0 = hidden below screen, 0.0 = fully visible
    property bool isOpen: false
    property bool localLiquidify: Quickshell.env("LIQUIDIFY") === "true"

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
            filterApps("");
        }
    }

    Component.onCompleted: {
        openTimer.start();
        filterApps("");
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
            property bool isWebResult: false
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

    // Live Web Search Process
    property string currentFetchQuery: ""
    property string pendingQuery: ""
    Timer {
        id: webFetchDebounce
        interval: 500
        repeat: false
        property string targetQuery: ""
        onTriggered: {
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
        stdout: StdioCollector {
            id: webFetchStdout
            onStreamFinished: {
                let txt = webFetchStdout.text;
                try {
                    if (currentQuery !== currentFetchQuery) {
                        return;
                    }
                    
                    let lines = txt.trim().split("\n");
                    let lastLine = lines[lines.length - 1];
                    if (!lastLine) {
                        return;
                    }
                    
                    let json = JSON.parse(lastLine);
                    if (json.length === 0) return;
                    
                    let newArr = [];
                    for(let k=0; k<filteredApps.length; k++) newArr.push(filteredApps[k]);
                    
                    for (let i = 0; i < json.length; i++) {
                        let searchObj = customResultComp.createObject(root, {
                            name: json[i].name,
                            comment: json[i].comment,
                            icon: json[i].icon || "web-browser",
                            command: ["xdg-open", json[i].url],
                            isWebResult: true
                        });
                        if (searchObj) {
                            newArr.push(searchObj);
                        }
                    }
                    filteredApps = newArr;
                } catch (e) { 
                    console.log("Live search error: " + e);
                }
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
            arr.sort((a, b) => {
                let nameA = (a.name || "").toLowerCase();
                let nameB = (b.name || "").toLowerCase();
                if (nameA < nameB) return -1;
                if (nameA > nameB) return 1;
                return 0;
            });
            filteredApps = arr;
        } else {
            let apps = [];
            let results = [];
            try {
                results = FuzzySort.go(q, allApps, {
                    keys: ['name', 'genericName', 'comment'],
                    all: true
                });
                apps = results.map(function(r) { return r.obj; });
            } catch (e) {
                Quickshell.execDetached(["bash", "-c", "echo 'FuzzySort ERROR: " + e + "' >> /tmp/qs_debug.log"]);
            }
            
            let mathRes = safeEvalMath(q);
            if (mathRes) apps.unshift(mathRes);
            
            let convRes = safeEvalConv(q);
            if (convRes) apps.unshift(convRes);
            
            let pathRes = tryPath(query);
            if (pathRes) apps.unshift(pathRes);
            
            // Web search fallback if no strict matches
            try {
                if (apps.length === 0 || (results.length > 0 && results[0].score < -1000)) {
                    let searchObj = customResultComp.createObject(root, {
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
        id: masterWrapper
        anchors.bottom: parent.bottom
        anchors.bottomMargin: true ? 200 : 0
        anchors.horizontalCenter: parent.horizontalCenter
        width: card.width
        height: card.height + 1
        clip: false

        // ── Launcher card ─────────────────────────────────────────────
        Item {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0

            readonly property int cardWidth: 500
            readonly property int maxListItems: 7
            readonly property int itemH: 48
            readonly property int searchH: 32
            readonly property int cardPad: 12
            readonly property int verticalPad: 6

            readonly property int fullHeight: (appList.count === 0 ? 120 : Math.min(appList.contentHeight, (maxListItems * itemH) + ((maxListItems - 1) * 4))) + searchH + verticalPad * 3 + 32

            width: true ? (root.isOpen ? cardWidth : 52) : (root.isOpen ? cardWidth : 160)
            property real dynamicMargin: width > 52 ? ((width - 52) / (cardWidth - 52)) * cardPad : 0
            property real dynamicVMargin: width > 52 ? ((width - 52) / (cardWidth - 52)) * verticalPad : 0
            
            property bool isModeFiles: typeof searchField !== "undefined" && searchField !== null ? (searchField.text.startsWith("f ") || searchField.text.startsWith("F ")) : false
            // splitOffset = folder pill width + gap between pills
            // The search bar's width = cardWidth - splitOffset, driven by this with OutBack bounce
            readonly property real folderPillSize: card.searchH + card.verticalPad * 2
            property real splitOffset: isModeFiles ? (folderPillSize + 8) : 0
            Behavior on splitOffset { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
            
            height: true ? (searchField.text.length > 0 ? fullHeight : (root.isOpen ? searchH + verticalPad * 2 : searchH)) : (root.isOpen ? fullHeight : 0)

            onHeightChanged: console.log("Card height:", height)
            onWidthChanged: console.log("Card width:", width)

            scale: true ? (root.isOpen ? 1.0 : 0.9) : 1.0
            opacity: 1.0

            Behavior on scale { NumberAnimation { duration: Theme.liquidify ? 1000 : 450; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.OutExpo; easing.amplitude: 1.0; easing.period: 0.85 } }
            Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: Theme.liquidify ? 1200 : 550; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.InOutExpo; easing.amplitude: 0.4; easing.period: 0.85 } }
            Behavior on height { NumberAnimation { duration: Theme.liquidify ? 1200 : 550; easing.type: Theme.liquidify ? Easing.OutElastic : Easing.InOutExpo; easing.amplitude: 0.4; easing.period: 0.85 } }

            Rectangle {
                id: listCardBg
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: searchCardBg.top
                anchors.bottomMargin: 8
                height: Math.max(0, parent.height - searchCardBg.height - 8)
                
                color: Qt.rgba(root.colSurfaceContainer.r, root.colSurfaceContainer.g, root.colSurfaceContainer.b, root.bgOpacity)
                border.color: Qt.rgba(1, 1, 1, 0.10)
                border.width: 1
                radius: 16
                
                opacity: (height > 10) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                clip: true
            }

            // ── Folder mode pill — lives at left, revealed as search bar retreats ──
            // z-order: folder pill is BEHIND (lower z) than searchCardBg.
            // The search bar starts full-width and covers it; when files mode
            // activates the search bar's left edge bounces right, exposing the pill.
            Rectangle {
                id: modeIndicatorBg
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                height: card.searchH + card.verticalPad * 2
                width: height  // square pill, same height as search bar
                radius: height / 2
                z: 0  // behind the search bar

                // Instant show — it just sits there; the search bar reveals it
                opacity: card.isModeFiles ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 80 } }

                color: Qt.rgba(root.colSurfaceContainer.r, root.colSurfaceContainer.g, root.colSurfaceContainer.b, root.bgOpacity)
                border.color: Qt.rgba(1, 1, 1, 0.10)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "folder"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 20
                    color: root.colOnSurface
                    opacity: card.isModeFiles ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }

            // ── Search bar pill — bounces right, uncovering the folder pill ──
            Rectangle {
                id: searchCardBg
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                // Shrinks from the LEFT as splitOffset grows (with OutBack bounce)
                // This makes it look like the left portion tears off
                width: parent.width - card.splitOffset
                height: Math.min(card.height, card.searchH + card.verticalPad * 2)
                z: 1  // on top, covering the folder pill when not split

                color: Qt.rgba(root.colSurfaceContainer.r, root.colSurfaceContainer.g, root.colSurfaceContainer.b, root.bgOpacity)
                border.color: Qt.rgba(1, 1, 1, 0.10)
                border.width: 1
                radius: height / 2
            }

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
            anchors.topMargin: card.verticalPad + 8
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: card.searchH + card.verticalPad * 2 + 24
            clip: true
            opacity: root.isOpen ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 300 } }



            Column {
                anchors.centerIn: parent
                spacing: 10
                visible: appList.count === 0
                opacity: appList.count === 0 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "search" // material icon
                    font.family: "Material Symbols Rounded"
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

            ListView {
                id: appList
                anchors.fill: parent
                anchors.leftMargin: card.cardPad
                anchors.rightMargin: card.cardPad
                clip: true
                spacing: 4
                currentIndex: 0
                maximumFlickVelocity: 2500
                model: root.filteredApps
                onModelChanged: positionViewAtBeginning()
                
                Rectangle {
                    id: rowHighlight
                    x: 0
                    width: appList.width
                    height: appList.currentItem ? appList.currentItem.height : card.itemH
                    y: appList.currentItem ? (appList.currentItem.y - appList.contentY) : 0
                    radius: height / 2
                    color: root.colOnSurface
                    opacity: appList.count > 0 ? 0.09 : 0
                    visible: appList.count > 0

                    Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0] } }
                    Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0] } }
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
                    height: (delegateItem.modelData?.isWebResult) ? 96 : card.itemH

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
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
                        visible: !(delegateItem.modelData?.isWebResult ?? false)
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        IconImage {
                            asynchronous: true
                            source: {
                                let icn = delegateItem.modelData?.icon ?? "";
                                if (icn.startsWith("http://") || icn.startsWith("https://")) {
                                    return icn;
                                }
                                return Quickshell.iconPath(icn, "application-x-executable");
                            }
                            width: 32
                            height: 32
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0
                            width: parent.width - 44 - 12

                            Text {
                                text: delegateItem.modelData?.name ?? ""
                                color: root.colOnSurface
                                font.weight: Theme.defaultFontWeight; font.pixelSize: Theme.defaultFontSize - 1
                                font.family: Theme.defaultFontFamily
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: delegateItem.modelData?.comment
                                      || delegateItem.modelData?.genericName
                                      || ""
                                color: root.colOnSurfaceVariant
                                font.weight: Theme.defaultFontWeight; font.pixelSize: 11
                                font.family: Theme.defaultFontFamily
                                elide: Text.ElideRight
                                width: parent.width
                                visible: text.length > 0
                            }
                        }
                    }

                    Column {
                        visible: delegateItem.modelData?.isWebResult ?? false
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        anchors.topMargin: 12
                        anchors.bottomMargin: 12
                        spacing: 4

                        Row {
                            spacing: 6
                            IconImage {
                                asynchronous: true
                                source: delegateItem.modelData?.icon ?? ""
                                width: 14
                                height: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: {
                                    let url = delegateItem.modelData?.command?.[1] ?? "";
                                    if (url.startsWith("http")) {
                                        let domain = url.split("/")[2] ?? "";
                                        return domain.replace("www.", "") + " › " + url.split("/").slice(3,5).join(" › ");
                                    }
                                    return "";
                                }
                                color: root.colOnSurfaceVariant
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                width: parent.parent.width - 24
                            }
                        }

                        Text {
                            text: delegateItem.modelData?.name ?? ""
                            color: "#8ab4f8"
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: delegateItem.modelData?.comment ?? ""
                            color: root.colOnSurfaceVariant
                            font.family: Theme.defaultFontFamily
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            width: parent.width
                            lineHeight: 1.1
                        }
                    }
                }
            }
        }

        // ── Search bar ────────────────────────────────────────────────
        Rectangle {
            id: searchBar
            parent: card
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: card.dynamicMargin
            anchors.bottomMargin: card.dynamicVMargin
            width: parent.width - (card.splitOffset > 0 ? card.splitOffset : 0) - card.dynamicMargin * 2

            height: card.searchH
            radius: height / 2
            clip: true

            color: "transparent"
            border.width: 0

            // Search icon background
            Item {
                id: searchIconWrapper
                anchors.left: parent.left
                anchors.leftMargin: card.width > 200 ? 12 : (card.width - width) / 2
                anchors.verticalCenter: parent.verticalCenter
                width: 80
                height: 32

                Image {
                    id: searchIconTxt
                    anchors.centerIn: parent
                    source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/cupcake-word-" + (Theme.isDark ? "light" : "dark") + ".svg"
                    height: 26
                    width: 73
                    fillMode: Image.PreserveAspectFit
                    opacity: 1.0
                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        color: root.colOnSurface
                    }
                    smooth: true
                    scale: card.width > 200 ? 1.0 : 0.95
                    Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutElastic; easing.amplitude: 0.6 } }
                }
            }

            // Inner Pill for Text Input
            Rectangle {
                id: searchInputPill
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                radius: height / 2
                color: "transparent"
                opacity: card.width > 250 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 100 } }
                
                Text {
                    id: separatorDot
                    anchors.left: parent.left
                    anchors.leftMargin: 88
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.colOnSurfaceVariant
                    text: "•"
                    font.pixelSize: 10
                    opacity: card.width > 100 ? 0.7 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }

                // Placeholder
                Text {
                    id: placeholderTxt
                    anchors.left: parent.left
                    anchors.leftMargin: 106
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.colOnSurfaceVariant
                    font.pixelSize: 13
                    font.family: Theme.defaultFontFamily
                    text: true ? "Search, calculate or run" : "Search applications…"
                    visible: searchField.text.length === 0
                    opacity: card.width > 100 ? 0.75 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }

                TextInput {
                    id: searchField
                    anchors.left: parent.left
                    anchors.leftMargin: 106
                    anchors.right: clearBtn.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.colOnSurface
                    font.weight: Theme.defaultFontWeight; font.pixelSize: 14
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
                Rectangle {
                    id: clearBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22
                    radius: 11
                    color: Qt.rgba(root.colOnSurface.r, root.colOnSurface.g, root.colOnSurface.b, clearBtnMa.containsMouse ? 0.15 : 0.08)
                    border.width: 0
                    opacity: searchField.text.length > 0 && card.width > 100 ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "close"
                        font.family: "Material Symbols Rounded"
                        font.weight: Theme.defaultFontWeight
                        font.pixelSize: 14
                        color: root.colOnSurfaceVariant
                    }

                    MouseArea {
                        id: clearBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
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

        Shape {
            visible: false
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
            visible: false
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
    } // Item
} // PanelWindow
