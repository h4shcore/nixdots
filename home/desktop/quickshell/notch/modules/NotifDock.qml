import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.common
import qs.services

// Toast dock attached to the top-right corner of the screen border.
// Slides in from the right; concave ears blend it into the top + right borders.
Item {
    id: root

    required property real screenWidth
    property bool active: true

    readonly property real cardW: 340
    readonly property bool shown: active && Notifs.popups.length > 0
    readonly property real e: Theme.earRadius
    readonly property real t: Theme.border
    readonly property real r: 20

    property real boxH: 0
    property real slide: shown ? 0 : width + e + 24

    // keep the last height while sliding away
    Binding {
        target: root
        property: "boxH"
        value: root.t + 8 + list.contentHeight + 10
        when: root.shown
        restoreMode: Binding.RestoreNone
    }
    Behavior on boxH { Anim {} }
    Behavior on slide { Anim { duration: Theme.dur.slow; curve: root.shown ? Theme.spring : Theme.emphasized } }

    width: cardW + t + 20
    height: Math.max(boxH, t + e + r)
    x: screenWidth - width + slide
    y: 0

    Shape {
        x: -root.e
        width: root.width + root.e
        height: root.height + root.e
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: sp

            readonly property real e: root.e
            readonly property real t: root.t
            readonly property real r: root.r
            readonly property real w: root.width
            readonly property real h: root.height

            fillColor: Theme.surface
            strokeWidth: -1

            startX: 0
            startY: 0
            PathLine { x: sp.w + sp.e; y: 0 }
            PathLine { x: sp.w + sp.e; y: sp.h + sp.e }
            PathLine { x: sp.w - sp.t + sp.e; y: sp.h + sp.e }
            PathArc { x: sp.w - sp.t; y: sp.h; radiusX: sp.e; radiusY: sp.e; direction: PathArc.Counterclockwise }
            PathLine { x: sp.r + sp.e; y: sp.h }
            PathArc { x: sp.e; y: sp.h - sp.r; radiusX: sp.r; radiusY: sp.r }
            PathLine { x: sp.e; y: sp.t + sp.e }
            PathArc { x: 0; y: sp.t; radiusX: sp.e; radiusY: sp.e; direction: PathArc.Counterclockwise }
            PathLine { x: 0; y: 0 }
        }
    }

    ListView {
        id: list
        x: 10
        y: root.t + 8
        width: root.cardW
        height: contentHeight
        spacing: 8
        interactive: false
        model: ScriptModel { values: [...Notifs.popups] }

        delegate: NotifCard {
            required property var modelData
            width: ListView.view.width
            entry: modelData
        }

        add: Transition {
            ParallelAnimation {
                Anim { property: "opacity"; from: 0; to: 1; curve: Theme.standard; duration: 200 }
                Anim { property: "scale"; from: 0.9; to: 1 }
            }
        }
        remove: Transition {
            ParallelAnimation {
                Anim { property: "opacity"; to: 0; curve: Theme.standard; duration: 200 }
                Anim { property: "scale"; to: 0.9; curve: Theme.standard; duration: 200 }
            }
        }
        displaced: Transition {
            Anim { property: "y" }
        }
    }
}
