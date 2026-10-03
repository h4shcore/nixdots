import QtQuick

Rectangle {
    id: root

    property string glyph
    property bool primary: false
    property int size: 36
    signal clicked

    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    color: primary ? Theme.primary : mouse.containsMouse ? Theme.surfaceHiest : "transparent"
    opacity: enabled ? 1 : 0.4
    scale: mouse.pressed ? 0.88 : 1

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on scale { Anim { duration: Theme.dur.fast } }

    Icon {
        anchors.centerIn: parent
        text: root.glyph
        font.pixelSize: root.size * 0.42
        color: root.primary ? Theme.primaryFg : Theme.fg
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
