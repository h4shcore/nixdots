import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Invisible helper window for two jobs:
//  1. capture ONE window by itself (Hyprland toplevel export) -> PNG
//  2. crop a region out of the pre-selection freeze frame -> PNG (so the overlay can never bleed in)
PanelWindow {
    id: win

    visible: Capture.grabbing || Capture.cropping

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

    // ── single window ──
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

    // ── region crop from the freeze frame ──
    function crop() {
        if (!Capture.cropping || cropImg.status !== Image.Ready) return;
        const s = cropImg.implicitWidth / Math.max(1, Capture.cropScrW);      // physical px per logical px
        const size = Qt.size(Math.max(1, Math.round(Capture.cropW * s)), Math.max(1, Math.round(Capture.cropH * s)));
        cropBox.grabToImage(r => Capture.cropped(r.saveToFile(Capture.shotPath)), size);
    }

    Timer {
        id: cropTimer
        interval: 60
        onTriggered: win.crop()
    }

    Item {
        id: cropBox
        width: Math.max(1, Capture.cropW)
        height: Math.max(1, Capture.cropH)
        clip: true

        Image {
            id: cropImg
            source: Capture.cropping && Capture.freezePath !== "" ? "file://" + Capture.freezePath : ""
            cache: false
            asynchronous: false
            fillMode: Image.Stretch
            smooth: true
            x: -Capture.cropX
            y: -Capture.cropY
            width: Capture.cropScrW
            height: Capture.cropScrH

            onStatusChanged: if (status === Image.Ready && Capture.cropping) cropTimer.restart()
        }
    }
}
