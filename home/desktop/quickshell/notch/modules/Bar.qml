import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import qs.common
import qs.services

PanelWindow {
    id: win

    property bool expanded: false
    property string view: "main"   // "main" | "notifs"
    property bool trayOpen: false
    property var trayItem: null
    property bool shown: false

    Component.onCompleted: shown = true

    onExpandedChanged: {
        if (expanded) Network.refresh();
        else {
            view = "main";
            trayOpen = false;
        }
    }

    // toasts only on the monitor you're working on
    readonly property bool focusedHere: (Hyprland.focusedMonitor?.name ?? screen.name) === screen.name

    readonly property Item cur: !expanded ? null : (view === "notifs" ? notifPanel : view === "traymenu" ? trayMenu : cc)

    // notch geometry
    readonly property real pillW: clock.implicitWidth + Theme.pad * 2
    readonly property real targetW: Math.max(pillW, cur ? cur.implicitWidth + Theme.pad * 2 : 0)
    readonly property real targetH: Theme.pillHeight + (cur ? cur.implicitHeight + Theme.pad : 0)
    property real bodyW: targetW
    property real bodyH: targetH
    property real bodyR: expanded ? 24 : Theme.notchRadius

    Behavior on bodyW { Anim {} }
    Behavior on bodyH { Anim { curve: win.expanded ? Theme.spring : Theme.emphasized } }
    Behavior on bodyR { Anim { duration: 200; curve: Theme.standard } }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "notch"

    mask: Region {
        item: notch
        Region { item: dock }
        Region { item: wsDock }
    }

    Timer {
        id: collapse
        interval: 350
        onTriggered: {
            if (cc.busy) collapse.restart();
            else win.expanded = false;
        }
    }

    // ───────────── screen border ─────────────
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: frame

            readonly property real t: Theme.border
            readonly property real r: Theme.borderRadius
            readonly property real w: win.width
            readonly property real h: win.height

            fillRule: ShapePath.OddEvenFill
            fillColor: Theme.surface
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

    // ───────────── notification dock (top-right) ─────────────
    WsDock {
        id: wsDock
        screen: win.screen
        screenWidth: win.width
    }

    NotifDock {
        id: dock
        screenWidth: win.width
        active: win.focusedHere && !(win.expanded && win.view === "notifs")
    }

    // ───────────── the notch ─────────────
    Item {
        id: notch

        x: (parent.width - width) / 2
        y: win.shown ? 0 : -height - 10
        width: win.bodyW
        height: win.bodyH

        Behavior on y { Anim { duration: Theme.dur.slow } }

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
            x: -Theme.earRadius
            width: notch.width + Theme.earRadius * 2
            height: notch.height
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                id: body

                readonly property real e: Theme.earRadius
                readonly property real t: Theme.border
                readonly property real r: win.bodyR
                readonly property real w: notch.width
                readonly property real h: notch.height

                fillColor: Theme.surface
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

            // header row: clock (swapped for the tray when toggled) + right-side chips
            Item {
                width: parent.width
                y: Theme.border
                height: Theme.pillHeight - Theme.border

                Clock {
                    id: clock
                    anchors.centerIn: parent
                    opacity: win.trayOpen ? 0 : 1
                    scale: win.trayOpen ? 0.9 : 1
                    Behavior on opacity { Anim { duration: 200; curve: Theme.standard } }
                    Behavior on scale { Anim { duration: 200; curve: Theme.standard } }
                }

                Tray {
                    id: tray
                    anchors.centerIn: parent
                    cell: 26
                    iconSize: 18
                    onMenuRequested: item => {
                        win.trayItem = item;
                        win.view = "traymenu";
                    }
                    opacity: win.trayOpen ? 1 : 0
                    scale: win.trayOpen ? 1 : 0.9
                    enabled: win.trayOpen
                    Behavior on opacity { Anim { duration: 250; curve: Theme.standard } }
                    Behavior on scale { Anim { duration: 250 } }
                }

                // in-notch tooltip for hovered tray icons
                Rectangle {
                    id: tip

                    readonly property var it: tray.hoveredItem

                    z: 10
                    visible: opacity > 0
                    opacity: win.trayOpen && it !== null && (it.tooltipTitle || it.title) ? 1 : 0
                    Behavior on opacity { Anim { duration: 150; curve: Theme.standard } }

                    y: parent.height + 4
                    x: Math.max(8, Math.min(parent.width - width - 8, tray.x + tray.hoverX - width / 2))
                    width: tipCol.implicitWidth + 20
                    height: tipCol.implicitHeight + 12
                    radius: 12
                    color: Theme.surfaceHiest

                    Column {
                        id: tipCol
                        anchors.centerIn: parent
                        spacing: 2

                        Label {
                            width: Math.min(implicitWidth, 260)
                            text: tip.it ? (tip.it.tooltipTitle || tip.it.title) : ""
                            font.bold: true
                            font.pixelSize: 12
                        }
                        Label {
                            width: Math.min(implicitWidth, 260)
                            visible: text !== ""
                            text: tip.it ? (tip.it.tooltipDescription || "") : ""
                            color: Theme.fgDim
                            font.pixelSize: 11
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.pad - 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    opacity: win.expanded ? 1 : 0
                    enabled: win.expanded
                    Behavior on opacity { Anim { duration: 250; curve: Theme.standard } }

                    // tray toggle
                    Chip {
                        visible: SystemTray.items.values.length > 0
                        active: win.trayOpen
                        onClicked: {
                            win.trayOpen = !win.trayOpen;
                            if (!win.trayOpen && win.view === "traymenu") win.view = "main";
                        }

                        Icon {
                            text: "\uf104"
                            font.pixelSize: 13
                            rotation: win.trayOpen ? 180 : 0
                            Behavior on rotation { Anim {} }
                        }
                        Label {
                            text: SystemTray.items.values.length
                            font.pixelSize: 12
                        }
                    }

                    // notifications
                    Chip {
                        active: win.view === "notifs"
                        onClicked: {
                            win.trayOpen = false;
                            win.view = win.view === "notifs" ? "main" : "notifs";
                        }

                        Icon {
                            text: Notifs.dnd ? "\uf1f6" : "\uf0f3"
                            font.pixelSize: 13
                            color: Notifs.count > 0 && !Notifs.dnd ? Theme.primary : Theme.fg
                        }
                        Label {
                            visible: Notifs.count > 0
                            text: Notifs.count
                            font.pixelSize: 12
                            color: Theme.primary
                        }
                    }
                }
            }

            ControlCenter {
                id: cc
                anchors.horizontalCenter: parent.horizontalCenter
                y: Theme.pillHeight
                width: implicitWidth
                shown: win.expanded && win.view === "main"
                opacity: shown ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { Anim { duration: 200; curve: Theme.standard } }
            }

            TrayMenu {
                id: trayMenu
                anchors.horizontalCenter: parent.horizontalCenter
                y: Theme.pillHeight
                width: implicitWidth
                item: win.trayItem
                opacity: win.expanded && win.view === "traymenu" ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { Anim { duration: 200; curve: Theme.standard } }
                onClose: win.view = "main"
            }

            NotifPanel {
                id: notifPanel
                anchors.horizontalCenter: parent.horizontalCenter
                y: Theme.pillHeight
                width: implicitWidth
                opacity: win.expanded && win.view === "notifs" ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { Anim { duration: 200; curve: Theme.standard } }
            }
        }
    }
}
