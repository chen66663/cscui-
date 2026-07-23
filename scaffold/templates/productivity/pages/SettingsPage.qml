import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import cscui

Page {
    id: settingsPage
    required property var theme
    property var animWindowRef
    padding: 20
    background: Rectangle {
        color: "transparent"
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12

        Label {
            text: settingsPage.theme.localized("Settings", "设置")
            font.pixelSize: 24
            font.bold: true
            color: settingsPage.theme.textColor
            Layout.alignment: Qt.AlignHCenter
        }

        Button {
            theme: settingsPage.theme
            text: settingsPage.theme.isDark
                  ? settingsPage.theme.localized("Light theme", "浅色主题")
                  : settingsPage.theme.localized("Dark theme", "深色主题")
            iconCharacter: settingsPage.theme.isDark ? "\uf185" : "\uf186"
            iconRotateOnClick: true
            Layout.fillWidth: true
            onClicked: settingsPage.theme.toggleTheme()
        }

        Button {
            theme: settingsPage.theme
            text: settingsPage.theme.isChinese ? "English" : "中文"
            iconCharacter: "\uf1ab"
            accessibleName: settingsPage.theme.localized("Switch language to Chinese",
                                                         "切换语言为英语")
            Layout.fillWidth: true
            onClicked: settingsPage.theme.toggleLanguage()
        }

        Slider {
            id: animSlider
            theme: settingsPage.theme
            Layout.preferredWidth: 480
            text: settingsPage.theme.localized("Animation duration", "动画时长")
            itemSpacing: 10
            minimumValue: 300
            maximumValue: 3000
            decimals: 0
            stepSize: 50
            valueSuffix: "ms"
            value: settingsPage.animWindowRef ? settingsPage.animWindowRef.animDuration : settingsPage.theme.durationSlow
            onUserValueChanged: function(value) {
                if (settingsPage.animWindowRef)
                    settingsPage.animWindowRef.animDuration = Math.round(value)
            }
        }
    }

    Connections {
        target: settingsPage.animWindowRef
        function onAnimDurationChanged() {
            if (settingsPage.animWindowRef)
                animSlider.value = settingsPage.animWindowRef.animDuration
        }
    }
}
