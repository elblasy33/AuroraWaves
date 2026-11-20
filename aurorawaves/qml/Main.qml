import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Window
import "kshim" as Kirigami
import "kshim"

// Aurora Waves — the desktop window.
//   sidebar | page | (queue / lyrics panel)
//   ─────────── now-playing bar ───────────
QQC2.ApplicationWindow {
    id: win

    width: 1240
    height: 800
    minimumWidth: 320
    minimumHeight: 160
    visible: true
    title: (app.ytMode && app.ytTrack ? app.ytTrack.title + " · "
            : app.wantPlaying && app.current ? app.current.name + " · " : "") + Backend.appName
    color: Theme.backgroundColor
    font: Theme.defaultFont

    LayoutMirroring.enabled: app.rtl
    LayoutMirroring.childrenInherit: true

    palette.window: Theme.backgroundColor
    palette.windowText: Theme.textColor
    palette.base: Theme.surfaceColor
    palette.alternateBase: Qt.lighter(Theme.surfaceColor, 1.1)
    palette.text: Theme.textColor
    palette.button: Qt.rgba(Theme.textColor.r, Theme.textColor.g, Theme.textColor.b, 0.08)
    palette.buttonText: Theme.textColor
    palette.highlight: Theme.highlightColor
    palette.highlightedText: "white"
    palette.placeholderText: Theme.dimTextColor
    palette.toolTipBase: Theme.surfaceColor
    palette.toolTipText: Theme.textColor
    palette.light: Qt.rgba(Theme.textColor.r, Theme.textColor.g, Theme.textColor.b, 0.15)
    palette.midlight: Qt.rgba(Theme.textColor.r, Theme.textColor.g, Theme.textColor.b, 0.12)
    palette.mid: Qt.rgba(Theme.textColor.r, Theme.textColor.g, Theme.textColor.b, 0.25)
    palette.dark: Qt.rgba(Theme.textColor.r, Theme.textColor.g, Theme.textColor.b, 0.4)

    property string page: Prefs.lastPage
    property bool trayNoticeShown: false
    // tray menu in the app's language
    function trayLabels() {
        Backend.setTrayLabels([app.wantPlaying ? app.t("إيقاف") : app.t("تشغيل"), app.t("التالي"),
                               app.t("إظهار النافذة"), app.t("خروج")])
    }
    Connections {
        target: app
        function onWantPlayingChanged() { win.trayLabels() }
        function onLangChanged() { win.trayLabels() }
    }
    Component.onCompleted: trayLabels()
    property bool nowOpen: false
    // size modes: wide (sidebar) · compact (icon rail) · narrow (bottom tabs) · mini (player only)
    readonly property bool mini: width < gu * 26 || height < gu * 20
    readonly property bool narrow: !mini && width < gu * 40
    readonly property bool compact: width < 1020
    readonly property real gu: Units.gridUnit
    readonly property string coverUrl: app.ytMode && app.ytTrack ? (app.ytTrack.thumb || "")
                                     : app.previewing ? app.previewLogo
                                     : app.current ? app.logoUrl(app.current.logo) : ""

    function go(key) { page = key; Prefs.lastPage = key; nowOpen = false }
    // a card from the home page: hand it to the YouTube Music page
    function openYt(item) { go("youtube"); ytPage.pick(item) }

    AppState {
        id: app
        expanded: win.visible
        width: 0; height: 0
    }

    // ------------------------------------------------------------- backdrop
    Aurora {
        anchors.fill: parent
        visible: Prefs.auroraEnabled
        color: app.accent
        image: win.coverUrl
        running: win.visible && Prefs.animations
        strength: Prefs.auroraStrength * (app.wantPlaying ? 1.0 : 0.65)
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(Theme.backgroundColor.r, Theme.backgroundColor.g, Theme.backgroundColor.b, 0.35) }
            GradientStop { position: 1; color: Qt.rgba(Theme.backgroundColor.r, Theme.backgroundColor.g, Theme.backgroundColor.b, 0.7) }
        }
    }

    // ------------------------------------------------------------- layout
    MiniPlayer {
        anchors.fill: parent
        visible: win.mini
        app: app
        cover: win.coverUrl
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: win.narrow ? gu * 0.4 : gu * 0.7
        spacing: win.narrow ? gu * 0.4 : gu * 0.7
        visible: !win.mini

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: gu * 0.7

            Sidebar {
                visible: !win.narrow
                Layout.fillHeight: true
                app: app
                current: win.page
                collapsed: win.compact || Prefs.sidebarCollapsed
                onPicked: function (key) { win.go(key) }
            }

            // pages
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                StackLayout {
                    id: pages
                    anchors.fill: parent
                    currentIndex: ["home", "radio", "youtube", "music", "settings"].indexOf(win.page)

                    HomePage {
                        app: app
                        onOpenPage: function (key) { win.go(key) }
                        onOpenYtItem: function (item) { win.openYt(item) }
                    }
                    RadioPage { id: radioPage; app: app; form: form }
                    YTMusicPage { id: ytPage; app: app; showBack: false; visible: win.page === "youtube" }
                    ColumnLayout {
                        spacing: Units.largeSpacing
                        Kirigami.Heading { text: app.t("موسيقاي"); level: 2 }
                        StationsView { Layout.fillWidth: true; Layout.fillHeight: true; app: app; form: form; filter: "local" }
                    }
                    SettingsPage { app: app; onOpenYtAccount: { win.go("youtube"); ytPage.showAccount() } }
                }
            }

            SidePanel {
                Layout.fillHeight: true
                Layout.preferredWidth: gu * 19
                visible: Prefs.showQueuePanel && !win.compact
                app: app
            }
        }

        NowPlayingBar {
            Layout.fillWidth: true
            app: app
            onExpand: win.nowOpen = true
        }

        BottomNav {
            Layout.fillWidth: true
            visible: win.narrow
            app: app
            current: win.page
            onPicked: function (key) { win.go(key) }
        }
    }

    // full-window "now playing" with big cover and lyrics
    NowPlayingView {
        anchors.fill: parent
        app: app
        cover: win.coverUrl
        open: win.nowOpen && !win.mini
        onClose: win.nowOpen = false
    }

    // station add / edit sheet (above everything)
    StationForm {
        id: form
        anchors.fill: parent
        app: app
    }

    // ------------------------------------------------------------- keyboard
    readonly property bool typing: activeFocusItem !== null && activeFocusItem.hasOwnProperty("cursorPosition")
    Shortcut { sequence: "Space"; enabled: !win.typing; onActivated: app.toggle() }
    Shortcut { sequence: "Media Play"; onActivated: app.toggle() }
    Shortcut { sequence: "Ctrl+Right"; onActivated: app.step(1) }
    Shortcut { sequence: "Ctrl+Left"; onActivated: app.step(-1) }
    Shortcut { sequence: "Ctrl+Up"; onActivated: app.setVolume(app.volume + 5) }
    Shortcut { sequence: "Ctrl+Down"; onActivated: app.setVolume(app.volume - 5) }
    Shortcut { sequence: "Ctrl+F"; onActivated: win.go("youtube") }
    Shortcut { sequence: "Ctrl+L"; onActivated: Prefs.showQueuePanel = !Prefs.showQueuePanel }
    Shortcut { sequence: "F11"; onActivated: win.visibility === Window.FullScreen ? win.showNormal() : win.showFullScreen() }
    Shortcut { sequence: "Escape"; enabled: win.nowOpen; onActivated: win.nowOpen = false }
    Shortcut { sequences: [StandardKey.Quit]; onActivated: Qt.quit() }

    // save settings changed in the last moments (the app exits without waiting for timers)
    Connections {
        target: Qt.application
        function onAboutToQuit() { Prefs.save() }
    }

    // ------------------------------------------------------------- tray / single instance
    Connections {
        target: Backend
        function onRaiseRequested() { win.show(); win.raise(); win.requestActivate() }
        function onTrayAction(action) {
            if (action === "toggle") app.toggle()
            else if (action === "next") app.step(1)
            else if (action === "quit") Qt.quit()
            else if (win.visible && win.active) win.hide()
            else { win.show(); win.raise(); win.requestActivate() }
        }
    }
    onClosing: function (close) {
        if (Prefs.keepInTray && Backend.trayAvailable) {
            close.accepted = false
            win.hide()
            if (!win.trayNoticeShown && app.wantPlaying) {
                win.trayNoticeShown = true
                Backend.trayMessage(Backend.appName, app.t("ما زال يعمل في شريط النظام. للإغلاق: أيقونة التطبيق ← خروج."))
            }
        } else {
            Qt.quit()
        }
    }
}
