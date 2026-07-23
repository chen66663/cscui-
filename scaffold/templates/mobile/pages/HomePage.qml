import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import cscui

Page {
    id: homePage
    required property var theme
    background: Rectangle { color: "transparent" }
    
    header: Label {
        text: homePage.theme.localized("Home", "首页")
        font.pixelSize: 24
        font.bold: true
        padding: 20
        horizontalAlignment: Text.AlignHCenter
        color: theme.textColor
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20

        Button {
            theme: homePage.theme
            Layout.alignment: Qt.AlignHCenter
            text: homePage.theme.localized("Welcome to cscui", "欢迎使用 cscui")
            iconCharacter: "\uf015"
            onClicked: console.log(homePage.theme.localized("Welcome clicked", "已点击欢迎按钮"))
        }

        Label {
            text: homePage.theme.localized("This is the home page", "这是首页")
            font.pixelSize: 16
            color: theme.textColor
            Layout.alignment: Qt.AlignHCenter
        }   
    }
}
