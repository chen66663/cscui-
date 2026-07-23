pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects

// Responsive pie and donut chart. Invalid, negative and zero values are
// excluded before geometry is calculated, preventing malformed canvas paths.
Rectangle {
    id: root

    required property var theme

    width: 600
    height: 500
    color: "transparent"
    activeFocusOnTab: true

    property string title: theme.localized("Pie Chart", "饼图")
    property string subtitle: theme.localized("Distribution", "分布")
    property var dataSeries: [
        {
            name: theme.localized("Distribution", "分布"),
            data: [
                {
                    label: theme.localized("Category A", "类别 A"),
                    value: 30,
                    color: "#007AFF"
                },
                {
                    label: theme.localized("Category B", "类别 B"),
                    value: 20,
                    color: "#34C759"
                },
                {
                    label: theme.localized("Category C", "类别 C"),
                    value: 15,
                    color: "#FF9F0A"
                },
                {
                    label: theme.localized("Category D", "类别 D"),
                    value: 25,
                    color: "#5AC8FA"
                },
                {
                    label: theme.localized("Category E", "类别 E"),
                    value: 10,
                    color: "#FF3B30"
                }
            ]
        }
    ]
    property var dataPoints: []
    readonly property var effectiveData: {
        const source = root.dataPoints && root.dataPoints.length > 0 ? root.dataPoints : (root.dataSeries && root.dataSeries.length > 0 && root.dataSeries[0] ? (root.dataSeries[0].data || []) : []);
        const colors = [theme.focusColor, theme.successColor, theme.warningColor, theme.infoColor, theme.dangerColor];
        const normalized = [];
        for (let index = 0; index < source.length; ++index) {
            const item = source[index];
            if (!item)
                continue;
            const value = Number(item.value);
            if (!isFinite(value) || value <= 0)
                continue;
            normalized.push({
                label: item.label || (theme.localized("Item ", "项目 ") + (index + 1)),
                value: value,
                color: item.color || colors[index % colors.length],
                sourceIndex: index
            });
        }
        return normalized;
    }

    property color tooltipColor: theme.elevatedColor
    property color tooltipTextColor: theme.textColor
    property int hoveredIndex: -1
    property real tooltipTargetX: 0
    property real tooltipTargetY: 0
    property real innerRadius: 0
    property bool showLabels: true

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
    readonly property real totalValue: {
        let total = 0;
        for (let index = 0; index < effectiveData.length; ++index)
            total += effectiveData[index].value;
        return total;
    }

    signal pointClicked(int index, var dataPoint)
    signal pointHovered(int index, var dataPoint)

    Accessible.role: Accessible.Graphic
    Accessible.name: title
    Accessible.description: subtitle

    function contrastingTextColor(colorValue) {
        const parsed = Qt.darker(colorValue, 1.0);
        const luminance = parsed.r * 0.299 + parsed.g * 0.587 + parsed.b * 0.114;
        return luminance > 0.62 ? "#1D1D1F" : "#FFFFFF";
    }

    function selectRelative(offset) {
        if (effectiveData.length === 0)
            return;
        const next = (hoveredIndex + offset + effectiveData.length) % effectiveData.length;
        updateSelection(next);
    }

    function updateSelection(index) {
        if (index < 0 || index >= chartCanvas.sliceRects.length)
            return;
        const slice = chartCanvas.sliceRects[index];
        const angle = slice.startAngle + (slice.endAngle - slice.startAngle) / 2;
        const distance = (slice.innerRadius + slice.outerRadius) / 2;
        const anchorX = chartCanvas.width / 2 + Math.cos(angle) * distance;
        const anchorY = chartCanvas.height / 2 + Math.sin(angle) * distance;
        tooltipTargetX = Math.max(0, Math.min(anchorX + theme.spacingSmall, chartArea.width - tooltip.width));
        tooltipTargetY = Math.max(0, Math.min(anchorY - tooltip.height / 2, chartArea.height - tooltip.height));
        if (hoveredIndex !== index) {
            hoveredIndex = index;
            pointHovered(index, effectiveData[index]);
        }
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
        if (hoveredIndex >= 0 && hoveredIndex < effectiveData.length) {
            event.accepted = true;
            pointClicked(hoveredIndex, effectiveData[hoveredIndex]);
        }
    }
    Keys.onEscapePressed: function (event) {
        event.accepted = true;
        hoveredIndex = -1;
    }

    Rectangle {
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
            antialiasing: true
            property var sliceRects: []

            onPaint: {
                const context = getContext("2d");
                context.clearRect(0, 0, width, height);
                sliceRects = [];

                const data = root.effectiveData;
                if (data.length === 0 || root.totalValue <= 0 || width <= 0 || height <= 0)
                    return;

                const centerX = width / 2;
                const centerY = height / 2;
                const hoverOffset = theme.reducedMotion ? 0 : 4;
                const baseRadius = Math.max(0, Math.min(width, height) / 2 - hoverOffset - 3);
                if (baseRadius <= 0)
                    return;
                const safeInnerRadius = Math.max(0, Math.min(root.innerRadius, baseRadius - 3));
                let currentAngle = -Math.PI / 2;

                for (let index = 0; index < data.length; ++index) {
                    const item = data[index];
                    const sliceAngle = item.value / root.totalValue * Math.PI * 2;
                    const endAngle = currentAngle + sliceAngle;
                    const outerRadius = baseRadius + (index === root.hoveredIndex ? hoverOffset : 0);

                    context.beginPath();
                    if (safeInnerRadius > 0) {
                        context.arc(centerX, centerY, outerRadius, currentAngle, endAngle, false);
                        context.arc(centerX, centerY, safeInnerRadius, endAngle, currentAngle, true);
                    } else {
                        context.moveTo(centerX, centerY);
                        context.arc(centerX, centerY, outerRadius, currentAngle, endAngle, false);
                    }
                    context.closePath();
                    context.fillStyle = item.color;
                    context.fill();
                    context.strokeStyle = root.backgroundVisible ? root.backgroundColor : theme.canvasColor;
                    context.lineWidth = 2;
                    context.stroke();

                    sliceRects.push({
                        startAngle: currentAngle,
                        endAngle: endAngle,
                        innerRadius: safeInnerRadius,
                        outerRadius: outerRadius,
                        index: index
                    });

                    if (root.showLabels && sliceAngle >= 0.24) {
                        const midAngle = currentAngle + sliceAngle / 2;
                        const labelRadius = safeInnerRadius > 0 ? (safeInnerRadius + baseRadius) / 2 : baseRadius * 0.68;
                        const labelX = centerX + Math.cos(midAngle) * labelRadius;
                        const labelY = centerY + Math.sin(midAngle) * labelRadius;
                        context.fillStyle = root.contrastingTextColor(item.color);
                        // Canvas follows CSS font syntax; quote families such
                        // as "Segoe UI Variable" so labels use the same font
                        // as the surrounding QML text without console errors.
                        context.font = "600 " + theme.fontSizeCaption + "px \"" + theme.fontFamily + "\"";
                        context.textAlign = "center";
                        context.textBaseline = "middle";
                        context.fillText(Math.round(item.value / root.totalValue * 100) + "%", labelX, labelY);
                    }

                    currentAngle = endAngle;
                }
            }

            MouseArea {
                id: pointer

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.hoveredIndex >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor

                onPositionChanged: function (mouse) {
                    const centerX = chartCanvas.width / 2;
                    const centerY = chartCanvas.height / 2;
                    const dx = mouse.x - centerX;
                    const dy = mouse.y - centerY;
                    const distance = Math.sqrt(dx * dx + dy * dy);
                    let angle = Math.atan2(dy, dx);
                    if (angle < -Math.PI / 2)
                        angle += Math.PI * 2;

                    let match = -1;
                    for (let index = 0; index < chartCanvas.sliceRects.length; ++index) {
                        const slice = chartCanvas.sliceRects[index];
                        if (distance >= slice.innerRadius && distance <= slice.outerRadius && angle >= slice.startAngle && angle < slice.endAngle) {
                            match = index;
                            break;
                        }
                    }
                    if (match >= 0)
                        root.updateSelection(match);
                    else
                        root.hoveredIndex = -1;
                }
                onExited: root.hoveredIndex = -1
                onClicked: {
                    if (root.hoveredIndex >= 0)
                        root.pointClicked(root.hoveredIndex, root.effectiveData[root.hoveredIndex]);
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
                function onEffectiveDataChanged() {
                    chartCanvas.requestPaint();
                }
                function onHoveredIndexChanged() {
                    chartCanvas.requestPaint();
                }
                function onInnerRadiusChanged() {
                    chartCanvas.requestPaint();
                }
                function onShowLabelsChanged() {
                    chartCanvas.requestPaint();
                }
                function onBackgroundColorChanged() {
                    chartCanvas.requestPaint();
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
            opacity: root.hoveredIndex >= 0 ? 1 : 0
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
                    if (root.hoveredIndex < 0 || root.hoveredIndex >= root.effectiveData.length)
                        return "";
                    const item = root.effectiveData[root.hoveredIndex];
                    return item.label + ": " + item.value + " (" + Math.round(item.value / root.totalValue * 100) + "%)";
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
        visible: root.effectiveData.length > 0

        Repeater {
            model: root.effectiveData

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
                    text: parent.modelData.label
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
        visible: root.effectiveData.length === 0
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
        nameEn: "PieChart"
        nameZh: "饼图"
    }
}
