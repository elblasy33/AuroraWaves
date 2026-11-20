import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import "kshim" as Kirigami
import "kshim"

// Lyrics of the YouTube Music song that is playing. Synced lyrics follow the song: the current line
// is lit and kept in view; click a line to jump there.
Item {
    id: ly
    property var app
    property real fontScale: 1.0

    property var lines: []
    property bool synced: false
    property string source: ""
    property bool loading: false
    property string loadedFor: ""

    readonly property string songId: app.ytMode && app.ytTrack ? app.ytTrack.id : ""
    // the player reports position once a second: interpolate in between for smooth highlighting
    property real basePos: app.position
    property double baseAt: Date.now()
    property real now: app.position
    onBasePosChanged: baseAt = Date.now()
    Timer {
        interval: 200; repeat: true
        running: ly.visible && ly.synced && ly.app.isPlaying
        onTriggered: ly.now = ly.basePos + (Date.now() - ly.baseAt) / 1000
    }
    readonly property int currentLine: {
        if (!synced) return -1
        var c = -1
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].start <= now + 0.25) c = i
            else break
        }
        return c
    }
    onCurrentLineChanged: if (currentLine >= 0 && !list.moving) list.positionViewAtIndex(currentLine, ListView.Center)

    function load() {
        if (songId === "" || songId === loadedFor) return
        var want = songId
        loadedFor = songId
        lines = []; synced = false; source = ""; loading = true
        app.runYt("lyrics", want, function (r) {
            if (ly.songId !== want) return
            ly.loading = false
            if (r && r.lines) { ly.lines = r.lines; ly.synced = !!r.synced; ly.source = r.source || "" }
        })
    }
    onSongIdChanged: if (visible) load()
    onVisibleChanged: if (visible) load()

    ListView {
        id: list
        anchors.fill: parent
        clip: true
        model: ly.lines
        spacing: Units.smallSpacing * 1.5
        boundsBehavior: Flickable.StopAtBounds
        topMargin: height * 0.3
        bottomMargin: height * 0.3
        QQC2.ScrollBar.vertical: QQC2.ScrollBar { }
        delegate: QQC2.Label {
            required property var modelData
            required property int index
            readonly property bool cur: index === ly.currentLine
            width: list.width - Units.gridUnit
            text: modelData.text === "" ? "♪" : modelData.text
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            color: Theme.textColor
            opacity: !ly.synced ? 0.9 : cur ? 1 : index < ly.currentLine ? 0.4 : 0.6
            font.pointSize: Theme.defaultFont.pointSize * ly.fontScale * (cur ? 1.25 : 1.05)
            font.weight: cur ? Font.Bold : Font.DemiBold
            Behavior on opacity { NumberAnimation { duration: 250 } }
            MouseArea {
                anchors.fill: parent
                enabled: ly.synced && modelData.start >= 0
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: ly.app.seek(modelData.start)
            }
        }
        footer: QQC2.Label {
            width: list.width
            visible: ly.source !== ""
            text: ly.source
            horizontalAlignment: Text.AlignHCenter
            color: Theme.dimTextColor
            font: Theme.smallFont
            topPadding: Units.gridUnit
        }
    }

    QQC2.BusyIndicator { anchors.centerIn: parent; running: ly.loading; visible: running }
    Kirigami.PlaceholderMessage {
        anchors.centerIn: parent
        width: parent.width - Units.gridUnit * 2
        visible: !ly.loading && ly.lines.length === 0
        icon.name: "lyrics"
        text: ly.songId === "" ? ly.app.t("الكلمات متاحة لأغاني يوتيوب ميوزك") : ly.app.t("لا توجد كلمات لهذه الأغنية")
    }
}
