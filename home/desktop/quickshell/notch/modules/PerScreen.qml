import Quickshell
import qs.common

Scope {
    id: root

    required property var modelData

    Bar { screen: root.modelData }

    Exclusion { screen: root.modelData; edge: "top"; size: Theme.reserveTop }
    Exclusion { screen: root.modelData; edge: "bottom"; size: Theme.border }
    Exclusion { screen: root.modelData; edge: "left"; size: Theme.border }
    Exclusion { screen: root.modelData; edge: "right"; size: Theme.border }
}
