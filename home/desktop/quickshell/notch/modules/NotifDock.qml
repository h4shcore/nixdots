import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.common
import qs.services

// Toast dock attached to the bottom-right corner of the screen border.
// Slides in from the right; concave ears blend it into the bottom + right borders.
Item {
    id: root

    required property real screenWidth
    required property real screenHeight
    property bool active: true

    readonly property real cardW: 340
    readonly property bool shown: active && Notifs.popups.length > 0
    readonly property real e: Look.earRadius
    readonly property real t: Look.border
    readonly property real r: 20

    property real boxH: 0
    property real slide: shown ? 0 : width + 24

    // keep the last height while sliding away
    Binding {
        target: root
        property: "boxH"
        value: 10 + list.contentHeight + 8 + root.t
        when: root.shown
        restoreMode: Binding.RestoreNone
    }
    Behavior on boxH { Anim {} }
    Behavior on slide { Anim { duration: Look.dur.slow; curve: root.shown ? Look.spring : Look.emphasized } }

    width: cardW + t + 20
    height: Math.max(boxH, r + t + e + 20)
    x: screenWidth - width + slide
    y: screenHeight - height

    Shape {
        x: -root.e
        y: -root.e
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

            fillColor: Look.surface
            strokeWidth: -1

            // shape-local = root-local + (e, e)
            startX: sp.w + sp.e
            startY: 0
            PathLine { x: sp.w - sp.t + sp.e; y: 0 }
            PathArc { x: sp.w - sp.t; y: sp.e; radiusX: sp.e; radiusY: sp.e }
            PathLine { x: sp.r + sp.e; y: sp.e }
            PathArc { x: sp.e; y: sp.r + sp.e; radiusX: sp.r; radiusY: sp.r; direction: PathArc.Counterclockwise }
            PathLine { x: sp.e; y: sp.h - sp.t }
            PathArc { x: 0; y: sp.h - sp.t + sp.e; radiusX: sp.e; radiusY: sp.e }
            PathLine { x: 0; y: sp.h + sp.e }
            PathLine { x: sp.w + sp.e; y: sp.h + sp.e }
            PathLine { x: sp.w + sp.e; y: 0 }
        }
    }

    ListView {
        id: list
        x: 10
        y: 10
        width: root.cardW
        height: contentHeight
        spacing: 8
        interactive: false
        model: ScriptModel { values: [...Notifs.popups].slice(0, 4) }

        delegate: NotifCard {
            id: nc

            required property var modelData
            property bool entered: false

            width: ListView.view.width
            entry: modelData

            // enter animation lives in the card itself, so rapid arrivals can't interrupt it
            opacity: entered ? 1 : 0
            scale: entered ? 1 : 0.9
            Behavior on opacity { Anim { duration: 220; curve: Look.standard } }
            Behavior on scale { Anim {} }
            Behavior on y { enabled: nc.entered; Anim {} }

            Component.onCompleted: Qt.callLater(() => nc.entered = true)
        }

        remove: Transition {
            ParallelAnimation {
                Anim { property: "opacity"; to: 0; curve: Look.standard; duration: 200 }
                Anim { property: "scale"; to: 0.9; curve: Look.standard; duration: 200 }
            }
        }
    }
}
