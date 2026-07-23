pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

// A compact action control. Public properties intentionally mirror the original
// component so catalog pages and downstream applications remain source compatible.
FocusScope {
    id: root

    // Explicit injection keeps Bound components synchronized with the shell theme.
    property var theme

    property string text: theme ? theme.localized("Button", "按钮") : "Button"
    property string iconCharacter: ""
    property string iconFontFamily: root.theme ? root.theme.iconFamily(iconFont.name) : iconFont.name
    signal clicked

    property bool backgroundVisible: true
    property real radius: theme ? (theme.radiusMedium || 8) : 8
    property color containerColor: theme ? theme.secondaryColor : "#FFFFFF"
    property color hoverColor: theme ? theme.hoverColor : "#E5E5EA"
    property color textColor: theme ? theme.textColor : "#1D1D1F"
    property color iconColor: root.textColor
    property string size: "m"
    property bool shadowEnabled: true
    property real pressedScale: 0.98
    property color shadowColor: theme ? theme.shadowColor : "#24000000"
    property bool iconRotateOnClick: false
    property bool textShown: root.text !== ""
    readonly property bool hasIcon: root.iconCharacter !== ""
    property int labelSpacing: sizeTokens.spacing
    readonly property real contentScale: 0.4
    readonly property int iconSize: sizeTokens.fontSize
    readonly property int fontSize: sizeTokens.fontSize
    readonly property int paddingLeft: sizeTokens.padding
    readonly property int paddingRight: sizeTokens.padding

    // New opt-in name for assistive technology; the old text property remains the fallback.
    property string accessibleName: root.text

    QtObject {
        id: sizeTokens
        readonly property var current: ({
                xs: ({
                        height: 32,
                        padding: 10,
                        fontSize: 13,
                        spacing: 4
                    }),
                s: ({
                        height: 36,
                        padding: 14,
                        fontSize: 14,
                        spacing: 6
                    }),
                m: ({
                        height: 44,
                        padding: 16,
                        fontSize: 15,
                        spacing: 7
                    }),
                l: ({
                        height: 52,
                        padding: 20,
                        fontSize: 16,
                        spacing: 8
                    }),
                xl: ({
                        height: 60,
                        padding: 24,
                        fontSize: 18,
                        spacing: 10
                    })
            })[root.size] || ({
                height: 44,
                padding: 16,
                fontSize: 15,
                spacing: 7
            })
        readonly property int height: current.height
        readonly property int padding: current.padding
        readonly property int fontSize: current.fontSize
        readonly property int spacing: current.spacing
    }

    implicitHeight: sizeTokens.height
    implicitWidth: Math.max(implicitHeight, labelRow.implicitWidth + root.paddingLeft + root.paddingRight)
    activeFocusOnTab: true
    opacity: root.enabled ? 1 : 0.45

    Accessible.role: Accessible.Button
    Accessible.name: root.accessibleName
    Accessible.description: root.text

    FontLoader {
        id: iconFont
        source: root.theme ? root.theme.iconSource() : "qrc:/cscui/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

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
        color: {
            if (!root.backgroundVisible)
                return "transparent";
            if (pointer.pressed)
                return theme ? theme.pressedColor : "#D1D1D6";
            if (pointer.containsMouse || root.activeFocus)
                return root.hoverColor;
            return root.containerColor;
        }
        border.width: root.activeFocus ? 2 : 0
        border.color: theme ? theme.focusColor : "#007AFF"

        Behavior on color {
            ColorAnimation {
                duration: theme ? theme.durationFast : 120
            }
        }
        Behavior on border.width {
            NumberAnimation {
                duration: theme ? theme.durationFast : 120
            }
        }
    }

    RowLayout {
        id: labelRow
        anchors.centerIn: parent
        spacing: root.hasIcon && root.textShown ? Math.max(0, root.labelSpacing) : 0

        Text {
            id: iconLabel
            visible: root.hasIcon
            text: root.iconCharacter
            color: root.iconColor
            font.family: root.iconFontFamily
            font.pixelSize: root.iconSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Layout.preferredWidth: implicitWidth
            Layout.preferredHeight: root.iconSize + 4

            transform: Rotation {
                id: iconRotation
                origin.x: iconLabel.width / 2
                origin.y: iconLabel.height / 2
            }
        }

        Text {
            id: label
            visible: root.textShown
            text: root.text
            color: root.textColor
            font.family: theme ? theme.fontFamily : "sans-serif"
            font.pixelSize: root.fontSize
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            Layout.maximumWidth: Math.max(0, root.width - root.paddingLeft - root.paddingRight)
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: {
            root.forceActiveFocus();
            pressScale.xScale = root.pressedScale;
            pressScale.yScale = root.pressedScale;
            if (root.iconRotateOnClick)
                iconRotationAnimation.restart();
        }
        onReleased: {
            restoreScale.restart();
            if (containsMouse)
                root.clicked();
        }
        onCanceled: restoreScale.restart()
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

    PropertyAnimation {
        id: iconRotationAnimation
        target: iconRotation
        property: "angle"
        from: 0
        to: 360
        duration: theme ? theme.durationNormal : 220
        easing.type: Easing.OutCubic
        onFinished: iconRotation.angle = 0
    }

    Keys.onSpacePressed: {
        if (root.enabled) {
            event.accepted = true;
            root.clicked();
        }
    }
    Keys.onReturnPressed: {
        if (root.enabled) {
            event.accepted = true;
            root.clicked();
        }
    }
    Keys.onEnterPressed: {
        if (root.enabled) {
            event.accepted = true;
            root.clicked();
        }
    }

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "Button"
        nameZh: "按钮"
    }
}
