pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

FocusScope {
    id: root

    required property var theme
    property string iconCharacter: ""
    property string accessibleName: ""
    property string toolTip: accessibleName
    property bool checked: false
    property bool checkable: false
    property bool flat: true
    property int iconSize: 16
    property color foregroundColor: checked ? root.theme.focusColor : root.theme.textColor
    property color backgroundColor: checked ? root.theme.selectionColor : root.theme.tertiaryColor
    signal clicked

    implicitWidth: root.theme.touchTarget
    implicitHeight: root.theme.touchTarget
    activeFocusOnTab: true
    objectName: accessibleName
    opacity: enabled ? 1 : 0.45

    Accessible.role: checkable || checked ? Accessible.CheckBox : Accessible.Button
    Accessible.name: accessibleName
    Accessible.checkable: checkable || checked
    Accessible.checked: checked

    function trigger() {
        if (enabled)
            clicked();
    }

    FontLoader {
        id: iconFont
        source: root.theme ? root.theme.iconSource() : "qrc:/cscui/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: root.theme.spacingXs
        radius: root.theme.radiusMedium
        color: {
            if (pointer.pressed)
                return root.theme.pressedColor;
            if (pointer.containsMouse || root.activeFocus)
                return root.theme.hoverColor;
            return root.flat && !root.checked ? "transparent" : root.backgroundColor;
        }
        border.width: root.activeFocus ? 2 : 0
        border.color: root.theme.focusColor

        Behavior on color {
            ColorAnimation {
                duration: root.theme.durationFast
                easing.type: Easing.OutCubic
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.iconCharacter
        color: root.foregroundColor
        font.family: root.theme
                         ? root.theme.iconFamily(iconFont.status === FontLoader.Ready ? iconFont.name : root.theme.fontFamily)
                         : (iconFont.status === FontLoader.Ready ? iconFont.name : "sans-serif")
        font.pixelSize: root.iconSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.trigger()
    }

    Keys.onSpacePressed: root.trigger()
    Keys.onReturnPressed: root.trigger()
    Keys.onEnterPressed: root.trigger()

    ToolTip.visible: pointer.containsMouse && root.toolTip.length > 0
    ToolTip.text: root.toolTip
    ToolTip.delay: 500
}
