import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

// Centered empty state: icon, title, explanation and an optional action button.
ColumnLayout {
    id: ph
    property alias text: title.text
    property string explanation: ""
    property IconGroup icon: IconGroup { }
    property QtObject helpfulAction: null
    spacing: Units.largeSpacing

    Icon {
        Layout.alignment: Qt.AlignHCenter
        visible: ph.icon.name !== ""
        source: ph.icon.name
        implicitWidth: Units.iconSizes.huge
        color: Theme.dimTextColor
    }
    QQC2.Label {
        id: title
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: Theme.textColor
        font.pointSize: Theme.defaultFont.pointSize * 1.2
        font.weight: Font.DemiBold
        opacity: 0.85
    }
    QQC2.Label {
        Layout.fillWidth: true
        visible: text !== ""
        text: ph.explanation
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: Theme.dimTextColor
    }
    QQC2.Button {
        Layout.alignment: Qt.AlignHCenter
        visible: ph.helpfulAction !== null && ph.helpfulAction.enabled
        text: ph.helpfulAction ? ph.helpfulAction.text : ""
        onClicked: ph.helpfulAction.trigger()
    }
}
