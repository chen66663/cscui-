pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var theme
    property string title: ""
    property string subtitle: ""
    property string badge: ""

    implicitHeight: content.implicitHeight + root.theme.spacingSmall

    RowLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.theme.spacingMedium
        clip: true

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: root.theme.spacingXs

            Text {
                Layout.fillWidth: true
                text: root.title
                color: root.theme.textColor
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.fontSizeHeading
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
                maximumLineCount: 2
            }

            Text {
                Layout.fillWidth: true
                visible: root.subtitle.length > 0
                text: root.subtitle
                color: root.theme.secondaryTextColor
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.fontSizeBody
                lineHeight: 1.35
                wrapMode: Text.Wrap
                maximumLineCount: 2
            }
        }

        Rectangle {
            visible: root.badge.length > 0
            Layout.preferredWidth: Math.min(badgeLabel.implicitWidth + root.theme.spacingMedium, Math.max(72, root.width * 0.28))
            Layout.maximumWidth: Math.max(72, root.width * 0.28)
            implicitHeight: 22
            radius: root.theme.radiusSmall
            color: root.theme.selectionColor

            Text {
                id: badgeLabel
                anchors.centerIn: parent
                width: parent.width - root.theme.spacingSmall
                text: root.badge
                color: root.theme.focusColor
                font.family: root.theme.fontFamily
                // Badges are compact, but remain readable at the same size as
                // other captions because they can carry the only count/status
                // cue in a section header.
                font.pixelSize: Math.max(12, root.theme.fontSizeCaption)
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }
    }
}
