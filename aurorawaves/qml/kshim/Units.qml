pragma Singleton
import QtQuick

QtObject {
    readonly property real gridUnit: Math.round(fontMetrics.height)
    readonly property real smallSpacing: Math.round(gridUnit / 4)
    readonly property real largeSpacing: smallSpacing * 2
    readonly property QtObject iconSizes: QtObject {
        readonly property int small: 16
        readonly property int smallMedium: 22
        readonly property int medium: 32
        readonly property int large: 48
        readonly property int huge: 64
    }
    property FontMetrics fontMetrics: FontMetrics { font: Theme.defaultFont }
}
