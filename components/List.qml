pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

// Scrollable action list. The bundled icon font makes the component portable
// instead of relying on an id declared by an embedding page.
FocusScope {
    id: root

    property var theme: null

    property var model: []
    signal itemClicked(int index, var data)

    property bool backgroundVisible: true
    property real radius: theme ? (theme.radiusLarge || 12) : 12
    property int buttonHeight: 44
    property int itemHeight: buttonHeight
    property int itemFontSize: 15
    property int itemIconSize: 16
    property int horizontalPadding: 12
    property int labelSpacing: 10
    property int buttonsSpacing: 4
    property int listPadding: horizontalPadding
    property real pressedScale: 0.98
    property bool textShown: true
    property color containerColor: theme ? theme.secondaryColor : "#FFFFFF"
    property color hoverColor: theme ? theme.hoverColor : "#E5E5EA"
    property color textColor: theme ? theme.textColor : "#1D1D1F"
    property bool shadowEnabled: true
    property color shadowColor: theme ? theme.shadowColor : "#24000000"
    property int currentIndex: -1
    property string accessibleName: theme ? theme.localized("List", "列表") : "List"

    implicitWidth: 220
    implicitHeight: 220
    activeFocusOnTab: false
    opacity: root.enabled ? 1 : 0.45

    Accessible.role: Accessible.List
    Accessible.name: root.accessibleName

    readonly property int itemCount: root.model && root.model.count !== undefined ? root.model.count : (root.model ? root.model.length : 0)

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
        var value = root.itemAt(index);
        root.itemClicked(index, {
            display: value && value.display !== undefined ? value.display : value,
            iconChar: value && value.iconChar !== undefined ? value.iconChar : ""
        });
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
        shadowBlur: theme ? theme.shadowBlur : 0.25
        shadowHorizontalOffset: theme ? theme.shadowXOffset : 0
        shadowVerticalOffset: theme ? theme.shadowYOffset : 2
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        visible: root.backgroundVisible
        radius: Math.max(0, root.radius)
        color: root.containerColor
    }

    ListView {
        id: listView
        cacheBuffer: 120
        reuseItems: true
        anchors.fill: parent
        anchors.margins: Math.max(0, root.listPadding)
        model: root.model || []
        spacing: Math.max(0, root.buttonsSpacing)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: root.currentIndex

        delegate: FocusScope {
            id: listItem
            required property int index
            width: listView.width
            height: Math.max(44, root.itemHeight)
            activeFocusOnTab: true
            property var itemValue: root.itemAt(index)
            property string itemLabel: String(itemValue && itemValue.display !== undefined ? itemValue.display : itemValue)
            property string itemIcon: String(itemValue && itemValue.iconChar !== undefined ? itemValue.iconChar : "")
            property bool hovered: itemPointer.containsMouse
            property bool selected: root.currentIndex === index

            Accessible.role: Accessible.ListItem
            Accessible.name: itemLabel
            Accessible.selected: selected

            Rectangle {
                anchors.fill: parent
                radius: Math.min(root.radius, 8)
                color: listItem.selected ? (theme ? theme.selectionColor : "#D9ECFF") : (itemPointer.pressed ? (theme ? theme.pressedColor : "#D1D1D6") : (listItem.hovered || listItem.activeFocus ? root.hoverColor : "transparent"))
                border.width: listItem.activeFocus ? 2 : 0
                border.color: theme ? theme.focusColor : "#007AFF"
                Behavior on color {
                    ColorAnimation {
                        duration: theme ? theme.durationFast : 120
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Math.max(8, root.horizontalPadding)
                anchors.rightMargin: Math.max(8, root.horizontalPadding)
                spacing: Math.max(0, root.labelSpacing)

                Text {
                    visible: listItem.itemIcon !== ""
                    text: listItem.itemIcon
                    color: listItem.selected ? (theme ? theme.focusColor : "#007AFF") : root.textColor
                    font.family: root.theme ? root.theme.iconFamily(iconFont.name) : iconFont.name
                    font.pixelSize: root.itemIconSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    Layout.preferredWidth: root.itemIconSize + 4
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.textShown
                    text: listItem.itemLabel
                    color: root.textColor
                    font.family: theme ? theme.fontFamily : "sans-serif"
                    font.pixelSize: root.itemFontSize
                    font.weight: listItem.selected ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
            }

            MouseArea {
                id: itemPointer
                anchors.fill: parent
                enabled: root.enabled
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    listItem.forceActiveFocus();
                    root.activate(listItem.index);
                }
            }

            Keys.onSpacePressed: {
                event.accepted = true;
                root.activate(listItem.index);
            }
            Keys.onReturnPressed: {
                event.accepted = true;
                root.activate(listItem.index);
            }
            Keys.onEnterPressed: {
                event.accepted = true;
                root.activate(listItem.index);
            }
        }

        ScrollBar.vertical: CscScrollBar {
            theme: root.theme
            policy: ScrollBar.AsNeeded
        }
    }

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "List"
        nameZh: "列表"
    }
}
