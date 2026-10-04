import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.common

// System tray attached to the top-right corner of the screen border.
// Idle: a row of icons. Hover an icon: the dock grows a tooltip card. Right-click: it grows the app's menu.
Item {
    id: root

    property real screenWidth: 0

    readonly property real e: Look.earRadius
    readonly property real t: Look.border
    readonly property real r: 18

    property bool ready: false
    readonly property bool shown: ready && SystemTray.items.values.length > 0
    property string mode: "idle"        // idle | tip | menu
    property var menuItem: null
    property var tipItem: null
    readonly property var hoveredIcon: tray.hoveredItem

    Component.onCompleted: ready = true

    function tipTitle(it) { return it ? (it.tooltipTitle || it.title || it.id || "") : ""; }

    onHoveredIconChanged: {
        if (hoveredIcon) {
            tipItem = hoveredIcon;
            if (mode !== "menu") mode = "tip";
        }
    }

    Timer {
        id: leaveTimer
        interval: 350
        onTriggered: root.mode = "idle"
    }
    HoverHandler {
        onHoveredChanged: {
            if (hovered) leaveTimer.stop();
            else leaveTimer.restart();
        }
    }

    // ── geometry ──
    readonly property real iconsW: tray.implicitWidth + Look.pad * 2 + t
    readonly property real tipW: tipBox.implicitWidth + Look.pad * 2 + t
    readonly property real menuW: menuPanel.implicitWidth + Look.pad * 2 + t
    property real bodyW: mode === "menu" ? Math.max(iconsW, menuW) : mode === "tip" ? Math.max(iconsW, tipW) : iconsW
    property real bodyH: Look.pillHeight + (mode === "menu" ? menuPanel.implicitHeight + Look.pad
                                           : mode === "tip" ? tipBox.implicitHeight + Look.pad : 0)

    Behavior on bodyW { Anim {} }
    Behavior on bodyH { Anim { curve: root.mode === "idle" ? Look.emphasized : Look.spring } }

    width: bodyW
    height: bodyH
    x: screenWidth - width
    y: shown ? 0 : -height - 10

    Behavior on y { Anim { duration: Look.dur.slow } }

    // ── body shape (concave ears into the top + right borders) ──
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
            readonly property real h: Math.max(root.height, root.t + root.e + root.r)

            fillColor: Look.surface
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

    // ── content ──
    Item {
        width: root.width - root.t
        height: root.height
        clip: true

        Tray {
            id: tray
            anchors.right: parent.right
            anchors.rightMargin: Look.pad
            cell: 26
            iconSize: 18
            y: root.t + (Look.pillHeight - root.t - cell) / 2
            onMenuRequested: item => {
                root.menuItem = item;
                root.mode = "menu";
            }
        }

        // tooltip card
        Item {
            id: tipBox
            anchors.horizontalCenter: parent.horizontalCenter
            y: Look.pillHeight
            implicitWidth: tipRow.implicitWidth
            implicitHeight: tipRow.implicitHeight
            width: implicitWidth
            opacity: root.mode === "tip" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim { duration: 200; curve: Look.standard } }

            RowLayout {
                id: tipRow
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignTop
                    radius: 14
                    color: Look.surfaceHi

                    IconImage {
                        anchors.centerIn: parent
                        width: 26
                        height: 26
                        source: root.tipItem ? root.tipItem.icon : ""
                    }
                }

                ColumnLayout {
                    Layout.maximumWidth: 250
                    spacing: 2

                    Label {
                        Layout.fillWidth: true
                        text: root.tipTitle(root.tipItem)
                        font.bold: true
                        font.pixelSize: 14
                    }
                    Label {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: root.tipItem ? (root.tipItem.tooltipDescription || "") : ""
                        color: Look.fgDim
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        text: "Click to open" + (root.tipItem && root.tipItem.hasMenu ? "  ·  Right-click for menu" : "")
                        color: Look.primary
                        font.pixelSize: 11
                    }
                }
            }
        }

        // the app's own menu
        TrayMenu {
            id: menuPanel
            anchors.horizontalCenter: parent.horizontalCenter
            y: Look.pillHeight
            width: implicitWidth
            item: root.menuItem
            opacity: root.mode === "menu" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim { duration: 200; curve: Look.standard } }
            onClose: root.mode = "idle"
        }
    }
}
