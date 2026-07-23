pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

// Multi-selection group. selectedIndices is copied before mutation so external
// bindings receive a new value and selectionChanged always carries a snapshot.
FocusScope {
    id: root

    // Explicit injection keeps Bound components synchronized with the shell theme.
    property var theme

    property var model: []
    property var selectedIndices: []
    signal selectionChanged(var selectedIndices, var selectedData)

    property bool backgroundVisible: true
    property real radius: theme ? (theme.radiusMedium || 8) : 8
    property int fontSize: 15
    property color containerColor: theme ? theme.secondaryColor : "#FFFFFF"
    property color hoverColor: theme ? theme.hoverColor : "#E5E5EA"
    property color textColor: theme ? theme.textColor : "#1D1D1F"
    property color checkmarkColor: theme ? theme.focusColor : "#007AFF"
    property real pressedScale: 0.98
    property bool shadowEnabled: true
    property color shadowColor: theme ? theme.shadowColor : "#24000000"
    property int horizontalPadding: 12
    property int boxSize: 20
    property int labelSpacing: 10
    property int buttonsSpacing: 4
    property int buttonHeight: 44
    property real maxTextWidth: 0
    property string accessibleName: theme ? theme.localized("Options", "选项") : "Options"

    readonly property int itemCount: root.model && root.model.count !== undefined ? root.model.count : (root.model ? root.model.length : 0)

    implicitWidth: Math.max(180, root.horizontalPadding * 2 + root.boxSize + root.labelSpacing + root.maxTextWidth + 16)
    implicitHeight: Math.max(theme ? theme.controlHeight : 44, root.itemCount * root.buttonHeight + Math.max(0, root.itemCount - 1) * Math.max(0, root.buttonsSpacing) + root.horizontalPadding * 2)
    activeFocusOnTab: false
    opacity: root.enabled ? 1 : 0.45

    Accessible.role: Accessible.Grouping
    Accessible.name: root.accessibleName

    function itemAt(index) {
        if (!root.model || index < 0 || index >= root.itemCount)
            return ({
                    text: ""
                });
        if (root.model.get !== undefined)
            return root.model.get(index);
        return root.model[index];
    }

    function updateMaxTextWidth() {
        var widest = 0;
        for (var i = 0; i < root.itemCount; ++i) {
            measureText.text = String(root.itemAt(i).text !== undefined ? root.itemAt(i).text : root.itemAt(i));
            widest = Math.max(widest, measureText.width);
        }
        root.maxTextWidth = widest;
    }

    function selectedData() {
        var data = [];
        for (var i = 0; i < root.selectedIndices.length; ++i)
            data.push(root.itemAt(root.selectedIndices[i]));
        return data;
    }

    function toggleIndex(index) {
        if (!root.enabled)
            return;
        var next = root.selectedIndices ? root.selectedIndices.slice() : [];
        var at = next.indexOf(index);
        if (at >= 0)
            next.splice(at, 1);
        else
            next.push(index);
        root.selectedIndices = next;
        root.selectionChanged(next, root.selectedData());
    }

    TextMetrics {
        id: measureText
        font.family: theme ? theme.fontFamily : "sans-serif"
        font.pixelSize: root.fontSize
    }

    Component.onCompleted: root.updateMaxTextWidth()
    onModelChanged: root.updateMaxTextWidth()

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
        color: root.containerColor
    }

    Column {
        id: optionColumn
        anchors.fill: parent
        anchors.margins: Math.max(0, root.horizontalPadding)
        spacing: Math.max(0, root.buttonsSpacing)

        Repeater {
            model: root.model || []

            delegate: FocusScope {
                id: option
                required property int index
                width: optionColumn.width
                height: Math.max(44, root.buttonHeight)
                activeFocusOnTab: true
                property var itemValue: root.itemAt(index)
                property bool checked: root.selectedIndices.indexOf(index) >= 0
                property bool hovered: optionPointer.containsMouse

                Accessible.role: Accessible.CheckBox
                Accessible.name: String(itemValue && itemValue.text !== undefined ? itemValue.text : itemValue)
                Accessible.checkable: true
                Accessible.checked: checked

                Rectangle {
                    anchors.fill: parent
                    radius: Math.min(root.radius, 8)
                    color: !root.backgroundVisible ? "transparent" : (optionPointer.pressed ? (theme ? theme.pressedColor : "#D1D1D6") : (option.hovered || option.activeFocus ? root.hoverColor : "transparent"))
                    border.width: option.activeFocus ? 2 : 0
                    border.color: theme ? theme.focusColor : "#007AFF"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Math.max(8, root.horizontalPadding)
                    anchors.rightMargin: Math.max(8, root.horizontalPadding)
                    spacing: Math.max(0, root.labelSpacing)

                    Rectangle {
                        Layout.preferredWidth: root.boxSize
                        Layout.preferredHeight: root.boxSize
                        radius: Math.min(6, root.boxSize * 0.25)
                        color: option.checked ? root.checkmarkColor : "transparent"
                        border.width: option.checked ? 0 : 2
                        border.color: root.checkmarkColor

                        Text {
                            anchors.centerIn: parent
                            text: "\uf00c"
                            visible: option.checked
                            color: theme ? theme.contrastTextColor(root.checkmarkColor) : "#FFFFFF"
                            font.family: root.theme ? root.theme.iconFamily(iconFont.name) : iconFont.name
                            font.pixelSize: Math.max(11, root.boxSize * 0.65)
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: String(option.itemValue && option.itemValue.text !== undefined ? option.itemValue.text : option.itemValue)
                        color: root.textColor
                        font.family: theme ? theme.fontFamily : "sans-serif"
                        font.pixelSize: root.fontSize
                        font.weight: option.checked ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                MouseArea {
                    id: optionPointer
                    anchors.fill: parent
                    enabled: root.enabled
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        option.forceActiveFocus();
                        root.toggleIndex(option.index);
                    }
                }

                Keys.onSpacePressed: {
                    event.accepted = true;
                    root.toggleIndex(option.index);
                }
                Keys.onReturnPressed: {
                    event.accepted = true;
                    root.toggleIndex(option.index);
                }
                Keys.onEnterPressed: {
                    event.accepted = true;
                    root.toggleIndex(option.index);
                }
            }
        }
    }

    FontLoader {
        id: iconFont
        source: root.theme ? root.theme.iconSource() : "qrc:/cscui/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "CheckBox"
        nameZh: "复选框"
    }
}
