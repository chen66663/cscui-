pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../components" as Components

// Life dashboard: widgets first, then charts and opt-in media.
ColumnLayout {
    id: root

    // Loader users may attach the shared theme after construction. Keep a
    // complete local contract available so initial bindings remain valid.
    property var theme: fallbackTheme
    property var toastRef: null
    property var openAnimatedWindowHandler: null
    property var openMusicWindowHandler: null
    property int availableWidth: 0
    property int animationDuration: 320
    property int contentDelayPercent: 28
    property int contentDurationPercent: 72
    property int closeDurationPercent: 68
    property int contentOffset: 10
    readonly property var animatedTriggerVariants: [
        {
            label: root.theme.localized("Square", "直角方形"),
            radius: 0,
            color: root.theme.focusColor,
            hoverColor: Qt.lighter(root.theme.focusColor, root.theme.isDark ? 1.25 : 1.12),
            iconColor: root.theme.onAccentColor
        },
        {
            label: root.theme.localized("Small radius", "小圆角"),
            radius: root.theme.radiusSmall,
            color: root.theme.selectionColor,
            hoverColor: root.theme.hoverColor,
            iconColor: root.theme.focusColor
        },
        {
            label: root.theme.localized("Rounded", "圆角"),
            radius: root.theme.radiusLarge,
            color: root.theme.tertiaryColor,
            hoverColor: root.theme.hoverColor,
            iconColor: root.theme.textColor
        },
        {
            label: root.theme.localized("Soft rounded", "大圆角"),
            radius: 22,
            color: root.theme.secondaryColor,
            hoverColor: root.theme.hoverColor,
            iconColor: root.theme.textColor
        }
    ]
    signal eventLogged(string message)

    Components.Theme {
        id: fallbackTheme
    }

    ListModel {
        id: playlistPreviewModel

        ListElement {
            source: "file:///cscui-demo/focus-loop.mp3"
            title: "Focus Loop"
            artist: "cscui demo"
        }
        ListElement {
            source: "file:///cscui-demo/night-build.mp3"
            title: "Night Build"
            artist: "cscui demo"
        }
        ListElement {
            source: "file:///cscui-demo/quiet-review.mp3"
            title: "Quiet Review"
            artist: "cscui demo"
        }
    }

    width: availableWidth > 0 ? availableWidth : 720
    spacing: theme ? theme.spacingXLarge : 24

    function log(message) {
        eventLogged(message);
    }

    function animationProfile() {
        return {
            duration: root.animationDuration,
            contentDelayFactor: root.contentDelayPercent / 100,
            contentDurationFactor: root.contentDurationPercent / 100,
            closeDurationFactor: root.closeDurationPercent / 100,
            contentOffset: root.contentOffset
        };
    }

    function launchAnimatedWindow(source, variantLabel) {
        if (root.openAnimatedWindowHandler)
            root.openAnimatedWindowHandler(source, root.animationProfile());
        root.log(root.theme.localized("Animated window opened", "动画窗口已打开")
                 + (variantLabel ? " · " + variantLabel : ""));
    }

    // Used by the shell auto-demo / README capture: morph from the real launcher.
    function demoOpenAnimatedWindow() {
        root.launchAnimatedWindow(
                    animatedWindowLauncher,
                    root.theme.localized("Standard", "标准按钮"));
    }

    function resetAnimationParameters() {
        root.animationDuration = 320;
        root.contentDelayPercent = 28;
        root.contentDurationPercent = 72;
        root.closeDurationPercent = 68;
        root.contentOffset = 10;
        durationSlider.value = root.animationDuration;
        delaySlider.value = root.contentDelayPercent;
        contentDurationSlider.value = root.contentDurationPercent;
        closeSlider.value = root.closeDurationPercent;
        offsetSlider.value = root.contentOffset;
    }

    Component.onCompleted: Qt.callLater(function() {
        // Slider normalizes its default value while its range bindings are
        // being installed. Reapply the page profile after all ranges exist.
        durationSlider.value = root.animationDuration;
        delaySlider.value = root.contentDelayPercent;
        contentDurationSlider.value = root.contentDurationPercent;
        closeSlider.value = root.closeDurationPercent;
        offsetSlider.value = root.contentOffset;
    })

    Components.CscSectionHeader {
        Layout.fillWidth: true
        theme: root.theme
        title: root.theme.localized("Life dashboard", "生活看板")
        subtitle: root.theme.localized("Glanceable widgets first, then charts, surfaces and opt-in media.", "先看一眼小组件，再浏览图表、材质与按需媒体。")
        badge: root.theme.localized("Full kit", "完整套件")
    }

    Components.CscDemoSection {
        Layout.fillWidth: true
        theme: root.theme
        title: root.theme.localized("At a glance", "今日一览")
        description: root.theme.localized("Clock, battery, goals and countdowns share the same tokens.", "时钟、电量、目标与倒计时共享同一套设计令牌。")

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: root.theme ? root.theme.spacingLarge : 16

            Components.ClockCard {
                theme: root.theme
                width: 280
                height: 170
                useNetworkWeather: false
                weatherApiKey: ""
                shadowEnabled: false
            }

            Components.BatteryCard {
                theme: root.theme
                width: 180
                height: 170
                batteryLevel: 76
                charging: true
                shadowEnabled: false
            }

            Components.FitnessProgress {
                theme: root.theme
                width: 220
                height: 220
                title: root.theme.localized("WEEKLY GOAL", "每周目标")
                goal: 100
                value: 68
                shadowEnabled: false
            }

            Components.YearProgress {
                theme: root.theme
                width: 280
                height: 100
                shadowEnabled: false
            }

            Components.NextHolidayCountdown {
                theme: root.theme
                width: 280
                height: 100
                useNetwork: false
                shadowEnabled: false
            }
        }
    }

    Components.CscDemoSection {
        Layout.fillWidth: true
        theme: root.theme
        title: root.theme.localized("Weekly rhythm", "每周节奏")
        description: root.theme.localized("Series use distinct hues and direct labels; exact values remain available on interaction.", "数据系列使用不同色相与直接标签，交互时可查看精确数值。")

        Components.AreaChart {
            theme: root.theme
            Layout.fillWidth: true
            Layout.preferredHeight: 330
            title: root.theme.localized("Weekly activity", "每周活动")
            subtitle: root.theme.localized("Build and review sessions", "构建与评审次数")
            // The section already provides elevation; a second offscreen
            // shadow texture only increases GPU bandwidth while scrolling.
            shadowEnabled: false
            dataSeries: [
                {
                    name: root.theme.localized("Builds", "构建"),
                    color: root.theme.focusColor,
                    data: [
                        {
                            month: root.theme.localized("Mon", "周一"),
                            value: 18,
                            label: root.theme.localized("Monday", "星期一")
                        },
                        {
                            month: root.theme.localized("Tue", "周二"),
                            value: 26,
                            label: root.theme.localized("Tuesday", "星期二")
                        },
                        {
                            month: root.theme.localized("Wed", "周三"),
                            value: 23,
                            label: root.theme.localized("Wednesday", "星期三")
                        },
                        {
                            month: root.theme.localized("Thu", "周四"),
                            value: 35,
                            label: root.theme.localized("Thursday", "星期四")
                        },
                        {
                            month: root.theme.localized("Fri", "周五"),
                            value: 31,
                            label: root.theme.localized("Friday", "星期五")
                        },
                        {
                            month: root.theme.localized("Sat", "周六"),
                            value: 14,
                            label: root.theme.localized("Saturday", "星期六")
                        },
                        {
                            month: root.theme.localized("Sun", "周日"),
                            value: 11,
                            label: root.theme.localized("Sunday", "星期日")
                        }
                    ]
                },
                {
                    name: root.theme.localized("Reviews", "评审"),
                    color: root.theme.successColor,
                    data: [
                        {
                            month: root.theme.localized("Mon", "周一"),
                            value: 9,
                            label: root.theme.localized("Monday", "星期一")
                        },
                        {
                            month: root.theme.localized("Tue", "周二"),
                            value: 14,
                            label: root.theme.localized("Tuesday", "星期二")
                        },
                        {
                            month: root.theme.localized("Wed", "周三"),
                            value: 16,
                            label: root.theme.localized("Wednesday", "星期三")
                        },
                        {
                            month: root.theme.localized("Thu", "周四"),
                            value: 20,
                            label: root.theme.localized("Thursday", "星期四")
                        },
                        {
                            month: root.theme.localized("Fri", "周五"),
                            value: 19,
                            label: root.theme.localized("Friday", "星期五")
                        },
                        {
                            month: root.theme.localized("Sat", "周六"),
                            value: 8,
                            label: root.theme.localized("Saturday", "星期六")
                        },
                        {
                            month: root.theme.localized("Sun", "周日"),
                            value: 6,
                            label: root.theme.localized("Sunday", "星期日")
                        }
                    ]
                }
            ]
            onPointClicked: function (index, dataPoint) {
                root.log(root.theme.localized("Area value: ", "面积图数值：") + dataPoint.value);
            }
        }
    }

    Components.CscDemoSection {
        Layout.fillWidth: true
        theme: root.theme
        title: root.theme.localized("Quality and coverage", "质量与覆盖")
        description: root.theme.localized("Bar charts compare discrete values; donut charts keep category counts small.", "柱状图用于比较离散数值，环形图则保持较少的分类数量。")

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: root.theme ? root.theme.spacingLarge : 16

            Components.BarChart {
                theme: root.theme
                width: root.width >= 940 ? (root.width - 64) / 2 : root.width - 40
                height: 330
                title: root.theme.localized("Component quality", "组件质量")
                subtitle: root.theme.localized("Automated checks by release", "各版本自动化检查")
                shadowEnabled: false
                dataSeries: [
                    {
                        name: "1.0",
                        color: root.theme.focusColor,
                        data: [
                            {
                                label: root.theme.localized("Lint", "代码检查"),
                                value: 82
                            },
                            {
                                label: root.theme.localized("A11y", "无障碍"),
                                value: 74
                            },
                            {
                                label: root.theme.localized("Tests", "测试"),
                                value: 68
                            },
                            {
                                label: root.theme.localized("Docs", "文档"),
                                value: 88
                            }
                        ]
                    },
                    {
                        name: "1.1",
                        color: root.theme.successColor,
                        data: [
                            {
                                label: root.theme.localized("Lint", "代码检查"),
                                value: 96
                            },
                            {
                                label: root.theme.localized("A11y", "无障碍"),
                                value: 92
                            },
                            {
                                label: root.theme.localized("Tests", "测试"),
                                value: 90
                            },
                            {
                                label: root.theme.localized("Docs", "文档"),
                                value: 94
                            }
                        ]
                    }
                ]
                onPointClicked: function (seriesIndex, dataIndex, dataPoint) {
                    root.log(root.theme.localized("Bar value: ", "柱状图数值：") + dataPoint.value);
                }
            }

            Components.PieChart {
                theme: root.theme
                width: root.width >= 940 ? (root.width - 64) / 2 : Math.min(430, root.width - 40)
                height: 330
                title: root.theme.localized("Catalogue coverage", "目录覆盖")
                subtitle: root.theme.localized("Components by family", "按系列统计组件")
                innerRadius: 58
                shadowEnabled: false
                dataSeries: [
                    {
                        name: root.theme.localized("Components", "组件"),
                        data: [
                            {
                                label: root.theme.localized("Controls", "控件"),
                                value: 14,
                                color: root.theme.focusColor
                            },
                            {
                                label: root.theme.localized("Data", "数据"),
                                value: 9,
                                color: root.theme.successColor
                            },
                            {
                                label: root.theme.localized("Media", "媒体"),
                                value: 6,
                                color: root.theme.warningColor
                            },
                            {
                                label: root.theme.localized("Utilities", "工具"),
                                value: 5,
                                color: root.theme.infoColor
                            }
                        ]
                    }
                ]
            }
        }
    }

    Components.CscDemoSection {
        Layout.fillWidth: true
        theme: root.theme
        title: root.theme.localized("Surfaces and time", "材质与时间")
        description: root.theme.localized("Material overlays, pointer-aware cards and time displays stay useful in both light and dark themes.", "材质叠层、指针感知卡片与时间显示在浅色和深色主题下都保持可读。")

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: root.theme ? root.theme.spacingLarge : 16

            ColumnLayout {
                width: Math.min(360, Math.max(260, root.width - 48))
                spacing: root.theme.spacingSmall

                Text {
                    Layout.fillWidth: true
                    text: "BlurCard"
                    color: root.theme.textColor
                    font.family: root.theme.monoFontFamily
                    font.pixelSize: root.theme.fontSizeCaption
                    font.weight: Font.DemiBold
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 190
                    clip: true

                    Image {
                        id: blurBackdrop
                        anchors.fill: parent
                        source: "qrc:/cscui/fonts/pic/02.jpg"
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize: Qt.size(Math.round(width), Math.round(height))
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: root.theme.isDark ? "#66000000" : "#33000000"
                    }

                    Components.BlurCard {
                        anchors.fill: parent
                        anchors.margins: root.theme.spacingLarge
                        theme: root.theme
                        blurSource: blurBackdrop
                        blurAmount: 0.82
                        blurMax: 28
                        borderRadius: root.theme.radiusLarge
                        borderColor: root.theme.borderColor

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: root.theme.spacingLarge
                            spacing: root.theme.spacingSmall

                            Text {
                                Layout.fillWidth: true
                                text: root.theme.localized("Focused surface", "专注表面")
                                color: root.theme.textColor
                                font.family: root.theme.fontFamily
                                font.pixelSize: root.theme.fontSizeTitle
                                font.weight: Font.DemiBold
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.theme.localized("Blur is reserved for a clear foreground layer.", "模糊只用于突出明确的前景层。")
                                color: root.theme.secondaryTextColor
                                font.family: root.theme.fontFamily
                                font.pixelSize: root.theme.fontSizeBody
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                width: Math.min(420, Math.max(280, root.width - 48))
                spacing: root.theme.spacingSmall

                Text {
                    Layout.fillWidth: true
                    text: root.theme.localized("HitokotoCard / HoverCard", "HitokotoCard / HoverCard")
                    color: root.theme.textColor
                    font.family: root.theme.monoFontFamily
                    font.pixelSize: root.theme.fontSizeCaption
                    font.weight: Font.DemiBold
                }

                Components.HitokotoCard {
                    theme: root.theme
                    Layout.fillWidth: true
                    Layout.preferredHeight: 160
                    useNetworkQuote: false
                    useNetworkImage: false
                    quoteText: root.theme.localized("Clarity is a feature.", "清晰本身就是一种功能。")
                    quoteFrom: "cscui"
                    shadowEnabled: false
                }

                Components.HoverCard {
                    theme: root.theme
                    Layout.fillWidth: true
                    Layout.preferredHeight: 190
                    accessibleName: root.theme.localized("Hover card preview", "悬停卡片预览")
                    accessibleDescription: root.theme.localized("Move the pointer over the card to inspect its restrained tilt.", "将指针移到卡片上查看克制的倾斜效果。")

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: root.theme.spacingSmall

                        Text {
                            Layout.fillWidth: true
                            text: "HoverCard"
                            color: root.theme.focusColor
                            font.family: root.theme.monoFontFamily
                            font.pixelSize: root.theme.fontSizeCaption
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.theme.localized("Pointer-aware motion", "指针感知动效")
                            color: root.theme.textColor
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.fontSizeTitle
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.theme.localized("The card settles back when focus leaves it.", "焦点离开后卡片会平滑回到原位。")
                            color: root.theme.secondaryTextColor
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.fontSizeBody
                            wrapMode: Text.WordWrap
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }

            ColumnLayout {
                width: Math.min(360, Math.max(250, root.width - 48))
                spacing: root.theme.spacingSmall

                Text {
                    Layout.fillWidth: true
                    text: root.theme.localized("Clock / TimeDisplay", "Clock / TimeDisplay")
                    color: root.theme.textColor
                    font.family: root.theme.monoFontFamily
                    font.pixelSize: root.theme.fontSizeCaption
                    font.weight: Font.DemiBold
                }

                Row {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 184
                    Layout.minimumHeight: 184
                    spacing: root.theme.spacingMedium

                    Components.Clock {
                        theme: root.theme
                        width: 176
                        height: 176
                        accessibleName: root.theme.localized("Current analog clock", "当前模拟时钟")
                    }

                    Components.TimeDisplay {
                        theme: root.theme
                        width: 112
                        height: 176
                        is24Hour: false
                        separatorVisible: true
                    }
                }
            }
        }
    }

    Components.CscDemoSection {
        Layout.fillWidth: true
        theme: root.theme
        title: root.theme.localized("Animated window", "动画窗口")
        description: root.theme.localized("Tune the shared-element transition, then compare square triggers with different corner radii. The animation only changes scene-graph transforms, color and opacity.", "调节共享元素过渡参数，并比较不同圆角的方形触发按钮。动画只改变场景图变换、颜色和不透明度。")

        GridLayout {
            id: animatedDemoLayout
            Layout.fillWidth: true
            columns: root.width >= 860 ? 2 : 1
            columnSpacing: root.theme.spacingXLarge
            rowSpacing: root.theme.spacingLarge

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 300
                Layout.preferredWidth: 420
                Layout.alignment: Qt.AlignTop
                spacing: root.theme.spacingMedium

                Text {
                    Layout.fillWidth: true
                    text: root.theme.localized("Launch surfaces", "触发按钮")
                    color: root.theme.textColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeBody
                    font.weight: Font.DemiBold
                }

                Components.Button {
                    id: animatedWindowLauncher
                    theme: root.theme
                    size: "m"
                    text: root.theme.localized("Open animated window", "打开动画窗口")
                    iconCharacter: "\uf5fd"
                    containerColor: root.theme.focusColor
                    hoverColor: Qt.lighter(root.theme.focusColor, root.theme.isDark ? 1.25 : 1.12)
                    textColor: root.theme.onAccentColor
                    iconColor: root.theme.onAccentColor
                    shadowEnabled: false
                    onClicked: root.launchAnimatedWindow(
                                   animatedWindowLauncher,
                                   root.theme.localized("Standard", "标准按钮"))
                }

                Text {
                    Layout.fillWidth: true
                    text: root.theme.localized("Square variants", "方形按钮样式")
                    color: root.theme.secondaryTextColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeCaption
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: root.theme.spacingMedium

                    Repeater {
                        model: root.animatedTriggerVariants

                        delegate: Column {
                            id: triggerVariant
                            required property var modelData

                            width: 84
                            spacing: root.theme.spacingSmall

                            Components.Button {
                                id: squareTrigger
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 64
                                height: 64
                                theme: root.theme
                                text: ""
                                iconCharacter: "\uf065"
                                accessibleName: root.theme.localized("Open animated window: ", "打开动画窗口：")
                                                + triggerVariant.modelData.label
                                radius: triggerVariant.modelData.radius
                                containerColor: triggerVariant.modelData.color
                                hoverColor: triggerVariant.modelData.hoverColor
                                iconColor: triggerVariant.modelData.iconColor
                                shadowEnabled: false
                                pressedScale: 0.95
                                onClicked: root.launchAnimatedWindow(
                                               squareTrigger,
                                               triggerVariant.modelData.label)
                            }

                            Text {
                                width: parent.width
                                text: triggerVariant.modelData.label
                                color: root.theme.secondaryTextColor
                                font.family: root.theme.fontFamily
                                font.pixelSize: root.theme.fontSizeCaption
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.minimumWidth: 320
                Layout.preferredWidth: 420
                Layout.alignment: Qt.AlignTop
                implicitHeight: parameterColumn.implicitHeight + root.theme.spacingLarge * 2
                radius: root.theme.radiusLarge
                color: root.theme.surfaceSecondaryColor
                border.width: 1
                border.color: root.theme.borderColor

                ColumnLayout {
                    id: parameterColumn
                    anchors.fill: parent
                    anchors.margins: root.theme.spacingLarge
                    spacing: root.theme.spacingMedium

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: root.theme.localized("Animation parameters", "动画参数")
                            color: root.theme.textColor
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.fontSizeBody
                            font.weight: Font.DemiBold
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            Layout.fillWidth: true
                            text: root.animationDuration + " ms · "
                                  + root.contentDelayPercent + "% / "
                                  + root.contentDurationPercent + "% · "
                                  + root.closeDurationPercent + "% · "
                                  + root.contentOffset + " px"
                            color: root.theme.focusColor
                            font.family: root.theme.monoFontFamily
                            font.pixelSize: root.theme.fontSizeCaption
                            horizontalAlignment: Text.AlignRight
                            wrapMode: Text.Wrap
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.theme.reducedMotion
                              ? root.theme.localized("Reduced motion is active; transitions run instantly.", "已启用减少动态效果；过渡将立即完成。")
                              : root.theme.localized("Changes apply the next time a window opens.", "参数将在下次打开窗口时生效。")
                        color: root.theme.secondaryTextColor
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSizeCaption
                        wrapMode: Text.Wrap
                    }

                    Components.Slider {
                        id: durationSlider
                        Layout.fillWidth: true
                        theme: root.theme
                        text: root.theme.localized("Duration", "动画时长")
                        labelWidth: 104
                        minimumValue: 80
                        maximumValue: 1200
                        stepSize: 10
                        decimals: 0
                        valueSuffix: " ms"
                        value: root.animationDuration
                        onUserValueChanged: function (value) {
                            root.animationDuration = Math.round(value);
                        }
                    }

                    Components.Slider {
                        id: delaySlider
                        Layout.fillWidth: true
                        theme: root.theme
                        text: root.theme.localized("Content delay", "内容延迟")
                        labelWidth: 104
                        minimumValue: 0
                        maximumValue: 60
                        stepSize: 1
                        decimals: 0
                        valueSuffix: "%"
                        value: root.contentDelayPercent
                        onUserValueChanged: function (value) {
                            root.contentDelayPercent = Math.round(value);
                        }
                    }

                    Components.Slider {
                        id: contentDurationSlider
                        Layout.fillWidth: true
                        theme: root.theme
                        text: root.theme.localized("Content fade", "内容淡入")
                        labelWidth: 104
                        minimumValue: 10
                        maximumValue: 100
                        stepSize: 1
                        decimals: 0
                        valueSuffix: "%"
                        value: root.contentDurationPercent
                        onUserValueChanged: function (value) {
                            root.contentDurationPercent = Math.round(value);
                        }
                    }

                    Components.Slider {
                        id: closeSlider
                        Layout.fillWidth: true
                        theme: root.theme
                        text: root.theme.localized("Close duration", "关闭时长")
                        labelWidth: 104
                        minimumValue: 20
                        maximumValue: 140
                        stepSize: 1
                        decimals: 0
                        valueSuffix: "%"
                        value: root.closeDurationPercent
                        onUserValueChanged: function (value) {
                            root.closeDurationPercent = Math.round(value);
                        }
                    }

                    Components.Slider {
                        id: offsetSlider
                        Layout.fillWidth: true
                        theme: root.theme
                        text: root.theme.localized("Content offset", "内容位移")
                        labelWidth: 104
                        minimumValue: 0
                        maximumValue: 64
                        stepSize: 1
                        decimals: 0
                        valueSuffix: " px"
                        value: root.contentOffset
                        onUserValueChanged: function (value) {
                            root.contentOffset = Math.round(value);
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Item { Layout.fillWidth: true }

                        Components.Button {
                            theme: root.theme
                            size: "xs"
                            text: root.theme.localized("Reset parameters", "重置参数")
                            iconCharacter: "\uf2ea"
                            backgroundVisible: false
                            shadowEnabled: false
                            onClicked: root.resetAnimationParameters()
                        }
                    }
                }
            }
        }
    }

    Components.CscDemoSection {
        Layout.fillWidth: true
        theme: root.theme
        title: root.theme.localized("Accent and media", "强调色与媒体")
        description: root.theme.localized("Preview an accent, then opt in to local music scanning.", "先预览强调色，再按需启用本地音乐扫描。")

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: root.theme ? root.theme.spacingLarge : 16

            Components.ColorPicker {
                theme: root.theme
                width: Math.min(340, Math.max(280, root.width - 48))
                onPickedColorChanged: root.log(root.theme.localized("Accent preview updated", "强调色预览已更新"))
            }

            ColumnLayout {
                width: Math.min(Math.max(0, root.width - 40), Math.max(280, root.width - 360))
                spacing: root.theme.spacingMedium

                Components.SwitchButton {
                    id: mediaSwitch
                    theme: root.theme
                    size: "s"
                    text: root.theme.localized("Load local media demo", "加载本地媒体演示")
                    onToggled: function (value) {
                        mediaLoader.active = value;
                        root.log(root.theme.localized("Media demo: ", "媒体演示：") + value);
                    }
                }

                Text {
                    visible: !mediaLoader.active
                    Layout.fillWidth: true
                    text: root.theme.localized(
                              "Local media access is disabled until requested. The playlist below is a local demo model.",
                              "在用户主动请求前，本地媒体访问保持禁用。下方播放列表为本地演示数据。")
                    color: root.theme.secondaryTextColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeBody
                    wrapMode: Text.WordWrap
                }

                Loader {
                    id: mediaLoader
                    active: false
                    Layout.fillWidth: true
                    sourceComponent: Component {
                        Components.MusicPlayer {
                            theme: root.theme
                            width: mediaLoader.width
                            shadowEnabled: false
                            openWindowHandler: root.openMusicWindowHandler
                            onSourceChanged: root.log(root.theme.localized("Media source changed", "媒体源已更改"))
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.theme.localized("Playlist preview", "播放列表预览")
                    color: root.theme.textColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeTitle
                    font.weight: Font.DemiBold
                }

                Components.Playlist {
                    theme: root.theme
                    Layout.fillWidth: true
                    Layout.preferredHeight: 250
                    model: playlistPreviewModel
                    playerRef: null
                    autoScan: false
                    importEnabled: false
                }
            }
        }
    }
}
