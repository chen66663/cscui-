import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import cscui

Page {
    required property var theme
    padding: 20
    background: Rectangle {
        color: "transparent"
    }

    Label {
        text: theme.localized("Favorites", "收藏")
        anchors.centerIn: parent
        font.pixelSize: 24
        color: theme.textColor
    }

    Flow {
        spacing: 16
        anchors.fill: parent

        Clock {

        }

    }
}
