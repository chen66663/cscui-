pragma ComponentBehavior: Bound

import QtQuick

// Shared visual contract for cscui. Pages consume semantic tokens instead of
// owning palette values, which keeps light/dark and accessibility variants in sync.
QtObject {
    id: theme

    property string mode: "auto"
    property alias requestedMode: theme.mode
    property bool isDark: false
    // Language is kept beside the visual theme so every dynamically loaded
    // page observes one runtime-switchable locale. "auto" follows the host
    // locale; explicit "en" and "zh" values are stable for tests and embeds.
    property string language: "auto"
    property alias requestedLanguage: theme.language
    readonly property string systemLanguage: Qt.locale().name.toLowerCase().indexOf("zh") === 0 ? "zh" : "en"
    readonly property string effectiveLanguage: language === "auto" ? systemLanguage : language
    readonly property bool isChinese: effectiveLanguage === "zh"
    readonly property var localeObject: Qt.locale(isChinese ? "zh_CN" : "en_US")
    property bool reducedMotion: false
    // Convenience gate for Behaviors / continuous loops.
    readonly property bool motionEnabled: !reducedMotion
    property bool highContrast: false
    property bool showLayoutBounds: false
    property int openAnimatedWindowCount: 0
    readonly property bool anyAnimatedWindowOpen: openAnimatedWindowCount > 0

    // Qt 6.5+ exposes the platform appearance through styleHints. Unknown
    // schemes intentionally fall back to light mode for predictable contrast.
    readonly property bool systemPrefersDark: Application.styleHints.colorScheme === Qt.Dark

    // Canvas and surface hierarchy mirrors the macOS grouped-material model.
    readonly property color primaryColor: isDark ? "#1C1C1E" : "#F5F5F7"
    readonly property color secondaryColor: isDark ? "#2C2C2E" : "#FFFFFF"
    readonly property color tertiaryColor: isDark ? "#3A3A3C" : "#F2F2F7"
    readonly property color elevatedColor: isDark ? "#323234" : "#FFFFFF"
    readonly property color sidebarColor: isDark ? "#242426" : "#ECECF0"
    readonly property color textColor: isDark ? "#F5F5F7" : "#1D1D1F"
    readonly property color secondaryTextColor: isDark ? "#AEAEB2" : "#5C5C60"
    readonly property color tertiaryTextColor: isDark ? "#8E8E93" : "#6E6E73"
    readonly property color borderColor: highContrast ? (isDark ? "#A1A1A6" : "#545458") : (isDark ? "#48484A" : "#D1D1D6")
    readonly property color separatorColor: highContrast
                                          ? (isDark ? "#5A5A5E" : "#B8B8BE")
                                          : (isDark ? "#3A3A3C" : "#D8D8DC")
    readonly property color hoverColor: highContrast
                                    ? (isDark ? "#454548" : "#DEDEE4")
                                    : (isDark ? "#3A3A3C" : "#E5E5EA")
    readonly property color pressedColor: highContrast
                                      ? (isDark ? "#5A5A5E" : "#B8B8BE")
                                      : (isDark ? "#48484A" : "#D1D1D6")
    // The selected surface is paired with focusColor text/icons. Keep both
    // pairs above 4.5:1 in normal and high-contrast themes.
    readonly property color selectionColor: highContrast
                                       ? (isDark ? "#234E73" : "#C2E0FF")
                                       : (isDark ? "#193B61" : "#D9ECFF")
    readonly property color blurOverlayColor: isDark ? "#D929292B" : "#D9FFFFFF"

    // Descriptive aliases let new code read like the design system while
    // retaining primary/secondary/tertiary names used by legacy components.
    readonly property color canvasColor: primaryColor
    readonly property color surfaceColor: secondaryColor
    readonly property color surfaceSecondaryColor: tertiaryColor
    readonly property color panelColor: elevatedColor
    readonly property color onSurfaceColor: textColor
    readonly property color mutedTextColor: secondaryTextColor
    readonly property color accentColor: focusColor

    // Apple blue is attractive but fails normal-text contrast on white and on
    // the selected surface. These tonal variants preserve the same hue while
    // meeting WCAG AA in both appearance modes.
    readonly property color defaultFocusColor: isDark
                                              ? (highContrast ? "#8CC8FF" : "#66B2FF")
                                              : (highContrast ? "#0052A3" : "#0066CC")
    property color focusColor: defaultFocusColor
    readonly property color onAccentColor: contrastTextColor(focusColor)
    readonly property color successColor: "#34C759"
    readonly property color warningColor: "#FF9F0A"
    readonly property color dangerColor: "#FF3B30"
    readonly property color infoColor: "#5AC8FA"

    property real musicVolume: 0.2

    readonly property color shadowColor: isDark ? "#70000000" : "#24000000"
    readonly property real shadowBlur: isDark ? 0.45 : 0.32
    readonly property int shadowXOffset: 0
    readonly property int shadowYOffset: 4

    // Radius, spacing, type and control dimensions form the compact desktop
    // scale. Interactive controls keep a 44 px minimum hit target.
    readonly property int radiusSmall: 6
    readonly property int radiusMedium: 8
    readonly property int radiusLarge: 12
    readonly property int spacingXs: 4
    readonly property int spacingSmall: 8
    readonly property int spacingMedium: 12
    readonly property int spacingLarge: 16
    readonly property int spacingXLarge: 24
    readonly property int fontSizeCaption: 11
    readonly property int fontSizeBody: 13
    readonly property int fontSizeTitle: 17
    readonly property int fontSizeHeading: 22
    readonly property int controlHeightSmall: 32
    readonly property int controlHeight: 36
    readonly property int touchTarget: 44
    readonly property int durationFast: reducedMotion ? 0 : 140
    readonly property int durationNormal: reducedMotion ? 0 : 220
    readonly property int durationSlow: reducedMotion ? 0 : 320

    readonly property string fontFamily: Qt.platform.os === "osx" ? ".AppleSystemUIFont" : (Qt.platform.os === "windows" ? "Segoe UI Variable" : "Noto Sans")
    readonly property string monoFontFamily: Qt.platform.os === "windows" ? "Cascadia Mono" : (Qt.platform.os === "osx" ? "SF Mono" : "monospace")
    // Filled by the shell FontLoader once ready. Empty => components load locally.
    property string iconFontFamily: ""
    readonly property bool hasIconFont: iconFontFamily.length > 0
    readonly property string iconFontUrl:
        "qrc:/cscui/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    function iconFamily(fallback) { return hasIconFont ? iconFontFamily : fallback }
    function iconSource() { return hasIconFont ? "" : iconFontUrl }

    function getBorderColor(focused) {
        return focused ? focusColor : borderColor;
    }

    function contrastTextColor(backgroundColor) {
        const c = Qt.color(backgroundColor);
        const channel = function (value) {
            return value <= 0.04045 ? value / 12.92 : Math.pow((value + 0.055) / 1.055, 2.4);
        };
        const luminance = 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
        const whiteContrast = 1.05 / (luminance + 0.05);
        // #1D1D1F is the primary foreground token used by the light theme.
        const darkContrast = (luminance + 0.05) / 0.063;
        return whiteContrast >= darkContrast ? "#FFFFFF" : "#1D1D1F";
    }

    function setMode(nextMode) {
        const normalized = (nextMode === "light" || nextMode === "dark" || nextMode === "auto") ? nextMode : "auto";
        mode = normalized;
        isDark = normalized === "dark" || (normalized === "auto" && systemPrefersDark);
    }

    function toggleTheme() {
        setMode(isDark ? "light" : "dark");
    }

    function setLanguage(nextLanguage) {
        const normalized = String(nextLanguage || "auto").trim().toLowerCase();
        language = (normalized === "en" || normalized === "zh" || normalized === "auto") ? normalized : "auto";
    }

    function toggleLanguage() {
        setLanguage(isChinese ? "en" : "zh");
    }

    // Calling this function from a binding records a dependency on
    // effectiveLanguage, so every label updates immediately without recreating
    // the page or installing a process-wide QTranslator.
    function localized(englishText, chineseText) {
        const currentLanguage = effectiveLanguage;
        if (currentLanguage === "zh" && chineseText !== undefined && chineseText !== null)
            return String(chineseText);
        return String(englishText === undefined || englishText === null ? "" : englishText);
    }

    function resetAccessibility() {
        reducedMotion = false;
        highContrast = false;
        showLayoutBounds = false;
    }

    Component.onCompleted: {
        setMode(mode);
        setLanguage(language);
    }

    Behavior on focusColor {
        ColorAnimation {
            duration: theme.durationNormal
            easing.type: Easing.OutCubic
        }
    }
}
