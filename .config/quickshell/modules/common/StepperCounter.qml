import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"

Rectangle {
    id: root

    // Configurable Properties
    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property string suffix: ""
    property string prefix: ""
    property int decimals: (stepSize % 1 === 0 ? 0 : (stepSize < 0.1 ? 2 : 1))
    property bool editable: true

    // Colors
    property color colBg: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.06)
    property color colBorder: Qt.rgba(Theme.colOutline.r, Theme.colOutline.g, Theme.colOutline.b, 0.15)
    property color colHover: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.12)
    property color colPressed: Qt.rgba(Theme.colPrimary.r, Theme.colPrimary.g, Theme.colPrimary.b, 0.25)
    property color colText: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.90)
    property color colTextDim: Qt.rgba(Theme.colOnSurface.r, Theme.colOnSurface.g, Theme.colOnSurface.b, 0.55)
    property color colAccent: Theme.colPrimary

    signal valueModified(real newValue)

    implicitWidth: Math.max(120, centerContent.implicitWidth + 64)
    implicitHeight: 32
    radius: height / 2
    color: colBg
    border.color: editField.activeFocus ? colAccent : colBorder
    border.width: 1

    Behavior on border.color { ColorAnimation { duration: 150 } }
    Behavior on color { ColorAnimation { duration: 150 } }

    function formattedValue(v) {
        let rounded = Number(v.toFixed(root.decimals));
        let numStr = root.decimals > 0 ? rounded.toFixed(root.decimals) : rounded.toString();
        return (root.prefix !== "" ? root.prefix + " " : "") + numStr + (root.suffix !== "" ? " " + root.suffix : "");
    }

    function setValueClamped(newVal) {
        let clamped = Math.max(root.from, Math.min(root.to, newVal));
        if (root.decimals === 0) clamped = Math.round(clamped);
        else clamped = Number(clamped.toFixed(root.decimals));
        
        if (clamped !== root.value) {
            root.value = clamped;
            root.valueModified(clamped);
        }
    }

    function decrement() {
        setValueClamped(root.value - root.stepSize);
    }

    function increment() {
        setValueClamped(root.value + root.stepSize);
    }

    // Auto-repeat timers for smooth press-and-hold
    Timer {
        id: repeatTimer
        property var action: null
        interval: 350
        repeat: false
        onTriggered: stepTimer.running = true
    }

    Timer {
        id: stepTimer
        interval: 65
        repeat: true
        onTriggered: {
            if (repeatTimer.action) repeatTimer.action();
        }
    }

    function startAutoRepeat(fn) {
        fn();
        repeatTimer.action = fn;
        repeatTimer.start();
    }

    function stopAutoRepeat() {
        repeatTimer.stop();
        stepTimer.stop();
        repeatTimer.action = null;
    }

    // Mouse wheel support over the entire capsule
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) root.increment();
            else if (wheel.angleDelta.y < 0) root.decrement();
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Minus Button
        Rectangle {
            id: minusBtn
            Layout.preferredWidth: 30
            Layout.fillHeight: true
            radius: parent.height / 2
            color: minusMa.pressed ? root.colPressed : (minusMa.containsMouse ? root.colHover : "transparent")
            opacity: root.value <= root.from ? 0.35 : 1.0

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "−"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 16
                font.weight: Font.Bold
                color: minusMa.containsMouse && root.value > root.from ? root.colAccent : root.colTextDim
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            MouseArea {
                id: minusMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.value > root.from ? Qt.PointingHandCursor : Qt.ArrowCursor
                onPressed: {
                    if (root.value > root.from) root.startAutoRepeat(root.decrement);
                }
                onReleased: root.stopAutoRepeat()
                onCanceled: root.stopAutoRepeat()
            }
        }

        // Center Value / Direct Editor
        Item {
            id: centerContent
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // Display Mode
            Text {
                id: valText
                anchors.centerIn: parent
                visible: !editField.visible
                text: root.formattedValue(root.value)
                color: valMa.containsMouse && root.editable ? root.colAccent : root.colText
                font.family: Theme.defaultFontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                Behavior on color { ColorAnimation { duration: 120 } }
            }

            MouseArea {
                id: valMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.editable ? Qt.IBeamCursor : Qt.ArrowCursor
                visible: !editField.visible
                onClicked: {
                    if (root.editable) {
                        editField.text = (root.decimals > 0 ? root.value.toFixed(root.decimals) : Math.round(root.value)).toString();
                        editField.visible = true;
                        editField.selectAll();
                        editField.forceActiveFocus();
                    }
                }
            }

            // Inline Direct Numeric Editor
            TextField {
                id: editField
                anchors.fill: parent
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                visible: false
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: root.colText
                font.family: Theme.defaultFontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                background: Item {}
                padding: 0

                function commit() {
                    let num = parseFloat(text.trim());
                    if (!isNaN(num)) {
                        root.setValueClamped(num);
                    }
                    visible = false;
                }

                onAccepted: commit()
                onActiveFocusChanged: {
                    if (!activeFocus && visible) commit();
                }
            }
        }

        // Plus Button
        Rectangle {
            id: plusBtn
            Layout.preferredWidth: 30
            Layout.fillHeight: true
            radius: parent.height / 2
            color: plusMa.pressed ? root.colPressed : (plusMa.containsMouse ? root.colHover : "transparent")
            opacity: root.value >= root.to ? 0.35 : 1.0

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "+"
                font.family: Theme.defaultFontFamily
                font.pixelSize: 16
                font.weight: Font.Bold
                color: plusMa.containsMouse && root.value < root.to ? root.colAccent : root.colTextDim
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            MouseArea {
                id: plusMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.value < root.to ? Qt.PointingHandCursor : Qt.ArrowCursor
                onPressed: {
                    if (root.value < root.to) root.startAutoRepeat(root.increment);
                }
                onReleased: root.stopAutoRepeat()
                onCanceled: root.stopAutoRepeat()
            }
        }
    }
}
