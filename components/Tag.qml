pragma ComponentBehavior: Bound

import QtQuick

// Compact status / category chip. Color alone is never the only cue: text is required.
Item {
    id: root

    property var theme: null
    // neutral | info | success | warning | danger | accent
    property string tone: "neutral"
    property string text: ""
    property bool filled: false

    readonly property var _palette: {
        const t = root.theme;
        const map = {
            "neutral": {
                fg: t ? t.secondaryTextColor : "#5C5C60",
                bg: t ? t.tertiaryColor : "#F2F2F7",
                bd: t ? t.separatorColor : "#D8D8DC"
            },
            "info": {
                fg: t ? t.infoColor : "#5AC8FA",
                bg: t ? Qt.rgba(t.infoColor.r, t.infoColor.g, t.infoColor.b, t.isDark ? 0.22 : 0.14) : "#E5F6FD",
                bd: t ? t.infoColor : "#5AC8FA"
            },
            "success": {
                fg: t ? t.successColor : "#34C759",
                bg: t ? Qt.rgba(t.successColor.r, t.successColor.g, t.successColor.b, t.isDark ? 0.22 : 0.14) : "#E5F8EA",
                bd: t ? t.successColor : "#34C759"
            },
            "warning": {
                fg: t ? t.warningColor : "#FF9F0A",
                bg: t ? Qt.rgba(t.warningColor.r, t.warningColor.g, t.warningColor.b, t.isDark ? 0.22 : 0.14) : "#FFF4E0",
                bd: t ? t.warningColor : "#FF9F0A"
            },
            "danger": {
                fg: t ? t.dangerColor : "#FF3B30",
                bg: t ? Qt.rgba(t.dangerColor.r, t.dangerColor.g, t.dangerColor.b, t.isDark ? 0.22 : 0.14) : "#FFE8E6",
                bd: t ? t.dangerColor : "#FF3B30"
            },
            "accent": {
                fg: t ? t.focusColor : "#0066CC",
                bg: t ? t.selectionColor : "#D9ECFF",
                bd: t ? t.focusColor : "#0066CC"
            }
        };
        return map[root.tone] || map["neutral"];
    }

    implicitWidth: Math.max(label.implicitWidth + (root.theme ? root.theme.spacingMedium : 12), 36)
    implicitHeight: Math.max(22, (root.theme ? root.theme.fontSizeCaption : 11) + 10)
    Accessible.role: Accessible.StaticText
    Accessible.name: root.text

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.filled ? root._palette.bd : root._palette.bg
        border.width: root.filled ? 0 : 1
        border.color: root._palette.bd
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.filled ? (root.theme ? root.theme.onAccentColor : "#FFFFFF") : root._palette.fg
        font.family: root.theme ? root.theme.fontFamily : "sans-serif"
        font.pixelSize: root.theme ? Math.max(11, root.theme.fontSizeCaption) : 11
        font.weight: Font.DemiBold
        elide: Text.ElideRight
        width: Math.min(implicitWidth, root.width - 12)
        horizontalAlignment: Text.AlignHCenter
    }

    CscIdentityLayer {
        active: false
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "Tag"
        nameZh: "标签"
    }
}
