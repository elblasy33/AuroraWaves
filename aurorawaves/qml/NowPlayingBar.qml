import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import "kshim" as Kirigami
import "kshim"
import "presets.js" as Presets

// Bottom bar: cover + title | transport + progress | volume, lyrics, queue, full screen.
GlassPanel {
    id: bar
    property var app
    signal expand()

    readonly property real gu: Units.gridUnit
    // narrow: title + play controls only, progress as a thin line along the bottom
    readonly property bool narrow: width < gu * 40
    readonly property bool yt: app.ytMode && app.ytTrack !== null
    readonly property bool tracks: app.localPlayback && app.duration > 0 && app.wantPlaying
    readonly property string title: yt ? app.ytTrack.title
                                  : app.previewing ? app.previewName
                                  : app.current ? app.current.name : app.t("أمواج أورورا")
    readonly property string subtitle: yt ? [app.ytTrack.artist, app.ytTrack.album].filter(function (x) { return x && x !== app.ytTrack.title }).join("  ·  ")
                                     : app.isPlaying && app.trackTitle !== "" ? app.trackTitle
                                     : app.statusText()

    implicitHeight: narrow ? gu * 3.8 : gu * 4.6
    radius: 24
    accent: app.accent
    highlighted: app.wantPlaying

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: gu * 0.6
        anchors.rightMargin: gu
        spacing: gu

        // ---- now playing
        Item {
            Layout.preferredWidth: bar.narrow ? -1 : Math.min(bar.width * 0.3, gu * 20)
            Layout.fillWidth: bar.narrow
            Layout.fillHeight: true
            RowLayout {
                anchors.fill: parent
                spacing: gu * 0.7
                Item {
                    Layout.preferredWidth: bar.narrow ? gu * 2.8 : gu * 3.4; Layout.preferredHeight: Layout.preferredWidth
                    OnAirRing {
                        anchors.centerIn: parent
                        width: parent.width; height: parent.height
                        color: bar.app.accent
                        cornerRatio: cover.radiusRatio
                        active: bar.app.wantPlaying && !bar.app.isPaused && Prefs.animations
                        busy: bar.app.isBusy
                    }
                    StationLogo {
                        id: cover
                        anchors.centerIn: parent
                        width: parent.width * 0.86; height: width
                        logo: bar.yt ? (bar.app.ytTrack.thumb || "") : bar.app.previewing ? bar.app.previewLogo : bar.app.current ? (bar.app.current.logo || "") : ""
                        tint: bar.yt ? "#e53935" : bar.app.current ? bar.app.current.color : bar.app.accent
                        glyph: bar.yt ? "♪" : bar.app.current ? (bar.app.current.glyph || "") : "♪"
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: bar.title
                        color: Theme.textColor
                        font.weight: Font.Bold
                        font.pointSize: Theme.defaultFont.pointSize * 1.08
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: bar.subtitle
                        color: bar.app.playState === "error" ? Theme.negativeTextColor : Theme.dimTextColor
                        font: Theme.smallFont
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: bar.expand()
            }
        }

        // ---- transport + progress
        ColumnLayout {
            Layout.fillWidth: !bar.narrow
            spacing: 2
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: gu * 0.8
                LayoutMirroring.enabled: false
                GlassButton {
                    iconName: "media-skip-backward"
                    visible: !bar.narrow || bar.width > gu * 24
                    implicitHeight: bar.narrow ? gu * 1.9 : gu * 2.2
                    toolTip: bar.yt ? bar.app.t("السابق") : bar.app.t("المحطة السابقة")
                    onClicked: bar.app.step(-1)
                }
                GlassButton {
                    iconName: bar.app.isBusy ? "view-refresh"
                            : bar.app.isPlaying && (bar.tracks || bar.yt) ? "media-playback-pause"
                            : bar.app.isPlaying ? "media-playback-stop" : "media-playback-start"
                    filled: true
                    accent: bar.app.accent
                    implicitHeight: bar.narrow ? gu * 2.4 : gu * 2.8
                    implicitWidth: implicitHeight
                    iconScale: 0.55
                    toolTip: bar.app.wantPlaying ? bar.app.t("إيقاف") : bar.app.t("تشغيل")
                    onClicked: bar.app.toggle()
                }
                GlassButton {
                    iconName: "media-skip-forward"
                    implicitHeight: bar.narrow ? gu * 1.9 : gu * 2.2
                    toolTip: bar.yt ? bar.app.t("التالي") : bar.app.t("المحطة التالية")
                    onClicked: bar.app.step(1)
                }
            }
            // progress (songs and files) or a live badge (radio)
            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: gu * 34
                Layout.alignment: Qt.AlignHCenter
                visible: bar.tracks && !bar.narrow
                LayoutMirroring.enabled: false
                LayoutMirroring.childrenInherit: true
                QQC2.Label { text: bar.app.fmtTime(seek.pressed ? seek.value : bar.app.position); color: Theme.dimTextColor; font: Theme.smallFont }
                GlassSlider {
                    id: seek
                    Layout.fillWidth: true
                    from: 0
                    to: Math.max(1, bar.app.duration)
                    stepSize: 0
                    value: pressed ? value : bar.app.position
                    accent: bar.app.accent
                    onMoved: if (!pressed) bar.app.seek(value)
                    onPressedChanged: if (!pressed) bar.app.seek(value)
                }
                QQC2.Label { text: bar.app.fmtTime(bar.app.duration); color: Theme.dimTextColor; font: Theme.smallFont }
            }
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                visible: !bar.tracks && bar.app.isPlaying && !bar.narrow
                implicitWidth: liveRow.implicitWidth + 16
                implicitHeight: liveRow.implicitHeight + 6
                radius: height / 2
                color: Qt.rgba(1, 0.23, 0.19, 0.18)
                border.width: 1
                border.color: Qt.rgba(1, 0.23, 0.19, 0.6)
                Row {
                    id: liveRow
                    anchors.centerIn: parent
                    spacing: 6
                    Rectangle {
                        width: 7; height: 7; radius: 4; color: "#ff3b30"
                        anchors.verticalCenter: parent.verticalCenter
                        SequentialAnimation on opacity {
                            running: bar.app.isPlaying && Prefs.animations; loops: Animation.Infinite
                            NumberAnimation { to: 0.2; duration: 700 }
                            NumberAnimation { to: 1.0; duration: 700 }
                        }
                    }
                    QQC2.Label {
                        text: bar.app.t("مباشر") + (Prefs.showStreamInfo && bar.app.streamInfo !== "" ? "  ·  " + bar.app.streamInfo : "")
                        font.pixelSize: Theme.smallFont.pixelSize > 0 ? Theme.smallFont.pixelSize : 11
                        font.bold: true
                        color: "#ff8a80"
                    }
                }
            }
        }

        // ---- volume + panels
        RowLayout {
            visible: !bar.narrow
            Layout.preferredWidth: Math.min(bar.width * 0.26, gu * 17)
            spacing: gu * 0.4
            Item { Layout.fillWidth: true }
            QQC2.ToolButton {
                icon.name: "lyrics"
                visible: bar.yt
                checkable: true
                checked: Prefs.showQueuePanel
                onClicked: Prefs.showQueuePanel = checked
                QQC2.ToolTip.text: bar.app.t("كلمات الأغنية وقائمة التشغيل")
                QQC2.ToolTip.visible: hovered
            }
            QQC2.ToolButton {
                icon.name: "view-media-playlist"
                visible: !bar.yt
                checkable: true
                checked: Prefs.showQueuePanel
                onClicked: Prefs.showQueuePanel = checked
                QQC2.ToolTip.text: bar.app.t("قائمة التشغيل")
                QQC2.ToolTip.visible: hovered
            }
            Kirigami.Icon {
                source: bar.app.volume === 0 ? "audio-volume-muted" : bar.app.volume < 35 ? "audio-volume-low"
                      : bar.app.volume < 70 ? "audio-volume-medium" : "audio-volume-high"
                implicitWidth: Units.iconSizes.small
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    property int saved: 70
                    onClicked: { if (bar.app.volume > 0) { saved = bar.app.volume; bar.app.setVolume(0) } else bar.app.setVolume(saved) }
                }
            }
            GlassSlider {
                Layout.preferredWidth: gu * 7
                accent: bar.app.accent
                value: bar.app.volume
                onMoved: bar.app.setVolume(value)
            }
            QQC2.ToolButton {
                icon.name: "maximize-2"
                onClicked: bar.expand()
                QQC2.ToolTip.text: bar.app.t("وضع العرض الكامل")
                QQC2.ToolTip.visible: hovered
            }
        }
    }

    // narrow: progress along the bottom edge
    Rectangle {
        visible: bar.narrow && bar.tracks
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: bar.radius; rightMargin: bar.radius; bottomMargin: 3 }
        height: 3; radius: 1.5
        color: Qt.rgba(Theme.textColor.r, Theme.textColor.g, Theme.textColor.b, 0.15)
        LayoutMirroring.enabled: false
        Rectangle {
            height: parent.height; radius: parent.radius
            width: parent.width * Math.min(1, bar.app.position / Math.max(1, bar.app.duration))
            color: bar.app.accent
        }
    }
}
