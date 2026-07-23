import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import cscui
import "pages"

ApplicationWindow {
    id: mainWindow
    width: 960
    height: 540
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
        { display: appTheme.localized("Favorites", "收藏"), iconChar: "\uf005" },
        { display: appTheme.localized("Settings", "设置"), iconChar: "\uf013" }
    ]

    SplitView {
        anchors.fill: parent
        handle: Rectangle {
            implicitWidth: 0
            color: "transparent"
        }

        Pane {
            id: sidebar
            property bool expanded: false
            property int collapsedWidth: 85
            property int expandedWidth: 140
            padding: 0
            background: Rectangle {
                color: theme.secondaryColor
            }
            implicitWidth: expanded ? expandedWidth : collapsedWidth
            clip: false
            SplitView.minimumWidth: collapsedWidth
            SplitView.maximumWidth: expandedWidth
            SplitView.preferredWidth: implicitWidth

            Behavior on implicitWidth {
                NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
            }

            HoverHandler {
                onHoveredChanged: sidebar.expanded = hovered
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                List {
                    theme: mainWindow.appTheme
                    backgroundVisible: false
                    model: mainWindow.navigationModel
                    textShown: sidebar.expanded
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onItemClicked: function(index, data) { contentStack.currentIndex = index }
                }

                Item { Layout.fillHeight: true }
            }
        }

        StackLayout {
            id: contentStack
            currentIndex: 0
            clip: true
            Layout.fillWidth: true

            Item {
                id: homeContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                opacity: visible ? 1 : 0
                transform: Translate {
                    y: homeContainer.visible ? 0 : 12
                    Behavior on y { NumberAnimation { duration: mainWindow.appTheme.durationNormal; easing.type: Easing.OutCubic } }
                }
                Behavior on opacity { NumberAnimation { duration: mainWindow.appTheme.durationNormal; easing.type: Easing.OutCubic } }
                HomePage { id: homePage; anchors.fill: parent; theme: mainWindow.appTheme }
            }

            Item {
                id: favoritesContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                opacity: visible ? 1 : 0
                transform: Translate {
                    y: favoritesContainer.visible ? 0 : 12
                    Behavior on y { NumberAnimation { duration: mainWindow.appTheme.durationNormal; easing.type: Easing.OutCubic } }
                }
                Behavior on opacity { NumberAnimation { duration: mainWindow.appTheme.durationNormal; easing.type: Easing.OutCubic } }
                FavoritesPage { anchors.fill: parent; theme: mainWindow.appTheme }
            }

            Item {
                id: settingsContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                opacity: visible ? 1 : 0
                transform: Translate {
                    y: settingsContainer.visible ? 0 : 12
                    Behavior on y { NumberAnimation { duration: mainWindow.appTheme.durationNormal; easing.type: Easing.OutCubic } }
                }
                Behavior on opacity { NumberAnimation { duration: mainWindow.appTheme.durationNormal; easing.type: Easing.OutCubic } }
                SettingsPage {
                    anchors.fill: parent
                    theme: mainWindow.appTheme
                    animWindowRef: homePage.animatedWindow
                }
            }
        }
    }
}
