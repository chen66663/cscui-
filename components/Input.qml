pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

// Single-line text input with an optional password visibility action.
FocusScope {
    id: root

    // Explicit injection keeps Bound components synchronized with the shell theme.
    property var theme

    property alias text: textField.text
    property alias placeholderText: textField.placeholderText
    property bool readOnly: false
    property bool passwordField: false
    property bool passwordVisible: false
    signal accepted

    property int fontSize: 15
    property real radius: theme ? (theme.radiusMedium || 8) : 8
    // Kept as public customization points, now backed by the bundled icon font.
    property string showPasswordSymbol: "\uf06e"
    property string hidePasswordSymbol: "\uf070"
    property bool backgroundVisible: true
    property string accessibleName: root.placeholderText
    property int horizontalPadding: 12
    property int inputMethodHints: Qt.ImhNone

    implicitWidth: 240
    implicitHeight: theme ? theme.controlHeight : 44
    activeFocusOnTab: true
    opacity: root.enabled ? 1 : 0.45

    Accessible.role: Accessible.EditableText
    Accessible.name: root.accessibleName
    Accessible.readOnly: root.readOnly
    Accessible.passwordEdit: root.passwordField

    FontLoader {
        id: iconFont
        source: root.theme ? root.theme.iconSource() : "qrc:/cscui/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: Math.max(0, root.radius)
        color: root.backgroundVisible ? (theme ? theme.secondaryColor : "#FFFFFF") : "transparent"
        border.width: textField.activeFocus || eyeAction.activeFocus ? 2 : 1
        border.color: {
            if (textField.activeFocus || eyeAction.activeFocus)
                return theme ? theme.focusColor : "#007AFF";
            return theme ? theme.borderColor : "#D1D1D6";
        }

        Behavior on border.color {
            ColorAnimation {
                duration: theme ? theme.durationFast : 120
            }
        }
        Behavior on border.width {
            NumberAnimation {
                duration: theme ? theme.durationFast : 120
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Math.max(8, root.horizontalPadding)
        anchors.rightMargin: root.passwordField ? 4 : Math.max(8, root.horizontalPadding)
        spacing: 4

        Basic.TextField {
            id: textField
            Layout.fillWidth: true
            Layout.fillHeight: true
            enabled: root.enabled
            readOnly: root.readOnly
            selectByMouse: true
            color: theme ? theme.textColor : "#1D1D1F"
            placeholderTextColor: theme ? theme.tertiaryTextColor : "#6E6E73"
            selectionColor: theme ? theme.focusColor : "#007AFF"
            selectedTextColor: theme ? theme.onAccentColor : "#FFFFFF"
            font.family: theme ? theme.fontFamily : "sans-serif"
            font.pixelSize: root.fontSize
            verticalAlignment: TextInput.AlignVCenter
            echoMode: root.passwordField ? (root.passwordVisible ? TextInput.Normal : TextInput.Password) : TextInput.Normal
            inputMethodHints: root.inputMethodHints
            background: null
            onAccepted: root.accepted()
        }

        FocusScope {
            id: eyeAction
            visible: root.passwordField
            enabled: root.enabled
            Layout.preferredWidth: 36
            Layout.fillHeight: true
            activeFocusOnTab: visible

            Accessible.role: Accessible.Button
            Accessible.name: root.passwordVisible
                             ? (theme ? theme.localized("Hide password", "隐藏密码") : "Hide password")
                             : (theme ? theme.localized("Show password", "显示密码") : "Show password")

            Rectangle {
                anchors.centerIn: parent
                width: 32
                height: 32
                radius: theme ? theme.radiusSmall : 6
                color: eyePointer.pressed ? (theme ? theme.pressedColor : "#D1D1D6") : ((eyePointer.containsMouse || eyeAction.activeFocus) ? (theme ? theme.hoverColor : "#E5E5EA") : "transparent")
                border.width: eyeAction.activeFocus ? 2 : 0
                border.color: theme ? theme.focusColor : "#007AFF"
            }

            Text {
                anchors.centerIn: parent
                text: root.passwordVisible ? root.hidePasswordSymbol : root.showPasswordSymbol
                color: theme ? theme.secondaryTextColor : "#5C5C60"
                font.family: root.theme ? root.theme.iconFamily(iconFont.name) : iconFont.name
                font.pixelSize: 14
            }

            MouseArea {
                id: eyePointer
                anchors.fill: parent
                enabled: eyeAction.enabled
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    eyeAction.forceActiveFocus();
                    root.passwordVisible = !root.passwordVisible;
                }
            }

            Keys.onSpacePressed: {
                event.accepted = true;
                root.passwordVisible = !root.passwordVisible;
            }
            Keys.onReturnPressed: {
                event.accepted = true;
                root.passwordVisible = !root.passwordVisible;
            }
        }
    }

    onActiveFocusChanged: {
        if (activeFocus && !eyeAction.activeFocus)
            textField.forceActiveFocus();
    }

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "Input"
        nameZh: "输入框"
    }
}
