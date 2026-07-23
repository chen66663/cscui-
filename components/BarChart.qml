pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects

// Responsive grouped bar chart with defensive handling for sparse series.
// Both the legacy dataPoints API and the multi-series dataSeries API are kept.
Rectangle {
    id: root

    required property var theme

    width: 600
    height: 500
    color: "transparent"
    activeFocusOnTab: true

    property string title: theme.localized("Bar Chart", "柱状图")
    property string subtitle: theme.localized("Data overview", "数据概览")
    property var dataSeries: [
        {
            name: theme.localized("Sales", "销售额"),
            color: theme.focusColor,
            data: [
                {
                    label: theme.localized("Jan", "1月"),
                    value: 120
                },
                {
                    label: theme.localized("Feb", "2月"),
                    value: 180
                },
                {
                    label: theme.localized("Mar", "3月"),
                    value: 237
                },
                {
                    label: theme.localized("Apr", "4月"),
                    value: 160
                },
                {
                    label: theme.localized("May", "5月"),
                    value: 90
                },
                {
                    label: theme.localized("Jun", "6月"),
                    value: 200
                }
            ]
        }
    ]
    property var dataPoints: []

    readonly property var effectiveDataSeries: {
        const source = root.dataPoints && root.dataPoints.length > 0 ? [
            {
                name: theme.localized("Data", "数据"),
                color: root.barColor,
                data: root.dataPoints
            }
        ] : (root.dataSeries || []);
        const normalized = [];
        for (let index = 0; index < source.length; ++index) {
            const series = source[index];
            if (!series || !series.data || typeof series.data.length !== "number")
                continue;
            normalized.push({
                name: series.name || (theme.localized("Series ", "系列 ") + (index + 1)),
                color: series.color || root.seriesColor(index),
                data: series.data
            });
        }
        return normalized;
    }
    readonly property int categoryCount: {
        let count = 0;
        for (let index = 0; index < effectiveDataSeries.length; ++index)
            count = Math.max(count, effectiveDataSeries[index].data.length);
        return count;
    }

    property color barColor: theme.focusColor
    property color tooltipColor: theme.elevatedColor
    property color tooltipTextColor: theme.textColor
    property int hoveredSeriesIndex: -1
    property int hoveredDataIndex: -1
    property real tooltipTargetX: 0
    property real tooltipTargetY: 0

    property bool backgroundVisible: true
    property real radius: theme.radiusMedium
    property int fontSize: theme.fontSizeBody
    property int titleFontSize: theme.fontSizeTitle
    property int subtitleFontSize: theme.fontSizeCaption
    property color backgroundColor: theme.surfaceColor
    property color textColor: theme.textColor
    property color subtitleColor: theme.secondaryTextColor
    property bool shadowEnabled: true
    property color shadowColor: theme.shadowColor
    property int chartPadding: theme.spacingLarge
    property int topPadding: 74
    property real barSpacing: 0.18
    property real groupSpacing: 0.28
    property real maxValue: {
        let maximum = 0;
        for (let seriesIndex = 0; seriesIndex < effectiveDataSeries.length; ++seriesIndex) {
            const data = effectiveDataSeries[seriesIndex].data;
            for (let dataIndex = 0; dataIndex < data.length; ++dataIndex)
                maximum = Math.max(maximum, root.safeValue(data[dataIndex] ? data[dataIndex].value : 0));
        }
        return Math.max(1, maximum);
    }
    property real chartWidth: Math.max(0, width - chartPadding * 2)
    property real chartHeight: Math.max(0, height - topPadding - chartPadding - (legend.visible ? legend.height + theme.spacingMedium : 0))

    signal pointClicked(int seriesIndex, int dataIndex, var dataPoint)
    signal pointHovered(int seriesIndex, int dataIndex, var dataPoint)

    Accessible.role: Accessible.Graphic
    Accessible.name: title
    Accessible.description: subtitle

    function safeValue(value) {
        const numeric = Number(value);
        return isFinite(numeric) ? Math.max(0, numeric) : 0;
    }

    function seriesColor(index) {
        const colors = [theme.focusColor, theme.successColor, theme.warningColor, theme.infoColor, theme.dangerColor];
        return colors[index % colors.length];
    }

    function pointAt(seriesIndex, dataIndex) {
        if (seriesIndex < 0 || seriesIndex >= effectiveDataSeries.length)
            return null;
        const data = effectiveDataSeries[seriesIndex].data;
        return dataIndex >= 0 && dataIndex < data.length ? data[dataIndex] : null;
    }

    function labelAt(dataIndex) {
        for (let seriesIndex = 0; seriesIndex < effectiveDataSeries.length; ++seriesIndex) {
            const point = pointAt(seriesIndex, dataIndex);
            if (point)
                return point.label || point.month || (dataIndex + 1);
        }
        return dataIndex + 1;
    }

    function selectRelative(offset) {
        const points = chartCanvas.barRects;
        if (!points || points.length === 0)
            return;
        let current = -1;
        for (let index = 0; index < points.length; ++index) {
            if (points[index].seriesIndex === hoveredSeriesIndex && points[index].dataIndex === hoveredDataIndex) {
                current = index;
                break;
            }
        }
        const next = points[(current + offset + points.length) % points.length];
        updateSelection(next);
    }

    function updateSelection(rect) {
        if (!rect)
            return;
        tooltipTargetX = Math.max(0, Math.min(rect.x + rect.w / 2 - tooltip.width / 2, chartArea.width - tooltip.width));
        tooltipTargetY = Math.max(0, rect.y - tooltip.height - theme.spacingXs);
        if (hoveredSeriesIndex !== rect.seriesIndex || hoveredDataIndex !== rect.dataIndex) {
            hoveredSeriesIndex = rect.seriesIndex;
            hoveredDataIndex = rect.dataIndex;
            pointHovered(rect.seriesIndex, rect.dataIndex, pointAt(rect.seriesIndex, rect.dataIndex));
        }
    }

    function clearSelection() {
        hoveredSeriesIndex = -1;
        hoveredDataIndex = -1;
    }

    Keys.onLeftPressed: function (event) {
        event.accepted = true;
        selectRelative(-1);
    }
    Keys.onRightPressed: function (event) {
        event.accepted = true;
        selectRelative(1);
    }
    Keys.onReturnPressed: function (event) {
        const point = pointAt(hoveredSeriesIndex, hoveredDataIndex);
        if (point) {
            event.accepted = true;
            pointClicked(hoveredSeriesIndex, hoveredDataIndex, point);
        }
    }
    Keys.onEscapePressed: function (event) {
        event.accepted = true;
        clearSelection();
    }

    Rectangle {
        id: background

        anchors.fill: parent
        radius: root.radius
        color: root.backgroundVisible ? root.backgroundColor : "transparent"
        border.width: root.activeFocus ? 2 : (root.backgroundVisible ? 1 : 0)
        border.color: root.activeFocus ? theme.focusColor : theme.borderColor

        layer.enabled: root.shadowEnabled && root.backgroundVisible && !theme.highContrast
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.shadowColor
            shadowBlur: theme.shadowBlur
            shadowHorizontalOffset: theme.shadowXOffset
            shadowVerticalOffset: theme.shadowYOffset
        }
    }

    Column {
        id: titleColumn

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: root.chartPadding
        anchors.leftMargin: root.chartPadding
        anchors.rightMargin: root.chartPadding
        spacing: theme.spacingXs

        Text {
            width: parent.width
            text: root.title
            color: root.textColor
            font.family: theme.fontFamily
            font.pixelSize: root.titleFontSize
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.subtitle
            color: root.subtitleColor
            font.family: theme.fontFamily
            font.pixelSize: root.subtitleFontSize
            elide: Text.ElideRight
        }
    }

    Item {
        id: chartArea

        anchors.fill: parent
        anchors.topMargin: Math.max(root.topPadding, titleColumn.y + titleColumn.height + theme.spacingMedium)
        anchors.leftMargin: root.chartPadding
        anchors.rightMargin: root.chartPadding
        anchors.bottomMargin: legend.visible ? legend.height + theme.spacingLarge * 2 : root.chartPadding

        Canvas {
            id: chartCanvas

            anchors.fill: parent
            anchors.bottomMargin: 26
            antialiasing: true
            property var barRects: []

            onPaint: {
                const context = getContext("2d");
                context.clearRect(0, 0, width, height);
                barRects = [];

                const series = root.effectiveDataSeries;
                const dataLength = root.categoryCount;
                if (series.length === 0 || dataLength === 0 || width <= 0 || height <= 0)
                    return;

                context.lineWidth = 1;
                context.strokeStyle = theme.separatorColor;
                for (let gridIndex = 0; gridIndex <= 4; ++gridIndex) {
                    const lineY = Math.round(height * gridIndex / 4) + 0.5;
                    context.beginPath();
                    context.moveTo(0, lineY);
                    context.lineTo(width, lineY);
                    context.stroke();
                }

                const seriesCount = series.length;
                const categoryWidth = width / dataLength;
                const groupGap = Math.max(0, Math.min(0.9, root.groupSpacing));
                const barGap = Math.max(0, Math.min(0.9, root.barSpacing));
                const groupWidth = categoryWidth * (1 - groupGap);
                const seriesStep = groupWidth / seriesCount;
                const barWidth = Math.max(1, seriesStep * (1 - (seriesCount > 1 ? barGap : 0)));
                const groupOffset = (categoryWidth - groupWidth) / 2;

                for (let dataIndex = 0; dataIndex < dataLength; ++dataIndex) {
                    for (let seriesIndex = 0; seriesIndex < seriesCount; ++seriesIndex) {
                        const point = root.pointAt(seriesIndex, dataIndex);
                        if (!point)
                            continue;

                        const value = root.safeValue(point.value);
                        const calculatedHeight = Math.min(height, value / root.maxValue * height);
                        const barHeight = value > 0 ? Math.max(2, calculatedHeight) : 0;
                        const x = dataIndex * categoryWidth + groupOffset + seriesIndex * seriesStep + (seriesStep - barWidth) / 2;
                        const y = height - barHeight;
                        const rect = {
                            x: x,
                            y: y,
                            w: barWidth,
                            h: barHeight,
                            seriesIndex: seriesIndex,
                            dataIndex: dataIndex
                        };
                        barRects.push(rect);

                        if (barHeight <= 0)
                            continue;
                        context.globalAlpha = root.hoveredSeriesIndex === seriesIndex && root.hoveredDataIndex === dataIndex ? 0.76 : 1;
                        context.fillStyle = series[seriesIndex].color;
                        const corner = Math.min(theme.radiusSmall, barWidth / 2, barHeight / 2);
                        context.beginPath();
                        context.moveTo(x, height);
                        context.lineTo(x, y + corner);
                        context.quadraticCurveTo(x, y, x + corner, y);
                        context.lineTo(x + barWidth - corner, y);
                        context.quadraticCurveTo(x + barWidth, y, x + barWidth, y + corner);
                        context.lineTo(x + barWidth, height);
                        context.closePath();
                        context.fill();
                    }
                }
                context.globalAlpha = 1;
            }

            MouseArea {
                id: pointer

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.hoveredSeriesIndex >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor

                onPositionChanged: function (mouse) {
                    const rects = chartCanvas.barRects;
                    let match = null;
                    for (let index = rects.length - 1; index >= 0; --index) {
                        const rect = rects[index];
                        const hitHeight = Math.max(rect.h, 6);
                        if (mouse.x >= rect.x && mouse.x <= rect.x + rect.w && mouse.y >= rect.y && mouse.y <= rect.y + hitHeight) {
                            match = rect;
                            break;
                        }
                    }
                    if (match)
                        root.updateSelection(match);
                    else
                        root.clearSelection();
                }
                onExited: root.clearSelection()
                onClicked: {
                    const point = root.pointAt(root.hoveredSeriesIndex, root.hoveredDataIndex);
                    if (point)
                        root.pointClicked(root.hoveredSeriesIndex, root.hoveredDataIndex, point);
                    root.forceActiveFocus();
                }
            }

            Connections {
                target: root

                function onDataPointsChanged() {
                    chartCanvas.requestPaint();
                }
                function onDataSeriesChanged() {
                    chartCanvas.requestPaint();
                }
                function onEffectiveDataSeriesChanged() {
                    chartCanvas.requestPaint();
                }
                function onHoveredSeriesIndexChanged() {
                    chartCanvas.requestPaint();
                }
                function onHoveredDataIndexChanged() {
                    chartCanvas.requestPaint();
                }
                function onMaxValueChanged() {
                    chartCanvas.requestPaint();
                }
                function onBarSpacingChanged() {
                    chartCanvas.requestPaint();
                }
                function onGroupSpacingChanged() {
                    chartCanvas.requestPaint();
                }
            }
        }

        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 22

            Repeater {
                model: root.categoryCount

                Item {
                    required property int index
                    x: index * parent.width / Math.max(1, root.categoryCount)
                    width: parent.width / Math.max(1, root.categoryCount)
                    height: parent.height

                    Text {
                        anchors.fill: parent
                        text: root.labelAt(index)
                        color: root.subtitleColor
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeCaption
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Rectangle {
            id: tooltip

            x: root.tooltipTargetX
            y: root.tooltipTargetY
            width: Math.min(chartArea.width, tooltipText.implicitWidth + theme.spacingMedium * 2)
            height: tooltipText.implicitHeight + theme.spacingSmall * 2
            radius: theme.radiusSmall
            color: root.tooltipColor
            border.width: 1
            border.color: theme.borderColor
            opacity: root.hoveredSeriesIndex >= 0 && root.hoveredDataIndex >= 0 ? 1 : 0
            visible: opacity > 0
            z: 10

            Behavior on opacity {
                NumberAnimation {
                    duration: theme.durationFast
                }
            }

            Text {
                id: tooltipText

                anchors.centerIn: parent
                width: Math.min(implicitWidth, chartArea.width - theme.spacingMedium * 2)
                text: {
                    const point = root.pointAt(root.hoveredSeriesIndex, root.hoveredDataIndex);
                    if (!point)
                        return "";
                    const series = root.effectiveDataSeries[root.hoveredSeriesIndex];
                    return (series.name ? series.name + "\n" : "")
                            + (point.label || point.month || theme.localized("Value", "数值"))
                            + ": " + root.safeValue(point.value);
                }
                color: root.tooltipTextColor
                font.family: theme.fontFamily
                font.pixelSize: root.fontSize
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }
    }

    Flow {
        id: legend

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.chartPadding
        height: childrenRect.height
        spacing: theme.spacingMedium
        visible: root.effectiveDataSeries.length > 1

        Repeater {
            model: root.effectiveDataSeries

            Row {
                required property var modelData
                spacing: theme.spacingXs

                Rectangle {
                    width: 10
                    height: 10
                    radius: 3
                    color: parent.modelData.color
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: parent.modelData.name
                    color: root.subtitleColor
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeCaption
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.categoryCount === 0
        text: theme.localized("No data", "暂无数据")
        color: root.subtitleColor
        font.family: theme.fontFamily
        font.pixelSize: root.fontSize
    }

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "BarChart"
        nameZh: "柱状图"
    }
}
