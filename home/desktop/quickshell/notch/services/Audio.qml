pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property string glyph: muted || volume <= 0 ? "\uf026" : volume < 0.5 ? "\uf027" : "\uf028"

    function setVolume(v) {
        if (!sink?.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    function toggleMute() {
        if (sink?.audio) sink.audio.muted = !sink.audio.muted;
    }

    PwObjectTracker { objects: [root.sink] }
}
