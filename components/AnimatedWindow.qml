pragma ComponentBehavior: Bound

import QtQuick

// A window-level shared-element transition. Geometry is represented with a
// scene-graph Scale transform, so opening a large view never animates layout
// width/height/x/y or rebuilds a full-window layer on every frame.
Item {
    id: animationWrapper

    z: 999
    visible: false
    state: "iconState"
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    focus: visible

    // Keep the component usable on its own (including scaffolded projects)
    // while still allowing the application to inject its shared theme.
    Theme { id: fallbackTheme }
    property var theme: fallbackTheme
    property real sourceOpacity: 1.0
    property bool dismissOnOverlay: false
    property string windowTitle: ""

    // Compatibility properties retained from the original public component.
    property int animDuration: theme ? theme.durationSlow : 320
    property real segment1Progress: 0.8
    property real segment1DurationFactor: 0.28
    property real segment2DurationFactor: 0.72
    property real maxTiltAngle: theme && theme.reducedMotion ? 0 : 12
    property real closeDurationFactor: 0.68
    property real contentOffset: 10
    property int openEasing: Easing.OutQuint
    property int closeEasing: Easing.InCubic
    property color textColor: theme ? theme.textColor : "#1D1D1F"
    property color fullscreenColor: theme ? theme.secondaryColor : "#FFFFFF"
    property color buttonColor: theme ? theme.secondaryColor : "#FFFFFF"

    default property alias contentData: contentArea.data

    readonly property bool isAnimating: openAnimation.running || closeAnimation.running
    property bool _trackedOpen: false
    property var startState: ({
        x: 0,
        y: 0,
        width: 100,
        height: 100,
        radius: 12,
        color: "#00000000",
        rotationX: 0,
        rotationY: 0,
        sourceItem: null
    })
    property real _startScaleX: 0.1
    property real _startScaleY: 0.1
    property real _scaleOriginX: width / 2
    property real _scaleOriginY: height / 2
    property real _startContainerRadius: 0

    readonly property int _effectiveDuration: theme && theme.reducedMotion
                                              ? 0
                                              : Math.max(0, animationWrapper.animDuration)
    readonly property real _effectiveContentOffset: theme && theme.reducedMotion
                                                    ? 0
                                                    : Math.max(0, animationWrapper.contentOffset)
    readonly property real _contentDelayFactor: Math.max(0, Math.min(0.6, animationWrapper.segment1DurationFactor))
    readonly property real _contentDurationFactor: Math.max(0, Math.min(1, animationWrapper.segment2DurationFactor))
    readonly property int _contentDelayDuration: Math.round(_effectiveDuration * _contentDelayFactor)
    readonly property int _contentFadeDuration: Math.round(_effectiveDuration * _contentDurationFactor)
    readonly property int _closeDuration: Math.round(_effectiveDuration
                                                      * Math.max(0.2, Math.min(1.4, animationWrapper.closeDurationFactor)))
    readonly property int _contentCloseDuration: Math.min(_closeDuration,
                                                          Math.round(_effectiveDuration * 0.4))

    signal opened
    signal closed

    Accessible.role: Accessible.Pane
    Accessible.name: windowTitle.length > 0
                     ? windowTitle
                     : (theme ? theme.localized("Expanded window", "展开窗口") : "Expanded window")

    // Temporarily override the trigger opacity without destroying a binding
    // owned by the caller. Disabling this Binding restores the original value
    // or expression automatically when the window closes.
    Binding {
        target: animationWrapper.startState.sourceItem
        property: "opacity"
        value: 0
        when: animationWrapper.visible && animationWrapper.startState.sourceItem !== null
        restoreMode: Binding.RestoreBindingOrValue
    }

    function _updateThemeOpenCount(open) {
        if (_trackedOpen === open)
            return;
        _trackedOpen = open;
        if (!theme)
            return;
        if (open)
            theme.openAnimatedWindowCount += 1;
        else if (theme.openAnimatedWindowCount > 0)
            theme.openAnimatedWindowCount -= 1;
    }

    function _isVisibleColor(candidate) {
        if (!candidate || candidate === "transparent")
            return false;
        return candidate.a === undefined || candidate.a > 0.01;
    }

    function _findSurfaceColor(item) {
        if (!item || !item.visible || item.opacity <= 0.01)
            return null;
        if (_isVisibleColor(item.containerColor))
            return item.containerColor;
        if (_isVisibleColor(item.color))
            return item.color;
        for (let index = 0; index < item.children.length; ++index) {
            const childColor = _findSurfaceColor(item.children[index]);
            if (childColor)
                return childColor;
        }
        return null;
    }

    function applyProfile(profile) {
        const options = profile || {};
        const requestedDuration = Number(options.duration);
        const requestedDelay = Number(options.contentDelayFactor);
        const requestedContentDuration = Number(options.contentDurationFactor);
        const requestedCloseFactor = Number(options.closeDurationFactor);
        const requestedOffset = Number(options.contentOffset);

        animDuration = isFinite(requestedDuration)
                       ? Math.max(0, Math.min(2000, Math.round(requestedDuration)))
                       : (theme ? theme.durationSlow : 320);
        segment1DurationFactor = isFinite(requestedDelay)
                                 ? Math.max(0, Math.min(0.6, requestedDelay))
                                 : 0.28;
        segment2DurationFactor = isFinite(requestedContentDuration)
                                 ? Math.max(0.1, Math.min(1, requestedContentDuration))
                                 : 0.72;
        closeDurationFactor = isFinite(requestedCloseFactor)
                              ? Math.max(0.2, Math.min(1.4, requestedCloseFactor))
                              : 0.68;
        contentOffset = isFinite(requestedOffset)
                        ? Math.max(0, Math.min(64, requestedOffset))
                        : 10;
    }

    function updateStartStatePosition(captureAppearance) {
        const source = startState.sourceItem;
        if (!source || width <= 0 || height <= 0)
            return false;

        // Mapping all corners preserves the apparent trigger size while its
        // press feedback Scale transform is still settling.
        const topLeft = source.mapToItem(animationWrapper, 0, 0);
        const topRight = source.mapToItem(animationWrapper, source.width, 0);
        const bottomLeft = source.mapToItem(animationWrapper, 0, source.height);
        const bottomRight = source.mapToItem(animationWrapper, source.width, source.height);
        const minX = Math.min(topLeft.x, topRight.x, bottomLeft.x, bottomRight.x);
        const maxX = Math.max(topLeft.x, topRight.x, bottomLeft.x, bottomRight.x);
        const minY = Math.min(topLeft.y, topRight.y, bottomLeft.y, bottomRight.y);
        const maxY = Math.max(topLeft.y, topRight.y, bottomLeft.y, bottomRight.y);

        startState.x = minX;
        startState.y = minY;
        startState.width = Math.max(1, maxX - minX);
        startState.height = Math.max(1, maxY - minY);
        if (captureAppearance !== false) {
            startState.radius = source.radius !== undefined ? Math.max(0, Number(source.radius)) : 12;
            startState.color = _findSurfaceColor(source);
            if (!_isVisibleColor(startState.color))
                startState.color = theme ? theme.secondaryColor : "#FFFFFF";
        }

        _startScaleX = Math.max(0.001, Math.min(1, startState.width / width));
        _startScaleY = Math.max(0.001, Math.min(1, startState.height / height));
        _scaleOriginX = Math.abs(1 - _startScaleX) < 0.0001
                        ? width / 2
                        : startState.x / (1 - _startScaleX);
        _scaleOriginY = Math.abs(1 - _startScaleY) < 0.0001
                        ? height / 2
                        : startState.y / (1 - _startScaleY);
        const radiusScale = Math.sqrt(_startScaleX * _startScaleY);
        _startContainerRadius = Math.min(Math.min(width, height) / 2,
                                         startState.radius / Math.max(0.001, radiusScale));
        startStateChanged();
        return true;
    }

    function _prepareOpeningFrame() {
        sharedScale.origin.x = _scaleOriginX;
        sharedScale.origin.y = _scaleOriginY;
        sharedScale.xScale = _startScaleX;
        sharedScale.yScale = _startScaleY;
        appContainer.radius = _startContainerRadius;
        appContainer.color = startState.color;
        windowContent.opacity = 0;
        contentTranslate.y = _effectiveContentOffset;
    }

    function open(source, titleText) {
        if (!source || width <= 0 || height <= 0)
            return;

        openAnimation.stop();
        closeAnimation.stop();

        if (startState.sourceItem !== source || !visible)
            sourceOpacity = source.opacity;
        startState.sourceItem = source;
        windowTitle = titleText === undefined ? "" : String(titleText);
        if (!updateStartStatePosition(true))
            return;

        _prepareOpeningFrame();
        visible = true;
        state = "fullscreenState";
        forceActiveFocus();
        _updateThemeOpenCount(true);
        openAnimation.start();
    }

    function close() {
        if (!visible || state === "iconState")
            return;
        openAnimation.stop();
        updateStartStatePosition(false);
        state = "iconState";
        closeAnimation.restart();
    }

    function _finishClose() {
        const source = startState.sourceItem;
        visible = false;
        startState.sourceItem = null;
        _updateThemeOpenCount(false);
        if (source && source.forceActiveFocus)
            source.forceActiveFocus();
        closed();
    }

    Keys.onEscapePressed: function (event) {
        event.accepted = true;
        animationWrapper.close();
    }

    onWidthChanged: if (visible && !isAnimating)
        updateStartStatePosition(false)
    onHeightChanged: if (visible && !isAnimating)
        updateStartStatePosition(false)

    MouseArea {
        anchors.fill: parent
        enabled: animationWrapper.visible
        acceptedButtons: Qt.AllButtons
        preventStealing: true
        propagateComposedEvents: false
        onClicked: if (animationWrapper.dismissOnOverlay)
            animationWrapper.close()
        onPressed: function (mouse) { mouse.accepted = true }
        onReleased: function (mouse) { mouse.accepted = true }
        onDoubleClicked: function (mouse) { mouse.accepted = true }
        onWheel: function (wheel) { wheel.accepted = true }
    }

    Rectangle {
        id: appContainer

        anchors.fill: parent
        // Rounded clipping is only needed while visible content intersects a
        // rounded edge. The steady full-screen state therefore has no stencil
        // clip or offscreen layer cost.
        clip: radius > 0.5 && windowContent.opacity > 0.01
        color: animationWrapper.fullscreenColor
        transform: Scale {
            id: sharedScale
            origin.x: animationWrapper._scaleOriginX
            origin.y: animationWrapper._scaleOriginY
            xScale: 1
            yScale: 1
        }

        Item {
            id: windowContent

            anchors.fill: parent
            opacity: 0
            enabled: animationWrapper.state === "fullscreenState" && opacity > 0.15
            transform: Translate {
                id: contentTranslate
                y: 0
            }

            Item {
                id: contentArea
                anchors.fill: parent
            }

            Button {
                theme: animationWrapper.theme
                size: "s"
                iconCharacter: "\uf078"
                text: ""
                shadowEnabled: false
                accessibleName: animationWrapper.theme
                                ? animationWrapper.theme.localized("Close expanded window", "关闭展开窗口")
                                : "Close expanded window"
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 12
                z: 10
                onClicked: animationWrapper.close()
            }
        }
    }

    ParallelAnimation {
        id: openAnimation

        NumberAnimation {
            target: sharedScale
            property: "xScale"
            to: 1
            duration: animationWrapper._effectiveDuration
            easing.type: animationWrapper.openEasing
        }
        NumberAnimation {
            target: sharedScale
            property: "yScale"
            to: 1
            duration: animationWrapper._effectiveDuration
            easing.type: animationWrapper.openEasing
        }
        NumberAnimation {
            target: appContainer
            property: "radius"
            to: 0
            duration: animationWrapper._effectiveDuration
            easing.type: animationWrapper.openEasing
        }
        ColorAnimation {
            target: appContainer
            property: "color"
            to: animationWrapper.fullscreenColor
            duration: animationWrapper._effectiveDuration
            easing.type: animationWrapper.openEasing
        }
        SequentialAnimation {
            PauseAnimation { duration: animationWrapper._contentDelayDuration }
            ParallelAnimation {
                NumberAnimation {
                    target: windowContent
                    property: "opacity"
                    to: 1
                    duration: animationWrapper._contentFadeDuration
                    easing.type: animationWrapper.openEasing
                }
                NumberAnimation {
                    target: contentTranslate
                    property: "y"
                    to: 0
                    duration: animationWrapper._contentFadeDuration
                    easing.type: animationWrapper.openEasing
                }
            }
        }
        onFinished: animationWrapper.opened()
    }

    ParallelAnimation {
        id: closeAnimation

        NumberAnimation {
            target: sharedScale
            property: "xScale"
            to: animationWrapper._startScaleX
            duration: animationWrapper._closeDuration
            easing.type: animationWrapper.closeEasing
        }
        NumberAnimation {
            target: sharedScale
            property: "yScale"
            to: animationWrapper._startScaleY
            duration: animationWrapper._closeDuration
            easing.type: animationWrapper.closeEasing
        }
        NumberAnimation {
            target: appContainer
            property: "radius"
            to: animationWrapper._startContainerRadius
            duration: animationWrapper._closeDuration
            easing.type: animationWrapper.closeEasing
        }
        ColorAnimation {
            target: appContainer
            property: "color"
            to: animationWrapper.startState.color
            duration: animationWrapper._closeDuration
            easing.type: animationWrapper.closeEasing
        }
        NumberAnimation {
            target: windowContent
            property: "opacity"
            to: 0
            duration: animationWrapper._contentCloseDuration
            easing.type: animationWrapper.closeEasing
        }
        NumberAnimation {
            target: contentTranslate
            property: "y"
            to: animationWrapper._effectiveContentOffset
            duration: animationWrapper._contentCloseDuration
            easing.type: animationWrapper.closeEasing
        }
        onFinished: animationWrapper._finishClose()
    }

    Component.onDestruction: {
        _updateThemeOpenCount(false);
    }

    CscIdentityLayer {
        parent: animationWrapper
        anchors.fill: parent
        theme: animationWrapper.theme
        nameEn: "AnimatedWindow"
        nameZh: "动画窗口"
    }
}
