import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import "kshim" as Kirigami
import "kshim"

// The whole window as a small player: a card (tall windows) or a strip (short windows).
// Shown when the window is made very small; enlarge it to get the full app back.
Item {
    id: mini
    property var app
    property string cover: ""

    readonly property real gu: Units.gridUnit
    readonly property bool strip: height < gu * 13 || width > height * 1.6
    readonly property bool yt: app.ytMode && app.ytTrack !== null
    readonly property bool tracks: app.localPlayback && app.duration > 0 && app.wantPlaying
    readonly property string title: yt ? app.ytTrack.title : app.previewing ? app.previewName
                                  : app.current ? app.current.name : app.t("أمواج أورورا")
    readonly property string subtitle: yt ? app.ytTrack.artist
                                     : app.isPlaying && app.trackTitle !== "" ? app.trackTitle : app.statusText()

    component Cover: Item {
        OnAirRing {
            anchors.centerIn: parent
            width: parent.width; height: parent.height
            color: mini.app.accent
            cornerRatio: art.radiusRatio
            active: mini.app.wantPlaying && !mini.app.isPaused && Prefs.animations
            busy: mini.app.isBusy
        }
        StationLogo {
            id: art
            anchors.centerIn: parent
            width: parent.width * 0.86; height: width
            logo: mini.yt ? (mini.app.ytTrack.thumb || "") : mini.app.previewing ? mini.app.previewLogo : mini.app.current ? (mini.app.current.logo || "") : ""
            tint: mini.yt ? "#e53935" : mini.app.current ? mini.app.current.color : mini.app.accent
            glyph: mini.yt ? "♪" : mini.app.current ? (mini.app.current.glyph || "") : "♪"
        }
    }
    component Transport: RowLayout {
        property real size: gu * 2.4
        spacing: size * 0.25
        LayoutMirroring.enabled: false
        GlassButton { iconName: "media-skip-backward"; implicitHeight: size * 0.8; onClicked: mini.app.step(-1) }
        GlassButton {
            iconName: mini.app.isBusy ? "view-refresh"
                    : mini.app.isPlaying && (mini.tracks || mini.yt) ? "media-playback-pause"
                    : mini.app.isPlaying ? "media-playback-stop" : "media-playback-start"
            filled: true; accent: mini.app.accent
            implicitWidth: size; implicitHeight: size
            iconScale: 0.55
            onClicked: mini.app.toggle()
        }
        GlassButton { iconName: "media-skip-forward"; implicitHeight: size * 0.8; onClicked: mini.app.step(1) }
    }

    // ---- strip: cover | title | controls
    RowLayout {
        anchors.fill: parent
        anchors.margins: gu * 0.6
        visible: mini.strip
        spacing: gu * 0.7
        Cover {
            Layout.preferredHeight: Math.min(parent.height, gu * 5)
            Layout.preferredWidth: Layout.preferredHeight
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            QQC2.Label { Layout.fillWidth: true; text: mini.title; color: Theme.textColor; font.weight: Font.Bold; elide: Text.ElideRight; horizontalAlignment: Text.AlignLeft }
            QQC2.Label { Layout.fillWidth: true; text: mini.subtitle; color: Theme.dimTextColor; font: Theme.smallFont; elide: Text.ElideRight; horizontalAlignment: Text.AlignLeft }
            Rectangle {
                Layout.fillWidth: true
                visible: mini.tracks
                implicitHeight: 3; radius: 1.5
                color: Qt.rgba(Theme.textColor.r, Theme.textColor.g, Theme.textColor.b, 0.15)
                LayoutMirroring.enabled: false
                Rectangle { height: parent.height; radius: parent.radius; color: mini.app.accent
                            width: parent.width * Math.min(1, mini.app.position / Math.max(1, mini.app.duration)) }
            }
        }
        Transport { size: Math.min(gu * 2.4, mini.height * 0.45); visible: mini.width > gu * 15 }
        GlassButton {   // very narrow strip: play/pause only
            visible: mini.width <= gu * 15
            iconName: mini.app.isPlaying ? "media-playback-pause" : "media-playback-start"
            filled: true; accent: mini.app.accent
            onClicked: mini.app.toggle()
        }
    }

    // ---- card: big cover, title, progress, controls, volume
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: gu
        visible: !mini.strip
        spacing: gu * 0.6
        Item { Layout.fillHeight: true }
        Cover {
            Layout.alignment: Qt.AlignHCenter
            readonly property real side: Math.min(mini.width - gu * 2, mini.height * 0.45)
            Layout.preferredWidth: side
            Layout.preferredHeight: side
        }
        QQC2.Label { Layout.fillWidth: true; text: mini.title; color: Theme.textColor; font.weight: Font.Bold; font.pointSize: Theme.defaultFont.pointSize * 1.15; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter }
        QQC2.Label { Layout.fillWidth: true; text: mini.subtitle; color: Theme.dimTextColor; font: Theme.smallFont; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter }
        GlassSlider {
            Layout.fillWidth: true
            visible: mini.tracks
            from: 0; to: Math.max(1, mini.app.duration); stepSize: 0
            value: pressed ? value : mini.app.position
            accent: mini.app.accent
            onPressedChanged: if (!pressed) mini.app.seek(value)
        }
        Transport { Layout.alignment: Qt.AlignHCenter }
        RowLayout {
            Layout.fillWidth: true
            Kirigami.Icon { source: mini.app.volume === 0 ? "audio-volume-muted" : "audio-volume-high"; implicitWidth: Units.iconSizes.small }
            GlassSlider { Layout.fillWidth: true; accent: mini.app.accent; value: mini.app.volume; onMoved: mini.app.setVolume(value) }
        }
        Item { Layout.fillHeight: true }
    }
}
