pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Applies a wallpaper by running matugen (your matugen config's hooks set the wallpaper
// and regenerate the colors). The last applied wallpaper is remembered across restarts.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/Pictures/wallpapers"
    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell-notch"
    property string scheme: "scheme-smart"
    property real contrast: 0.5

    property string current: ""
    property string pending: ""
    property bool applying: false
    property bool ready: false

    function apply(path) {
        if (applying) return;
        pending = path;
        applying = true;
        proc.command = ["matugen", "--type", scheme, "--contrast", String(contrast), "image", path];
        proc.running = true;
    }

    Process {
        id: proc
        onExited: {
            root.applying = false;
            root.current = root.pending;
            if (root.ready) cur.setText(root.current);
        }
    }

    Process {
        command: ["mkdir", "-p", root.stateDir]
        running: true
        onExited: root.ready = true
    }

    FileView {
        id: cur
        path: root.ready ? root.stateDir + "/wallpaper.txt" : ""
        printErrors: false
        onLoaded: root.current = text().trim()
    }
}
