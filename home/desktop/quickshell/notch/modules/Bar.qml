import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common
import qs.services

// Full-screen layer: draws the screen border + a notch hanging off the top edge.
// Collapsed = just the clock. Hover = expands into the control center.
// Only the notch takes input; everything else is click-through.
PanelWindow {
    id: win

    property bool expanded: false
    property string view: "main"   // "main" | "notifs"
    property bool shown: false
    property bool songShown: false
    property bool songArmed: false

    Component.onCompleted: shown = true

    onExpandedChanged: {
        if (expanded) Network.refresh();
        else view = "main";
    }

    // toasts only on the monitor you're working on
    readonly property bool focusedHere: (Hyprland.focusedMonitor?.name ?? screen.name) === screen.name

    // song toast replaces the clock while it shows
    readonly property bool songShowing: !expanded && songShown

    readonly property Item cur: expanded ? (view === "notifs" ? notifPanel : cc) : (songShown ? songToast : null)

    // notch geometry
    readonly property real pillW: clock.implicitWidth + Look.pad * 2
    readonly property real targetW: Math.max(pillW, cur ? cur.implicitWidth + Look.pad * 2 : 0)
    readonly property real targetH: songShowing ? Look.border + 10 + songToast.implicitHeight + 12
                                                 : Look.pillHeight + (cur ? cur.implicitHeight + Look.pad : 0)
    property real bodyW: targetW
    property real bodyH: targetH
    property real bodyR: cur ? 24 : Look.notchRadius

    Behavior on bodyW { Anim {} }
    Behavior on bodyH { Anim { curve: win.cur ? Look.spring : Look.emphasized } }
    Behavior on bodyR { Anim { duration: 200; curve: Look.standard } }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "notch"
    WlrLayershell.keyboardFocus: LauncherState.open && focusedHere ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: notch
        Region { item: dock }
        Region { item: wsDock }
        Region { item: trayDock }
        Region { item: launcher }
        Region { item: wallDock }
        Region { item: clipDock }
        Region { item: scrim }
    }

    // 3s "now playing" toast in the notch when the track changes
    Timer {
        id: songTimer
        interval: 3000
        onTriggered: win.songShown = false
    }
    Timer {
        interval: 2000
        running: true
        onTriggered: win.songArmed = true
    }
    Connections {
        target: Players.active
        function onTrackTitleChanged() {
            if (!win.songArmed || !win.focusedHere || !Players.active?.trackTitle) return;
            win.songShown = true;
            songTimer.restart();
        }
    }

    Timer {
        id: collapse
        interval: 350
        onTriggered: {
            if (cc.busy) collapse.restart();
            else win.expanded = false;
        }
    }

    // dims the screen while the launcher is open; clicking it closes the launcher
    Item {
        id: scrim

        property real dim: LauncherState.open && win.focusedHere ? 1 : 0
        Behavior on dim { Anim { duration: 250; curve: Look.standard } }

        width: dim > 0.01 ? win.width : 0
        height: win.height

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.35 * scrim.dim
        }
        MouseArea {
            anchors.fill: parent
            onClicked: LauncherState.hide()
        }
    }

    // ───────────── screen border ─────────────
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: frame

            readonly property real t: Look.border
            readonly property real r: Look.borderRadius
            readonly property real w: win.width
            readonly property real h: win.height

            fillRule: ShapePath.OddEvenFill
            fillColor: Look.surface
            strokeWidth: -1

            startX: 0
            startY: 0
            PathLine { x: frame.w; y: 0 }
            PathLine { x: frame.w; y: frame.h }
            PathLine { x: 0; y: frame.h }
            PathLine { x: 0; y: 0 }

            PathMove { x: frame.t + frame.r; y: frame.t }
            PathLine { x: frame.w - frame.t - frame.r; y: frame.t }
            PathArc { x: frame.w - frame.t; y: frame.t + frame.r; radiusX: frame.r; radiusY: frame.r }
            PathLine { x: frame.w - frame.t; y: frame.h - frame.t - frame.r }
            PathArc { x: frame.w - frame.t - frame.r; y: frame.h - frame.t; radiusX: frame.r; radiusY: frame.r }
            PathLine { x: frame.t + frame.r; y: frame.h - frame.t }
            PathArc { x: frame.t; y: frame.h - frame.t - frame.r; radiusX: frame.r; radiusY: frame.r }
            PathLine { x: frame.t; y: frame.t + frame.r }
            PathArc { x: frame.t + frame.r; y: frame.t; radiusX: frame.r; radiusY: frame.r }
        }
    }

    // ───────────── corner docks: workspaces (top-left), tray (top-right), toasts (bottom-right) ─────────────
    WsDock {
        id: wsDock
        screen: win.screen
    }

    TrayDock {
        id: trayDock
        screenWidth: win.width
    }

    NotifDock {
        id: dock
        screenWidth: win.width
        screenHeight: win.height
        active: win.focusedHere && !(win.expanded && win.view === "notifs")
    }

    OsdDock {
        screenWidth: win.width
        screenHeight: win.height
        active: !win.expanded
    }

    LauncherDock {
        id: launcher
        screenWidth: win.width
        screenHeight: win.height
        active: win.focusedHere
    }

    ClipboardDock {
        id: clipDock
        screenWidth: win.width
        screenHeight: win.height
        active: win.focusedHere
    }

    WallpaperDock {
        id: wallDock
        screenWidth: win.width
        screenHeight: win.height
        active: win.focusedHere
    }

    // ───────────── the notch ─────────────
    Item {
        id: notch

        x: (parent.width - width) / 2
        y: win.shown ? 0 : -height - 10
        width: win.bodyW
        height: win.bodyH

        Behavior on y { Anim { duration: Look.dur.slow } }

        HoverHandler {
            id: hover
            onHoveredChanged: {
                if (hovered) {
                    collapse.stop();
                    win.expanded = true;
                } else {
                    collapse.restart();
                }
            }
        }

        // body shape with concave "ears" that blend into the top border
        Shape {
            x: -Look.earRadius
            width: notch.width + Look.earRadius * 2
            height: notch.height
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                id: body

                readonly property real e: Look.earRadius
                readonly property real t: Look.border
                readonly property real r: win.bodyR
                readonly property real w: notch.width
                readonly property real h: notch.height

                fillColor: Look.surface
                strokeWidth: -1

                startX: 0
                startY: 0
                PathLine { x: body.w + 2 * body.e; y: 0 }
                PathLine { x: body.w + 2 * body.e; y: body.t }
                PathArc { x: body.w + body.e; y: body.t + body.e; radiusX: body.e; radiusY: body.e; direction: PathArc.Counterclockwise }
                PathLine { x: body.w + body.e; y: body.h - body.r }
                PathArc { x: body.w + body.e - body.r; y: body.h; radiusX: body.r; radiusY: body.r }
                PathLine { x: body.e + body.r; y: body.h }
                PathArc { x: body.e; y: body.h - body.r; radiusX: body.r; radiusY: body.r }
                PathLine { x: body.e; y: body.t + body.e }
                PathArc { x: 0; y: body.t; radiusX: body.e; radiusY: body.e; direction: PathArc.Counterclockwise }
                PathLine { x: 0; y: 0 }
            }
        }

        Item {
            anchors.fill: parent
            clip: true

            // header row: clock + notification bell
            Item {
                width: parent.width
                y: Look.border
                height: Look.pillHeight - Look.border

                Clock {
                    id: clock
                    anchors.centerIn: parent
                    opacity: win.songShowing ? 0 : 1
                    scale: win.songShowing ? 0.9 : 1
                    Behavior on opacity { Anim { duration: 200; curve: Look.standard } }
                    Behavior on scale { Anim { duration: 200; curve: Look.standard } }
                }

                Chip {
                    anchors.right: parent.right
                    anchors.rightMargin: Look.pad - 6
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: win.expanded ? 1 : 0
                    enabled: win.expanded
                    active: win.view === "notifs"
                    onClicked: win.view = win.view === "notifs" ? "main" : "notifs"
                    Behavior on opacity { Anim { duration: 250; curve: Look.standard } }

                    InkIcon {
                        text: Notifs.dnd ? "\uf1f6" : "\uf0f3"
                        pixelSize: 13
                        box: 20
                        color: Notifs.count > 0 && !Notifs.dnd ? Look.primary : Look.fg
                    }
                    Label {
                        visible: Notifs.count > 0
                        text: Notifs.count
                        font.pixelSize: 12
                        color: Look.primary
                    }
                }
            }

            ControlCenter {
                id: cc
                anchors.horizontalCenter: parent.horizontalCenter
                y: Look.pillHeight
                width: implicitWidth
                shown: win.expanded && win.view === "main"
                opacity: shown ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { Anim { duration: 200; curve: Look.standard } }
            }

            SongToast {
                id: songToast
                anchors.horizontalCenter: parent.horizontalCenter
                y: Look.border + 10
                width: implicitWidth
                opacity: !win.expanded && win.songShown ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { Anim { duration: 250; curve: Look.standard } }
            }

            NotifPanel {
                id: notifPanel
                anchors.horizontalCenter: parent.horizontalCenter
                y: Look.pillHeight
                width: implicitWidth
                opacity: win.expanded && win.view === "notifs" ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { Anim { duration: 200; curve: Look.standard } }
            }
        }
    }
}
