pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

// Month calendar with a stable six-week grid. Each generated cell always has a
// valid dateValue, including leading/trailing days from adjacent months.
FocusScope {
    id: root

    property var theme: null

    property bool backgroundVisible: true
    property real radius: theme ? (theme.radiusLarge || 12) : 12
    property int padding: 12
    property bool shadowEnabled: true
    property date selectedDate: new Date()
    signal dateClicked(date clickedDate)
    property int currentYear: root.selectedDate.getFullYear()
    property int currentMonth: root.selectedDate.getMonth()
    property var dayModel: []
    property string accessibleName: theme ? theme.localized("Calendar", "日历") : "Calendar"
    property int cellSize: 32

    implicitWidth: Math.max(260, root.padding * 2 + root.cellSize * 7 + 24)
    implicitHeight: calendarLayout.implicitHeight + root.padding * 2
    activeFocusOnTab: true
    opacity: root.enabled ? 1 : 0.45

    Accessible.role: Accessible.Table
    Accessible.name: root.accessibleName

    function sameDate(first, second) {
        return first instanceof Date && second instanceof Date && first.getFullYear() === second.getFullYear() && first.getMonth() === second.getMonth() && first.getDate() === second.getDate();
    }

    function generateCalendarModel() {
        var result = [];
        var first = new Date(root.currentYear, root.currentMonth, 1);
        var firstDay = first.getDay();
        var start = new Date(root.currentYear, root.currentMonth, 1 - firstDay);
        var today = new Date();
        for (var i = 0; i < 42; ++i) {
            var dateValue = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
            result.push({
                day: dateValue.getDate(),
                isCurrentMonth: dateValue.getMonth() === root.currentMonth && dateValue.getFullYear() === root.currentYear,
                isToday: root.sameDate(dateValue, today),
                dateValue: dateValue
            });
        }
        root.dayModel = result;
    }

    function goToPrevMonth() {
        if (root.currentMonth === 0) {
            root.currentMonth = 11;
            root.currentYear -= 1;
        } else {
            root.currentMonth -= 1;
        }
    }

    function goToNextMonth() {
        if (root.currentMonth === 11) {
            root.currentMonth = 0;
            root.currentYear += 1;
        } else {
            root.currentMonth += 1;
        }
    }

    function selectDate(dateValue) {
        if (!(dateValue instanceof Date) || !root.enabled)
            return;
        root.selectedDate = new Date(dateValue);
        root.currentYear = root.selectedDate.getFullYear();
        root.currentMonth = root.selectedDate.getMonth();
        root.dateClicked(root.selectedDate);
    }

    Component.onCompleted: root.generateCalendarModel()
    onCurrentMonthChanged: root.generateCalendarModel()
    onCurrentYearChanged: root.generateCalendarModel()
    onSelectedDateChanged: {
        if (root.selectedDate instanceof Date && (root.selectedDate.getFullYear() !== root.currentYear || root.selectedDate.getMonth() !== root.currentMonth)) {
            root.currentYear = root.selectedDate.getFullYear();
            root.currentMonth = root.selectedDate.getMonth();
        }
    }

    FontLoader {
        id: iconFont
        source: root.theme ? root.theme.iconSource() : "qrc:/cscui/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    MultiEffect {
        source: surface
        anchors.fill: surface
        visible: root.backgroundVisible && root.shadowEnabled
        shadowEnabled: visible
        shadowColor: theme ? theme.shadowColor : "#24000000"
        shadowBlur: theme ? theme.shadowBlur : 0.25
        shadowHorizontalOffset: theme ? theme.shadowXOffset : 0
        shadowVerticalOffset: theme ? theme.shadowYOffset : 2
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: Math.max(0, root.radius)
        visible: root.backgroundVisible
        color: theme ? theme.secondaryColor : "#FFFFFF"
    }

    ColumnLayout {
        id: calendarLayout
        anchors.fill: parent
        anchors.margins: Math.max(0, root.padding)
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 36

            FocusScope {
                id: previousButton
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: theme ? theme.localized("Previous month", "上个月") : "Previous month"

                Text {
                    anchors.centerIn: parent
                    text: "\uf053"
                    color: theme ? theme.focusColor : "#007AFF"
                    font.family: root.theme ? root.theme.iconFamily(iconFont.name) : iconFont.name
                    font.pixelSize: 14
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: root.enabled
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.goToPrevMonth()
                }
                Keys.onSpacePressed: {
                    event.accepted = true;
                    root.goToPrevMonth();
                }
                Keys.onReturnPressed: {
                    event.accepted = true;
                    root.goToPrevMonth();
                }
            }

            Text {
                Layout.fillWidth: true
                text: theme && theme.isChinese
                      ? root.currentYear + "年" + (root.currentMonth + 1) + "月"
                      : new Date(root.currentYear, root.currentMonth, 1).toLocaleDateString(theme ? theme.localeObject : Qt.locale(), "MMMM yyyy")
                color: theme ? theme.textColor : "#1D1D1F"
                font.family: theme ? theme.fontFamily : "sans-serif"
                font.pixelSize: 16
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            FocusScope {
                id: nextButton
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: theme ? theme.localized("Next month", "下个月") : "Next month"

                Text {
                    anchors.centerIn: parent
                    text: "\uf054"
                    color: theme ? theme.focusColor : "#007AFF"
                    font.family: root.theme ? root.theme.iconFamily(iconFont.name) : iconFont.name
                    font.pixelSize: 14
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: root.enabled
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.goToNextMonth()
                }
                Keys.onSpacePressed: {
                    event.accepted = true;
                    root.goToNextMonth();
                }
                Keys.onReturnPressed: {
                    event.accepted = true;
                    root.goToNextMonth();
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: 0
            rowSpacing: 0

            Repeater {
                model: theme && theme.isChinese
                       ? ["日", "一", "二", "三", "四", "五", "六"]
                       : ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                delegate: Text {
                    required property string modelData
                    text: modelData
                    color: theme ? theme.tertiaryTextColor : "#6E6E73"
                    font.family: theme ? theme.fontFamily : "sans-serif"
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                }
            }
        }

        GridLayout {
            id: dayGrid
            Layout.fillWidth: true
            Layout.preferredHeight: root.cellSize * 6 + rowSpacing * 5
            columns: 7
            columnSpacing: 2
            rowSpacing: 2

            Repeater {
                model: root.dayModel
                delegate: FocusScope {
                    id: dayCell
                    required property int index
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: root.cellSize
                    Layout.minimumWidth: root.cellSize
                    activeFocusOnTab: true
                    property bool selected: root.sameDate(modelData.dateValue, root.selectedDate)
                    property bool hovered: dayPointer.containsMouse

                    Accessible.role: Accessible.Cell
                    Accessible.name: Qt.formatDate(modelData.dateValue, "yyyy-MM-dd")
                    Accessible.selected: dayCell.selected

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: dayCell.selected ? (theme ? theme.focusColor : "#007AFF") : (dayCell.hovered || dayCell.activeFocus ? (theme ? theme.hoverColor : "#E5E5EA") : "transparent")
                        border.width: dayCell.activeFocus ? 2 : 0
                        border.color: theme ? theme.focusColor : "#007AFF"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.day
                            color: dayCell.selected
                                   ? (theme ? theme.onAccentColor : "#FFFFFF")
                                   : (modelData.isCurrentMonth
                                      ? (theme ? theme.textColor : "#1D1D1F")
                                      : (theme ? theme.tertiaryTextColor : "#6E6E73"))
                            font.family: theme ? theme.fontFamily : "sans-serif"
                            font.pixelSize: 13
                            font.weight: modelData.isToday ? Font.DemiBold : Font.Normal
                        }
                    }

                    MouseArea {
                        id: dayPointer
                        anchors.fill: parent
                        enabled: root.enabled
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            dayCell.forceActiveFocus();
                            root.selectDate(dayCell.modelData.dateValue);
                        }
                    }

                    Keys.onSpacePressed: {
                        event.accepted = true;
                        root.selectDate(dayCell.modelData.dateValue);
                    }
                    Keys.onReturnPressed: {
                        event.accepted = true;
                        root.selectDate(dayCell.modelData.dateValue);
                    }
                    Keys.onEnterPressed: {
                        event.accepted = true;
                        root.selectDate(dayCell.modelData.dateValue);
                    }
                }
            }
        }
    }

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "Calendar"
        nameZh: "日历"
    }
}
