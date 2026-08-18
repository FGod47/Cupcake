import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../../theme"
import Quickshell.Io
import Quickshell
import "../common"

Item {
    id: root

    property color cText: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.88)
    property color cTextDim: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.6)
    property color cAccent: Theme.colPrimary
    property color cBgElevated: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.05)

    property string username: Quickshell.env("USER") || "zero"
    property string realName: "Zero"
    property string hostname: "infinity"
    property string shellPath: "/usr/bin/zsh"
    property string homeDirPath: Theme.homeDir || "/home/zero"
    property string uidGid: "1000:1000"
    property string groupsList: "wheel, audio, video, storage, network, users"
    property string diskUsageText: "Calculating..."
    property real diskUsagePercent: 0.34
    property string avatarPath: ""
    property int avatarTimestamp: Date.now()

    Process {
        id: userDataReader
        command: ["bash", "-c", '
echo "USER: $(whoami)"
echo "REALNAME: $(getent passwd $USER 2>/dev/null | cut -d ":" -f 5 | cut -d "," -f 1)"
echo "UID: $(id -u 2>/dev/null):$(id -g 2>/dev/null)"
echo "SHELL: $SHELL"
echo "HOME: $HOME"
echo "GROUPS: $(groups 2>/dev/null)"
echo "HOSTNAME: $(hostname 2>/dev/null)"
echo "DISK: $(df -h ~ 2>/dev/null | awk "NR==2 {print \$3 \" of \" \$2 \" (\" \$5 \" used)\"}")"
echo "PERCENT: $(df -h ~ 2>/dev/null | awk "NR==2 {print \$5}" | tr -d "%")"
echo "AVATAR: $(ls ~/.face ~/.face.icon ~/.local/share/qylock-themes/cupcake-sddm/avatar.png 2>/dev/null | head -n 1)"
']
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                let lines = text.trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i];
                    if (line.startsWith("USER: ")) root.username = line.substring(6).trim();
                    else if (line.startsWith("REALNAME: ")) {
                        let rn = line.substring(10).trim();
                        if (rn !== "") root.realName = rn;
                    }
                    else if (line.startsWith("UID: ")) root.uidGid = line.substring(5).trim();
                    else if (line.startsWith("SHELL: ")) root.shellPath = line.substring(7).trim();
                    else if (line.startsWith("HOME: ")) root.homeDirPath = line.substring(6).trim();
                    else if (line.startsWith("GROUPS: ")) root.groupsList = line.substring(8).trim();
                    else if (line.startsWith("HOSTNAME: ")) root.hostname = line.substring(10).trim();
                    else if (line.startsWith("DISK: ")) root.diskUsageText = line.substring(6).trim();
                    else if (line.startsWith("PERCENT: ")) {
                        let p = parseFloat(line.substring(9).trim());
                        if (!isNaN(p)) root.diskUsagePercent = Math.min(1.0, Math.max(0.0, p / 100.0));
                    }
                    else if (line.startsWith("AVATAR: ")) root.avatarPath = line.substring(8).trim();
                }
            }
        }
    }

    Timer {
        interval: 6000
        repeat: true
        running: true
        onTriggered: {
            if (!userDataReader.running) userDataReader.running = true;
        }
    }

    ScrollView {
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        anchors.fill: parent
        anchors.bottomMargin: 28
        leftPadding: 32
        rightPadding: 32
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 20

            // ── 1. USER PROFILE HERO CARD ──────────────────────────────────
            NCard {
                sectionTitle: "User profile"

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    Layout.bottomMargin: 8
                    spacing: 24

                    // Large Avatar with Interactive Hover
                    Rectangle {
                        Layout.preferredWidth: 84
                        Layout.preferredHeight: 84
                        radius: 42
                        color: cBgElevated
                        border.color: Theme.colPrimary
                        border.width: 2
                        clip: true

                        Rectangle {
                            id: heroAvatarMask
                            anchors.fill: parent
                            radius: 42
                            visible: false
                        }

                        Item {
                            anchors.fill: parent
                            layer.enabled: true
                            layer.effect: OpacityMask { maskSource: heroAvatarMask }

                            Image {
                                id: userHeroAvatarImg
                                anchors.fill: parent
                                source: (root.avatarPath !== "" ? ("file://" + root.avatarPath) : ("file://" + Theme.homeDir + "/.local/share/qylock-themes/cupcake-sddm/avatar.png")) + "?t=" + root.avatarTimestamp
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            // Fallback Monogram
                            Text {
                                anchors.centerIn: parent
                                visible: userHeroAvatarImg.status !== Image.Ready
                                text: root.username.length > 0 ? root.username.charAt(0).toUpperCase() : "U"
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 36
                                font.weight: Font.Bold
                                color: Theme.colPrimary
                            }

                            // Hover Overlay with Camera Icon
                            Rectangle {
                                anchors.fill: parent
                                color: Qt.rgba(0, 0, 0, 0.55)
                                opacity: avatarMa.containsMouse ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "\uea4e" // camera / photo
                                        font.family: "tabler-icons"
                                        font.pixelSize: 20
                                        color: "#ffffff"
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "EDIT"
                                        font.family: Theme.defaultFontFamily
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                        color: "#ffffff"
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: avatarMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["bash", "-c", "XDG_CURRENT_DESKTOP=gnome zenity --file-selection --file-filter='Images | *.png *.jpg *.jpeg *.webp' --file-filter='All Files | *' 2>/dev/null | xargs -I{} " + Theme.homeDir + "/.local/bin/cupcake-set-avatar \"{}\""]);
                                updateAvatarTimer.start();
                            }
                        }
                    }

                    // User Identity & Badges
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        RowLayout {
                            spacing: 10
                            Text {
                                text: root.realName !== "" ? root.realName : root.username
                                color: Theme.colOnSurface
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 22
                                font.weight: Font.Bold
                                font.letterSpacing: -0.3
                            }

                            // Admin Pill Badge
                            Rectangle {
                                height: 22; radius: 11
                                width: adminRow.implicitWidth + 16
                                color: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.15)
                                border.width: 1; border.color: Theme.colPrimary
                                RowLayout {
                                    id: adminRow; anchors.centerIn: parent; spacing: 4
                                    Text { text: "\ueaf8"; font.family: "tabler-icons"; font.pixelSize: 11; color: Theme.colPrimary }
                                    Text { text: "ADMINISTRATOR"; font.family: Theme.defaultFontFamily; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.colPrimary }
                                }
                            }
                        }

                        RowLayout {
                            spacing: 12
                            Text {
                                text: "@" + root.username
                                color: Theme.colOnSurfaceVariant
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }
                            Text { text: "•"; color: Theme.colOnSurfaceVariant; opacity: 0.5 }
                            Text {
                                text: root.hostname
                                color: Theme.colOnSurfaceVariant
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 12
                                opacity: 0.8
                            }
                        }

                        // Action Buttons
                        RowLayout {
                            Layout.topMargin: 4
                            spacing: 10

                            // Change Avatar Button
                            Rectangle {
                                height: 32; radius: 8
                                implicitWidth: changeAvatarRow.implicitWidth + 20
                                color: Theme.colPrimary
                                scale: changeAvatarMa.containsMouse ? 1.02 : 1.0
                                Behavior on scale { NumberAnimation { duration: 120 } }
                                RowLayout {
                                    id: changeAvatarRow; anchors.centerIn: parent; spacing: 6
                                    Text { text: "\uea4e"; font.family: "tabler-icons"; font.pixelSize: 13; color: Theme.colSurface }
                                    Text { text: "Change Avatar"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.Bold; color: Theme.colSurface }
                                }
                                MouseArea {
                                    id: changeAvatarMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["bash", "-c", "XDG_CURRENT_DESKTOP=gnome zenity --file-selection --file-filter='Images | *.png *.jpg *.jpeg *.webp' --file-filter='All Files | *' 2>/dev/null | xargs -I{} " + Theme.homeDir + "/.local/bin/cupcake-set-avatar \"{}\""]);
                                        updateAvatarTimer.start();
                                    }
                                }
                            }

                            // Change Password Button
                            Rectangle {
                                height: 32; radius: 8
                                implicitWidth: changePassRow.implicitWidth + 18
                                color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
                                border.width: 1; border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.15)
                                RowLayout {
                                    id: changePassRow; anchors.centerIn: parent; spacing: 6
                                    Text { text: "\ueab0"; font.family: "tabler-icons"; font.pixelSize: 13; color: Theme.colPrimary }
                                    Text { text: "Change Password"; font.family: Theme.defaultFontFamily; font.pixelSize: 12; font.weight: Font.Medium; color: Theme.colOnSurface }
                                }
                                MouseArea {
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached(["bash", "-c", "foot -e passwd || kitty -e passwd || alacritty -e passwd 2>/dev/null"])
                                }
                            }
                        }
                    }
                }
            }

            // Timer to reload avatar after change
            Timer {
                id: updateAvatarTimer
                interval: 1500
                onTriggered: {
                    root.avatarTimestamp = Date.now();
                    if (!userDataReader.running) userDataReader.running = true;
                }
            }

            // ── 2. ACCOUNT & SYSTEM DETAILS ────────────────────────────────
            NCard {
                sectionTitle: "Account details"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueae5" } // user
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Full name"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Display name associated with this user account"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text { text: root.realName; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Bold }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueaf3" } // at / id
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Username & UID"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "POSIX system login name and identifier"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text { text: root.username + " (" + root.uidGid + ")"; color: Theme.colPrimary; font.family: Theme.monoFontFamily; font.pixelSize: 12; font.weight: Font.Bold }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\uea83" } // home
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Home directory"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Primary user storage and personal configurations directory"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text { text: root.homeDirPath; color: Theme.colOnSurface; font.family: Theme.monoFontFamily; font.pixelSize: 12 }
                }

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueaf4" } // terminal
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Login shell"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: "Default interactive command-line interpreter"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.pixelSize: 11; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        height: 24; radius: 6
                        width: shellBadgeRow.implicitWidth + 14
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)
                        border.width: 1; border.color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
                        RowLayout {
                            id: shellBadgeRow; anchors.centerIn: parent; spacing: 4
                            Text { text: root.shellPath.split("/").pop().toUpperCase(); font.family: Theme.monoFontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: Theme.colPrimary }
                        }
                    }
                }
            }

            // ── 3. STORAGE USAGE ───────────────────────────────────────────
            NCard {
                sectionTitle: "Home directory storage"

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Disk Space Used"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                        Item { Layout.fillWidth: true }
                        Text { text: root.diskUsageText; color: Theme.colPrimary; font.family: Theme.monoFontFamily; font.pixelSize: 12; font.weight: Font.Bold }
                    }

                    // Usage Progress Bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 8; radius: 4
                        color: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.08)

                        Rectangle {
                            height: parent.height; radius: 4
                            width: Math.max(8, parent.width * root.diskUsagePercent)
                            color: Theme.colPrimary
                            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            // ── 4. GROUPS & PRIVILEGES ─────────────────────────────────────
            NCard {
                sectionTitle: "Groups & access permissions"

                NRow {
                    RowLayout {
                        spacing: 12
                        NIconBadge { icon: "\ueb2a" } // shield-check
                        ColumnLayout {
                            spacing: 1
                            Text { text: "System groups"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                            Text { text: root.groupsList; color: Theme.colOnSurfaceVariant; font.family: Theme.monoFontFamily; font.pixelSize: 11; opacity: 0.8; Layout.preferredWidth: 600; wrapMode: Text.WordWrap }
                        }
                    }
                }
            }
        }
    }
}
