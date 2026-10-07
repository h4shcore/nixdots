import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

// The hover-expanded control center. `shown` drives the staggered reveal.
Item {
    id: root

    property bool shown: false
    readonly property bool busy: vol.pressed || bri.pressed || media.busy

    implicitWidth: 360
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 10

        Reveal {
            Layout.fillWidth: true
            shown: root.shown
            delay: 0

            RowLayout {
                width: parent.width
                spacing: 10

                Tile {
                    Layout.fillWidth: true
                    glyph: "\uf1eb"
                    title: "Wi-Fi"
                    subtitle: !Network.enabled ? "Off" : (Network.ssid || "Not connected")
                    on: Network.enabled
                    onClicked: Network.toggle()
                }
                Tile {
                    Layout.fillWidth: true
                    visible: Bt.available
                    glyph: "\uf293"
                    title: "Bluetooth"
                    subtitle: Bt.label
                    on: Bt.enabled
                    onClicked: Bt.toggle()
                }
            }
        }

        Reveal {
            Layout.fillWidth: true
            shown: root.shown
            delay: 50

            FatSlider {
                id: vol
                width: parent.width
                glyph: Audio.glyph
                value: Audio.muted ? 0 : Audio.volume
                onMoved: v => Audio.setVolume(v)
                onIconClicked: Audio.toggleMute()
            }
        }

        Reveal {
            Layout.fillWidth: true
            visible: Brightness.available
            shown: root.shown
            delay: 100

            FatSlider {
                id: bri
                width: parent.width
                glyph: "\uf185"
                value: Brightness.value
                onMoved: v => Brightness.set(v)
            }
        }

        Reveal {
            Layout.fillWidth: true
            visible: Battery.present
            shown: root.shown
            delay: 125

            ColumnLayout {
                width: parent.width
                spacing: 4

                FatSlider {
                    Layout.fillWidth: true
                    readOnly: true
                    glyph: Battery.icon
                    value: Battery.percent / 100
                    fill: Battery.low ? Look.error : Look.primary
                    fillFg: Battery.low ? Look.surface : Look.primaryFg
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    Layout.rightMargin: 14
                    visible: text !== ""
                    text: Battery.eta
                    color: Look.fgDim
                    font.pixelSize: 11
                }
            }
        }

        Reveal {
            Layout.fillWidth: true
            visible: Players.active !== null
            shown: root.shown
            delay: 150

            MediaCard {
                id: media
                width: parent.width
            }
        }
    }
}
