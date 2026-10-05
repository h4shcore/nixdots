import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.services

// Clipboard history growing out of the bottom border.
// Type to search · Up/Down (Tab, Ctrl+J/K) move · Enter copy · Shift+Enter copy + paste
// Ctrl+D delete · Alt+P pin · Esc close
Item {
    id: root

    required property real screenWidth
    required property real screenHeight
    property bool active: true

    readonly property bool open: LauncherState.open && LauncherState.mode === "clip" && active
    property string query: ""
    readonly property var results: Clip.search(query)
    readonly property bool empty: results.length === 0
    property bool confirmClear: false

    readonly property real e: Look.earRadius
    readonly property real t: Look.border
    readonly property real r: 28
    readonly property int rowH: 54
    readonly property int maxRows: 7
    readonly property real listH: Math.min(results.length, maxRows) * rowH
    readonly property real targetW: 620
    readonly property real targetH: 14 + 46 + 10 + (empty ? 56 : listH) + 14 + t

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

    function label(r) {
        if (!r.isImage) return r.preview;
        const m = /\[\[ binary data (\S+ \S+) (\w+) (\d+x\d+) \]\]/.exec(r.preview);
        return m ? m[2].toUpperCase() + " image  ·  " + m[3] + "  ·  " + m[1] : "Image";
    }

    function current() { return root.results[lv.currentIndex]; }

    function copyCurrent(paste) {
        const r = current();
        if (!r) return;
        Clip.copy(r.id, paste);
        LauncherState.hide();
    }
    function removeCurrent() {
        const r = current();
        if (r) Clip.remove(r.id);
    }
    function pinCurrent() {
        const r = current();
        if (r) Clip.togglePin(r.id);
    }

    function move(delta) {
        if (lv.count === 0) return;
        lv.currentIndex = (lv.currentIndex + delta + lv.count) % lv.count;
        lv.positionViewAtIndex(lv.currentIndex, ListView.Contain);
    }

    onOpenChanged: {
        settled = false;
        settleTimer.restart();
        confirmClear = false;
        if (open) {
            Clip.refresh();
            input.text = "";
            lv.currentIndex = 0;
            focusTimer.restart();
        }
    }
    onQueryChanged: lv.currentIndex = 0

    Timer {
        id: focusTimer
        interval: 60
        onTriggered: input.forceActiveFocus()
    }
    Timer {
        id: confirmTimer
        interval: 3000
        onTriggered: root.confirmClear = false
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
                    text: "\uf0ea"
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
                        rightMargin: 120
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
                        const alt = ev.modifiers & Qt.AltModifier;
                        const shift = ev.modifiers & Qt.ShiftModifier;
                        if (ev.key === Qt.Key_Down || ev.key === Qt.Key_Tab || (ctrl && ev.key === Qt.Key_J) || (ctrl && ev.key === Qt.Key_N)) {
                            root.move(1);
                            ev.accepted = true;
                        } else if (ev.key === Qt.Key_Up || ev.key === Qt.Key_Backtab || (ctrl && ev.key === Qt.Key_K) || (ctrl && ev.key === Qt.Key_P)) {
                            root.move(-1);
                            ev.accepted = true;
                        } else if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) {
                            root.copyCurrent(!!shift);
                            ev.accepted = true;
                        } else if (ctrl && ev.key === Qt.Key_D) {
                            root.removeCurrent();
                            ev.accepted = true;
                        } else if (alt && ev.key === Qt.Key_P) {
                            root.pinCurrent();
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
                    text: "Search clipboard…"
                    color: Look.fgDim
                    font.pixelSize: 15
                }

                Label {
                    anchors.right: clearBtn.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.confirmClear ? "Clear all?" : root.results.length + (root.query === "" ? " items" : " found")
                    color: root.confirmClear ? Look.primary : Look.fgDim
                    font.pixelSize: 11
                }

                IconButton {
                    id: clearBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    size: 32
                    primary: root.confirmClear
                    glyph: "\uf1f8"
                    onClicked: {
                        if (root.confirmClear) {
                            Clip.wipe();
                            root.confirmClear = false;
                        } else {
                            root.confirmClear = true;
                            confirmTimer.restart();
                        }
                    }
                }
            }
        }

        // history list
        Reveal {
            x: 14
            y: 14 + 46 + 10
            width: parent.width - 28
            height: root.listH
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
                    readonly property bool hot: current || rowMouse.containsMouse

                    width: ListView.view.width
                    height: root.rowH

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: 18
                        color: row.current ? Look.secondaryContainer : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onPositionChanged: lv.currentIndex = row.index
                        onClicked: {
                            lv.currentIndex = row.index;
                            root.copyCurrent(false);
                        }
                    }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 16
                            rightMargin: 12
                        }
                        spacing: 12

                        // image thumbnail, or a text glyph
                        ClippingRectangle {
                            Layout.preferredWidth: 46
                            Layout.preferredHeight: 34
                            radius: 10
                            color: Look.surfaceHiest

                            Image {
                                anchors.fill: parent
                                visible: row.modelData.isImage
                                source: row.modelData.isImage ? Clip.thumbUrl(row.modelData.id) : ""
                                sourceSize: Qt.size(120, 90)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                            InkIcon {
                                anchors.centerIn: parent
                                visible: !row.modelData.isImage
                                text: "\uf15c"
                                color: Look.fgDim
                                pixelSize: 15
                                box: 28
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: root.label(row.modelData)
                            font.pixelSize: 13
                            font.family: row.modelData.isImage ? Look.font : "monospace"
                        }

                        IconButton {
                            size: 28
                            glyph: "\uf005"
                            primary: row.modelData.pinned
                            opacity: row.modelData.pinned || row.hot ? 1 : 0
                            enabled: opacity > 0
                            Behavior on opacity { Anim { duration: 120; curve: Look.standard } }
                            onClicked: Clip.togglePin(row.modelData.id)
                        }
                        IconButton {
                            size: 28
                            glyph: "\uf00d"
                            opacity: row.hot ? 1 : 0
                            enabled: opacity > 0
                            Behavior on opacity { Anim { duration: 120; curve: Look.standard } }
                            onClicked: Clip.remove(row.modelData.id)
                        }
                    }
                }
            }
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 14 + 46 + 10 + 18
            visible: root.empty
            opacity: root.open ? 1 : 0
            text: !Clip.available ? "Needs cliphist + wl-clipboard installed"
                : root.query === "" ? "Clipboard history is empty — copy something"
                : "Nothing matches “" + root.query + "”"
            color: Look.fgDim
        }
    }
}
