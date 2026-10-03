pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ── colors: defaults below, overridden live by ~/.config/quickshell/colors.json (matugen) ──
    readonly property color surface: c.surface
    readonly property color surfaceHi: c.surfaceHi
    readonly property color surfaceHiest: c.surfaceHiest
    readonly property color fg: c.fg
    readonly property color fgDim: c.fgDim
    readonly property color primary: c.primary
    readonly property color primaryFg: c.primaryFg
    readonly property color secondaryContainer: c.secondaryContainer
    readonly property color error: c.error
    readonly property color outline: c.outline

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/colors.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        adapter: JsonAdapter {
            id: c
            property string surface: "#141318"
            property string surfaceHi: "#2b292f"
            property string surfaceHiest: "#36343a"
            property string fg: "#e6e0e9"
            property string fgDim: "#938f99"
            property string primary: "#d0bcff"
            property string primaryFg: "#381e72"
            property string secondaryContainer: "#4a4458"
            property string error: "#f2b8b5"
            property string outline: "#49454f"
        }
    }

    // ── sizing ──
    readonly property int pillHeight: 38
    readonly property int gap: 8
    readonly property int pad: 16
    readonly property int panelRadius: 28
    readonly property int border: 4            // screen border thickness
    readonly property int borderRadius: 18     // inner corner radius of the screen border
    readonly property int earRadius: 10        // concave corners where the notch meets the top border
    readonly property int notchRadius: 16      // notch bottom corner radius
    readonly property int reserveTop: pillHeight   // space tiled windows leave at the top (set to pillHeight so the notch never overlaps them)

    // ── fonts (Nerd Font gives the icon glyphs too) ──
    readonly property string font: "Maple Mono NF"

    // ── motion (curves are the M3-expressive ones caelestia uses) ──
    readonly property var spring: [0.38, 1.21, 0.22, 1.0, 1, 1]
    readonly property var standard: [0.2, 0, 0, 1, 1, 1]
    readonly property var emphasized: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
    readonly property var dur: ({ fast: 180, normal: 400, slow: 650 })
}
