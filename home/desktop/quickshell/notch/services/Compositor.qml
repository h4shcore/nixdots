pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Thin compositor adapter: this config runs on Niri and on Hyprland (auto-detected from the environment).
Singleton {
    id: root

    readonly property bool niri: !!Quickshell.env("NIRI_SOCKET")
    readonly property bool hyprland: !niri
    readonly property string name: niri ? "niri" : "hyprland"

    // niri state, refreshed on every niri event
    property string niriFocused: ""
    property var niriWorkspaces: []     // [{ id, idx, name, output, is_active, is_focused, active_window_id }]

    // name of the output (monitor) that currently has focus
    readonly property string focusedOutput: niri ? niriFocused : (Hyprland.focusedMonitor?.name ?? "")

    readonly property var logoutCmd: niri ? ["niri", "msg", "action", "quit", "--skip-confirmation"] : ["uwsm", "stop"]

    function niriAction(args) {
        Quickshell.execDetached(["niri", "msg", "action"].concat(args));
    }

    function niriRefresh() {
        if (!niri) return;
        if (!wsProc.running) wsProc.running = true;
        if (!outProc.running) outProc.running = true;
    }

    Process {
        id: wsProc
        command: ["niri", "msg", "--json", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.niriWorkspaces = JSON.parse(text); } catch (err) {}
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
                    root.niriFocused = o ? o.name : "";
                } catch (err) {}
            }
        }
    }

    // any niri event -> refresh (debounced)
    Process {
        running: root.niri
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: line => debounce.restart()
        }
    }

    Timer {
        id: debounce
        interval: 50
        onTriggered: root.niriRefresh()
    }

    Component.onCompleted: niriRefresh()
}
