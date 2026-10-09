import QtQuick
import QtQuick.Layouts

// One row in a picker list: icon, title, optional subtitle, optional trailing widgets (default children).
Rectangle {
    id: root

    property string glyph
    property string title
    property string subtitle
    property bool active: false
    default property alias trailing: tr.data
    signal clicked

    implicitHeight: 46
    radius: 16
    color: active ? Look.secondaryContainer : mouse.containsMouse ? Look.surfaceHi : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 12
            rightMargin: 10
        }
        spacing: 10

        InkIcon {
            text: root.glyph
            color: root.active ? Look.primary : Look.fg
            pixelSize: 17
            box: 28
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Label {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: 13
                font.bold: root.active
            }
            Label {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.subtitle
                color: Look.fgDim
                font.pixelSize: 11
            }
        }
        RowLayout {
            id: tr
            spacing: 4
        }
    }
}
