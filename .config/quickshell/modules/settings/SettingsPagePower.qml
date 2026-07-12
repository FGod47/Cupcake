import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "../../theme"
import "../common"

Item {
    id: root
    property string activeTab: "battery"
    
    // Battery State
    property string batteryPercent: "Unknown"
    property string batteryStatus: "Unknown"
    property bool hasBattery: false
    
    // Warning State
    property bool warningsEnabled: true

    Command {
        id: batCommand
        command: ["bash", "-c", "bat=$(ls /sys/class/power_supply | grep -i bat | head -n 1); if [ -n \"$bat\" ]; then echo \"$(cat /sys/class/power_supply/$bat/capacity)|$(cat /sys/class/power_supply/$bat/status)\"; else echo \"No Battery\"; fi"]
        onStdoutLinesChanged: {
            if (stdoutLines.length > 0) {
                let out = stdoutLines[0];
                if (out === "No Battery" || out === "") {
                    root.hasBattery = false;
                } else {
                    root.hasBattery = true;
                    let parts = out.split("|");
                    root.batteryPercent = parts[0] + "%";
                    root.batteryStatus = parts[1];
                }
            }
        }
    }

    Command {
        id: checkWarningsCommand
        command: ["bash", "-c", "if [ -f ~/.config/cupcake/disable_battery_warnings ]; then echo 'disabled'; else echo 'enabled'; fi"]
        onStdoutLinesChanged: {
            if (stdoutLines.length > 0) {
                root.warningsEnabled = (stdoutLines[0] === "enabled");
            }
        }
    }

    Timer {
        interval: 10000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            batCommand.running = true;
            checkWarningsCommand.running = true;
        }
    }

    onVisibleChanged: {
        if (visible) {
            batCommand.running = true;
            checkWarningsCommand.running = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16
        
        SettingsSegmentedControl {
            Layout.fillWidth: true
            model: [
                { label: "Battery", value: "battery" },
                { label: "Session & Idle", value: "session-panel" }
            ]
            currentValue: root.activeTab
            onValueChanged: (val, idx) => { root.activeTab = val; }
        }
        
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            // BATTERY TAB
            ScrollView {
                anchors.fill: parent
                contentWidth: availableWidth
                clip: true
                visible: root.activeTab === "battery"
                
                ColumnLayout {
                    width: Math.min(parent.width, 1000)
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 24
                    
                    SettingsCard {
                        title: "Battery Information"
                        icon: "\uea38"
                        surfaceColor: Theme.colSurfaceContainer
                        outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                        primaryColor: Theme.colPrimary
                        onSurfaceColor: Theme.colOnSurface
                        
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Current Level"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                Text { text: root.hasBattery ? root.batteryStatus : "Not found"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                            }
                            Text {
                                text: root.hasBattery ? root.batteryPercent : "--"
                                color: Theme.colPrimary
                                font.family: Theme.defaultFontFamily
                                font.pixelSize: 24
                                font.weight: 800
                            }
                        }
                    }

                    SettingsCard {
                        title: "Power Alerts"
                        icon: "\uea02"
                        surfaceColor: Theme.colSurfaceContainer
                        outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                        primaryColor: Theme.colPrimary
                        onSurfaceColor: Theme.colOnSurface
                        
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Low Battery Warnings"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                Text { text: "Show desktop notifications when battery drops below 20%, 10%, and 5%"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                            }
                            StyledSwitch {
                                checked: root.warningsEnabled
                                onCheckedChanged: {
                                    if (checked) {
                                        Quickshell.execDetached(["bash", "-c", "rm -f ~/.config/cupcake/disable_battery_warnings"]);
                                    } else {
                                        Quickshell.execDetached(["bash", "-c", "touch ~/.config/cupcake/disable_battery_warnings"]);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // SESSION TAB
            ScrollView {
                anchors.fill: parent
                contentWidth: availableWidth
                clip: true
                visible: root.activeTab === "session-panel"
                
                ColumnLayout {
                    width: Math.min(parent.width, 1000)
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 24
                    
                    SettingsCard {
                        title: "Session Panel Settings"
                        icon: ""
                        surfaceColor: Theme.colSurfaceContainer
                        outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                        primaryColor: Theme.colPrimary
                        onSurfaceColor: Theme.colOnSurface
                        
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Session Actions"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                Text { text: "Show session actions directly in the panel"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                            }
                            StyledSwitch {
                                checked: true
                                onCheckedChanged: {}
                            }
                        }
                    }
                    
                    SettingsCard {
                        title: "Idle Settings"
                        icon: "\uea63"
                        surfaceColor: Theme.colSurfaceContainer
                        outlineColor: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
                        primaryColor: Theme.colPrimary
                        onSurfaceColor: Theme.colOnSurface
                        
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                Text { text: "Pre Action Fade"; color: Theme.colOnSurface; font.family: Theme.defaultFontFamily; font.pixelSize: Theme.defaultFontSize; font.weight: Math.min(900, Theme.defaultFontWeight + 200) }
                                Text { text: "Fade screen before sleeping"; color: Theme.colOnSurfaceVariant; font.family: Theme.defaultFontFamily; font.weight: Theme.defaultFontWeight; font.pixelSize: 12; Layout.maximumWidth: 300; wrapMode: Text.WordWrap }
                            }
                            StyledSwitch {
                                checked: false
                                onCheckedChanged: {}
                            }
                        }
                    }
                }
            }
        }
    }
}
