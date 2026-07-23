pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

// A switch exposes one source of truth (checked) and emits toggled after every
// user gesture. The track and thumb dimensions are independent of the label.
FocusScope {
    id: root

    // Explicit injection keeps Bound components synchronized with the shell theme.
    property var theme

    property string text: theme ? theme.localized("Switch", "开关") : "Switch"
    property bool checked: false
    signal toggled(bool checked)

    property bool backgroundVisible: true
    property real radius: theme ? (theme.radiusMedium || 8) : 8
    property string size: "m"
    readonly property real contentScale: 0.4
    readonly property real trackWidth: sizeTokens.trackWidth
    readonly property real trackHeight: sizeTokens.trackHeight
    readonly property real thumbSize: sizeTokens.thumbSize
    property int fontSize: sizeTokens.fontSize
    property int labelSpacing: sizeTokens.spacing
    property color containerColor: theme ? theme.secondaryColor : "#FFFFFF"
    property color hoverColor: theme ? theme.hoverColor : "#E5E5EA"
    property color textColor: theme ? theme.textColor : "#1D1D1F"
    property color thumbColor: "#FFFFFF"
    property bool shadowEnabled: true
    property real pressedScale: 0.98
    property color shadowColor: theme ? theme.shadowColor : "#24000000"
    readonly property int paddingLeft: sizeTokens.padding
    readonly property int paddingRight: sizeTokens.padding
    property string accessibleName: root.text

    QtObject {
        id: sizeTokens
        readonly property var current: ({
                xs: ({
                        height: 32,
                        padding: 8,
                        fontSize: 13,
                        spacing: 6,
                        trackWidth: 32,
                        trackHeight: 18,
                        thumbSize: 14
                    }),
                s: ({
                        height: 36,
                        padding: 10,
                        fontSize: 14,
                        spacing: 7,
                        trackWidth: 36,
                        trackHeight: 20,
                        thumbSize: 16
                    }),
                m: ({
                        height: 44,
                        padding: 12,
                        fontSize: 15,
                        spacing: 8,
                        trackWidth: 40,
                        trackHeight: 22,
                        thumbSize: 18
                    }),
                l: ({
                        height: 52,
                        padding: 16,
                        fontSize: 16,
                        spacing: 9,
                        trackWidth: 46,
                        trackHeight: 26,
                        thumbSize: 22
                    }),
                xl: ({
                        height: 60,
                        padding: 20,
                        fontSize: 18,
                        spacing: 10,
                        trackWidth: 54,
                        trackHeight: 30,
                        thumbSize: 26
                    })
            })[root.size] || ({
                height: 44,
                padding: 12,
                fontSize: 15,
                spacing: 8,
                trackWidth: 40,
                trackHeight: 22,
                thumbSize: 18
            })
        readonly property int height: current.height
        readonly property int padding: current.padding
        readonly property int fontSize: current.fontSize
        readonly property int spacing: current.spacing
        readonly property int trackWidth: current.trackWidth
        readonly property int trackHeight: current.trackHeight
        readonly property int thumbSize: current.thumbSize
    }

    implicitHeight: sizeTokens.height
    implicitWidth: controlRow.implicitWidth + root.paddingLeft + root.paddingRight
    activeFocusOnTab: true
    opacity: root.enabled ? 1 : 0.45

    Accessible.role: Accessible.CheckBox
    Accessible.name: root.accessibleName
    Accessible.checkable: true
    Accessible.checked: root.checked

    transform: Scale {
        id: pressScale
        origin.x: root.width / 2
        origin.y: root.height / 2
    }

    MultiEffect {
        source: surface
        anchors.fill: surface
        visible: root.backgroundVisible && root.shadowEnabled
        shadowEnabled: visible
        shadowColor: root.shadowColor
        shadowBlur: theme ? theme.shadowBlur : 0.25
        shadowHorizontalOffset: theme ? theme.shadowXOffset : 0
        shadowVerticalOffset: theme ? theme.shadowYOffset : 2
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: Math.max(0, root.radius)
        visible: root.backgroundVisible
        color: pointer.pressed ? (theme ? theme.pressedColor : "#D1D1D6") : ((pointer.containsMouse || root.activeFocus) ? root.hoverColor : root.containerColor)
        Behavior on color {
            ColorAnimation {
                duration: theme ? theme.durationFast : 120
            }
        }
    }

    RowLayout {
        id: controlRow
        anchors.centerIn: parent
        spacing: Math.max(0, root.labelSpacing)

        Rectangle {
            id: track
            Layout.preferredWidth: root.trackWidth
            Layout.preferredHeight: root.trackHeight
            radius: height / 2
            color: root.checked ? (theme ? theme.focusColor : "#007AFF") : (theme ? theme.tertiaryTextColor : "#8E8E93")
            border.width: root.checked ? 0 : 1
            border.color: theme ? theme.borderColor : "#D1D1D6"
            clip: true

            Behavior on color {
                ColorAnimation {
                    duration: theme ? theme.durationFast : 120
                }
            }

            Rectangle {
                id: thumb
                width: root.thumbSize
                height: root.thumbSize
                radius: width / 2
                color: root.checked && theme ? theme.onAccentColor : root.thumbColor
                anchors.verticalCenter: parent.verticalCenter
                x: root.checked ? parent.width - width - 2 : 2
                Behavior on x {
                    NumberAnimation {
                        duration: theme ? theme.durationNormal : 180
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Text {
            text: root.text
            color: root.textColor
            font.family: theme ? theme.fontFamily : "sans-serif"
            font.pixelSize: root.fontSize
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            Layout.maximumWidth: Math.max(0, root.width - root.trackWidth - root.paddingLeft - root.paddingRight - root.labelSpacing)
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: {
            root.forceActiveFocus();
            pressScale.xScale = root.pressedScale;
            pressScale.yScale = root.pressedScale;
        }
        onReleased: {
            restoreScale.restart();
            if (containsMouse)
                root.toggleFromUser();
        }
        onCanceled: restoreScale.restart()
    }

    function toggleFromUser() {
        if (!root.enabled)
            return;
        root.checked = !root.checked;
        root.toggled(root.checked);
    }

    ParallelAnimation {
        id: restoreScale
        NumberAnimation {
            target: pressScale
            property: "xScale"
            to: 1
            duration: theme ? theme.durationFast : 120
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: pressScale
            property: "yScale"
            to: 1
            duration: theme ? theme.durationFast : 120
            easing.type: Easing.OutCubic
        }
    }

    Keys.onSpacePressed: {
        event.accepted = true;
        root.toggleFromUser();
    }
    Keys.onReturnPressed: {
        event.accepted = true;
        root.toggleFromUser();
    }
    Keys.onEnterPressed: {
        event.accepted = true;
        root.toggleFromUser();
    }

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "SwitchButton"
        nameZh: "开关"
    }
}
