import QtQuick

Item {
    id: root

    property real value: 0
    property color fill: Look.primary
    readonly property bool pressed: area.pressed
    signal moved(real value)

    implicitWidth: 200
    implicitHeight: 24

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: area.pressed ? 14 : 8
        radius: height / 2
        color: Look.surfaceHiest

        Behavior on height { Anim { duration: Look.dur.fast } }

        Rectangle {
            width: Math.max(parent.height, parent.width * Math.min(1, Math.max(0, root.value)))
            height: parent.height
            radius: height / 2
            color: root.fill

            Behavior on width {
                enabled: !area.pressed
                Anim { duration: 150; curve: Look.standard }
            }
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
}
