pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Screenshots (grim) and screen recording (wf-recorder) with result notifications.
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
        if (recording) recProc.signal(2);     // SIGINT -> wf-recorder finalizes the file
        else cancel();
    }

    function cancel() {
        selecting = false;
        countdown = 0;
        pending = null;
        countTimer.stop();
        settleTimer.stop();
    }

    function finishRect(scr, x, y, w, h) {
        selecting = false;
        arm({ x: Math.round(scr.x + x), y: Math.round(scr.y + y), w: Math.round(w), h: Math.round(h), output: "" });
    }

    function finishWindow(c) {
        selecting = false;
        arm({ x: Math.round(c.x), y: Math.round(c.y), w: Math.round(c.w), h: Math.round(c.h), output: "" });
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
            shotProc.command = ["sh", "-c", "mkdir -p '" + shotDir + "' && grim " + where + " '" + f + "' && wl-copy < '" + f + "'"];
            shotProc.running = true;
        } else {
            const f = recDir + "/recording_" + stamp() + ".mp4";
            recPath = f;
            recProc.command = ["sh", "-c", "mkdir -p '" + recDir + "' && exec wf-recorder " + (audio ? "-a " : "") + where + " -f '" + f + "'"];
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
                if (root.target === "window") winProc.running = true;
                root.selecting = true;
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
        id: shotProc
        onExited: code => {
            if (code === 0) root.notify("Screenshot saved", root.shotPath.slice(root.shotPath.lastIndexOf("/") + 1) + "\nCopied to clipboard", root.shotPath);
            else root.notifyPlain("Screenshot failed", "grim/wl-copy exited with code " + code);
        }
    }

    Process {
        id: recProc
        onExited: code => {
            root.recording = false;
            elapsedTimer.stop();
            if (code === 0) root.notify("Recording saved", root.recPath.slice(root.recPath.lastIndexOf("/") + 1) + "\n" + root.fmt(root.elapsed), root.recPath);
            else root.notifyPlain("Recording stopped", "wf-recorder exited with code " + code);
        }
    }

    Process {
        id: winProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const scr = root.selectScreen;
                    const ws = Hyprland.monitorFor(scr)?.activeWorkspace?.id;
                    root.windows = JSON.parse(text)
                        .filter(c => c.mapped && !c.hidden && c.workspace && c.workspace.id === ws)
                        .sort((a, b) => a.focusHistoryID - b.focusHistoryID)
                        .map(c => ({ x: c.at[0], y: c.at[1], w: c.size[0], h: c.size[1], title: c.title }));
                } catch (err) {
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
        command: ["sh", "-c", "command -v wf-recorder >/dev/null"]
        running: true
        onExited: code => root.hasRec = code === 0
    }
}
