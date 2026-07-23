import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import cscui

Page {
    id: searchPage
    required property var theme
    background: Rectangle { color: "transparent" }

    header: Label {
        text: searchPage.theme.localized("Search", "搜索")
        font.pixelSize: 24
        font.bold: true
        padding: 20
        horizontalAlignment: Text.AlignHCenter
        color: theme.textColor
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20
        width: parent.width * 0.8

        Input {
            theme: searchPage.theme
            Layout.fillWidth: true
            placeholderText: searchPage.theme.localized("Search…", "搜索…")
        }

        Button {
            theme: searchPage.theme
            text: searchPage.theme.localized("Search", "搜索")
            Layout.alignment: Qt.AlignHCenter
            onClicked: console.log(searchPage.theme.localized("Search clicked", "已点击搜索"))
        }
    }
}
