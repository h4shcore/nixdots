import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string glyph
    property string title
    property string subtitle
    property bool on: false
    signal clicked

    implicitHeight: 52
    radius: 18
    color: on ? Theme.primary : mouse.containsMouse ? Theme.surfaceHiest : Theme.surfaceHi
    scale: mouse.pressed ? 0.95 : 1

    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on scale { Anim { duration: Theme.dur.fast } }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 14
            rightMargin: 12
        }
        spacing: 10

        InkIcon {
            text: root.glyph
            pixelSize: 17
            box: 26
            color: root.on ? Theme.primaryFg : Theme.fg
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Label {
                Layout.fillWidth: true
                text: root.title
                font.bold: true
                font.pixelSize: 12
                color: root.on ? Theme.primaryFg : Theme.fg
            }
            Label {
                Layout.fillWidth: true
                text: root.subtitle
                font.pixelSize: 11
                color: root.on ? Theme.primaryFg : Theme.fgDim
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
