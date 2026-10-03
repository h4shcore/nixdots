import QtQuick
import Quickshell.Hyprland
import qs.common

// 5 workspaces per "page" (so a second monitor on 6-10 still shows 1-5 slots).
Item {
    id: root

    required property var screen

    readonly property int count: 5
    readonly property int cell: 22
    readonly property int gap: 4
    readonly property var mon: Hyprland.monitorFor(screen)
    readonly property int activeId: mon?.activeWorkspace?.id ?? 1
    readonly property int base: Math.floor((Math.max(1, activeId) - 1) / count) * count + 1
    readonly property int slot: Math.max(0, activeId - base)

    function occupied(id) {
        const v = Hyprland.workspaces.values;
        for (let i = 0; i < v.length; i++)
            if (v[i].id === id) return true;
        return false;
    }

    implicitWidth: count * cell + (count - 1) * gap
    implicitHeight: Theme.pillHeight - 10

    Row {
        spacing: root.gap
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: root.count

            Item {
                required property int index
                width: root.cell
                height: 10

                Rectangle {
                    anchors.centerIn: parent
                    width: 6
                    height: 6
                    radius: 3
                    color: root.occupied(root.base + parent.index) ? Theme.fg : Theme.outline
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }
    }

    // sliding active indicator
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: root.slot * (root.cell + root.gap)
        width: root.cell
        height: 8
        radius: 4
        color: Theme.primary

        Behavior on x { Anim {} }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: m => {
            const i = Math.max(0, Math.min(root.count - 1, Math.floor(m.x / (root.cell + root.gap))));
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + (root.base + i) + " })");
        }
        onWheel: w => Hyprland.dispatch(w.angleDelta.y > 0 ? 'hl.dsp.focus({ workspace = "e-1" })' : 'hl.dsp.focus({ workspace = "e+1" })')
    }
}
