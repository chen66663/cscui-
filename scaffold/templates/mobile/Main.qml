import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import cscui
import "pages"

ApplicationWindow {
    id: mainWindow
    readonly property bool isMobile: Qt.platform.os === "android" || Qt.platform.os === "ios"
    
    width: isMobile ? Screen.width : 375
    height: isMobile ? Screen.height : 812
    visibility: isMobile ? Window.FullScreen : Window.Windowed
    visible: true
    title: "{{PROJECT_NAME}}"

    color: theme.primaryColor

    FontLoader {
        id: iconFont
        source: "qrc:/cscui/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    Theme { id: theme }
    readonly property var appTheme: theme
    readonly property var navigationModel: [
        { display: appTheme.localized("Home", "首页"), iconChar: "\uf015" },
        { display: appTheme.localized("Search", "搜索"), iconChar: "\uf002" },
        { display: appTheme.localized("Settings", "设置"), iconChar: "\uf013" }
    ]

    StackLayout {
        id: contentStack
        anchors.fill: parent
        anchors.bottomMargin: 80
        currentIndex: 0

        HomePage { theme: mainWindow.appTheme }
        SearchPage { theme: mainWindow.appTheme }
        SettingsPage { theme: mainWindow.appTheme }
    }

    NavBar {
        theme: mainWindow.appTheme
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 20
        
        model: mainWindow.navigationModel
        
        currentIndex: contentStack.currentIndex
        
        onItemClicked: (index, data) => {
            contentStack.currentIndex = index
        }
    }
}
