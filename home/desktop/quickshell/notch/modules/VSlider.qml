import QtQuick
import qs.common
import Quickshell.Widgets

// Tall pill slider: fills from the bottom, icon at the bottom, value at the top.
// Face colors flip over the fill (same trick as FatSlider).
Item {
    id: root

    property string glyph
    property real value: 0
    property color fill: Look.primary
    property color fillFg: Look.primaryFg
    property bool readOnly: false
    readonly property bool pressed: area.pressed
    signal moved(real v)
    signal iconClicked

    implicitWidth: 54
    implicitHeight: 170

    property real shownFill: height * Math.min(1, Math.max(0, value))
    Behavior on shownFill {
        enabled: !area.pressed
        Anim { duration: 150; curve: Look.standard }
    }

    component Face: Item {
        property string glyph
        property real value: 0
        property color col: Look.fg

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 13
            text: Math.round(parent.value * 100)
            color: parent.col
            font.pixelSize: 11
            font.bold: true
        }
        InkIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - height - 10
            text: parent.glyph
            color: parent.col
            pixelSize: 17
            box: 30
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Look.surfaceHi
    }

    Face {
        width: root.width
        height: root.height
        glyph: root.glyph
        value: root.value
        col: Look.fgDim
    }

    ClippingRectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: root.shownFill
        radius: width / 2
        color: root.fill

        Face {
            anchors.bottom: parent.bottom
            width: root.width
            height: root.height
            glyph: root.glyph
            value: root.value
            col: root.fillFg
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: !root.readOnly
        preventStealing: true
        function update(my) { root.moved(Math.max(0, Math.min(1, 1 - my / height))); }
        onPressed: m => update(m.y)
        onPositionChanged: m => { if (pressed) update(m.y); }
    }

    // icon zone = click (mute etc.), sits above the drag area
    MouseArea {
        enabled: !root.readOnly
        anchors.bottom: parent.bottom
        width: parent.width
        height: 50
        onClicked: root.iconClicked()
    }
}
