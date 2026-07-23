import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import cscui

Page {
    id: settingsPage
    required property var theme
    background: Rectangle { color: "transparent" }

    header: Label {
        text: settingsPage.theme.localized("Settings", "设置")
        font.pixelSize: 24
        font.bold: true
        padding: 20
        horizontalAlignment: Text.AlignHCenter
        color: theme.textColor
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20
        
        Label {
            text: settingsPage.theme.localized("Appearance and language", "外观与语言")
            font.pixelSize: 16
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
    }
}
