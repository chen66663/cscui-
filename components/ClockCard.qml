import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: root

    required property var theme

    width: 300
    height: 100

    // === 样式 ===
    property color faceColor: theme.secondaryColor
    property color textColor: theme.textColor
    property color accentColor: theme.focusColor
    property real radius: theme ? theme.radiusLarge : 12
    property bool backgroundVisible: true
    property bool shadowEnabled: true
    property color shadowColor: theme.shadowColor

    // === 时间与显示 ===
    property bool is24Hour: true
    property bool showSeconds: false
    property date now: new Date()

    function pad2(n) {
        return (n < 10 ? "0" : "") + n;
    }
    function hourStr(d) {
        let h = d.getHours();
        if (!is24Hour) {
            h = h % 12;
            if (h === 0)
                h = 12;
        }
        return pad2(h);
    }
    function minuteStr(d) {
        return pad2(d.getMinutes());
    }
    function secondStr(d) {
        return pad2(d.getSeconds());
    }
    function weekdayLabel(d) {
        const englishDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        const chineseDays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"];
        return theme.isChinese ? chineseDays[d.getDay()] : englishDays[d.getDay()];
    }

    readonly property string dateLine: theme.isChinese
                                               ? (now.getMonth() + 1) + "月" + now.getDate() + "日 " + weekdayLabel(now)
                                               : now.toLocaleDateString(theme.localeObject, "MMM d, ddd")

    // === 天气（可配置） ===
    FontLoader {
        id: iconFont
        source: root.theme ? root.theme.iconSource() : "qrc:/cscui/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }
    // 图标与温度可由外部覆盖
    property string weatherIcon: "\uf0c2"   // fa-cloud（默认）
    property int temperature: 26
    property bool weatherVisible: true

    // === 天气网络数据（心知天气 Seniverse） ===
    // Network access is opt-in. Credentials must be injected by the host app;
    // the component intentionally ships without a secret or a default request.
    property bool useNetworkWeather: false
    property string weatherApiKey: ""
    property string weatherLocation: "chengdu" // 支持城市名/行政区/经纬度等
    property string weatherLanguage: theme.isChinese ? "zh-Hans" : "en"
    property string weatherUnit: "c" // c=摄氏, f=华氏
    property bool weatherLoading: false
    property string weatherError: ""
    readonly property string weatherApiUrl: "https://api.seniverse.com/v3/weather/now.json?key=" + encodeURIComponent(weatherApiKey) + "&location=" + encodeURIComponent(weatherLocation) + "&language=" + encodeURIComponent(weatherLanguage) + "&unit=" + encodeURIComponent(weatherUnit)
    // 保留天气码（心知为字符串数字），用于调试或扩展
    property int weatherCode: -1

    function mapWeatherToIcon(text, code) {
        // 基于心知天气的 now.text 文本与 code 简单映射
        // 文本示例："晴"、"多云"、"阴"、"小雨"、"雷阵雨"、"雾"、"霾"、"小雪" 等
        const t = (text || "").toLowerCase();
        if (t.indexOf("雷") !== -1 || t.indexOf("thunder") !== -1)
            return "\uf76c"; // cloud-bolt
        if (t.indexOf("雨") !== -1 || t.indexOf("rain") !== -1 || t.indexOf("shower") !== -1) {
            if (t.indexOf("阵") !== -1 || t.indexOf("暴") !== -1 || t.indexOf("storm") !== -1)
                return "\uf740"; // cloud-showers-heavy
            return "\uf73d"; // cloud-rain
        }
        if (t.indexOf("雪") !== -1 || t.indexOf("冰") !== -1 || t.indexOf("snow") !== -1 || t.indexOf("ice") !== -1)
            return "\uf2dc"; // snowflake
        if (t.indexOf("雾") !== -1 || t.indexOf("霾") !== -1 || t.indexOf("fog") !== -1 || t.indexOf("haze") !== -1)
            return "\uf75f"; // smog
        if (t.indexOf("阴") !== -1 || t.indexOf("overcast") !== -1)
            return "\uf0c2"; // cloud
        if (t.indexOf("云") !== -1 || t.indexOf("cloud") !== -1)
            return "\uf6c4"; // cloud-sun
        if (t.indexOf("晴") !== -1 || t.indexOf("sun") !== -1 || t.indexOf("clear") !== -1)
            return "\uf185"; // sun
        // 兜底：依据 code 的粗略分类（可按需细化）
        if (code >= 10 && code <= 39)
            return "\uf73d"; // 各类雨
        if (code >= 40 && code <= 49)
            return "\uf75f"; // 雾/霾
        if (code >= 50 && code <= 59)
            return "\uf2dc"; // 各类雪
        return "\uf0c2"; // 默认 cloud
    }

    function fetchWeather() {
        if (!useNetworkWeather)
            return;
        if (!weatherApiKey || !weatherLocation) {
            weatherError = theme.localized("A weather API key and location are required.", "需要天气 API 密钥和位置。");
            return;
        }
        weatherLoading = true;
        weatherError = "";
        try {
            const xhr = new XMLHttpRequest();
            xhr.open("GET", weatherApiUrl);
            xhr.onreadystatechange = function () {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    root.weatherLoading = false;
                    if (xhr.status === 200) {
                        try {
                            const payload = JSON.parse(xhr.responseText);
                            const res = payload && payload.results && payload.results[0];
                            if (res && res.now) {
                                // 更新温度与图标（心知：now.temperature 为字符串）
                                root.temperature = Math.round(Number(res.now.temperature));
                                root.weatherCode = Number(res.now.code);
                                root.weatherIcon = mapWeatherToIcon(res.now.text, root.weatherCode);
                            } else {
                                root.weatherError = theme.localized("The weather service returned an invalid response.", "天气服务返回了无效响应。");
                            }
                        } catch (e) {
                            root.weatherError = theme.localized("The weather response could not be parsed.", "无法解析天气响应。");
                        }
                    } else {
                        root.weatherError = theme.localized("Weather request failed with status ", "天气请求失败，状态码：") + xhr.status + ".";
                    }
                }
            };
            xhr.send();
        } catch (err) {
            weatherLoading = false;
            weatherError = theme.localized("The weather request could not be started.", "无法启动天气请求。");
        }
    }

    // 每秒更新时间
    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        onTriggered: root.now = new Date()
    }

    // 每 15 分钟刷新天气
    Timer {
        interval: 15 * 60 * 1000
        running: root.visible && useNetworkWeather
        repeat: true
        onTriggered: fetchWeather()
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
        radius: root.radius
        color: faceColor
        visible: root.backgroundVisible
        antialiasing: true
    }

    // 内容布局
    Row {
        anchors.fill: parent
        anchors.margins: 12
        spacing: Math.max(12, width * 0.06)

        // 左侧大时间
        Row {
            id: timeRow
            spacing: 8
            width: Math.max(0, parent.width - rightColumn.width - 24)
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: hourStr(now)
                color: accentColor
                font.pixelSize: Math.min(42, Math.max(28, root.height * 0.36))
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                text: ":"
                color: theme.textColor
                font.pixelSize: Math.min(42, Math.max(28, root.height * 0.36))
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                text: minuteStr(now)
                color: theme.textColor
                font.pixelSize: Math.min(42, Math.max(28, root.height * 0.36))
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }
            // 可选秒
            Text {
                visible: showSeconds
                text: ":" + secondStr(now)
                color: theme.textColor
                font.pixelSize: Math.min(28, Math.max(20, root.height * 0.24))
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // 右侧天气与日期
        Column {
            id: rightColumn
            spacing: 6
            width: 110
            anchors.verticalCenter: parent.verticalCenter

            Row {
                spacing: 6
                visible: weatherVisible
                Text {
                    text: weatherIcon
                    font.family: root.theme ? root.theme.iconFamily(iconFont.name) : iconFont.name
                    font.pixelSize: 16
                    color: theme.textColor
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: temperature + "°"
                    font.pixelSize: 14
                    color: theme.textColor
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Text {
                text: dateLine
                color: theme.textColor
                font.pixelSize: 12
            }
        }
    }

    // 主题变化时刷新（影响颜色与日期颜色）
    Connections {
        target: theme
        enabled: !!theme
        ignoreUnknownSignals: true
        function onIsDarkChanged() {
            background.color = faceColor;
        }
        function onFocusColorChanged() {
        }
        function onTextColorChanged() {
        }
    }

    // API 参数变化时触发天气更新
    onWeatherLocationChanged: if (useNetworkWeather)
        fetchWeather()
    onWeatherApiKeyChanged: if (useNetworkWeather)
        fetchWeather()
    onWeatherLanguageChanged: if (useNetworkWeather)
        fetchWeather()
    onWeatherUnitChanged: if (useNetworkWeather)
        fetchWeather()
    Component.onCompleted: if (useNetworkWeather && weatherApiKey.length > 0)
        fetchWeather()

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "ClockCard"
        nameZh: "时钟卡片"
    }
}
