pragma Singleton
import QtQuick
import Quickshell

// Icon resolver. If a Material Symbols font is installed, every icon is drawn from it (by ligature
// name); otherwise the Nerd Font glyphs are used. Code may pass either an old Nerd Font "\uXXXX"
// glyph (translated below) or a Material icon name like "battery_full" / "lock".
Singleton {
    id: root

    // 0 = auto-detect, 1 = always Material Symbols, 2 = always Nerd Font glyphs
    readonly property int mode: 0

    readonly property string nerdFamily: "Symbols Nerd Font Mono"
    readonly property var materialFamilies: ["Material Symbols Rounded", "Material Symbols Outlined", "Material Symbols Sharp"]

    readonly property string matFamily: {
        try {
            const fams = Qt.fontFamilies();
            for (const f of root.materialFamilies)
                if (fams.indexOf(f) >= 0) return f;
        } catch (err) {}
        return "";
    }
    readonly property bool useMaterial: mode === 1 || (mode === 0 && matFamily !== "")
    readonly property string family: matFamily !== "" ? matFamily : materialFamilies[0]
    readonly property real sizeScale: useMaterial ? 1.25 : 1

    // Nerd Font glyph -> Material Symbols name
    readonly property var toMat: ({
        "\uf0f3": "notifications", "\uf1f6": "notifications_off", "\uf005": "star", "\uf001": "music_note",
        "\uf1f8": "delete", "\uf185": "brightness_high", "\uf030": "photo_camera", "\uf00d": "close",
        "\uf00c": "check", "\uf2d0": "web_asset", "\uf293": "bluetooth", "\uf1eb": "wifi",
        "\uf15c": "description", "\uf130": "mic", "\uf125": "crop", "\uf111": "fiber_manual_record",
        "\uf108": "desktop_windows", "\uf105": "chevron_right", "\uf104": "chevron_left", "\uf0ea": "content_paste",
        "\uf0d0": "auto_fix_high", "\uf086": "forum", "\uf051": "skip_next", "\uf04d": "stop",
        "\uf04c": "pause", "\uf04b": "play_arrow", "\uf048": "skip_previous", "\uf03e": "image",
        "\uf03d": "videocam", "\uf028": "volume_up", "\uf027": "volume_down", "\uf026": "volume_off",
        "\uf009": "grid_view", "\uf002": "search"
    })

    // Material names that only exist in newer code -> Nerd Font fallback glyph
    readonly property var extraNerd: ({
        "battery_full": "\uf240", "battery_6_bar": "\uf240", "battery_5_bar": "\uf241", "battery_4_bar": "\uf241",
        "battery_3_bar": "\uf242", "battery_2_bar": "\uf243", "battery_1_bar": "\uf244", "battery_alert": "\uf244",
        "battery_charging_full": "\uf0e7",
        "lock": "\uf023", "logout": "\uf08b", "bedtime": "\uf186", "restart_alt": "\uf021",
        "power_settings_new": "\uf011"
    })

    readonly property var toNerd: {
        const o = {};
        for (const k in toMat) o[toMat[k]] = k;
        for (const k in extraNerd) o[k] = extraNerd[k];
        return o;
    }

    function resolve(t) {
        t = t ?? "";
        const isName = /^[a-z][a-z0-9_]+$/.test(t);
        if (useMaterial) {
            if (toMat[t] !== undefined) return { family: family, text: toMat[t] };
            if (isName) return { family: family, text: t };
        } else if (isName && toNerd[t] !== undefined) {
            return { family: nerdFamily, text: toNerd[t] };
        }
        return { family: nerdFamily, text: t };
    }
}
