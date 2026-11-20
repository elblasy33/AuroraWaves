import QtQuick
import QtQuick.Controls as QQC2
import "kshim"

// On/off switch in the glass style (accent track, white knob).
QQC2.Switch {
    id: sw
    property color accent: Theme.highlightColor
    padding: 0
    implicitWidth: indicator.implicitWidth
    implicitHeight: indicator.implicitHeight
    indicator: Rectangle {
        implicitWidth: 44
        implicitHeight: 24
        x: sw.mirrored ? sw.width - width : 0
        y: (sw.height - height) / 2
        radius: height / 2
        color: sw.checked ? sw.accent : Qt.rgba(Theme.textColor.r, Theme.textColor.g, Theme.textColor.b, 0.16)
        border.width: 1
        border.color: sw.checked ? Qt.lighter(sw.accent, 1.3) : Qt.rgba(Theme.textColor.r, Theme.textColor.g, Theme.textColor.b, 0.2)
        opacity: sw.enabled ? 1 : 0.45
        Behavior on color { ColorAnimation { duration: 150 } }
        Rectangle {
            width: 18; height: 18; radius: 9
            y: 3
            x: (sw.checked !== sw.mirrored) ? parent.width - width - 3 : 3
            color: "white"
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
    }
    contentItem: Item { }
}
