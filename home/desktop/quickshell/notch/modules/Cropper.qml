import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Invisible helper: crops a region out of the pre-selection freeze frame -> PNG
// (so the selector overlay can never bleed into the screenshot).
PanelWindow {
    id: win

    visible: Capture.cropping

    implicitWidth: 1
    implicitHeight: 1
    anchors {
        top: true
        left: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}
    WlrLayershell.namespace: "notch-crop"
    WlrLayershell.layer: WlrLayer.Background

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
