import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import qs.common

// Workspace indicator attached to the top-left corner of the screen border.
// Collapsed: current workspace (or open special workspace). Hover: shows all of them.
Item {
    id: root

    required property var screen
    property real screenWidth: 0

    readonly property real e: Look.earRadius
    readonly property real t: Look.border
    readonly property real r: 18

    readonly property var mon: Hyprland.monitorFor(screen)
    readonly property int activeId: mon?.activeWorkspace?.id ?? 1
    readonly property int page: Math.floor((Math.max(1, activeId) - 1) / 5) * 5 + 1
    property string special: ""      // open special workspace, without the "special:" prefix
    property bool expanded: false
    property bool shown: false

    readonly property var specials: [
        { name: "magic", glyph: "\uf0d0", label: "Magic" },
        { name: "chat", glyph: "\uf086", label: "Chat" },
        { name: "music", glyph: "\uf001", label: "Music" }
    ]

    function specialInfo(name) {
        for (let i = 0; i < specials.length; i++)
            if (specials[i].name === name) return specials[i];
        return { name: name, glyph: "\uf005", label: name.charAt(0).toUpperCase() + name.slice(1) };
    }

    function hasWs(id) {
        const v = Hyprland.workspaces.values;
        for (let i = 0; i < v.length; i++)
            if (v[i].id === id) return true;
        return false;
    }

    function hasSpecial(name) {
        const v = Hyprland.workspaces.values;
        for (let i = 0; i < v.length; i++)
            if (v[i].name === "special:" + name) return true;
        return false;
    }

    Component.onCompleted: {
        shown = true;
        special = (mon?.lastIpcObject?.specialWorkspace?.name ?? "").replace(/^special:/, "");
    }

    // activespecial>>special:NAME,MONITOR  (NAME empty when it closes)
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activespecial") return;
            const d = event.data.split(",");
            if (d[1] !== root.screen.name) return;
            root.special = d[0].replace(/^special:/, "");
        }
    }

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
        onWheel: e => Hyprland.dispatch(e.angleDelta.y > 0
            ? 'hl.dsp.focus({ workspace = "e-1" })'
            : 'hl.dsp.focus({ workspace = "e+1" })')
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
                text: root.special !== "" ? root.specialInfo(root.special).glyph : "\uf009"
                pixelSize: 13
                box: 20
                color: Look.primary
            }
            Label {
                font.bold: true
                font.pixelSize: 13
                text: root.special !== ""
                    ? (root.expanded ? "Special · " : "") + root.specialInfo(root.special).label
                    : (root.expanded ? "Workspace " : "") + root.activeId
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
                model: 5

                Rectangle {
                    id: cell

                    required property int index
                    readonly property int wsId: root.page + index
                    readonly property bool current: root.activeId === wsId
                    readonly property bool on: current && root.special === ""

                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 14
                    color: on ? Look.primary : cm.containsMouse ? Look.surfaceHiest : Look.surfaceHi
                    border.width: current && !on ? 1 : 0
                    border.color: Look.primary
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Label {
                        anchors.centerIn: parent
                        text: cell.wsId
                        font.pixelSize: 12
                        font.bold: cell.on
                        color: cell.on ? Look.primaryFg : (root.hasWs(cell.wsId) ? Look.fg : Look.fgDim)
                    }
                    MouseArea {
                        id: cm
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + cell.wsId + " })")
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 16
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                color: Look.outline
            }

            Repeater {
                model: root.specials

                Rectangle {
                    id: scell

                    required property var modelData
                    readonly property bool on: root.special === modelData.name

                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 14
                    color: on ? Look.primary : sm.containsMouse ? Look.surfaceHiest : Look.surfaceHi
                    Behavior on color { ColorAnimation { duration: 150 } }

                    InkIcon {
                        anchors.centerIn: parent
                        text: scell.modelData.glyph
                        pixelSize: 13
                        box: 28
                        color: scell.on ? Look.primaryFg : (root.hasSpecial(scell.modelData.name) ? Look.fg : Look.fgDim)
                    }
                    // dot = has windows
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        width: 4
                        height: 4
                        radius: 2
                        color: Look.primary
                        visible: !scell.on && root.hasSpecial(scell.modelData.name)
                    }
                    MouseArea {
                        id: sm
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Hyprland.dispatch('hl.dsp.workspace.toggle_special("' + scell.modelData.name + '")')
                    }
                }
            }
        }
    }
}
