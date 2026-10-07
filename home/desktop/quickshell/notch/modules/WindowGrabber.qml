import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Invisible helper: captures ONE window by itself (Hyprland toplevel export), so overlapping and
// translucent windows don't bleed into window screenshots, then saves it as PNG.
PanelWindow {
    id: win

    visible: Capture.grabbing

    implicitWidth: 1
    implicitHeight: 1
    anchors {
        top: true
        left: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}
    WlrLayershell.namespace: "notch-grab"
    WlrLayershell.layer: WlrLayer.Background

    function save() {
        if (!Capture.grabbing) return;
        sv.grabToImage(r => Capture.grabbed(r.saveToFile(Capture.shotPath)));
    }

    Timer {
        id: saveTimer
        interval: 80
        onTriggered: win.save()
    }

    ScreencopyView {
        id: sv
        captureSource: Capture.grabToplevel
        live: false
        paintCursor: false
        width: sourceSize.width
        height: sourceSize.height

        onCaptureSourceChanged: if (captureSource) Qt.callLater(() => sv.captureFrame())
        onHasContentChanged: if (hasContent && Capture.grabbing) saveTimer.restart()
    }
}
