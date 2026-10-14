import QtQuick
import QtQuick.Shapes
import qs.common

// Wavy progress slider: the played part is a flowing sine wave that calms to a straight line
// when paused or while you drag; a pill thumb marks the position. Click/drag to seek.
Item {
    id: root

    property real value: 0
    property bool playing: false
    property color fill: Look.primary
    property color track: Look.surfaceHiest
    readonly property bool pressed: area.pressed
    signal moved(real v)

    implicitWidth: 200
    implicitHeight: 22
    opacity: enabled ? 1 : 0.5

    readonly property real pad: 6
    readonly property real wavelength: 24

    // wave motion
    property real phase: 0
    NumberAnimation on phase {
        running: root.visible && root.playing
        from: 0
        to: Math.PI * 2
        duration: 1500
        loops: Animation.Infinite
    }
    property real amplitude: root.playing && !area.pressed ? 3 : 0
    Behavior on amplitude { Anim { duration: 450; curve: Look.standard } }

    // position: glides between 1s MPRIS ticks, snaps quickly on seeks
    property real shown: value
    Behavior on shown {
        enabled: !area.pressed
        NumberAnimation {
            duration: Math.abs(root.value - root.shown) < 0.03 ? 1000 : 250
            easing.type: Math.abs(root.value - root.shown) < 0.03 ? Easing.Linear : Easing.OutCubic
        }
    }
    readonly property real thumbX: pad + (width - pad * 2) * Math.min(1, Math.max(0, shown))

    function buildWave(ph, a, tx, h) {
        const pts = [];
        const cy = h / 2;
        const end = Math.max(2, tx - 4);
        for (let x = 2; x < end; x += 3) {
            const env = Math.min(1, (x - 2) / 14) * Math.min(1, (tx - x) / 18);
            pts.push(Qt.point(x, cy + a * env * Math.sin(x * 2 * Math.PI / wavelength - ph)));
        }
        pts.push(Qt.point(end, cy));
        if (pts.length < 2) pts.unshift(Qt.point(2, cy));
        return pts;
    }
    property var wave: buildWave(phase, amplitude, thumbX, height)

    // remaining track
    Rectangle {
        x: root.thumbX + 8
        width: Math.max(0, root.width - x - 1)
        anchors.verticalCenter: parent.verticalCenter
        height: 3
        radius: 1.5
        color: root.track
    }

    // played wave
    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            strokeColor: root.fill
            strokeWidth: 3.5
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathPolyline { path: root.wave }
        }
    }

    // thumb
    Rectangle {
        x: root.thumbX - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: area.pressed ? 6 : 4
        height: area.pressed ? 22 : 18
        radius: width / 2
        color: root.fill

        Behavior on width { Anim { duration: Look.dur.fast } }
        Behavior on height { Anim { duration: Look.dur.fast } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        preventStealing: true
        function update(mx) { root.moved(Math.max(0, Math.min(1, (mx - root.pad) / (root.width - root.pad * 2)))); }
        onPressed: m => update(m.x)
        onPositionChanged: m => { if (pressed) update(m.x); }
    }
}
