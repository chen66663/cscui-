pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../components" as Components

// 今日工作流：用真实表单任务串联操作、输入、选择与反馈组件。
ColumnLayout {
    id: root

    property var theme: fallbackTheme
    property var toastRef: null
    property int availableWidth: 0
    signal eventLogged(string message)

    Components.Theme {
        id: fallbackTheme
    }

    width: availableWidth > 0 ? availableWidth : 720
    spacing: theme ? theme.spacingXLarge : 24

    function log(message) {
        eventLogged(message);
    }

    function submitProject() {
        loader.running = true;
        root.log(root.theme.localized("Project submit started", "已开始提交项目"));
        submitResetTimer.restart();
    }

    Timer {
        id: submitResetTimer
        interval: 1400
        onTriggered: {
            loader.running = false;
            if (root.toastRef)
                root.toastRef.show(root.theme.localized("Project saved", "项目已保存"));
            root.log(root.theme.localized("Project submit finished", "项目提交完成"));
        }
    }

    Components.CscSectionHeader {
        Layout.fillWidth: true
        theme: root.theme
        title: root.theme.localized("Today's workflow", "今日工作流")
        subtitle: root.theme.localized(
            "Set up a project, choose preferences, then confirm with clear feedback.",
            "配置项目、选择偏好，再用明确反馈完成提交。")
        badge: root.theme.localized("Everyday controls", "常用控件")
    }

    Components.Card {
        theme: root.theme
        Layout.fillWidth: true
        radius: root.theme.radiusLarge
        shadowEnabled: false

        ColumnLayout {
            spacing: root.theme.spacingSmall

            Text {
                Layout.fillWidth: true
                text: root.theme.localized("Workbench status", "工作台状态")
                color: root.theme.textColor
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.fontSizeTitle
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                text: root.theme.localized(
                    "Theme tokens drive every control on this page. Toast, Drawer and About live in the window chrome.",
                    "本页控件共用 Theme 令牌；Toast、Drawer 与 About 位于窗口壳层。")
                color: root.theme.secondaryTextColor
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.fontSizeBody
                wrapMode: Text.WordWrap
                lineHeight: 1.35
            }

            Text {
                Layout.fillWidth: true
                text: (root.theme.isDark
                       ? root.theme.localized("Dark", "深色")
                       : root.theme.localized("Light", "浅色"))
                      + " · "
                      + (root.theme.isChinese
                         ? root.theme.localized("Chinese", "中文")
                         : root.theme.localized("English", "英文"))
                      + " · Theme"
                color: root.theme.focusColor
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.fontSizeCaption
                font.weight: Font.DemiBold
            }
        }
    }

    Components.CscDemoSection {
        Layout.fillWidth: true
        theme: root.theme
        title: root.theme.localized("Quick actions", "快捷操作")
        description: root.theme.localized(
            "Primary work sits first; secondary and disabled states stay easy to scan.",
            "主要操作优先展示，次要与禁用状态一目了然。")

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: root.theme ? root.theme.spacingMedium : 12

            Components.Button {
                theme: root.theme
                size: "s"
                text: root.theme.isDark
                      ? root.theme.localized("Use light theme", "使用浅色主题")
                      : root.theme.localized("Use dark theme", "使用深色主题")
                iconCharacter: root.theme && root.theme.isDark ? "\uf186" : "\uf185"
                onClicked: {
                    root.theme.toggleTheme();
                    if (root.toastRef)
                        root.toastRef.show(root.theme.isDark
                                           ? root.theme.localized("Dark theme enabled", "已启用深色主题")
                                           : root.theme.localized("Light theme enabled", "已启用浅色主题"));
                    root.log(root.theme.localized("Theme changed", "主题已更改"));
                }
            }

            Components.Button {
                theme: root.theme
                size: "s"
                text: root.theme.localized("Save draft", "保存草稿")
                iconCharacter: "\uf0c7"
                onClicked: {
                    if (root.toastRef)
                        root.toastRef.show(root.theme.localized("Draft saved", "草稿已保存"));
                    root.log(root.theme.localized("Draft saved", "草稿已保存"));
                }
            }

            Components.Button {
                theme: root.theme
                size: "s"
                text: root.theme.localized("Show toast", "显示提示")
                iconCharacter: "\uf0f3"
                onClicked: {
                    if (root.toastRef)
                        root.toastRef.show(root.theme.localized("Action completed", "操作已完成"));
                    root.log(root.theme.localized("Toast requested", "已请求提示"));
                }
            }

            Components.Button {
                theme: root.theme
                size: "s"
                text: root.theme.localized("Settings", "设置")
                iconCharacter: "\uf013"
                onClicked: root.log(root.theme.localized("Settings action", "设置操作"))
            }

            Components.Button {
                theme: root.theme
                size: "s"
                text: root.theme.localized("Disabled", "已禁用")
                enabled: false
                iconCharacter: "\uf05e"
            }

            Components.SwitchButton {
                theme: root.theme
                size: "s"
                text: root.theme.localized("Live preview", "实时预览")
                onToggled: function (value) {
                    root.log(root.theme.localized("Live preview: ", "实时预览：") + value);
                }
            }

            Components.MenuButton {
                theme: root.theme
                text: root.theme.localized("More actions", "更多操作")
                menuModel: [
                    root.theme.localized("Duplicate", "复制"),
                    root.theme.localized("Rename", "重命名"),
                    root.theme.localized("Archive", "归档")
                ]
                onItemClicked: function (index, label) {
                    root.log(root.theme.localized("Menu action: ", "菜单操作：") + label);
                }
            }
        }
    }

    Components.CscDemoSection {
        Layout.fillWidth: true
        theme: root.theme
        title: root.theme.localized("Project setup", "项目配置")
        description: root.theme.localized(
            "Visible labels, sensible defaults, and progressive choices.",
            "可见标签、合理默认值，以及循序渐进的选项。")

        GridLayout {
            id: formGrid
            Layout.fillWidth: true
            columns: root.width >= 720 ? 2 : 1
            columnSpacing: root.theme ? root.theme.spacingLarge : 16
            rowSpacing: root.theme ? root.theme.spacingLarge : 16

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: root.theme ? root.theme.spacingXs : 4

                Text {
                    id: projectNameLabel
                    Layout.fillWidth: true
                    text: root.theme.localized("Project name", "项目名称")
                    color: root.theme.textColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeBody
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    Accessible.role: Accessible.StaticText
                }

                Components.Input {
                    theme: root.theme
                    Layout.fillWidth: true
                    placeholderText: root.theme.localized("e.g. Evolve UI", "例如 Evolve UI")
                    accessibleName: projectNameLabel.text
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: root.theme ? root.theme.spacingXs : 4

                Text {
                    id: accessTokenLabel
                    Layout.fillWidth: true
                    text: root.theme.localized("Access token", "访问令牌")
                    color: root.theme.textColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeBody
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    Accessible.role: Accessible.StaticText
                }

                Components.Input {
                    theme: root.theme
                    Layout.fillWidth: true
                    placeholderText: root.theme.localized("Paste token", "粘贴令牌")
                    passwordField: true
                    accessibleName: accessTokenLabel.text
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: root.theme ? root.theme.spacingXs : 4

                Text {
                    Layout.fillWidth: true
                    text: root.theme.localized("Appearance", "外观模式")
                    color: root.theme.textColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeBody
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                }

                Components.Dropdown {
                    theme: root.theme
                    Layout.fillWidth: true
                    model: [
                        { text: root.theme.localized("Automatic", "自动") },
                        { text: root.theme.localized("Light", "浅色") },
                        { text: root.theme.localized("Dark", "深色") }
                    ]
                    onSelectionChanged: function (index, data) {
                        root.log(root.theme.localized("Appearance selection: ", "外观选择：") + index);
                    }
                }
            }

            Components.Slider {
                theme: root.theme
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBottom
                text: root.theme.localized("Opacity", "不透明度")
                minimumValue: 0
                maximumValue: 100
                stepSize: 5
                value: 80
                onUserValueChanged: function (value) {
                    root.log(root.theme.localized("Opacity: ", "不透明度：") + value);
                }
            }

            Components.CheckBox {
                theme: root.theme
                Layout.fillWidth: true
                Layout.columnSpan: formGrid.columns
                model: [
                    { text: root.theme.localized("Keyboard navigation", "键盘导航") },
                    { text: root.theme.localized("Screen reader labels", "屏幕阅读器标签") },
                    { text: root.theme.localized("Reduced motion", "减少动态效果") }
                ]
                onSelectionChanged: function (indexes) {
                    root.log(root.theme.localized("Checked items: ", "已选项目：") + indexes.length);
                }
            }

            Components.RadioButton {
                theme: root.theme
                Layout.fillWidth: true
                Layout.columnSpan: formGrid.columns
                model: [
                    { text: root.theme.localized("Compact density", "紧凑密度") },
                    { text: root.theme.localized("Comfortable density", "舒适密度") }
                ]
                onSelectionChanged: function (index) {
                    root.log(root.theme.localized("Density: ", "密度：") + index);
                }
            }
        }
    }

    Components.CscDemoSection {
        Layout.fillWidth: true
        theme: root.theme
        title: root.theme.localized("Status and discovery", "状态与发现")
        description: root.theme.localized(
            "Tags, progress, search and empty states for everyday task flows.",
            "标签、进度、搜索与空状态，覆盖日常任务流。")

        ColumnLayout {
            Layout.fillWidth: true
            spacing: root.theme ? root.theme.spacingLarge : 16

            Components.SearchField {
                theme: root.theme
                Layout.fillWidth: true
                Layout.maximumWidth: 420
                placeholderText: root.theme.localized("Search projects, owners, tags…", "搜索项目、负责人、标签…")
                onSubmitted: function (text) {
                    if (root.toastRef)
                        root.toastRef.show(root.theme.localized("Search: ", "搜索：") + text);
                    root.log(root.theme.localized("Search: ", "搜索：") + text);
                }
            }

            Components.Divider {
                theme: root.theme
                Layout.fillWidth: true
                label: root.theme.localized("Project health", "项目健康度")
            }

            Flow {
                Layout.fillWidth: true
                spacing: root.theme ? root.theme.spacingSmall : 8

                Components.Tag {
                    theme: root.theme
                    text: root.theme.localized("Stable", "稳定")
                    tone: "success"
                }
                Components.Tag {
                    theme: root.theme
                    text: root.theme.localized("In review", "评审中")
                    tone: "warning"
                }
                Components.Tag {
                    theme: root.theme
                    text: root.theme.localized("Blocked", "受阻")
                    tone: "danger"
                }
                Components.Tag {
                    theme: root.theme
                    text: root.theme.localized("Docs", "文档")
                    tone: "info"
                }
                Components.Tag {
                    theme: root.theme
                    text: root.theme.localized("Core", "核心")
                    tone: "accent"
                    filled: true
                }
            }

            Components.ProgressBar {
                theme: root.theme
                Layout.fillWidth: true
                Layout.maximumWidth: 480
                text: root.theme.localized("Sprint completion", "迭代完成度")
                value: 68
                tone: "accent"
            }

            Components.ProgressBar {
                theme: root.theme
                Layout.fillWidth: true
                Layout.maximumWidth: 480
                text: root.theme.localized("Background sync", "后台同步")
                indeterminate: true
                showValueLabel: false
                tone: "info"
            }

            Components.Card {
                theme: root.theme
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                radius: root.theme.radiusLarge
                shadowEnabled: false

                Components.EmptyState {
                    anchors.fill: parent
                    theme: root.theme
                    title: root.theme.localized("No matching tasks", "没有匹配的任务")
                    description: root.theme.localized(
                        "Try another filter, or create a task to get started.",
                        "试试其他筛选，或新建一个任务开始。")
                    actionText: root.theme.localized("New task", "新建任务")
                    iconCharacter: ""
                    onActionClicked: {
                        if (root.toastRef)
                            root.toastRef.show(root.theme.localized("Create task", "创建任务"));
                        root.log(root.theme.localized("Empty state action", "空状态操作"));
                    }
                }
            }
        }
    }

    Components.CscDemoSection {
        Layout.fillWidth: true
        theme: root.theme
        title: root.theme.localized("Confirm and feedback", "确认与反馈")
        description: root.theme.localized(
            "Loading, alerts and expandable notes close the loop without noise.",
            "加载、提示框与可展开说明形成闭环，但不喧宾夺主。")

        ColumnLayout {
            Layout.fillWidth: true
            spacing: root.theme ? root.theme.spacingLarge : 16

            Flow {
                Layout.fillWidth: true
                spacing: root.theme ? root.theme.spacingMedium : 12

                Components.Button {
                    theme: root.theme
                    size: "s"
                    text: root.theme.localized("Submit project", "提交项目")
                    iconCharacter: "\uf1d8"
                    containerColor: root.theme.focusColor
                    hoverColor: Qt.lighter(root.theme.focusColor, root.theme.isDark ? 1.25 : 1.12)
                    textColor: root.theme.onAccentColor
                    iconColor: root.theme.onAccentColor
                    onClicked: root.submitProject()
                }

                Components.Button {
                    theme: root.theme
                    size: "s"
                    text: root.theme.localized("Open alert", "打开提示框")
                    iconCharacter: "\uf071"
                    onClicked: alertDialog.open()
                }

                Components.Button {
                    theme: root.theme
                    size: "s"
                    text: root.theme.localized("Toggle loading", "切换加载")
                    iconCharacter: "\uf110"
                    onClicked: loader.running = !loader.running
                }
            }

            Components.LoadingIndicator {
                id: loader
                theme: root.theme
                visible: running
                running: false
                size: 28
                Layout.alignment: Qt.AlignLeft
            }

            Components.Accordion {
                theme: root.theme
                Layout.fillWidth: true
                Layout.maximumWidth: 640
                title: root.theme.localized("Implementation notes", "实现说明")

                Text {
                    Layout.fillWidth: true
                    text: root.theme.localized(
                        "Every control exposes stable default, hover, focus and disabled states. The inspector can draw layout bounds and disable motion.",
                        "每个控件都为默认、悬停、焦点和禁用状态提供稳定视觉表现。检查器可绘制布局边界并关闭动态效果。")
                    color: root.theme.textColor
                    wrapMode: Text.WordWrap
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeBody
                    lineHeight: 1.4
                }
            }
        }
    }

    Components.AlertDialog {
        id: alertDialog
        theme: root.theme
        title: root.theme.localized("Confirm action", "确认操作")
        message: root.theme.localized(
            "This example demonstrates a recoverable confirmation flow.",
            "此示例演示了可撤回的确认流程。")
        confirmText: root.theme.localized("Continue", "继续")
        cancelText: root.theme.localized("Cancel", "取消")
        onConfirm: root.log(root.theme.localized("Alert confirmed", "已确认提示"))
        onCancel: root.log(root.theme.localized("Alert cancelled", "已取消提示"))
    }
}
