import QtQuick

// Icon that centers the glyph's *visible shape* in a fixed box (Nerd Font glyphs have uneven
// bearings) and crossfades + springs between glyphs when `text` changes.
Item {
    id: root

    property string text
    property color color: Theme.fg
    property int pixelSize: 18
    property int box: 28
    property string last: ""

    implicitWidth: box
    implicitHeight: box

    component Ink: Item {
        id: ink

        property string text
        property color color: Theme.fg
        property int size: 18
        property int box: 28

        width: box
        height: box
        transformOrigin: Item.Center

        TextMetrics {
            id: tm
            font.family: Theme.font
            font.pixelSize: ink.size
            text: ink.text
        }
        Text {
            text: ink.text
            color: ink.color
            font.family: Theme.font
            font.pixelSize: ink.size
            x: (ink.box - tm.tightBoundingRect.width) / 2 - tm.tightBoundingRect.x
            y: (ink.box - tm.tightBoundingRect.height) / 2 - (tm.ascent + tm.tightBoundingRect.y)
        }
    }

    Ink {
        id: back
        opacity: 0
        color: root.color
        size: root.pixelSize
        box: root.box
    }
    Ink {
        id: front
        text: root.text
        color: root.color
        size: root.pixelSize
        box: root.box
    }

    onTextChanged: {
        back.text = last;
        last = text;
        swap.restart();
    }
    Component.onCompleted: last = text

    ParallelAnimation {
        id: swap
        Anim { target: back; property: "opacity"; from: 1; to: 0; duration: 180; curve: Theme.standard }
        Anim { target: back; property: "scale"; from: 1; to: 0.6; duration: 180; curve: Theme.standard }
        Anim { target: front; property: "opacity"; from: 0; to: 1; duration: 220; curve: Theme.standard }
        Anim { target: front; property: "scale"; from: 0.6; to: 1 }
    }
}
