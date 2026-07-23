//Accordion.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

ColumnLayout {
    id: root
    // Explicit injection keeps legacy accordion surfaces on the active palette.
    property var theme
    spacing: 0   // 标题和内容之间不留空隙

    // ==== 外部接口 ====
    property bool backgroundVisible: true        // 是否显示背景
    property string title: theme ? theme.localized("Click to expand", "点击展开") : "Click to expand"
    property bool expanded: true                 // 是否展开
    default property alias content: contentLayout.data  // 默认内容插槽

    // ==== 样式 ====
    property real radius: theme ? theme.radiusLarge : 12
    property color headerColor: theme.secondaryColor
    property color headerHoverColor: Qt.darker(headerColor, 1.1)
    property color textColor: theme.textColor
    property color shadowColor: theme.shadowColor
    property bool shadowEnabled: true
    property int headerHeight: 52
    // A negative value lets the expanded surface follow wrapped or dynamic
    // content. Positive values remain supported for compatibility.
    property real contentHeight: -1
    readonly property real effectiveContentHeight: contentHeight >= 0
                                                   ? contentHeight
                                                   : contentLayout.implicitHeight

    // ==== 1. 标题栏  ====
    Item {
        id: headerContainer
        width: parent.width
        height: root.headerHeight
        Layout.fillWidth: true

        // 阴影效果
        MultiEffect {
            source: header
            anchors.fill: header
            visible: root.shadowEnabled && root.backgroundVisible
            shadowEnabled: true
            shadowColor: root.shadowColor
            shadowBlur: root.theme.shadowBlur
            shadowVerticalOffset: root.theme.shadowYOffset
            shadowHorizontalOffset: root.theme.shadowXOffset
        }

        // 背景矩形
        Rectangle {
            id: header
            visible: root.backgroundVisible
            anchors.fill: parent
            radius: root.radius
            color: mouseArea.containsMouse ? root.headerHoverColor : root.headerColor
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // 标题栏布局
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 8

            // 标题文字
            Text {
                text: root.title
                color: root.textColor
                font.pixelSize: 16
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
            }

            // 右侧箭头 (展开/折叠状态切换)
            Text {
                text: "\uf054"   // FontAwesome: chevron-right
                font.family: "Font Awesome 6 Free"
                font.pixelSize: 16
                color: root.theme.focusColor
                rotation: root.expanded ? -90 : 90
                Behavior on rotation {
                    RotationAnimation { duration: 250; easing.type: Easing.InOutQuad }
                }
            }
        }

        // 点击交互
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }

    // ==== 2. 内容区 (可折叠) ====
    Rectangle {
        id: contentWrapper
        radius: root.radius
        Layout.fillWidth: true
        color: root.backgroundVisible ? root.theme.secondaryColor : "transparent"
        implicitHeight: root.expanded ? root.effectiveContentHeight : 0
        Layout.preferredHeight: implicitHeight
        clip: true
        Layout.topMargin: 8

        // 展开/收起过渡动画
        Behavior on implicitHeight {
            NumberAnimation {
                // Prefer duration over Behavior.enabled — layout height must
                // still settle when reduced motion is on.
                duration: root.theme && root.theme.reducedMotion ? 0 : 250
                easing.type: Easing.OutCubic
            }
        }

        // 自动排列内容组件
        ColumnLayout {
            id: contentLayout
            width: parent.width
        }
    }

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "Accordion"
        nameZh: "手风琴"
    }
}
