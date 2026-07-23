pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

// Linear progress. Value is always paired with an optional text label for a11y.
Item {
    id: root

    property var theme: null
    property real value: 0
    property real minimumValue: 0
    property real maximumValue: 100
    property string text: ""
    property bool showValueLabel: true
    // neutral | accent | success | warning | danger
    property string tone: "accent"
    property bool indeterminate: false

    readonly property real _ratio: {
        const span = Math.max(0.0001, root.maximumValue - root.minimumValue);
        return Math.max(0, Math.min(1, (root.value - root.minimumValue) / span));
    }
    readonly property color _fill: {
        const t = root.theme;
        if (!t)
            return "#0066CC";
        if (root.tone === "success")
            return t.successColor;
        if (root.tone === "warning")
            return t.warningColor;
        if (root.tone === "danger")
            return t.dangerColor;
        if (root.tone === "neutral")
            return t.secondaryTextColor;
        return t.focusColor;
    }

    implicitWidth: 240
    implicitHeight: column.implicitHeight
    Accessible.role: Accessible.ProgressBar
    Accessible.name: root.text.length ? root.text : (root.theme ? root.theme.localized("Progress", "进度") : "Progress")

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: root.theme ? root.theme.spacingXs : 4

        RowLayout {
            Layout.fillWidth: true
            spacing: root.theme ? root.theme.spacingSmall : 8
            visible: root.text.length > 0 || root.showValueLabel

            Text {
                Layout.fillWidth: true
                visible: root.text.length > 0
                text: root.text
                color: root.theme ? root.theme.textColor : "#1D1D1F"
                font.family: root.theme ? root.theme.fontFamily : "sans-serif"
                font.pixelSize: root.theme ? root.theme.fontSizeBody : 13
                elide: Text.ElideRight
            }

            Text {
                visible: root.showValueLabel && !root.indeterminate
                text: Math.round(root._ratio * 100) + "%"
                color: root.theme ? root.theme.secondaryTextColor : "#5C5C60"
                font.family: root.theme ? root.theme.monoFontFamily : "monospace"
                font.pixelSize: root.theme ? root.theme.fontSizeCaption : 11
            }
        }

        Item {
            id: track
            Layout.fillWidth: true
            Layout.preferredHeight: 8

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: root.theme ? root.theme.tertiaryColor : "#F2F2F7"
            }

            Rectangle {
                id: fill
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                width: root.indeterminate ? parent.width * 0.32 : parent.width * root._ratio
                radius: height / 2
                color: root._fill
                x: root.indeterminate ? fill.fillTravel * Math.max(0, track.width - width) : 0
                property real fillTravel: 0

                Behavior on width {
                    enabled: !(root.theme && root.theme.reducedMotion) && !root.indeterminate
                    NumberAnimation {
                        duration: root.theme ? root.theme.durationNormal : 220
                        easing.type: Easing.OutCubic
                    }
                }

                SequentialAnimation {
                    running: root.indeterminate && root.visible && !(root.theme && root.theme.reducedMotion)
                    loops: Animation.Infinite
                    NumberAnimation {
                        target: fill
                        property: "fillTravel"
                        from: 0
                        to: 1
                        duration: 1100
                        easing.type: Easing.InOutCubic
                    }
                    NumberAnimation {
                        target: fill
                        property: "fillTravel"
                        from: 1
                        to: 0
                        duration: 1100
                        easing.type: Easing.InOutCubic
                    }
                }
            }
        }
    }

    CscIdentityLayer {
        active: false
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "ProgressBar"
        nameZh: "进度条"
    }
}
