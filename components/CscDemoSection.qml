pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var theme
    property string title: ""
    property string description: ""
    property int padding: root.theme.spacingLarge
    default property alias content: contentColumn.data
    property bool entranceReady: false
    property real entranceY: 10

    implicitHeight: contentColumn.implicitHeight + padding * 2
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
            root.entranceY = 10
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

    // Demo sections stay flat because their children may themselves be cards or
    // framed tools. A separator provides grouping without card-in-card chrome.
    ColumnLayout {
        id: contentColumn
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: root.padding
        spacing: root.theme.spacingLarge

        ColumnLayout {
            Layout.fillWidth: true
            spacing: root.theme.spacingXs

            Text {
                Layout.fillWidth: true
                text: root.title
                color: root.theme.textColor
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.fontSizeTitle
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
            }

            Text {
                Layout.fillWidth: true
                visible: root.description.length > 0
                text: root.description
                color: root.theme.secondaryTextColor
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.fontSizeBody
                lineHeight: 1.35
                wrapMode: Text.Wrap
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.theme.showLayoutBounds ? 2 : 1
        color: root.theme.showLayoutBounds ? root.theme.dangerColor : root.theme.separatorColor
    }
}
