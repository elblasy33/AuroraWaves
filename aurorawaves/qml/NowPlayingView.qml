import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import "kshim" as Kirigami
import "kshim"

// Full-window "now playing": a large cover in the aurora, the controls, and the lyrics beside it.
Item {
    id: np
    property var app
    property string cover: ""
    property bool open: false
    signal close()

    readonly property real gu: Units.gridUnit
    readonly property bool yt: app.ytMode && app.ytTrack !== null
    readonly property bool tracks: app.localPlayback && app.duration > 0 && app.wantPlaying
    readonly property bool wide: width > gu * 50

    visible: opacity > 0
    opacity: open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    Rectangle { anchors.fill: parent; color: Theme.backgroundColor }
    Aurora {
        anchors.fill: parent
        color: np.app.accent
        image: np.cover
        running: np.visible && Prefs.animations
        strength: 1.0
    }
    Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, Theme.dark ? 0.25 : 0.05) }
    MouseArea { anchors.fill: parent }      // keep clicks off the page underneath

    GridLayout {
        anchors.fill: parent
        anchors.margins: gu * 2
        columns: np.wide && np.yt ? 2 : 1
        columnSpacing: gu * 3
        transform: Translate { y: np.open ? 0 : 40; Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } } }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: gu

            Item { Layout.fillHeight: true }
            Item {
                id: coverBox
                Layout.alignment: Qt.AlignHCenter
                readonly property real side: Math.min(np.height * 0.5, (np.wide && np.yt ? np.width * 0.42 : np.width * 0.6))
                Layout.preferredWidth: side
                Layout.preferredHeight: side
                OnAirRing {
                    anchors.centerIn: parent
                    width: parent.width; height: parent.height
                    color: np.app.accent
                    cornerRatio: big.radiusRatio
                    active: np.app.wantPlaying && !np.app.isPaused && Prefs.animations
                    busy: np.app.isBusy
                }
                StationLogo {
                    id: big
                    anchors.centerIn: parent
                    width: parent.width * 0.9; height: width
                    logo: np.yt ? (np.app.ytTrack.thumb || "") : np.app.previewing ? np.app.previewLogo : np.app.current ? (np.app.current.logo || "") : ""
                    tint: np.yt ? "#e53935" : np.app.current ? np.app.current.color : np.app.accent
                    glyph: np.yt ? "♪" : np.app.current ? (np.app.current.glyph || "") : "♪"
                    scale: np.app.isPlaying ? 1 : 0.96
                    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                }
            }
            Kirigami.Heading {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                level: 1
                text: np.yt ? np.app.ytTrack.title : np.app.previewing ? np.app.previewName : np.app.current ? np.app.current.name : ""
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            QQC2.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: np.yt ? [np.app.ytTrack.artist, np.app.ytTrack.album].filter(function (x) { return x && x !== np.app.ytTrack.title }).join("  ·  ")
                    : np.app.trackTitle !== "" ? np.app.trackTitle : np.app.statusText()
                color: Theme.dimTextColor
                font.pointSize: Theme.defaultFont.pointSize * 1.15
                elide: Text.ElideRight
            }
            Equalizer {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: coverBox.side * 0.8
                width: coverBox.side * 0.8
                height: 30
                visible: !np.tracks && Prefs.showEqualizer
                color: np.app.accent
                running: np.visible && np.app.wantPlaying && !np.app.isPaused && Prefs.animations
                level: np.app.isPlaying ? 1 : 0.2
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: coverBox.side * 1.2
                Layout.alignment: Qt.AlignHCenter
                visible: np.tracks
                LayoutMirroring.enabled: false
                LayoutMirroring.childrenInherit: true
                QQC2.Label { text: np.app.fmtTime(seekBig.pressed ? seekBig.value : np.app.position); color: Theme.dimTextColor }
                GlassSlider {
                    id: seekBig
                    Layout.fillWidth: true
                    from: 0; to: Math.max(1, np.app.duration); stepSize: 0
                    value: pressed ? value : np.app.position
                    accent: np.app.accent
                    onPressedChanged: if (!pressed) np.app.seek(value)
                }
                QQC2.Label { text: np.app.fmtTime(np.app.duration); color: Theme.dimTextColor }
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: gu * 1.4
                LayoutMirroring.enabled: false
                GlassButton { iconName: "media-skip-backward"; implicitHeight: gu * 2.8; onClicked: np.app.step(-1) }
                GlassButton {
                    iconName: np.app.isBusy ? "view-refresh"
                            : np.app.isPlaying && (np.tracks || np.yt) ? "media-playback-pause"
                            : np.app.isPlaying ? "media-playback-stop" : "media-playback-start"
                    filled: true
                    accent: np.app.accent
                    implicitWidth: gu * 4; implicitHeight: gu * 4
                    iconScale: 0.5
                    onClicked: np.app.toggle()
                }
                GlassButton { iconName: "media-skip-forward"; implicitHeight: gu * 2.8; onClicked: np.app.step(1) }
            }
            Item { Layout.fillHeight: true }
        }

        // lyrics beside the cover (YouTube Music songs)
        GlassPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumWidth: gu * 30
            visible: np.wide && np.yt
            radius: 28
            tint: 0.05
            LyricsView {
                anchors.fill: parent
                anchors.margins: gu
                app: np.app
                fontScale: 1.25
                visible: np.open && np.wide && np.yt
            }
        }
    }

    GlassButton {
        anchors { top: parent.top; right: parent.right; margins: gu }
        iconName: "minimize-2"
        toolTip: np.app.t("رجوع")
        onClicked: np.close()
    }
}
