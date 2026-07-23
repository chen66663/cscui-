pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

// Product information surface retained under the historical Aboutme name.
// The text reveal is intentionally driven by windowOpen so a drawer can keep
// its content mounted without spending timer work while it is dismissed.
Item {
    id: root

    required property var theme

    property bool windowOpen: false
    property string version: "1.0.0"
    property string introTextEn: "A focused Qt Quick component workbench"
    property string introTextZh: "专注的 Qt Quick 组件工作台"
    property int typewriterInterval: 28
    property bool typewriterEnabled: true
    property bool reducedMotion: root.theme ? root.theme.reducedMotion : false
    property string typedText: ""
    property bool cursorVisible: false

    readonly property string introductionText: root.theme
                                                ? root.theme.localized(root.introTextEn, root.introTextZh)
                                                : root.introTextEn
    readonly property bool typing: typingTimer.running
    readonly property bool typingComplete: root.introductionText.length > 0
                                           && root.typedText === root.introductionText

    property var aboutItems: [
        {
            icon: "\uf121",
            label: "Qt Quick",
            value: root.theme.localized("Reusable desktop components", "可复用桌面组件")
        },
        {
            icon: "\uf29a",
            label: root.theme.localized("Accessible", "无障碍"),
            value: root.theme.localized("Keyboard and screen-reader contracts", "键盘与屏幕阅读器契约")
        },
        {
            icon: "\uf188",
            label: root.theme.localized("Inspectable", "可检查"),
            value: root.theme.localized("Built-in runtime diagnostics", "内置运行时诊断")
        },
        {
            icon: "\uf1d8",
            label: root.theme.localized("Portable", "跨平台"),
            value: root.theme.localized("Windows, macOS and Linux targets", "支持 Windows、macOS 与 Linux")
        }
    ]

    // The index is deliberately data-driven so the About surface can act as a
    // compact catalogue without duplicating demo layout or component logic.
    property var componentItems: [
        { name: "Aboutme", description: "带有打字机效果的介绍界面" },
        { name: "Accordion", description: "下拉信息栏" },
        { name: "AlertDialog", description: "确认与告警对话框" },
        { name: "AnimatedWindow", description: "iPadOS 动画风格窗口组件" },
        { name: "AreaChart", description: "折线 / 面积图组件" },
        { name: "Avatar", description: "头像组件" },
        { name: "BarChart", description: "柱状图组件" },
        { name: "BatteryCard", description: "电池状态卡片组件" },
        { name: "BlurCard", description: "高斯模糊卡片组件" },
        { name: "Button", description: "带图标与动画的圆角按钮组件" },
        { name: "Calendar", description: "日历组件" },
        { name: "Card", description: "基础卡片容器组件" },
        { name: "CardWithTextArea", description: "带文本区域的卡片容器组件" },
        { name: "Carousel", description: "轮播组件" },
        { name: "CheckBox", description: "动画复选框组件" },
        { name: "Clock", description: "时钟显示组件" },
        { name: "ClockCard", description: "时钟卡片容器组件" },
        { name: "ColorPicker", description: "颜色选择器组件" },
        { name: "DataTable", description: "高性能表格组件" },
        { name: "Divider", description: "分割线组件" },
        { name: "Drawer", description: "侧边栏组件" },
        { name: "Dropdown", description: "下拉选择框组件" },
        { name: "EmptyState", description: "空状态占位组件" },
        { name: "FitnessProgress", description: "健身进度展示组件" },
        { name: "HitokotoCard", description: "一言卡片组件" },
        { name: "HoverCard", description: "鼠标悬停浮起卡片容器组件" },
        { name: "Input", description: "支持焦点变色与阴影的输入框" },
        { name: "List", description: "列表展示组件" },
        { name: "LoadingIndicator", description: "加载动画组件" },
        { name: "MenuButton", description: "菜单按钮组件" },
        { name: "MusicPlayer", description: "音乐播放器组件" },
        { name: "MusicWindow", description: "全屏音乐播放窗口" },
        { name: "NavBar", description: "导航栏组件" },
        { name: "NextHolidayCountdown", description: "假期倒计时组件" },
        { name: "PieChart", description: "饼图组件" },
        { name: "Playlist", description: "播放列表组件" },
        { name: "ProgressBar", description: "线性进度条组件" },
        { name: "RadioButton", description: "动画单选组件" },
        { name: "SearchField", description: "搜索输入框组件" },
        { name: "SimpleDatePicker", description: "简易日期选择组件" },
        { name: "Slider", description: "支持滑块动画的调节组件" },
        { name: "SwitchButton", description: "动画开关组件" },
        { name: "Tag", description: "状态标签组件" },
        { name: "Theme", description: "全局样式与颜色定义" },
        { name: "TimeDisplay", description: "时间显示组件" },
        { name: "Toast", description: "支持消息提示的组件" },
        { name: "YearProgress", description: "年度进度展示组件" }
    ]

    signal typingFinished

    readonly property int contentPadding: root.theme ? root.theme.spacingLarge : 16
    readonly property int cardPadding: root.theme ? root.theme.spacingLarge : 16

    implicitWidth: 360
    implicitHeight: Math.max(420, pageColumn.implicitHeight + root.contentPadding * 2)
    // A drawer supplies its own height; standalone users still get a useful
    // intrinsic surface instead of an Item with the default zero size.
    width: parent ? parent.width : implicitWidth
    height: parent && parent.height > 0 ? parent.height : implicitHeight
    clip: true

    Accessible.role: Accessible.Pane
    Accessible.name: root.theme.localized("About cscui", "关于 cscui")
    Accessible.description: root.introductionText

    FontLoader {
        id: iconFont
        source: root.theme ? root.theme.iconSource() : "qrc:/cscui/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    function resetTypewriter() {
        typingTimer.stop();
        root.cursorVisible = false;
        root.typedText = "";

        if (!root.windowOpen || !root.visible)
            return;

        if (!root.typewriterEnabled || root.reducedMotion || root.introductionText.length === 0) {
            root.typedText = root.introductionText;
            return;
        }

        root.cursorVisible = true;
        typingTimer.start();
    }

    function finishImmediately() {
        typingTimer.stop();
        root.typedText = root.introductionText;
        root.cursorVisible = false;
        if (root.introductionText.length > 0)
            root.typingFinished();
    }

    Timer {
        id: typingTimer
        interval: Math.max(16, root.typewriterInterval)
        repeat: true
        onTriggered: {
            if (!root.windowOpen || !root.visible || root.reducedMotion || !root.typewriterEnabled) {
                root.finishImmediately();
                return;
            }

            const nextLength = root.typedText.length + 1;
            root.typedText = root.introductionText.slice(0, nextLength);
            if (root.typedText.length >= root.introductionText.length) {
                typingTimer.stop();
                root.cursorVisible = false;
                root.typingFinished();
            }
        }
    }

    Connections {
        target: root.theme
        ignoreUnknownSignals: true

        function onEffectiveLanguageChanged() {
            if (root.windowOpen)
                root.resetTypewriter();
        }

        function onReducedMotionChanged() {
            if (root.windowOpen)
                root.resetTypewriter();
        }
    }

    onWindowOpenChanged: {
        if (root.windowOpen)
            root.resetTypewriter();
        else {
            typingTimer.stop();
            root.cursorVisible = false;
        }
    }

    onVisibleChanged: {
        if (root.visible && root.windowOpen)
            root.resetTypewriter();
        else if (!root.visible)
            typingTimer.stop();
    }

    onReducedMotionChanged: if (root.windowOpen)
        root.resetTypewriter()

    onIntroductionTextChanged: if (root.windowOpen)
        root.resetTypewriter()

    Flickable {
        id: scrollView
        anchors.fill: parent
        contentWidth: width
        contentHeight: Math.max(height, pageColumn.implicitHeight + root.contentPadding * 2)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
        flickableDirection: Flickable.VerticalFlick

        ColumnLayout {
            id: pageColumn
            x: root.contentPadding
            y: root.contentPadding
            width: Math.max(0, scrollView.width - root.contentPadding * 2)
            spacing: root.theme.spacingLarge

            Text {
                Layout.fillWidth: true
                text: "cscui"
                color: root.theme.textColor
                font.family: root.theme.fontFamily
                font.pixelSize: Math.min(30, root.theme.fontSizeHeading + 8)
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
            }

            // Keep a stable box based on the full localized string. Only the
            // glyphs change while typing, so narrow drawers do not reflow.
            Item {
                Layout.fillWidth: true
                implicitHeight: Math.max(root.theme.touchTarget, fullIntroMeasure.implicitHeight)
                Layout.preferredHeight: implicitHeight

                Text {
                    id: fullIntroMeasure
                    anchors.left: parent.left
                    anchors.right: parent.right
                    visible: false
                    text: root.introductionText
                    wrapMode: Text.WordWrap
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeTitle
                }

                Text {
                    anchors.fill: parent
                    text: root.typedText + (root.cursorVisible ? " \u2588" : "")
                    color: root.theme.secondaryTextColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeTitle
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                    Accessible.ignored: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: featureColumn.implicitHeight + root.cardPadding * 2
                radius: root.theme.radiusLarge
                color: root.theme.secondaryColor
                border.width: 1
                border.color: root.theme.separatorColor

                ColumnLayout {
                    id: featureColumn
                    anchors.fill: parent
                    anchors.margins: root.cardPadding
                    spacing: root.theme.spacingMedium

                    Repeater {
                        model: root.aboutItems

                        delegate: RowLayout {
                            id: featureRow
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: root.theme.spacingMedium

                            Text {
                                text: featureRow.modelData.icon
                                color: root.theme.focusColor
                                font.family: root.theme ? root.theme.iconFamily(iconFont.name) : iconFont.name
                                font.pixelSize: 15
                                Layout.preferredWidth: 22
                                horizontalAlignment: Text.AlignHCenter
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: root.theme.spacingXs

                                Text {
                                    Layout.fillWidth: true
                                    text: featureRow.modelData.label
                                    color: root.theme.textColor
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: root.theme.fontSizeBody
                                    font.weight: Font.DemiBold
                                    wrapMode: Text.WordWrap
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: featureRow.modelData.value
                                    color: root.theme.secondaryTextColor
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: root.theme.fontSizeCaption
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.theme.localized("Component index", "组件索引")
                color: root.theme.textColor
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.fontSizeTitle
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                text: root.theme.localized(
                          root.componentItems.length + " reusable components",
                          root.componentItems.length + " 个可复用组件")
                color: root.theme.secondaryTextColor
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.fontSizeCaption
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: root.theme.spacingXs

                Repeater {
                    model: root.componentItems

                    delegate: RowLayout {
                        id: componentRow
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: root.theme.spacingMedium

                        Text {
                            Layout.preferredWidth: 168
                            text: componentRow.modelData.name
                            color: root.theme.focusColor
                            font.family: root.theme.monoFontFamily
                            font.pixelSize: root.theme.fontSizeCaption
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: componentRow.modelData.description
                            color: root.theme.secondaryTextColor
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.fontSizeCaption
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.theme.localized("Version ", "版本 ") + root.version
                      + "  |  " + root.theme.localized("MIT License", "MIT 许可证")
                color: root.theme.tertiaryTextColor
                font.family: root.theme.monoFontFamily
                font.pixelSize: root.theme.fontSizeCaption
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
    }

    Component.onCompleted: {
        if (root.windowOpen)
            root.resetTypewriter();
    }

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "Aboutme"
        nameZh: "关于"
    }
}
