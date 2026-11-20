import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import "kshim" as Kirigami
import "kshim"

// Pick one of the bundled icons as a station logo (replaces KDE's icon dialog).
QQC2.Popup {
    id: picker
    signal picked(string name)

    parent: QQC2.Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(parent ? parent.width - 80 : 600, Units.gridUnit * 30)
    height: Math.min(parent ? parent.height - 80 : 500, Units.gridUnit * 26)
    modal: true
    padding: Units.gridUnit
    onOpened: { filter.text = ""; filter.forceActiveFocus() }

    background: Rectangle {
        radius: 22
        color: Theme.surfaceColor
        border.width: 1
        border.color: Qt.rgba(Theme.textColor.r, Theme.textColor.g, Theme.textColor.b, 0.15)
    }
    QQC2.Overlay.modal: Rectangle { color: Qt.rgba(0, 0, 0, 0.5) }

    ColumnLayout {
        anchors.fill: parent
        spacing: Units.largeSpacing
        Kirigami.SearchField {
            id: filter
            Layout.fillWidth: true
        }
        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: Units.gridUnit * 3.4
            cellHeight: cellWidth
            model: Backend.iconNames.filter(function (n) { return n.indexOf(filter.text.trim().toLowerCase()) >= 0 })
            QQC2.ScrollBar.vertical: QQC2.ScrollBar { }
            delegate: Item {
                required property string modelData
                width: grid.cellWidth; height: grid.cellHeight
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 12
                    color: cellMouse.containsMouse ? Qt.rgba(Theme.highlightColor.r, Theme.highlightColor.g, Theme.highlightColor.b, 0.25) : "transparent"
                }
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Units.iconSizes.medium; height: width
                    source: parent.modelData
                }
                MouseArea {
                    id: cellMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    QQC2.ToolTip.text: parent.modelData
                    QQC2.ToolTip.visible: containsMouse
                    onClicked: { picker.picked(parent.modelData); picker.close() }
                }
            }
        }
    }
}
