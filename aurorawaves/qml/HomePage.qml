import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import "kshim" as Kirigami
import "kshim"

// Home: a greeting, your stations, and YouTube Music's feed in your language.
Item {
    id: home
    property var app
    signal openPage(string key)
    signal openYtItem(var item)

    readonly property real gu: Units.gridUnit
    property var shelves: []
    property bool loading: false

    readonly property string greeting: {
        var h = new Date().getHours()
        return h < 5 ? app.t("سهرة سعيدة") : h < 12 ? app.t("صباح الخير") : h < 18 ? app.t("نهارك سعيد") : app.t("مساء الخير")
    }

    function load() {
        if (loading || shelves.length > 0 || !app.ytStatus.ready) return
        loading = true
        app.runYt("home", JSON.stringify({ lang: app.lang, country: app.systemCountry }), function (r) {
            home.loading = false
            if (r && r.shelves) home.shelves = r.shelves
        })
    }
    Component.onCompleted: app.ytCheck(function () { home.load() })
    Connections { target: home.app; function onYtStatusChanged() { home.load() } }

    component Card: Item {
        id: card
        property var item
        property bool round: false
        signal picked()
        width: gu * 8
        height: cover.height + texts.implicitHeight + Units.smallSpacing
        StationLogo {
            id: cover
            width: parent.width; height: width
            logo: card.item.thumb || card.item.logo || ""
            tint: card.item.color || "#e53935"
            glyph: card.item.glyph || "♪"
            radiusRatio: card.round ? 0.5 : 0.16
            scale: cm.containsMouse ? 1.04 : 1
            Behavior on scale { NumberAnimation { duration: 140 } }
        }
        ColumnLayout {
            id: texts
            anchors.top: cover.bottom
            anchors.topMargin: Units.smallSpacing
            width: parent.width
            spacing: 0
            QQC2.Label { Layout.fillWidth: true; text: card.item.title || card.item.name || ""; color: Theme.textColor; font.weight: Font.DemiBold; elide: Text.ElideRight; horizontalAlignment: card.round ? Text.AlignHCenter : Text.AlignLeft }
            QQC2.Label { Layout.fillWidth: true; text: card.item.subtitle || card.item.group || ""; visible: text !== ""; color: Theme.dimTextColor; font: Theme.smallFont; elide: Text.ElideRight; horizontalAlignment: card.round ? Text.AlignHCenter : Text.AlignLeft }
        }
        MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: card.picked() }
    }

    component Shelf: ColumnLayout {
        id: shelf
        property string title
        property string action: ""
        property alias model: lv.model
        property alias delegate: lv.delegate
        signal actionClicked()
        Layout.fillWidth: true
        spacing: Units.smallSpacing
        RowLayout {
            Layout.fillWidth: true
            Kirigami.Heading { text: shelf.title; level: 3; Layout.fillWidth: true; elide: Text.ElideRight }
            QQC2.Label {
                visible: shelf.action !== ""
                text: shelf.action
                color: Theme.linkColor
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shelf.actionClicked() }
            }
        }
        ListView {
            id: lv
            Layout.fillWidth: true
            Layout.preferredHeight: gu * 11.6
            orientation: ListView.Horizontal
            spacing: gu
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AsNeeded }
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: col.implicitHeight + gu
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        QQC2.ScrollBar.vertical: QQC2.ScrollBar { }

        ColumnLayout {
            id: col
            width: parent.width - gu
            spacing: gu * 1.4

            // greeting
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: gu * 0.5
                spacing: 2
                Kirigami.Heading { text: home.greeting; level: 1 }
                QQC2.Label {
                    text: home.app.t("ماذا تريد أن تسمع اليوم؟")
                    color: Theme.dimTextColor
                    font.pointSize: Theme.defaultFont.pointSize * 1.1
                }
            }

            // quick starts
            Flow {
                Layout.fillWidth: true
                spacing: gu * 0.6
                Repeater {
                    model: [
                        { key: "radio", icon: "globe", text: home.app.t("اكتشف إذاعات العالم"), color: "#1e88e5" },
                        { key: "youtube", icon: "music-note-16th", text: home.app.t("ابحث في يوتيوب ميوزك"), color: "#e53935" },
                        { key: "music", icon: "folder-music", text: home.app.t("شغّل ملفاتك"), color: "#8e24aa" }
                    ]
                    delegate: GlassPanel {
                        id: qs
                        required property var modelData
                        width: Math.max(gu * 14, qsRow.implicitWidth + gu * 2)
                        height: gu * 3.4
                        radius: 20
                        accent: modelData.color
                        hovered: qsMouse.containsMouse
                        RowLayout {
                            id: qsRow
                            anchors.fill: parent
                            anchors.margins: gu * 0.6
                            spacing: gu * 0.7
                            Rectangle {
                                Layout.preferredWidth: gu * 2.2; Layout.preferredHeight: gu * 2.2
                                radius: width * 0.3
                                gradient: Gradient {
                                    GradientStop { position: 0; color: Qt.lighter(qs.modelData.color, 1.3) }
                                    GradientStop { position: 1; color: Qt.darker(qs.modelData.color, 1.3) }
                                }
                                Kirigami.Icon { anchors.centerIn: parent; source: qs.modelData.icon; width: parent.width * 0.55; height: width; color: "white" }
                            }
                            QQC2.Label { text: qs.modelData.text; color: Theme.textColor; font.weight: Font.DemiBold }
                        }
                        MouseArea { id: qsMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: home.openPage(qs.modelData.key) }
                    }
                }
            }

            // your stations
            Shelf {
                visible: home.app.stations.length > 0
                title: home.app.t("محطاتك")
                action: home.app.t("إدارة")
                onActionClicked: home.openPage("radio")
                model: home.app.stations
                delegate: Card {
                    required property var modelData
                    item: modelData
                    onPicked: home.app.play(modelData.id)
                }
            }

            // YouTube Music feed
            QQC2.BusyIndicator {
                Layout.alignment: Qt.AlignHCenter
                visible: home.loading && home.shelves.length === 0
                running: visible
            }
            GlassPanel {
                Layout.fillWidth: true
                visible: home.app.ytStatus.checked && !home.app.ytStatus.ready
                implicitHeight: ytRow.implicitHeight + gu * 1.4
                radius: 20
                RowLayout {
                    id: ytRow
                    anchors.fill: parent
                    anchors.margins: gu * 0.7
                    spacing: gu
                    Kirigami.Icon { source: "music-note-16th"; implicitWidth: Units.iconSizes.large; color: "#ff5252" }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Kirigami.Heading { text: home.app.t("يوتيوب ميوزك"); level: 3 }
                        QQC2.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: Theme.dimTextColor; text: home.app.t("فعّله لتظهر هنا الأغاني والقوائم المقترحة بلغتك.") }
                    }
                    GlassButton { text: home.app.t("تفعيل"); filled: true; accent: "#e53935"; onClicked: home.openPage("youtube") }
                }
            }
            Repeater {
                model: home.shelves
                delegate: Shelf {
                    required property var modelData
                    title: modelData.title
                    model: modelData.items
                    delegate: Card {
                        required property var modelData
                        item: modelData
                        round: modelData.kind === "artist"
                        onPicked: home.openYtItem(modelData)
                    }
                }
            }
        }
    }
}
