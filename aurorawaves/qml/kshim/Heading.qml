import QtQuick
import QtQuick.Controls as QQC2

QQC2.Label {
    property int level: 1
    color: Theme.textColor
    font.weight: Font.DemiBold
    font.pointSize: Theme.defaultFont.pointSize * [1, 1.75, 1.45, 1.22, 1.08, 1.0][Math.max(0, Math.min(5, level))]
}
