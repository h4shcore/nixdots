import Quickshell
import Quickshell.Wayland

// Invisible strip whose only job is reserving screen space on one edge.
PanelWindow {
    id: root

    required property string edge
    required property int size

    readonly property bool horiz: edge === "top" || edge === "bottom"

    anchors {
        top: root.edge !== "bottom"
        bottom: root.edge !== "top"
        left: root.edge !== "right"
        right: root.edge !== "left"
    }
    implicitWidth: horiz ? 1 : size
    implicitHeight: horiz ? size : 1
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: size
    color: "transparent"
    mask: Region {}
    WlrLayershell.namespace: "notch-exclusion"
    WlrLayershell.layer: WlrLayer.Background
}
