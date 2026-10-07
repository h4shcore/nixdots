import QtQuick

// Plain icon (no ink-centering). Accepts a Nerd Font glyph or a Material icon name, see Icons.qml.
Item {
    id: root

    property string text
    property color color: Look.fg
    property alias font: glyph.font

    readonly property var res: Icons.resolve(text)

    implicitWidth: glyph.implicitWidth
    implicitHeight: glyph.implicitHeight

    Text {
        id: glyph
        anchors.centerIn: parent
        text: root.res.text
        color: root.color
        font.family: root.res.family
        font.pixelSize: 15 * Icons.sizeScale
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
