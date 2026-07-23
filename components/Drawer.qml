pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

// A modal right-side sheet. The root item owns the full overlay so the scrim
// can consume input even when the visual panel is narrower than the window.
FocusScope {
    id: root

    property var theme: null

    property bool backgroundVisible: true
    property color drawerColor: root.theme ? root.theme.secondaryColor : "#FFFFFF"
    property real radius: root.theme ? root.theme.radiusLarge : 12
    property real columnspacing: root.theme ? root.theme.spacingMedium : 12
    property int padding: root.theme ? root.theme.spacingLarge : 16
    property bool shadowEnabled: true
    property color shadowColor: root.theme ? root.theme.shadowColor : "#24000000"

    property bool opened: false
    property int panelWidth: 340
    property int minimumPanelWidth: 280
    property int edgeMargin: root.theme ? root.theme.spacingMedium : 12

    // closeOnOverlay is the preferred spelling used by the shell. Keep the
    // historical dismissOnOverlay name as an alias for existing consumers.
    property bool closeOnOverlay: true
    property alias dismissOnOverlay: root.closeOnOverlay
    property bool scrimVisible: true
    property color scrimColor: root.theme
                                  ? Qt.rgba(0, 0, 0, root.theme.isDark ? 0.56 : 0.42)
                                  : Qt.rgba(0, 0, 0, 0.42)
    property int openDuration: root.theme ? root.theme.durationNormal : 220
    property int closeDuration: root.theme ? root.theme.durationFast : 140
    property bool reducedMotion: root.theme ? root.theme.reducedMotion : false
    property string accessibleName: root.theme
                                    ? root.theme.localized("Side drawer", "侧边栏")
                                    : "Side drawer"

    default property alias content: contentLayout.data

    readonly property real effectivePanelWidth: {
        const available = Math.max(0, root.width);
        if (available <= root.minimumPanelWidth + root.edgeMargin)
            return available;
        return Math.min(Math.max(root.minimumPanelWidth, root.panelWidth),
                        Math.max(0, available - root.edgeMargin));
    }
    readonly property bool transitioning: root.visible
                                         && (root.opened
                                             ? panelTranslation.x > 0.5
                                             : panelTranslation.x < root.effectivePanelWidth - 0.5)

    property bool _componentReady: false

    implicitWidth: root.panelWidth
    implicitHeight: 600
    width: parent ? parent.width : 960
    height: parent ? parent.height : implicitHeight
    // Stay present for the exit transition so the scrim and input blocker do
    // not disappear before the panel has reached its resting position.
    visible: root.opened
             || panelTranslation.x < root.effectivePanelWidth - 0.5
             || scrim.opacity > 0.01
    focus: root.opened
    clip: true

    Accessible.role: Accessible.Pane
    Accessible.name: root.accessibleName
    Accessible.description: root.opened
                           ? (root.theme ? root.theme.localized("Open", "已打开") : "Open")
                           : (root.theme ? root.theme.localized("Closed", "已关闭") : "Closed")

    function open() {
        root.opened = true;
    }

    function close() {
        root.opened = false;
    }

    function toggle() {
        root.opened = !root.opened;
    }

    Rectangle {
        id: scrim
        anchors.fill: parent
        z: 0
        color: root.scrimColor
        visible: root.visible
        opacity: root.scrimVisible && root.opened ? 1 : 0

        Behavior on opacity {
            enabled: root._componentReady && !root.reducedMotion

            NumberAnimation {
                duration: root.opened ? root.openDuration : root.closeDuration
                easing.type: root.opened ? Easing.OutCubic : Easing.InCubic
            }
        }

        // The hit area remains enabled even when scrimVisible is false. This
        // keeps the drawer modal and prevents clicks leaking to the workspace.
        MouseArea {
            anchors.fill: parent
            enabled: root.visible
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
            preventStealing: true
            // Keep the pointer visible when the scrim is intentionally
            // non-dismissible; a blank cursor makes the modal state feel like
            // an input failure rather than a deliberate interaction choice.
            cursorShape: Qt.ArrowCursor

            onClicked: if (root.closeOnOverlay)
                root.close()
            onWheel: wheel.accepted = true
        }
    }

    Item {
        id: panel
        anchors.right: parent.right
        y: 0
        width: root.effectivePanelWidth
        height: root.height
        z: 1
        clip: true

        transform: Translate {
            id: panelTranslation
            x: root.opened ? 0 : root.effectivePanelWidth

            Behavior on x {
                enabled: root._componentReady && root.visible && !root.reducedMotion

                NumberAnimation {
                    duration: root.opened ? root.openDuration : root.closeDuration
                    easing.type: root.opened ? Easing.OutCubic : Easing.InCubic
                }
            }
        }

        MultiEffect {
            anchors.fill: background
            source: background
            visible: root.shadowEnabled && root.backgroundVisible
            shadowEnabled: true
            shadowColor: root.shadowColor
            shadowBlur: root.theme ? root.theme.shadowBlur : 0.32
            shadowVerticalOffset: root.theme ? root.theme.shadowYOffset : 4
            shadowHorizontalOffset: root.theme ? root.theme.shadowXOffset : 0
        }

        Rectangle {
            id: background
            anchors.fill: parent
            radius: root.radius
            color: root.drawerColor
            visible: root.backgroundVisible
            border.width: root.theme ? 1 : 0
            border.color: root.theme ? root.theme.borderColor : "transparent"
        }

        // Consume blank-panel input while allowing content children above this
        // layer to receive their own pointer and keyboard events.
        MouseArea {
            anchors.fill: parent
            z: 0.5
            enabled: root.visible
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
            preventStealing: true
            onWheel: wheel.accepted = true
        }

        ColumnLayout {
            id: contentLayout
            anchors.fill: parent
            anchors.margins: root.padding
            spacing: root.columnspacing
            z: 1
        }
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: root.visible && root.opened
        onActivated: root.close()
    }

    onOpenedChanged: {
        if (root.opened)
            Qt.callLater(function() { root.forceActiveFocus(); });
    }

    Component.onCompleted: {
        root._componentReady = true;
        if (root.opened)
            Qt.callLater(function() { root.forceActiveFocus(); });
    }

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "Drawer"
        nameZh: "侧栏"
    }
}
