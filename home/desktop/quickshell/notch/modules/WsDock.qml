import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import qs.common
import qs.services

// Niri workspaces, attached to the top-left corner of the screen border.
// Collapsed: current workspace. Hover: every workspace on this monitor (click to switch, scroll to move).
Item {
    id: root

    required property var screen
    property real screenWidth: 0

    readonly property real e: Look.earRadius
    readonly property real t: Look.border
    readonly property real r: 18

    // this monitor's workspaces, in order
    readonly property var nws: Compositor.workspaces.filter(w => w.output === screen.name).sort((a, b) => a.idx - b.idx)
    readonly property var cur: nws.find(w => w.is_active) ?? null
    readonly property int count: Math.max(1, nws.length)
    readonly property int activeNum: cur?.idx ?? 1

    property bool expanded: false
    property bool shown: false

    Component.onCompleted: shown = true

    // ── geometry ──
    readonly property real collapsedW: head.implicitWidth + Look.pad * 2 + t
    readonly property real detailW: detail.implicitWidth + Look.pad * 2 + t
    property real bodyW: expanded ? Math.max(collapsedW, detailW) : collapsedW
    property real bodyH: Look.pillHeight + (expanded ? 46 : 0)

    Behavior on bodyW { Anim {} }
    Behavior on bodyH { Anim { curve: root.expanded ? Look.spring : Look.emphasized } }

    width: bodyW
    height: bodyH
    x: 0
    y: shown ? 0 : -height - 10

    Behavior on y { Anim { duration: Look.dur.slow } }

    Timer {
        id: collapse
        interval: 300
        onTriggered: root.expanded = false
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered) {
                collapse.stop();
                root.expanded = true;
            } else {
                collapse.restart();
            }
        }
    }

    WheelHandler {
        onWheel: e => Compositor.action([e.angleDelta.y > 0 ? "focus-workspace-up" : "focus-workspace-down"])
    }

    // ── body shape (concave ears into the top + left borders) ──
    Shape {
        width: root.width + root.e
        height: root.height + root.e
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: sp

            readonly property real e: root.e
            readonly property real t: root.t
            readonly property real r: root.r
            readonly property real w: root.width
            readonly property real h: Math.max(root.height, root.t + root.e + root.r)

            fillColor: Look.surface
            strokeWidth: -1

            startX: 0
            startY: 0
            PathLine { x: sp.w + sp.e; y: 0 }
            PathLine { x: sp.w + sp.e; y: sp.t }
            PathArc { x: sp.w; y: sp.t + sp.e; radiusX: sp.e; radiusY: sp.e; direction: PathArc.Counterclockwise }
            PathLine { x: sp.w; y: sp.h - sp.r }
            PathArc { x: sp.w - sp.r; y: sp.h; radiusX: sp.r; radiusY: sp.r }
            PathLine { x: sp.t + sp.e; y: sp.h }
            PathArc { x: sp.t; y: sp.h + sp.e; radiusX: sp.e; radiusY: sp.e; direction: PathArc.Counterclockwise }
            PathLine { x: 0; y: sp.h + sp.e }
            PathLine { x: 0; y: 0 }
        }
    }

    // ── content ──
    Item {
        x: root.t
        width: root.width - root.t
        height: root.height
        clip: true

        RowLayout {
            id: head
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.t
            height: Look.pillHeight - root.t
            spacing: 8

            InkIcon {
                text: "\uf009"
                pixelSize: 13
                box: 20
                color: Look.primary
            }
            Label {
                font.bold: true
                font.pixelSize: 13
                text: (root.expanded ? "Workspace " : "") + (root.cur?.name || root.activeNum)
            }
        }

        RowLayout {
            id: detail
            anchors.horizontalCenter: parent.horizontalCenter
            y: Look.pillHeight
            spacing: 4
            opacity: root.expanded ? 1 : 0
            Behavior on opacity { Anim { duration: 200; curve: Look.standard } }

            Repeater {
                model: root.count

                Rectangle {
                    id: cell

                    required property int index
                    readonly property var nw: root.nws[index] ?? null
                    readonly property bool on: nw?.is_active ?? false
                    readonly property bool occupied: nw?.active_window_id != null

                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 14
                    color: on ? Look.primary : cm.containsMouse ? Look.surfaceHiest : Look.surfaceHi
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Label {
                        anchors.centerIn: parent
                        text: cell.nw ? cell.nw.idx : cell.index + 1
                        font.pixelSize: 12
                        font.bold: cell.on
                        color: cell.on ? Look.primaryFg : (cell.occupied ? Look.fg : Look.fgDim)
                    }
                    MouseArea {
                        id: cm
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Compositor.action(["focus-workspace", String(cell.nw ? cell.nw.idx : cell.index + 1)])
                    }
                }
            }
        }
    }
}
