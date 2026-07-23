pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: timeDisplay

    property var theme: null

    implicitWidth: 100
    implicitHeight: 100
    width: implicitWidth
    height: implicitHeight

    property bool is24Hour: true
    property string currentHour: ""
    property string currentMinute: ""
    property string currentPeriod: ""
    property bool separatorVisible: true
    property string accessibleName: theme
                                    ? theme.localized("Current time", "当前时间")
                                    : "Current time"

    readonly property int layoutSpacing: theme ? theme.spacingXs : 4
    readonly property real separatorHeight: separatorVisible ? 2 : 0
    readonly property real digitLineHeight: Math.max(
                                                 18,
                                                 (height - separatorHeight - layoutSpacing * 2) / 2)
    readonly property int digitFontSize: Math.max(
                                             12,
                                             Math.min(60,
                                                      Math.floor(Math.min(width * 0.55,
                                                                         digitLineHeight * 0.8))))
    readonly property string spokenTime: currentHour.length > 0 && currentMinute.length > 0
                                         ? currentHour + ":" + currentMinute
                                           + (currentPeriod.length > 0 ? " " + currentPeriod : "")
                                         : ""

    Accessible.role: Accessible.StaticText
    Accessible.name: timeDisplay.accessibleName
    Accessible.description: timeDisplay.spokenTime

    Column {
        anchors.centerIn: parent
        spacing: timeDisplay.layoutSpacing
        width: parent.width
        height: timeDisplay.digitLineHeight * 2
                + timeDisplay.separatorHeight
                + timeDisplay.layoutSpacing * 2

        Text {
            id: hourText
            width: parent.width
            height: timeDisplay.digitLineHeight
            text: timeDisplay.currentHour
            color: timeDisplay.theme ? timeDisplay.theme.focusColor : "#007AFF"
            font.family: timeDisplay.theme ? timeDisplay.theme.monoFontFamily : "monospace"
            font.pixelSize: timeDisplay.digitFontSize
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Rectangle {
            id: separatorLine
            width: Math.min(60, parent.width * 0.6)
            height: timeDisplay.separatorHeight
            color: timeDisplay.theme ? timeDisplay.theme.textColor : "#1D1D1F"
            anchors.horizontalCenter: parent.horizontalCenter
            visible: timeDisplay.separatorVisible
            radius: 1
        }

        Text {
            id: minuteText
            width: parent.width
            height: timeDisplay.digitLineHeight
            text: timeDisplay.currentMinute
            color: timeDisplay.theme ? timeDisplay.theme.textColor : "#1D1D1F"
            font.family: timeDisplay.theme ? timeDisplay.theme.monoFontFamily : "monospace"
            font.pixelSize: timeDisplay.digitFontSize
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    Timer {
        id: updateTimer
        interval: 1000
        running: timeDisplay.visible && timeDisplay.width > 0 && timeDisplay.height > 0
        repeat: true

        onTriggered: timeDisplay.updateTime()
    }

    function updateTime() {
        const now = new Date()
        var h = now.getHours()
        if (!timeDisplay.is24Hour) {
            timeDisplay.currentPeriod = h >= 12 ? "PM" : "AM"
            h = h % 12
            if (h === 0) h = 12
        } else {
            timeDisplay.currentPeriod = ""
        }
        timeDisplay.currentHour = h.toString().padStart(2, "0")
        timeDisplay.currentMinute = now.getMinutes().toString().padStart(2, "0")
    }

    onIs24HourChanged: timeDisplay.updateTime()
    Component.onCompleted: timeDisplay.updateTime()

    CscIdentityLayer {
        parent: timeDisplay
        anchors.fill: parent
        theme: timeDisplay.theme
        nameEn: "TimeDisplay"
        nameZh: "时间显示"
    }
}
