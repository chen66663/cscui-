pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

// Data table with optional row selection. Row activation and selection are
// deliberately separate: selectable=false never mutates a model's `checked`
// role, while rowClicked remains available for normal table actions.
Rectangle {
    id: root

    property var theme: null

    width: 600
    height: 400
    clip: true
    color: "transparent"

    property var headers: []
    property var model: ListModel {}
    property bool selectable: false
    signal rowClicked(int index, var rowData)
    signal checkStateChanged(int index, var rowData, bool isChecked)

    property bool backgroundVisible: true
    property real radius: theme ? (theme.radiusLarge || 12) : 12
    property int headerHeight: 44
    property int rowHeight: 44
    property int fontSize: 13
    property int cellPadding: 12
    property real pressedScale: 0.98
    property color headerColor: theme ? theme.tertiaryColor : "#F2F2F7"
    property color rowColor: theme ? theme.secondaryColor : "#FFFFFF"
    property color hoverColor: theme ? theme.hoverColor : "#E5E5EA"
    property color textColor: theme ? theme.textColor : "#1D1D1F"
    property color headerTextColor: theme ? theme.secondaryTextColor : "#5C5C60"
    property bool shadowEnabled: true
    property color shadowColor: theme ? theme.shadowColor : "#24000000"
    property color checkmarkColor: theme ? theme.focusColor : "#007AFF"
    property int boxSize: 20
    property var columnWidths: []
    property string headerCheckState: "none" // none, all, partial
    property int modelRevision: 0

    // Model signals can arrive in bursts (for example, one per ListModel row).
    // Coalesce expensive measurements and selection scans into one event-loop pass.
    property bool _columnWidthRefreshPending: false
    property bool _selectionRefreshPending: false
    property bool _ignoreInternalModelSignals: false
    property bool _componentReady: false
    property var _textWidthCache: ({})
    property int _textWidthCacheSize: 0

    readonly property int rowCount: root.model && root.model.count !== undefined ? root.model.count : (root.model ? root.model.length : 0)
    readonly property int selectionColumnWidth: root.selectable ? 44 : 0
    readonly property int tableContentWidth: root.selectionColumnWidth + root.sumColumnWidths()

    Accessible.role: Accessible.Table
    Accessible.name: theme ? theme.localized("Data table", "数据表格") : "Data table"

    function sumColumnWidths() {
        var total = 0;
        for (var i = 0; i < root.columnWidths.length; ++i)
            total += Number(root.columnWidths[i]) || 0;
        return total;
    }

    function rowAt(index) {
        if (!root.model || index < 0 || index >= root.rowCount)
            return ({});
        if (root.model.get !== undefined)
            return root.model.get(index);
        return root.model[index] || ({});
    }

    function rowChecked(index) {
        // Reading modelRevision makes the binding refresh when ListModel.setProperty is used.
        var revision = root.modelRevision;
        var row = root.rowAt(index);
        return row && row.checked === true;
    }

    function cellText(row, key) {
        if (!row || row[key] === undefined || row[key] === null)
            return "-";
        return String(row[key]);
    }

    function measuredTextWidth(value) {
        var text = String(value);
        var cacheKey = "$" + text;
        var cached = root._textWidthCache[cacheKey];
        if (cached !== undefined)
            return cached;

        textMetrics.text = text;
        var width = textMetrics.width;
        // Bound the cache so a table containing unbounded user text cannot
        // retain every value for the lifetime of the component.
        if (root._textWidthCacheSize >= 2048) {
            root._textWidthCache = ({});
            root._textWidthCacheSize = 0;
        }
        root._textWidthCache[cacheKey] = width;
        root._textWidthCacheSize += 1;
        return width;
    }

    function updateHeaderCheckState() {
        if (!root.selectable || root.rowCount === 0) {
            root.headerCheckState = "none";
            return;
        }
        var checked = 0;
        for (var i = 0; i < root.rowCount; ++i) {
            if (root.rowChecked(i))
                ++checked;
        }
        root.headerCheckState = checked === 0 ? "none" : (checked === root.rowCount ? "all" : "partial");
    }

    function calculateColumnWidths() {
        var widths = [];
        for (var i = 0; i < root.headers.length; ++i) {
            var header = root.headers[i] || ({});
            var headerText = String(header.label !== undefined ? header.label : header.key || "");
            widths.push(Math.max(96, root.measuredTextWidth(headerText) + root.cellPadding * 2));
        }
        for (var rowIndex = 0; rowIndex < root.rowCount; ++rowIndex) {
                var row = root.rowAt(rowIndex);
                for (var column = 0; column < root.headers.length; ++column) {
                    var key = root.headers[column] ? root.headers[column].key : "";
                    var textWidth = root.measuredTextWidth(root.cellText(row, key));
                    widths[column] = Math.max(widths[column] || 96, textWidth + root.cellPadding * 2);
                }
            }

        // Avoid invalidating every cell when the measured widths did not change.
        if (widths.length === root.columnWidths.length) {
            var unchanged = true;
            for (var widthIndex = 0; widthIndex < widths.length; ++widthIndex) {
                if (widths[widthIndex] !== root.columnWidths[widthIndex]) {
                    unchanged = false;
                    break;
                }
            }
            if (unchanged)
                return;
        }
        root.columnWidths = widths;
    }

    function scheduleModelRefresh(recalculateWidths, refreshSelection) {
        if (!root._componentReady)
            return;
        if (recalculateWidths)
            root._columnWidthRefreshPending = true;
        if (refreshSelection)
            root._selectionRefreshPending = true;
        modelRefreshTimer.restart();
    }

    function flushModelRefresh() {
        var recalculateWidths = root._columnWidthRefreshPending;
        var refreshSelection = root._selectionRefreshPending;
        root._columnWidthRefreshPending = false;
        root._selectionRefreshPending = false;

        if (recalculateWidths)
            root.calculateColumnWidths();
        if (refreshSelection)
            root.updateHeaderCheckState();
    }

    function writeRowChecked(index, checked) {
        if (root.model && root.model.setProperty !== undefined)
            root.model.setProperty(index, "checked", checked);
        else if (root.model && root.model[index] !== undefined)
            root.model[index].checked = checked;
    }

    function setRowChecked(index, checked) {
        if (!root.selectable || index < 0 || index >= root.rowCount)
            return;

        // Internal writes are accounted for below; ignore the synchronous
        // ListModel dataChanged signal so one click produces one refresh.
        root._ignoreInternalModelSignals = true;
        try {
            root.writeRowChecked(index, checked);
        } finally {
            root._ignoreInternalModelSignals = false;
        }
        root.modelRevision += 1;
        root.updateHeaderCheckState();
    }

    function toggleAll() {
        if (!root.selectable)
            return;
        var next = root.headerCheckState !== "all";
        var changed = false;

        // Batch row writes so select-all remains O(n), rather than rescanning
        // all rows and rebuilding delegate bindings after every item.
        root._ignoreInternalModelSignals = true;
        try {
            for (var i = 0; i < root.rowCount; ++i) {
                if (root.rowChecked(i) === next)
                    continue;
                root.writeRowChecked(i, next);
                changed = true;
            }
        } finally {
            root._ignoreInternalModelSignals = false;
        }

        if (changed)
            root.modelRevision += 1;
        root.headerCheckState = root.rowCount > 0 && next ? "all" : "none";
    }

    function activateRow(index) {
        var row = root.rowAt(index);
        if (root.selectable) {
            var next = !root.rowChecked(index);
            root.setRowChecked(index, next);
            root.checkStateChanged(index, row, next);
        }
        root.rowClicked(index, row);
    }

    TextMetrics {
        id: textMetrics
        font.family: theme ? theme.fontFamily : "sans-serif"
        font.pixelSize: root.fontSize
        onFontChanged: {
            root._textWidthCache = ({});
            root._textWidthCacheSize = 0;
            root.scheduleModelRefresh(true, false);
        }
    }

    Timer {
        id: modelRefreshTimer
        interval: 16
        repeat: false
        onTriggered: root.flushModelRefresh()
    }

    Component.onCompleted: {
        root._componentReady = true;
        modelRefreshTimer.stop();
        root._columnWidthRefreshPending = false;
        root._selectionRefreshPending = false;
        root.calculateColumnWidths();
        root.updateHeaderCheckState();
    }
    onHeadersChanged: root.scheduleModelRefresh(true, false)
    onModelChanged: {
        root.modelRevision += 1;
        root.scheduleModelRefresh(true, true);
    }
    onSelectableChanged: root.updateHeaderCheckState()
    onCellPaddingChanged: root.scheduleModelRefresh(true, false)
    onFontSizeChanged: {
        root._textWidthCache = ({});
        root._textWidthCacheSize = 0;
        root.scheduleModelRefresh(true, false);
    }

    Connections {
        target: root.model && root.model.dataChanged !== undefined ? root.model : null
        enabled: target !== null
        function onDataChanged() {
            if (root._ignoreInternalModelSignals)
                return;
            root.modelRevision += 1;
            root.scheduleModelRefresh(true, true);
        }
        function onRowsInserted() {
            root.modelRevision += 1;
            root.scheduleModelRefresh(true, true);
        }
        function onRowsRemoved() {
            root.modelRevision += 1;
            root.scheduleModelRefresh(true, true);
        }
    }

    MultiEffect {
        source: surface
        anchors.fill: surface
        visible: root.backgroundVisible && root.shadowEnabled
        shadowEnabled: visible
        shadowColor: root.shadowColor
        shadowBlur: theme ? theme.shadowBlur : 0.25
        shadowHorizontalOffset: theme ? theme.shadowXOffset : 0
        shadowVerticalOffset: theme ? theme.shadowYOffset : 2
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: Math.max(0, root.radius)
        visible: root.backgroundVisible
        color: root.rowColor
        clip: true
    }

    FontLoader {
        id: iconFont
        source: root.theme ? root.theme.iconSource() : "qrc:/cscui/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    Flickable {
        id: horizontalFlick
        anchors.fill: parent
        anchors.margins: 1
        clip: true
        flickableDirection: Flickable.HorizontalFlick
        contentWidth: Math.max(width, root.tableContentWidth)
        contentHeight: height
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: tableColumn
            width: Math.max(horizontalFlick.width, root.tableContentWidth)
            height: horizontalFlick.height

            Row {
                id: headerRow
                width: root.tableContentWidth
                height: root.headerHeight

                Rectangle {
                    visible: root.selectable
                    width: root.selectionColumnWidth
                    height: parent.height
                    color: root.headerColor

                    FocusScope {
                        anchors.centerIn: parent
                        width: root.boxSize + 8
                        height: root.boxSize + 8
                        activeFocusOnTab: true
                        Accessible.role: Accessible.CheckBox
                        Accessible.name: theme ? theme.localized("Select all rows", "选择全部行") : "Select all rows"
                        Accessible.checkable: true
                        Accessible.checked: root.headerCheckState === "all"

                        Rectangle {
                            anchors.centerIn: parent
                            width: root.boxSize
                            height: root.boxSize
                            radius: 5
                            color: root.headerCheckState === "none" ? "transparent" : root.checkmarkColor
                            border.width: root.headerCheckState === "none" ? 2 : 0
                            border.color: root.checkmarkColor

                            Text {
                                anchors.centerIn: parent
                                text: root.headerCheckState === "partial" ? "\uf068" : "\uf00c"
                                visible: root.headerCheckState !== "none"
                                color: theme ? theme.contrastTextColor(root.checkmarkColor) : "#FFFFFF"
                                font.family: root.theme ? root.theme.iconFamily(iconFont.name) : iconFont.name
                                font.pixelSize: 11
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: root.enabled
                            onClicked: root.toggleAll()
                        }
                        Keys.onSpacePressed: {
                            event.accepted = true;
                            root.toggleAll();
                        }
                        Keys.onReturnPressed: {
                            event.accepted = true;
                            root.toggleAll();
                        }
                    }
                }

                Repeater {
                    model: root.headers
                    delegate: Rectangle {
                        required property int index
                        required property var modelData
                        width: root.columnWidths[index] || 96
                        height: headerRow.height
                        color: root.headerColor

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: root.cellPadding
                            anchors.rightMargin: root.cellPadding
                            text: String(modelData.label !== undefined ? modelData.label : modelData.key || "")
                            color: root.headerTextColor
                            font.family: theme ? theme.fontFamily : "sans-serif"
                            font.pixelSize: root.fontSize
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            ListView {
                id: tableView
                width: root.tableContentWidth
                height: Math.max(0, tableColumn.height - root.headerHeight)
                model: root.model || []
                clip: true
                spacing: 1
                boundsBehavior: Flickable.StopAtBounds
                // Keep a small off-screen buffer so flings do not hitch while
                // still avoiding a full-table texture reserve.
                cacheBuffer: Math.max(headerHeight * 4, 160)
                reuseItems: true

                delegate: FocusScope {
                    id: rowItem
                    required property int index
                    width: tableView.width
                    height: Math.max(44, root.rowHeight)
                    activeFocusOnTab: true
                    property var rowData: root.rowAt(index)
                    property bool checked: {
                        root.modelRevision;
                        return root.rowChecked(index);
                    }
                    property bool hovered: rowPointer.containsMouse

                    Accessible.role: Accessible.Row
                    Accessible.name: (theme ? theme.localized("Row ", "第 ") : "Row ")
                                     + (index + 1)
                                     + (theme && theme.isChinese ? " 行" : "")
                    Accessible.selected: rowItem.checked

                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: rowItem.hovered || rowItem.activeFocus ? root.hoverColor : root.rowColor
                        border.width: rowItem.activeFocus ? 2 : 0
                        border.color: theme ? theme.focusColor : "#007AFF"
                        Behavior on color {
                            ColorAnimation {
                                duration: theme ? theme.durationFast : 120
                            }
                        }
                    }

                    Row {
                        anchors.fill: parent

                        Rectangle {
                            visible: root.selectable
                            width: root.selectionColumnWidth
                            height: parent.height
                            color: "transparent"

                            Rectangle {
                                anchors.centerIn: parent
                                width: root.boxSize
                                height: root.boxSize
                                radius: 5
                                color: rowItem.checked ? root.checkmarkColor : "transparent"
                                border.width: rowItem.checked ? 0 : 2
                                border.color: root.checkmarkColor
                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf00c"
                                    visible: rowItem.checked
                                    color: theme ? theme.contrastTextColor(root.checkmarkColor) : "#FFFFFF"
                                    font.family: root.theme ? root.theme.iconFamily(iconFont.name) : iconFont.name
                                    font.pixelSize: 11
                                }
                            }
                        }

                        Repeater {
                            model: root.headers
                            delegate: Item {
                                required property int index
                                required property var modelData
                                width: root.columnWidths[index] || 96
                                height: rowItem.height
                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: root.cellPadding
                                    anchors.rightMargin: root.cellPadding
                                    text: root.cellText(rowItem.rowData, modelData.key)
                                    color: root.textColor
                                    font.family: theme ? theme.fontFamily : "sans-serif"
                                    font.pixelSize: root.fontSize
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: rowPointer
                        anchors.fill: parent
                        enabled: root.enabled
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            rowItem.forceActiveFocus();
                            root.activateRow(rowItem.index);
                        }
                    }

                    Keys.onSpacePressed: {
                        event.accepted = true;
                        root.activateRow(rowItem.index);
                    }
                    Keys.onReturnPressed: {
                        event.accepted = true;
                        root.activateRow(rowItem.index);
                    }
                    Keys.onEnterPressed: {
                        event.accepted = true;
                        root.activateRow(rowItem.index);
                    }
                }

                ScrollBar.vertical: CscScrollBar {
                    theme: root.theme
                    policy: ScrollBar.AsNeeded
                }
            }
        }

        ScrollBar.horizontal: CscScrollBar {
            theme: root.theme
            policy: ScrollBar.AsNeeded
        }
    }

    // Workbench identity chip (hover → name). Reparented to root so default
    // property aliases (content slots) do not swallow it.
    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "DataTable"
        nameZh: "数据表"
    }
}
