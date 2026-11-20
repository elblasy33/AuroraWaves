import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import "kshim" as Kirigami
import "kshim"

// Right-hand panel: what plays next (YouTube queue or your stations) and the lyrics.
GlassPanel {
    id: panel
    property var app
    property string tab: app.ytMode ? "queue" : "stations"

    readonly property real gu: Units.gridUnit
    radius: 24
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: gu * 0.7
        spacing: Units.largeSpacing

        Segmented {
            Layout.fillWidth: true
            accent: panel.app.accent
            current: panel.tab
            model: panel.app.ytMode
                   ? [{ key: "queue", text: panel.app.t("التالي"), icon: "view-media-playlist" },
                      { key: "lyrics", text: panel.app.t("الكلمات"), icon: "lyrics" }]
                   : [{ key: "stations", text: panel.app.t("محطاتك"), icon: "network-wireless" },
                      { key: "lyrics", text: panel.app.t("الكلمات"), icon: "lyrics" }]
            onPicked: function (key) { panel.tab = key }
        }

        // YouTube Music queue
        ListView {
            id: queue
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: panel.tab === "queue"
            clip: true
            spacing: Units.smallSpacing
            model: visible ? panel.app.ytQueue : []
            boundsBehavior: Flickable.StopAtBounds
            QQC2.ScrollBar.vertical: QQC2.ScrollBar { }
            onVisibleChanged: if (visible) positionViewAtIndex(panel.app.ytIndex, ListView.Center)
            header: QQC2.Label {
                width: queue.width
                bottomPadding: Units.smallSpacing
                text: (panel.app.ytName ? panel.app.ytName + "  ·  " : "") + panel.app.ytQueue.length + panel.app.t(" أغنية")
                color: Theme.dimTextColor
                font: Theme.smallFont
                elide: Text.ElideRight
            }
            delegate: GlassPanel {
                id: qrow
                required property var modelData
                required property int index
                readonly property bool cur: index === panel.app.ytIndex
                width: queue.width - Units.smallSpacing
                height: gu * 2.8
                radius: 14
                highlighted: cur
                accent: panel.app.accent
                hovered: qh.hovered
                opacity: index < panel.app.ytIndex ? 0.55 : 1
                HoverHandler { id: qh }
                TapHandler { onTapped: panel.app.jumpYt(qrow.index) }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Units.smallSpacing * 2
                    anchors.rightMargin: Units.smallSpacing * 2
                    spacing: Units.smallSpacing * 2
                    StationLogo { Layout.preferredWidth: gu * 2; Layout.preferredHeight: gu * 2; logo: qrow.modelData.thumb || ""; tint: "#e53935"; glyph: "♪"; radiusRatio: 0.22 }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        QQC2.Label { Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; text: qrow.modelData.title; color: qrow.cur ? panel.app.accent : Theme.textColor; font.weight: qrow.cur ? Font.Bold : Font.Normal; elide: Text.ElideRight }
                        QQC2.Label { Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; text: qrow.modelData.artist || ""; color: Theme.dimTextColor; font: Theme.smallFont; elide: Text.ElideRight }
                    }
                }
            }
        }

        // radio: your stations, one click to switch
        ListView {
            id: stations
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: panel.tab === "stations"
            clip: true
            spacing: Units.smallSpacing
            model: visible ? panel.app.stations : []
            boundsBehavior: Flickable.StopAtBounds
            QQC2.ScrollBar.vertical: QQC2.ScrollBar { }
            delegate: GlassPanel {
                id: srow
                required property var modelData
                readonly property bool cur: panel.app.current !== null && panel.app.current.id === modelData.id && !panel.app.ytMode
                width: stations.width - Units.smallSpacing
                height: gu * 2.8
                radius: 14
                highlighted: cur && panel.app.wantPlaying
                accent: modelData.color
                hovered: sh.hovered
                HoverHandler { id: sh }
                TapHandler { onTapped: panel.app.play(srow.modelData.id) }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Units.smallSpacing * 2
                    anchors.rightMargin: Units.smallSpacing * 2
                    spacing: Units.smallSpacing * 2
                    StationLogo { Layout.preferredWidth: gu * 2; Layout.preferredHeight: gu * 2; logo: srow.modelData.logo || ""; tint: srow.modelData.color; glyph: srow.modelData.glyph || "" }
                    QQC2.Label { Layout.fillWidth: true; text: srow.modelData.name; color: Theme.textColor; font.weight: srow.cur ? Font.Bold : Font.Normal; elide: Text.ElideRight }
                    Equalizer { visible: srow.cur && panel.app.isPlaying; width: gu * 1.2; height: gu * 0.9; bars: 4; color: srow.modelData.color; running: visible && Prefs.animations }
                }
            }
        }

        LyricsView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: panel.tab === "lyrics"
            app: panel.app
        }
    }
}
