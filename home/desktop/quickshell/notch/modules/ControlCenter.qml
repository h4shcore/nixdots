import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

// The hover-expanded control center, bento style:
//   [ 2x2 toggle tiles ][ vol ][ bri ]
//   [ now-playing card                ]
//   [ shortcut strip                  ]
// `shown` drives the staggered reveal.
Item {
    id: root

    property bool shown: false
    readonly property bool busy: vol.pressed || bri.pressed || media.busy
    signal openNotifs

    implicitWidth: 420
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 10

        // ── toggles + vertical sliders ──
        Reveal {
            Layout.fillWidth: true
            shown: root.shown
            delay: 0

            RowLayout {
                width: parent.width
                height: 170
                spacing: 10

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10

                    Tile {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        glyph: "\uf1eb"
                        title: "Wi-Fi"
                        subtitle: !Network.enabled ? "Off" : (Network.ssid || "Not connected")
                        on: Network.enabled
                        onClicked: Network.toggle()
                    }
                    Tile {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: Bt.available
                        glyph: "\uf293"
                        title: "Bluetooth"
                        subtitle: Bt.label
                        on: Bt.enabled
                        onClicked: Bt.toggle()
                    }
                    Tile {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        glyph: Notifs.dnd ? "\uf1f6" : "\uf0f3"
                        title: "Focus"
                        subtitle: Notifs.dnd ? "Muted" : "Off"
                        on: Notifs.dnd
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }
                    Tile {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.columnSpan: Bt.available ? 1 : 2
                        glyph: "\uf086"
                        title: "Inbox"
                        subtitle: Notifs.count > 0 ? Notifs.count + " new" : "All clear"
                        on: Notifs.count > 0
                        onClicked: root.openNotifs()
                    }
                }

                VSlider {
                    id: vol
                    Layout.fillHeight: true
                    glyph: Audio.glyph
                    value: Audio.muted ? 0 : Audio.volume
                    onMoved: v => Audio.setVolume(v)
                    onIconClicked: Audio.toggleMute()
                }

                VSlider {
                    id: bri
                    Layout.fillHeight: true
                    visible: Brightness.available
                    glyph: "\uf185"
                    value: Brightness.value
                    onMoved: v => Brightness.set(v)
                }
            }
        }

        // ── now playing ──
        Reveal {
            Layout.fillWidth: true
            visible: Players.active !== null
            shown: root.shown
            delay: 50

            MediaCard {
                id: media
                width: parent.width
            }
        }

        // ── shortcuts into the bottom docks ──
        Reveal {
            Layout.fillWidth: true
            shown: root.shown
            delay: 100

            Rectangle {
                width: parent.width
                height: 48
                radius: 24
                color: Look.surfaceHi

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 0

                    Repeater {
                        model: [
                            { g: "\uf009", m: "apps" },
                            { g: "\uf0ea", m: "clip" },
                            { g: "\uf03e", m: "wall" },
                            { g: "\uf030", m: "cap" },
                            { g: "power_settings_new", m: "power" }
                        ]

                        Item {
                            required property var modelData

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            IconButton {
                                anchors.centerIn: parent
                                size: 38
                                glyph: parent.modelData.g
                                primary: LauncherState.open && LauncherState.mode === parent.modelData.m
                                onClicked: LauncherState.toggleMode(parent.modelData.m)
                            }
                        }
                    }
                }
            }
        }
    }
}
