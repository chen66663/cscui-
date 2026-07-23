pragma ComponentBehavior: Bound

import QtQuick

// Quiet separator for grouping without card-in-card chrome.
Item {
    id: root

    property var theme: null
    // horizontal | vertical
    property string orientation: "horizontal"
    property string label: ""
    property real thickness: 1

    readonly property bool _vertical: root.orientation === "vertical"

    implicitWidth: root._vertical ? Math.max(root.thickness, labelItem.visible ? labelItem.implicitWidth : root.thickness)
                                  : (labelItem.visible ? Math.max(120, labelItem.implicitWidth + 48) : 120)
    implicitHeight: root._vertical ? 48
                                   : (labelItem.visible ? Math.max(20, labelItem.implicitHeight) : root.thickness)
    Accessible.ignored: root.label.length === 0
    Accessible.role: Accessible.StaticText
    Accessible.name: root.label

    Rectangle {
        visible: !labelItem.visible
        anchors.centerIn: parent
        width: root._vertical ? root.thickness : parent.width
        height: root._vertical ? parent.height : root.thickness
        color: root.theme ? root.theme.separatorColor : "#D8D8DC"
    }

    Row {
        id: labelItem
        visible: root.label.length > 0 && !root._vertical
        anchors.centerIn: parent
        width: parent.width
        spacing: root.theme ? root.theme.spacingSmall : 8

        Rectangle {
            width: Math.max(12, (parent.width - labelText.implicitWidth - parent.spacing * 2) / 2)
            height: root.thickness
            anchors.verticalCenter: parent.verticalCenter
            color: root.theme ? root.theme.separatorColor : "#D8D8DC"
        }

        Text {
            id: labelText
            text: root.label
            color: root.theme ? root.theme.tertiaryTextColor : "#6E6E73"
            font.family: root.theme ? root.theme.fontFamily : "sans-serif"
            font.pixelSize: root.theme ? root.theme.fontSizeCaption : 11
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: Math.max(12, (parent.width - labelText.implicitWidth - parent.spacing * 2) / 2)
            height: root.thickness
            anchors.verticalCenter: parent.verticalCenter
            color: root.theme ? root.theme.separatorColor : "#D8D8DC"
        }
    }

    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "Divider"
        nameZh: "分割线"
    }
}
