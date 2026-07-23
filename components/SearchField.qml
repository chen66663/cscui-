pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

// Search entry built on the shared Input look, with clear affordance and submit signal.
FocusScope {
    id: root

    property var theme: null
    property alias text: field.text
    property string placeholderText: theme ? theme.localized("Search", "搜索") : "Search"
    property string accessibleName: root.placeholderText
    signal submitted(string text)
    signal cleared()

    implicitWidth: 280
    implicitHeight: theme ? theme.controlHeight : 36
    activeFocusOnTab: true
    Accessible.role: Accessible.EditableText
    Accessible.name: root.accessibleName

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: root.theme ? root.theme.radiusMedium : 8
        color: root.theme ? root.theme.secondaryColor : "#FFFFFF"
        border.width: root.activeFocus || field.activeFocus ? 2 : 1
        border.color: root.activeFocus || field.activeFocus
                      ? (root.theme ? root.theme.focusColor : "#0066CC")
                      : (root.theme ? root.theme.borderColor : "#D1D1D6")

        Behavior on border.color {
            ColorAnimation {
                duration: root.theme ? root.theme.durationFast : 140
                easing.type: Easing.OutCubic
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.theme ? root.theme.spacingSmall : 8
        anchors.rightMargin: root.theme ? root.theme.spacingSmall : 8
        spacing: root.theme ? root.theme.spacingSmall : 8

        Text {
            text: "\uf002"
            color: root.theme ? root.theme.secondaryTextColor : "#5C5C60"
            font.family: root.theme ? root.theme.iconFamily(iconFont.name) : iconFont.name
            font.pixelSize: 13
            Layout.preferredWidth: 16
            horizontalAlignment: Text.AlignHCenter
        }

        TextInput {
            id: field
            Layout.fillWidth: true
            Layout.fillHeight: true
            verticalAlignment: TextInput.AlignVCenter
            color: root.theme ? root.theme.textColor : "#1D1D1F"
            font.family: root.theme ? root.theme.fontFamily : "sans-serif"
            font.pixelSize: root.theme ? root.theme.fontSizeBody : 13
            selectByMouse: true
            clip: true
            leftPadding: 0
            rightPadding: 0
            onAccepted: root.submitted(text)

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: !field.text && !field.activeFocus
                text: root.placeholderText
                color: root.theme ? root.theme.tertiaryTextColor : "#6E6E73"
                font: field.font
                elide: Text.ElideRight
            }
        }

        Text {
            visible: field.text.length > 0
            text: "\uf00d"
            color: root.theme ? root.theme.secondaryTextColor : "#5C5C60"
            font.family: root.theme ? root.theme.iconFamily(iconFont.name) : iconFont.name
            font.pixelSize: 12
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            Accessible.role: Accessible.Button
            Accessible.name: root.theme ? root.theme.localized("Clear", "清除") : "Clear"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    field.text = "";
                    root.cleared();
                    field.forceActiveFocus();
                }
            }
        }
    }

    FontLoader {
        id: iconFont
        source: root.theme ? root.theme.iconSource() : "qrc:/cscui/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    Keys.onEscapePressed: (event) => {
        if (field.text.length > 0) {
            field.text = "";
            root.cleared();
            event.accepted = true;
        }
    }

    CscIdentityLayer {
        parent: root
        anchors.fill: parent
        theme: root.theme
        nameEn: "SearchField"
        nameZh: "搜索框"
    }
}
