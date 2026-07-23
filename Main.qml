pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "components" as Components

ApplicationWindow {
    id: root

    visible: true
    width: requestedWidth > 0 ? requestedWidth : 1280
    height: requestedHeight > 0 ? requestedHeight : 820
    minimumWidth: 760
    minimumHeight: 560
    title: "cscui"
    color: root.runtimeTheme.canvasColor
    flags: Qt.Window | Qt.FramelessWindowHint

    // These properties are populated by QQmlApplicationEngine before loading;
    // keeping them on the root avoids hidden context-property dependencies.
    property bool debugUi: false
    property bool autoAnimatedDemo: false
    property string buildMode: "Unknown"
    property string themeMode: "auto"
    property string languageMode: "auto"
    property string screenshotPath: ""
    property int requestedWidth: 0
    property int requestedHeight: 0
    property int requestedPage: 0
    // C++ exposes this instance as a root-context compatibility bridge for
    // legacy components that still resolve `theme` lexically. The context
    // property is intentionally the sole unqualified access in this file.
    // qmllint disable unqualified
    readonly property var runtimeTheme: theme
    // qmllint enable unqualified
    property bool debugVisible: debugUi
    property int currentIndex: 0
    property int displayedIndex: 0
    property int previousIndex: -1
    property bool pageTransitionRunning: false
    property int pageTransitionDirection: 1
    property var activatedPages: [false, false, false]
    property var pageScrollPositions: [0, 0, 0]
    property var incomingPageLoader: null
    property var outgoingPageLoader: null
    property string animatedContentMode: "demo"
    property var pendingAnimatedSource: null
    // Frameless windows on Windows often leave visibility stuck after
    // showMaximized(); track geometry ourselves so green light can restore.
    property bool customMaximized: false
    property real restoreX: 0
    property real restoreY: 0
    property real restoreWidth: 1280
    property real restoreHeight: 820

    readonly property bool isEffectivelyMaximized: root.customMaximized
            || root.visibility === Window.Maximized
    readonly property int titleBarHeight: 52
    readonly property int resizeMargin: 6
    readonly property int inspectorWidth: Math.min(320, Math.max(280, Math.round(width * 0.28)))
    readonly property int usableWorkspaceWidth: width - (root.debugVisible ? root.inspectorWidth : 0)
    readonly property bool compactNavigation: usableWorkspaceWidth < 860
    readonly property int navigationWidth: compactNavigation ? 76 : 228
    readonly property var currentPage: navigationModel[currentIndex]
    readonly property string currentPageLabel: pageLabel(currentPage)
    readonly property string currentPageSubtitle: pageSubtitle(currentPage)
    // Exposed for the command-line screenshot harness. Pages are incubated
    // asynchronously, so a fixed startup delay can capture only the spinner
    // on the heavier extended catalogue.
    property bool currentPageReady: false
    readonly property string focusDescription: {
        const focused = root.activeFocusItem;
        if (!focused)
            return root.runtimeTheme.localized("None", "无");
        return focused.objectName && focused.objectName.length > 0
                ? focused.objectName
                : root.runtimeTheme.localized("Item", "项目");
    }
    readonly property real devicePixelRatio: Screen.devicePixelRatio

    // The source paths are intentionally stable: external pages and smoke tests
    // use this three-destination contract when embedding the catalogue.
    readonly property var navigationModel: [
        {
            labelEn: "Today's Workflow",
            labelZh: "今日工作流",
            subtitleEn: "Actions, forms and confirmation feedback",
            subtitleZh: "操作、表单与确认反馈",
            icon: "\uf1b2",
            source: "pages/BaseComponents.qml"
        },
        {
            labelEn: "Schedule and Content",
            labelZh: "日程与资料",
            subtitleEn: "Lists, calendar, notes and tables",
            subtitleZh: "列表、日历、备注与表格",
            icon: "\uf5fd",
            source: "pages/NoBackgroundComponents.qml"
        },
        {
            labelEn: "Life Dashboard",
            labelZh: "生活看板",
            subtitleEn: "Widgets, charts and opt-in media",
            subtitleZh: "小组件、图表与按需媒体",
            icon: "\uf201",
            source: "pages/OtherComponents.qml"
        }
    ]

    function pageLabel(page) {
        return page
                ? root.runtimeTheme.localized(page.labelEn, page.labelZh)
                : "";
    }

    function pageSubtitle(page) {
        return page
                ? root.runtimeTheme.localized(page.subtitleEn, page.subtitleZh)
                : "";
    }

    function toggleAboutDrawer() {
        aboutDrawer.toggle();
        root.logEvent(root.runtimeTheme.localized("About panel: ", "关于面板：")
                      + (aboutDrawer.opened
                         ? root.runtimeTheme.localized("opened", "已打开")
                         : root.runtimeTheme.localized("closed", "已关闭")));
    }

    function toggleMaximized() {
        if (root.isEffectivelyMaximized) {
            root.customMaximized = false;
            root.showNormal();
            // Always re-apply the pre-maximize geometry. Frameless Windows
            // builds frequently ignore showNormal()'s size restore.
            root.x = root.restoreX;
            root.y = root.restoreY;
            root.width = root.restoreWidth;
            root.height = root.restoreHeight;
            return;
        }

        root.restoreX = root.x;
        root.restoreY = root.y;
        root.restoreWidth = root.width;
        root.restoreHeight = root.height;
        root.customMaximized = true;
        root.showMaximized();

        // If the platform did not enter Maximized for a frameless window,
        // fill the screen available area manually.
        Qt.callLater(function () {
            if (!root.customMaximized)
                return;
            if (root.visibility === Window.Maximized)
                return;
            const scr = root.screen;
            if (!scr)
                return;
            root.x = scr.virtualX;
            root.y = scr.virtualY;
            root.width = scr.desktopAvailableWidth > 0 ? scr.desktopAvailableWidth : scr.width;
            root.height = scr.desktopAvailableHeight > 0 ? scr.desktopAvailableHeight : scr.height;
        });
    }

    function toggleDebugPanel() {
        root.debugVisible = !root.debugVisible;
        root.logEvent(root.runtimeTheme.localized("UI inspector: ", "界面检查器：")
                      + (root.debugVisible
                         ? root.runtimeTheme.localized("opened", "已打开")
                         : root.runtimeTheme.localized("closed", "已关闭")));
    }

    function logEvent(message) {
        if (debugPanel)
            debugPanel.addEvent(message);
    }

    function pageLoaderAt(index) {
        return index >= 0 && index < root.navigationModel.length
                ? pageLoaderRepeater.itemAt(index)
                : null;
    }

    function setPageActivated(index, active) {
        if (index < 0 || index >= root.navigationModel.length)
            return;
        // Avoid rewriting the activation array when nothing changes; that
        // rebinds every page Loader.active and can hitch navigation.
        if (root.activatedPages[index] === active)
            return;
        const next = root.activatedPages.slice();
        next[index] = active;
        root.activatedPages = next;
    }

    function savePageScroll(index) {
        if (index < 0 || index >= root.navigationModel.length)
            return;
        const next = root.pageScrollPositions.slice();
        next[index] = contentFlickable.contentY;
        root.pageScrollPositions = next;
    }

    function finishPageTransition() {
        if (root.incomingPageLoader) {
            root.incomingPageLoader.opacity = 1;
            root.incomingPageLoader.transitionOffset = 0;
            root.incomingPageLoader.transitionScale = 1;
            root.incomingPageLoader.visible = true;
        }
        if (root.outgoingPageLoader && root.outgoingPageLoader !== root.incomingPageLoader) {
            root.outgoingPageLoader.opacity = 0;
            root.outgoingPageLoader.transitionOffset = 0;
            root.outgoingPageLoader.transitionScale = 1;
            root.outgoingPageLoader.visible = false;
        }
        root.pageTransitionRunning = false;
        root.previousIndex = -1;
        root.outgoingPageLoader = null;
        root.incomingPageLoader = null;
    }

    function commitPage(index) {
        const target = root.pageLoaderAt(index);
        if (!target || target.status !== Loader.Ready)
            return;
        if (index === root.displayedIndex) {
            target.visible = true;
            target.opacity = 1;
            target.transitionOffset = 0;
            const savedY = root.pageScrollPositions[index] || 0;
            if (Math.abs(contentFlickable.contentY - savedY) > 0.5)
                contentFlickable.contentY = savedY;
            return;
        }

        if (pageTransition.running) {
            pageTransition.stop();
            root.finishPageTransition();
        }

        root.previousIndex = root.displayedIndex;
        root.outgoingPageLoader = root.pageLoaderAt(root.previousIndex);
        root.incomingPageLoader = target;
        root.pageTransitionDirection = index > root.previousIndex ? 1 : -1;
        root.displayedIndex = index;

        // Outgoing off: animate only the incoming tree.
        if (root.outgoingPageLoader && root.outgoingPageLoader !== target) {
            root.outgoingPageLoader.visible = false;
            root.outgoingPageLoader.opacity = 0;
            root.outgoingPageLoader.transitionOffset = 0;
        }

        const savedY = root.pageScrollPositions[index] || 0;
        if (Math.abs(contentFlickable.contentY - savedY) > 0.5)
            contentFlickable.contentY = savedY;

        const motion = root.runtimeTheme ? root.runtimeTheme.motionEnabled : true;
        target.visible = true;
        if (!motion) {
            target.opacity = 1;
            target.transitionOffset = 0;
            target.transitionScale = 1;
            root.finishPageTransition();
            return;
        }

        // Fade + slide + micro-scale (transform only).
        target.opacity = 0;
        target.transitionOffset = root.pageTransitionDirection * 36;
        target.transitionScale = 0.985;
        root.pageTransitionRunning = true;
        pageTitleChrome.opacity = 0;
        pageTransition.restart();
        pageTitleIn.restart();
    }

    function activatePage(index) {
        if (index < 0 || index >= root.navigationModel.length || index === root.currentIndex)
            return;
        root.savePageScroll(root.displayedIndex);
        root.setPageActivated(index, true);
        root.currentIndex = index;
        const target = root.pageLoaderAt(index);
        if (target && target.status === Loader.Ready) {
            // Keep ready state stable for preloaded destinations to avoid a
            // one-frame spinner flash on every navigation click.
            root.currentPageReady = target.item !== null;
            root.commitPage(index);
        } else {
            root.currentPageReady = false;
        }
        Qt.callLater(function () {
            root.logEvent(root.runtimeTheme.localized("Page: ", "页面：") + root.pageLabel(root.navigationModel[index]));
        });
    }

    function preloadNextPage() {
        // Prefer nearest unloaded pages, but never start a second incubation
        // while one is still Loading — keeps the GUI thread responsive.
        for (let index = 0; index < root.navigationModel.length; ++index) {
            const loader = root.pageLoaderAt(index);
            if (root.activatedPages[index] && loader && loader.status === Loader.Loading)
                return;
        }

        let candidate = -1;
        let candidateDistance = Number.MAX_VALUE;
        for (let pageIndex = 0; pageIndex < root.navigationModel.length; ++pageIndex) {
            if (root.activatedPages[pageIndex])
                continue;
            const distance = Math.abs(pageIndex - root.currentIndex);
            if (distance < candidateDistance) {
                candidate = pageIndex;
                candidateDistance = distance;
            }
        }
        if (candidate >= 0)
            root.setPageActivated(candidate, true);
        else
            pagePreloadTimer.stop();
    }

    function scheduleBackgroundPreload() {
        if (!pagePreloadTimer.running)
            pagePreloadTimer.start();
        // Kick one candidate immediately so the first idle frame is used.
        Qt.callLater(root.preloadNextPage);
    }

    function openMusicWindow(player) {
        if (!player)
            return;
        animatedWindow.applyProfile(null);
        root.animatedContentMode = "music";
        root.pendingAnimatedSource = player;
        animatedContentLoader.active = true;
        if (animatedContentLoader.item)
            animatedContentLoader.item.sourceItem = player;
        animatedWindow.open(player, root.runtimeTheme.localized("Now playing", "正在播放"));
    }

    function openAnimatedDemo(source, animationProfile) {
        if (!source)
            return;
        animatedWindow.applyProfile(animationProfile);
        root.animatedContentMode = "demo";
        root.pendingAnimatedSource = null;
        animatedContentLoader.active = true;
        animatedWindow.open(source, root.runtimeTheme.localized("Animated window", "动画窗口"));
    }

    FontLoader {
        id: iconFont
        source: "qrc:/cscui/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
        onStatusChanged: {
            if (status === FontLoader.Ready && root.runtimeTheme)
                root.runtimeTheme.iconFontFamily = name;
        }
        Component.onCompleted: {
            if (status === FontLoader.Ready && root.runtimeTheme)
                root.runtimeTheme.iconFontFamily = name;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.runtimeTheme.canvasColor
    }

    Rectangle {
        id: titleBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.titleBarHeight
        color: root.runtimeTheme.sidebarColor
        border.width: root.runtimeTheme.showLayoutBounds ? 2 : 0
        border.color: root.runtimeTheme.dangerColor
        z: 50

        MouseArea {
            anchors.fill: parent
            anchors.leftMargin: 132
            anchors.rightMargin: 132
            acceptedButtons: Qt.LeftButton
            onPressed: root.startSystemMove()
            onDoubleClicked: root.toggleMaximized()
        }

        Row {
            id: trafficLights
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            z: 2

            Repeater {
                model: [
                    {
                        color: "#FF5F57",
                        glyph: "\uf00d",
                        name: root.runtimeTheme.localized("Close window", "关闭窗口"),
                        action: 0
                    },
                    {
                        color: "#FEBC2E",
                        glyph: "\uf068",
                        name: root.runtimeTheme.localized("Minimize window", "最小化窗口"),
                        action: 1
                    },
                    {
                        color: "#28C840",
                        glyph: root.isEffectivelyMaximized ? "\uf066" : "\uf065",
                        name: root.isEffectivelyMaximized
                              ? root.runtimeTheme.localized("Restore window", "还原窗口")
                              : root.runtimeTheme.localized("Maximize window", "最大化窗口"),
                        action: 2
                    }
                ]

                delegate: Item {
                    id: trafficButton
                    required property var modelData
                    width: 44
                    height: 44
                    objectName: trafficButton.modelData.name
                    activeFocusOnTab: true

                    Accessible.role: Accessible.Button
                    Accessible.name: trafficButton.modelData.name

                    function activate() {
                        if (trafficButton.modelData.action === 0)
                            root.close();
                        else if (trafficButton.modelData.action === 1)
                            root.showMinimized();
                        else
                            root.toggleMaximized();
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 13
                        height: 13
                        radius: width / 2
                        color: trafficButton.modelData.color
                        border.width: 1
                        border.color: Qt.darker(trafficButton.modelData.color, 1.12)

                        Text {
                            anchors.centerIn: parent
                            visible: trafficPointer.containsMouse
                            text: trafficButton.modelData.glyph
                            color: Qt.darker(trafficButton.modelData.color, 2.4)
                            font.family: iconFont.name
                            font.pixelSize: 7
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: root.runtimeTheme.radiusSmall
                        color: "transparent"
                        border.width: trafficButton.activeFocus ? 2 : 0
                        border.color: root.runtimeTheme.focusColor
                    }

                    MouseArea {
                        id: trafficPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: trafficButton.activate()
                    }

                    Keys.onSpacePressed: trafficButton.activate()
                    Keys.onReturnPressed: trafficButton.activate()
                    Keys.onEnterPressed: trafficButton.activate()

                    ToolTip.visible: trafficPointer.containsMouse
                    ToolTip.text: trafficButton.modelData.name
                    ToolTip.delay: 600
                }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 1

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "cscui"
                color: root.runtimeTheme.textColor
                font.family: root.runtimeTheme.fontFamily
                font.pixelSize: root.runtimeTheme.fontSizeBody
                font.weight: Font.DemiBold
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.currentPageLabel
                color: root.runtimeTheme.tertiaryTextColor
                font.family: root.runtimeTheme.fontFamily
                font.pixelSize: root.runtimeTheme.fontSizeCaption
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: root.runtimeTheme.spacingSmall
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.runtimeTheme.spacingXs
            z: 2

            Components.CscIconButton {
                // Qualify the outer theme explicitly. In a bound component,
                // `theme: theme` resolves the right-hand side to this button's
                // own property and leaves the control unthemed.
                theme: root.runtimeTheme
                iconCharacter: theme.isDark ? "\uf185" : "\uf186"
                accessibleName: theme.isDark
                                ? root.runtimeTheme.localized("Switch to light theme", "切换到浅色主题")
                                : root.runtimeTheme.localized("Switch to dark theme", "切换到深色主题")
                toolTip: accessibleName
                onClicked: theme.toggleTheme()
            }

            Components.CscIconButton {
                theme: root.runtimeTheme
                iconCharacter: "\uf1ab"
                accessibleName: root.runtimeTheme.isChinese
                                ? root.runtimeTheme.localized("Switch to English", "切换到英文")
                                : root.runtimeTheme.localized("Switch to Chinese", "切换到中文")
                toolTip: accessibleName
                onClicked: root.runtimeTheme.toggleLanguage()
            }

            Components.CscIconButton {
                theme: root.runtimeTheme
                iconCharacter: "\uf188"
                accessibleName: root.runtimeTheme.localized("Toggle UI inspector", "切换界面检查器")
                toolTip: root.runtimeTheme.localized("Toggle UI inspector (Ctrl+Shift+D)", "切换界面检查器（Ctrl+Shift+D）")
                checked: root.debugVisible
                checkable: true
                onClicked: root.toggleDebugPanel()
            }

            Components.CscIconButton {
                theme: root.runtimeTheme
                iconCharacter: "\uf129"
                accessibleName: root.runtimeTheme.localized("Open about and component index", "打开关于与组件索引")
                toolTip: accessibleName
                checked: aboutDrawer.opened
                checkable: true
                onClicked: root.toggleAboutDrawer()
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: root.runtimeTheme.separatorColor
        }
    }

    Item {
        id: workspace
        anchors.top: titleBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        // Reserve inspector space at every breakpoint so debug mode never
        // places an opaque panel over controls that still need interaction.
        anchors.rightMargin: root.debugVisible ? root.inspectorWidth : 0

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                id: navigationRail
                Layout.fillHeight: true
                Layout.preferredWidth: root.navigationWidth
                color: root.runtimeTheme.sidebarColor
                border.width: root.runtimeTheme.showLayoutBounds ? 2 : 0
                border.color: root.runtimeTheme.dangerColor

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: root.runtimeTheme.spacingMedium
                    spacing: root.runtimeTheme.spacingSmall

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        spacing: root.runtimeTheme.spacingSmall

                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: root.runtimeTheme.radiusMedium
                            color: root.runtimeTheme.focusColor

                            Text {
                                anchors.centerIn: parent
                                text: "C"
                                color: root.runtimeTheme.onAccentColor
                                font.family: root.runtimeTheme.fontFamily
                                font.pixelSize: 18
                                font.weight: Font.Bold
                            }
                        }

                        ColumnLayout {
                            visible: !root.compactNavigation
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: "cscui"
                                color: root.runtimeTheme.textColor
                                font.family: root.runtimeTheme.fontFamily
                                font.pixelSize: root.runtimeTheme.fontSizeTitle
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: root.runtimeTheme.localized("Personal workbench", "个人工作台")
                                color: root.runtimeTheme.secondaryTextColor
                                font.family: root.runtimeTheme.fontFamily
                                font.pixelSize: root.runtimeTheme.fontSizeCaption
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Text {
                        visible: !root.compactNavigation
                        text: root.runtimeTheme.localized("SCENES", "场景")
                        color: root.runtimeTheme.tertiaryTextColor
                        font.family: root.runtimeTheme.fontFamily
                        font.pixelSize: root.runtimeTheme.fontSizeCaption
                        font.weight: Font.DemiBold
                        Layout.leftMargin: root.runtimeTheme.spacingSmall
                        Layout.topMargin: root.runtimeTheme.spacingSmall
                    }

                    Repeater {
                        model: root.navigationModel

                        delegate: FocusScope {
                            id: navigationItem
                            required property int index
                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: root.runtimeTheme.touchTarget
                            activeFocusOnTab: true
                            objectName: root.pageLabel(navigationItem.modelData)

                            Accessible.role: Accessible.Button
                            Accessible.name: root.pageLabel(navigationItem.modelData)
                            Accessible.description: root.pageSubtitle(navigationItem.modelData)
                            Accessible.selected: navigationItem.index === root.currentIndex

                            Rectangle {
                                anchors.fill: parent
                                radius: root.runtimeTheme.radiusMedium
                                color: {
                                    if (navigationItem.index === root.currentIndex)
                                        return root.runtimeTheme.selectionColor;
                                    if (navigationPointer.containsMouse || navigationItem.activeFocus)
                                        return root.runtimeTheme.hoverColor;
                                    return "transparent";
                                }
                                border.width: navigationItem.activeFocus ? 2 : 0
                                border.color: root.runtimeTheme.focusColor

                                Behavior on color {
                                    ColorAnimation {
                                        duration: root.runtimeTheme.durationNormal
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: root.compactNavigation ? 0 : root.runtimeTheme.spacingSmall
                                anchors.rightMargin: root.runtimeTheme.spacingSmall
                                spacing: root.runtimeTheme.spacingSmall

                                Text {
                                    Layout.preferredWidth: root.compactNavigation ? parent.width : 22
                                    text: navigationItem.modelData.icon
                                    color: navigationItem.index === root.currentIndex ? root.runtimeTheme.focusColor : root.runtimeTheme.secondaryTextColor
                                    font.family: iconFont.status === FontLoader.Ready ? iconFont.name : root.runtimeTheme.fontFamily
                                    font.pixelSize: navigationItem.index === root.currentIndex ? 16 : 15
                                    horizontalAlignment: Text.AlignHCenter
                                    scale: navigationItem.index === root.currentIndex ? 1.08 : 1.0
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: root.runtimeTheme.durationNormal
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: root.runtimeTheme.durationNormal
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                    Behavior on font.pixelSize {
                                        NumberAnimation {
                                            duration: root.runtimeTheme.durationFast
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

                                ColumnLayout {
                                    visible: !root.compactNavigation
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: root.pageLabel(navigationItem.modelData)
                                        color: root.runtimeTheme.textColor
                                        font.family: root.runtimeTheme.fontFamily
                                        font.pixelSize: root.runtimeTheme.fontSizeBody
                                        font.weight: navigationItem.index === root.currentIndex ? Font.DemiBold : Font.Normal
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.pageSubtitle(navigationItem.modelData)
                                        color: root.runtimeTheme.tertiaryTextColor
                                        font.family: root.runtimeTheme.fontFamily
                                        font.pixelSize: root.runtimeTheme.fontSizeCaption
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea {
                                id: navigationPointer
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activatePage(navigationItem.index)
                            }

                            Keys.onSpacePressed: root.activatePage(navigationItem.index)
                            Keys.onReturnPressed: root.activatePage(navigationItem.index)
                            Keys.onEnterPressed: root.activatePage(navigationItem.index)

                            ToolTip.visible: root.compactNavigation && navigationPointer.containsMouse
                            ToolTip.text: root.pageLabel(navigationItem.modelData)
                            ToolTip.delay: 500
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        radius: root.runtimeTheme.radiusSmall
                        color: root.runtimeTheme.tertiaryColor
                        border.width: 1
                        border.color: root.runtimeTheme.separatorColor

                        Text {
                            anchors.centerIn: parent
                            text: root.compactNavigation ? "1.0" : "cscui 1.0.0"
                            color: root.runtimeTheme.secondaryTextColor
                            font.family: root.runtimeTheme.monoFontFamily
                            font.pixelSize: root.runtimeTheme.fontSizeCaption
                        }
                    }
                }

                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: 1
                    color: root.runtimeTheme.separatorColor
                }
            }

            Rectangle {
                id: contentPane
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: root.runtimeTheme.canvasColor
                border.width: root.runtimeTheme.showLayoutBounds ? 2 : 0
                border.color: root.runtimeTheme.dangerColor

                Rectangle {
                    id: pageToolbar
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 84
                    color: root.runtimeTheme.canvasColor

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: root.runtimeTheme.spacingXLarge
                        anchors.rightMargin: root.runtimeTheme.spacingXLarge
                        spacing: root.runtimeTheme.spacingLarge

                        ColumnLayout {
                            id: pageTitleChrome
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: root.runtimeTheme.spacingXs

                            Text {
                                text: root.currentPageLabel
                                color: root.runtimeTheme.textColor
                                font.family: root.runtimeTheme.fontFamily
                                font.pixelSize: root.runtimeTheme.fontSizeHeading
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                text: root.currentPageSubtitle
                                color: root.runtimeTheme.secondaryTextColor
                                font.family: root.runtimeTheme.fontFamily
                                font.pixelSize: root.runtimeTheme.fontSizeBody
                                elide: Text.ElideRight
                            }
                        }

                        Components.CscSegmentedControl {
                            visible: contentPane.width >= 600
                            theme: root.runtimeTheme
                            model: [
                                root.runtimeTheme.localized("Workflow", "工作流"),
                                root.runtimeTheme.localized("Content", "资料"),
                                root.runtimeTheme.localized("Dashboard", "看板")
                            ]
                            currentIndex: root.currentIndex
                            onActivated: function (index) {
                                root.activatePage(index);
                            }
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: root.runtimeTheme.separatorColor
                    }
                }

                Flickable {
                    id: contentFlickable
                    anchors.top: pageToolbar.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    clip: true
                    contentWidth: width
                    // Prefer the live page's implicit height; fall back to the
                    // loader height. Always keep at least the viewport so the
                    // first polish frame never reports a zero-range flickable.
                    contentHeight: {
                        const loader = root.pageLoaderAt(root.displayedIndex);
                        let pageH = 0;
                        if (loader && loader.item)
                            pageH = Math.max(loader.height, loader.item.implicitHeight, loader.item.height);
                        else if (loader)
                            pageH = loader.height;
                        return Math.max(height, pageHost.y + pageH + root.runtimeTheme.spacingXLarge);
                    }
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick
                    interactive: true
                    // Avoid rubber-band fighting the first layout after a page load.
                    rebound: Transition {}
                    maximumFlickVelocity: 4000
                    flickDeceleration: 1500

                    // Windows: force wheel to outer flickable when children ignore it.
                    WheelHandler {
                        // Nested combo/popup surfaces still win when they accept.
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: function (event) {
                            if (contentFlickable.contentHeight <= contentFlickable.height + 0.5)
                                return;
                            const dy = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y / 120 * 48;
                            const maxY = Math.max(0, contentFlickable.contentHeight - contentFlickable.height);
                            contentFlickable.contentY = Math.max(0, Math.min(maxY, contentFlickable.contentY - dy));
                            event.accepted = true;
                        }
                    }

                    Item {
                        id: pageHost

                        x: root.runtimeTheme.spacingXLarge
                        y: root.runtimeTheme.spacingXLarge
                        width: Math.max(0, contentFlickable.width - root.runtimeTheme.spacingXLarge * 2)
                        height: {
                            const loader = root.pageLoaderAt(root.displayedIndex);
                            if (!loader || !loader.item)
                                return loader ? loader.height : 0;
                            return Math.max(loader.height, loader.item.implicitHeight, loader.item.height);
                        }

                        // Each destination is constructed once and retained.
                        // Sequential asynchronous preloading spreads the one-off
                        // work across idle frames; later navigation only fades
                        // and translates existing scene-graph nodes.
                        // qmllint disable missing-property
                        Repeater {
                            id: pageLoaderRepeater
                            model: root.navigationModel

                            delegate: Loader {
                                id: cachedPageLoader

                                required property int index
                                required property var modelData
                                property real transitionOffset: 0
                                property real transitionScale: 1

                                x: 0
                                y: 0
                                width: pageHost.width
                                height: item ? Math.max(item.implicitHeight, item.height) : 0
                                active: root.activatedPages[index] === true
                                // Incubate off the critical path so navigation stays responsive
                                // while charts and tables materialize in the background.
                                asynchronous: true
                                source: modelData.source
                                visible: false
                                opacity: 0
                                // Stay interactive during fade-in (wheel must work immediately).
                                enabled: visible && index === root.displayedIndex
                                transform: [
                                    Translate {
                                        x: cachedPageLoader.transitionOffset
                                        y: (1 - cachedPageLoader.transitionScale) * 12
                                    },
                                    Scale {
                                        origin.x: cachedPageLoader.width * 0.5
                                        origin.y: 0
                                        xScale: cachedPageLoader.transitionScale
                                        yScale: cachedPageLoader.transitionScale
                                    }
                                ]

                                onLoaded: {
                                    if (!item)
                                        return;
                                    item.theme = root.runtimeTheme;
                                    item.availableWidth = width;
                                    if (item.viewportWidth !== undefined)
                                        item.viewportWidth = width;
                                    item.toastRef = toast;
                                    if (item.openMusicWindowHandler !== undefined)
                                        item.openMusicWindowHandler = root.openMusicWindow;
                                    if (item.openAnimatedWindowHandler !== undefined)
                                        item.openAnimatedWindowHandler = root.openAnimatedDemo;
                                    if (item.eventLogged !== undefined)
                                        item.eventLogged.connect(root.logEvent);

                                    if (index === root.currentIndex || index === root.displayedIndex) {
                                        if (index === root.currentIndex)
                                            root.currentPageReady = true;
                                        visible = true;
                                        opacity = 1;
                                        transitionOffset = 0;
                                        transitionScale = 1;
                                        // Let ColumnLayout finish one polish pass, then
                                        // refresh flickable range so the wheel works immediately.
                                        Qt.callLater(function () {
                                            contentFlickable.returnToBounds();
                                        });
                                    } else {
                                        // Keep preloaded pages fully hidden. Instant swap in
                                        // commitPage is cheaper than dual-tree polish passes.
                                        visible = false;
                                        opacity = 0;
                                        transitionOffset = 0;
                                        transitionScale = 1;
                                    }
                                    if (index === root.currentIndex && index !== root.displayedIndex)
                                        root.commitPage(index);
                                    root.scheduleBackgroundPreload();
                                    Qt.callLater(function () {
                                        root.logEvent(root.runtimeTheme.localized("Loaded: ", "已加载：") + root.pageLabel(modelData));
                                    });
                                }

                                onWidthChanged: {
                                    if (item)
                                        item.availableWidth = width;
                                    if (item && item.viewportWidth !== undefined)
                                        item.viewportWidth = width;
                                }

                                onStatusChanged: {
                                    if (index === root.currentIndex) {
                                        if (status === Loader.Ready && item)
                                            root.currentPageReady = true;
                                        else if (status === Loader.Loading || status === Loader.Null)
                                            root.currentPageReady = false;
                                        else if (status === Loader.Error)
                                            root.currentPageReady = true; // stop spinner; error is logged
                                    }
                                    if (status === Loader.Error)
                                        root.logEvent(root.runtimeTheme.localized("Unable to load: ", "无法加载：") + modelData.source);
                                }
                            }
                        }
                        // qmllint enable missing-property
                    }

                    ScrollBar.vertical: Components.CscScrollBar {
                        theme: root.runtimeTheme
                        policy: ScrollBar.AsNeeded
                    }
                }

                BusyIndicator {
                    anchors.centerIn: parent
                    // Depend on currentPageReady, not a function call into the
                    // Repeater. pageLoaderAt(...).status is invisible to the
                    // binding engine, so the spinner never stopped after Ready.
                    running: !root.currentPageReady
                    visible: running
                    // Pass wheel/click through to the flickable underneath.
                    enabled: false
                    z: 20
                }

                // Incoming-only page transition: opacity + lateral drift.
                // Outgoing is already hidden in commitPage.
                ParallelAnimation {
                    id: pageTransition

                    NumberAnimation {
                        target: root.incomingPageLoader
                        property: "opacity"
                        to: 1
                        duration: root.runtimeTheme.durationNormal
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: root.incomingPageLoader
                        property: "transitionOffset"
                        to: 0
                        duration: root.runtimeTheme.durationNormal
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: root.incomingPageLoader
                        property: "transitionScale"
                        to: 1
                        duration: root.runtimeTheme.durationNormal
                        easing.type: Easing.OutCubic
                    }
                    onFinished: root.finishPageTransition()
                }

                NumberAnimation {
                    id: pageTitleIn
                    target: pageTitleChrome
                    property: "opacity"
                    to: 1
                    duration: root.runtimeTheme.durationNormal
                    easing.type: Easing.OutCubic
                }

                Timer {
                    id: pagePreloadTimer
                    interval: 48
                    repeat: true
                    onTriggered: root.preloadNextPage()
                }
            }
        }
    }

    Components.CscDebugPanel {
        id: debugPanel
        anchors.top: titleBar.bottom
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: root.inspectorWidth
        visible: root.debugVisible
        z: 90
        theme: root.runtimeTheme
        buildMode: root.buildMode
        pageName: root.currentPageLabel
        focusName: root.focusDescription
        platformName: Qt.platform.os
        devicePixelRatio: root.devicePixelRatio
        viewportWidth: contentPane.width
        viewportHeight: contentPane.height
        onCloseRequested: root.toggleDebugPanel()
    }

    Components.Drawer {
        id: aboutDrawer
        anchors.top: titleBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        z: 850
        theme: root.runtimeTheme
        panelWidth: Math.min(430, Math.max(320, Math.round(width * 0.36)))
        closeOnOverlay: true
        accessibleName: root.runtimeTheme.localized("About and component index", "关于与组件索引")

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.runtimeTheme.touchTarget

            ColumnLayout {
                Layout.fillWidth: true
                spacing: root.runtimeTheme.spacingXs

                Text {
                    Layout.fillWidth: true
                    text: root.runtimeTheme.localized("About cscui", "关于 cscui")
                    color: root.runtimeTheme.textColor
                    font.family: root.runtimeTheme.fontFamily
                    font.pixelSize: root.runtimeTheme.fontSizeTitle
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: root.runtimeTheme.localized("47 reusable components", "47 个可复用组件")
                    color: root.runtimeTheme.secondaryTextColor
                    font.family: root.runtimeTheme.fontFamily
                    font.pixelSize: root.runtimeTheme.fontSizeCaption
                }
            }

            Components.CscIconButton {
                theme: root.runtimeTheme
                iconCharacter: "\uf00d"
                accessibleName: root.runtimeTheme.localized("Close about panel", "关闭关于面板")
                toolTip: accessibleName
                onClicked: aboutDrawer.close()
            }
        }

        Components.Aboutme {
            theme: root.runtimeTheme
            windowOpen: aboutDrawer.opened
            version: "1.0.0"
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    Canvas {
        id: layoutGuide
        anchors.fill: workspace
        visible: root.runtimeTheme.showLayoutBounds
        z: 200
        opacity: 0.45

        onPaint: {
            const context = getContext("2d");
            context.reset();
            context.strokeStyle = root.runtimeTheme.dangerColor;
            context.lineWidth = 0.5;
            for (let x = 8; x < width; x += 8) {
                context.beginPath();
                context.moveTo(x, 0);
                context.lineTo(x, height);
                context.stroke();
            }
            for (let y = 8; y < height; y += 8) {
                context.beginPath();
                context.moveTo(0, y);
                context.lineTo(width, y);
                context.stroke();
            }
        }

        onVisibleChanged: if (visible)
            requestPaint()
        onWidthChanged: if (visible)
            requestPaint()
        onHeightChanged: if (visible)
            requestPaint()
    }

    Components.Toast {
        id: toast
        anchors.top: titleBar.bottom
        // contentPane is nested inside the workspace layout and cannot be an
        // anchor target here. This equivalent binding avoids a runtime warning.
        x: Math.round(workspace.x + contentPane.x + (contentPane.width - width) / 2)
        anchors.topMargin: 14 + yOffset
        theme: root.runtimeTheme
        z: 500
    }

    Components.AnimatedWindow {
        id: animatedWindow

        anchors.fill: parent
        theme: root.runtimeTheme
        z: 1100
        dismissOnOverlay: false
        onClosed: {
            animatedContentLoader.active = false;
            root.pendingAnimatedSource = null;
        }

        Loader {
            id: animatedContentLoader
            anchors.fill: parent
            active: false
            asynchronous: true
            sourceComponent: root.animatedContentMode === "music"
                             ? musicWindowComponent
                             : animatedDemoComponent
            onLoaded: {
                if (root.animatedContentMode === "music" && item)
                    item.sourceItem = root.pendingAnimatedSource;
            }
        }
    }

    Component {
        id: musicWindowComponent

        Components.MusicWindow {
            theme: root.runtimeTheme
            sourceItem: null
        }
    }

    Component {
        id: animatedDemoComponent

        Item {
            Accessible.role: Accessible.Pane
            Accessible.name: root.runtimeTheme.localized("Animated window demonstration", "动画窗口演示")

            Column {
                anchors.centerIn: parent
                width: Math.min(520, Math.max(280, parent.width - 64))
                spacing: root.runtimeTheme.spacingLarge

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "\uf5fd"
                    color: root.runtimeTheme.focusColor
                    font.family: iconFont.name
                    font.pixelSize: 44
                }

                Text {
                    width: parent.width
                    text: root.runtimeTheme.localized("AnimatedWindow", "AnimatedWindow 动画窗口")
                    color: root.runtimeTheme.textColor
                    font.family: root.runtimeTheme.fontFamily
                    font.pixelSize: root.runtimeTheme.fontSizeHeading
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    width: parent.width
                    text: root.runtimeTheme.localized("The transition keeps spatial continuity while only animating scene-graph transforms and opacity.", "过渡保持空间连续性，同时只动画场景图变换与不透明度。")
                    color: root.runtimeTheme.secondaryTextColor
                    font.family: root.runtimeTheme.fontFamily
                    font.pixelSize: root.runtimeTheme.fontSizeBody
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }
        }
    }


    Timer {
        id: autoAnimatedDemoTimer
        interval: 900
        repeat: false
        running: root.autoAnimatedDemo && root.currentPageReady
        onTriggered: {
            root.openAnimatedDemo(titleBar, {
                duration: 320,
                contentDelayFactor: 0.28,
                contentDurationFactor: 0.72,
                closeDurationFactor: 0.68,
                contentOffset: 10
            })
        }
    }

    Shortcut {
        sequence: "Ctrl+Shift+D"
        context: Qt.ApplicationShortcut
        onActivated: root.toggleDebugPanel()
    }

    Connections {
        target: root.runtimeTheme

        function onIsDarkChanged() {
            root.logEvent(root.runtimeTheme.localized("Theme: ", "主题：")
                          + (root.runtimeTheme.isDark
                             ? root.runtimeTheme.localized("dark", "深色")
                             : root.runtimeTheme.localized("light", "浅色")));
        }

        function onEffectiveLanguageChanged() {
            root.logEvent(root.runtimeTheme.isChinese
                          ? root.runtimeTheme.localized("Language: Chinese", "语言：中文")
                          : root.runtimeTheme.localized("Language: English", "语言：英文"));
        }

        function onShowLayoutBoundsChanged() {
            if (root.runtimeTheme.showLayoutBounds)
                layoutGuide.requestPaint();
        }
    }

    onVisibilityChanged: {
        // Only mirror the platform maximized state. Manual frameless fill uses
        // customMaximized alone and must not be cleared by Windowed visibility.
        if (root.visibility === Window.Maximized)
            root.customMaximized = true;
    }

    Component.onCompleted: {
        root.restoreWidth = root.width;
        root.restoreHeight = root.height;
        root.restoreX = root.x;
        root.restoreY = root.y;
        if (iconFont.status === FontLoader.Ready)
            root.runtimeTheme.iconFontFamily = iconFont.name;
        root.runtimeTheme.setMode(root.themeMode);
        root.runtimeTheme.setLanguage(root.languageMode);
        const initialIndex = root.requestedPage >= 0 && root.requestedPage < root.navigationModel.length
                             ? root.requestedPage
                             : 0;
        root.currentIndex = initialIndex;
        root.displayedIndex = initialIndex;
        const initialPages = [];
        for (let index = 0; index < root.navigationModel.length; ++index)
            initialPages.push(index === initialIndex);
        root.activatedPages = initialPages;
        // Start background incubation as soon as the first destination is up.
        root.scheduleBackgroundPreload();
        root.logEvent(root.runtimeTheme.localized("cscui started / ", "cscui 已启动 / ") + root.buildMode);
        if (root.debugVisible)
            root.logEvent(root.runtimeTheme.localized("Inspector enabled", "检查器已启用"));
    }

    // Frameless windows need explicit resize hit areas on every edge.
    Item {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.resizeMargin
        z: 1000
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeHorCursor
            onPressed: root.startSystemResize(Qt.LeftEdge)
        }
    }

    Item {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.resizeMargin
        z: 1000
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeHorCursor
            onPressed: root.startSystemResize(Qt.RightEdge)
        }
    }

    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.resizeMargin
        z: 1000
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeVerCursor
            onPressed: root.startSystemResize(Qt.TopEdge)
        }
    }

    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.resizeMargin
        z: 1000
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeVerCursor
            onPressed: root.startSystemResize(Qt.BottomEdge)
        }
    }

    Item {
        anchors.left: parent.left
        anchors.top: parent.top
        width: root.resizeMargin * 2
        height: root.resizeMargin * 2
        z: 1001
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeFDiagCursor
            onPressed: root.startSystemResize(Qt.LeftEdge | Qt.TopEdge)
        }
    }

    Item {
        anchors.right: parent.right
        anchors.top: parent.top
        width: root.resizeMargin * 2
        height: root.resizeMargin * 2
        z: 1001
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeBDiagCursor
            onPressed: root.startSystemResize(Qt.RightEdge | Qt.TopEdge)
        }
    }

    Item {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: root.resizeMargin * 2
        height: root.resizeMargin * 2
        z: 1001
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeBDiagCursor
            onPressed: root.startSystemResize(Qt.LeftEdge | Qt.BottomEdge)
        }
    }

    Item {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: root.resizeMargin * 2
        height: root.resizeMargin * 2
        z: 1001
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeFDiagCursor
            onPressed: root.startSystemResize(Qt.RightEdge | Qt.BottomEdge)
        }
    }
}
