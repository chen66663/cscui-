pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic

// Shared scrollbar skin for the workbench. Qt's platform default can inject a
// bright track in dark mode, so both pieces are mapped to semantic theme tokens.
Basic.ScrollBar {
    id: root

    property var theme: null
    readonly property color trackColor: theme ? theme.tertiaryColor : "#F2F2F7"
    readonly property color idleHandleColor: theme ? theme.secondaryTextColor : "#8E8E93"
    readonly property color activeHandleColor: theme ? theme.focusColor : "#007AFF"
    readonly property int colorAnimationDuration: theme ? theme.durationFast : 140

    implicitWidth: 10
    implicitHeight: 10
    padding: 2
    hoverEnabled: true

    background: Rectangle {
        radius: width / 2
        color: root.trackColor
        opacity: root.active || root.hovered ? 0.55 : 0.24
    }

    contentItem: Rectangle {
        implicitWidth: 6
        implicitHeight: 6
        radius: width / 2
        color: root.active || root.hovered ? root.activeHandleColor : root.idleHandleColor
        opacity: root.active || root.hovered ? 0.9 : 0.58

        Behavior on color {
            ColorAnimation {
                duration: root.colorAnimationDuration
            }
        }
    }
}
