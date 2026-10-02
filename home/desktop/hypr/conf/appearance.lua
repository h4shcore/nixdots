-- https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 5,
        gaps_workspaces = 50,

        border_size = 1,

        col = {
            active_border = "rgba(0DB7D455)",
            inactive_border = "rgba(31313600)",
        },
        resize_on_border = true,

        no_focus_fallback = true,
        allow_tearing = true, -- allows the `immediate` window rule to work
        snap = {
            enabled = true,
            window_gap = 4,
            monitor_gap = 5,
            respect_gaps = true,
        },
    },

    decoration = {
        -- 2 = circle, higher = squircle, 4 = very obvious squircle
        -- Fuck clearly visible squircles. 100% Apple brainrot.
        rounding_power = 2.5,
        rounding = 18,
        blur = {
            enabled = true,
            xray = false,
            special = false,
            new_optimizations = true,
            size = 10,
            passes = 3,
            brightness = 1,
            noise = 0.05,
            contrast = 0.89,
            vibrancy = 0.5,
            vibrancy_darkness = 0.5,
            popups = false,
            popups_ignorealpha = 0.6,
            input_methods = true,
            input_methods_ignorealpha = 0.8,
        },
        shadow = {
            enabled = true,
            range = 20,
            offset = { 0, 2 },
            render_power = 10,
            color = "rgba(00000020)",
        },
        dim_inactive = true,
        dim_strength = 0.05,
        dim_special = 0.2,
    },

    animations = {
        enabled = true,
    },
})
