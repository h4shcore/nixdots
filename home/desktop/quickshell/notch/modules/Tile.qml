import QtQuick
import qs.common

// Bento toggle tile: icon orb top-left, title + status bottom-left.
// Off = flat surface; on = tinted container with a filled primary orb.
Rectangle {
    id: root

    property string glyph
    property string title
    property string subtitle
    property bool on: false
    signal clicked

    implicitHeight: 80
    radius: 22
    color: on ? Look.secondaryContainer : Look.surfaceHi
    scale: mouse.pressed ? 0.96 : 1

    Behavior on color { ColorAnimation { duration: 220 } }
    Behavior on scale { Anim { duration: Look.dur.fast } }

    // hover wash
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Look.fg
        opacity: mouse.containsMouse ? 0.06 : 0
        Behavior on opacity { Anim { duration: 150; curve: Look.standard } }
    }

    Rectangle {
        x: 12
        y: 9
        width: 28
        height: 28
        radius: 14
        color: root.on ? Look.primary : Qt.alpha(Look.fg, 0.1)
        Behavior on color { ColorAnimation { duration: 220 } }

        InkIcon {
            anchors.centerIn: parent
            text: root.glyph
            pixelSize: 14
            box: 28
            color: root.on ? Look.primaryFg : Look.fgDim
        }
    }

    Column {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 14
            rightMargin: 10
            bottomMargin: 10
        }

        Label {
            width: parent.width
            text: root.title
            font.bold: true
            font.pixelSize: 12
        }
        Label {
            width: parent.width
            text: root.subtitle
            font.pixelSize: 11
            color: Look.fgDim
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
