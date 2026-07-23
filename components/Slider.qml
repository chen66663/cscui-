pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

// Range control with deterministic clamping and quantisation. All value
// changes initiated by a pointer, key or spin box emit userValueChanged.
FocusScope {
    id: root

    // Explicit injection keeps Bound components synchronized with the shell theme.
    property var theme

    property alias text: label.text
    property real value: 50.0
    property real minimumValue: 0.0
    property real maximumValue: 100.0
    property bool showValueLabel: true
    property bool showSpinBox: false
    property bool showValueText: true
    property string valueSuffix: ""
    property int decimals: 0
    property int labelWidth: 60
    property int valueWidth: 60
    property int stepSize: 1
    property bool valueEditable: true
    // Kept public for compatibility with older integrations that inspect the scale.
    property real _scale: Math.pow(10, Math.max(0, root.decimals))
    signal userValueChanged(real value)

    property bool backgroundVisible: true
    property int fontSize: 15
    property real radius: theme ? (theme.radiusMedium || 8) : 8
    property color trackColor: theme ? theme.tertiaryColor : "#F2F2F7"
    property color fillColor: theme ? theme.focusColor : "#007AFF"
    property color handleColor: theme ? theme.secondaryColor : "#FFFFFF"
    property color borderColor: theme ? theme.getBorderColor(root.focused) : "#D1D1D6"
    property int itemSpacing: 12
    property int containerMargins: 8
    property bool focused: false
    property bool isPressed: false
    property bool hovered: false
    property bool _syncing: false
    property bool _ready: false

    implicitWidth: 320
    implicitHeight: theme ? theme.controlHeight : 44
    activeFocusOnTab: true
    opacity: root.enabled ? 1 : 0.45

    Accessible.role: Accessible.Slider
    Accessible.name: root.text
    Accessible.description: root.formatValue(root.displayValue)

    readonly property real lowerBound: Math.min(root.minimumValue, root.maximumValue)
    readonly property real upperBound: Math.max(root.minimumValue, root.maximumValue)
    readonly property real displayValue: root.value

    function clamp(valueToClamp) {
        var numeric = Number(valueToClamp);
        if (!isFinite(numeric))
            numeric = root.lowerBound;
        return Math.max(root.lowerBound, Math.min(root.upperBound, numeric));
    }

    function quantize(valueToQuantize) {
        var step = Math.abs(Number(root.stepSize));
        if (!isFinite(step) || step <= 0)
            step = 1;
        var clamped = root.clamp(valueToQuantize);
        var snapped = root.lowerBound + Math.round((clamped - root.lowerBound) / step) * step;
        return Number(root.clamp(snapped).toFixed(Math.max(0, root.decimals)));
    }

    function setUserValue(nextValue) {
        if (!root.enabled)
            return;
        var normalized = root.quantize(nextValue);
        if (normalized !== root.value)
            root.value = normalized;
        root.userValueChanged(normalized);
    }

    function valueFromPosition(position) {
        var span = Math.max(0, track.width - handle.width);
        var fraction = span > 0 ? Number(position) / span : 0;
        fraction = Math.max(0, Math.min(1, fraction));
        return root.lowerBound + fraction * (root.upperBound - root.lowerBound);
    }

    function updateHandle() {
        var span = Math.max(0, track.width - handle.width);
        var fraction = root.upperBound > root.lowerBound ? (root.clamp(root.value) - root.lowerBound) / (root.upperBound - root.lowerBound) : 0;
        handleX = Math.max(0, Math.min(span, fraction * span));
    }

    function formatValue(realValue) {
        var formatted = root.decimals > 0 ? Number(realValue).toFixed(root.decimals) : String(Math.round(realValue));
        return formatted + root.valueSuffix;
    }

    function commitSpinValue(scaledValue) {
        root.setUserValue(Number(scaledValue) / root._scale);
    }

    function normalizeCurrentValue() {
        var normalized = root.quantize(root.value);
        if (normalized !== root.value)
            root.value = normalized;
        else
            root.updateHandle();
    }

    property real handleX: 0

    onValueChanged: {
        var normalized = root.quantize(root.value);
        if (normalized !== root.value) {
            root._syncing = true;
            root.value = normalized;
            root._syncing = false;
        }
        root.updateHandle();
    }
    onMinimumValueChanged: root.normalizeCurrentValue()
    onMaximumValueChanged: root.normalizeCurrentValue()
    onStepSizeChanged: root.normalizeCurrentValue()
    onDecimalsChanged: root.normalizeCurrentValue()

    Component.onCompleted: {
        root.value = root.quantize(root.value);
        root._ready = true;
        root.updateHandle();
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: Math.max(0, root.radius)
        color: root.backgroundVisible ? (theme ? theme.secondaryColor : "#FFFFFF") : "transparent"
        border.width: root.focused || root.activeFocus ? 2 : 1
        border.color: root.focused || root.activeFocus ? (theme ? theme.focusColor : "#007AFF") : root.borderColor
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: Math.max(0, root.containerMargins)
        spacing: Math.max(0, root.itemSpacing)

        Text {
            id: label
            text: ""
            visible: text !== ""
            color: theme ? theme.textColor : "#1D1D1F"
            font.family: theme ? theme.fontFamily : "sans-serif"
            font.pixelSize: root.fontSize
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            Layout.preferredWidth: Math.max(0, root.labelWidth)
            Layout.maximumWidth: Math.max(0, root.labelWidth)
        }

        Item {
            id: track
            Layout.fillWidth: true
            Layout.minimumWidth: 64
            Layout.preferredHeight: 30
            Layout.alignment: Qt.AlignVCenter
            onWidthChanged: root.updateHandle()

            Rectangle {
                id: trackRail
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 6
                radius: height / 2
                color: root.trackColor

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.max(0, root.handleX + handle.width / 2)
                    radius: height / 2
                    color: root.fillColor
                }
            }

            Rectangle {
                id: handle
                width: 22
                height: 22
                x: root.handleX
                anchors.verticalCenter: parent.verticalCenter
                radius: width / 2
                color: root.handleColor
                border.width: 1
                border.color: theme ? theme.borderColor : "#D1D1D6"
                scale: root.isPressed ? 0.92 : (root.hovered || root.focused ? 1.04 : 1)
                Behavior on x {
                    enabled: root._ready && !root.isPressed
                    NumberAnimation {
                        duration: theme ? theme.durationFast : 120
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: theme ? theme.durationFast : 120
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                id: trackPointer
                anchors.fill: parent
                enabled: root.enabled
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onEntered: root.hovered = true
                onExited: root.hovered = false
                onPressed: {
                    root.forceActiveFocus();
                    root.focused = true;
                    root.isPressed = true;
                    var local = Math.max(0, Math.min(track.width - handle.width, mouse.x - handle.width / 2));
                    root.handleX = local;
                    root.setUserValue(root.valueFromPosition(local));
                }
                onPositionChanged: {
                    if (pressed) {
                        var local = Math.max(0, Math.min(track.width - handle.width, mouse.x - handle.width / 2));
                        root.handleX = local;
                        root.setUserValue(root.valueFromPosition(local));
                    }
                }
                onReleased: {
                    root.isPressed = false;
                    root.focused = true;
                }
                onCanceled: root.isPressed = false
            }
        }

        Basic.SpinBox {
            id: spin
            visible: root.showValueLabel && root.showSpinBox
            enabled: root.enabled && root.valueEditable
            Layout.preferredWidth: Math.max(48, root.valueWidth)
            Layout.preferredHeight: Math.max(32, row.height - 4)
            from: Math.round(root.lowerBound * root._scale)
            to: Math.round(root.upperBound * root._scale)
            stepSize: Math.max(1, Math.round(Math.abs(root.stepSize) * root._scale))
            value: Math.round(root.value * root._scale)
            editable: root.valueEditable
            background: Rectangle {
                radius: theme ? theme.radiusSmall : 6
                color: root.backgroundVisible ? (theme ? theme.tertiaryColor : "#F2F2F7") : "transparent"
                border.width: spin.activeFocus ? 2 : 1
                border.color: spin.activeFocus ? (theme ? theme.focusColor : "#007AFF") : (theme ? theme.borderColor : "#D1D1D6")
            }
            contentItem: TextInput {
                text: root.formatValue(Number(spin.value) / root._scale)
                color: theme ? theme.textColor : "#1D1D1F"
                font.family: theme ? theme.fontFamily : "sans-serif"
                font.pixelSize: root.fontSize
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                readOnly: !root.valueEditable
                selectByMouse: true
            }
            textFromValue: function (scaled, locale) {
                return root.formatValue(Number(scaled) / root._scale);
            }
            valueFromText: function (display, locale) {
                var cleaned = String(display).replace(root.valueSuffix, "").trim();
                var parsed = Number(cleaned);
                return isFinite(parsed) ? Math.round(root.quantize(parsed) * root._scale) : spin.from;
            }
            onValueModified: root.commitSpinValue(spin.value)
            onActiveFocusChanged: root.focused = activeFocus
        }

        Text {
            id: valueText
            visible: root.showValueLabel && root.showValueText && !root.showSpinBox
            text: root.formatValue(root.value)
            color: theme ? theme.textColor : "#1D1D1F"
            font.family: theme ? theme.fontFamily : "sans-serif"
            font.pixelSize: root.fontSize
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: Math.max(0, root.valueWidth)
        }
    }

    Keys.onLeftPressed: {
        event.accepted = true;
        root.focused = true;
        root.setUserValue(root.value - Math.abs(root.stepSize || 1));
    }
    Keys.onDownPressed: {
        event.accepted = true;
        root.focused = true;
        root.setUserValue(root.value - Math.abs(root.stepSize || 1));
    }
    Keys.onRightPressed: {
        event.accepted = true;
        root.focused = true;
        root.setUserValue(root.value + Math.abs(root.stepSize || 1));
    }
    Keys.onUpPressed: {
        event.accepted = true;
        root.focused = true;
        root.setUserValue(root.value + Math.abs(root.stepSize || 1));
    }
    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Home) {
            event.accepted = true;
            root.setUserValue(root.lowerBound);
        } else if (event.key === Qt.Key_End) {
            event.accepted = true;
            root.setUserValue(root.upperBound);
        }
    }

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        active: false
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "Slider"
        nameZh: "滑块"
    }
}
