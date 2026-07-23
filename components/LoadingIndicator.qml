import QtQuick

// Vector activity indicator. Unlike the former GIF implementation, both color
// and speed are functional and the asset remains sharp at any display scale.
Item {
    id: root

    // Explicit injection keeps the indicator aligned with the active palette.
    property var theme

    width: size
    height: size

    property real size: 40
    // Seconds per revolution; lower values produce a faster spinner.
    property real speed: 0.8
    property color color: root.theme ? root.theme.focusColor : "#0066CC"
    property bool running: true

    Accessible.role: Accessible.ProgressBar
    Accessible.name: root.theme ? root.theme.localized("Loading", "加载中") : "Loading"

    Item {
        id: rotor

        anchors.fill: parent
        visible: root.running

        Canvas {
            id: canvas

            anchors.fill: parent
            antialiasing: true

            onPaint: {
                const context = getContext("2d");
                context.clearRect(0, 0, width, height);

                const lineWidth = Math.max(2, Math.min(width, height) * 0.11);
                const radius = Math.max(0, Math.min(width, height) / 2 - lineWidth);
                const centerX = width / 2;
                const centerY = height / 2;

                context.lineWidth = lineWidth;
                context.lineCap = "round";
                context.strokeStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.18);
                context.beginPath();
                context.arc(centerX, centerY, radius, 0, Math.PI * 2, false);
                context.stroke();

                context.strokeStyle = root.color;
                context.beginPath();
                context.arc(centerX, centerY, radius, -Math.PI / 2, Math.PI * 0.85, false);
                context.stroke();
            }

            Connections {
                target: root

                function onColorChanged() {
                    canvas.requestPaint();
                }

                function onSizeChanged() {
                    canvas.requestPaint();
                }
            }
        }

        RotationAnimator on rotation {
            from: 0
            to: 360
            duration: Math.max(200, root.speed * 1000)
            loops: Animation.Infinite
            running: root.running && root.visible && !(root.theme && root.theme.reducedMotion)
        }
    }

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "LoadingIndicator"
        nameZh: "加载指示"
    }
}
