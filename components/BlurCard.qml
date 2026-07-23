import QtQuick
import QtQuick.Effects

// Captures the pixels behind this item and applies a rounded material overlay.
// A solid fallback remains visible when no source item is available.
Item {
    id: root

    // Explicit injection keeps material overlays aligned with the active palette.
    property var theme

    width: 300
    height: 200

    property Item blurSource: null
    property real blurAmount: 1.0
    property bool dragable: false
    property real blurMax: 64
    property real borderRadius: theme.radiusLarge
    property color borderColor: theme.borderColor
    property real borderWidth: 1
    default property alias content: contentItem.data

    readonly property point sourcePosition: blurSource ? root.mapToItem(blurSource, 0, 0) : Qt.point(0, 0)
    readonly property real effectiveRadius: Math.max(0, Math.min(borderRadius, Math.min(width, height) / 2))

    ShaderEffectSource {
        id: effectSource

        anchors.fill: parent
        sourceItem: root.blurSource
        sourceRect: Qt.rect(root.sourcePosition.x, root.sourcePosition.y, root.width, root.height)
        live: root.visible
        recursive: false
        hideSource: false
        visible: false
    }

    Item {
        id: maskItem

        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: root.effectiveRadius
            color: "#FFFFFF"
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: effectSource
        visible: root.blurSource !== null && root.blurAmount > 0
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: Math.max(0, root.blurMax)
        blur: Math.max(0, Math.min(1, root.blurAmount))
        maskEnabled: true
        maskSource: maskItem
    }

    Rectangle {
        anchors.fill: parent
        radius: root.effectiveRadius
        color: theme.blurOverlayColor
        border.color: root.borderColor
        border.width: root.borderWidth
        z: 1
    }

    Item {
        id: contentItem

        anchors.fill: parent
        clip: true
        z: 2
    }

    DragHandler {
        enabled: root.dragable
        target: root
        acceptedButtons: Qt.LeftButton
    }

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "BlurCard"
        nameZh: "模糊卡片"
    }
}
