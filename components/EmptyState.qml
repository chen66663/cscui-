pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

// Friendly empty / error placeholder with optional primary action.
Item {
    id: root

    property var theme: null
    property string title: theme ? theme.localized("Nothing here yet", "这里还没有内容") : "Nothing here yet"
    property string description: theme
        ? theme.localized("When items appear, they will show up in this space.", "有内容时会显示在这里。")
        : "When items appear, they will show up in this space."
    property string actionText: ""
    property string iconCharacter: "\uf07c"
    signal actionClicked()

    implicitWidth: 320
    implicitHeight: column.implicitHeight + (theme ? theme.spacingXLarge * 2 : 48)
    property bool entranceReady: false
    property real entranceY: 12
    opacity: root.entranceReady ? 1 : 0
    transform: Translate { y: root.entranceY }
    Behavior on opacity {
        enabled: root.theme && root.theme.motionEnabled
        NumberAnimation {
            duration: root.theme.durationNormal
            easing.type: Easing.OutCubic
        }
    }
    Behavior on entranceY {
        enabled: root.theme && root.theme.motionEnabled
        NumberAnimation {
            duration: root.theme.durationNormal
            easing.type: Easing.OutCubic
        }
    }
    Component.onCompleted: {
        if (root.theme && root.theme.motionEnabled) {
            root.entranceY = 12
            root.entranceReady = false
            Qt.callLater(function () {
                root.entranceY = 0
                root.entranceReady = true
            })
        } else {
            root.entranceY = 0
            root.entranceReady = true
        }
    }
    Accessible.role: Accessible.Pane
    Accessible.name: root.title
    Accessible.description: root.description

    ColumnLayout {
        id: column
        anchors.centerIn: parent
        width: Math.min(parent.width - 32, 360)
        spacing: root.theme ? root.theme.spacingMedium : 12

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 56
            Layout.preferredHeight: 56
            implicitWidth: 56
            implicitHeight: 56
            radius: 28
            color: root.theme ? root.theme.selectionColor : "#D9ECFF"

            Text {
                anchors.centerIn: parent
                text: root.iconCharacter
                color: root.theme ? root.theme.focusColor : "#0066CC"
                font.family: root.theme ? root.theme.iconFamily(iconFont.name) : iconFont.name
                font.pixelSize: 22
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.title
            color: root.theme ? root.theme.textColor : "#1D1D1F"
            font.family: root.theme ? root.theme.fontFamily : "sans-serif"
            font.pixelSize: root.theme ? root.theme.fontSizeTitle : 17
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }

        Text {
            Layout.fillWidth: true
            text: root.description
            color: root.theme ? root.theme.secondaryTextColor : "#5C5C60"
            font.family: root.theme ? root.theme.fontFamily : "sans-serif"
            font.pixelSize: root.theme ? root.theme.fontSizeBody : 13
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            lineHeight: 1.35
        }

        Button {
            visible: root.actionText.length > 0
            Layout.alignment: Qt.AlignHCenter
            theme: root.theme
            size: "s"
            text: root.actionText
            iconCharacter: "\uf067"
            onClicked: root.actionClicked()
        }
    }

    FontLoader {
        id: iconFont
        source: root.theme ? root.theme.iconSource() : "qrc:/cscui/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "EmptyState"
        nameZh: "空状态"
    }
}
