pragma Singleton
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property list<MprisPlayer> list: Mpris.players.values
    // prefer whichever player is actually playing, else the first one
    readonly property MprisPlayer active: list.find(p => p.isPlaying) ?? list[0] ?? null
}
