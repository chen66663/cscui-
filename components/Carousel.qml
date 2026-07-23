// Carousel.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Window

Item {
    id: root

    required property var theme

    // ==== 公共/样式属性 ====
    property real radius: theme ? theme.radiusLarge : 12
    property bool shadowEnabled: true
    property bool autoLoadRemote: false
    property string remoteFeedUrl: "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=5&mkt=en-US"
    property bool loading: false
    property string errorMessage: ""
    signal loadFailed(string message)

    // ==== 数据模型 ====
    property var model: []
    property alias currentIndex: swipeView.currentIndex

    // Image loading is deliberately bounded to the visible page and its
    // neighbours.  Repeater still keeps lightweight delegates for every item,
    // but off-screen delegates do not allocate image textures.
    property bool lazyLoad: true
    property int preloadRadius: 1
    // Disable the global QML image cache by default so discarded pages can be
    // reclaimed.  Applications that revisit the same images frequently can
    // opt in with `cacheImages: true`.
    property bool cacheImages: false
    // The decode scale is independent from the visual item size.  Keeping a
    // small cap avoids an accidental multi-megapixel texture during a resize.
    // Quantization prevents every single resize pixel from scheduling another
    // asynchronous image decode.
    property real decodeScale: 1.0
    property int maxDecodeDimension: 2048
    property int decodeSizeStep: 64
    readonly property real screenScale: {
        const dpr = Number(Screen.devicePixelRatio);
        return Number.isFinite(dpr) && dpr > 0 ? dpr : 1.0;
    }

    function isIndexWithinPreloadWindow(itemIndex) {
        if (!root.lazyLoad)
            return true;
        const activeIndex = Math.max(0, swipeView.currentIndex);
        const distance = Math.abs(Number(itemIndex) - activeIndex);
        return Number.isFinite(distance) && distance <= Math.max(0, root.preloadRadius);
    }

    function boundedDecodeDimension(value) {
        const step = Math.max(1, root.decodeSizeStep);
        const quantizedValue = Math.ceil(Math.max(1, Number(value)) / step) * step;
        return Math.max(1, Math.min(root.maxDecodeDimension, quantizedValue));
    }

    // ==== 尺寸/布局 ====
    implicitWidth: 400
    implicitHeight: width * 9 / 16

    // ==== 背景阴影效果 ====
    MultiEffect {
        source: background
        anchors.fill: background
        visible: root.shadowEnabled
        shadowEnabled: true
        shadowColor: theme.shadowColor
        shadowBlur: theme.shadowBlur
        shadowVerticalOffset: theme.shadowYOffset
        shadowHorizontalOffset: theme.shadowXOffset
    }

    // ==== 背景容器与滑动视图 ====
    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.radius
        color: theme.secondaryColor
        clip: true

        // ==== 图片滑动视图 ====
        Item {
            id: swipeContainer
            anchors.fill: parent
            anchors.margins: -1

            SwipeView {
                id: swipeView
                anchors.fill: parent
                interactive: model.length > 1
                visible: true
                opacity: 0 // 保持可交互但不直接显示（由掩模负责显示）

                // ==== 图片重复显示 ====
                Repeater {
                    model: root.model
                    delegate: Item {
                        width: swipeView.width
                        height: swipeView.height

                        readonly property bool shouldLoad: root.isIndexWithinPreloadWindow(index)

                        // 原始图像（隐藏），用于 MultiEffect 的 source
                        Image {
                            id: sourceItem
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            cache: root.cacheImages
                            asynchronous: true
                            visible: true

                            // Decode at the rendered size instead of retaining
                            // the source photo's native dimensions in memory.
                            // The device scale keeps the result crisp on HiDPI
                            // displays while the dimension cap bounds memory.
                            property int targetWidth: root.boundedDecodeDimension(swipeView.width * root.decodeScale
                                                                                  * root.screenScale)
                            property int targetHeight: root.boundedDecodeDimension(swipeView.height * root.decodeScale
                                                                                   * root.screenScale)
                            property string optimizedSource: {
                                const src = String(modelData || "");
                                if (!src.startsWith("http://") && !src.startsWith("https://"))
                                    return src;
                                const separator = src.indexOf("?") === -1 ? "?" : "&";
                                return src + separator + "w=" + targetWidth + "&h=" + targetHeight;
                            }
                            // Clearing source for distant pages releases the
                            // decoder/texture while preserving the swipe
                            // delegate and its layout geometry.
                            source: shouldLoad ? optimizedSource : ""
                            sourceSize: shouldLoad ? Qt.size(targetWidth, targetHeight) : Qt.size(0, 0)
                        }

                        // 移除单图圆角裁剪，保留容器级圆角显示

                        // 加载占位：主题色三点加载动画
                        LoadingIndicator {
                            theme: root.theme
                            anchors.centerIn: parent
                            size: Math.min(parent.width, parent.height) * 0.15
                            speed: 0.8
                            // Distant delegates intentionally have a null
                            // source; they must not start an animation loop.
                            visible: shouldLoad && sourceItem.status !== Image.Ready
                            running: visible
                            z: 2
                        }
                    }
                }
            }

            // 容器级掩模，保证滑动时区域保持圆角
            MultiEffect {
                id: swipeMasked
                source: swipeView
                anchors.fill: parent
                maskEnabled: true
                maskSource: containerMask
                autoPaddingEnabled: false
                antialiasing: true
                // The source moves during a swipe; caching this effect adds a
                // second full-size texture and invalidates it every frame.
                layer.enabled: false
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
                z: 1
            }

            // 整体加载占位：当未有图片数据时显示
            LoadingIndicator {
                theme: root.theme
                anchors.centerIn: parent
                size: Math.min(parent.width, parent.height) * 0.15
                speed: 0.8
                visible: root.model.length === 0
                running: visible
                z: 3
            }

            // 圆角掩模图形
            Item {
                id: containerMask
                anchors.fill: parent
                layer.enabled: true

                visible: false
                Rectangle {
                    anchors.fill: parent
                    radius: root.radius
                    color: "black"
                }
            }
        }

        // ==== 底部页码指示器 ====
        PageIndicator {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 15
            count: swipeView.count
            currentIndex: swipeView.currentIndex
            delegate: Item {
                id: indicatorDelegate
                required property int index
                implicitWidth: 24
                implicitHeight: 8

                Rectangle {
                    anchors.centerIn: parent
                    width: 8
                    height: 8
                    radius: 4
                    color: theme.textColor
                    opacity: 0.85
                    transform: Scale {
                        id: indicatorScale
                        origin.x: 4
                        origin.y: 4
                        xScale: indicatorDelegate.index === swipeView.currentIndex ? 3 : 1
                        Behavior on xScale {
                            NumberAnimation {
                                duration: theme && theme.reducedMotion ? 0 : 220
                                easing.type: Easing.InOutCubic
                            }
                        }
                    }
                }
            }
        }
    }

    // ==== 生命周期 ====
    Component.onCompleted: {
        if (root.autoLoadRemote && root.model.length === 0)
            root.fetchBingImages();
    }

    // ==== 函数：获取 Bing 图片 ====
    function fetchBingImages() {
        if (root.loading)
            return;
        root.loading = true;
        root.errorMessage = "";
        var xhr = new XMLHttpRequest();
        var url = root.remoteFeedUrl + "&_=" + new Date().getTime();
        xhr.open("GET", url);
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                root.loading = false;
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText);
                        const images = response && response.images ? response.images : [];
                        const urls = [];
                        for (let i = 0; i < images.length; i++) {
                            if (images[i].url)
                                urls.push("https://www.bing.com" + images[i].url);
                        }
                        if (urls.length > 0)
                            root.model = urls;
                        else
                            root.reportLoadFailure(theme ? theme.localized("The image feed returned no usable items.", "图片源未返回可用内容。") : "The image feed returned no usable items.");
                    } catch (error) {
                        root.reportLoadFailure(theme ? theme.localized("The image feed returned invalid data.", "图片源返回了无效数据。") : "The image feed returned invalid data.");
                    }
                } else {
                    root.reportLoadFailure((theme ? theme.localized("Image request failed with status ", "图片请求失败，状态码：") : "Image request failed with status ") + xhr.status + ".");
                }
            }
        };
        xhr.send();
    }

    function reportLoadFailure(message) {
        root.loading = false;
        root.errorMessage = message;
        root.loadFailed(message);
    }

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "Carousel"
        nameZh: "轮播"
    }
}
