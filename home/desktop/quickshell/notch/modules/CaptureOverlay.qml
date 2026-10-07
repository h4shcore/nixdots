import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.services

// Fullscreen frozen-frame selector (region drag, or click a window). One per screen, shown only
// on the screen the capture was started from.
PanelWindow {
    id: win

    readonly property bool mine: Capture.selecting && Capture.selectScreen !== null && Capture.selectScreen.name === screen.name
    readonly property bool windowMode: Capture.target === "window"

    // selection rect, overlay-local logical px
    property real selX: 0
    property real selY: 0
    property real selW: 0
    property real selH: 0
    property bool dragging: false
    property int hov: -1
    readonly property bool hasSel: selW > 1 && selH > 1

    function resetSel() {
        selX = 0;
        selY = 0;
        selW = 0;
        selH = 0;
        hov = -1;
        dragging = false;
    }

    onMineChanged: {
        resetSel();
        if (mine) {
            frameTimer.restart();
            stage.forceActiveFocus();
        }
    }

    Behavior on selX { enabled: win.windowMode; Anim { duration: 140; curve: Look.standard } }
    Behavior on selY { enabled: win.windowMode; Anim { duration: 140; curve: Look.standard } }
    Behavior on selW { enabled: win.windowMode; Anim { duration: 140; curve: Look.standard } }
    Behavior on selH { enabled: win.windowMode; Anim { duration: 140; curve: Look.standard } }

    visible: mine
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "notch-capture"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: mine ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Timer {
        id: frameTimer
        interval: 30
        onTriggered: sv.captureFrame()
    }

    Item {
        id: stage
        anchors.fill: parent
        focus: true

        Keys.onPressed: ev => {
            if (ev.key === Qt.Key_Escape) {
                Capture.cancel();
                ev.accepted = true;
            }
        }

        ScreencopyView {
            id: sv
            anchors.fill: parent
            captureSource: win.screen
            live: false
            paintCursor: false
        }

        // dim everything except the selection
        Item {
            anchors.fill: parent
            opacity: win.mine ? 1 : 0
            Behavior on opacity { Anim { duration: 200; curve: Look.standard } }

            Rectangle { color: Qt.rgba(0, 0, 0, 0.5); x: 0; y: 0; width: parent.width; height: win.selY }
            Rectangle { color: Qt.rgba(0, 0, 0, 0.5); x: 0; y: win.selY + win.selH; width: parent.width; height: parent.height - (win.selY + win.selH) }
            Rectangle { color: Qt.rgba(0, 0, 0, 0.5); x: 0; y: win.selY; width: win.selX; height: win.selH }
            Rectangle { color: Qt.rgba(0, 0, 0, 0.5); x: win.selX + win.selW; y: win.selY; width: parent.width - (win.selX + win.selW); height: win.selH }
        }

        // selection outline
        Rectangle {
            visible: win.hasSel
            x: win.selX
            y: win.selY
            width: win.selW
            height: win.selH
            color: "transparent"
            border.width: 2
            border.color: Look.primary
            radius: win.windowMode ? 10 : 2
        }

        // size / title chip under the selection
        Rectangle {
            visible: win.hasSel
            x: Math.max(8, Math.min(parent.width - width - 8, win.selX + win.selW / 2 - width / 2))
            y: Math.min(parent.height - height - 8, win.selY + win.selH + 10)
            width: dimLabel.implicitWidth + 24
            height: 28
            radius: 14
            color: Look.surface

            Label {
                id: dimLabel
                anchors.centerIn: parent
                font.pixelSize: 12
                text: win.windowMode && win.hov >= 0 ? Capture.windows[win.hov].title || "window"
                                                     : Math.round(win.selW) + " × " + Math.round(win.selH)
            }
        }

        // hint
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 18
            width: hint.implicitWidth + 32
            height: 34
            radius: 17
            color: Look.surface

            Label {
                id: hint
                anchors.centerIn: parent
                font.pixelSize: 12
                color: Look.fgDim
                text: (Capture.kind === "record" ? "Record  ·  " : "Screenshot  ·  ")
                    + (win.windowMode ? "click a window" : "drag to select an area") + "  ·  Esc to cancel"
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.CrossCursor

            property real sx: 0
            property real sy: 0

            function windowAt(mx, my) {
                const gx = mx + win.screen.x;
                const gy = my + win.screen.y;
                const ws = Capture.windows;
                for (let i = 0; i < ws.length; i++) {
                    const w = ws[i];
                    if (gx >= w.x && gx < w.x + w.w && gy >= w.y && gy < w.y + w.h) return i;
                }
                return -1;
            }

            onPositionChanged: m => {
                if (win.windowMode) {
                    const i = windowAt(m.x, m.y);
                    win.hov = i;
                    if (i >= 0) {
                        const w = Capture.windows[i];
                        win.selX = w.x - win.screen.x;
                        win.selY = w.y - win.screen.y;
                        win.selW = w.w;
                        win.selH = w.h;
                    } else {
                        win.selW = 0;
                        win.selH = 0;
                    }
                } else if (win.dragging) {
                    win.selX = Math.min(sx, m.x);
                    win.selY = Math.min(sy, m.y);
                    win.selW = Math.abs(m.x - sx);
                    win.selH = Math.abs(m.y - sy);
                }
            }

            onPressed: m => {
                if (win.windowMode) return;
                sx = m.x;
                sy = m.y;
                win.dragging = true;
                win.selX = m.x;
                win.selY = m.y;
                win.selW = 0;
                win.selH = 0;
            }

            onReleased: m => {
                if (win.windowMode) return;
                win.dragging = false;
                if (win.selW > 8 && win.selH > 8) Capture.finishRect(win.screen, win.selX, win.selY, win.selW, win.selH);
                else win.resetSel();
            }

            onClicked: m => {
                if (win.windowMode && win.hov >= 0) Capture.finishWindow(Capture.windows[win.hov]);
            }
        }
    }
}
