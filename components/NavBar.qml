pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

// Horizontal navigation group. Icons use the bundled Font Awesome asset so the
// component no longer depends on a page-level iconFont id.
FocusScope {
    id: root

    property var theme: null

    property var model: []
    property int currentIndex: -1
    signal itemClicked(int index, var modelData)

    property real radius: theme ? (theme.radiusLarge || 12) : 12
    property int itemHeight: 44
    property int itemFontSize: 14
    property int itemIconSize: 15
    property int itemSpacing: 4
    property int horizontalPadding: 6
    property real pressedScale: 0.98
    property bool backgroundVisible: true
    property bool shadowEnabled: true
    property color shadowColor: theme ? theme.shadowColor : "#24000000"
    property real shadowBlur: theme ? theme.shadowBlur : 0.25
    property real shadowHorizontalOffset: theme ? theme.shadowXOffset : 0
    property real shadowVerticalOffset: theme ? theme.shadowYOffset : 2
    property int itemWidth: 112
    property string accessibleName: theme ? theme.localized("Navigation", "导航") : "Navigation"

    readonly property int itemCount: root.model && root.model.count !== undefined ? root.model.count : (root.model ? root.model.length : 0)

    implicitWidth: root.horizontalPadding * 2 + root.itemCount * root.itemWidth + Math.max(0, root.itemCount - 1) * Math.max(0, root.itemSpacing)
    implicitHeight: Math.max(44, root.itemHeight) + root.horizontalPadding * 2
    activeFocusOnTab: false
    opacity: root.enabled ? 1 : 0.45

    Accessible.role: Accessible.PageTabList
    Accessible.name: root.accessibleName

    function itemAt(index) {
        if (!root.model || index < 0 || index >= root.itemCount)
            return ({
                    display: "",
                    iconChar: ""
                });
        if (root.model.get !== undefined)
            return root.model.get(index);
        return root.model[index];
    }

    function activate(index) {
        if (!root.enabled || index < 0 || index >= root.itemCount)
            return;
        root.currentIndex = index;
        root.itemClicked(index, root.itemAt(index));
    }

    function moveSelection(delta) {
        if (root.itemCount <= 0)
            return;
        var start = root.currentIndex >= 0 ? root.currentIndex : 0;
        root.activate((start + delta + root.itemCount) % root.itemCount);
    }

    FontLoader {
        id: iconFont
        source: root.theme ? root.theme.iconSource() : "qrc:/cscui/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    MultiEffect {
        source: surface
        anchors.fill: surface
        visible: root.backgroundVisible && root.shadowEnabled
        shadowEnabled: visible
        shadowColor: root.shadowColor
        shadowBlur: root.shadowBlur
        shadowHorizontalOffset: root.shadowHorizontalOffset
        shadowVerticalOffset: root.shadowVerticalOffset
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        visible: root.backgroundVisible
        radius: Math.max(0, root.radius)
        color: theme ? theme.secondaryColor : "#FFFFFF"
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Math.max(0, root.horizontalPadding)
        spacing: Math.max(0, root.itemSpacing)

        Repeater {
            model: root.model || []

            delegate: FocusScope {
                id: navItem
                required property int index
                Layout.preferredWidth: root.itemWidth
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(44, root.itemHeight)
                activeFocusOnTab: true
                property var itemValue: root.itemAt(index)
                property string itemLabel: String(itemValue && itemValue.display !== undefined ? itemValue.display : itemValue)
                property string itemIcon: String(itemValue && itemValue.iconChar !== undefined ? itemValue.iconChar : "")
                property bool selected: root.currentIndex === index
                property bool hovered: navPointer.containsMouse

                Accessible.role: Accessible.PageTab
                Accessible.name: itemLabel
                Accessible.selected: selected

                Rectangle {
                    anchors.fill: parent
                    radius: Math.min(root.radius, 8)
                    color: navItem.selected ? (theme ? theme.selectionColor : "#D9ECFF") : (navPointer.pressed ? (theme ? theme.pressedColor : "#D1D1D6") : (navItem.hovered || navItem.activeFocus ? (theme ? theme.hoverColor : "#E5E5EA") : "transparent"))
                    border.width: navItem.activeFocus ? 2 : 0
                    border.color: theme ? theme.focusColor : "#007AFF"
                    Behavior on color {
                        ColorAnimation {
                            duration: theme ? theme.durationFast : 120
                        }
                    }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 7

                    Text {
                        visible: navItem.itemIcon !== ""
                        text: navItem.itemIcon
                        color: navItem.selected ? (theme ? theme.focusColor : "#007AFF") : (theme ? theme.secondaryTextColor : "#5C5C60")
                        font.family: root.theme ? root.theme.iconFamily(iconFont.name) : iconFont.name
                        font.pixelSize: root.itemIconSize
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        text: navItem.itemLabel
                        color: navItem.selected ? (theme ? theme.focusColor : "#007AFF") : (theme ? theme.textColor : "#1D1D1F")
                        font.family: theme ? theme.fontFamily : "sans-serif"
                        font.pixelSize: root.itemFontSize
                        font.weight: navItem.selected ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                        Layout.maximumWidth: Math.max(0, root.itemWidth - root.itemIconSize - 28)
                    }
                }

                MouseArea {
                    id: navPointer
                    anchors.fill: parent
                    enabled: root.enabled
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        navItem.forceActiveFocus();
                        root.activate(navItem.index);
                    }
                }

                Keys.onSpacePressed: {
                    event.accepted = true;
                    root.activate(navItem.index);
                }
                Keys.onReturnPressed: {
                    event.accepted = true;
                    root.activate(navItem.index);
                }
                Keys.onEnterPressed: {
                    event.accepted = true;
                    root.activate(navItem.index);
                }
                Keys.onLeftPressed: {
                    event.accepted = true;
                    root.moveSelection(-1);
                }
                Keys.onRightPressed: {
                    event.accepted = true;
                    root.moveSelection(1);
                }
            }
        }
    }

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "NavBar"
        nameZh: "导航栏"
    }
}
