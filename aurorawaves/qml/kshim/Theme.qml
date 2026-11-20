pragma Singleton
import QtQuick

// Colors and fonts. Dark by default (the glass and the aurora shine there); light and system too.
QtObject {
    readonly property bool dark: Prefs.theme === "dark"
                                 || (Prefs.theme === "system" && Qt.styleHints.colorScheme === Qt.ColorScheme.Dark)

    readonly property color backgroundColor: dark ? "#0d0e1c" : "#eef0f7"
    readonly property color surfaceColor: dark ? "#16182b" : "#ffffff"
    readonly property color textColor: dark ? "#f2f3fa" : "#1b1d2c"
    readonly property color dimTextColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.62)
    readonly property color highlightColor: "#e5396b"          // Aurora Waves red-pink
    readonly property color linkColor: dark ? "#ff7aa2" : "#c2185b"
    readonly property color negativeTextColor: dark ? "#ff6b6b" : "#c62828"
    readonly property color positiveTextColor: dark ? "#5ee6a0" : "#2e7d32"
    readonly property color neutralTextColor: dark ? "#ffc861" : "#b26a00"

    readonly property font defaultFont: Qt.application.font
    readonly property font smallFont: Qt.font({ family: defaultFont.family,
                                                pointSize: Math.max(7, defaultFont.pointSize * 0.86) })
}
