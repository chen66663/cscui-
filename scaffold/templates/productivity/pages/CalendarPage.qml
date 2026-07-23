import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import cscui

Page {
    id: calendarPage
    required property var theme
    background: Rectangle {
        color: "transparent"
    }

    // 获取当前日期
    property var currentDate: new Date()
    property int currentYear: currentDate.getFullYear()
    property int currentMonth: currentDate.getMonth() // 0-11

    // 获取当月天数
    function getDaysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate()
    }

    // 获取当月第一天是星期几 (0-6, 0=Sunday)
    function getFirstDayOfMonth(year, month) {
        return new Date(year, month, 1).getDay()
    }

    property int daysInMonth: getDaysInMonth(currentYear, currentMonth)
    property int startDayOffset: getFirstDayOfMonth(currentYear, currentMonth)
    
    readonly property var weekdayNames: theme.isChinese
                                        ? ["日", "一", "二", "三", "四", "五", "六"]
                                        : ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            
            Label {
                text: calendarPage.theme.localized("Calendar", "日历")
                font.pixelSize: 24
                font.bold: true
                color: theme.textColor
                Layout.fillWidth: true
            }
            
            Label {
                text: calendarPage.currentDate.toLocaleString(calendarPage.theme.localeObject,
                                                               "MMMM yyyy")
                font.pixelSize: 16
                color: theme.focusColor
            }
        }

        GridLayout {
            columns: 7
            Layout.fillWidth: true
            Layout.fillHeight: true
            columnSpacing: 1
            rowSpacing: 1
            
            Repeater {
                model: calendarPage.weekdayNames
                Label {
                    text: modelData
                    font.bold: true
                    color: Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.6)
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                }
            }

            Repeater {
                model: 42
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: theme.secondaryColor
                    radius: 4
                    
                    // 计算实际日期：index - 偏移量 + 1
                    property int day: index - startDayOffset + 1
                    property bool isCurrentMonth: day > 0 && day <= daysInMonth
                    property bool isToday: isCurrentMonth && day === currentDate.getDate()
                    
                    opacity: isCurrentMonth ? 1.0 : 0.3
                    border.width: isToday ? 2 : 0
                    border.color: theme.focusColor
                    
                    Label {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 8
                        text: isCurrentMonth ? day : ""
                        color: isToday ? theme.focusColor : theme.textColor
                        font.bold: isToday
                        visible: isCurrentMonth
                    }
                    
                    // 随机日程 (仅在当月有效日期显示)
                    Rectangle {
                        visible: isCurrentMonth && (day % 7 === 2 || day % 10 === 5) // 随机逻辑
                        width: parent.width - 10
                        height: 18
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottomMargin: 6
                        radius: 3
                        color: theme.focusColor
                        
                        Label {
                            text: calendarPage.theme.localized("Meeting", "会议")
                            font.pixelSize: 10
                            color: "white"
                            anchors.centerIn: parent
                        }
                    }
                }
            }
        }
    }
}
