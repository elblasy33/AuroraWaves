import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import "kshim" as Kirigami
import "kshim"

// World radio: your stations, the world directory, and check & repair.
Item {
    id: page
    property var app
    property var form
    property string tab: "mine"          // mine | discover | health

    ColumnLayout {
        anchors.fill: parent
        spacing: Units.largeSpacing

        Segmented {
            Layout.preferredWidth: Math.min(parent.width, Units.gridUnit * 28)
            accent: app.accent
            current: page.tab
            model: [
                { key: "mine",     text: app.t("محطاتي"),       icon: "network-wireless" },
                { key: "discover", text: app.t("اكتشف العالم"), icon: "globe" },
                { key: "health",   text: app.t("فحص وإصلاح"),   icon: "tools-wizard" }
            ]
            onPicked: function (key) { page.tab = key }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: ["mine", "discover", "health"].indexOf(page.tab)
            StationsView { app: page.app; form: page.form; filter: "radio" }
            DiscoverPage { app: page.app; showBack: false; visible: page.tab === "discover" }
            HealthPage { app: page.app; editor: page.form; showBack: false; visible: page.tab === "health" }
        }
    }
}
