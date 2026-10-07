pragma Singleton
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property bool present: dev?.isPresent ?? false

    // UPower reports 0..1 (guard in case a build reports 0..100)
    readonly property real percent: {
        const p = dev?.percentage ?? 0;
        return Math.max(0, Math.min(100, p <= 1 ? p * 100 : p));
    }
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging
    readonly property bool full: dev?.state === UPowerDeviceState.FullyCharged
    readonly property bool low: present && !charging && !full && percent <= 20

    readonly property string icon: {
        if (charging) return "battery_charging_full";
        const p = percent;
        if (p >= 90) return "battery_full";
        if (p >= 75) return "battery_6_bar";
        if (p >= 60) return "battery_5_bar";
        if (p >= 45) return "battery_4_bar";
        if (p >= 30) return "battery_3_bar";
        if (p >= 15) return "battery_2_bar";
        if (p >= 5) return "battery_1_bar";
        return "battery_alert";
    }

    function dur(sec) {
        const m = Math.round(sec / 60);
        const h = Math.floor(m / 60);
        return h > 0 ? h + "h " + (m % 60) + "m" : m + " min";
    }

    readonly property string eta: {
        if (!present) return "";
        if (full) return "Fully charged";
        const t = charging ? (dev?.timeToFull ?? 0) : (dev?.timeToEmpty ?? 0);
        const d = t > 0 ? dur(t) : "";
        if (charging) return d ? "Charging · " + d + " to full" : "Charging";
        return d ? d + " remaining" : "On battery";
    }
}
