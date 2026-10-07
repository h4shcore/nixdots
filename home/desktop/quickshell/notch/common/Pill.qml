import QtQuick
import QtQuick.Layouts

// Rounded toggle/button with an optional icon.
Rectangle {
    id: root

    property string glyph
    property string text
    property bool selected: false
    property color accent: Look.primary
    signal clicked

    implicitHeight: 38
    implicitWidth: row.implicitWidth + 28
    radius: height / 2
    color: selected ? accent : mouse.containsMouse ? Look.surfaceHiest : Look.surfaceHi
    opacity: enabled ? 1 : 0.4
    scale: mouse.pressed ? 0.95 : 1

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on scale { Anim { duration: Look.dur.fast } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8

        InkIcon {
            visible: root.glyph !== ""
            text: root.glyph
            color: root.selected ? Look.primaryFg : Look.fg
            pixelSize: 14
            box: 20
        }
        Label {
            visible: root.text !== ""
            text: root.text
            color: root.selected ? Look.primaryFg : Look.fg
            font.pixelSize: 13
            font.bold: root.selected
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
