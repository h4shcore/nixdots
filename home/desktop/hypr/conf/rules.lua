-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- ######## Window rules ########

-- Ignore maximize requests from all apps
local suppressMaximizeRule = hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

-- Blur: disable for xwayland context menus and for all windows.
-- (Layer surfaces like bars/launchers are still blurred via the layer rules below.)
-- Delete the second rule if you want blur on regular windows.
hl.window_rule({ match = { class = "^()$", title = "^()$" }, no_blur = true })
hl.window_rule({ match = { class = ".*" }, no_blur = true })

-- Floating + centered file dialogs
for _, title in ipairs({
    "^(Open File)(.*)$",
    "^(Select a File)(.*)$",
    "^(Open Folder)(.*)$",
    "^(Save As)(.*)$",
    "^(Library)(.*)$",
    "^(File Upload)(.*)$",
    "^(.*)(wants to save)$",
    "^(.*)(wants to open)$",
}) do
    hl.window_rule({ match = { title = title }, float = true, center = true })
end

-- Floating utility windows (by class)
for _, class in ipairs({
    "^(blueberry\\.py)$",
    "^(guifetch)$", -- FlafyDev/guifetch
    ".*plasmawindowed.*",
    "kcm_.*",
    ".*bluedevilwizard",
}) do
    hl.window_rule({ match = { class = class }, float = true })
end

-- Floating, centered, 45% of the monitor
for _, class in ipairs({
    "^(pavucontrol)$",
    "^(org.pulseaudio.pavucontrol)$",
    "^(nm-connection-editor)$",
}) do
    hl.window_rule({
        match  = { class = class },
        float  = true,
        center = true,
        size   = { "(monitor_w*0.45)", "(monitor_h*0.45)" },
    })
end

hl.window_rule({
    match = { class = "^(Zotero)$" },
    float = true,
    size  = { "(monitor_w*0.45)", "(monitor_h*0.45)" },
})

hl.window_rule({
    match = { class = "org.freedesktop.impl.portal.desktop.kde" },
    float = true,
    size  = { "(monitor_w*0.60)", "(monitor_h*0.65)" },
})

hl.window_rule({ match = { title = ".*Welcome" }, float = true })
hl.window_rule({ match = { title = "^(Settings)$" }, float = true })

-- Move
-- kde-material-you-colors spawns a window when changing dark/light theme; keep it out of the way.
hl.window_rule({
    match = { class = "^(plasma-changeicons)$" },
    float = true,
    no_initial_focus = true,
    move  = { 999999, 999999 },
})
-- Dolphin copy dialog
hl.window_rule({ match = { title = "^(Copying — Dolphin)$" }, move = { 40, 80 } })

-- Tiling
hl.window_rule({ match = { class = "^dev\\.warp\\.Warp$" }, tile = true })

-- Picture-in-Picture
hl.window_rule({
    match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
    float = true,
    pin   = true,
    keep_aspect_ratio = true,
    move  = { "(monitor_w*0.73)", "(monitor_h*0.72)" },
    size  = { "(monitor_w*0.25)", "(monitor_h*0.25)" },
})

-- Screen sharing indicator
hl.window_rule({
    match = { title = ".*is sharing (a window|your screen).*" },
    float = true,
    pin   = true,
    move  = { "(monitor_w*.5-window_w*.5)", "(monitor_h-window_h-12)" },
})

-- Tearing (needs general.allow_tearing = true, already set)
hl.window_rule({ match = { title = ".*\\.exe" }, immediate = true })
hl.window_rule({ match = { title = ".*minecraft.*" }, immediate = true })
hl.window_rule({ match = { class = "^(steam_app).*" }, immediate = true })

-- No shadow for tiled windows
hl.window_rule({ match = { float = false }, no_shadow = true })

-- Special workspaces (tag windows, then send each tag to its own special workspace)
local music_player_tag      = "music_player"
local communication_app_tag = "communication_app"

-- Tags every window whose `field` (class, title, initial_title, ...) matches one of `patterns`
local function tagged_rule(tag, patterns, field)
    for _, pattern in ipairs(patterns) do
        hl.window_rule({ match = { [field] = pattern }, tag = "+" .. tag })
    end
end

tagged_rule(music_player_tag, {
    "feishin|Supersonic|Plexamp",                                  -- Self hosted
    "Spotify",                                                     -- Spotify
    "Cider",                                                       -- Apple music
    "com.github.th-ch.youtube-music|com-maxrave-simpmusic-MainKt", -- YouTube music
}, "class")
tagged_rule(music_player_tag, {
    "Spotify|Spotify Free" -- Spotify wayland, it has no class for some reason
}, "initial_title")
tagged_rule(communication_app_tag, {
    "discord|equibop|vesktop", -- Discord clients
    "whatsapp"                 -- Whatsapp
}, "class")

-- tag -> special workspace
local special_workspaces = {
    [music_player_tag]      = "special:music",
    [communication_app_tag] = "special:chat",
}
for tag, workspace in pairs(special_workspaces) do
    hl.window_rule({ match = { tag = tag }, workspace = workspace })
    hl.workspace_rule({ workspace = workspace, gaps_out = 30 })
end

-- ######## Workspace rules ########

-- Gaps around the scratchpad (your bind uses special:magic)
hl.workspace_rule({ workspace = "special:magic", gaps_out = 30 })

-- "Smart gaps" / "No gaps when only" (uncomment all if you want it)
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

-- ######## Layer rules ########

hl.layer_rule({ match = { namespace = ".*" }, xray = false })

-- No map animation
for _, ns in ipairs({
    "walker", "selection", "overview", "anyrun", "indicator.*",
    "osk", "hyprpicker", "noanim",
    "gtk4-layer-shell", -- launchers need to be FAST
}) do
    hl.layer_rule({ match = { namespace = ns }, no_anim = true })
end

-- Blur: { namespace, ignore_alpha (nil = blur only) }
local blurred = {
    { "gtk-layer-shell", 0 },
    { "launcher",        0.5 },  -- fuzzel
    { "notifications",   0.69 }, -- mako
    { "logout_dialog" },         -- wlogout
    -- { "waybar", 0.6 },        -- uncomment if your Waybar background is translucent

    -- ags-style shell namespaces (inert if you don't run ags)
    { "session[0-9]*" },
    { "bar[0-9]*",       0.6 },
    { "barcorner.*",     0.6 },
    { "dock[0-9]*",      0.6 },
    { "indicator.*",     0.6 },
    { "overview[0-9]*",  0.6 },
    { "cheatsheet[0-9]*", 0.6 },
    { "sideright[0-9]*", 0.6 },
    { "sideleft[0-9]*",  0.6 },
    { "osk[0-9]*",       0.6 },
}
for _, b in ipairs(blurred) do
    hl.layer_rule({ match = { namespace = b[1] }, blur = true, ignore_alpha = b[2] })
end

-- ags slide animations
hl.layer_rule({ match = { namespace = "sideleft.*" },  animation = "slide left" })
hl.layer_rule({ match = { namespace = "sideright.*" }, animation = "slide right" })

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)
