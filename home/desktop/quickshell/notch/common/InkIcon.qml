import QtQuick

// Icon centered in a fixed box. With `ink: true` it measures the glyph's visible shape and centers that
// (Nerd Font glyphs have uneven bearings); with `ink: false` it just centers the text box.
// Crossfades + springs between glyphs when `text` changes.
Item {
    id: root

    property string text
    property color color: Look.fg
    property int pixelSize: 18
    property int box: 28
    property string family: "Symbols Nerd Font Mono"   // falls back to any font that has the glyph
    property bool ink: true
    property string last: ""

    implicitWidth: box
    implicitHeight: box

    component Ink: Item {
        id: it

        property string text
        property color color: Look.fg
        property int size: 18
        property int box: 28
        property string family
        property bool measure: true

        width: box
        height: box
        transformOrigin: Item.Center

        TextMetrics {
            id: tm
            font.family: it.family
            font.pixelSize: it.size
            text: it.text
        }
        Text {
            id: glyph
            text: it.text
            color: it.color
            font.family: it.family
            font.pixelSize: it.size
            x: it.measure ? (it.box - tm.tightBoundingRect.width) / 2 - tm.tightBoundingRect.x
                          : (it.box - width) / 2
            y: it.measure ? (it.box - tm.tightBoundingRect.height) / 2 - (glyph.baselineOffset + tm.tightBoundingRect.y)
                          : (it.box - height) / 2
        }
    }

    Ink {
        id: back
        opacity: 0
        color: root.color
        size: root.pixelSize
        box: root.box
        family: root.family
        measure: root.ink
    }
    Ink {
        id: front
        text: root.text
        color: root.color
        size: root.pixelSize
        box: root.box
        family: root.family
        measure: root.ink
    }

    onTextChanged: {
        back.text = last;
        last = text;
        swap.restart();
    }
    Component.onCompleted: last = text

    ParallelAnimation {
        id: swap
        Anim { target: back; property: "opacity"; from: 1; to: 0; duration: 180; curve: Look.standard }
        Anim { target: back; property: "scale"; from: 1; to: 0.6; duration: 180; curve: Look.standard }
        Anim { target: front; property: "opacity"; from: 0; to: 1; duration: 220; curve: Look.standard }
        Anim { target: front; property: "scale"; from: 0.6; to: 1 }
    }
}
