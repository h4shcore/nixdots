import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

Item {
    id: root

    implicitWidth: 300
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            IconButton {
                glyph: Audio.glyph
                onClicked: Audio.toggleMute()
            }
            Slider {
                Layout.fillWidth: true
                value: Audio.muted ? 0 : Audio.volume
                onMoved: v => Audio.setVolume(v)
            }
            Label {
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignRight
                text: Math.round(Audio.volume * 100) + "%"
                color: Theme.fgDim
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: Brightness.available

            IconButton {
                glyph: "\uf185"
                enabled: false
                opacity: 1
            }
            Slider {
                Layout.fillWidth: true
                value: Brightness.value
                onMoved: v => Brightness.set(v)
            }
            Label {
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignRight
                text: Math.round(Brightness.value * 100) + "%"
                color: Theme.fgDim
            }
        }
    }
}
