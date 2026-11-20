import QtQuick
import QtQuick.Controls as QQC2

// Glass search box with a search icon and a clear button.
QQC2.TextField {
    id: field
    implicitHeight: Math.round(Units.gridUnit * 2.1)
    leftPadding: Units.gridUnit * 2
    rightPadding: text !== "" ? Units.gridUnit * 2 : Units.gridUnit * 0.8
    color: Theme.textColor
    placeholderTextColor: Theme.dimTextColor
    selectByMouse: true
    background: Rectangle {
        radius: height / 2
        color: Qt.rgba(Theme.textColor.r, Theme.textColor.g, Theme.textColor.b, field.activeFocus ? 0.10 : 0.06)
        border.width: 1
        border.color: field.activeFocus ? Qt.rgba(Theme.highlightColor.r, Theme.highlightColor.g, Theme.highlightColor.b, 0.8)
                                        : Qt.rgba(Theme.textColor.r, Theme.textColor.g, Theme.textColor.b, 0.14)
    }
    Icon {
        source: "edit-find"
        width: Units.iconSizes.small; height: width
        anchors.verticalCenter: parent.verticalCenter
        x: field.mirrored ? parent.width - width - Units.gridUnit * 0.7 : Units.gridUnit * 0.7
        color: Theme.dimTextColor
    }
    Icon {
        visible: field.text !== ""
        source: "window-close"
        width: Units.iconSizes.small; height: width
        anchors.verticalCenter: parent.verticalCenter
        x: field.mirrored ? Units.gridUnit * 0.7 : parent.width - width - Units.gridUnit * 0.7
        color: Theme.dimTextColor
        MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: { field.clear(); field.forceActiveFocus() } }
    }
}
