import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import "kshim" as Kirigami
import "kshim"

// Settings: language and look, playback and window, YouTube Music, about.
Item {
    id: page
    property var app
    signal openYtAccount()

    readonly property real gu: Units.gridUnit

    component Section: GlassPanel {
        id: sec
        property string title
        property string icon
        default property alias rows: body.data
        Layout.fillWidth: true
        implicitHeight: body.implicitHeight + head.implicitHeight + gu * 2
        radius: 22
        RowLayout {
            id: head
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: gu }
            Kirigami.Icon { source: sec.icon; implicitWidth: Units.iconSizes.smallMedium; color: page.app.accent }
            Kirigami.Heading { text: sec.title; level: 3; Layout.fillWidth: true }
        }
        ColumnLayout {
            id: body
            anchors { left: parent.left; right: parent.right; top: head.bottom; margins: gu; topMargin: gu * 0.6 }
            spacing: gu * 0.6
        }
    }
    component Row2: RowLayout {
        property alias label: lbl.text
        property string hint: ""
        Layout.fillWidth: true
        spacing: gu
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            QQC2.Label { id: lbl; Layout.fillWidth: true; color: Theme.textColor; wrapMode: Text.WordWrap }
            QQC2.Label { Layout.fillWidth: true; visible: parent.parent.hint !== ""; text: parent.parent.hint; color: Theme.dimTextColor; font: Theme.smallFont; wrapMode: Text.WordWrap }
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
            width: Math.min(parent.width - gu, gu * 44)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: gu

            Kirigami.Heading { text: page.app.t("الإعدادات"); level: 1 }

            Section {
                title: page.app.t("اللغة والمظهر")
                icon: "shapes"
                Row2 {
                    label: page.app.t("اللغة")
                    Segmented {
                        Layout.preferredWidth: gu * 16
                        accent: page.app.accent
                        current: Prefs.language
                        model: [{ key: "auto", text: page.app.t("تلقائي"), icon: "" },
                                { key: "ar", text: "العربية", icon: "" },
                                { key: "en", text: "English", icon: "" }]
                        onPicked: function (k) { Prefs.language = k }
                    }
                }
                Row2 {
                    label: page.app.t("السمة")
                    hint: page.app.t("ألوان الأيقونات تتحدّث بعد إعادة تشغيل التطبيق")
                    Segmented {
                        Layout.preferredWidth: gu * 16
                        accent: page.app.accent
                        current: Prefs.theme
                        model: [{ key: "dark", text: page.app.t("داكن"), icon: "moon" },
                                { key: "light", text: page.app.t("فاتح"), icon: "sun" },
                                { key: "system", text: page.app.t("النظام"), icon: "" }]
                        onPicked: function (k) { Prefs.theme = k }
                    }
                }
                Row2 {
                    label: page.app.t("شفافية الزجاج")
                    GlassSlider { Layout.preferredWidth: gu * 12; from: 0; to: 30; value: Prefs.glassOpacity * 100; accent: page.app.accent; onMoved: Prefs.glassOpacity = value / 100 }
                }
                Row2 {
                    label: page.app.t("خلفية الأورورا المتحركة")
                    GlassSwitch { accent: page.app.accent; checked: Prefs.auroraEnabled; onToggled: Prefs.auroraEnabled = checked }
                }
                Row2 {
                    label: page.app.t("قوة الأورورا")
                    enabled: Prefs.auroraEnabled
                    GlassSlider { Layout.preferredWidth: gu * 12; from: 10; to: 100; value: Prefs.auroraStrength * 100; accent: page.app.accent; onMoved: Prefs.auroraStrength = value / 100 }
                }
                Row2 {
                    label: page.app.t("لون المحطة كلون رئيسي")
                    GlassSwitch { accent: page.app.accent; checked: Prefs.useStationAccent; onToggled: Prefs.useStationAccent = checked }
                }
                Row2 {
                    label: page.app.t("الحركات")
                    GlassSwitch { accent: page.app.accent; checked: Prefs.animations; onToggled: Prefs.animations = checked }
                }
                Row2 {
                    label: page.app.t("شكل اللوجو")
                    Segmented {
                        Layout.preferredWidth: gu * 16
                        accent: page.app.accent
                        current: String(Prefs.logoShape)
                        model: [{ key: "0", text: page.app.t("مستدير"), icon: "" },
                                { key: "1", text: page.app.t("دائري"), icon: "" },
                                { key: "2", text: page.app.t("مربع"), icon: "" }]
                        onPicked: function (k) { Prefs.logoShape = parseInt(k) }
                    }
                }
            }

            Section {
                title: page.app.t("التشغيل والنافذة")
                icon: "media-playback-start"
                Row2 {
                    label: page.app.t("الإبقاء في شريط النظام عند الإغلاق")
                    hint: Backend.trayAvailable ? "" : page.app.t("شريط النظام غير متاح في سطح المكتب الحالي")
                    GlassSwitch { accent: page.app.accent; enabled: Backend.trayAvailable; checked: Prefs.keepInTray; onToggled: Prefs.keepInTray = checked }
                }
                Row2 {
                    label: page.app.t("تشغيل آخر محطة عند فتح التطبيق")
                    GlassSwitch { accent: page.app.accent; checked: Prefs.resumeOnStart; onToggled: Prefs.resumeOnStart = checked }
                }
                Row2 {
                    label: page.app.t("التحكم من متحكم الوسائط وأزرار الميديا (MPRIS)")
                    GlassSwitch { accent: page.app.accent; checked: Prefs.mprisEnabled; onToggled: Prefs.mprisEnabled = checked }
                }
                Row2 {
                    label: page.app.t("معلومات البث (الترميز ومعدل البت)")
                    GlassSwitch { accent: page.app.accent; checked: Prefs.showStreamInfo; onToggled: Prefs.showStreamInfo = checked }
                }
            }

            Section {
                title: page.app.t("يوتيوب ميوزك")
                icon: "music-note-16th"
                Row2 {
                    label: page.app.ytStatus.ready ? page.app.t("مفعّل") + "  ·  yt-dlp " + (page.app.ytStatus.ytdlp || "")
                                                   : page.app.t("غير مفعّل")
                    GlassButton {
                        visible: !page.app.ytStatus.ready
                        text: page.app.ytSetupBusy ? page.app.t("جاري التفعيل…") : page.app.t("تفعيل")
                        enabled: !page.app.ytSetupBusy
                        filled: true; accent: "#e53935"
                        onClicked: page.app.ytSetup()
                    }
                }
                Row2 {
                    label: page.app.ytStatus.signedIn ? page.app.t("الحساب: ") + (page.app.ytStatus.account.name || "")
                                                      : page.app.t("غير مسجّل الدخول (اختياري)")
                    GlassButton {
                        text: page.app.ytStatus.signedIn ? page.app.t("الحساب") : page.app.t("تسجيل الدخول")
                        iconName: "user"
                        enabled: page.app.ytStatus.ready
                        onClicked: page.openYtAccount()
                    }
                }
            }

            Section {
                title: page.app.t("حول")
                icon: "info"
                QQC2.Label {
                    Layout.fillWidth: true
                    color: Theme.textColor
                    wrapMode: Text.WordWrap
                    text: Backend.appName + "  " + Backend.version + "\n" + page.app.t("إذاعات العالم ويوتيوب ميوزك وموسيقاك في مشغّل زجاجي واحد.")
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    color: Theme.dimTextColor
                    font: Theme.smallFont
                    wrapMode: Text.WordWrap
                    text: "GPL-2.0-or-later · Radio Browser · zeno.fm · ytmusicapi · yt-dlp · mpv · Lucide icons (ISC)\n"
                          + page.app.t("غير تابع لجوجل أو يوتيوب.")
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: gu * 0.5
                    GlassButton { text: "GitHub"; iconName: "link"; onClicked: Backend.openUrl("https://github.com/elblasy33/AuroraWaves") }
                    GlassButton { text: page.app.t("الإبلاغ عن مشكلة"); iconName: "dialog-warning"; onClicked: Backend.openUrl("https://github.com/elblasy33/AuroraWaves/issues") }
                }
            }
        }
    }
}
