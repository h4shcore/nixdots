import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import qs.common
import qs.services

// Power menu growing out of the bottom border.
// Left/Right (Tab) move · Enter run · L lock · E log out · S suspend · R reboot · P shut down · Esc close
// Destructive actions (log out / reboot / shut down) ask for a second press within 3 seconds.
Item {
    id: root

    required property real screenWidth
    required property real screenHeight
    property bool active: true

    readonly property bool open: LauncherState.open && LauncherState.mode === "power" && active

    // edit these if your setup differs
    readonly property var commands: ({
        lock: ["hyprlock"],
        logout: ["uwsm", "stop"],
        suspend: ["systemctl", "suspend"],
        reboot: ["systemctl", "reboot"],
        poweroff: ["systemctl", "poweroff"]
    })

    readonly property var actions: [
        { id: "lock", label: "Lock", glyph: "lock", key: Qt.Key_L, confirm: false },
        { id: "logout", label: "Log out", glyph: "logout", key: Qt.Key_E, confirm: true },
        { id: "suspend", label: "Suspend", glyph: "bedtime", key: Qt.Key_S, confirm: false },
        { id: "reboot", label: "Reboot", glyph: "restart_alt", key: Qt.Key_R, confirm: true },
        { id: "poweroff", label: "Shut down", glyph: "power_settings_new", key: Qt.Key_P, confirm: true }
    ]

    property int index: 0
    property string armed: ""

    readonly property real e: Look.earRadius
    readonly property real t: Look.border
    readonly property real r: 28
    readonly property real targetW: 580
    readonly property real targetH: 16 + 34 + 12 + 96 + 18 + t

    property real bodyW: open ? targetW : 240
    property real bodyH: open ? targetH : 0
    Behavior on bodyW { Anim {} }
    Behavior on bodyH { Anim { curve: root.open ? Look.spring : Look.emphasized } }

    function activate(i) {
        const a = actions[i];
        if (!a) return;
        index = i;
        if (a.confirm && armed !== a.id) {
            armed = a.id;
            armTimer.restart();
            return;
        }
        armed = "";
        LauncherState.hide();
        Quickshell.execDetached(commands[a.id]);
    }

    onOpenChanged: {
        armed = "";
        index = 0;
        if (open) focusTimer.restart();
    }
    Timer {
        id: focusTimer
        interval: 60
        onTriggered: keys.forceActiveFocus()
    }
    Timer {
        id: armTimer
        interval: 3000
        onTriggered: root.armed = ""
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
                if (ev.key === Qt.Key_Left || ev.key === Qt.Key_Backtab || ev.key === Qt.Key_H) {
                    root.index = (root.index + root.actions.length - 1) % root.actions.length;
                    root.armed = "";
                } else if (ev.key === Qt.Key_Right || ev.key === Qt.Key_Tab || ev.key === Qt.Key_J) {
                    root.index = (root.index + 1) % root.actions.length;
                    root.armed = "";
                } else if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) {
                    root.activate(root.index);
                } else if (ev.key === Qt.Key_Escape) {
                    LauncherState.hide();
                } else {
                    const i = root.actions.findIndex(a => a.key === ev.key);
                    if (i < 0) return;
                    root.activate(i);
                }
                ev.accepted = true;
            }
        }

        // header
        Reveal {
            x: 16
            y: 16
            width: parent.width - 32
            height: 34
            shown: root.open
            delay: 20

            RowLayout {
                anchors.fill: parent
                spacing: 10

                InkIcon {
                    text: "power_settings_new"
                    color: Look.primary
                    pixelSize: 17
                    box: 26
                }
                Label {
                    text: "Power"
                    font.bold: true
                    font.pixelSize: 14
                }
                Item { Layout.fillWidth: true }
                Label {
                    text: root.armed !== "" ? "Press again to confirm" : "← →  select   ·   Enter  run   ·   Esc  close"
                    color: root.armed !== "" ? Look.error : Look.fgDim
                    font.pixelSize: 11
                }
            }
        }

        // actions
        Reveal {
            x: 16
            y: 16 + 34 + 12
            width: parent.width - 32
            height: 96
            shown: root.open
            delay: 70

            RowLayout {
                anchors.fill: parent
                spacing: 10

                Repeater {
                    model: root.actions

                    Rectangle {
                        id: tile

                        required property var modelData
                        required property int index
                        readonly property bool current: root.index === index
                        readonly property bool armed: root.armed === modelData.id

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 26
                        color: armed ? Look.error : current ? Look.secondaryContainer : (tileMouse.containsMouse ? Look.surfaceHiest : Look.surfaceHi)
                        scale: tileMouse.pressed ? 0.95 : (current ? 1.04 : 1)

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on scale { Anim { duration: Look.dur.fast } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            InkIcon {
                                Layout.alignment: Qt.AlignHCenter
                                text: tile.modelData.glyph
                                color: tile.armed ? Look.surface : (tile.current ? Look.primary : Look.fg)
                                pixelSize: 24
                                box: 36
                            }
                            Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: tile.armed ? "Confirm?" : tile.modelData.label
                                color: tile.armed ? Look.surface : Look.fg
                                font.pixelSize: 12
                                font.bold: tile.current || tile.armed
                            }
                        }

                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onPositionChanged: root.index = tile.index
                            onClicked: root.activate(tile.index)
                        }
                    }
                }
            }
        }
    }
}
