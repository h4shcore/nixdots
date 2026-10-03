import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    property string glyph
    property real value: 0
    readonly property bool pressed: slider.pressed
    signal moved(real v)
    signal iconClicked

    spacing: 10

    IconButton {
        size: 32
        glyph: root.glyph
        onClicked: root.iconClicked()
    }
    Slider {
        id: slider
        Layout.fillWidth: true
        value: root.value
        onMoved: v => root.moved(v)
    }
    Label {
        Layout.preferredWidth: 34
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.value * 100) + "%"
        color: Theme.fgDim
    }
}
