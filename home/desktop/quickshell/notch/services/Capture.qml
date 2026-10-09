pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Screenshots (grim) and screen recording (wl-screenrec) with result notifications.
// Output: ~/Pictures/Screenshots and ~/Videos/Recordings. Screenshots are also copied to the clipboard.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string shotDir: home + "/Pictures/Screenshots"
    readonly property string recDir: home + "/Videos/Recordings"

    // options (set by the dock)
    property string kind: "shot"        // shot | record
    property string target: "region"    // region | window | screen
    property int delay: 0
    property bool audio: false
    property bool softwareEncode: false     // true -> pass --no-hw (no VAAPI hardware encoder available)

    // runtime
    property bool selecting: false
    property var selectScreen: null
    property var windows: []            // window mode: [{ x, y, w, h, title }] in global logical px
    property var pending: null          // { x, y, w, h, output }
    property int countdown: 0
    property bool recording: false
    property int elapsed: 0
    property string shotPath: ""
    property string recPath: ""
    property bool hasGrim: true
    property bool hasRec: true

    // single-window screenshots go through a toplevel grab (see WindowGrabber.qml)
    property var grabToplevel: null
    property bool grabbing: false
    property string shotWhere: ""

    // frozen frame shown behind the selector (taken with grim before the overlay appears)
    property string freezePath: ""
    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"

    function dropFreeze() {
        if (freezePath !== "") Quickshell.execDetached(["rm", "-f", freezePath]);
        freezePath = "";
    }

    function fmt(s) {
        s = Math.max(0, Math.floor(s || 0));
        return String(Math.floor(s / 60)).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0");
    }

    function focusScreen() {
        return Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
    }

    function stamp() { return Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss"); }
    function dirOf(p) { return p.slice(0, p.lastIndexOf("/")); }
    function open(path) { Quickshell.execDetached(["xdg-open", path]); }

    // one-shot entry point for keybinds
    function start(k, t) {
        if (k === "record" && recording) {
            stop();
            return;
        }
        kind = k;
        target = t;
        go();
    }

    function go() {
        LauncherState.hide();
        if (kind === "record" && recording) {
            stop();
            return;
        }
        if (selecting || countdown > 0) return;
        launchTimer.restart();     // let the dock finish closing before we look at the screen
    }

    function stop() {
        if (recording) recProc.signal(2);     // SIGINT -> wl-screenrec finalizes the file
        else cancel();
    }

    function cancel() {
        selecting = false;
        dropFreeze();
        countdown = 0;
        pending = null;
        countTimer.stop();
        settleTimer.stop();
    }

    function finishRect(scr, x, y, w, h) {
        selecting = false;
        dropFreeze();
        arm({ x: Math.round(scr.x + x), y: Math.round(scr.y + y), w: Math.round(w), h: Math.round(h), output: "" });
    }

    function finishWindow(c) {
        selecting = false;
        dropFreeze();
        arm({ x: Math.round(c.x), y: Math.round(c.y), w: Math.round(c.w), h: Math.round(c.h), output: "", address: c.address });
    }

    function toplevelFor(address) {
        const a = String(address).replace(/^0x/, "");
        const t = Hyprland.toplevels.values.find(x => String(x.address).replace(/^0x/, "") === a);
        return t ? t.wayland : null;
    }

    function runShot() {
        shotProc.command = ["sh", "-c", "mkdir -p '" + shotDir + "' && grim " + shotWhere + " '" + shotPath + "' && wl-copy < '" + shotPath + "'"];
        shotProc.running = true;
    }

    // called by WindowGrabber; falls back to a plain region grab if the window grab failed
    function grabbed(ok) {
        if (!grabbing) return;
        grabTimeout.stop();
        grabbing = false;
        grabToplevel = null;
        if (ok) {
            clipProc.command = ["sh", "-c", "wl-copy < '" + shotPath + "'"];
            clipProc.running = true;
            notify("Screenshot saved", shotPath.slice(shotPath.lastIndexOf("/") + 1) + "\nCopied to clipboard", shotPath);
        } else {
            runShot();
        }
    }

    function arm(p) {
        pending = p;
        if (delay > 0) {
            countdown = delay;
            countTimer.restart();
        } else {
            settleTimer.restart();      // give the overlay a moment to disappear
        }
    }

    function fire() {
        const p = pending;
        pending = null;
        if (!p) return;

        let w = p.w, h = p.h;
        if (kind === "record") {      // h264 wants even dimensions
            w -= w % 2;
            h -= h % 2;
        }
        const where = p.output !== "" ? "-o '" + p.output + "'" : "-g '" + p.x + "," + p.y + " " + w + "x" + h + "'";

        if (kind === "shot") {
            const f = shotDir + "/screenshot_" + stamp() + ".png";
            shotPath = f;
            shotWhere = where;
            if (p.address) {
                const tl = toplevelFor(p.address);
                if (tl) {
                    grabToplevel = tl;
                    grabbing = true;
                    grabTimeout.restart();
                    return;
                }
            }
            runShot();
        } else {
            const f = recDir + "/recording_" + stamp() + ".mp4";
            recPath = f;
            recProc.command = ["sh", "-c", "mkdir -p '" + recDir + "' && exec wl-screenrec " + (audio ? "--audio " : "") + (softwareEncode ? "--no-hw " : "") + where + " -f '" + f + "'"];
            recProc.running = true;
            elapsed = 0;
            recording = true;
            elapsedTimer.restart();
        }
    }

    // ── notifications (go through our own notification server) ──
    function notify(title, body, path) {
        notifyComp.createObject(root, {
            command: ["notify-send", "-a", "Capture", "-i", path, "-A", "open=Open", "-A", "folder=Show in folder", "-w", title, body],
            target: path
        });
    }

    function notifyPlain(title, body) {
        Quickshell.execDetached(["notify-send", "-a", "Capture", title, body]);
    }

    Component {
        id: notifyComp

        Process {
            id: np

            required property string target

            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    const a = text.trim();
                    if (a === "open") root.open(np.target);
                    else if (a === "folder") root.open(root.dirOf(np.target));
                }
            }
            onExited: np.destroy()
        }
    }

    // ── processes / timers ──
    Timer {
        id: launchTimer
        interval: 380
        onTriggered: {
            const scr = root.focusScreen();
            root.selectScreen = scr;
            if (root.target === "screen") {
                root.arm({ x: 0, y: 0, w: 0, h: 0, output: scr.name });
            } else {
                if (root.target === "window") {
                    root.windows = [];
                    Hyprland.refreshToplevels();
                    winProc.running = true;
                }
                root.freezePath = root.runtimeDir + "/notch-freeze-" + root.stamp() + ".png";
                freezeProc.command = ["grim", "-o", scr.name, root.freezePath];
                freezeProc.running = true;
            }
        }
    }
    Timer {
        id: settleTimer
        interval: 220
        onTriggered: root.fire()
    }
    Timer {
        id: countTimer
        interval: 1000
        repeat: true
        onTriggered: {
            root.countdown--;
            if (root.countdown <= 0) {
                countTimer.stop();
                root.fire();
            }
        }
    }
    Timer {
        id: elapsedTimer
        interval: 1000
        repeat: true
        onTriggered: root.elapsed++
    }

    Process {
        id: freezeProc
        onExited: code => {
            if (code !== 0) root.freezePath = "";     // no freeze frame: overlay just dims the live screen
            root.selecting = true;
        }
    }

    Timer {
        id: grabTimeout
        interval: 3500
        onTriggered: root.grabbed(false)
    }

    Process { id: clipProc }

    Process {
        command: ["mkdir", "-p", root.shotDir, root.recDir]
        running: true
    }

    Process {
        id: shotProc
        onExited: code => {
            if (code === 0) root.notify("Screenshot saved", root.shotPath.slice(root.shotPath.lastIndexOf("/") + 1) + "\nCopied to clipboard", root.shotPath);
            else root.notifyPlain("Screenshot failed", "grim/wl-copy exited with code " + code);
        }
    }

    // exit codes after a Ctrl-C stop vary between recorders, so judge success by whether the file exists
    Process {
        id: recProc
        onExited: code => {
            root.recording = false;
            elapsedTimer.stop();
            statProc.command = ["test", "-s", root.recPath];
            statProc.running = true;
        }
    }

    Process {
        id: statProc
        onExited: code => {
            if (code === 0) root.notify("Recording saved", root.recPath.slice(root.recPath.lastIndexOf("/") + 1) + "\n" + root.fmt(root.elapsed), root.recPath);
            else root.notifyPlain("Recording failed", "wl-screenrec didn't produce a file (try softwareEncode: true if you have no VAAPI encoder)");
        }
    }

    // windows on the focused monitor: its active workspace + its open special workspace (on top)
    Process {
        id: winProc
        command: ["sh", "-c", "hyprctl -j monitors; echo '@@@'; hyprctl -j clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parts = text.split("@@@");
                    const mons = JSON.parse(parts[0]);
                    const clients = JSON.parse(parts[1]);
                    const scr = root.selectScreen;
                    const mon = mons.find(m => m.name === scr.name);
                    const ws = mon ? mon.activeWorkspace.id : -1;
                    const sp = mon && mon.specialWorkspace ? mon.specialWorkspace.id : 0;
                    const onSpecial = c => sp !== 0 && c.workspace.id === sp;

                    root.windows = clients
                        .filter(c => c.mapped && !c.hidden && c.workspace && (c.workspace.id === ws || onSpecial(c)))
                        .filter(c => c.at[0] < scr.x + scr.width && c.at[0] + c.size[0] > scr.x
                                  && c.at[1] < scr.y + scr.height && c.at[1] + c.size[1] > scr.y)
                        .sort((a, b) => (onSpecial(b) - onSpecial(a)) || (b.floating - a.floating) || (a.focusHistoryID - b.focusHistoryID))
                        .map(c => ({ x: c.at[0], y: c.at[1], w: c.size[0], h: c.size[1], title: c.title || c["class"], address: c.address }));
                } catch (err) {
                    console.warn("Capture: could not read windows:", err);
                    root.windows = [];
                }
            }
        }
    }

    Process {
        command: ["sh", "-c", "command -v grim >/dev/null"]
        running: true
        onExited: code => root.hasGrim = code === 0
    }
    Process {
        command: ["sh", "-c", "command -v wl-screenrec >/dev/null"]
        running: true
        onExited: code => root.hasRec = code === 0
    }
}
