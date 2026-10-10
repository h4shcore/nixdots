pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Niri integration: focused output, workspaces, actions. Refreshed on every niri event.
Singleton {
    id: root

    property string focusedOutput: ""
    property var workspaces: []     // [{ id, idx, name, output, is_active, is_focused, active_window_id }]

    readonly property var logoutCmd: ["niri", "msg", "action", "quit", "--skip-confirmation"]

    function action(args) {
        Quickshell.execDetached(["niri", "msg", "action"].concat(args));
    }

    function refresh() {
        if (!wsProc.running) wsProc.running = true;
        if (!outProc.running) outProc.running = true;
    }

    Process {
        id: wsProc
        command: ["niri", "msg", "--json", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.workspaces = JSON.parse(text); } catch (err) {}
            }
        }
    }

    Process {
        id: outProc
        command: ["niri", "msg", "--json", "focused-output"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const o = JSON.parse(text);
                    root.focusedOutput = o ? o.name : "";
                } catch (err) {}
            }
        }
    }

    // any niri event -> refresh (debounced)
    Process {
        running: true
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: line => debounce.restart()
        }
    }

    Timer {
        id: debounce
        interval: 50
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
