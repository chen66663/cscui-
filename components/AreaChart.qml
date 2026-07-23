pragma ComponentBehavior: Bound

// AreaChart.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

Rectangle {
    id: root

    // Injected by the host page so Bound components share one palette.
    required property var theme

    width: 600
    height: 500
    color: "transparent"
    clip: false
    activeFocusOnTab: true
    Keys.priority: Keys.BeforeItem
    KeyNavigation.tab: styleButton
    KeyNavigation.priority: KeyNavigation.BeforeItem

    // === 接口属性 & 信号 ===
    property string title: theme.localized("Area Chart", "面积图")
    property string subtitle: theme.localized("Visits during the first six months", "前六个月访问量")

    // 支持多数据系列
    property var dataSeries: [
        {
            name: theme.localized("Mobile", "移动端"),
            color: theme.focusColor,
            data: [
                {
                    month: theme.localized("Jan", "1月"),
                    value: 120,
                    label: theme.localized("January", "一月")
                },
                {
                    month: theme.localized("Feb", "2月"),
                    value: 180,
                    label: theme.localized("February", "二月")
                },
                {
                    month: theme.localized("Mar", "3月"),
                    value: 237,
                    label: theme.localized("March", "三月")
                },
                {
                    month: theme.localized("Apr", "4月"),
                    value: 160,
                    label: theme.localized("April", "四月")
                },
                {
                    month: theme.localized("May", "5月"),
                    value: 90,
                    label: theme.localized("May", "五月")
                },
                {
                    month: theme.localized("Jun", "6月"),
                    value: 200,
                    label: theme.localized("June", "六月")
                }
            ]
        }
    ]

    // 兼容单数据系列格式
    property var dataPoints: []

    property bool keyboardSelectionActive: false
    property string accessibleName: root.title
    property string accessibleDescription: root.generatedAccessibleDescription

    Accessible.role: Accessible.Graphic
    Accessible.name: root.accessibleName
    Accessible.description: root.accessibleDescription
    Accessible.focusable: true

    // 内部计算属性：合并的数据系列
    readonly property var effectiveDataSeries: {
        if (dataPoints && dataPoints.length > 0) {
            // 使用旧格式
            return [
                {
                    name: theme.localized("Data", "数据"),
                    color: theme.focusColor,
                    data: dataPoints
                }
            ];
        } else {
            // 使用新格式
            return dataSeries;
        }
    }

    readonly property int pointCount: {
        if (root.effectiveDataSeries.length === 0 || !root.effectiveDataSeries[0].data)
            return 0;
        return root.effectiveDataSeries[0].data.length;
    }
    readonly property string lineStyleLabel: root.lineStyleText()
    readonly property string keyboardHint: theme.localized(
                                               "Use Left and Right to browse points, Home and End to jump to the first or last point, and Enter or Space to activate the selected point.",
                                               "使用左右方向键浏览数据点，Home 和 End 跳转到首尾数据点，按 Enter 或空格键触发当前数据点。")
    readonly property string selectedPointDescription: root.describeSelectedPoint()
    readonly property string generatedAccessibleDescription: {
        var seriesCount = root.effectiveDataSeries.length;
        var summary = root.subtitle + " " + theme.localized(
            seriesCount + " series and " + root.pointCount + " points.",
            "包含 " + seriesCount + " 个数据系列和 " + root.pointCount + " 个数据点。"
        );
        if (root.hoveredIndex >= 0)
            summary += " " + theme.localized("Selected point: ", "当前数据点：") + root.selectedPointDescription + ".";
        return summary + " " + root.keyboardHint;
    }

    // === 线条样式枚举 ===
    enum LineStyle {
        Smooth,
        Linear,
        Step
    }

    property int lineStyle: AreaChart.LineStyle.Smooth

    property color areaColor: Qt.rgba(theme.focusColor.r, theme.focusColor.g, theme.focusColor.b, 0.3)
    property color lineColor: theme.focusColor
    property color tooltipColor: theme.primaryColor
    property color tooltipTextColor: theme.textColor
    property int hoveredIndex: -1

    signal pointClicked(int index, var dataPoint)
    signal pointHovered(int index, var dataPoint)

    // === 样式属性 ===
    property bool backgroundVisible: true
    property real radius: theme ? theme.radiusLarge : 12
    property int fontSize: 14
    property int titleFontSize: 18
    property int subtitleFontSize: 12
    property color backgroundColor: theme.secondaryColor
    property color textColor: theme.textColor
    property color subtitleColor: theme.secondaryTextColor
    property bool shadowEnabled: true
    property color shadowColor: theme.shadowColor
    property int chartPadding: 20
    property int topPadding: 90

    function pointAt(index) {
        if (index < 0 || root.effectiveDataSeries.length === 0)
            return null;
        var data = root.effectiveDataSeries[0].data;
        return data && index < data.length ? data[index] : null;
    }

    function pointLabel(point, index) {
        if (point) {
            var label = point.label !== undefined && point.label !== null ? point.label : point.month;
            if (label !== undefined && label !== null && String(label).length > 0)
                return String(label);
        }
        return theme.localized("Point " + (index + 1), "数据点 " + (index + 1));
    }

    function pointValue(point) {
        var value = Number(point && point.value);
        return isFinite(value) ? value : 0;
    }

    function lineStyleText() {
        switch (root.lineStyle) {
        case AreaChart.LineStyle.Linear:
            return theme.localized("Linear", "直线");
        case AreaChart.LineStyle.Step:
            return theme.localized("Step", "阶梯");
        case AreaChart.LineStyle.Smooth:
        default:
            return theme.localized("Smooth", "平滑");
        }
    }

    function cycleLineStyle() {
        switch (root.lineStyle) {
        case AreaChart.LineStyle.Smooth:
            root.lineStyle = AreaChart.LineStyle.Linear;
            break;
        case AreaChart.LineStyle.Linear:
            root.lineStyle = AreaChart.LineStyle.Step;
            break;
        case AreaChart.LineStyle.Step:
        default:
            root.lineStyle = AreaChart.LineStyle.Smooth;
            break;
        }
    }

    function describeSelectedPoint() {
        if (root.hoveredIndex < 0)
            return theme.localized("No data point selected", "未选择数据点");
        var point = root.pointAt(root.hoveredIndex);
        if (!point)
            return theme.localized("No data point selected", "未选择数据点");

        var values = [];
        var series = root.effectiveDataSeries;
        for (var seriesIndex = 0; seriesIndex < series.length; ++seriesIndex) {
            var data = series[seriesIndex].data;
            if (data && root.hoveredIndex < data.length) {
                var name = series[seriesIndex].name || theme.localized("Series " + (seriesIndex + 1), "系列 " + (seriesIndex + 1));
                values.push(String(name) + ": " + String(data[root.hoveredIndex].value));
            }
        }
        var detail = values.length > 0 ? " (" + values.join(", ") + ")" : "";
        return root.pointLabel(point, root.hoveredIndex) + detail;
    }

    function selectPoint(index, fromKeyboard) {
        var count = root.pointCount;
        if (count <= 0) {
            root.hoveredIndex = -1;
            return;
        }

        var nextIndex = Math.max(0, Math.min(index, count - 1));
        root.keyboardSelectionActive = fromKeyboard === true;

        var dataPoint = root.pointAt(nextIndex);
        var stepX = chartCanvas.width / Math.max(1, count);
        var plotHeight = Math.max(0, chartCanvas.height - 16);
        var pointX = chartArea.x + chartCanvas.x + stepX * nextIndex + stepX / 2;
        var pointY = chartArea.y + chartCanvas.y + 8 + plotHeight - root.pointValue(dataPoint) / root.maxValue * plotHeight;
        var maxTooltipX = Math.max(0, root.width - tooltip.width - 10);
        var maxTooltipY = Math.max(0, root.height - tooltip.height - 10);
        tooltip.x = Math.max(0, Math.min(pointX - tooltip.width / 2, maxTooltipX));
        tooltip.y = Math.max(0, Math.min(pointY - tooltip.height - 10, maxTooltipY));

        if (root.hoveredIndex !== nextIndex) {
            root.hoveredIndex = nextIndex;
            root.pointHovered(nextIndex, dataPoint);
        }
    }

    function selectRelative(offset) {
        if (root.pointCount <= 0)
            return;
        var nextIndex = root.hoveredIndex < 0
                ? (offset < 0 ? root.pointCount - 1 : 0)
                : (root.hoveredIndex + offset + root.pointCount) % root.pointCount;
        root.selectPoint(nextIndex, true);
    }

    function activateSelectedPoint() {
        var point = root.pointAt(root.hoveredIndex);
        if (point)
            root.pointClicked(root.hoveredIndex, point);
    }

    function clearSelection() {
        root.keyboardSelectionActive = false;
        root.hoveredIndex = -1;
    }

    onActiveFocusChanged: {
        if (root.activeFocus) {
            if (root.hoveredIndex < 0 && root.pointCount > 0)
                root.selectPoint(0, true);
        } else if (root.keyboardSelectionActive) {
            root.clearSelection();
        }
    }

    onPointCountChanged: {
        if (root.hoveredIndex >= root.pointCount)
            root.clearSelection();
    }

    Keys.onLeftPressed: function (event) {
        if (styleButton.activeFocus)
            return;
        event.accepted = true;
        root.selectRelative(-1);
    }
    Keys.onRightPressed: function (event) {
        if (styleButton.activeFocus)
            return;
        event.accepted = true;
        root.selectRelative(1);
    }
    Keys.onPressed: function (event) {
        if (styleButton.activeFocus)
            return;
        if (event.key === Qt.Key_Home) {
            event.accepted = true;
            root.selectPoint(0, true);
        } else if (event.key === Qt.Key_End) {
            event.accepted = true;
            root.selectPoint(root.pointCount - 1, true);
        }
    }
    Keys.onReturnPressed: function (event) {
        if (styleButton.activeFocus)
            return;
        event.accepted = true;
        root.activateSelectedPoint();
    }
    Keys.onEnterPressed: function (event) {
        if (styleButton.activeFocus)
            return;
        event.accepted = true;
        root.activateSelectedPoint();
    }
    Keys.onSpacePressed: function (event) {
        if (styleButton.activeFocus)
            return;
        event.accepted = true;
        root.activateSelectedPoint();
    }
    Keys.onTabPressed: function (event) {
        if (styleButton.activeFocus || (event.modifiers & Qt.ShiftModifier))
            return;
        event.accepted = true;
        styleButton.forceActiveFocus();
    }
    Keys.onEscapePressed: function (event) {
        if (styleButton.activeFocus)
            return;
        event.accepted = true;
        root.clearSelection();
    }

    // === 计算属性 ===
    property real maxValue: {
        var max = 0;
        var series = root.effectiveDataSeries;
        for (var s = 0; s < series.length; s++) {
            var data = series[s].data;
            for (var i = 0; i < data.length; i++) {
                if (data[i].value > max) {
                    max = data[i].value;
                }
            }
        }
        // A non-zero scale keeps empty/all-zero datasets finite and drawable.
        return Math.max(1, max);
    }

    property real chartWidth: Math.max(0, width - chartPadding * 2)
    property real chartHeight: Math.max(0, height - topPadding - chartPadding - (legend.visible ? 60 : 0))

    // === 背景与阴影 ===
    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.radius
        color: root.backgroundVisible ? root.backgroundColor : "transparent"
        border.width: root.activeFocus && !styleButton.activeFocus ? 2 : 0
        border.color: root.theme.focusColor

        layer.enabled: root.shadowEnabled && root.backgroundVisible && !(root.theme && root.theme.highContrast)
        layer.effect: MultiEffect {
            shadowEnabled: root.shadowEnabled
            shadowColor: root.shadowColor
            shadowBlur: root.theme.shadowBlur
            shadowHorizontalOffset: root.theme.shadowXOffset
            shadowVerticalOffset: root.theme.shadowYOffset
        }
    }

    // === 标题区域 ===
    Column {
        id: titleColumn
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 40
        spacing: 5

        Text {
            text: root.title
            font.pixelSize: root.titleFontSize
            font.bold: true
            color: root.textColor
        }

        Text {
            text: root.subtitle
            font.pixelSize: root.subtitleFontSize
            color: root.subtitleColor
        }
    }

    // === 样式切换按钮 ===
    Rectangle {
        id: styleButton
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 40
        width: 80
        height: 32
        radius: 16
        color: root.backgroundVisible ? root.theme.secondaryColor : "transparent"
        border.color: styleButton.activeFocus ? root.theme.focusColor : root.theme.borderColor
        border.width: styleButton.activeFocus ? 2 : (root.backgroundVisible ? 1 : 0)
        activeFocusOnTab: true
        KeyNavigation.backtab: root
        KeyNavigation.priority: KeyNavigation.BeforeItem

        Accessible.role: Accessible.Button
        Accessible.name: root.theme.localized("Line style: ", "线条样式：") + root.lineStyleLabel
        Accessible.description: root.theme.localized("Activate to cycle between smooth, linear, and step lines.", "激活以循环切换平滑、直线和阶梯线条。")
        Accessible.focusable: true

        Text {
            anchors.centerIn: parent
            text: root.lineStyleLabel
            font.pixelSize: 12
            color: root.textColor
        }

        // 悬停效果
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.theme.focusColor
            opacity: styleButton.hovered || styleButton.activeFocus ? 0.1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: root.theme.reducedMotion ? 0 : 200
                }
            }
        }

        property bool hovered: false
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: styleButton.hovered = true
            onExited: styleButton.hovered = false
            onPressed: styleButton.forceActiveFocus()
            onClicked: root.cycleLineStyle()
        }

        Keys.onLeftPressed: function (event) { event.accepted = true; }
        Keys.onRightPressed: function (event) { event.accepted = true; }
        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Home || event.key === Qt.Key_End)
                event.accepted = true;
        }
        Keys.onSpacePressed: function (event) {
            event.accepted = true;
            root.cycleLineStyle();
        }
        Keys.onReturnPressed: function (event) {
            event.accepted = true;
            root.cycleLineStyle();
        }
        Keys.onEnterPressed: function (event) {
            event.accepted = true;
            root.cycleLineStyle();
        }
    }

    // === 图表区域 ===
    Item {
        id: chartArea
        anchors.fill: parent
        anchors.topMargin: root.topPadding
        anchors.margins: root.chartPadding

        // === 绘制区域图表 ===
        Canvas {
            id: chartCanvas
            anchors.fill: parent
            anchors.margins: 8  // 增加边距确保完整的圆形数据点可见
            anchors.bottomMargin: legend.visible ? 100 : 40  // 为横轴标签和图例留出空间

            // 绘制区域路径的函数
            function drawAreaPath(ctx, points, lineStyle) {
                switch (lineStyle) {
                case AreaChart.LineStyle.Linear:
                    // 直线连接
                    for (var i = 1; i < points.length; i++) {
                        ctx.lineTo(points[i].x, points[i].y);
                    }
                    break;
                case AreaChart.LineStyle.Step:
                    // 阶梯连接
                    for (var j = 1; j < points.length; j++) {
                        ctx.lineTo(points[j].x, points[j - 1].y); // 水平线
                        ctx.lineTo(points[j].x, points[j].y);   // 垂直线
                    }
                    break;
                case AreaChart.LineStyle.Smooth:
                default:
                    // 平滑曲线 - 使用Catmull-Rom样条
                    if (points.length > 2) {
                        // 第一段：从第一个点到第二个点
                        var cp1x = points[0].x + (points[1].x - points[0].x) * 0.25;
                        var cp1y = points[0].y;
                        var cp2x = points[1].x - (points[2].x - points[0].x) * 0.25;
                        var cp2y = points[1].y - (points[2].y - points[0].y) * 0.25;
                        ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, points[1].x, points[1].y);

                        // 中间段：使用Catmull-Rom样条
                        for (var k = 2; k < points.length - 1; k++) {
                            var p0 = points[k - 2];
                            var p1 = points[k - 1];
                            var p2 = points[k];
                            var p3 = points[k + 1];

                            // Catmull-Rom控制点计算
                            var cp1x_cat = p1.x + (p2.x - p0.x) / 6;
                            var cp1y_cat = p1.y + (p2.y - p0.y) / 6;
                            var cp2x_cat = p2.x - (p3.x - p1.x) / 6;
                            var cp2y_cat = p2.y - (p3.y - p1.y) / 6;

                            ctx.bezierCurveTo(cp1x_cat, cp1y_cat, cp2x_cat, cp2y_cat, p2.x, p2.y);
                        }

                        // 最后一段：到最后一个点
                        if (points.length > 2) {
                            var lastIdx = points.length - 1;
                            var cp1x_last = points[lastIdx - 1].x + (points[lastIdx].x - points[lastIdx - 2].x) * 0.25;
                            var cp1y_last = points[lastIdx - 1].y + (points[lastIdx].y - points[lastIdx - 2].y) * 0.25;
                            var cp2x_last = points[lastIdx].x - (points[lastIdx].x - points[lastIdx - 1].x) * 0.25;
                            var cp2y_last = points[lastIdx].y;
                            ctx.bezierCurveTo(cp1x_last, cp1y_last, cp2x_last, cp2y_last, points[lastIdx].x, points[lastIdx].y);
                        }
                    } else if (points.length === 2) {
                        // 只有两个点时，使用简单的二次曲线
                        var midX = (points[0].x + points[1].x) / 2;
                        var midY = (points[0].y + points[1].y) / 2;
                        ctx.quadraticCurveTo(midX, points[0].y, points[1].x, points[1].y);
                    } else {
                        // 只有一个点时，直接连线
                        ctx.lineTo(points[0].x, points[0].y);
                    }
                    break;
                }
            }

            // 绘制线条路径的函数
            function drawLinePath(ctx, points, lineStyle) {
                switch (lineStyle) {
                case AreaChart.LineStyle.Linear:
                    // 直线连接
                    for (var i = 1; i < points.length; i++) {
                        ctx.lineTo(points[i].x, points[i].y);
                    }
                    break;
                case AreaChart.LineStyle.Step:
                    // 阶梯连接
                    for (var j = 1; j < points.length; j++) {
                        ctx.lineTo(points[j].x, points[j - 1].y); // 水平线
                        ctx.lineTo(points[j].x, points[j].y);   // 垂直线
                    }
                    break;
                case AreaChart.LineStyle.Smooth:
                default:
                    // 平滑曲线 - 使用相同的Catmull-Rom算法
                    if (points.length > 2) {
                        // 第一段：从第一个点到第二个点
                        var cp1x_line = points[0].x + (points[1].x - points[0].x) * 0.25;
                        var cp1y_line = points[0].y;
                        var cp2x_line = points[1].x - (points[2].x - points[0].x) * 0.25;
                        var cp2y_line = points[1].y - (points[2].y - points[0].y) * 0.25;
                        ctx.bezierCurveTo(cp1x_line, cp1y_line, cp2x_line, cp2y_line, points[1].x, points[1].y);

                        // 中间段：使用Catmull-Rom样条
                        for (var k = 2; k < points.length - 1; k++) {
                            var p0_line = points[k - 2];
                            var p1_line = points[k - 1];
                            var p2_line = points[k];
                            var p3_line = points[k + 1];

                            // Catmull-Rom控制点计算
                            var cp1x_cat_line = p1_line.x + (p2_line.x - p0_line.x) / 6;
                            var cp1y_cat_line = p1_line.y + (p2_line.y - p0_line.y) / 6;
                            var cp2x_cat_line = p2_line.x - (p3_line.x - p1_line.x) / 6;
                            var cp2y_cat_line = p2_line.y - (p3_line.y - p1_line.y) / 6;

                            ctx.bezierCurveTo(cp1x_cat_line, cp1y_cat_line, cp2x_cat_line, cp2y_cat_line, p2_line.x, p2_line.y);
                        }

                        // 最后一段：到最后一个点
                        if (points.length > 2) {
                            var lastIdx_line = points.length - 1;
                            var cp1x_last_line = points[lastIdx_line - 1].x + (points[lastIdx_line].x - points[lastIdx_line - 2].x) * 0.25;
                            var cp1y_last_line = points[lastIdx_line - 1].y + (points[lastIdx_line].y - points[lastIdx_line - 2].y) * 0.25;
                            var cp2x_last_line = points[lastIdx_line].x - (points[lastIdx_line].x - points[lastIdx_line - 1].x) * 0.25;
                            var cp2y_last_line = points[lastIdx_line].y;
                            ctx.bezierCurveTo(cp1x_last_line, cp1y_last_line, cp2x_last_line, cp2y_last_line, points[lastIdx_line].x, points[lastIdx_line].y);
                        }
                    } else if (points.length === 2) {
                        // 只有两个点时，使用简单的二次曲线
                        var midX_line = (points[0].x + points[1].x) / 2;
                        var midY_line = (points[0].y + points[1].y) / 2;
                        ctx.quadraticCurveTo(midX_line, points[0].y, points[1].x, points[1].y);
                    } else if (points.length === 1)
                    // 只有一个点时，不需要绘制线条
                    {} else {
                        // 多个点时，直接连线
                        for (var l = 1; l < points.length; l++) {
                            ctx.lineTo(points[l].x, points[l].y);
                        }
                    }
                    break;
                }
            }

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                var series = root.effectiveDataSeries;
                if (series.length === 0 || series[0].data.length === 0)
                    return;

                var chartHeight = height - 16; // 为顶部和底部的数据点留出空间

                // 为每个数据系列绘制图表
                for (var seriesIndex = 0; seriesIndex < series.length; seriesIndex++) {
                    var currentSeries = series[seriesIndex];
                    var data = currentSeries.data;
                    if (!data || data.length === 0)
                        continue;
                    var seriesStepX = width / data.length;

                    // 创建路径点 - 居中对齐
                    var points = [];
                    for (var i = 0; i < data.length; i++) {
                        var x = seriesStepX * i + seriesStepX / 2; // 居中对齐
                        var y = 8 + chartHeight - (data[i].value / root.maxValue) * chartHeight;
                        points.push({
                            x: x,
                            y: y
                        });
                    }

                    // 绘制区域填充
                    ctx.beginPath();
                    ctx.moveTo(points[0].x, 8 + chartHeight); // 从底部开始
                    ctx.lineTo(points[0].x, points[0].y); // 到第一个数据点

                    // 根据线条样式绘制不同的曲线
                    drawAreaPath(ctx, points, root.lineStyle);

                    // 回到底部完成区域
                    ctx.lineTo(points[points.length - 1].x, 8 + chartHeight);
                    ctx.closePath();

                    // 填充区域 - 使用系列颜色的透明版本
                    var seriesColor = currentSeries.color;
                    var color = Qt.color(seriesColor);
                    ctx.fillStyle = Qt.rgba(color.r, color.g, color.b, 0.3);
                    ctx.fill();

                    // 绘制边界线
                    ctx.beginPath();
                    ctx.moveTo(points[0].x, points[0].y);

                    drawLinePath(ctx, points, root.lineStyle);

                    ctx.strokeStyle = seriesColor;
                    ctx.lineWidth = 2;
                    ctx.stroke();

                    // 绘制数据点 - 只在悬停时显示
                    if (root.hoveredIndex >= 0 && root.hoveredIndex < points.length) {
                        var hoveredPoint = points[root.hoveredIndex];

                        // 绘制外圆
                        ctx.beginPath();
                        ctx.arc(hoveredPoint.x, hoveredPoint.y, 5, 0, 2 * Math.PI);
                        ctx.fillStyle = seriesColor;
                        ctx.fill();

                        // 绘制内圆
                        ctx.beginPath();
                        ctx.arc(hoveredPoint.x, hoveredPoint.y, 3, 0, 2 * Math.PI);
                        ctx.fillStyle = "white";
                        ctx.fill();
                    }
                }
            }

            // 当数据改变时重新绘制
            Connections {
                target: root
                function onDataPointsChanged() {
                    chartCanvas.requestPaint();
                }
                function onDataSeriesChanged() {
                    chartCanvas.requestPaint();
                }
                function onAreaColorChanged() {
                    chartCanvas.requestPaint();
                }
                function onLineColorChanged() {
                    chartCanvas.requestPaint();
                }
                function onHoveredIndexChanged() {
                    chartCanvas.requestPaint();
                }
            }
        }

        // === 交互层 ===
        MouseArea {
            id: hoverMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: root.hoveredIndex >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor

            Timer {
                id: hideTimer
                interval: 200
                repeat: false
                onTriggered: {
                    if (!root.keyboardSelectionActive)
                        root.clearSelection();
                }
            }

            onPositionChanged: function (mouse) {
                hideTimer.stop();

                var series = root.effectiveDataSeries;
                if (series.length === 0 || !series[0].data || series[0].data.length === 0) {
                    root.clearSelection();
                    return;
                }

                // 使用与绘制相同的坐标计算方式
                var dataLength = series[0].data.length;
                var stepX = chartCanvas.width / dataLength;
                var index = Math.floor((mouse.x - chartCanvas.x) / stepX);
                index = Math.max(0, Math.min(index, dataLength - 1));
                root.selectPoint(index, false);
            }

            onExited: function () {
                hideTimer.start();
            }

            onClicked: {
                root.activateSelectedPoint();
                root.forceActiveFocus();
            }
        }
    }

    // === X轴标签 ===
    Row {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: root.chartPadding
        anchors.bottomMargin: legend.visible ? 75 : 15

        Repeater {
            model: root.effectiveDataSeries.length > 0 ? root.effectiveDataSeries[0].data : []
            delegate: Text {
                required property var modelData

                width: root.chartWidth / (root.effectiveDataSeries.length > 0 ? root.effectiveDataSeries[0].data.length : 1)
                text: modelData.month
                font.pixelSize: root.fontSize - 2
                color: root.subtitleColor
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // === 悬停提示框 ===
    Rectangle {
        id: tooltip
        // 使用 opacity 控制显示隐藏，配合 Behavior
        opacity: root.hoveredIndex >= 0 ? 1 : 0
        visible: opacity > 0

        width: tooltipContent.width + 20
        height: tooltipContent.height + 16
        radius: 8
        color: root.tooltipColor
        border.color: root.lineColor
        border.width: 1

        // 动态定位 - 现在由 MouseArea 控制
        x: 0
        y: 0

        // 添加平滑移动动画
        Behavior on x {
            enabled: root.hoveredIndex >= 0
            NumberAnimation {
                duration: theme.reducedMotion ? 0 : 220
                easing.type: Easing.OutCubic
            }
        }
        Behavior on y {
            enabled: root.hoveredIndex >= 0
            NumberAnimation {
                duration: theme.reducedMotion ? 0 : 220
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: theme.reducedMotion ? 0 : 160
            }
        }

        Column {
            id: tooltipContent
            anchors.centerIn: parent
            spacing: 4

            Text {
                text: root.hoveredIndex >= 0 ? root.pointLabel(root.pointAt(root.hoveredIndex), root.hoveredIndex) : ""
                font.pixelSize: root.fontSize - 1
                color: root.tooltipTextColor
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // 显示所有数据系列的值
            Repeater {
                model: root.effectiveDataSeries

                Row {
                    id: tooltipSeries
                    required property var modelData

                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 5

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: tooltipSeries.modelData.color
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: tooltipSeries.modelData.name
                        font.pixelSize: root.fontSize - 2
                        color: root.subtitleColor
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: root.hoveredIndex >= 0 && tooltipSeries.modelData.data.length > root.hoveredIndex ? tooltipSeries.modelData.data[root.hoveredIndex].value : ""
                        font.pixelSize: root.fontSize - 1
                        color: root.tooltipTextColor
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    // === 底部图例 ===
    Row {
        id: legend
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 20
        spacing: 30
        visible: root.effectiveDataSeries.length > 1
                 || (root.effectiveDataSeries.length === 1
                     && root.effectiveDataSeries[0].name !== theme.localized("Data", "数据"))

        Repeater {
            model: root.effectiveDataSeries

            Row {
                id: legendSeries
                required property var modelData

                spacing: 8

                Rectangle {
                    width: 12
                    height: 12
                    radius: 2
                    color: legendSeries.modelData.color
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: legendSeries.modelData.name
                    font.pixelSize: root.fontSize - 2
                    color: root.subtitleColor
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // 监听线条样式变化
    Connections {
        target: root
        function onLineStyleChanged() {
            chartCanvas.requestPaint();
        }
    }

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "AreaChart"
        nameZh: "面积图"
    }
}
