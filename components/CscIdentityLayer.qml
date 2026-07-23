pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

// Hover name chip on Overlay. Never covers host content; refuses invalid
// coordinates so it cannot stick to the window top-left.
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
    readonly property bool canShow: root.active
                                   && root.visible
                                   && root.nameEn.length > 0
                                   && root.width >= 48
                                   && root.height >= 32

    HoverHandler {
        id: hover
        enabled: root.canShow
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onHoveredChanged: {
            if (hovered)
                showTimer.restart()
            else {
                showTimer.stop()
                chip.close()
            }
        }
    }

    // Small delay avoids flicker when the pointer crosses dense control rows.
    Timer {
        id: showTimer
        interval: 280
        repeat: false
        onTriggered: root.show()
    }

    Timer {
        id: followTimer
        interval: 32
        repeat: true
        running: hover.hovered && chip.opened
        onTriggered: root.place()
    }

    function show() {
        if (!hover.hovered || !root.canShow)
            return
        const overlay = Overlay.overlay
        if (!overlay || overlay.width < 32 || overlay.height < 32)
            return
        chip.open()
        // Place after Popup has a real size in the overlay.
        Qt.callLater(root.place)
        Qt.callLater(root.place)
    }

    function place() {
        if (!chip.opened)
            return
        const overlay = Overlay.overlay
        if (!overlay || overlay.width < 32 || overlay.height < 32)
            return

        // Host must still be on-screen with a real size.
        if (!root.visible || root.width < 48 || root.height < 32) {
            chip.close()
            return
        }

        const gap = root.theme ? root.theme.spacingSmall : 6
        const w = Math.max(chip.implicitWidth, 56)
        const h = Math.max(chip.implicitHeight, 24)

        // Map host top-right into overlay space.
        const topLeft = root.mapToItem(overlay, 0, 0)
        if (!isFinite(topLeft.x) || !isFinite(topLeft.y)) {
            chip.close()
            return
        }

        // Prefer outside the host, just above its top-right.
        let x = topLeft.x + root.width - w
        let y = topLeft.y - h - gap
        if (y < gap)
            y = topLeft.y + root.height + gap

        // Reject degenerate placements (would look like "stuck" at 0,0).
        if (x < -w || y < -h || x > overlay.width || y > overlay.height) {
            chip.close()
            return
        }

        x = Math.max(gap, Math.min(x, overlay.width - w - gap))
        y = Math.max(gap, Math.min(y, overlay.height - h - gap))

        // If clamping dragged the chip far from the host, hide instead of lying.
        const hostCx = topLeft.x + root.width * 0.5
        const hostCy = topLeft.y + root.height * 0.5
        const chipCx = x + w * 0.5
        const chipCy = y + h * 0.5
        const dx = chipCx - hostCx
        const dy = chipCy - hostCy
        if ((dx * dx + dy * dy) > (420 * 420)) {
            chip.close()
            return
        }

        chip.x = x
        chip.y = y
    }

    Connections {
        target: root
        function onVisibleChanged() {
            if (!root.visible)
                chip.close()
        }
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
                property: "opacity"
                from: 0
                to: 1
                duration: root.theme ? root.theme.durationFast : 140
                easing.type: Easing.OutCubic
            }
        }
        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
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
    }
}
