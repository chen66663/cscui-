pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects

// A restrained pointer-responsive surface. The public rotation properties are
// retained for compatibility, while reduced-motion mode disables perspective.
FocusScope {
    id: root

    property var theme: null

    implicitWidth: 160
    implicitHeight: 230
    width: implicitWidth
    height: implicitHeight

    property real maxRotationAngle: 3.5
    property real rotationX: 0
    property real rotationY: 0
    readonly property bool isHovered: pointer.containsMouse
    readonly property bool reducedMotion: theme ? theme.reducedMotion : false
    readonly property bool highContrast: theme ? theme.highContrast : false
    readonly property bool visuallyActive: root.isHovered || root.activeFocus
    property string accessibleName: theme
                                    ? theme.localized("Hover card", "悬停卡片")
                                    : "Hover card"
    property string accessibleDescription: theme
                                           ? theme.localized("A pointer-responsive content group", "响应指针移动的内容分组")
                                           : "A pointer-responsive content group"
    default property alias content: contentItem.data

    activeFocusOnTab: true
    scale: root.activeFocus && !root.reducedMotion ? 1.01 : 1.0

    Accessible.role: Accessible.Grouping
    Accessible.name: root.accessibleName
    Accessible.description: root.accessibleDescription

    Behavior on scale {
        NumberAnimation {
            duration: root.theme ? root.theme.durationFast : 140
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: card

        anchors.fill: parent
        radius: root.theme ? root.theme.radiusLarge : 12
        color: root.theme ? root.theme.surfaceColor : "#FFFFFF"
        border.width: root.activeFocus || root.highContrast ? 2 : 1
        border.color: root.activeFocus
                      ? (root.theme ? root.theme.focusColor : "#007AFF")
                      : (root.theme ? root.theme.borderColor : "#D1D1D6")

        layer.enabled: root.visuallyActive && !root.highContrast
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.theme ? root.theme.shadowColor : "#24000000"
            shadowBlur: root.theme ? root.theme.shadowBlur : 0.25
            shadowHorizontalOffset: root.theme ? root.theme.shadowXOffset : 0
            shadowVerticalOffset: root.theme ? root.theme.shadowYOffset : 2
        }

        transform: [
            Rotation {
                origin.x: card.width / 2
                origin.y: card.height / 2
                axis.x: 0
                axis.y: 1
                axis.z: 0
                angle: root.reducedMotion ? 0 : root.rotationY

                Behavior on angle {
                    enabled: !root.isHovered
                    NumberAnimation {
                        duration: root.theme ? root.theme.durationNormal : 220
                        easing.type: Easing.OutCubic
                    }
                }
            },
            Rotation {
                origin.x: card.width / 2
                origin.y: card.height / 2
                axis.x: 1
                axis.y: 0
                axis.z: 0
                angle: root.reducedMotion ? 0 : root.rotationX

                Behavior on angle {
                    enabled: !root.isHovered
                    NumberAnimation {
                        duration: root.theme ? root.theme.durationNormal : 220
                        easing.type: Easing.OutCubic
                    }
                }
            }
        ]

        Item {
            id: contentItem

            anchors.fill: parent
            anchors.margins: root.theme ? root.theme.spacingLarge : 16
        }
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: function (mouse) {
            if (root.reducedMotion)
                return;
            const halfWidth = Math.max(1, root.width / 2);
            const halfHeight = Math.max(1, root.height / 2);
            root.rotationY = root.maxRotationAngle * (mouse.x - halfWidth) / halfWidth;
            root.rotationX = -root.maxRotationAngle * (mouse.y - halfHeight) / halfHeight;
        }
        onExited: root.resetRotation()
        onCanceled: root.resetRotation()
    }

    function resetRotation() {
        rotationX = 0;
        rotationY = 0;
    }

    onActiveFocusChanged: if (!activeFocus)
        root.resetRotation()

    Keys.onEscapePressed: function (event) {
        root.resetRotation();
        event.accepted = true;
    }

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "HoverCard"
        nameZh: "悬停卡片"
    }
}
