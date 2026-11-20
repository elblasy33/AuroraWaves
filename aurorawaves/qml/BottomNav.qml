import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import "kshim" as Kirigami
import "kshim"

// Narrow windows: the sections as a row of icons along the bottom (like a phone app).
GlassPanel {
    id: nav
    property var app
    property string current: "home"
    signal picked(string key)

    readonly property real gu: Units.gridUnit
    implicitHeight: gu * 3.4
    radius: 22

    RowLayout {
        anchors.fill: parent
        anchors.margins: gu * 0.3
        spacing: 0
        Repeater {
            model: [
                { key: "home",     icon: "go-home",          text: nav.app.t("الرئيسية") },
                { key: "radio",    icon: "network-wireless", text: nav.app.t("الراديو") },
                { key: "youtube",  icon: "music-note-16th",  text: nav.app.t("يوتيوب") },
                { key: "music",    icon: "folder-music",     text: nav.app.t("موسيقاي") },
                { key: "settings", icon: "configure",        text: nav.app.t("الإعدادات") }
            ]
            delegate: Item {
                id: item
                required property var modelData
                readonly property bool sel: nav.current === modelData.key
                Layout.fillWidth: true
                Layout.fillHeight: true
                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 6, gu * 5); height: parent.height - 4
                    radius: 16
                    color: item.sel ? Qt.rgba(nav.app.accent.r, nav.app.accent.g, nav.app.accent.b, 0.28)
                         : itemMouse.containsMouse ? Qt.rgba(Theme.textColor.r, Theme.textColor.g, Theme.textColor.b, 0.07) : "transparent"
                }
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 1
                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignHCenter
                        source: item.modelData.icon
                        implicitWidth: Units.iconSizes.smallMedium
                        color: item.sel ? Theme.textColor : Theme.dimTextColor
                    }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignHCenter
                        visible: nav.width > gu * 22
                        text: item.modelData.text
                        color: item.sel ? Theme.textColor : Theme.dimTextColor
                        font.pointSize: Theme.defaultFont.pointSize * 0.78
                        font.weight: item.sel ? Font.Bold : Font.Normal
                    }
                }
                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: nav.picked(item.modelData.key)
                }
            }
        }
    }
}
