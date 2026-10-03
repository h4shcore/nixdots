import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common
import qs.services

// Toast popups, top-right on the focused monitor.
PanelWindow {
    id: win

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    anchors {
        top: true
        right: true
    }
    margins {
        top: Theme.border + Theme.gap
        right: Theme.border + Theme.gap
    }
    implicitWidth: 372
    implicitHeight: 700
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "notch-popups"
    WlrLayershell.layer: WlrLayer.Overlay

    mask: Region { item: list }

    ListView {
        id: list
        width: parent.width
        height: contentHeight
        spacing: 8
        interactive: false
        model: ScriptModel { values: [...Notifs.popups] }

        delegate: NotifCard {
            required property var modelData
            width: ListView.view.width
            entry: modelData
        }

        add: Transition {
            ParallelAnimation {
                Anim { property: "x"; from: win.width; to: 0 }
                Anim { property: "opacity"; from: 0; to: 1; curve: Theme.standard; duration: 200 }
            }
        }
        remove: Transition {
            ParallelAnimation {
                Anim { property: "x"; to: win.width; curve: Theme.emphasized; duration: 350 }
                Anim { property: "opacity"; to: 0; curve: Theme.standard; duration: 250 }
            }
        }
        displaced: Transition {
            Anim { property: "y" }
        }
    }
}
