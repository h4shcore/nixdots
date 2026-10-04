import QtQuick
import Quickshell.Widgets

// Chunky slider with the icon + percentage drawn inside; text flips color over the fill.
Item {
    id: root

    property string glyph
    property real value: 0
    readonly property bool pressed: area.pressed
    signal moved(real v)
    signal iconClicked

    implicitWidth: 300
    implicitHeight: 42

    property real shownFill: width * Math.min(1, Math.max(0, value))
    Behavior on shownFill {
        enabled: !area.pressed
        Anim { duration: 150; curve: Look.standard }
    }

    component Face: Item {
        property string glyph
        property real value: 0
        property color col: Look.fg

        InkIcon {
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            text: parent.glyph
            color: parent.col
            pixelSize: 16
            box: 28
        }
        Label {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(parent.value * 100) + "%"
            color: parent.col
            font.pixelSize: 13
            font.bold: true
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Look.surfaceHi
    }

    Face {
        width: root.width
        height: root.height
        glyph: root.glyph
        value: root.value
        col: Look.fg
    }

    ClippingRectangle {
        width: root.shownFill
        height: parent.height
        radius: height / 2
        color: Look.primary

        Face {
            width: root.width
            height: root.height
            glyph: root.glyph
            value: root.value
            col: Look.primaryFg
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        preventStealing: true
        function update(mx) { root.moved(Math.max(0, Math.min(1, mx / width))); }
        onPressed: m => update(m.x)
        onPositionChanged: m => { if (pressed) update(m.x); }
    }

    // icon zone = click (mute etc.), sits above the drag area
    MouseArea {
        width: 46
        height: parent.height
        onClicked: root.iconClicked()
    }
}
