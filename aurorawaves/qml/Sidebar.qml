import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import "kshim" as Kirigami
import "kshim"

// Glass navigation rail: brand, sections, account. Icons only when collapsed.
GlassPanel {
    id: bar
    property var app
    property string current: "home"
    property bool collapsed: false
    signal picked(string key)

    readonly property real gu: Units.gridUnit
    readonly property var sections: [
        { key: "home",     icon: "go-home",          text: app.t("الرئيسية") },
        { key: "radio",    icon: "network-wireless", text: app.t("الراديو") },
        { key: "youtube",  icon: "music-note-16th",  text: app.t("يوتيوب ميوزك") },
        { key: "music",    icon: "folder-music",     text: app.t("موسيقاي") }
    ]

    implicitWidth: collapsed ? gu * 4 : gu * 13
    Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    radius: 24
    clip: true

    component NavItem: Item {
        id: nav
        property string key
        property string icon
        property string text
        readonly property bool sel: bar.current === key
        Layout.fillWidth: true
        implicitHeight: gu * 2.4

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: nav.sel ? Qt.rgba(bar.app.accent.r, bar.app.accent.g, bar.app.accent.b, 0.28)
                 : navMouse.containsMouse ? Qt.rgba(Theme.textColor.r, Theme.textColor.g, Theme.textColor.b, 0.07) : "transparent"
            border.width: nav.sel ? 1 : 0
            border.color: Qt.rgba(bar.app.accent.r, bar.app.accent.g, bar.app.accent.b, 0.7)
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: bar.collapsed ? 0 : gu * 0.8
            anchors.rightMargin: gu * 0.8
            spacing: gu * 0.7
            Item { Layout.fillWidth: bar.collapsed }
            Kirigami.Icon {
                source: nav.icon
                implicitWidth: Units.iconSizes.smallMedium
                color: nav.sel ? Theme.textColor : Theme.dimTextColor
            }
            QQC2.Label {
                visible: !bar.collapsed
                Layout.fillWidth: true
                text: nav.text
                color: Theme.textColor
                opacity: nav.sel ? 1 : 0.78
                font.weight: nav.sel ? Font.Bold : Font.Medium
                elide: Text.ElideRight
            }
            Item { Layout.fillWidth: bar.collapsed }
        }
        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: bar.picked(nav.key)
            QQC2.ToolTip.text: nav.text
            QQC2.ToolTip.visible: bar.collapsed && containsMouse
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: gu * 0.7
        spacing: gu * 0.3

        // brand
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: gu * 0.8
            spacing: gu * 0.6
            Item { Layout.fillWidth: bar.collapsed }
            Image {
                source: "../assets/aurora-waves.svg"
                sourceSize: Qt.size(gu * 2.2, gu * 2.2)
                Layout.preferredWidth: gu * 2.2
                Layout.preferredHeight: gu * 2.2
            }
            ColumnLayout {
                visible: !bar.collapsed
                spacing: 0
                Layout.fillWidth: true
                QQC2.Label { text: bar.app.t("أمواج أورورا"); color: Theme.textColor; font.weight: Font.Bold; font.pointSize: Theme.defaultFont.pointSize * 1.15; elide: Text.ElideRight; Layout.fillWidth: true }
                QQC2.Label { text: bar.app.t("راديو · يوتيوب · موسيقاك"); color: Theme.dimTextColor; font: Theme.smallFont; elide: Text.ElideRight; Layout.fillWidth: true }
            }
            Item { Layout.fillWidth: bar.collapsed }
        }

        Repeater {
            model: bar.sections
            delegate: NavItem {
                required property var modelData
                key: modelData.key
                icon: modelData.icon
                text: modelData.text
            }
        }

        Item { Layout.fillHeight: true }

        // the playing station / song in miniature (collapsed rail shows only the cover)
        GlassPanel {
            Layout.fillWidth: true
            visible: bar.app.wantPlaying
            implicitHeight: gu * 3.2
            radius: 18
            accent: bar.app.accent
            highlighted: true
            RowLayout {
                anchors.fill: parent
                anchors.margins: gu * 0.4
                spacing: gu * 0.5
                Item { Layout.fillWidth: bar.collapsed }
                StationLogo {
                    Layout.preferredWidth: gu * 2.3; Layout.preferredHeight: gu * 2.3
                    logo: bar.app.ytMode && bar.app.ytTrack ? (bar.app.ytTrack.thumb || "") : bar.app.current ? (bar.app.current.logo || "") : ""
                    tint: bar.app.accent
                    glyph: bar.app.current ? (bar.app.current.glyph || "") : "♪"
                }
                QQC2.Label {
                    visible: !bar.collapsed
                    Layout.fillWidth: true
                    text: bar.app.ytMode && bar.app.ytTrack ? bar.app.ytTrack.title : bar.app.current ? bar.app.current.name : ""
                    color: Theme.textColor
                    font: Theme.smallFont
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Item { Layout.fillWidth: bar.collapsed }
            }
        }

        NavItem { key: "settings"; icon: "configure"; text: bar.app.t("الإعدادات") }

        // collapse / expand the rail
        QQC2.ToolButton {
            Layout.alignment: Qt.AlignHCenter
            icon.name: (bar.collapsed !== bar.app.rtl) ? "go-next" : "go-previous"
            visible: !(bar.width < gu * 5 && Prefs.sidebarCollapsed === false)   // forced compact: no toggle
            onClicked: Prefs.sidebarCollapsed = !Prefs.sidebarCollapsed
            QQC2.ToolTip.text: bar.collapsed ? bar.app.t("توسيع") : bar.app.t("تصغير")
            QQC2.ToolTip.visible: hovered
        }
    }
}
