import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import "kshim" as Kirigami
import "kshim"
import "presets.js" as Presets

// Your stations as a grid of glass cards: play on click, actions on hover, right-click menu.
// filter: "radio" (streams) or "local" (files, folders, playlists).
Item {
    id: view
    property var app
    property var form                       // StationForm
    property string filter: "radio"

    readonly property real gu: Units.gridUnit
    readonly property var items: {
        var out = []
        for (var i = 0; i < app.stations.length; i++) {
            var s = app.stations[i], k = app.kindOf(s)
            var local = k === "file" || k === "folder" || k === "playlist"
            if ((filter === "local") === local && (app.groupFilter === "" || (s.group || "") === app.groupFilter || filter === "local"))
                out.push({ st: s, index: i })
        }
        return out
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Units.largeSpacing

        // toolbar
        RowLayout {
            Layout.fillWidth: true
            spacing: Units.smallSpacing
            // category chips (radio)
            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: gu * 1.9
                visible: view.filter === "radio" && app.groups.length > 0
                contentWidth: chipRow.implicitWidth
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Row {
                    id: chipRow
                    spacing: Units.smallSpacing
                    Repeater {
                        model: [""].concat(app.groups)
                        delegate: GlassPanel {
                            id: chip
                            required property string modelData
                            readonly property bool sel: app.groupFilter === modelData
                            width: chipLbl.implicitWidth + Units.largeSpacing * 3
                            height: gu * 1.8
                            radius: height / 2
                            highlighted: sel
                            accent: app.accent
                            hovered: chipMouse.containsMouse
                            QQC2.Label { id: chipLbl; anchors.centerIn: parent; text: chip.modelData === "" ? app.t("الكل") : chip.modelData; color: Theme.textColor; font.weight: chip.sel ? Font.Bold : Font.Normal }
                            MouseArea { id: chipMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: app.groupFilter = chip.modelData }
                        }
                    }
                }
            }
            Item { Layout.fillWidth: true; visible: !(view.filter === "radio" && app.groups.length > 0) }
            GlassButton {
                visible: view.filter === "radio"
                iconName: "document-import"
                text: app.t("استيراد")
                toolTip: app.t("استيراد قائمة تشغيل (M3U / PLS) كمحطات")
                onClicked: importDialog.open()
            }
            GlassButton {
                visible: view.filter === "local"
                iconName: "folder-open"
                text: app.t("إضافة مجلد")
                onClicked: { form.openForm(-2); form.dKind = "folder"; form.openBrowse() }
            }
            GlassButton {
                iconName: "list-add"
                text: view.filter === "local" ? app.t("إضافة ملف") : app.t("محطة جديدة")
                filled: true
                accent: app.accent
                onClicked: {
                    form.openForm(-2)
                    if (view.filter === "local") { form.dKind = "file"; form.openBrowse() }
                }
            }
        }

        // the grid
        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            readonly property int cols: Math.max(2, Math.floor(width / (gu * 9.5)))
            cellWidth: Math.floor(width / cols)
            cellHeight: cellWidth * 0.92
            model: view.items
            boundsBehavior: Flickable.StopAtBounds
            QQC2.ScrollBar.vertical: QQC2.ScrollBar { }
            footer: Item {
                width: grid.width
                height: view.filter === "radio" ? maspero.implicitHeight + gu * 2 : gu
                // Egypt's official public radio, one click each
                ColumnLayout {
                    id: maspero
                    visible: view.filter === "radio"
                    anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: gu }
                    spacing: Units.smallSpacing
                    RowLayout {
                        Kirigami.Icon { source: "folder-music"; implicitWidth: Units.iconSizes.small; opacity: 0.7 }
                        QQC2.Label { text: app.t("الإذاعات المصرية الرسمية (ماسبيرو) — اضغط للإضافة"); color: Theme.textColor; font.weight: Font.DemiBold; opacity: 0.7 }
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: Units.smallSpacing
                        Repeater {
                            model: Presets.catalog
                            delegate: GlassPanel {
                                id: mchip
                                required property var modelData
                                readonly property bool added: { app.stations; return form.hasUrl(modelData.url) }
                                width: mRow.implicitWidth + Units.largeSpacing * 2
                                height: gu * 1.9
                                radius: height / 2
                                opacity: added ? 0.4 : 1
                                hovered: mMouse.containsMouse && !added
                                Row {
                                    id: mRow
                                    anchors.centerIn: parent
                                    spacing: Units.smallSpacing
                                    StationLogo { width: gu * 1.2; height: width; anchors.verticalCenter: parent.verticalCenter; logo: mchip.modelData.logo; tint: mchip.modelData.color; glyph: mchip.modelData.glyph; radiusRatio: 0.5 }
                                    QQC2.Label { text: Presets.nameFor(mchip.modelData, app.lang); color: Theme.textColor; anchors.verticalCenter: parent.verticalCenter; font: Theme.smallFont }
                                    Kirigami.Icon { source: mchip.added ? "checkmark" : "list-add"; width: Units.iconSizes.small; height: width; anchors.verticalCenter: parent.verticalCenter }
                                }
                                MouseArea {
                                    id: mMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: !mchip.added
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var list = app.stations.slice()
                                        var st = Presets.make(mchip.modelData, app.lang)
                                        st.group = app.t("ماسبيرو")
                                        list.push(st)
                                        app.saveStations(list)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            delegate: Item {
                id: cell
                required property var modelData
                readonly property var st: modelData.st
                readonly property bool isCurrent: app.current !== null && app.current.id === st.id && !app.ytMode && !app.previewing
                width: grid.cellWidth; height: grid.cellHeight

                GlassPanel {
                    id: card
                    anchors.fill: parent
                    anchors.margins: Units.smallSpacing
                    radius: 22
                    hovered: cardHover.hovered
                    highlighted: cell.isCurrent && app.wantPlaying
                    accent: cell.st.color
                    scale: cardTap.pressed ? 0.97 : 1
                    Behavior on scale { NumberAnimation { duration: 120 } }

                    HoverHandler { id: cardHover }
                    TapHandler {
                        id: cardTap
                        acceptedButtons: Qt.LeftButton
                        onTapped: cell.isCurrent && app.wantPlaying ? app.toggle() : app.play(cell.st.id)
                        onDoubleTapped: form.openForm(cell.modelData.index)
                    }
                    TapHandler { acceptedButtons: Qt.RightButton; onTapped: cardMenu.popup() }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Units.gridUnit * 0.7
                        spacing: Units.smallSpacing
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            StationLogo {
                                anchors.centerIn: parent
                                width: Math.min(parent.width, parent.height) * 0.86; height: width
                                logo: cell.st.logo || ""
                                tint: cell.st.color
                                glyph: cell.st.glyph || ""
                            }
                            Equalizer {
                                visible: cell.isCurrent && app.isPlaying
                                anchors { right: parent.right; top: parent.top }
                                width: gu * 1.4; height: gu
                                bars: 4
                                color: cell.st.color
                                running: visible && Prefs.animations
                                level: 1
                            }
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            text: cell.st.name
                            color: Theme.textColor
                            horizontalAlignment: Text.AlignHCenter
                            font.weight: cell.isCurrent ? Font.Bold : Font.DemiBold
                            elide: Text.ElideRight
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            text: cell.st.subtitle || cell.st.group || ""
                            visible: text !== ""
                            color: Theme.dimTextColor
                            horizontalAlignment: Text.AlignHCenter
                            font: Theme.smallFont
                            elide: Text.ElideRight
                        }
                    }

                    // hover actions
                    Row {
                        anchors { top: parent.top; right: parent.right; margins: Units.smallSpacing }
                        opacity: cardHover.hovered ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                        QQC2.ToolButton { icon.name: "document-edit"; onClicked: form.openForm(cell.modelData.index); QQC2.ToolTip.text: app.t("تعديل"); QQC2.ToolTip.visible: hovered }
                        QQC2.ToolButton { icon.name: "overflow-menu"; onClicked: cardMenu.popup(); QQC2.ToolTip.text: app.t("المزيد"); QQC2.ToolTip.visible: hovered }
                    }
                    QQC2.Menu {
                        id: cardMenu
                        QQC2.MenuItem { text: app.t("تشغيل"); icon.name: "media-playback-start"; onTriggered: app.play(cell.st.id) }
                        QQC2.MenuItem { text: app.t("تعديل…"); icon.name: "document-edit"; onTriggered: form.openForm(cell.modelData.index) }
                        QQC2.MenuItem { text: app.t("نسخ المحطة"); icon.name: "edit-copy"; onTriggered: form.duplicate(cell.modelData.index) }
                        QQC2.MenuItem { text: app.t("لأعلى"); icon.name: "arrow-up"; enabled: cell.modelData.index > 0; onTriggered: form.move(cell.modelData.index, -1) }
                        QQC2.MenuItem { text: app.t("لأسفل"); icon.name: "arrow-down"; enabled: cell.modelData.index < app.stations.length - 1; onTriggered: form.move(cell.modelData.index, 1) }
                        QQC2.MenuSeparator { }
                        QQC2.MenuItem { text: app.t("حذف"); icon.name: "edit-delete"; onTriggered: form.remove(cell.modelData.index) }
                    }
                }
            }
        }
    }

    Kirigami.PlaceholderMessage {
        anchors.centerIn: parent
        width: parent.width - gu * 4
        visible: view.items.length === 0
        icon.name: view.filter === "local" ? "folder-music" : "network-wireless"
        text: view.filter === "local" ? app.t("أضف ملفاتك الموسيقية") : app.t("لا توجد محطات بعد")
        explanation: view.filter === "local" ? app.t("ملف واحد، أو مجلد كامل، أو قائمة تشغيل M3U/PLS. تُشغَّل بالترتيب أو عشوائيًا.")
                                             : app.t("اكتشف إذاعات العالم من تبويب «اكتشف»، أو أضف رابطًا بنفسك.")
        helpfulAction: Kirigami.Action {
            enabled: view.filter === "radio" && Backend.widgetStationCount > 0
            text: app.t("استيراد محطاتك من ودجت أمواج أورورا") + " (" + Backend.widgetStationCount + ")"
            onTriggered: view.importFromWidget()
        }
    }

    // stations of the Plasma widget (same format), skipping the ones already here
    function importFromWidget() {
        var got = []
        try { got = JSON.parse(Backend.widgetStations()) } catch (e) { }
        var list = app.stations.slice()
        for (var i = 0; i < got.length; i++)
            if (!form.hasUrl(got[i].url)) list.push(got[i])
        app.saveStations(list)
    }

    FileDialog {
        id: importDialog
        title: app.t("استيراد قائمة تشغيل كمحطات")
        nameFilters: [app.t("قوائم تشغيل (*.m3u *.m3u8 *.pls)")]
        onAccepted: form.importPlaylist(selectedFile.toString())
    }
}
