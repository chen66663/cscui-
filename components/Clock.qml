pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: clock

    property var theme: null

    implicitWidth: 200
    implicitHeight: 200
    width: implicitWidth
    height: implicitHeight

    property color faceColor: theme ? theme.secondaryColor : "#FFFFFF"
    property color hourHandColor: theme ? theme.textColor : "#1D1D1F"
    property color minuteHandColor: theme ? theme.secondaryTextColor : "#5C5C60"
    property color secondDotColor: theme ? theme.focusColor : "#007AFF"
    property string accessibleName: theme
                                    ? theme.localized("Analog clock", "模拟时钟")
                                    : "Analog clock"

    property date currentTime: new Date()
    readonly property bool reducedMotion: theme ? theme.reducedMotion : false

    Accessible.role: Accessible.StaticText
    Accessible.name: clock.accessibleName
    Accessible.description: Qt.formatTime(clock.currentTime, "HH:mm:ss")

    Timer {
        interval: clock.reducedMotion ? 60000 : 1000
        running: clock.visible && clock.width > 0 && clock.height > 0
        repeat: true
        onTriggered: clock.currentTime = new Date()
    }

    Rectangle {
        id: clockFace

        width: Math.max(0, Math.min(clock.width, clock.height))
        height: width
        anchors.centerIn: parent
        color: clock.faceColor
        radius: width / 2
        clip: true
        border.width: clock.theme && clock.theme.highContrast ? 2 : 1
        border.color: clock.theme ? clock.theme.borderColor : "#D1D1D6"

        property real centerX: width / 2
        property real centerY: height / 2

        Repeater {
            model: 12

            delegate: Item {
                id: tickContainer
                required property int index

                anchors.fill: parent
                rotation: tickContainer.index * 30

                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: Math.max(6, parent.height * 0.065)
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: tickContainer.index % 3 === 0
                           ? Math.max(2, parent.width * 0.018)
                           : Math.max(1, parent.width * 0.01)
                    height: tickContainer.index % 3 === 0
                            ? Math.max(8, parent.height * 0.065)
                            : Math.max(5, parent.height * 0.04)
                    radius: width / 2
                    color: tickContainer.index % 3 === 0
                           ? clock.hourHandColor
                           : clock.minuteHandColor
                    opacity: tickContainer.index % 3 === 0 ? 0.72 : 0.42
                }
            }
        }

        Rectangle {
            id: hourHand
            width: parent.width * 0.08
            height: parent.height * 0.25
            color: clock.hourHandColor
            radius: width / 2
            x: clockFace.centerX - width / 2
            y: clockFace.centerY - height
            transformOrigin: Item.Bottom
            rotation: (clock.currentTime.getHours() % 12 + clock.currentTime.getMinutes() / 60) * 30
        }

        Rectangle {
            id: minuteHand
            width: parent.width * 0.05
            height: parent.height * 0.35
            color: clock.minuteHandColor
            radius: width / 2
            x: clockFace.centerX - width / 2
            y: clockFace.centerY - height
            transformOrigin: Item.Bottom
            rotation: (clock.currentTime.getMinutes() + clock.currentTime.getSeconds() / 60) * 6
        }

        Rectangle {
            id: secondDot
            visible: !clock.reducedMotion
            width: parent.width * 0.06
            height: width
            color: clock.secondDotColor
            radius: width / 2

            property real pathRadius: parent.width / 2 - width * 1.5
            property real secondsAngle: clock.currentTime.getSeconds() * 6

            x: clockFace.centerX + pathRadius * Math.sin(secondsAngle * Math.PI / 180) - width / 2
            y: clockFace.centerY - pathRadius * Math.cos(secondsAngle * Math.PI / 180) - height / 2
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.max(6, parent.width * 0.055)
            height: width
            radius: width / 2
            color: clock.secondDotColor
            border.width: 1
            border.color: clock.faceColor
        }
    }

    CscIdentityLayer {
        parent: clock
        anchors.fill: parent
        theme: clock.theme
        nameEn: "Clock"
        nameZh: "时钟"
    }
}
