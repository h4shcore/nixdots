import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.common
import qs.services

Chip {
    id: root

    readonly property MprisPlayer p: Players.active

    visible: p !== null

    Icon {
        text: "\uf001"
        color: root.p?.isPlaying ? Theme.primary : Theme.fgDim
        Behavior on color { ColorAnimation { duration: 250 } }
    }
    Label {
        text: root.p ? (root.p.trackTitle || "Unknown") + (root.p.trackArtist ? "  ·  " + root.p.trackArtist : "") : ""
        Layout.maximumWidth: 170
    }
}
