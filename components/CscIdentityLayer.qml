pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

// Hover name chip. Lives on Overlay.overlay so it never covers host chrome.
Item {
    id: root

    anchors.fill: parent
    property var theme: null
    property string nameEn: ""
    property string nameZh: ""
    property bool active: true

    readonly property string displayLabel: {
        if (root.theme && root.theme.isChinese && root.nameZh.length)
            return root.nameEn + " · " + root.nameZh
        return root.nameEn
    }
    readonly property bool canShow: root.active && root.nameEn.length && root.width > 28 && root.height > 28

    HoverHandler {
        id: hover
        enabled: root.canShow
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onHoveredChanged: hovered ? root.show() : chip.close()
    }

    function show() {
        if (!root.canShow || !Overlay.overlay)
            return
        chip.open()
        root.place()
    }

    function place() {
        if (!chip.opened || !Overlay.overlay)
            return
        const gap = root.theme ? root.theme.spacingSmall : 6
        const w = chip.implicitWidth
        const h = chip.implicitHeight
        // Prefer outside top-right; flip below if near window top.
        let lx = root.width - w
        let ly = -h - gap
        const top = root.mapToItem(Overlay.overlay, 0, 0).y
        if (top + ly < gap)
            ly = root.height + gap
        const p = root.mapToItem(Overlay.overlay, lx, ly)
        chip.x = Math.max(gap, Math.min(p.x, Overlay.overlay.width - w - gap))
        chip.y = Math.max(gap, Math.min(p.y, Overlay.overlay.height - h - gap))
    }

    // Track host geometry while open (scroll / resize) without per-frame work when idle.
    Timer {
        interval: 32
        repeat: true
        running: hover.hovered && chip.opened
        onTriggered: root.place()
    }

    Connections {
        target: root
        function onVisibleChanged() { if (!root.visible) chip.close() }
    }

    Popup {
        id: chip
        parent: Overlay.overlay
        modal: false
        dim: false
        focus: false
        padding: 0
        closePolicy: Popup.NoAutoClose
        implicitWidth: Math.min(Math.max(label.implicitWidth + 14, 56), 220)
        implicitHeight: 24

        enter: Transition {
            NumberAnimation {
                property: "opacity"; from: 0; to: 1
                duration: root.theme ? root.theme.durationFast : 140
                easing.type: Easing.OutCubic
            }
        }
        exit: Transition {
            NumberAnimation {
                property: "opacity"; from: 1; to: 0
                duration: root.theme ? root.theme.durationFast : 100
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            radius: root.theme ? root.theme.radiusSmall : 6
            color: root.theme ? root.theme.elevatedColor : "#FFFFFF"
            border.width: 1
            border.color: root.theme ? root.theme.focusColor : "#0066CC"
            opacity: 0.97
        }
        contentItem: Text {
            id: label
            anchors.centerIn: parent
            width: chip.implicitWidth - 12
            height: chip.implicitHeight
            text: root.displayLabel
            elide: Text.ElideRight
            color: root.theme ? root.theme.focusColor : "#0066CC"
            font.family: root.theme ? root.theme.monoFontFamily : "monospace"
            font.pixelSize: root.theme ? Math.max(11, root.theme.fontSizeCaption) : 11
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        onOpened: root.place()
    }
}
