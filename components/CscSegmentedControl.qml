pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var theme
    property var model: []
    property int currentIndex: 0
    property int minimumSegmentWidth: 72
    signal activated(int index)

    implicitWidth: segments.implicitWidth + root.theme.spacingSmall
    implicitHeight: root.theme.touchTarget

    function activate(index) {
        if (index < 0 || index >= segmentRepeater.count || index === currentIndex)
            return;
        currentIndex = index;
        activated(index);
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: root.theme.spacingXs
        anchors.bottomMargin: root.theme.spacingXs
        radius: root.theme.radiusMedium
        color: root.theme.tertiaryColor
        border.width: 1
        border.color: root.theme.separatorColor
    }

    RowLayout {
        id: segments
        anchors.fill: parent
        anchors.margins: root.theme.spacingXs
        spacing: 2

        Repeater {
            id: segmentRepeater
            model: root.model

            delegate: FocusScope {
                id: segment
                required property int index
                required property var modelData

                readonly property string labelText: typeof segment.modelData === "string" ? segment.modelData : (segment.modelData.label || "")

                Layout.preferredWidth: Math.max(root.minimumSegmentWidth, label.implicitWidth + root.theme.spacingXLarge)
                Layout.fillHeight: true
                activeFocusOnTab: true
                objectName: labelText

                Accessible.role: Accessible.RadioButton
                Accessible.name: labelText
                Accessible.checkable: true
                Accessible.checked: segment.index === root.currentIndex

                Rectangle {
                    anchors.fill: parent
                    radius: root.theme.radiusSmall
                    color: segment.index === root.currentIndex ? root.theme.elevatedColor : (pointer.containsMouse ? root.theme.hoverColor : "transparent")
                    border.width: segment.activeFocus ? 2 : (segment.index === root.currentIndex ? 1 : 0)
                    border.color: segment.activeFocus ? root.theme.focusColor : root.theme.separatorColor

                    Behavior on color {
                        ColorAnimation {
                            duration: root.theme.durationNormal
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: segment.labelText
                    color: segment.index === root.currentIndex ? root.theme.textColor : root.theme.secondaryTextColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeBody
                    font.weight: segment.index === root.currentIndex ? Font.DemiBold : Font.Normal
                }

                MouseArea {
                    id: pointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activate(segment.index)
                }

                Keys.onLeftPressed: root.activate(Math.max(0, segment.index - 1))
                Keys.onRightPressed: root.activate(Math.min(segmentRepeater.count - 1, segment.index + 1))
                Keys.onSpacePressed: root.activate(segment.index)
                Keys.onReturnPressed: root.activate(segment.index)
                Keys.onEnterPressed: root.activate(segment.index)
            }
        }
    }
}
