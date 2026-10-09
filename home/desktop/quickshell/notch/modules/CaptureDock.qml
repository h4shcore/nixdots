import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import qs.common
import qs.services

// Screenshot / recording control panel growing out of the bottom border.
// S / R pick screenshot / record · 1 2 3 pick region / window / screen · Enter go · Esc close
Item {
    id: root

    required property real screenWidth
    required property real screenHeight
    property bool active: true

    readonly property bool open: LauncherState.open && LauncherState.mode === "cap" && active

    readonly property real e: Look.earRadius
    readonly property real t: Look.border
    readonly property real r: 28

    readonly property real targetW: 600
    readonly property real targetH: 16 + col.implicitHeight + 16 + t

    property real bodyW: open ? targetW : 240
    property real bodyH: open ? targetH : 0
    Behavior on bodyW { Anim {} }
    Behavior on bodyH {
        Anim {
            duration: root.settled ? 140 : Look.dur.normal
            curve: root.settled ? Look.standard : (root.open ? Look.spring : Look.emphasized)
        }
    }

    property bool settled: false
    Timer {
        id: settleTimer
        interval: 450
        onTriggered: root.settled = true
    }

    onOpenChanged: {
        settled = false;
        settleTimer.restart();
        if (open) focusTimer.restart();
    }
    Timer {
        id: focusTimer
        interval: 60
        onTriggered: keys.forceActiveFocus()
    }

    width: bodyW
    height: bodyH
    x: (screenWidth - width) / 2
    y: screenHeight - height
    visible: height > 1

    // ── body shape: rounded top, concave ears into the bottom border ──
    Shape {
        x: -root.e
        width: root.width + root.e * 2
        height: root.height
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: sp

            readonly property real e: root.e
            readonly property real t: root.t
            readonly property real r: root.r
            readonly property real w: root.width
            readonly property real h: Math.max(root.height, root.r + root.t + root.e)

            fillColor: Look.surface
            strokeWidth: -1

            // shape-local x = root-local x + e
            startX: 0
            startY: sp.h
            PathLine { x: 0; y: sp.h - sp.t }
            PathArc { x: sp.e; y: sp.h - sp.t - sp.e; radiusX: sp.e; radiusY: sp.e; direction: PathArc.Counterclockwise }
            PathLine { x: sp.e; y: sp.r }
            PathArc { x: sp.e + sp.r; y: 0; radiusX: sp.r; radiusY: sp.r }
            PathLine { x: sp.e + sp.w - sp.r; y: 0 }
            PathArc { x: sp.e + sp.w; y: sp.r; radiusX: sp.r; radiusY: sp.r }
            PathLine { x: sp.e + sp.w; y: sp.h - sp.t - sp.e }
            PathArc { x: sp.e + sp.w + sp.e; y: sp.h - sp.t; radiusX: sp.e; radiusY: sp.e; direction: PathArc.Counterclockwise }
            PathLine { x: sp.w + 2 * sp.e; y: sp.h }
            PathLine { x: 0; y: sp.h }
        }
    }

    // ── content ──
    Item {
        width: root.width
        height: root.height - root.t
        clip: true

        Item {
            id: keys
            focus: true
            Keys.onPressed: ev => {
                if (ev.key === Qt.Key_S) Capture.kind = "shot";
                else if (ev.key === Qt.Key_R) Capture.kind = "record";
                else if (ev.key === Qt.Key_1) Capture.target = "region";
                else if (ev.key === Qt.Key_2) Capture.target = "window";
                else if (ev.key === Qt.Key_3) Capture.target = "screen";
                else if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) Capture.go();
                else if (ev.key === Qt.Key_Escape) LauncherState.hide();
                else return;
                ev.accepted = true;
            }
        }

        ColumnLayout {
            id: col
            x: 16
            y: 16
            width: parent.width - 32
            spacing: 10

            // kind
            Reveal {
                Layout.fillWidth: true
                shown: root.open
                delay: 20

                RowLayout {
                    width: parent.width
                    spacing: 8

                    Pill {
                        glyph: "\uf030"
                        text: "Screenshot"
                        selected: Capture.kind === "shot"
                        onClicked: Capture.kind = "shot"
                    }
                    Pill {
                        glyph: "\uf03d"
                        text: "Record"
                        selected: Capture.kind === "record"
                        onClicked: Capture.kind = "record"
                    }
                    Item { Layout.fillWidth: true }
                    Label {
                        visible: Capture.recording
                        text: "● Recording  " + Capture.fmt(Capture.elapsed)
                        color: Look.error
                        font.bold: true
                        font.pixelSize: 12
                    }
                }
            }

            // area
            Reveal {
                Layout.fillWidth: true
                shown: root.open
                delay: 60

                RowLayout {
                    width: parent.width
                    spacing: 8

                    Label {
                        Layout.preferredWidth: 46
                        text: "Area"
                        color: Look.fgDim
                        font.pixelSize: 12
                    }
                    Pill {
                        glyph: "\uf125"
                        text: "Region"
                        selected: Capture.target === "region"
                        onClicked: Capture.target = "region"
                    }
                    Pill {
                        glyph: "\uf2d0"
                        text: "Window"
                        selected: Capture.target === "window"
                        onClicked: Capture.target = "window"
                    }
                    Pill {
                        glyph: "\uf108"
                        text: "Screen"
                        selected: Capture.target === "screen"
                        onClicked: Capture.target = "screen"
                    }
                    Item { Layout.fillWidth: true }
                }
            }

            // delay + audio + go
            Reveal {
                Layout.fillWidth: true
                shown: root.open
                delay: 100

                RowLayout {
                    width: parent.width
                    spacing: 8

                    Label {
                        Layout.preferredWidth: 46
                        text: "Delay"
                        color: Look.fgDim
                        font.pixelSize: 12
                    }
                    Repeater {
                        model: [0, 3, 5, 10]

                        Pill {
                            required property int modelData
                            text: modelData === 0 ? "Now" : modelData + "s"
                            selected: Capture.delay === modelData
                            onClicked: Capture.delay = modelData
                        }
                    }
                    Pill {
                        visible: Capture.kind === "record"
                        glyph: "\uf130"
                        text: "Audio"
                        selected: Capture.audio
                        onClicked: Capture.audio = !Capture.audio
                    }
                    Item { Layout.fillWidth: true }
                    Pill {
                        selected: true
                        accent: Capture.kind === "record" && Capture.recording ? Look.error : Look.primary
                        glyph: Capture.kind === "shot" ? "\uf030" : (Capture.recording ? "\uf04d" : "\uf111")
                        text: Capture.kind === "shot" ? "Capture" : (Capture.recording ? "Stop" : "Record")
                        onClicked: Capture.go()
                    }
                }
            }

            // missing-dependency hint
            Reveal {
                Layout.fillWidth: true
                visible: (Capture.kind === "shot" && !Capture.hasGrim) || (Capture.kind === "record" && !Capture.hasRec)
                shown: root.open
                delay: 140

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    color: Look.error
                    font.pixelSize: 11
                    text: Capture.kind === "shot" ? "grim not found — install grim + wl-clipboard" : "wl-screenrec not found — install wl-screenrec"
                }
            }
        }
    }
}
