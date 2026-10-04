pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Desktop entries + usage tracking. Ranking = fuzzy match quality + "frecency"
// (launch count that decays with a ~14 day half-life), persisted across restarts.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.local/state/quickshell-notch"
    property bool ready: false

    // usage is stored as a JSON string: { "<desktop-entry id>": { count, last } }
    readonly property var usage: {
        try { return JSON.parse(store.adapter.json || "{}"); }
        catch (err) { return {}; }
    }
    readonly property var apps: DesktopEntries.applications.values.filter(e => !e.noDisplay)

    function frecency(e) {
        const u = usage[e.id];
        if (!u) return 0;
        const days = (Date.now() - u.last) / 86400000;
        return u.count * Math.pow(0.5, days / 14);
    }

    // 0 = no match, higher = better
    function match(e, q) {
        const name = (e.name ?? "").toLowerCase();
        if (name === q) return 100;
        if (name.startsWith(q)) return 90;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 75;
        if (name.includes(q)) return 60;
        const extra = ((e.genericName ?? "") + " " + String(e.keywords ?? "") + " " + (e.comment ?? "")).toLowerCase();
        if (extra.includes(q)) return 40;
        let i = 0;
        for (const c of name) {
            if (c === q[i]) i++;
            if (i === q.length) return 25;
        }
        return 0;
    }

    function search(query) {
        try {
            const q = (query ?? "").trim().toLowerCase();
            const out = [];
            for (const e of apps) {
                const f = frecency(e);
                let s;
                if (q === "") {
                    s = f;
                } else {
                    const m = match(e, q);
                    if (m === 0) continue;
                    s = m * 10 + Math.min(f, 20);
                }
                out.push({ id: e.id, entry: e, uses: usage[e.id]?.count ?? 0, score: s });
            }
            out.sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name));
            return out.slice(0, 60);
        } catch (err) {
            console.warn("Apps.search failed:", err);
            return [];
        }
    }

    function launch(e) {
        const u = Object.assign({}, usage);
        const cur = u[e.id] ?? { count: 0, last: 0 };
        u[e.id] = { count: cur.count + 1, last: Date.now() };
        store.adapter.json = JSON.stringify(u);
        if (ready) store.writeAdapter();
        e.execute();
    }

    Process {
        command: ["mkdir", "-p", root.dir]
        running: true
        onExited: root.ready = true
    }

    FileView {
        id: store
        path: root.ready ? root.dir + "/usage.json" : ""
        printErrors: false
        adapter: JsonAdapter {
            property string json: "{}"
        }
    }
}
