pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Backlight via brightnessctl. Hidden automatically on machines without one.
Singleton {
    id: root

    property real value: 0
    property bool available: false
    property bool dirty: false

    function set(v) {
        value = Math.max(0.02, Math.min(1, v));
        if (setProc.running) dirty = true;
        else apply();
    }

    function apply() {
        dirty = false;
        setProc.command = ["brightnessctl", "-q", "-c", "backlight", "set", Math.round(value * 100) + "%"];
        setProc.running = true;
    }

    function refresh() {
        if (!setProc.running && !dirty) getProc.running = true;
    }

    Process {
        id: setProc
        onExited: if (root.dirty) root.apply()
    }

    Process {
        id: getProc
        command: ["brightnessctl", "-c", "backlight", "-m"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(",");
                if (p.length >= 5) {
                    root.value = parseInt(p[3]) / 100;
                    root.available = true;
                }
            }
        }
    }

    Timer {
        interval: 800
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
