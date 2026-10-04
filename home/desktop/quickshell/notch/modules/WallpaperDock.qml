import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.services

// Wallpaper picker growing out of the bottom border: a looping carousel of thumbnails.
// Left/Right (h/l, Tab, scroll, drag) browse and wrap around, Enter or click applies, Esc closes.
Item {
    id: root

    required property real screenWidth
    required property real screenHeight
    property bool active: true

    readonly property bool open: LauncherState.open && LauncherState.mode === "wall" && active

    readonly property real e: Look.earRadius
    readonly property real t: Look.border
    readonly property real r: 28
    readonly property real itemW: 196
    readonly property real thumbH: 110
    readonly property real cardH: 7 + thumbH + 6 + 20 + 7

    readonly property real targetW: Math.min(screenWidth - 160, 1040)
    readonly property real targetH: 14 + 44 + 12 + cardH + 16 + t

    property real bodyW: open ? targetW : 240
    property real bodyH: open ? targetH : 0
    Behavior on bodyW { Anim {} }
    Behavior on bodyH { Anim { curve: root.open ? Look.spring : Look.emphasized } }

    function currentPath() {
        return pv.currentIndex >= 0 && pv.currentIndex < files.count ? files.get(pv.currentIndex, "filePath") : "";
    }

    function syncCurrent() {
        let idx = 0;
        for (let i = 0; i < files.count; i++) {
            if (files.get(i, "filePath") === Wallpaper.current) {
                idx = i;
                break;
            }
        }
        pv.currentIndex = idx;
        pv.positionViewAtIndex(idx, PathView.Center);
    }

    function step(delta) {
        if (files.count < 2) return;
        if (delta > 0) pv.incrementCurrentIndex();
        else pv.decrementCurrentIndex();
    }

    function applyPath(path) {
        if (path === "") return;
        Wallpaper.apply(path);
        LauncherState.hide();
    }

    onOpenChanged: {
        if (open) {
            syncCurrent();
            focusTimer.restart();
        }
    }

    Timer {
        id: focusTimer
        interval: 60
        onTriggered: keys.forceActiveFocus()
    }

    FolderListModel {
        id: files
        folder: "file://" + Wallpaper.dir
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.avif", "*.bmp"]
        caseSensitive: false
        showDirs: false
        sortField: FolderListModel.Name
        onCountChanged: if (root.open) root.syncCurrent()
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

        // keyboard handling
        Item {
            id: keys
            focus: true
            Keys.onPressed: ev => {
                if (ev.key === Qt.Key_Left || ev.key === Qt.Key_H || ev.key === Qt.Key_Backtab) {
                    root.step(-1);
                    ev.accepted = true;
                } else if (ev.key === Qt.Key_Right || ev.key === Qt.Key_L || ev.key === Qt.Key_Tab) {
                    root.step(1);
                    ev.accepted = true;
                } else if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) {
                    root.applyPath(root.currentPath());
                    ev.accepted = true;
                } else if (ev.key === Qt.Key_Escape) {
                    LauncherState.hide();
                    ev.accepted = true;
                }
            }
        }

        // header pill (same language as the launcher's search bar)
        Reveal {
            x: 14
            y: 14
            width: parent.width - 28
            height: 44
            shown: root.open
            delay: 20

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Look.surfaceHi

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 20
                    }
                    spacing: 10

                    InkIcon {
                        text: "\uf03e"
                        color: Look.primary
                        pixelSize: 16
                        box: 28
                    }
                    Label {
                        text: "Wallpapers"
                        font.bold: true
                        font.pixelSize: 14
                    }
                    Label {
                        visible: files.count > 0
                        text: (pv.currentIndex + 1) + " / " + files.count
                        color: Look.fgDim
                        font.pixelSize: 12
                    }
                    Item { Layout.fillWidth: true }
                    Label {
                        text: Wallpaper.applying ? "Applying…" : "← →  browse   ·   Enter  apply   ·   Esc  close"
                        color: Wallpaper.applying ? Look.primary : Look.fgDim
                        font.pixelSize: 11
                    }
                }
            }
        }

        // looping carousel
        Reveal {
            x: 0
            y: 14 + 44 + 12
            width: parent.width
            height: root.cardH
            visible: files.count > 0
            shown: root.open
            delay: 70

            PathView {
                id: pv
                anchors.fill: parent
                clip: true
                model: files
                pathItemCount: Math.min(files.count, 5)
                preferredHighlightBegin: 0.5
                preferredHighlightEnd: 0.5
                highlightRangeMode: PathView.StrictlyEnforceRange
                highlightMoveDuration: 420
                snapMode: PathView.SnapToItem
                maximumFlickVelocity: 2500

                // smoothly scale/fade cards by their distance from the center
                path: Path {
                    startX: 0
                    startY: pv.height / 2
                    PathAttribute { name: "sc"; value: 0.72 }
                    PathAttribute { name: "op"; value: 0.45 }
                    PathLine { x: pv.width / 2; y: pv.height / 2 }
                    PathAttribute { name: "sc"; value: 1 }
                    PathAttribute { name: "op"; value: 1 }
                    PathLine { x: pv.width; y: pv.height / 2 }
                    PathAttribute { name: "sc"; value: 0.72 }
                    PathAttribute { name: "op"; value: 0.45 }
                }

                WheelHandler {
                    onWheel: e => root.step((e.angleDelta.y + e.angleDelta.x) > 0 ? -1 : 1)
                }

                delegate: Item {
                    id: card

                    required property int index
                    required property string fileName
                    required property string filePath
                    required property url fileUrl

                    readonly property bool current: PathView.isCurrentItem
                    readonly property bool applied: filePath === Wallpaper.current

                    width: root.itemW
                    height: root.cardH
                    scale: PathView.sc ?? 0.72
                    opacity: PathView.op ?? 0.45
                    z: current ? 2 : 1

                    Rectangle {
                        anchors.fill: parent
                        radius: 24
                        color: card.current ? Look.secondaryContainer : Look.surfaceHi
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    ClippingRectangle {
                        id: thumb
                        x: 7
                        y: 7
                        width: parent.width - 14
                        height: root.thumbH
                        radius: 18
                        color: Look.surfaceHiest

                        Image {
                            anchors.fill: parent
                            source: card.fileUrl
                            sourceSize: Qt.size(420, 240)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { Anim { duration: 250; curve: Look.standard } }
                        }
                    }

                    // currently-applied badge
                    Rectangle {
                        visible: card.applied
                        x: thumb.x + thumb.width - 32
                        y: thumb.y + 8
                        width: 24
                        height: 24
                        radius: 12
                        color: Look.primary

                        InkIcon {
                            anchors.centerIn: parent
                            text: "\uf00c"
                            color: Look.primaryFg
                            pixelSize: 11
                            box: 24
                        }
                    }

                    Label {
                        x: 12
                        y: root.thumbH + 7 + 6
                        width: parent.width - 24
                        horizontalAlignment: Text.AlignHCenter
                        text: card.fileName.replace(/\.[^.]+$/, "")
                        color: card.current ? Look.fg : Look.fgDim
                        font.bold: card.current
                        font.pixelSize: 11
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (card.current) root.applyPath(card.filePath);
                            else pv.currentIndex = card.index;
                        }
                    }
                }
            }
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 14 + 44 + 12 + 50
            visible: files.count === 0
            opacity: root.open ? 1 : 0
            text: "No images in " + Wallpaper.dir
            color: Look.fgDim
        }
    }
}
