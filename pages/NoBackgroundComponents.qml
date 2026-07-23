pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../components" as Components

// 日程与资料：列表、导航、日历、备注、表格与本地媒体构成内容中心。
ColumnLayout {
    id: root

    property var theme: fallbackTheme
    property var toastRef: null
    property int availableWidth: 0
    property int contentTab: 0
    signal eventLogged(string message)

    Components.Theme {
        id: fallbackTheme
    }

    width: availableWidth > 0 ? availableWidth : 720
    spacing: theme ? theme.spacingXLarge : 24

    function log(message) {
        eventLogged(message);
    }

    Components.CscSectionHeader {
        Layout.fillWidth: true
        theme: root.theme
        title: root.theme.localized("Schedule and content", "日程与资料")
        subtitle: root.theme.localized(
            "Browse people, dates, notes and tables in one focused workspace.",
            "在同一工作区中浏览人员、日期、备注与表格。")
        badge: root.theme.localized("Content hub", "内容中心")
    }

    // 顶部：负责人卡片 + 分区导航
    Components.CscDemoSection {
        Layout.fillWidth: true
        theme: root.theme
        title: root.theme.localized("People and sections", "人员与分区")
        description: root.theme.localized(
            "Identity, navigation and destination lists stay adjacent for quick orientation.",
            "身份、导航与目标列表相邻排布，便于快速定位。")

        GridLayout {
            Layout.fillWidth: true
            columns: root.width >= 900 ? 2 : 1
            columnSpacing: root.theme ? root.theme.spacingLarge : 16
            rowSpacing: root.theme ? root.theme.spacingLarge : 16

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: root.theme ? root.theme.spacingMedium : 12

                Components.NavBar {
                    theme: root.theme
                    Layout.fillWidth: true
                    model: [
                        { display: root.theme.localized("Summary", "摘要"), iconChar: "\uf201" },
                        { display: root.theme.localized("Activity", "活动"), iconChar: "\uf1da" },
                        { display: root.theme.localized("Settings", "设置"), iconChar: "\uf013" }
                    ]
                    onItemClicked: function (index, data) {
                        root.contentTab = index;
                        root.log(root.theme.localized("Navigation index: ", "导航索引：") + index);
                    }
                }

                Components.Card {
                    theme: root.theme
                    Layout.fillWidth: true
                    radius: root.theme.radiusLarge
                    shadowEnabled: false

                    RowLayout {
                        spacing: root.theme.spacingMedium

                        Components.Avatar {
                            theme: root.theme
                            avatarSource: "qrc:/cscui/fonts/pic/avatar.png"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: root.theme.spacingXs

                            Text {
                                text: root.theme.localized("Component owner", "组件负责人")
                                color: root.theme.textColor
                                font.family: root.theme.fontFamily
                                font.pixelSize: root.theme.fontSizeTitle
                                font.weight: Font.DemiBold
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.theme.localized(
                                    "Reusable surfaces keep content, state and actions visually separate.",
                                    "可复用界面将内容、状态与操作在视觉上清晰分隔。")
                                color: root.theme.secondaryTextColor
                                font.family: root.theme.fontFamily
                                font.pixelSize: root.theme.fontSizeBody
                                wrapMode: Text.WordWrap
                                lineHeight: 1.35
                            }
                        }
                    }
                }
            }

            Components.List {
                theme: root.theme
                Layout.fillWidth: true
                Layout.preferredHeight: 250
                Layout.minimumWidth: 0
                model: [
                    { display: root.theme.localized("Overview", "概览"), iconChar: "\uf015" },
                    { display: root.theme.localized("Components", "组件"), iconChar: "\uf12e" },
                    { display: root.theme.localized("Accessibility", "无障碍"), iconChar: "\uf29a" },
                    { display: root.theme.localized("Diagnostics", "诊断"), iconChar: "\uf188" }
                ]
                onItemClicked: function (index, label) {
                    root.log(root.theme.localized("List item: ", "列表项目：") + label);
                }
            }
        }
    }

    // 日期：日历 + 日期条
    Components.CscDemoSection {
        Layout.fillWidth: true
        theme: root.theme
        title: root.theme.localized("Plan the week", "安排本周")
        description: root.theme.localized(
            "Pick a day on the calendar or skim the upcoming strip.",
            "在日历中选日，或在近期日期条中快速浏览。")

        GridLayout {
            Layout.fillWidth: true
            columns: root.width >= 860 ? 2 : 1
            columnSpacing: root.theme ? root.theme.spacingLarge : 16
            rowSpacing: root.theme ? root.theme.spacingLarge : 16

            Components.Calendar {
                theme: root.theme
                Layout.fillWidth: true
                Layout.maximumWidth: 400
                Layout.alignment: Qt.AlignTop
                onDateClicked: function (clickedDate) {
                    root.log(root.theme.localized("Calendar date: ", "日历日期：")
                             + Qt.formatDate(clickedDate, "yyyy-MM-dd"));
                    if (root.toastRef)
                        root.toastRef.show(root.theme.localized("Date selected", "已选择日期")
                                           + " · " + Qt.formatDate(clickedDate, "MM-dd"));
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignTop
                spacing: root.theme.spacingMedium

                Text {
                    Layout.fillWidth: true
                    text: root.theme.localized("Upcoming dates", "近期日期")
                    color: root.theme.textColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeTitle
                    font.weight: Font.DemiBold
                }

                Components.SimpleDatePicker {
                    theme: root.theme
                    Layout.fillWidth: true
                    onDateClicked: function (clickedDate) {
                        root.log(root.theme.localized("Date strip: ", "日期条：")
                                 + Qt.formatDate(clickedDate, "yyyy-MM-dd"));
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.theme.localized(
                        "Selected dates feed notes and the task table below.",
                        "选中的日期会同步到下方备注与任务表。")
                    color: root.theme.secondaryTextColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeBody
                    wrapMode: Text.WordWrap
                    lineHeight: 1.35
                }
            }
        }
    }

    // 书写表面
    Components.CscDemoSection {
        Layout.fillWidth: true
        theme: root.theme
        title: root.theme.localized("Notes and preferences", "备注与偏好")
        description: root.theme.localized(
            "Capture context beside lightweight editing toggles.",
            "在轻量编辑开关旁记录上下文。")

        GridLayout {
            Layout.fillWidth: true
            columns: root.width >= 860 ? 2 : 1
            columnSpacing: root.theme ? root.theme.spacingLarge : 16
            rowSpacing: root.theme ? root.theme.spacingLarge : 16

            Components.CardWithTextArea {
                theme: root.theme
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                Layout.minimumWidth: 0
                shadowEnabled: false
                radius: root.theme.radiusLarge
                accessibleName: root.theme.localized("Component notes", "组件备注")
                accessibleDescription: root.theme.localized(
                    "A multi-line note field for the selected component.",
                    "用于记录当前组件的多行备注。")
                placeholderText: root.theme.localized(
                    "Capture a note about this component…",
                    "记录关于此组件的备注…")
                text: root.theme.localized(
                    "Keyboard focus, readable spacing and a stable scroll region.",
                    "键盘焦点、舒适间距与稳定的滚动区域。")
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignTop
                spacing: root.theme.spacingSmall

                Text {
                    Layout.fillWidth: true
                    text: root.theme.localized("Editing states", "编辑状态")
                    color: root.theme.textColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeTitle
                    font.weight: Font.DemiBold
                }

                Components.CheckBox {
                    theme: root.theme
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    model: [
                        { text: root.theme.localized("Autosave draft", "自动保存草稿") },
                        { text: root.theme.localized("Keep focus ring visible", "保持焦点环可见") }
                    ]
                    onSelectionChanged: function (indexes) {
                        root.log(root.theme.localized("Editor options: ", "编辑选项：") + indexes.length);
                    }
                }
            }
        }
    }

    // 任务表
    Components.CscDemoSection {
        Layout.fillWidth: true
        theme: root.theme
        title: root.theme.localized("Component inventory", "组件清单")
        description: root.theme.localized(
            "Selectable rows with stable column alignment for daily triage.",
            "可选择行与稳定列对齐，便于每日分拣。")

        Components.DataTable {
            theme: root.theme
            Layout.fillWidth: true
            Layout.preferredHeight: 320
            selectable: true
            headers: [
                { key: "index", label: "#" },
                { key: "component", label: root.theme.localized("Component", "组件") },
                { key: "category", label: root.theme.localized("Category", "类别") },
                { key: "status", label: root.theme.localized("Status", "状态") },
                { key: "owner", label: root.theme.localized("Owner", "负责人") }
            ]
            model: [
                {
                    component: root.theme.localized("Button", "按钮"),
                    category: root.theme.localized("Control", "控件"),
                    status: root.theme.localized("Stable", "稳定"),
                    owner: root.theme.localized("Core", "核心"),
                    checked: true
                },
                {
                    component: root.theme.localized("Calendar", "日历"),
                    category: root.theme.localized("Input", "输入"),
                    status: root.theme.localized("Stable", "稳定"),
                    owner: root.theme.localized("Core", "核心"),
                    checked: false
                },
                {
                    component: root.theme.localized("Area chart", "面积图"),
                    category: root.theme.localized("Data", "数据"),
                    status: root.theme.localized("Preview", "预览"),
                    owner: root.theme.localized("Charts", "图表"),
                    checked: false
                },
                {
                    component: root.theme.localized("Music player", "音乐播放器"),
                    category: root.theme.localized("Media", "媒体"),
                    status: root.theme.localized("Preview", "预览"),
                    owner: root.theme.localized("Media", "媒体"),
                    checked: false
                },
                {
                    component: root.theme.localized("Inspector", "检查器"),
                    category: root.theme.localized("Developer", "开发者"),
                    status: root.theme.localized("Stable", "稳定"),
                    owner: root.theme.localized("Platform", "平台"),
                    checked: true
                }
            ]
            onRowClicked: function (index, rowData) {
                root.log(root.theme.localized("Table row: ", "表格行：") + index);
            }
            onCheckStateChanged: function (index, rowData, isChecked) {
                root.log(root.theme.localized("Table selection ", "表格选择 ") + index + ": " + isChecked);
            }
        }
    }

    // 本地媒体
    Components.CscDemoSection {
        Layout.fillWidth: true
        theme: root.theme
        title: root.theme.localized("Reference gallery", "参考图库")
        description: root.theme.localized(
            "Bundled assets for reliable offline preview.",
            "使用内置资源，离线预览同样可靠。")

        Components.Carousel {
            theme: root.theme
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(320, Math.max(220, width * 0.45))
            model: ["qrc:/cscui/fonts/pic/01.jpg", "qrc:/cscui/fonts/pic/02.jpg"]
            onCurrentIndexChanged: root.log(root.theme.localized("Carousel index: ", "轮播索引：") + currentIndex)
        }
    }
}
