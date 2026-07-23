pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import QtQuick.Window

Rectangle {
    id: root

    required property var theme
    property string buildMode: theme.localized("Unknown", "未知")
    property string pageName: theme.localized("Unknown", "未知")
    property string focusName: theme.localized("None", "无")
    property string platformName: Qt.platform.os
    property real devicePixelRatio: 1.0
    property int viewportWidth: 0
    property int viewportHeight: 0
    // FPS sampling is intentionally intermittent. A continuously running
    // FrameAnimation would keep the scene graph awake and make the inspector
    // itself a source of GPU load.
    readonly property int fpsSampleWindowMs: 250
    readonly property int fpsSamplePeriodMs: 1000
    property bool fpsSamplingActive: false
    property bool fpsIdle: false
    property int framesPerSecond: -1
    readonly property var fpsSampleState: ({
        frameCount: 0,
        firstFrameAt: 0,
        lastFrameAt: 0
    })
    readonly property int eventCount: eventModel.count
    signal closeRequested

    color: root.theme.sidebarColor
    border.width: 1
    border.color: root.theme.separatorColor

    function addEvent(message) {
        const value = String(message);
        eventModel.insert(0, {
            timestamp: Qt.formatTime(new Date(), "HH:mm:ss"),
            message: value
        });
        if (eventModel.count > 50)
            eventModel.remove(eventModel.count - 1);
    }

    function clearEvents() {
        eventModel.clear();
    }

    function beginFpsSample() {
        if (!root.visible || root.fpsSamplingActive)
            return;

        root.fpsSampleState.frameCount = 0;
        root.fpsSampleState.firstFrameAt = 0;
        root.fpsSampleState.lastFrameAt = 0;
        root.fpsSamplingActive = true;
    }

    function recordSampleFrame() {
        const timestamp = Date.now();
        if (root.fpsSampleState.frameCount === 0)
            root.fpsSampleState.firstFrameAt = timestamp;
        root.fpsSampleState.lastFrameAt = timestamp;
        root.fpsSampleState.frameCount += 1;
    }

    function finishFpsSample() {
        if (!root.fpsSamplingActive)
            return;

        root.fpsSamplingActive = false;
        const frameIntervals = root.fpsSampleState.frameCount - 1;
        const elapsed = root.fpsSampleState.lastFrameAt - root.fpsSampleState.firstFrameAt;
        const hasMeasuredRate = frameIntervals > 0 && elapsed > 0;
        root.fpsIdle = !hasMeasuredRate;
        if (hasMeasuredRate)
            root.framesPerSecond = Math.round(frameIntervals * 1000 / elapsed);
    }

    function resetFpsSample() {
        root.fpsSamplingActive = false;
        root.fpsSampleState.frameCount = 0;
        root.fpsSampleState.firstFrameAt = 0;
        root.fpsSampleState.lastFrameAt = 0;
        root.fpsIdle = false;
        root.framesPerSecond = -1;
    }

    // QQuickWindow emits frameSwapped after a real scene-graph frame has been
    // submitted. Observing that signal avoids FrameAnimation's implicit
    // render-loop wakeups while retaining a useful interactive FPS reading.
    Connections {
        target: root.Window.window
        enabled: root.visible && root.fpsSamplingActive

        function onFrameSwapped() {
            root.recordSampleFrame();
        }
    }

    Timer {
        interval: root.fpsSampleWindowMs
        running: root.visible && root.fpsSamplingActive
        repeat: false
        onTriggered: root.finishFpsSample()
    }

    Timer {
        interval: root.fpsSamplePeriodMs
        running: root.visible
        repeat: true
        onTriggered: root.beginFpsSample()
    }

    ListModel {
        id: eventModel
    }

    onVisibleChanged: {
        if (visible)
            beginFpsSample();
        else
            resetFpsSample();
    }

    Component.onCompleted: {
        if (visible)
            beginFpsSample();
    }

    // A local native control keeps the inspector keyboard accessible while
    // matching the compact switch geometry used by the rest of the shell.
    component InspectorSwitch: Basic.Switch {
        id: control
        required property var theme

        implicitHeight: control.theme.touchTarget
        Layout.fillWidth: true
        Accessible.name: control.text

        contentItem: Text {
            text: control.text
            color: control.enabled ? control.theme.textColor : control.theme.tertiaryTextColor
            font.family: control.theme.fontFamily
            font.pixelSize: control.theme.fontSizeBody
            verticalAlignment: Text.AlignVCenter
            rightPadding: control.indicator.width + control.theme.spacingMedium
            elide: Text.ElideRight
        }

        indicator: Rectangle {
            x: control.width - width
            y: (control.height - height) / 2
            implicitWidth: 38
            implicitHeight: 22
            radius: height / 2
            color: control.checked ? control.theme.focusColor : control.theme.tertiaryColor
            border.width: control.visualFocus ? 2 : 1
            border.color: control.visualFocus ? control.theme.focusColor : control.theme.borderColor

            Rectangle {
                id: thumb
                width: 18
                height: 18
                y: 2
                x: control.checked ? parent.width - width - 2 : 2
                radius: width / 2
                color: control.checked ? control.theme.onAccentColor : control.theme.secondaryTextColor

                Behavior on x {
                    NumberAnimation {
                        duration: control.theme.durationFast
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: control.theme.durationFast
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.theme.spacingLarge
        spacing: root.theme.spacingMedium

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: root.theme.spacingXs

                Text {
                    text: root.theme.localized("UI Inspector", "界面检查器")
                    color: root.theme.textColor
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeTitle
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "cscui / " + root.buildMode
                    color: root.theme.secondaryTextColor
                    font.family: root.theme.monoFontFamily
                    font.pixelSize: root.theme.fontSizeCaption
                }
            }

            CscIconButton {
                theme: root.theme
                iconCharacter: "\uf00d"
                accessibleName: root.theme.localized("Close UI inspector", "关闭界面检查器")
                toolTip: accessibleName
                onClicked: root.closeRequested()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: metricsGrid.implicitHeight + root.theme.spacingLarge * 2
            radius: root.theme.radiusLarge
            color: root.theme.secondaryColor
            border.width: 1
            border.color: root.theme.separatorColor

            GridLayout {
                id: metricsGrid
                anchors.fill: parent
                anchors.margins: root.theme.spacingMedium
                columns: 2
                rowSpacing: root.theme.spacingMedium
                columnSpacing: root.theme.spacingMedium

                Repeater {
                    model: [
                        {
                            label: root.theme.localized("Frame rate", "帧率"),
                            value: root.fpsIdle
                                   ? root.theme.localized("Idle", "空闲")
                                   : (root.framesPerSecond < 0
                                      ? root.theme.localized("Sampling", "采样中")
                                      : root.framesPerSecond + " FPS")
                        },
                        {
                            label: root.theme.localized("Viewport", "视口"),
                            value: root.viewportWidth + " x " + root.viewportHeight
                        },
                        {
                            label: root.theme.localized("DPR", "像素比"),
                            value: Number(root.devicePixelRatio).toFixed(2)
                        },
                        {
                            label: root.theme.localized("Platform", "平台"),
                            value: root.platformName
                        },
                        {
                            label: root.theme.localized("Build", "构建"),
                            value: root.buildMode
                        },
                        {
                            label: root.theme.localized("Page", "页面"),
                            value: root.pageName
                        },
                        {
                            label: root.theme.localized("Focus", "焦点"),
                            value: root.focusName
                        }
                    ]

                    delegate: ColumnLayout {
                        id: metricCell
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: metricCell.modelData.label
                            color: root.theme.secondaryTextColor
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.fontSizeCaption
                        }

                        Text {
                            Layout.fillWidth: true
                            text: metricCell.modelData.value
                            color: root.theme.textColor
                            font.family: root.theme.monoFontFamily
                            font.pixelSize: root.theme.fontSizeCaption
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        Text {
            text: root.theme.localized("Accessibility", "无障碍")
            color: root.theme.secondaryTextColor
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.fontSizeCaption
            font.weight: Font.DemiBold
        }

        InspectorSwitch {
            theme: root.theme
            text: root.theme.localized("Reduced motion", "减少动态效果")
            checked: root.theme.reducedMotion
            onToggled: {
                root.theme.reducedMotion = checked;
                root.addEvent(root.theme.localized("Reduced motion: ", "减少动态效果：")
                              + (checked ? root.theme.localized("on", "开") : root.theme.localized("off", "关")));
            }
        }

        InspectorSwitch {
            theme: root.theme
            text: root.theme.localized("High contrast", "高对比度")
            checked: root.theme.highContrast
            onToggled: {
                root.theme.highContrast = checked;
                root.addEvent(root.theme.localized("High contrast: ", "高对比度：")
                              + (checked ? root.theme.localized("on", "开") : root.theme.localized("off", "关")));
            }
        }

        InspectorSwitch {
            theme: root.theme
            text: root.theme.localized("Show layout bounds", "显示布局边界")
            checked: root.theme.showLayoutBounds
            onToggled: {
                root.theme.showLayoutBounds = checked;
                root.addEvent(root.theme.localized("Layout bounds: ", "布局边界：")
                              + (checked ? root.theme.localized("on", "开") : root.theme.localized("off", "关")));
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: root.theme.localized("Events", "事件")
                color: root.theme.secondaryTextColor
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.fontSizeCaption
                font.weight: Font.DemiBold
            }

            Text {
                text: eventModel.count
                color: root.theme.tertiaryTextColor
                font.family: root.theme.monoFontFamily
                font.pixelSize: root.theme.fontSizeCaption
            }

            CscIconButton {
                theme: root.theme
                iconCharacter: "\uf1f8"
                accessibleName: root.theme.localized("Clear events", "清除事件")
                toolTip: accessibleName
                implicitWidth: root.theme.touchTarget
                implicitHeight: root.theme.touchTarget
                onClicked: root.clearEvents()
            }
        }

        ListView {
        cacheBuffer: 80
        reuseItems: true
            id: eventList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: root.theme.spacingXs
            model: eventModel

            delegate: Rectangle {
                id: eventRow
                required property string timestamp
                required property string message
                width: eventList.width
                height: eventText.implicitHeight + root.theme.spacingMedium
                radius: root.theme.radiusSmall
                color: root.theme.secondaryColor

                Text {
                    id: eventText
                    anchors.fill: parent
                    anchors.margins: root.theme.spacingSmall
                    text: eventRow.timestamp + "  " + eventRow.message
                    color: root.theme.secondaryTextColor
                    font.family: root.theme.monoFontFamily
                    font.pixelSize: root.theme.fontSizeCaption
                    wrapMode: Text.WrapAnywhere
                }
            }

            ScrollBar.vertical: CscScrollBar {
                theme: root.theme
                policy: ScrollBar.AsNeeded
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.theme.localized("Ctrl+Shift+D toggles inspector", "Ctrl+Shift+D 切换检查器")
            color: root.theme.tertiaryTextColor
            font.family: root.theme.monoFontFamily
            font.pixelSize: root.theme.fontSizeCaption
        }
    }
}
