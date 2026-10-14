import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.services

// App launcher growing out of the bottom border (centered).
// Type to search, Up/Down (or Ctrl+J/K, Tab) to move, Enter to launch, Esc to close.
// Modes: "=2+2*3" calculator (math is also auto-detected), ":fire" emoji picker (Enter copies the result),
// ">cmd" runs a shell command in a terminal (Ctrl+Enter: silently in the background).
Item {
    id: root

    required property real screenWidth
    required property real screenHeight
    property bool active: true

    readonly property bool open: LauncherState.open && LauncherState.mode === "apps" && active
    property string query: ""
    readonly property string mode: query.startsWith(":") ? "emoji" : query.startsWith("=") ? "calc" : query.startsWith(">") ? "cmd" : "apps"
    readonly property var results: {
        const q = query;
        if (mode === "emoji") return Emoji.search(q.slice(1));
        if (mode === "cmd") return Cmd.rows(q.slice(1));
        if (mode === "calc") {
            const c = Calc.force(q.slice(1));
            return c ? [c] : [];
        }
        const c = Calc.auto(q);
        const apps = Apps.search(q);
        return c ? [c, ...apps] : apps;
    }
    readonly property bool empty: results.length === 0

    readonly property real e: Look.earRadius
    readonly property real t: Look.border
    readonly property real r: 28
    readonly property int rowH: 54
    readonly property int maxRows: 7
    readonly property real listH: Math.min(results.length, maxRows) * rowH
    readonly property real listShown: listH

    readonly property real targetW: 620
    readonly property real targetH: 14 + 46 + 10 + (empty ? 44 : listShown) + 14 + t

    property real bodyW: open ? targetW : 240
    property real bodyH: open ? targetH : 0
    Behavior on bodyW { Anim {} }
    Behavior on bodyH {
        Anim {
            duration: root.settled ? 140 : Look.dur.normal
            curve: root.settled ? Look.standard : (root.open ? Look.spring : Look.emphasized)
        }
    }

    // after the open/close animation, resizes while typing are quick and direct
    property bool settled: false
    Timer {
        id: settleTimer
        interval: 450
        onTriggered: root.settled = true
    }

    function iconFor(entry) {
        const i = entry.icon || "";
        if (i.startsWith("/")) return "file://" + i;
        return Quickshell.iconPath(i, "application-x-executable");
    }

    function launch(entry) {
        Apps.launch(entry);
        LauncherState.hide();
    }

    // apps launch; calculator results and emoji are copied to the clipboard
    function activate(r, background) {
        if (!r) return;
        if (r.kind === "cmd") {
            Cmd.run(r.text, !background);
            LauncherState.hide();
        } else if (r.kind === "calc" || r.kind === "emoji") {
            Quickshell.execDetached(["wl-copy", "--", r.text]);
            LauncherState.hide();
        } else {
            root.launch(r.entry);
        }
    }

    function launchCurrent(background) {
        root.activate(root.results[lv.currentIndex], background === true);
    }

    // IPC can open the launcher straight into a mode (preset "=" or ":")
    function applyPreset() {
        input.text = LauncherState.preset;
        LauncherState.preset = "";
        input.cursorPosition = input.text.length;
    }

    function move(delta) {
        if (lv.count === 0) return;
        lv.currentIndex = (lv.currentIndex + delta + lv.count) % lv.count;
        lv.positionViewAtIndex(lv.currentIndex, ListView.Contain);
    }

    onOpenChanged: {
        settled = false;
        settleTimer.restart();
        if (open) {
            applyPreset();
            lv.currentIndex = 0;
            focusTimer.restart();
        }
    }

    Connections {
        target: LauncherState
        function onPresetChanged() {
            if (root.open && LauncherState.preset !== "") root.applyPreset();
        }
    }
    onQueryChanged: lv.currentIndex = 0

    Timer {
        id: focusTimer
        interval: 60
        onTriggered: input.forceActiveFocus()
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

        // search bar
        Reveal {
            x: 14
            y: 14
            width: parent.width - 28
            height: 46
            shown: root.open
            delay: 20

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Look.surfaceHi

                InkIcon {
                    x: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.mode === "emoji" ? "\uf118" : root.mode === "calc" ? "\uf1ec" : root.mode === "cmd" ? "\uf120" : "\uf002"
                    color: Look.primary
                    pixelSize: 16
                    box: 28
                }

                TextInput {
                    id: input
                    anchors {
                        left: parent.left
                        leftMargin: 50
                        right: parent.right
                        rightMargin: 80
                        verticalCenter: parent.verticalCenter
                    }
                    color: Look.fg
                    selectionColor: Look.primary
                    selectedTextColor: Look.primaryFg
                    font.family: Look.font
                    font.pixelSize: 15
                    clip: true
                    onTextChanged: root.query = text

                    Keys.onPressed: ev => {
                        const ctrl = ev.modifiers & Qt.ControlModifier;
                        if (ev.key === Qt.Key_Down || ev.key === Qt.Key_Tab || (ctrl && ev.key === Qt.Key_J) || (ctrl && ev.key === Qt.Key_N)) {
                            root.move(1);
                            ev.accepted = true;
                        } else if (ev.key === Qt.Key_Up || ev.key === Qt.Key_Backtab || (ctrl && ev.key === Qt.Key_K) || (ctrl && ev.key === Qt.Key_P)) {
                            root.move(-1);
                            ev.accepted = true;
                        } else if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) {
                            root.launchCurrent(ctrl && root.mode === "cmd");
                            ev.accepted = true;
                        } else if (ev.key === Qt.Key_Escape) {
                            LauncherState.hide();
                            ev.accepted = true;
                        }
                    }
                }

                Label {
                    anchors.left: input.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text === ""
                    text: "Search apps…   = calc  ·  : emoji  ·  > run"
                    color: Look.fgDim
                    font.pixelSize: 15
                }

                Label {
                    anchors.right: parent.right
                    anchors.rightMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.mode === "calc" ? "calculator"
                        : root.mode === "cmd" ? "terminal"
                        : root.mode === "emoji" ? root.results.length + " emoji"
                        : root.results.length + (root.query === "" ? " apps" : " found")
                    color: Look.fgDim
                    font.pixelSize: 11
                }
            }
        }

        // results
        Reveal {
            x: 14
            y: 14 + 46 + 10
            width: parent.width - 28
            height: root.listShown
            visible: !root.empty
            shown: root.open
            delay: 70

            ListView {
                id: lv
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: ScriptModel {
                    values: root.results
                    objectProp: "id"
                }

                delegate: Item {
                    id: row

                    required property var modelData
                    required property int index
                    readonly property bool current: ListView.isCurrentItem
                    readonly property string kind: modelData.kind ?? "app"

                    width: ListView.view.width
                    height: root.rowH

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: 18
                        color: row.current ? Look.secondaryContainer : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 16
                            rightMargin: 16
                        }
                        spacing: 12

                        IconImage {
                            visible: row.kind === "app"
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            source: row.kind === "app" ? root.iconFor(row.modelData.entry) : ""
                            scale: row.current ? 1.08 : 1
                            Behavior on scale { Anim { duration: Look.dur.fast } }
                        }

                        // emoji glyph
                        Item {
                            visible: row.kind === "emoji"
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            scale: row.current ? 1.12 : 1
                            Behavior on scale { Anim { duration: Look.dur.fast } }

                            Text {
                                anchors.centerIn: parent
                                text: row.modelData.char ?? ""
                                font.family: "Noto Color Emoji"
                                font.pixelSize: 24
                            }
                        }

                        // command badge
                        Rectangle {
                            visible: row.kind === "cmd"
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            radius: 17
                            color: Look.secondaryContainer

                            Label {
                                anchors.centerIn: parent
                                text: "›_"
                                color: Look.primary
                                font.bold: true
                                font.pixelSize: 14
                            }
                        }

                        // calculator badge
                        Rectangle {
                            visible: row.kind === "calc"
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            radius: 17
                            color: Look.primary

                            Label {
                                anchors.centerIn: parent
                                text: "="
                                color: Look.primaryFg
                                font.bold: true
                                font.pixelSize: 18
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Label {
                                Layout.fillWidth: true
                                text: row.kind === "app" ? row.modelData.entry.name
                                    : row.kind === "calc" || row.kind === "cmd" ? row.modelData.title
                                    : row.modelData.name
                                font.bold: true
                                font.pixelSize: row.kind === "calc" ? 17 : 14
                            }
                            Label {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: row.kind === "app" ? (row.modelData.entry.comment || row.modelData.entry.genericName || "")
                                    : row.kind === "calc" ? row.modelData.subtitle + "  ·  Enter to copy"
                                    : row.kind === "cmd" ? row.modelData.subtitle
                                    : (row.modelData.keys || "Enter to copy")
                                color: Look.fgDim
                                font.pixelSize: 11
                            }
                        }

                        // frequently used marker
                        RowLayout {
                            visible: row.kind === "app" && row.modelData.uses >= 2
                            spacing: 5

                            Icon {
                                text: "\uf005"
                                font.pixelSize: 11
                                color: Look.primary
                            }
                            Label {
                                text: row.modelData.uses
                                color: Look.fgDim
                                font.pixelSize: 11
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onPositionChanged: lv.currentIndex = row.index
                        onClicked: mouse => root.activate(row.modelData, (mouse.modifiers & Qt.ControlModifier) !== 0)
                    }
                }

            }
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 14 + 46 + 10 + 12
            visible: root.empty
            opacity: root.open ? 1 : 0
            text: root.mode === "calc" ? "Type an expression, e.g. 12*(3+4)"
                : root.mode === "cmd" ? "Type a command, e.g. htop"
                : root.mode === "emoji" ? "No emoji match “" + root.query.slice(1) + "”"
                : root.query === "" ? "No applications found" : "No apps match “" + root.query + "”"
            color: Look.fgDim
        }
    }
}
