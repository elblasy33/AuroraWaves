import QtQuick

// A themed icon: a freedesktop / Lucide name (recolored, crisp at any size) or an image URL.
Item {
    id: icon
    property var source: ""
    property color color: Theme.textColor
    property bool isMask: true
    property string fallback: ""
    property bool active: false            // accepted for compatibility

    implicitWidth: Units.iconSizes.smallMedium
    implicitHeight: implicitWidth

    readonly property string name: String(source || "")
    readonly property bool isUrl: /^(file|https?|qrc|image):|^\//.test(name)

    Image {
        id: img
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        asynchronous: false
        smooth: true
        sourceSize: Qt.size(Math.max(16, icon.width * 2), Math.max(16, icon.height * 2))
        source: icon.name === "" ? ""
              : icon.isUrl ? icon.name
              : "image://icons/" + icon.name + "?" + icon.color
        onStatusChanged: if (status === Image.Error && icon.fallback !== "" && !icon.isUrl)
                             source = "image://icons/" + icon.fallback + "?" + icon.color
    }
}
