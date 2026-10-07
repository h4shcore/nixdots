import Quickshell
import qs.common

Scope {
    id: root

    required property var modelData

    Bar { screen: root.modelData }
    CaptureOverlay { screen: root.modelData }

    Exclusion { screen: root.modelData; edge: "top"; size: Look.reserveTop }
    Exclusion { screen: root.modelData; edge: "bottom"; size: Look.border }
    Exclusion { screen: root.modelData; edge: "left"; size: Look.border }
    Exclusion { screen: root.modelData; edge: "right"; size: Look.border }
}
