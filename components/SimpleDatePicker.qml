pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

// Four-day picker used by compact toolbars. Every cell is actionable; the
// selected date, rather than only today, owns the selection treatment.
FocusScope {
    id: root

    property var theme: null

    property bool backgroundVisible: true
    property real radius: theme ? (theme.radiusMedium || 8) : 8
    property int padding: 12
    property bool shadowEnabled: true
    property date selectedDate: new Date()
    signal dateClicked(date clickedDate)
    property var dateRange: []
    property int itemWidth: 56
    property int itemHeight: 56
    property int itemSpacing: 6
    property string accessibleName: theme ? theme.localized("Date", "日期") : "Date"

    implicitWidth: root.padding * 2 + root.itemWidth * 4 + root.itemSpacing * 3
    implicitHeight: root.padding * 2 + root.itemHeight
    activeFocusOnTab: true
    opacity: root.enabled ? 1 : 0.45

    Accessible.role: Accessible.List
    Accessible.name: root.accessibleName

    function generateDateRange() {
        var today = new Date();
        var result = [];
        for (var offset = -1; offset < 3; ++offset) {
            var dateValue = new Date(today.getFullYear(), today.getMonth(), today.getDate() + offset);
            result.push({
                date: dateValue,
                dayName: root.getDayName(dateValue.getDay()),
                dayNumber: dateValue.getDate(),
                isToday: root.isSameDate(dateValue, today)
            });
        }
        root.dateRange = result;
    }

    function getDayName(dayIndex) {
        // Date.getDay() is Sunday=0; the previous implementation was offset by four.
        const englishDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        const chineseDays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"];
        return theme && theme.isChinese ? (chineseDays[dayIndex] || "") : (englishDays[dayIndex] || "");
    }

    function isSameDate(date1, date2) {
        if (!(date1 instanceof Date) || !(date2 instanceof Date))
            return false;
        return date1.getFullYear() === date2.getFullYear() && date1.getMonth() === date2.getMonth() && date1.getDate() === date2.getDate();
    }

    function chooseDate(dateValue) {
        if (!root.enabled || !(dateValue instanceof Date))
            return;
        root.selectedDate = new Date(dateValue);
        root.dateClicked(root.selectedDate);
    }

    Component.onCompleted: root.generateDateRange()

    Connections {
        target: theme
        enabled: !!theme
        ignoreUnknownSignals: true
        function onEffectiveLanguageChanged() {
            root.generateDateRange();
        }
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

    Row {
        id: dateRow
        anchors.fill: parent
        anchors.margins: Math.max(0, root.padding)
        spacing: Math.max(0, root.itemSpacing)

        Repeater {
            model: root.dateRange

            delegate: FocusScope {
                id: dateCell
                required property int index
                required property var modelData
                width: root.itemWidth
                height: root.itemHeight
                activeFocusOnTab: true
                property bool selected: root.isSameDate(modelData.date, root.selectedDate)
                property bool hovered: datePointer.containsMouse

                Accessible.role: Accessible.ListItem
                Accessible.name: modelData.dayName + " " + modelData.dayNumber
                Accessible.selected: dateCell.selected

                Rectangle {
                    anchors.fill: parent
                    radius: Math.min(root.radius, 10)
                    color: dateCell.selected ? (theme ? theme.focusColor : "#007AFF") : (dateCell.hovered || dateCell.activeFocus ? (theme ? theme.hoverColor : "#E5E5EA") : "transparent")
                    border.width: dateCell.activeFocus ? 2 : 0
                    border.color: theme ? theme.focusColor : "#007AFF"
                    Behavior on color {
                        ColorAnimation {
                            duration: theme ? theme.durationFast : 120
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.dayName
                            color: dateCell.selected
                                   ? (theme ? theme.onAccentColor : "#FFFFFF")
                                   : (theme ? theme.tertiaryTextColor : "#6E6E73")
                            font.family: theme ? theme.fontFamily : "sans-serif"
                            font.pixelSize: 11
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.dayNumber
                            color: dateCell.selected
                                   ? (theme ? theme.onAccentColor : "#FFFFFF")
                                   : (theme ? theme.textColor : "#1D1D1F")
                            font.family: theme ? theme.fontFamily : "sans-serif"
                            font.pixelSize: 16
                            font.weight: modelData.isToday ? Font.DemiBold : Font.Normal
                        }
                    }
                }

                MouseArea {
                    id: datePointer
                    anchors.fill: parent
                    enabled: root.enabled
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        dateCell.forceActiveFocus();
                        root.chooseDate(dateCell.modelData.date);
                    }
                }

                Keys.onSpacePressed: {
                    event.accepted = true;
                    root.chooseDate(dateCell.modelData.date);
                }
                Keys.onReturnPressed: {
                    event.accepted = true;
                    root.chooseDate(dateCell.modelData.date);
                }
                Keys.onEnterPressed: {
                    event.accepted = true;
                    root.chooseDate(dateCell.modelData.date);
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
        nameEn: "SimpleDatePicker"
        nameZh: "日期条"
    }
}
