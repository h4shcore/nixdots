pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Wifi state via nmcli (NetworkManager).
Singleton {
    id: root

    property bool enabled: false
    property string ssid: ""

    function refresh() {
        radioProc.running = true;
        ssidProc.running = true;
    }

    function toggle() {
        toggleProc.command = ["nmcli", "radio", "wifi", root.enabled ? "off" : "on"];
        toggleProc.running = true;
        root.enabled = !root.enabled;
    }

    Process {
        id: radioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.enabled = text.trim() === "enabled"
        }
    }

    Process {
        id: ssidProc
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID", "dev", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n").find(x => x.startsWith("yes:"));
                root.ssid = l ? l.slice(4).replace(/\\:/g, ":") : "";
            }
        }
    }

    Process {
        id: toggleProc
        onExited: settle.restart()
    }

    Timer {
        id: settle
        interval: 1200
        onTriggered: root.refresh()
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
