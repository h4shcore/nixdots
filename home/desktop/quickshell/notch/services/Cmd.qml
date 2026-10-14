pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Launcher command mode (">"): run shell commands in a terminal (or silently), with persisted history.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.local/state/quickshell-notch"
    property bool ready: false

    // history is stored as a JSON string: ["cmd", ...] newest first
    readonly property var history: {
        try { return JSON.parse(store.adapter.json || "[]"); }
        catch (err) { return []; }
    }

    // opens $TERMINAL (or the first terminal found), runs the command, waits for Enter before closing
    readonly property string termScript: [
        'cmd="$1"',
        't="${TERMINAL:-}"',
        'if [ -z "$t" ] || ! command -v "$t" >/dev/null 2>&1; then',
        '  t=; for c in foot kitty alacritty ghostty wezterm xterm; do command -v "$c" >/dev/null 2>&1 && { t=$c; break; }; done',
        'fi',
        '[ -n "$t" ] || exit 1',
        'inner=\'( eval "$0" ); ec=$?; printf "\\n[exit %s] press Enter to close " "$ec"; read _\'',
        'case "$(basename "$t")" in',
        '  wezterm) exec "$t" start -- sh -c "$inner" "$cmd" ;;',
        '  kitty) exec "$t" sh -c "$inner" "$cmd" ;;',
        '  *) exec "$t" -e sh -c "$inner" "$cmd" ;;',
        'esac'
    ].join("\n")

    function rows(query) {
        const c = (query ?? "").trim();
        const q = c.toLowerCase();
        const out = [];
        if (c !== "")
            out.push({ id: "cmd:new", kind: "cmd", title: c, subtitle: "Run in terminal  ·  Ctrl+Enter in background", text: c });
        history.forEach((h, i) => {
            if (h === c) return;
            if (q !== "" && !h.toLowerCase().includes(q)) return;
            out.push({ id: "cmd:h" + i, kind: "cmd", title: h, subtitle: "Recent", text: h });
        });
        return out.slice(0, 40);
    }

    function remember(cmd) {
        const h = history.filter(x => x !== cmd);
        h.unshift(cmd);
        store.adapter.json = JSON.stringify(h.slice(0, 30));
        if (ready) store.writeAdapter();
    }

    function run(cmd, inTerminal) {
        cmd = (cmd ?? "").trim();
        if (cmd === "") return;
        remember(cmd);
        if (inTerminal) Quickshell.execDetached(["sh", "-c", termScript, "qs-cmd", cmd]);
        else Quickshell.execDetached(["sh", "-c", cmd]);
    }

    Process {
        command: ["mkdir", "-p", root.dir]
        running: true
        onExited: root.ready = true
    }

    FileView {
        id: store
        path: root.ready ? root.dir + "/cmds.json" : ""
        printErrors: false
        adapter: JsonAdapter {
            property string json: "[]"
        }
    }
}
