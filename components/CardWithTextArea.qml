pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: root

    property var theme: null
    property bool backgroundVisible: true
    property color cardColor: theme ? theme.secondaryColor : "#FFFFFF"
    property real radius: theme ? theme.radiusLarge : 12
    property int padding: theme ? theme.spacingLarge : 16
    property string accessibleName: theme
                                    ? theme.localized("Card text editor", "卡片文本编辑器")
                                    : "Card text editor"
    property string accessibleDescription: theme
                                           ? theme.localized("Enter or edit multi-line content", "输入或编辑多行内容")
                                           : "Enter or edit multi-line content"

    property bool shadowEnabled: true
    property color shadowColor: theme ? theme.shadowColor : "#24000000"

    property alias text: textArea.text
    property alias placeholderText: textArea.placeholderText
    property alias readOnly: textArea.readOnly

    default property alias content: contentLayout.data

    readonly property real effectivePadding: Math.min(
                                                 Math.max(0, root.padding),
                                                 Math.max(0, Math.min(root.width, root.height) / 4))

    implicitWidth: 300
    implicitHeight: 200
    width: implicitWidth
    height: implicitHeight
    clip: true

    // === 阴影效果 ===
    MultiEffect {
        source: background
        anchors.fill: background
        visible: root.shadowEnabled && root.backgroundVisible
        shadowEnabled: true
        shadowColor: root.shadowColor
        shadowBlur: root.theme ? root.theme.shadowBlur : 0.25
        shadowVerticalOffset: root.theme ? root.theme.shadowYOffset : 2
        shadowHorizontalOffset: root.theme ? root.theme.shadowXOffset : 0
    }

    // === 卡片背景 ===
    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.radius
        color: root.cardColor
        visible: root.backgroundVisible
        border.width: textArea.activeFocus || (root.theme && root.theme.highContrast) ? 2 : 1
        border.color: textArea.activeFocus
                      ? (root.theme ? root.theme.focusColor : "#007AFF")
                      : (root.theme ? root.theme.borderColor : "#D1D1D6")

        Behavior on border.color {
            ColorAnimation {
                duration: root.theme ? root.theme.durationFast : 140
            }
        }
    }

    // === 内容布局 ===
    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: root.effectivePadding
        spacing: root.theme ? root.theme.spacingSmall : 8

        Flickable {
            id: textScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            clip: true
            contentWidth: width
            contentHeight: Math.max(height, textArea.implicitHeight)
            boundsBehavior: Flickable.StopAtBounds
            interactive: true

            TextArea {
                id: textArea
                width: textScroll.width
                height: Math.max(textScroll.height, implicitHeight)
                wrapMode: Text.Wrap
                font.pixelSize: 16
                font.family: root.theme ? root.theme.fontFamily : "sans-serif"
                placeholderText: root.theme
                                 ? root.theme.localized("Enter content", "请输入内容")
                                 : "Enter content"
                palette.placeholderText: root.theme
                                         ? root.theme.tertiaryTextColor
                                         : "#6E6E73"
                background: null
                color: root.theme ? root.theme.textColor : "#1D1D1F"
                selectByMouse: true
                activeFocusOnTab: true

                Accessible.role: Accessible.EditableText
                Accessible.name: root.accessibleName
                Accessible.description: root.accessibleDescription
                Accessible.readOnly: textArea.readOnly

                onTextChanged: {
                    if (activeFocus && cursorPosition >= length)
                        textScroll.contentY = Math.max(0, textScroll.contentHeight - textScroll.height)
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }
    }

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "CardWithTextArea"
        nameZh: "文本卡片"
    }
}
