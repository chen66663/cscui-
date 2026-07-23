import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: root

    required property var theme

    width: 260
    height: 90

    // === 样式 ===
    property color faceColor: theme.secondaryColor
    property color textColor: theme.textColor
    property color accentColor: theme.focusColor
    // 阴影
    property bool backgroundVisible: true
    property bool shadowEnabled: true
    property color shadowColor: theme.shadowColor

    // === 时间与计算 ===
    property date now: new Date()
    readonly property int year: now.getFullYear()

    function isLeap(y) {
        return (y % 4 === 0 && y % 100 !== 0) || (y % 400 === 0);
    }
    readonly property int totalDays: isLeap(year) ? 366 : 365

    function dayOfYear(d) {
        // UTC dates avoid daylight-saving transitions changing the day count.
        const start = Date.UTC(d.getFullYear(), 0, 1);
        const today = Date.UTC(d.getFullYear(), d.getMonth(), d.getDate());
        return Math.floor((today - start) / (24 * 3600 * 1000)) + 1;
    }
    readonly property int passedDays: dayOfYear(now)
    readonly property real progress: Math.min(1, Math.max(0, passedDays / totalDays))

    readonly property string pctStr: (progress * 100).toFixed(2) + "%"
    readonly property string titleLine: theme.isChinese
                                               ? "第 " + passedDays + " 天，共 " + totalDays + " 天"
                                               : passedDays + " of " + totalDays + " days"
    readonly property string subLine: theme.isChinese ? year + " 年进度" : year + " progress"
    function pad2(n) {
        return (n < 10 ? "0" : "") + n;
    }
    readonly property string todayLine: theme.isChinese
                                               ? (now.getMonth() + 1) + "月" + now.getDate() + "日"
                                               : now.toLocaleDateString(theme.localeObject, "MMM d")

    // 每分钟刷新一次
    Timer {
        interval: 60000
        running: root.visible
        repeat: true
        onTriggered: root.now = new Date()
    }

    // 阴影效果（只作用于背景卡片）
    MultiEffect {
        source: background
        anchors.fill: background
        visible: root.shadowEnabled && root.backgroundVisible
        shadowEnabled: true
        shadowColor: root.shadowColor
        shadowBlur: theme.shadowBlur
        shadowHorizontalOffset: theme.shadowXOffset
        shadowVerticalOffset: theme.shadowYOffset
    }

    // 背景卡片
    Rectangle {
        id: background
        anchors.fill: parent
        radius: theme ? theme.radiusLarge : 12
        color: faceColor
        visible: root.backgroundVisible
    }

    Row {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 24
        // 左侧文字
        Column {
            spacing: 6
            width: parent.width - ringContainer.width - 24
            Text {
                text: titleLine
                color: textColor
                font.pixelSize: 14
                font.bold: true
            }
            Row {
                spacing: 8
                Text {
                    text: pctStr
                    color: accentColor
                    font.pixelSize: 20
                    font.bold: true
                }
                Text {
                    text: subLine
                    color: textColor
                    font.pixelSize: 12
                }
            }
            Text {
                text: todayLine
                color: textColor
                font.pixelSize: 12
            }
        }

        // 右侧小圆环
        Item {
            id: ringContainer
            width: 36
            height: 36

            Canvas {
                id: ring
                anchors.fill: parent
                antialiasing: true
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const w = width, h = height;
                    const cx = w / 2, cy = h / 2;
                    const trackW = 5;
                    const r = Math.min(w, h) / 2 - trackW / 2;
                    const start = -Math.PI / 2;
                    const end = start + Math.PI * 2;
                    const prog = start + Math.PI * 2 * root.progress;

                    // 轨道
                    ctx.beginPath();
                    ctx.lineWidth = trackW;
                    ctx.strokeStyle = Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.25);
                    ctx.lineCap = "round";
                    ctx.arc(cx, cy, r, start, end, false);
                    ctx.stroke();

                    // 进度
                    ctx.beginPath();
                    ctx.lineWidth = trackW;
                    ctx.strokeStyle = accentColor;
                    ctx.lineCap = "round";
                    ctx.arc(cx, cy, r, start, prog, false);
                    ctx.stroke();
                }
            }

            // 动态重绘
            Connections {
                // 当 theme 尚未传入时，避免目标为空导致告警
                target: theme
                enabled: !!theme
                ignoreUnknownSignals: true
                function onFocusColorChanged() {
                    ring.requestPaint();
                }
                function onTextColorChanged() {
                    ring.requestPaint();
                }
                function onIsDarkChanged() {
                    ring.requestPaint();
                }
            }
            Component.onCompleted: ring.requestPaint()
            Connections {
                target: root
                function onProgressChanged() {
                    ring.requestPaint();
                }
                function onAccentColorChanged() {
                    ring.requestPaint();
                }
            }
            onVisibleChanged: if (visible)
                ring.requestPaint()
            onWidthChanged: ring.requestPaint()
            onHeightChanged: ring.requestPaint()
        }
    }

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "YearProgress"
        nameZh: "年度进度"
    }
}
