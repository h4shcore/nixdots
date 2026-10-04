import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets
import qs.common
import qs.services

// Volume / brightness OSD hanging off the right border at the vertical center.
// A tall fat slider (percent on top, icon at the bottom, both inside the bar).
Item {
    id: root

    required property real screenWidth
    required property real screenHeight
    property bool active: true

    property bool flash: false
    property bool armed: false          // ignore the initial values loading in at startup
    property string kind: "volume"      // volume | brightness
    readonly property bool shown: active && flash

    readonly property real e: Look.earRadius
    readonly property real t: Look.border
    readonly property real r: 26
    readonly property real value: kind === "volume" ? (Audio.muted ? 0 : Audio.volume) : Brightness.value
    readonly property string glyph: kind === "volume" ? Audio.glyph : "\uf185"

    function trigger(k) {
        if (!armed) return;
        kind = k;
        flash = true;
        hideTimer.restart();
    }

    Timer {
        interval: 2000
        running: true
        onTriggered: root.armed = true
    }
    Timer {
        id: hideTimer
        interval: 1600
        onTriggered: root.flash = false
    }

    Connections {
        target: Audio
        function onVolumeChanged() { root.trigger("volume"); }
        function onMutedChanged() { root.trigger("volume"); }
    }
    Connections {
        target: Brightness
        function onValueChanged() { root.trigger("brightness"); }
    }

    property real slide: shown ? 0 : width + e + 20
    Behavior on slide { Anim { duration: Look.dur.slow; curve: root.shown ? Look.spring : Look.emphasized } }

    width: 64 + t
    height: 204
    x: screenWidth - width + slide
    y: (screenHeight - height) / 2

    // body with concave ears into the right border (above + below)
    Shape {
        y: -root.e
        width: root.width
        height: root.height + root.e * 2
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: sp

            readonly property real e: root.e
            readonly property real t: root.t
            readonly property real r: root.r
            readonly property real w: root.width
            readonly property real h: root.height

            fillColor: Look.surface
            strokeWidth: -1

            // shape-local y = root-local y + e
            startX: sp.w
            startY: 0
            PathLine { x: sp.w - sp.t; y: 0 }
            PathArc { x: sp.w - sp.t - sp.e; y: sp.e; radiusX: sp.e; radiusY: sp.e }
            PathLine { x: sp.r; y: sp.e }
            PathArc { x: 0; y: sp.e + sp.r; radiusX: sp.r; radiusY: sp.r; direction: PathArc.Counterclockwise }
            PathLine { x: 0; y: sp.e + sp.h - sp.r }
            PathArc { x: sp.r; y: sp.e + sp.h; radiusX: sp.r; radiusY: sp.r; direction: PathArc.Counterclockwise }
            PathLine { x: sp.w - sp.t - sp.e; y: sp.e + sp.h }
            PathArc { x: sp.w - sp.t; y: sp.e + sp.h + sp.e; radiusX: sp.e; radiusY: sp.e }
            PathLine { x: sp.w; y: sp.e + sp.h + sp.e }
            PathLine { x: sp.w; y: 0 }
        }
    }

    component Face: Item {
        property string glyph
        property real value: 0
        property color col: Look.fg

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 15
            text: Math.round(parent.value * 100)
            color: parent.col
            font.pixelSize: 14
            font.bold: true
        }
        InkIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            text: parent.glyph
            color: parent.col
            pixelSize: 18
            box: 30
        }
    }

    Rectangle {
        id: bar
        x: 10
        y: 12
        width: root.width - root.t - 20
        height: root.height - 24
        radius: width / 2
        color: Look.surfaceHi

        Face {
            anchors.fill: parent
            glyph: root.glyph
            value: root.value
            col: Look.fg
        }

        ClippingRectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: parent.height * Math.min(1, Math.max(0, root.value))
            radius: width / 2
            color: Look.primary
            Behavior on height { Anim { duration: 150; curve: Look.standard } }

            Face {
                anchors.bottom: parent.bottom
                width: bar.width
                height: bar.height
                glyph: root.glyph
                value: root.value
                col: Look.primaryFg
            }
        }
    }
}
