pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

// Combo box with keyboard navigation. The menu is reparented to the window
// overlay so scroll views and clipped catalogue sections cannot crop it.
FocusScope {
    id: root

    // Explicit injection keeps Bound components synchronized with the shell theme.
    property var theme

    property string title: theme ? theme.localized("Select", "请选择") : "Select"
    property alias opened: popup.opened
    property var model: []
    property int selectedIndex: -1
    signal selectionChanged(int index, var item)

    property bool backgroundVisible: true
    property real radius: theme ? (theme.radiusMedium || 8) : 8
    property color containerColor: theme ? theme.secondaryColor : "#FFFFFF"
    property color textColor: theme ? theme.textColor : "#1D1D1F"
    property color shadowColor: theme ? theme.shadowColor : "#24000000"
    property bool shadowEnabled: true
    property int fontSize: 15
    property color hoverColor: theme ? theme.hoverColor : "#E5E5EA"
    property int headerHeight: 44
    property int itemHeight: 44
    property int popupMaxHeight: 300
    property int horizontalPadding: 12
    property real pressedScale: 0.98
    property int popupSpacing: 6
    property int popupEnterDuration: 180
    property int popupExitDuration: 140
    property real popupSlideOffset: -8
    property real popupScaleFrom: 0.98
    property int popupDirection: -1 // -1 auto, 0 down, 1 up
    property int highlightedIndex: -1
    property string accessibleName: root.title

    readonly property int itemCount: root.model && root.model.count !== undefined ? root.model.count : (root.model ? root.model.length : 0)

    width: 220
    implicitWidth: 220
    implicitHeight: root.headerHeight
    activeFocusOnTab: true
    opacity: root.enabled ? 1 : 0.45

    Accessible.role: Accessible.ComboBox
    Accessible.name: root.accessibleName
    Accessible.description: root.opened
                            ? (theme ? theme.localized("Open", "已展开") : "Open")
                            : (theme ? theme.localized("Closed", "已收起") : "Closed")

    function itemAt(index) {
        if (!root.model || index < 0 || index >= root.itemCount)
            return ({
                    text: ""
                });
        if (root.model.get !== undefined)
            return root.model.get(index);
        return root.model[index];
    }

    function itemText(item) {
        return String(item && item.text !== undefined ? item.text : item);
    }

    function toggleOpen() {
        if (!root.enabled)
            return;
        if (popup.opened) {
            popup.close();
        } else {
            root.highlightedIndex = root.selectedIndex >= 0 ? root.selectedIndex : (root.itemCount > 0 ? 0 : -1);
            popup.open();
        }
    }

    function choose(index) {
        if (!root.enabled || index < 0 || index >= root.itemCount)
            return;
        root.selectedIndex = index;
        root.highlightedIndex = index;
        popup.close();
        root.selectionChanged(index, root.itemAt(index));
    }

    function moveHighlight(delta) {
        if (root.itemCount <= 0)
            return;
        var start = root.highlightedIndex >= 0 ? root.highlightedIndex : 0;
        root.highlightedIndex = (start + delta + root.itemCount) % root.itemCount;
    }

    onModelChanged: {
        if (root.selectedIndex >= root.itemCount)
            root.selectedIndex = -1;
        if (root.highlightedIndex >= root.itemCount)
            root.highlightedIndex = root.selectedIndex;
    }

    FontLoader {
        id: iconFont
        source: root.theme ? root.theme.iconSource() : "qrc:/cscui/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    MultiEffect {
        source: headerSurface
        anchors.fill: headerSurface
        visible: root.backgroundVisible && root.shadowEnabled
        shadowEnabled: visible
        shadowColor: root.shadowColor
        shadowBlur: theme ? theme.shadowBlur : 0.25
        shadowHorizontalOffset: theme ? theme.shadowXOffset : 0
        shadowVerticalOffset: theme ? theme.shadowYOffset : 2
    }

    Rectangle {
        id: headerSurface
        z: 2
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.headerHeight
        radius: Math.max(0, root.radius)
        visible: root.backgroundVisible
        color: headerPointer.pressed ? (theme ? theme.pressedColor : "#D1D1D6") : ((headerPointer.containsMouse || root.activeFocus) ? root.hoverColor : root.containerColor)
        border.width: root.activeFocus ? 2 : 1
        border.color: root.activeFocus ? (theme ? theme.focusColor : "#007AFF") : (theme ? theme.borderColor : "#D1D1D6")
        Behavior on color {
            ColorAnimation {
                duration: theme ? theme.durationFast : 120
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Math.max(8, root.horizontalPadding)
            anchors.rightMargin: Math.max(8, root.horizontalPadding)
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: root.selectedIndex >= 0 ? root.itemText(root.itemAt(root.selectedIndex)) : root.title
                color: root.textColor
                font.family: theme ? theme.fontFamily : "sans-serif"
                font.pixelSize: root.fontSize
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                text: "\uf078"
                color: theme ? theme.focusColor : "#007AFF"
                font.family: root.theme ? root.theme.iconFamily(iconFont.name) : iconFont.name
                font.pixelSize: 13
                rotation: root.opened ? (popup.effectiveDirection === 1 ? 0 : 180) : 0
                Behavior on rotation {
                    NumberAnimation {
                        duration: theme ? theme.durationFast : 120
                    }
                }
            }
        }

        MouseArea {
            id: headerPointer
            anchors.fill: parent
            enabled: root.enabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                root.forceActiveFocus();
                root.toggleOpen();
            }
        }
    }

    Popup {
        id: popup
        parent: Overlay.overlay
        popupType: Popup.Item
        modal: false
        focus: true
        padding: 4
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        property int effectiveDirection: 0
        width: root.width
        height: Math.min(root.popupMaxHeight,
                         Math.max(root.itemHeight + padding * 2,
                                  popupList.contentHeight + padding * 2))

        function reposition() {
            if (!popup.parent)
                return;
            const origin = root.mapToItem(popup.parent, 0, 0);
            const availableBelow = popup.parent.height - origin.y - root.headerHeight - root.popupSpacing;
            const availableAbove = origin.y - root.popupSpacing;
            const direction = root.popupDirection >= 0
                              ? root.popupDirection
                              : (availableBelow >= popup.height || availableBelow >= availableAbove ? 0 : 1);
            popup.effectiveDirection = direction;
            popup.x = Math.max(0, Math.min(popup.parent.width - popup.width, origin.x));
            popup.y = direction === 1
                    ? Math.max(0, origin.y - popup.height - root.popupSpacing)
                    : Math.min(Math.max(0, popup.parent.height - popup.height),
                               origin.y + root.headerHeight + root.popupSpacing);
        }

        onOpened: reposition()
        onHeightChanged: if (opened) reposition()
        onClosed: root.forceActiveFocus()

        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: theme && theme.reducedMotion ? 0 : root.popupEnterDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                from: root.popupScaleFrom
                to: 1
                duration: theme && theme.reducedMotion ? 0 : root.popupEnterDuration
                easing.type: Easing.OutCubic
            }
        }
        exit: Transition {
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: theme && theme.reducedMotion ? 0 : root.popupExitDuration
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                property: "scale"
                to: root.popupScaleFrom
                duration: theme && theme.reducedMotion ? 0 : root.popupExitDuration
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            radius: Math.max(0, root.radius)
            color: root.containerColor
            border.width: 1
            border.color: theme ? theme.borderColor : "#D1D1D6"
            clip: true
        }

        contentItem: ListView {
        cacheBuffer: 120
        reuseItems: true
            id: popupList
            clip: true
            model: root.model || []
            spacing: 2
            currentIndex: root.highlightedIndex

            delegate: FocusScope {
                id: popupItem
                required property int index
                width: popupList.width
                height: Math.max(44, root.itemHeight)
                activeFocusOnTab: true
                property var itemValue: root.itemAt(index)
                property bool selected: root.selectedIndex === index
                property bool highlighted: root.highlightedIndex === index

                Accessible.role: Accessible.ListItem
                Accessible.name: root.itemText(itemValue)
                Accessible.selected: selected

                Rectangle {
                    anchors.fill: parent
                    radius: Math.min(root.radius, 8)
                    color: popupItem.highlighted || popupItem.selected ? root.hoverColor : "transparent"
                    border.width: popupItem.activeFocus ? 2 : 0
                    border.color: theme ? theme.focusColor : "#007AFF"
                }

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: root.horizontalPadding
                    anchors.rightMargin: root.horizontalPadding
                    text: root.itemText(popupItem.itemValue)
                    color: root.textColor
                    font.family: theme ? theme.fontFamily : "sans-serif"
                    font.pixelSize: root.fontSize
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.enabled
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onEntered: root.highlightedIndex = popupItem.index
                    onClicked: {
                        popupItem.forceActiveFocus();
                        root.choose(popupItem.index);
                    }
                }

                Keys.onSpacePressed: {
                    event.accepted = true;
                    root.choose(popupItem.index);
                }
                Keys.onReturnPressed: {
                    event.accepted = true;
                    root.choose(popupItem.index);
                }
                Keys.onEnterPressed: {
                    event.accepted = true;
                    root.choose(popupItem.index);
                }
            }

            ScrollBar.vertical: CscScrollBar {
                theme: root.theme
                policy: ScrollBar.AsNeeded
            }
        }
    }

    Keys.onSpacePressed: {
        event.accepted = true;
        if (root.opened)
            root.choose(root.highlightedIndex);
        else
            root.toggleOpen();
    }
    Keys.onReturnPressed: {
        event.accepted = true;
        if (root.opened)
            root.choose(root.highlightedIndex);
        else
            root.toggleOpen();
    }
    Keys.onEnterPressed: {
        event.accepted = true;
        if (root.opened)
            root.choose(root.highlightedIndex);
        else
            root.toggleOpen();
    }
    Keys.onDownPressed: {
        event.accepted = true;
        if (!root.opened)
            root.toggleOpen();
        else
            root.moveHighlight(1);
    }
    Keys.onUpPressed: {
        event.accepted = true;
        if (!root.opened)
            root.toggleOpen();
        else
            root.moveHighlight(-1);
    }
    Keys.onEscapePressed: {
        if (root.opened) {
            event.accepted = true;
            popup.close();
        }
    }

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "Dropdown"
        nameZh: "下拉框"
    }
}
