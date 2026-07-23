pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "." as Components

// Window-level confirmation dialog. Popup's overlay keeps the dialog centered
// in the visible viewport even when it is declared inside scrolling content.
Popup {
    id: dialogRoot

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: parent ? Math.min(420, Math.max(280, parent.width - theme.spacingXLarge * 2)) : 420
    height: parent ? Math.min(parent.height - theme.spacingXLarge * 2, implicitHeight) : implicitHeight
    padding: theme.spacingLarge
    modal: true
    focus: true
    dim: true
    closePolicy: Popup.NoAutoClose

    property alias title: titleText.text
    property alias message: messageText.text
    property string cancelText: theme ? theme.localized("Cancel", "取消") : "Cancel"
    property string confirmText: theme ? theme.localized("Continue", "继续") : "Continue"
    // Explicit injection keeps the dialog and its nested actions synchronized.
    property var theme
    property bool dismissOnOverlay: true
    property bool closeOnConfirm: true
    property bool closeOnCancel: true

    signal confirm
    signal cancel

    function reject() {
        dialogRoot.cancel();
        if (dialogRoot.closeOnCancel)
            dialogRoot.close();
    }

    onOpened: confirmButton.forceActiveFocus()

    Shortcut {
        sequence: "Escape"
        enabled: dialogRoot.opened
        onActivated: dialogRoot.reject()
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: theme.durationNormal
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                from: 0.97
                to: 1
                duration: theme.durationNormal
                easing.type: Easing.OutCubic
            }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: theme.durationFast
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                property: "scale"
                from: 1
                to: 0.98
                duration: theme.durationFast
                easing.type: Easing.InCubic
            }
        }
    }

    Overlay.modal: Rectangle {
        color: theme.isDark ? "#99000000" : "#66000000"

        MouseArea {
            anchors.fill: parent
            onClicked: if (dialogRoot.dismissOnOverlay)
                dialogRoot.reject()
        }
    }

    background: Components.BlurCard {
        theme: dialogRoot.theme
        blurSource: dialogRoot.parent
        borderRadius: theme.radiusLarge
        borderColor: theme.borderColor
    }

    contentItem: ColumnLayout {
        id: contentCol

        spacing: theme.spacingMedium
        Accessible.role: Accessible.Dialog
        Accessible.name: dialogRoot.title
        Accessible.description: dialogRoot.message

        Text {
            id: titleText

            text: theme.localized("Title", "标题")
            color: theme.textColor
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeTitle
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Text {
            id: messageText

            text: theme.localized("Message", "消息")
            color: theme.secondaryTextColor
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeBody
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            spacing: theme.spacingSmall

            Components.Button {
                theme: dialogRoot.theme
                text: dialogRoot.cancelText
                size: "s"
                accessibleName: dialogRoot.cancelText
                onClicked: dialogRoot.reject()
            }

            Components.Button {
                id: confirmButton

                theme: dialogRoot.theme
                text: dialogRoot.confirmText
                size: "s"
                containerColor: theme.focusColor
                hoverColor: Qt.lighter(theme.focusColor, 1.08)
                textColor: theme.onAccentColor
                accessibleName: dialogRoot.confirmText
                onClicked: {
                    dialogRoot.confirm();
                    if (dialogRoot.closeOnConfirm)
                        dialogRoot.close();
                }
            }
        }
    }

    CscIdentityLayer {
        parent: dialogRoot
        anchors.fill: parent
        theme: dialogRoot.theme
        nameEn: "AlertDialog"
        nameZh: "对话框"
    }
}
