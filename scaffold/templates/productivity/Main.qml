import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import cscui
import "pages"

ApplicationWindow {
    id: mainWindow
    width: 1280
    height: 720
    visible: true
    title: "{{PROJECT_NAME}}"

    color: theme.primaryColor

    FontLoader {
        id: iconFont
        source: "qrc:/cscui/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    Theme { id: theme }
    readonly property var appTheme: theme
    readonly property var topMenuLabels: [
        appTheme.localized("File", "文件"),
        appTheme.localized("Edit", "编辑"),
        appTheme.localized("View", "视图"),
        appTheme.localized("Help", "帮助")
    ]
    readonly property var topMenuItems: [
        appTheme.localized("Option 1", "选项 1"),
        appTheme.localized("Option 2", "选项 2"),
        appTheme.localized("Option 3", "选项 3"),
        appTheme.localized("Settings", "设置"),
        appTheme.localized("Exit", "退出")
    ]
    readonly property var navigationModel: [
        { display: appTheme.localized("Dashboard", "仪表盘"), iconChar: "\uf015" },
        { display: appTheme.localized("Projects", "项目"), iconChar: "\uf07b" },
        { display: appTheme.localized("Tasks", "任务"), iconChar: "\uf0ae" },
        { display: appTheme.localized("Calendar", "日历"), iconChar: "\uf073" },
        { display: appTheme.localized("Reports", "报表"), iconChar: "\uf080" }
    ]

    // Main Layout
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: theme.secondaryColor
            
            // Bottom border for separation
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Qt.rgba(0,0,0,0.1)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 16

                // App Title
                Label {
                    text: "cscui"
                    font.bold: true
                    font.pixelSize: 16
                    color: theme.textColor
                    Layout.alignment: Qt.AlignVCenter
                }

                // Vertical Divider
                Rectangle {
                    Layout.fillHeight: true
                    Layout.topMargin: 12
                    Layout.bottomMargin: 12
                    width: 1
                    color: Qt.rgba(0,0,0,0.1)
                }

                // Menu Buttons
                Row {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter
                    
                    Repeater {
                        model: mainWindow.topMenuLabels
                        MenuButton {
                            theme: mainWindow.appTheme
                            text: modelData
                            menuModel: mainWindow.topMenuItems
                            backgroundVisible: false
                            hoverColor: Qt.rgba(0,0,0,0.05)
                            textColor: theme.textColor
                            
                            onItemClicked: (index, itemText) => {
                                console.log("Clicked", text, ":", itemText)
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true } // Spacer

                // Right-side controls (e.g., User Profile, Notifications)
                Row {
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter
                    
                    Button {
                        theme: mainWindow.appTheme
                        text: ""
                        iconCharacter: "\uf0f3" // Bell icon
                        accessibleName: mainWindow.appTheme.localized("Notifications", "通知")
                        width: 32
                        height: 32
                        radius: 16
                        backgroundVisible: false
                        hoverColor: Qt.rgba(0,0,0,0.05)
                        shadowEnabled: false
                    }
                    
                    Button {
                        theme: mainWindow.appTheme
                        text: ""
                        iconCharacter: "\uf007" // User icon
                        accessibleName: mainWindow.appTheme.localized("User profile", "用户资料")
                        width: 32
                        height: 32
                        radius: 16
                        backgroundVisible: false
                        hoverColor: Qt.rgba(0,0,0,0.05)
                        shadowEnabled: false
                    }
                }
            }
        }

        // Content Area with Sidebars
        SplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            handle: Rectangle {
                implicitWidth: 4
                color: "transparent"
                
                Rectangle {
                    anchors.centerIn: parent
                    width: 1
                    height: parent.height
                    color: Qt.rgba(0,0,0,0.1)
                }
            }

            // Left Sidebar (Navigation)
            Pane {
                id: leftSidebar
                implicitWidth: 240
                SplitView.minimumWidth: 200
                SplitView.maximumWidth: 320
                padding: 0
                background: Rectangle {
                    color: theme.secondaryColor
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Sidebar Header/Section Title
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        
                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: mainWindow.appTheme.localized("MAIN MENU", "主菜单")
                            font.pixelSize: 11
                            font.bold: true
                            color: Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.5)
                        }
                    }

                    ListView {
                        id: navListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: mainWindow.navigationModel
                        clip: true
                        currentIndex: 0

                        delegate: Item {
                            id: navDelegate
                            width: ListView.view.width
                            height: 40
                            
                            property bool isSelected: ListView.view.currentIndex === index
                            property bool isHovered: false

                            scale: 1.0
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                            // Selection Background (fades in/out)
                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                radius: 6
                                color: theme.primaryColor
                                opacity: isSelected ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }
                            
                            // Hover Background (fades in/out)
                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                radius: 6
                                color: Qt.rgba(0,0,0,0.05)
                                opacity: isHovered && !isSelected ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            // Selection indicator
                            Rectangle {
                                width: 3
                                height: isSelected ? 20 : 0
                                radius: 1.5
                                color: theme.focusColor
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: isSelected ? 1 : 0
                                
                                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                anchors.rightMargin: 16
                                spacing: 12

                                Text {
                                    text: modelData.iconChar
                                    font.family: iconFont.name
                                    font.pixelSize: 16
                                    color: isSelected ? theme.textColor : Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.7)
                                    Layout.preferredWidth: 20
                                    horizontalAlignment: Text.AlignHCenter
                                    
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                Label {
                                    text: modelData.display
                                    color: isSelected ? theme.textColor : Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.7)
                                    font.bold: isSelected
                                    Layout.fillWidth: true
                                    
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: navDelegate.isHovered = true
                                onExited: navDelegate.isHovered = false
                                onPressed: navDelegate.scale = 0.96
                                onReleased: navDelegate.scale = 1.0
                                onCanceled: navDelegate.scale = 1.0
                                onClicked: {
                                    navListView.currentIndex = index
                                    contentStack.currentIndex = index
                                }
                            }
                        }
                    }
                    
                    // Bottom Section (Settings)
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        
                        Rectangle {
                            anchors.top: parent.top
                            width: parent.width
                            height: 1
                            color: Qt.rgba(0,0,0,0.05)
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            
                            Text {
                                text: "\uf013" // cog
                                font.family: iconFont.name
                                font.pixelSize: 16
                                color: theme.textColor
                            }
                            
                            Label {
                                text: mainWindow.appTheme.localized("Settings", "设置")
                                color: theme.textColor
                                Layout.fillWidth: true
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // Navigate to settings
                                contentStack.currentIndex = mainWindow.navigationModel.length
                            }
                        }
                    }
                }
            }

            // Center Content Area
            Rectangle {
                SplitView.minimumWidth: 300
                SplitView.preferredWidth: 600
                SplitView.fillWidth: true
                Layout.fillHeight: true
                color: theme.primaryColor
                clip: true

                StackLayout {
                    id: contentStack
                    anchors.fill: parent
                    anchors.margins: 0 // Add padding around content
                    currentIndex: 0
                    
                    // Dashboard
                    Item {
                        id: dashboardContainer
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        opacity: visible ? 1 : 0
                        transform: Translate {
                            y: dashboardContainer.visible ? 0 : 12
                            Behavior on y { NumberAnimation { duration: mainWindow.appTheme.durationNormal; easing.type: Easing.OutCubic } }
                        }
                        Behavior on opacity { NumberAnimation { duration: mainWindow.appTheme.durationNormal; easing.type: Easing.OutCubic } }
                        HomePage { 
                            id: homePage
                            anchors.fill: parent
                            theme: mainWindow.appTheme
                        }
                    }

                    // Projects
                    Item {
                        id: projectsContainer
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        opacity: visible ? 1 : 0
                        transform: Translate {
                            y: projectsContainer.visible ? 0 : 12
                            Behavior on y { NumberAnimation { duration: mainWindow.appTheme.durationNormal; easing.type: Easing.OutCubic } }
                        }
                        Behavior on opacity { NumberAnimation { duration: mainWindow.appTheme.durationNormal; easing.type: Easing.OutCubic } }
                        FavoritesPage {
                            anchors.fill: parent
                            theme: mainWindow.appTheme
                        }
                    }

                    // Tasks
                    Item {
                        id: tasksContainer
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        opacity: visible ? 1 : 0
                        transform: Translate {
                            y: tasksContainer.visible ? 0 : 12
                            Behavior on y { NumberAnimation { duration: mainWindow.appTheme.durationNormal; easing.type: Easing.OutCubic } }
                        }
                        Behavior on opacity { NumberAnimation { duration: mainWindow.appTheme.durationNormal; easing.type: Easing.OutCubic } }
                        TasksPage {
                            anchors.fill: parent
                            theme: mainWindow.appTheme
                        }
                    }

                    // Calendar
                    Item {
                        id: calendarContainer
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        opacity: visible ? 1 : 0
                        transform: Translate {
                            y: calendarContainer.visible ? 0 : 12
                            Behavior on y { NumberAnimation { duration: mainWindow.appTheme.durationNormal; easing.type: Easing.OutCubic } }
                        }
                        Behavior on opacity { NumberAnimation { duration: mainWindow.appTheme.durationNormal; easing.type: Easing.OutCubic } }
                        CalendarPage {
                            anchors.fill: parent
                            theme: mainWindow.appTheme
                        }
                    }
                    
                    // Reports
                    Item {
                        id: reportsContainer
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        opacity: visible ? 1 : 0
                        transform: Translate {
                            y: reportsContainer.visible ? 0 : 12
                            Behavior on y { NumberAnimation { duration: mainWindow.appTheme.durationNormal; easing.type: Easing.OutCubic } }
                        }
                        Behavior on opacity { NumberAnimation { duration: mainWindow.appTheme.durationNormal; easing.type: Easing.OutCubic } }
                        ReportsPage {
                            anchors.fill: parent
                            theme: mainWindow.appTheme
                            iconFontFamily: iconFont.name
                        }
                    }

                    // Settings (Accessed via bottom link)
                    Item {
                        id: settingsContainer
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        opacity: visible ? 1 : 0
                        transform: Translate {
                            y: settingsContainer.visible ? 0 : 12
                            Behavior on y { NumberAnimation { duration: mainWindow.appTheme.durationNormal; easing.type: Easing.OutCubic } }
                        }
                        Behavior on opacity { NumberAnimation { duration: mainWindow.appTheme.durationNormal; easing.type: Easing.OutCubic } }
                        SettingsPage { 
                            anchors.fill: parent
                            theme: mainWindow.appTheme
                            animWindowRef: homePage.animatedWindow 
                        }
                    }
                }
            }

            // Right Sidebar (Inspector/Details)
            Pane {
                id: rightSidebar
                implicitWidth: 260
                SplitView.minimumWidth: 200
                SplitView.maximumWidth: 400
                Layout.fillHeight: true
                padding: 0
                background: Rectangle {
                    color: theme.secondaryColor
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Header
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        color: "transparent"
                        
                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: mainWindow.appTheme.localized("PROPERTIES", "属性")
                            font.bold: true
                            font.pixelSize: 12
                            color: theme.textColor
                        }
                        
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: Qt.rgba(0,0,0,0.05)
                        }
                    }

                    // Content
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: availableWidth
                        
                        ColumnLayout {
                            width: parent.width
                            spacing: 24
                            
                            // Section 1
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.margins: 16
                                spacing: 8
                                
                                Label {
                                    text: mainWindow.appTheme.localized("Item Details", "项目详情")
                                    font.bold: true
                                    color: theme.textColor
                                    Layout.leftMargin: 16
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 100
                                    Layout.leftMargin: 16
                                    Layout.rightMargin: 16
                                    color: Qt.rgba(0,0,0,0.03)
                                    radius: 8
                                    border.color: Qt.rgba(0,0,0,0.05)
                                    
                                    Label {
                                        anchors.centerIn: parent
                                        text: mainWindow.appTheme.localized("No item selected", "未选择项目")
                                        color: Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.5)
                                    }
                                }
                            }
                            
                            // Section 2
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.margins: 16
                                spacing: 12
                                
                                Label {
                                    text: mainWindow.appTheme.localized("Metadata", "元数据")
                                    font.bold: true
                                    color: theme.textColor
                                    Layout.leftMargin: 16
                                }
                                
                                GridLayout {
                                    columns: 2
                                    rowSpacing: 8
                                    columnSpacing: 16
                                    Layout.leftMargin: 16
                                    Layout.rightMargin: 16
                                    
                                    Label { text: mainWindow.appTheme.localized("Created:", "创建时间："); color: Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.6) }
                                    Label { text: "2023-10-27"; color: theme.textColor }
                                    
                                    Label { text: mainWindow.appTheme.localized("Author:", "作者："); color: Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.6) }
                                    Label { text: mainWindow.appTheme.localized("Admin", "管理员"); color: theme.textColor }
                                    
                                    Label { text: mainWindow.appTheme.localized("Status:", "状态："); color: Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.6) }
                                    Label { text: mainWindow.appTheme.localized("Active", "启用"); color: theme.focusColor; font.bold: true }
                                }
                            }
                            
                            Item { Layout.fillHeight: true } // Spacer
                        }
                    }

                    // Footer Actions
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        color: "transparent"
                        
                        Rectangle {
                            anchors.top: parent.top
                            width: parent.width
                            height: 1
                            color: Qt.rgba(0,0,0,0.05)
                        }
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 10
                            
                            Button {
                                theme: mainWindow.appTheme
                                text: mainWindow.appTheme.localized("Cancel", "取消")
                                size: "xs"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                backgroundVisible: false
                                shadowEnabled: false
                                radius: 6
                            }
                            
                            Button {
                                theme: mainWindow.appTheme
                                text: mainWindow.appTheme.localized("Apply", "应用")
                                size: "xs"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                containerColor: theme.focusColor
                                textColor: "white"
                                radius: 6
                                shadowEnabled: true
                            }
                        }
                    }
                }
            }
        }
    }
}
