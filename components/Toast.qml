pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects

// Transient status message. show() is idempotent: repeated calls replace the
// message, restart the entrance animation, and restart the dismissal timer.
Item {
    id: root

    property var theme
    property string text: ""
    property int duration: 2200
    property bool shadowEnabled: true
    property real radius: theme ? (theme.radiusLarge || 12) : 12
    property int padding: 12
    property real maxWidth: 420
    property color bgColor: theme ? theme.secondaryColor : "#FFFFFF"
    property color fgColor: theme ? theme.textColor : "#1D1D1F"
    property real yOffset: 0
    property string accessibleName: root.text

    width: Math.min(Math.max(1, contentItem.implicitWidth), root.maxWidth) + root.padding * 2
    height: contentItem.implicitHeight + root.padding * 2
    visible: false
    opacity: 0
    z: 2000

    Accessible.role: Accessible.Alert
    Accessible.name: root.accessibleName

    transform: Translate {
        y: root.yOffset
    }

    Rectangle {
        id: background
        anchors.fill: parent
        radius: Math.max(0, root.radius)
        color: root.bgColor
        border.width: 1
        border.color: theme ? theme.borderColor : "#D1D1D6"
    }

    MultiEffect {
        source: background
        anchors.fill: background
        visible: root.shadowEnabled
        shadowEnabled: visible
        shadowColor: theme ? theme.shadowColor : "#40000000"
        shadowBlur: theme ? theme.shadowBlur : 0.25
        shadowVerticalOffset: theme ? theme.shadowYOffset : 2
        shadowHorizontalOffset: theme ? theme.shadowXOffset : 0
    }

    Text {
        id: contentItem
        anchors.centerIn: parent
        width: Math.max(0, Math.min(root.maxWidth, implicitWidth))
        text: root.text
        color: root.fgColor
        font.family: theme ? theme.fontFamily : "sans-serif"
        font.pixelSize: 14
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
    }

    Behavior on opacity {
        NumberAnimation {
            duration: theme ? theme.durationNormal : 220
            easing.type: Easing.OutCubic
        }
    }

    function show(message) {
        outAnimation.stop();
        hideTimer.stop();
        root.text = String(message);
        root.visible = true;
        root.opacity = 1;
        root.yOffset = -12;
        enterAnimation.restart();
        hideTimer.restart();
    }

    function hide() {
        hideTimer.stop();
        if (!root.visible)
            return;
        outAnimation.restart();
    }

    PropertyAnimation {
        id: enterAnimation
        target: root
        property: "yOffset"
        from: -12
        to: 0
        duration: theme ? theme.durationNormal : 220
        easing.type: Easing.OutCubic
    }

    PropertyAnimation {
        id: outAnimation
        target: root
        property: "yOffset"
        from: 0
        to: -12
        duration: theme ? theme.durationFast : 160
        easing.type: Easing.InCubic
        onFinished: {
            root.opacity = 0;
            root.visible = false;
        }
    }

    Timer {
        id: hideTimer
        interval: Math.max(0, root.duration)
        repeat: false
        onTriggered: root.hide()
    }

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "Toast"
        nameZh: "提示"
    }
}
