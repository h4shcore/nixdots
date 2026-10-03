pragma Singleton
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)
    readonly property string label: !enabled ? "Off"
        : connected.length === 0 ? "On"
        : connected.length === 1 ? connected[0].name
        : connected.length + " devices"

    function toggle() {
        if (adapter) adapter.enabled = !adapter.enabled;
    }
}
