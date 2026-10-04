import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.services

// App launcher growing out of the bottom border (centered).
// Type to search, Up/Down (or Ctrl+J/K, Tab) to move, Enter to launch, Esc to close.
Item {
    id: root

    required property real screenWidth
    required property real screenHeight
    property bool active: true

    readonly property bool open: LauncherState.open && active
    property string query: ""
    readonly property var results: Apps.search(query)
    readonly property bool empty: results.length === 0

    readonly property real e: Theme.earRadius
    readonly property real t: Theme.border
    readonly property real r: 28
    readonly property int rowH: 54
    readonly property int maxRows: 7
    readonly property real listH: Math.min(results.length, maxRows) * rowH
    property real listShown: listH
    Behavior on listShown { Anim { duration: 250 } }

    readonly property real targetW: 620
    readonly property real targetH: 14 + 46 + 10 + (empty ? 44 : listShown) + 14 + t

    property real bodyW: open ? targetW : 240
    property real bodyH: open ? targetH : 0
    Behavior on bodyW { Anim {} }
    Behavior on bodyH { Anim { curve: root.open ? Theme.spring : Theme.emphasized } }

    function iconFor(entry) {
        const i = entry.icon || "";
        if (i.startsWith("/")) return "file://" + i;
        return Quickshell.iconPath(i, "application-x-executable");
    }

    function launch(entry) {
        Apps.launch(entry);
        LauncherState.hide();
    }

    function launchCurrent() {
        const r = root.results[lv.currentIndex];
        if (r) root.launch(r.entry);
    }

    function move(delta) {
        if (lv.count === 0) return;
        lv.currentIndex = (lv.currentIndex + delta + lv.count) % lv.count;
        lv.positionViewAtIndex(lv.currentIndex, ListView.Contain);
    }

    onOpenChanged: {
        if (open) {
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

            fillColor: Theme.surface
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
                color: Theme.surfaceHi

                InkIcon {
                    x: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf002"
                    color: Theme.primary
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
                    color: Theme.fg
                    selectionColor: Theme.primary
                    selectedTextColor: Theme.primaryFg
                    font.family: Theme.font
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
                            root.launchCurrent();
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
                    text: "Search apps…"
                    color: Theme.fgDim
                    font.pixelSize: 15
                }

                Label {
                    anchors.right: parent.right
                    anchors.rightMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.results.length + (root.query === "" ? " apps" : " found")
                    color: Theme.fgDim
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

                    width: ListView.view.width
                    height: root.rowH

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: 18
                        color: row.current ? Theme.secondaryContainer : "transparent"
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
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            source: root.iconFor(row.modelData.entry)
                            scale: row.current ? 1.08 : 1
                            Behavior on scale { Anim { duration: Theme.dur.fast } }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Label {
                                Layout.fillWidth: true
                                text: row.modelData.entry.name
                                font.bold: true
                                font.pixelSize: 14
                            }
                            Label {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: row.modelData.entry.comment || row.modelData.entry.genericName || ""
                                color: Theme.fgDim
                                font.pixelSize: 11
                            }
                        }

                        // frequently used marker
                        RowLayout {
                            visible: row.modelData.uses >= 2
                            spacing: 5

                            Icon {
                                text: "\uf005"
                                font.pixelSize: 11
                                color: Theme.primary
                            }
                            Label {
                                text: row.modelData.uses
                                color: Theme.fgDim
                                font.pixelSize: 11
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onPositionChanged: lv.currentIndex = row.index
                        onClicked: root.launch(row.modelData.entry)
                    }
                }

                add: Transition {
                    Anim { property: "opacity"; from: 0; to: 1; duration: 150; curve: Theme.standard }
                }
                displaced: Transition {
                    Anim { property: "y" }
                }
            }
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 14 + 46 + 10 + 12
            visible: root.empty
            opacity: root.open ? 1 : 0
            text: root.query === "" ? "No applications found" : "No apps match “" + root.query + "”"
            color: Theme.fgDim
        }
    }
}
