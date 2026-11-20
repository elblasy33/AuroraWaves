pragma Singleton
import QtQuick

// App settings, saved to ~/.config/aurora-waves/settings.json
QtObject {
    id: prefs

    property string language: "auto"          // auto | ar | en
    property string theme: "dark"              // dark | light | system
    property real glassOpacity: 0.07
    property bool auroraEnabled: true
    property real auroraStrength: 0.6
    property bool animations: true
    property int logoShape: 0                  // squircle | circle | soft square
    property bool useStationAccent: true
    property bool showEqualizer: true
    property bool showStreamInfo: true
    property bool showGroups: true
    property bool keepInTray: false           // closing the window keeps playing in the tray
    property bool resumeOnStart: false
    property bool mprisEnabled: true
    property int volume: 70
    property string lastStation: ""
    property bool sidebarCollapsed: false
    property bool showQueuePanel: false
    property string lastPage: "home"

    readonly property var keys: ["language", "theme", "glassOpacity", "auroraEnabled", "auroraStrength",
        "animations", "logoShape", "useStationAccent", "showEqualizer", "showStreamInfo", "showGroups",
        "keepInTray", "resumeOnStart", "mprisEnabled", "volume", "lastStation", "sidebarCollapsed",
        "showQueuePanel", "lastPage"]
    property bool loaded: false

    function load() {
        var raw = Backend.readConfig("settings.json")
        if (raw) {
            try {
                var o = JSON.parse(raw)
                for (var i = 0; i < keys.length; i++)
                    if (o[keys[i]] !== undefined) prefs[keys[i]] = o[keys[i]]
            } catch (e) { }
        }
        loaded = true
    }
    function save() {
        var o = {}
        for (var i = 0; i < keys.length; i++) o[keys[i]] = prefs[keys[i]]
        Backend.writeConfig("settings.json", JSON.stringify(o, null, 1))
    }

    property Timer saver: Timer { interval: 400; onTriggered: prefs.save() }
    function changed() { if (loaded) saver.restart() }

    onLanguageChanged: changed();       onThemeChanged: changed();          onGlassOpacityChanged: changed()
    onAuroraEnabledChanged: changed();  onAuroraStrengthChanged: changed(); onAnimationsChanged: changed()
    onLogoShapeChanged: changed();      onUseStationAccentChanged: changed(); onShowEqualizerChanged: changed()
    onShowStreamInfoChanged: changed(); onShowGroupsChanged: changed();     onKeepInTrayChanged: changed()
    onResumeOnStartChanged: changed();  onMprisEnabledChanged: changed();   onVolumeChanged: changed()
    onLastStationChanged: changed();    onSidebarCollapsedChanged: changed(); onShowQueuePanelChanged: changed()
    onLastPageChanged: changed()

    Component.onCompleted: load()
}
