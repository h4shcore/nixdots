import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services

PickerPanel {
    id: root

    title: "Bluetooth"
    icon: "bluetooth"
    subtitle: !Bt.enabled ? "Off" : (Bt.adapter?.discovering ? "Searching…" : Bt.label)

    headerRight: Pill {
        implicitHeight: 30
        text: Bt.enabled ? "On" : "Off"
        selected: Bt.enabled
        onClicked: Bt.toggle()
    }

    // scan only while this panel is open
    onVisibleChanged: if (Bt.adapter) Bt.adapter.discovering = visible && Bt.enabled

    Label {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 10
        Layout.bottomMargin: 10
        visible: !Bt.enabled || Bt.sorted.length === 0
        text: !Bt.enabled ? "Bluetooth is off" : "No devices yet — make sure your device is in pairing mode"
        color: Look.fgDim
        font.pixelSize: 12
    }

    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 288)
        visible: Bt.enabled && Bt.sorted.length > 0
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: ScriptModel { values: Bt.sorted }

        delegate: PickerRow {
            id: row

            required property var modelData

            width: ListView.view.width
            glyph: Bt.iconFor(modelData)
            title: modelData.name
            subtitle: modelData.connected ? "Connected" : (modelData.pairing ? "Pairing…" : (modelData.paired ? "Paired" : "Available"))
            active: modelData.connected
            onClicked: Bt.activate(modelData)

            Label {
                visible: modelData.batteryAvailable ?? false
                text: Math.round((modelData.battery ?? 0) <= 1 ? (modelData.battery ?? 0) * 100 : modelData.battery) + "%"
                color: Look.fgDim
                font.pixelSize: 11
            }
            IconButton {
                visible: modelData.paired && !modelData.connected
                size: 28
                glyph: "delete"
                onClicked: modelData.forget()
            }
        }
    }
}
