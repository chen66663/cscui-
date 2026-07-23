import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import cscui

Page {
    id: tasksPage
    required property var theme
    background: Rectangle {
        color: "transparent"
    }

    property var completedStates: [true, false, false, false, false, false]
    readonly property var taskItems: [
        { title: theme.localized("Review project requirements", "审核项目需求"), priority: "high" },
        { title: theme.localized("Design UI mockups", "设计界面原型"), priority: "high" },
        { title: theme.localized("Implement core logic", "实现核心逻辑"), priority: "medium" },
        { title: theme.localized("Unit testing", "单元测试"), priority: "medium" },
        { title: theme.localized("Documentation", "编写文档"), priority: "low" },
        { title: theme.localized("Client meeting", "客户会议"), priority: "high" }
    ]

    function toggleTask(taskIndex) {
        const nextStates = completedStates.slice()
        nextStates[taskIndex] = !nextStates[taskIndex]
        completedStates = nextStates
    }

    function priorityText(priority) {
        if (priority === "high")
            return theme.localized("High", "高")
        if (priority === "medium")
            return theme.localized("Medium", "中")
        return theme.localized("Low", "低")
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        Label {
            text: tasksPage.theme.localized("Tasks", "任务")
            font.pixelSize: 24
            font.bold: true
            color: theme.textColor
        }

        // Task List
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8
            
            model: tasksPage.taskItems

            delegate: Rectangle {
                width: ListView.view.width
                height: 50
                radius: 8
                color: theme.secondaryColor
                border.color: Qt.rgba(0,0,0,0.05)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 16

                    Rectangle {
                        width: 20
                        height: 20
                        radius: 4
                        border.color: theme.borderColor
                        color: tasksPage.completedStates[index] ? tasksPage.theme.focusColor : "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "\uf00c"
                            font.family: "Font Awesome 6 Free" 
                            font.styleName: "Solid"
                            visible: tasksPage.completedStates[index]
                            color: "white"
                            font.pixelSize: 12
                        }
                    }

                    Label {
                        text: modelData.title
                        color: tasksPage.theme.textColor
                        font.strikeout: tasksPage.completedStates[index]
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 60
                        height: 24
                        radius: 12
                        color: {
                            if (modelData.priority === "high") return Qt.rgba(1, 0, 0, 0.1)
                            if (modelData.priority === "medium") return Qt.rgba(1, 0.6, 0, 0.1)
                            return Qt.rgba(0, 0, 1, 0.1)
                        }
                        
                        Label {
                            anchors.centerIn: parent
                            text: tasksPage.priorityText(modelData.priority)
                            font.pixelSize: 10
                            color: {
                                if (modelData.priority === "high") return "red"
                                if (modelData.priority === "medium") return "orange"
                                return "blue"
                            }
                        }
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: tasksPage.toggleTask(index)
                }
            }
        }
    }
}
