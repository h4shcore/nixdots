import QtQuick
import QtQuick.Layouts

// Hoverable pill segment. Children go into a centered RowLayout.
Rectangle {
    id: root

    property bool active: false
    default property alias content: holder.data
    property alias hovered: mouse.containsMouse

    signal clicked(var mouse)
    signal scrolled(var wheel)

    implicitWidth: holder.implicitWidth + 20
    implicitHeight: Look.pillHeight - 10
    radius: height / 2
    color: active ? Look.secondaryContainer : mouse.containsMouse ? Look.surfaceHiest : "transparent"
    scale: mouse.pressed ? 0.94 : 1

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on scale { Anim { duration: Look.dur.fast } }

    RowLayout {
        id: holder
        anchors.centerIn: parent
        spacing: 6
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: m => root.clicked(m)
        onWheel: w => root.scrolled(w)
    }
}
