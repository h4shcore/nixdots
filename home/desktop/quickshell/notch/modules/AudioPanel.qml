import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services

PickerPanel {
    id: root

    title: "Sound"
    icon: "volume_up"
    subtitle: Audio.label(Audio.sink)

    function outIcon(n) {
        const s = Audio.label(n) + " " + (n?.name ?? "");
        return /headphone|headset|bluez|buds/i.test(s) ? "headphones" : /hdmi|display|dp|monitor/i.test(s) ? "tv" : "speaker";
    }

    Label {
        text: "OUTPUT"
        color: Look.fgDim
        font.pixelSize: 10
        font.bold: true
        font.letterSpacing: 1
        Layout.leftMargin: 6
    }

    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 4 * 48)
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: ScriptModel { values: Audio.sinks }

        delegate: PickerRow {
            required property var modelData

            width: ListView.view.width
            glyph: root.outIcon(modelData)
            title: Audio.label(modelData)
            subtitle: active ? "In use" : ""
            active: Audio.sink === modelData
            onClicked: Audio.setSink(modelData)
        }
    }

    Label {
        text: "INPUT"
        color: Look.fgDim
        font.pixelSize: 10
        font.bold: true
        font.letterSpacing: 1
        Layout.leftMargin: 6
        Layout.topMargin: 4
    }

    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 3 * 48)
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: ScriptModel { values: Audio.sources }

        delegate: PickerRow {
            required property var modelData

            width: ListView.view.width
            glyph: "mic"
            title: Audio.label(modelData)
            subtitle: active ? "In use" : ""
            active: Audio.source === modelData
            onClicked: Audio.setSource(modelData)
        }
    }

    FatSlider {
        Layout.fillWidth: true
        Layout.topMargin: 4
        glyph: Audio.micMuted ? "mic_off" : "mic"
        value: Audio.micMuted ? 0 : Audio.micVolume
        onMoved: v => Audio.setMicVolume(v)
        onIconClicked: Audio.toggleMicMute()
    }
}
