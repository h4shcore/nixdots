pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history on top of cliphist + wl-clipboard.
// Starts the wl-paste watchers itself unless some are already running (e.g. in your autostart).
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string stateDir: home + "/.local/state/quickshell-notch"
    readonly property string cacheDir: home + "/.cache/quickshell-notch/clip"

    property bool ready: false
    property bool available: true
    property var entries: []            // [{ id, preview, isImage }]
    property int thumbRev: 0

    // pinned ids, persisted as a JSON string: { "<id>": true }
    readonly property var pinned: {
        try { return JSON.parse(store.adapter.json || "{}"); }
        catch (err) { return {}; }
    }

    function thumbUrl(id) { return "file://" + cacheDir + "/" + id + ".png#" + thumbRev; }

    function parse(text) {
        const out = [];
        for (const line of text.split("\n")) {
            if (!line) continue;
            const tab = line.indexOf("\t");
            if (tab < 0) continue;
            const preview = line.slice(tab + 1);
            out.push({ id: line.slice(0, tab), preview: preview, isImage: preview.startsWith("[[ binary data") });
        }
        return out.slice(0, 200);
    }

    function refresh() {
        if (available && !listProc.running) listProc.running = true;
    }

    function search(query) {
        try {
            const q = (query ?? "").trim().toLowerCase();
            const out = [];
            for (const e of entries) {
                if (q !== "" && !(e.isImage ? "image" : e.preview.toLowerCase()).includes(q)) continue;
                out.push({ id: e.id, preview: e.preview, isImage: e.isImage, pinned: !!pinned[e.id] });
            }
            out.sort((a, b) => (b.pinned ? 1 : 0) - (a.pinned ? 1 : 0));
            return out.slice(0, 80);
        } catch (err) {
            console.warn("Clip.search failed:", err);
            return [];
        }
    }

    function copy(id, paste) {
        if (!/^\d+$/.test(id)) return;
        copyProc.command = ["sh", "-c", "cliphist decode " + id + " | wl-copy" + (paste ? "; sleep 0.12; wtype -M ctrl v -m ctrl" : "")];
        copyProc.running = true;
    }

    function remove(id) {
        if (!/^\d+$/.test(id)) return;
        entries = entries.filter(e => e.id !== id);
        delProc.command = ["sh", "-c", "printf '%s\\tx\\n' " + id + " | cliphist delete"];
        delProc.running = true;
    }

    function wipe() {
        entries = [];
        wipeProc.running = true;
    }

    function togglePin(id) {
        const p = Object.assign({}, pinned);
        if (p[id]) delete p[id];
        else p[id] = true;
        store.adapter.json = JSON.stringify(p);
        if (ready) store.writeAdapter();
    }

    function makeThumbs() {
        const ids = entries.filter(e => e.isImage).slice(0, 40).map(e => e.id);
        if (ids.length === 0 || thumbProc.running) return;
        thumbProc.command = ["sh", "-c",
            "d='" + cacheDir + "'; for id in " + ids.join(" ") + "; do [ -s \"$d/$id.png\" ] || cliphist decode \"$id\" > \"$d/$id.png\"; done"];
        thumbProc.running = true;
    }

    // ── setup ──
    Process {
        command: ["mkdir", "-p", root.stateDir, root.cacheDir]
        running: true
        onExited: {
            root.ready = true;
            availProc.running = true;
        }
    }
    Process {
        id: availProc
        command: ["sh", "-c", "command -v cliphist >/dev/null && command -v wl-paste >/dev/null"]
        onExited: code => {
            root.available = code === 0;
            if (root.available) watchCheck.running = true;
        }
    }
    // the [e] keeps this pgrep from matching its own command line
    Process {
        id: watchCheck
        command: ["sh", "-c", "pgrep -f 'wl-paste.*--watch cliphist stor[e]' >/dev/null"]
        onExited: code => {
            if (code !== 0) {
                textWatch.running = true;
                imgWatch.running = true;
            }
        }
    }
    Process {
        id: textWatch
        command: ["wl-paste", "--type", "text", "--watch", "cliphist", "store"]
    }
    Process {
        id: imgWatch
        command: ["wl-paste", "--type", "image", "--watch", "cliphist", "store"]
    }

    // ── data ──
    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = root.parse(text);
                root.makeThumbs();
            }
        }
    }
    Process {
        id: thumbProc
        onExited: root.thumbRev++
    }
    Process { id: copyProc }
    Process {
        id: delProc
        onExited: root.refresh()
    }
    Process {
        id: wipeProc
        command: ["cliphist", "wipe"]
    }

    FileView {
        id: store
        path: root.ready ? root.stateDir + "/clip-pins.json" : ""
        printErrors: false
        adapter: JsonAdapter {
            property string json: "{}"
        }
    }
}
